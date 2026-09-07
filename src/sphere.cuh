#ifndef SPHERE_H
#define SPHERE_H

#include "vec3.cuh"
#include "ray.cuh"
#include "material.cuh"
#include "hit_record.cuh"

struct sphere {
	vec3 center;
	float radius;
	material mat;

	sphere();
	sphere(const vec3& c, float r, material m);

	__host__ __device__ bool hit(const ray& r, float ray_tmin, float ray_tmax, hit_record& rec);
};

struct sphere_list {
	sphere* spheres;
	int num_spheres;

	__host__ __device__ bool hit(const ray& r, float ray_tmin, float ray_tmax, hit_record& rec) const;
};

#endif
