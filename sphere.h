#ifndef SPHERE_H
#define SPHERE_H

#include "vec3.h"
#include "ray.h"
#include "material.h"

struct sphere {
	vec3 center;
	vec3 velocity;
	float radius;
	material mat;

	__host__ __device__ sphere(const vec3& c, float r, material m) {
		center = c;
		velocity = vec3(0.0, 0.0, 0.0);
		radius = r;
		mat = m;
	}

	__host__ __device__ sphere(const vec3& c, const vec3& v, float r, material m) {
		center = c;
		velocity = v;
		radius = r;
		mat = m;
	}

	__host__ __device__ bool hit(const ray& r, float ray_tmin, float ray_tmax, hit_record& rec) {
		vec3 current_center = center + velocity*r.tm;
		vec3 oc = current_center - r.orig;
		float a = r.dir.length_squared();
		float h = dot(r.dir, oc);
		float c = oc.length_squared() - radius*radius;

		float discriminant = h*h - a*c;
		if (discriminant < 0.0) return false;

		float sqrtd = util::sqrt(discriminant);

		float root = (h - sqrtd) / a;
		if (root <= ray_tmin || ray_tmax <= root) {
			root = (h + sqrtd) / a;
			if (root <= ray_tmin || ray_tmax <= root) return false;
		}

		rec.t = root;
		rec.p = r.at(rec.t);
		vec3 outward_normal = (rec.p - current_center) / radius;
		rec.set_face_normal(r, outward_normal);
		rec.mat = &mat;

		return true;
	}
};

struct sphere_list {
	sphere* spheres;
	int num_spheres;

	__host__ __device__ bool hit(const ray& r, float ray_tmin, float ray_tmax, hit_record& rec) const {
		hit_record temp_rec;
		bool hit_anything = false;
		float closest_so_far = ray_tmax;

		for (int s = 0; s < num_spheres; s++) {
			if (spheres[s].hit(r, ray_tmin, closest_so_far, temp_rec)) {
				hit_anything = true;
				closest_so_far = temp_rec.t;
				rec = temp_rec;
			}
		}

		return hit_anything;
	}
};

#endif
