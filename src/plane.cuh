#ifndef PLANE_H
#define PLANE_H

#include "vec3.h"
#include "ray.h"
#include "material.cuh"
#include "hit_record.cuh"
#include "settings.h"

struct plane {
	vec3 p;
	vec3 n;
	material mat;

    plane();
    plane(vec3 point, vec3 normal, material m);

    __host__ __device__ bool hit(const ray& r, const float ray_tmin, const float ray_tmax, hit_record& rec);
};

struct plane_list {
	plane* planes;
	int num_planes;

	__host__ __device__ bool hit(const ray& r, const float ray_tmin, const float ray_tmax, hit_record& rec) const;
};

#endif
