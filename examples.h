#ifndef EXAMPLES_H
#define EXAMPLES_H

#include "scene.h"
#include "camera.h"

void cornell_box(camera& cam, scene& world, uint32_t& seed) {
	cam.width = 400;
	cam.height = 400;
	cam.samples_per_pixel = 5;
	cam.max_depth = 10;
	cam.background_color = vec3(0.0, 0.0, 0.0);
	cam.vfov = 40.0;
	cam.lookfrom = vec3(278.0, 278.0, -800.0);
	cam.lookat = vec3(278.0, 278.0, 0.0);
	cam.vup = vec3(0.0, 1.0, 0.0);
	cam.defocus_angle = 0.0;
	cam.initialize();

	material red(lambertian, vec3(0.65, 0.05, 0.05));
	material green(lambertian, vec3(0.12, 0.45, 0.15));
	material white(lambertian, vec3(0.73, 0.73, 0.73));
	material headlight(light, vec3(25.0, 25.0, 25.0));

    vec3 nv(0.0f, 0.0f, 0.0f);

	vec_mesh right_wall;
	std::vector<vec3> rw_vertices = {vec3(0.0, 0.0, 0.0), vec3(0.0, 555.0, 0.0), vec3(0.0, 555.0, 555.0), vec3(0.0, 0.0, 555.0)};
	std::vector<triangle> rw_triangles = {triangle(0, 1, 2, nv), triangle(0, 2, 3, nv)};
	right_wall.vertices = rw_vertices;
	right_wall.triangles = rw_triangles;
	right_wall.mat = red;
	right_wall.set_bounding_box();
	right_wall.set_normals();

	vec_mesh left_wall;
	std::vector<vec3> lw_vertices = {vec3(555.0, 0.0, 0.0), vec3(555.0, 555.0, 0.0), vec3(555.0, 555.0, 555.0), vec3(555.0, 0.0, 555.0)};
	std::vector<triangle> lw_triangles = {triangle(0, 2, 1, nv), triangle(0, 3, 2, nv)};
	left_wall.vertices = lw_vertices;
	left_wall.triangles = lw_triangles;
	left_wall.mat = green;
	left_wall.set_bounding_box();
	left_wall.set_normals();

	vec_mesh other_walls;
	std::vector<vec3> ow_vertices = {vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 555.0), vec3(555.0, 0.0, 555.0), vec3(555.0, 0.0, 0.0), vec3(0.0, 555.0, 0.0), vec3(0.0, 555.0, 555.0), vec3(555.0, 555.0, 555.0), vec3(555.0, 555.0, 0.0)};
	std::vector<triangle> ow_triangles = {triangle(0, 1, 2, nv), triangle(0, 2, 3, nv), triangle(1, 5, 6, nv), triangle(1, 6, 2, nv), triangle(4, 6, 5, nv), triangle(4, 7, 6, nv)};
	other_walls.vertices = ow_vertices;
	other_walls.triangles = ow_triangles;
	other_walls.mat = white;
	other_walls.set_bounding_box();
	other_walls.set_normals();

	vec_mesh teapot;
	teapot.load_obj("meshes/teapot.obj");

	for (vec3& v : teapot.vertices) {
		v *= 60.0;
		v += vec3(278.0, 0.0, 278.0);
	};
	teapot.mat = white;
	teapot.set_bounding_box();
	teapot.set_normals();

	vec_mesh headlight_mesh;
	std::vector<vec3> hl_vertices = {vec3(213.0, 554.0, 227.0), vec3(213.0, 554.0, 332.0), vec3(343.0, 554.0, 332.0), vec3(343.0, 554.0, 227.0)};
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
	cam.samples_per_pixel = 10;
	cam.max_depth = 10;
	cam.background_color = vec3(0.0, 0.0, 0.0);
	cam.vfov = 30.0;
	cam.lookfrom = vec3(0.0, 0.0, 0.0);
	cam.lookat = vec3(0.0, 0.0, -1.0);
	cam.vup = vec3(0.0, 1.0, 0.0);
	cam.defocus_angle = 0.0;
	cam.initialize();

	std::vector<vec_mesh> meshes;

	material teapot_mat(lambertian, vec3(1.0, 1.0, 1.0));
	material headlight_mat(light, vec3(20.0, 20.0, 20.0));

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


#endif
