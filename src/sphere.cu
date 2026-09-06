#include "sphere.cuh"

sphere::sphere() = default;

sphere::sphere(const vec3& c, float r, material m) {
    center = c;
    radius = r;
    mat = m;
}

__host__ __device__ bool sphere::hit(const ray& r, float ray_tmin, float ray_tmax, hit_record& rec) {
    vec3 oc = center - r.orig;
    float a = r.dir.length_squared();
    float h = dot(r.dir, oc);
    float c = oc.length_squared() - radius*radius;

    float discriminant = h*h - a*c;
    if (discriminant < 0.0f) return false;

    float sqrtd = util::sqrt(discriminant);

    float root = (h - sqrtd) / a;
    if (root <= ray_tmin || ray_tmax <= root) {
        root = (h + sqrtd) / a;
        if (root <= ray_tmin || ray_tmax <= root) return false;
    }

    rec.t = root;
    rec.p = r.at(rec.t);
    vec3 outward_normal = (rec.p - center) / radius;
    rec.set_face_normal(r, outward_normal);
    rec.mat = &mat;

    return true;
}

__host__ __device__ bool sphere_list::hit(const ray& r, float ray_tmin, float ray_tmax, hit_record& rec) const {
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
