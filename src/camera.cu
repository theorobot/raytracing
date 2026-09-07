#include "camera.cuh"

void camera::initialize() {
    center = lookfrom;
    float theta = vfov * PI / 180.0f;
    float h = util::tan(theta/2.0f);
    float viewport_height = 2.0f * h * focus_dist;
    float viewport_width = viewport_height*(float(width)/height);
    w = unit_vector(lookfrom - lookat);
    u = unit_vector(cross(vup, w));
    v = cross(w, u);
    vec3 viewport_u = viewport_width*u;
    vec3 viewport_v = viewport_height*-v;
    pixel_delta_u = viewport_u / width;
    pixel_delta_v = viewport_v / height;
    vec3 viewport_upper_left = center-(focus_dist*w) - viewport_u/2.0f - viewport_v/2.0f;
    pixel00_loc = viewport_upper_left + 0.5f*(pixel_delta_u+pixel_delta_v);
    float defocus_radius = focus_dist * util::tan(defocus_angle * PI / 360.0f);
    defocus_disk_u = u*defocus_radius;
    defocus_disk_v = v*defocus_radius;
}

__host__ __device__ ray camera::get_ray(int i, int j, uint32_t& seed) const {
    float u = i + util::random_float(seed, -0.5f, 0.5f);
	float v = j + util::random_float(seed, -0.5f, 0.5f);
	vec3 pixel_sample = pixel00_loc + u*pixel_delta_u + v*pixel_delta_v;
	vec3 ray_origin = (defocus_angle > 0.0f) ? defocus_disk_sample(seed) : center;
	vec3 ray_direction = pixel_sample - ray_origin;
	return ray(ray_origin, ray_direction);
}

__host__ __device__ vec3 camera::defocus_disk_sample(uint32_t& seed) const {
    vec3 p = util::random_in_unit_disk(seed);
    return center + (p.x*defocus_disk_u) + (p.y*defocus_disk_v);
}
