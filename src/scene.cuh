#ifndef SCENE_H
#define SCENE_H

#include "sphere.cuh"
#include "plane.cuh"
#include "mesh.cuh"
#include "hit_record.cuh"

struct scene {
	sphere_list spheres;
	plane_list planes;
	mesh_list meshes;

	__host__ __device__ bool hit(const ray& r, float ray_tmin, float ray_tmax, hit_record& rec) const;
};

#endif
