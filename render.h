#ifndef RENDER_H
#define RENDER_H

void write_image(vec3* colors, int width, int height, std::string file) {
	std::vector<uint8_t> PNG_pixels(width * height * 4);

	for (int y = 0; y < height; ++y) {
		for (int x = 0; x < width; ++x) {
			int c_idx = y*width+x;
			PNG_pixels[(y*width+x)*4+0] = (uint8_t)(util::linear_to_gamma(colors[c_idx].x)*255.999);
			PNG_pixels[(y*width+x)*4+1] = (uint8_t)(util::linear_to_gamma(colors[c_idx].y)*255.999);
			PNG_pixels[(y*width+x)*4+2] = (uint8_t)(util::linear_to_gamma(colors[c_idx].z)*255.999);
			PNG_pixels[(y*width+x)*4+3] = 255;
		}
	}

	std::vector<uint8_t> image;
	lodepng::encode(image, PNG_pixels, width, height);
	lodepng::save_file(image, file);

	std::cout << "Wrote image to file '" << file << "'\n";
}

__host__ __device__ vec3 ray_color(const ray& r, const scene& world, int depth, vec3 bg_color, uint32_t& seed) {
	ray current_ray = r;
	vec3 attenuation(1.0f, 1.0f, 1.0f);

	for (int bounce = 0; bounce < depth; ++bounce) {
		hit_record rec;
		if (world.hit(current_ray, 0.001f, 1000000.0f, rec)) {
			ray scattered;
			vec3 atten;
			if (rec.mat->scatter(current_ray, rec, atten, scattered, seed)) {
				current_ray = scattered;
				attenuation.x *= atten.x;
				attenuation.y *= atten.y;
				attenuation.z *= atten.z;
			} else {
				return attenuation * rec.mat->emission(current_ray, rec, atten, scattered, seed);
			}
		} else {
			return attenuation * bg_color;
		}
	}

	return vec3(0.0f, 0.0f, 0.0f);
}

__global__ void setPixelsGPU(camera cam, scene world, vec3* frame) {
	int workIndex = threadIdx.x + blockIdx.x*blockDim.x;
	if (workIndex >= cam.width*cam.height) return;
	vec3 color(0.0f, 0.0f, 0.0f);
	int x = workIndex % cam.width;
	int y = workIndex / cam.width;
	uint32_t seed = workIndex;
	for (int sample = 0; sample < cam.samples_per_pixel; ++sample) {
		ray r = cam.get_ray(x, y, seed);
		color += ray_color(r, world, cam.max_depth, cam.background_color, seed);
	}
	color /= cam.samples_per_pixel;
	color.x = util::clamp(color.x, 0.0f, 0.999f);
	color.y = util::clamp(color.y, 0.0f, 0.999f);
	color.z = util::clamp(color.z, 0.0f, 0.999f);
	frame[workIndex] = color;
}

void setPixelsCPU(camera cam, scene world, vec3* frame) {
	for (int i = 0; i < cam.width * cam.height; ++i) {
		vec3 color(0.0, 0.0, 0.0);
		uint32_t seed = i;
		int x = i % cam.width;
		int y = i / cam.width;
		for (int sample = 0; sample < cam.samples_per_pixel; ++sample) {
			ray r = cam.get_ray(x, y, seed);
			color += ray_color(r, world, cam.max_depth, cam.background_color, seed);
		}
		color /= cam.samples_per_pixel;
		color.x = util::clamp(color.x, 0.0, 0.999);
		color.y = util::clamp(color.y, 0.0, 0.999);
		color.z = util::clamp(color.z, 0.0, 0.999);
		frame[i] = color;
	}
}

