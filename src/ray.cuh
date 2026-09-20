#ifndef RAY_H
#define RAY_H

#include "vec3.cuh"

struct ray {
	vec3 orig;
	vec3 dir;
    vec3 dir_rec;

	__host__ __device__ ray() {};
	__host__ __device__ ray(const vec3& origin, const vec3& direction) {
		orig = origin; dir = direction;
        dir_rec = vec3(1.0f/dir.x, 1.0f/dir.y, 1.0f/dir.z);
	}

	__host__ __device__ vec3 at(float t) const {
		return orig + t*dir;
	}
};

#endif
