#ifndef CAMERA_H
#define CAMERA_H

#include "vec3.cuh"
#include "ray.cuh"
#include "settings.cuh"

class camera {
public:
	int width = 400;
	int height = 225;
	int samples_per_pixel = 10;
    int samples_per_frame = 1;
	int max_depth = 10;
	float vfov = 90.0f;
	vec3 lookfrom = vec3(0.0f, 0.0f, 0.0f);
	vec3 lookat = vec3(0.0f, 0.0f, -1.0f);
	vec3 vup = vec3(0.0f, 1.0f, 0.0f);
	float defocus_angle = 0.0f;
	float focus_dist = 10.0f;
	vec3 background_color;

    void initialize();
    __host__ __device__ ray get_ray(int i, int j, uint32_t& seed) const;
    __host__ __device__ vec3 defocus_disk_sample(uint32_t& seed) const;

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