void raytrace(const scene& world, camera& cam, uint32_t& seed, std::string output_file) {
	vec3* frame = nullptr;
	vec3* devFrame = nullptr;

	cudaMallocHost(&frame, cam.width*cam.height*sizeof(vec3));

	cudaMalloc(&devFrame, cam.width*cam.height*sizeof(vec3));
	cudaMemset(devFrame, 0, cam.width*cam.height*sizeof(vec3));

	int blocks = cuda::ceil_div(cam.width*cam.height, num_threads);

	std::chrono::high_resolution_clock::time_point start = std::chrono::high_resolution_clock::now();

	setPixelsGPU<<<blocks, num_threads>>>(cam, world, devFrame);

	cudaError_t err = cudaDeviceSynchronize();
	if (err != cudaSuccess) std::cout << cudaGetErrorString(err) << '\n';

	std::chrono::high_resolution_clock::time_point end = std::chrono::high_resolution_clock::now();
	std::chrono::duration<double> gpu_exec_time;
	gpu_exec_time = std::chrono::duration_cast<std::chrono::duration<double>>(end-start);

	std::cout << "GPU Executed in " << gpu_exec_time.count() << " seconds\n";

	cudaMemcpy(frame, devFrame, cam.width*cam.height*sizeof(vec3), cudaMemcpyDefault);

	write_image(frame, cam.width, cam.height, output_file);

	cudaFree(frame);
	cudaFree(devFrame);
	cudaFree(world.spheres.spheres);
	cudaFree(world.planes.planes);

	std::vector<mesh> host_meshes(world.meshes.num_meshes);
	cudaMemcpy(host_meshes.data(), world.meshes.meshes, world.meshes.num_meshes*sizeof(mesh), cudaMemcpyDeviceToHost);

	for (mesh& m : host_meshes) {
		cudaFree(m.vertices);
		cudaFree(m.triangles);
	}
	cudaFree(world.meshes.meshes);
}

void render_video(scene& world, camera& cam, uint32_t& seed, std::string output_file) {
	std::filesystem::create_directory("images/video_tmp");

	for (int frame = 0; frame < 30; frame++) {
		std::string frame_file = "images/video_tmp/frame" + std::to_string(frame+1) + ".png";
		raytrace(world, cam, seed, frame_file);
	}

	std::string ffmpeg_cmd = "ffmpeg -loglevel quiet -framerate 30 -i images/video_tmp/frame%d.png -c:v libx264 -crf 18 -pix_fmt yuv420p " + output_file;
	int wrote_video = std::system(ffmpeg_cmd.c_str());

	if (wrote_video == -1) {
		perror("Failed to create video. ffmpeg may not be installed");
	}

	std::filesystem::remove_all("images/video_tmp");
}

void create_scene(scene& world, std::vector<sphere> spheres, std::vector<plane> planes, std::vector<vec_mesh> vec_meshes) {
	std::vector<mesh> meshes;	
	for (vec_mesh& vm : vec_meshes) {
		mesh m;
		cudaMalloc(&m.vertices, vm.vertices.size()*sizeof(vec3));
		cudaMemcpy(m.vertices, vm.vertices.data(), vm.vertices.size()*sizeof(vec3), cudaMemcpyHostToDevice);
		m.num_vertices = vm.vertices.size();
		cudaMalloc(&m.triangles, vm.triangles.size()*sizeof(triangle));
		cudaMemcpy(m.triangles, vm.triangles.data(), vm.triangles.size()*sizeof(triangle), cudaMemcpyHostToDevice);
		cudaMalloc(&m.normals, vm.normals.size()*sizeof(vec3));
		cudaMemcpy(m.normals, vm.normals.data(), vm.normals.size()*sizeof(vec3), cudaMemcpyHostToDevice);
		m.num_triangles = vm.triangles.size();
		m.mat = vm.mat;
		m.bounding_box = vm.bounding_box;
		meshes.push_back(m);
	}

	cudaMalloc(&world.spheres.spheres, spheres.size()*sizeof(sphere));
	cudaMemcpy(world.spheres.spheres, spheres.data(), spheres.size()*sizeof(sphere), cudaMemcpyHostToDevice);
	world.spheres.num_spheres = spheres.size();

	cudaMalloc(&world.planes.planes, planes.size()*sizeof(plane));
	cudaMemcpy(world.planes.planes, planes.data(), planes.size()*sizeof(plane), cudaMemcpyHostToDevice);
	world.planes.num_planes = planes.size();

	cudaMalloc(&world.meshes.meshes, meshes.size()*sizeof(mesh));
	cudaMemcpy(world.meshes.meshes, meshes.data(), meshes.size()*sizeof(mesh), cudaMemcpyHostToDevice);
	world.meshes.num_meshes = meshes.size();
}

#endif
