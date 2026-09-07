#ifndef HIT_RECORD_H
#define HIT_RECORD_H

#include "vec3.cuh"
#include "ray.cuh"

struct material;

struct hit_record {
    vec3 p;
    vec3 normal;
    float t;
    bool front_face;
    material* mat;

    __host__ __device__ void set_face_normal(const ray& r, const vec3& outward_normal);
};

#endif
