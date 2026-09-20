#ifndef VEC_MESH_H
#define VEC_MESH_H

#include "vec3.cuh"
#include "ray.cuh"
#include "box.cuh"
#include "material.cuh"
#include "hit_record.cuh"
#include "settings.cuh"

struct triangle {
	int v0, v1, v2;
    vec3 normal;

    triangle();
    triangle(int v0_, int v1_, int v2_, vec3 n);
    
    box bounding_box(std::vector<vec3> v);
};

struct vec_mesh {
	std::vector<vec3> vertices;
	std::vector<triangle> triangles;
	material mat;
	box bounding_box;

	void load_obj(const std::string& filename);
	void set_bounding_box();
	void set_normals();
};

#endif
