#ifndef BOX_H
#define BOX_H

#include "vec3.h"
#include "ray.h"

struct box {
	vec3 bounds[2];

	box() = default;

	box(const vec3& min, const vec3& max) {
		bounds[0] = min;
		bounds[1] = max;
	}

	__host__ __device__ bool hit(const ray& r, float ray_tmin, float ray_tmax) const {
		float tmin, tmax, tymin, tymax, tzmin, tzmax;
		float divx = 1 / r.dir.x;
		if (r.dir.x >= 0) {
			tmin = (bounds[0].x - r.orig.x) * divx;
			tmax = (bounds[1].x - r.orig.x) * divx;
		} else {
			tmin = (bounds[1].x - r.orig.x) * divx;
			tmax = (bounds[0].x - r.orig.x) * divx;
		}
		if (r.dir.y >= 0) {
			tymin = (bounds[0].y - r.orig.y) / r.dir.y;
			tymax = (bounds[1].y - r.orig.y) / r.dir.y;
		} else {
			tymin = (bounds[1].y - r.orig.y) / r.dir.y;
			tymax = (bounds[0].y - r.orig.y) / r.dir.y;
		}
		if ((tmin > tymax) || (tymin > tmax)) return false;
		if (tymin > tmin) tmin = tymin;
		if (tymax < tmax) tmax = tymax;
		if (r.dir.z >= 0) {
			tzmin = (bounds[0].z - r.orig.z) / r.dir.z;
			tzmax = (bounds[1].z - r.orig.z) / r.dir.z;
		} else {
			tzmin = (bounds[1].z - r.orig.z) / r.dir.z;
			tzmax = (bounds[0].z - r.orig.z) / r.dir.z;
		}
		if ((tmin > tzmax) || (tzmin > tmax)) return false;
		if (tzmin > tmin) tmin = tzmin;
		if (tzmax < tmax) tmax = tzmax;
		return ((tmin < ray_tmax) && (tmax > ray_tmin));
	}
};

#endif
