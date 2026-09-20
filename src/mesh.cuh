#ifndef MESH_H
#define MESH_H

#include "vec3.cuh"
#include "ray.cuh"
#include "box.cuh"
#include "material.cuh"
#include "hit_record.cuh"
#include "settings.cuh"
#include "vec_mesh.cuh"
#include "bvh.cuh"

struct mesh {
    int triangles_start;
	int num_triangles;
	material mat;
	bvh_node* bvh;

	__host__ __device__ bool hit_triangle(const triangle& tri, const vec3* vertices, const ray& r, float ray_tmin, float ray_tmax, hit_record& rec);
	__host__ __device__ bool hit(const ray& r, const vec3* vertices, const triangle* triangles, float ray_tmin, float ray_tmax, int node_idx, hit_record& rec);
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
