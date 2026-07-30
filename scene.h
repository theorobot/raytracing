#ifndef OBJECT_H
#define OBJECT_H

#include "sphere.h"
#include "plane.h"
#include "mesh.h"

struct scene {
	sphere_list spheres;
	plane_list planes;
	mesh_list meshes;

	__host__ __device__ bool hit(const ray& r, float ray_tmin, float ray_tmax, hit_record& rec) const {
		hit_record temp_rec;
		bool hit_anything = false;
		float closest_so_far = ray_tmax;

		if (spheres.hit(r, ray_tmin, closest_so_far, temp_rec)) {
			hit_anything = true;
			closest_so_far = temp_rec.t;
			rec = temp_rec;
		}

		if (planes.hit(r, ray_tmin, closest_so_far, temp_rec)) {
			hit_anything = true;
			closest_so_far = temp_rec.t;
			rec = temp_rec;
		}

		if (meshes.hit(r, ray_tmin, closest_so_far, temp_rec)) {
			hit_anything = true;
			closest_so_far = temp_rec.t;
			rec = temp_rec;
		}

		return hit_anything;
	}
};

#endif
