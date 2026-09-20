#ifndef EXAMPLES_H
#define EXAMPLES_H

#include "scene.cuh"
#include "camera.cuh"
#include "bvh.cuh"

void cornell_box(camera& cam, scene& world, uint32_t& seed) {
	cam.width = 400;
	cam.height = 400;
	cam.samples_per_pixel = 5000;
    cam.samples_per_frame = 50;
	cam.max_depth = 10;
	cam.background_color = vec3(0.0f, 0.0f, 0.0f);
	cam.vfov = 38.0f;
	cam.lookfrom = vec3(278.0f, 278.0f, -800.0f);
	cam.lookat = vec3(278.0f, 278.0f, 0.0f);
	cam.vup = vec3(0.0f, 1.0f, 0.0f);
	cam.defocus_angle = 10.0f;
    cam.focus_dist = 1078.0f;
	cam.initialize();

    material red, green, white, headlight;
    red.set_lambertian(vec3(0.65f, 0.05f, 0.05f));
    green.set_lambertian(vec3(0.12f, 0.45f, 0.15f));
    white.set_lambertian(vec3(0.73f, 0.73f, 0.73f));
    headlight.set_light(vec3(25.0f, 25.0f, 25.0f));

    vec3 nv(0.0f, 0.0f, 0.0f);

	vec_mesh right_wall;
	std::vector<vec3> rw_vertices = {vec3(0.0f, 0.0f, 0.0f), vec3(0.0f, 555.0f, 0.0f), vec3(0.0f, 555.0f, 555.0f), vec3(0.0f, 0.0f, 555.0f)};
	std::vector<triangle> rw_triangles = {triangle(0, 1, 2, nv), triangle(0, 2, 3, nv)};
	right_wall.vertices = rw_vertices;
	right_wall.triangles = rw_triangles;
	right_wall.mat = red;
	right_wall.set_bounding_box();
	right_wall.set_normals();

	vec_mesh left_wall;
	std::vector<vec3> lw_vertices = {vec3(555.0f, 0.0f, 0.0f), vec3(555.0f, 555.0f, 0.0f), vec3(555.0f, 555.0f, 555.0f), vec3(555.0f, 0.0f, 555.0f)};
	std::vector<triangle> lw_triangles = {triangle(0, 2, 1, nv), triangle(0, 3, 2, nv)};
	left_wall.vertices = lw_vertices;
	left_wall.triangles = lw_triangles;
	left_wall.mat = green;
	left_wall.set_bounding_box();
	left_wall.set_normals();

	vec_mesh other_walls;
	std::vector<vec3> ow_vertices = {vec3(0.0f, 0.0f, 0.0f), vec3(0.0f, 0.0f, 555.0f), vec3(555.0f, 0.0f, 555.0f), vec3(555.0f, 0.0f, 0.0f), vec3(0.0f, 555.0f, 0.0f), vec3(0.0f, 555.0f, 555.0f), vec3(555.0f, 555.0f, 555.0f), vec3(555.0f, 555.0f, 0.0f)};
	std::vector<triangle> ow_triangles = {triangle(0, 1, 2, nv), triangle(0, 2, 3, nv), triangle(1, 5, 6, nv), triangle(1, 6, 2, nv), triangle(4, 6, 5, nv), triangle(4, 7, 6, nv)};
	other_walls.vertices = ow_vertices;
	other_walls.triangles = ow_triangles;
	other_walls.mat = white;
	other_walls.set_bounding_box();
	other_walls.set_normals();

	vec_mesh teapot;
	teapot.load_obj("meshes/teapot.obj");

	for (vec3& v : teapot.vertices) {
		v *= 60.0f;
		v += vec3(278.0f, 0.0f, 278.0f);
	};
	teapot.mat = white;
	teapot.set_bounding_box();
	teapot.set_normals();

	vec_mesh headlight_mesh;
	std::vector<vec3> hl_vertices = {vec3(213.0f, 554.0f, 227.0f), vec3(213.0f, 554.0f, 332.0f), vec3(343.0f, 554.0f, 332.0f), vec3(343.0f, 554.0f, 227.0f)};
	std::vector<triangle> hl_triangles = {triangle(0, 1, 2, nv), triangle(0, 2, 3, nv)};
	headlight_mesh.vertices = hl_vertices;
	headlight_mesh.triangles = hl_triangles;
	headlight_mesh.mat = headlight;
	headlight_mesh.set_bounding_box();
	headlight_mesh.set_normals();

	std::vector<sphere> spheres;
	std::vector<plane> planes;
	std::vector<vec_mesh> meshes;

	meshes.push_back(right_wall);
	meshes.push_back(left_wall);
	meshes.push_back(other_walls);
	meshes.push_back(headlight_mesh);
	meshes.push_back(teapot);

	create_scene(world, spheres, planes, meshes);
}

