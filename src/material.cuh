#ifndef MATERIAL_H
#define MATERIAL_H

#include "vec3.cuh"
#include "ray.cuh"
#include "settings.cuh"

struct hit_record;

enum mat_type {
	lambertian,
	metal,
	dielectric,
	light
};

struct material {
	mat_type e_type;
	vec3 v_albedo;
	float f_fuzz;
	float f_refraction_index;

    material();
    material(mat_type type, vec3 albedo, float fuzz, float refraction_index);
    
    void set_lambertian(vec3 albedo);
    void set_metal(vec3 albedo, float fuzz);
    void set_dielectric(vec3 albedo, float refraction_index);
    void set_light(vec3 albedo);

	__host__ __device__ bool scatter(const ray& r_in, const hit_record& rec, vec3& attenuation, ray& scattered, uint32_t& seed);
	__host__ __device__ vec3 emission(const ray& r_in, const hit_record& rec, vec3& attenuation, ray& scattered, uint32_t& seed);
};

#endif
