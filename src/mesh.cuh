#ifndef MESH_H
#define MESH_H

#include "vec3.cuh"
#include "ray.cuh"
#include "box.cuh"
#include "material.cuh"
#include "hit_record.cuh"
#include "settings.cuh"

struct triangle {
	int v0, v1, v2;
    vec3 normal;

    triangle();
    triangle(int v0_, int v1_, int v2_, vec3 n);
};

struct vec_mesh {
	std::vector<vec3> vertices;
	std::vector<triangle> triangles;
	material mat;
	box bounding_box;

	void load_obj(const std::string& filename);
	void set_bounding_box();
	void set_normals();
};

struct mesh {
    int triangles_start;
	int num_triangles;
	material mat;
	box bounding_box;

	__host__ __device__ bool hit_triangle(const triangle& tri, const vec3* vertices, const ray& r, float ray_tmin, float ray_tmax, hit_record& rec);
	__host__ __device__ bool hit(const ray& r, const vec3* vertices, const triangle* triangles, float ray_tmin, float ray_tmax, hit_record& rec);
};

struct mesh_list {
    vec3* vertices;
    triangle* triangles;
    int num_triangles;
	mesh* meshes;
	int num_meshes;

	__host__ __device__ bool hit(const ray& r, float ray_tmin, float ray_tmax, hit_record& rec) const;
};

#endif