void teapots(camera& cam, scene& world, uint32_t& seed) {
	cam.width = 1920;
	cam.height = 1080;
	cam.samples_per_pixel = 100;
	cam.max_depth = 10;
	cam.background_color = vec3(0.0f, 0.0f, 0.0f);
	cam.vfov = 30.0f;
	cam.lookfrom = vec3(0.0f, 0.0f, 0.0f);
	cam.lookat = vec3(0.0f, 0.0f, -1.0f);
	cam.vup = vec3(0.0f, 1.0f, 0.0f);
	cam.defocus_angle = 0.0f;
	cam.initialize();

	std::vector<vec_mesh> meshes;

    material teapot_mat;
    material headlight_mat;

    teapot_mat.set_lambertian(vec3(1.0f, 1.0f, 1.0f));
    headlight_mat.set_light(vec3(20.0f, 20.0f, 20.0f));

    /* vec_mesh tp;
    tp.load_obj("meshes/teapot.obj");
    tp.mat = teapot_mat;
    tp.set_bounding_box();
    tp.set_normals();

    std::vector<bvh_node> bvh = createBVH(tp);

    for (int n = 0; n < bvh.size(); n++) {
        std::cout << "BVH Node:  " << n << '\n';
        std::cout << "Min bound: {" << bvh[n].bounds.bounds[0].x << ' ' << bvh[n].bounds.bounds[0].y << ' ' << bvh[n].bounds.bounds[0].z << "}\n";
        std::cout << "Max bound: {" << bvh[n].bounds.bounds[1].x << ' ' << bvh[n].bounds.bounds[1].y << ' ' << bvh[n].bounds.bounds[1].z << "}\n";
        std::cout << "Left idx:  " << bvh[n].left_idx << '\n';
        std::cout << "Right idx: " << bvh[n].right_idx << '\n';
        std::cout << "First tri: " << bvh[n].firstTri << '\n';
        std::cout << "Tri count: " << bvh[n].triCount << '\n';
        std::cout << '\n';
    } */

	for (int i = -10; i <= 10; i += 10) {
		for (int j = -10; j <= 10; j += 10) {
			vec_mesh teapot;
			teapot.load_obj("meshes/teapot.obj");

			for (vec3& v : teapot.vertices) {
				v += vec3(i, j, -60.0);
			};
			teapot.mat = teapot_mat;
			teapot.set_bounding_box();
			teapot.set_normals();

			meshes.push_back(teapot);
		}
	}

    vec_mesh headlight;
    headlight.load_obj("meshes/cube.obj");
    for (vec3& v : headlight.vertices) {
        v.x *= 5.0f;
        v.y *= 5.0f;
        v.z += 2.0f;
    }
    headlight.mat = headlight_mat;
    headlight.set_bounding_box();
    headlight.set_normals();
    meshes.push_back(headlight);

	std::vector<sphere> spheres;
	std::vector<plane> planes;

	create_scene(world, spheres, planes, meshes);
}

void cube(camera& cam, scene& world, uint32_t& seed) {
	cam.width = 400;
	cam.height = 400;
	cam.samples_per_pixel = 1000;
    cam.samples_per_frame = 1000;
	cam.max_depth = 10;
	cam.background_color = vec3(0.0f, 0.0f, 0.0f);
	cam.vfov = 30.0f;
	cam.lookfrom = vec3(10.0f, 10.0f, 20.0f);
	cam.lookat = vec3(0.0f, 0.0f, 0.0f);
	cam.vup = vec3(0.0f, 1.0f, 0.0f);
	cam.defocus_angle = 0.0f;
	cam.initialize();

	std::vector<vec_mesh> meshes;

    material cube_mat;
    material light_mat;

    cube_mat.set_lambertian(vec3(0.7f, 0.7f, 0.7f));
    light_mat.set_light(vec3(5.0f, 5.0f, 5.0f));

    vec_mesh cube;
    cube.load_obj("meshes/cube.obj");
    cube.mat = cube_mat;
    cube.set_bounding_box();
    cube.set_normals();

    std::vector<bvh_node> bvh = createBVH(cube);
    for (int n = 0; n < bvh.size(); n++) {
        std::cout << "BVH Node:  " << n << '\n';
        std::cout << "Left idx:  " << bvh[n].left_idx << '\n';
        std::cout << "Right idx: " << bvh[n].right_idx << '\n';
        std::cout << "First tri: " << bvh[n].firstTri << '\n';
        std::cout << "Tri count: " << bvh[n].triCount << '\n';
        std::cout << '\n';
    }

    meshes.push_back(cube);

	std::vector<sphere> spheres;

    sphere s_light(vec3(5.0f, 10.0f, 30.0f), 10.0f, light_mat);
    spheres.push_back(s_light);

	std::vector<plane> planes;

	create_scene(world, spheres, planes, meshes);
}

#endif
