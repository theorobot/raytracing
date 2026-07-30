#ifndef RAY_H
#define RAY_H

#include "vec3.h"

struct ray {
	vec3 orig;
	vec3 dir;
	float tm;

	__host__ __device__ ray() {};
	__host__ __device__ ray(const vec3& origin, const vec3& direction) {
		orig = origin; dir = direction; tm=0.0;
	}

	__host__ __device__ ray(const vec3& origin, const vec3& direction, float time) {
		orig = origin; dir = direction; tm = time;
	}

	__host__ __device__ vec3 at(float t) const {
		return orig + t*dir;
	}
};

#endif
