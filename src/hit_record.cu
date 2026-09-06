#include "hit_record.cuh"
#include "material.cuh"

__host__ __device__ void hit_record::set_face_normal(const ray& r, const vec3& outward_normal) {
    front_face = dot(r.dir, outward_normal) < 0.0f;
    normal = front_face ? outward_normal : -outward_normal;
}
