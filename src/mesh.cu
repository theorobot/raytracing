#include "mesh.cuh"

__host__ __device__ bool mesh::hit_triangle(const triangle& tri, const vec3* vertices, const ray& r, float ray_tmin, float ray_tmax, hit_record& rec) {
    vec3 e1 = vertices[tri.v1] - vertices[tri.v0];
    vec3 e2 = vertices[tri.v2] - vertices[tri.v0];
    if (dot(tri.normal, r.dir) > 0.0f) return false;

    vec3 ray_cross_e2 = cross(r.dir, e2);
    float denom = dot(e1, ray_cross_e2);

    if (util::abs(denom) < 1e-6f) return false;

    float inv_denom = 1.0f / denom;
    vec3 s = r.orig - vertices[tri.v0];
    float u = inv_denom * dot(s, ray_cross_e2);

    if (u < -1e-6f || u-1.0f > 1e-6f) return false;

    vec3 s_cross_e1 = cross(s, e1);
    float v = inv_denom * dot(r.dir, s_cross_e1);

    if (v < -1e-6f || u+v-1.0f > 1e-6f) return false;

    float t = inv_denom * dot(e2, s_cross_e1);

    if (t > ray_tmin && t < ray_tmax) {
        rec.t = t;
        rec.p = r.at(t);
        rec.set_face_normal(r, unit_vector(tri.normal));
        rec.mat = &mat;
        return true;
    }

    return false;
}

__host__ __device__ bool mesh::hit(const ray& r, const vec3* vertices, const triangle* triangles, float ray_tmin, float ray_tmax, int node_idx, hit_record& rec) {
    constexpr int MAX_STACK_SIZE = 64;

    int stack[MAX_STACK_SIZE];
    int stack_size = 1;

    stack[0] = node_idx;

    bool hit_anything = false;
    float closest_so_far = ray_tmax;

    while (stack_size > 0) {
        int current_idx = stack[stack_size-1];
        stack_size--;
        bvh_node& node = bvh[current_idx];

        if (!node.bounds.hit(r, ray_tmin, closest_so_far)) continue;

        if (node.left_idx < 0) {
            hit_record temp_rec;

            for (int t = 0; t < node.triCount; t++) {
                if (hit_triangle(triangles[triangles_start+node.firstTri+t], vertices, r, ray_tmin, closest_so_far, temp_rec)) {
                    hit_anything = true;
                    closest_so_far = temp_rec.t;
                    rec = temp_rec;
                }
            }
        } else {
            if (stack_size + 2 <= MAX_STACK_SIZE) {
                stack[stack_size] = node.left_idx;
                stack_size++;
                stack[stack_size] = node.right_idx;
                stack_size++;
            }
        }
    }

    return hit_anything;
}

__host__ __device__ bool mesh_list::hit(const ray& r, float ray_tmin, float ray_tmax, hit_record& rec) const {
    hit_record temp_rec;
    bool hit_anything = false;
    float closest_so_far = ray_tmax;

    for (int m = 0; m < num_meshes; m++) {
        if (meshes[m].hit(r, vertices, triangles, ray_tmin, closest_so_far, 0, temp_rec)) {
            hit_anything = true;
            closest_so_far = temp_rec.t;
            rec = temp_rec;
        }
    }

    return hit_anything;
}
