#ifndef PLANE_H
#define PLANE_H

#include "vec3.h"
#include "ray.h"
#include "material.h"
#include "settings.h"

struct plane {
	vec3 p;
	vec3 n;
	material mat;

	plane() = default;

	plane(vec3 point, vec3 normal, material m) {
		p = point;
		n = unit_vector(normal);
		mat = m;
	}

	__host__ __device__ bool hit(const ray& r, const float ray_tmin, const float ray_tmax, hit_record& rec) {
		float denom = dot(n, r.dir);
		if (util::abs(denom) >= 1e-6f) {
			float t = dot(p-r.orig, n) / denom;
			if (t > ray_tmin && t < ray_tmax) {
				rec.t = t;
				rec.p = r.at(t);
				rec.set_face_normal(r, n);
				rec.mat = &mat;
				return true;
			}
		}
		return false;
	}
};

struct plane_list {
	plane* planes;
	int num_planes;

	__host__ __device__ bool hit(const ray& r, const float ray_tmin, const float ray_tmax, hit_record& rec) const {
		hit_record temp_rec;
		bool hit_anything = false;
		float closest_so_far = ray_tmax;

		for (int p = 0; p < num_planes; p++) {
			if (planes[p].hit(r, ray_tmin, closest_so_far, temp_rec)) {
				hit_anything = true;
				closest_so_far = temp_rec.t;
				rec = temp_rec;
			}
		}

		return hit_anything;
	}
};

#endif
