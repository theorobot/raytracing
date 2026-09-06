#ifndef RENDER_H
#define RENDER_H

#include "vec3.h"
#include "ray.h"
#include "camera.cuh"
#include "scene.cuh"
#include "settings.h"

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

__global__ void setPixelsGPU(camera cam, scene world, vec3* frame, int sampleOffset) {
	int workIndex = threadIdx.x + blockIdx.x*blockDim.x;
	if (workIndex >= cam.width*cam.height) return;
	vec3 color(0.0f, 0.0f, 0.0f);
	int x = workIndex % cam.width;
	int y = workIndex / cam.width;
	uint32_t seed = workIndex + sampleOffset * cam.width * cam.height;
	for (int sample = 0; sample < cam.samples_per_frame; ++sample) {
		ray r = cam.get_ray(x, y, seed);
		color += ray_color(r, world, cam.max_depth, cam.background_color, seed);
	}
	frame[workIndex] += color;
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
    vec3* new_frame = nullptr;
	vec3* devFrame = nullptr;

    frame = (vec3*)malloc(cam.width*cam.height*sizeof(vec3));
    memset(frame, 0, cam.width*cam.height*sizeof(vec3));

    cudaMallocHost(&new_frame, cam.width*cam.height*sizeof(vec3));

	cudaMalloc(&devFrame, cam.width*cam.height*sizeof(vec3));
	cudaMemset(devFrame, 0, cam.width*cam.height*sizeof(vec3));

	int blocks = cuda::ceil_div(cam.width*cam.height, num_threads);

    std::chrono::high_resolution_clock::time_point first_start = std::chrono::high_resolution_clock::now();

	std::chrono::high_resolution_clock::time_point start = std::chrono::high_resolution_clock::now();

    for (int sample = 0; sample < cam.samples_per_pixel; sample += cam.samples_per_frame) {
        std::chrono::high_resolution_clock::time_point start = std::chrono::high_resolution_clock::now();

        setPixelsGPU<<<blocks, num_threads>>>(cam, world, devFrame, sample);

        cudaError_t err = cudaDeviceSynchronize();
        if (err != cudaSuccess) std::cout << cudaGetErrorString(err) << '\n';

        std::chrono::high_resolution_clock::time_point end = std::chrono::high_resolution_clock::now();
        std::chrono::duration<double> gpu_exec_time;
        gpu_exec_time = std::chrono::duration_cast<std::chrono::duration<double>>(end-start);

        std::cout << "Finished " << sample+cam.samples_per_frame << "/" << cam.samples_per_pixel << " samples (" << 100*(sample+cam.samples_per_frame) / cam.samples_per_pixel << "%). Time taken: " << gpu_exec_time.count() << " seconds\n";
    }

    std::chrono::high_resolution_clock::time_point final_end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> total_exec_time;
    total_exec_time = std::chrono::duration_cast<std::chrono::duration<double>>(final_end-first_start);

    std::cout << "Rendering took " << total_exec_time.count() << " seconds to execute\n";

    cudaMemcpy(frame, devFrame, cam.width*cam.height*sizeof(vec3), cudaMemcpyDeviceToHost);

    for (int pix = 0; pix < cam.width*cam.height; ++pix) {
        frame[pix] /= cam.samples_per_pixel;

        frame[pix].x = util::clamp(frame[pix].x, 0.0f, 0.999f);
        frame[pix].y = util::clamp(frame[pix].y, 0.0f, 0.999f);
        frame[pix].z = util::clamp(frame[pix].z, 0.0f, 0.999f);
    }

	write_image(frame, cam.width, cam.height, output_file);

	cudaFree(frame);
	cudaFree(devFrame);
	cudaFree(world.spheres.spheres);
	cudaFree(world.planes.planes);
    cudaFree(world.meshes.vertices);
    cudaFree(world.meshes.triangles);
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
    std::vector<vec3> vertices;
    std::vector<triangle> triangles;
    int num_triangles = 0;
    int num_vertices = 0;
	for (vec_mesh& vm : vec_meshes) {
		mesh m;
        m.triangles_start = num_triangles;
        m.num_triangles = vm.triangles.size();
        m.mat = vm.mat;
        m.bounding_box = vm.bounding_box;
        meshes.push_back(m);
        vertices.insert(vertices.end(), vm.vertices.begin(), vm.vertices.end());
        triangles.insert(triangles.end(), vm.triangles.begin(), vm.triangles.end());
        for (int t = num_triangles; t < triangles.size(); t++) {
            triangles[t].v0 += num_vertices;
            triangles[t].v1 += num_vertices;
            triangles[t].v2 += num_vertices;
        }
        num_triangles += vm.triangles.size();
        num_vertices += vm.vertices.size();
	}

    cudaMalloc(&world.meshes.vertices, vertices.size()*sizeof(vec3));
    cudaMemcpy(world.meshes.vertices, vertices.data(), vertices.size()*sizeof(vec3), cudaMemcpyHostToDevice);

    cudaMalloc(&world.meshes.triangles, triangles.size()*sizeof(triangle));
    cudaMemcpy(world.meshes.triangles, triangles.data(), triangles.size()*sizeof(triangle), cudaMemcpyHostToDevice);
    world.meshes.num_triangles = triangles.size();

    cudaMalloc(&world.meshes.meshes, meshes.size()*sizeof(mesh));
    cudaMemcpy(world.meshes.meshes, meshes.data(), meshes.size()*sizeof(mesh), cudaMemcpyHostToDevice);
    world.meshes.num_meshes = meshes.size();

	cudaMalloc(&world.spheres.spheres, spheres.size()*sizeof(sphere));
	cudaMemcpy(world.spheres.spheres, spheres.data(), spheres.size()*sizeof(sphere), cudaMemcpyHostToDevice);
	world.spheres.num_spheres = spheres.size();

	cudaMalloc(&world.planes.planes, planes.size()*sizeof(plane));
	cudaMemcpy(world.planes.planes, planes.data(), planes.size()*sizeof(plane), cudaMemcpyHostToDevice);
	world.planes.num_planes = planes.size();
}

#endif
