#ifndef CAMERA_H
#define CAMERA_H

#include "vec3.h"
#include "ray.h"
#include "settings.h"

class camera {
public:
	int width = 400;
	int height = 225;
	int samples_per_pixel = 10;
	int max_depth = 10;
	float vfov = 90.0f;
	vec3 lookfrom = vec3(0.0f, 0.0f, 0.0f);
	vec3 lookat = vec3(0.0f, 0.0f, -1.0f);
	vec3 vup = vec3(0.0f, 1.0f, 0.0f);
	float defocus_angle = 0.0f;
	float focus_dist = 10.0f;
	vec3 background_color;

	void initialize() {
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

	__host__ __device__ ray get_ray(int i, int j, uint32_t& seed) const {
		float u = i + util::random_float(seed, -0.5f, 0.5f);
		float v = j + util::random_float(seed, -0.5f, 0.5f);
		vec3 pixel_sample = pixel00_loc + u*pixel_delta_u + v*pixel_delta_v;
		vec3 ray_origin = (defocus_angle > 0.0f) ? defocus_disk_sample(seed) : center;
		vec3 ray_direction = pixel_sample - ray_origin;
		return ray(ray_origin, ray_direction);
	}

	__host__ __device__ vec3 defocus_disk_sample(uint32_t& seed) const {
		vec3 p = util::random_in_unit_disk(seed);
		return center + (p.x*defocus_disk_u) + (p.y*defocus_disk_v);
	}

private:
	vec3 center;
	vec3 pixel00_loc;
	vec3 pixel_delta_u;
	vec3 pixel_delta_v;
	vec3 u;
	vec3 v;
	vec3 w;
	vec3 defocus_disk_u;
	vec3 defocus_disk_v;
};

#endif
