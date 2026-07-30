#ifndef MATERIAL_H
#define MATERIAL_H

#include "vec3.h"
#include "ray.h"
#include "settings.h"

enum mat_type {
	lambertian,
	metal,
	dielectric,
	light
};

struct hit_record;

struct material {
	mat_type e_type;
	vec3 v_albedo;
	float f_fuzz;
	float f_refraction_index;

	material() = default;

	material(mat_type type, vec3 albedo=vec3(0.0,0.0,0.0), float fuzz=0.0, float refraction_index=0.0) {
		e_type = type;
		v_albedo = albedo;
		f_fuzz = fuzz;
		f_refraction_index = refraction_index;
	}

	__host__ __device__ bool scatter(const ray& r_in, const hit_record& rec, vec3& attenuation, ray& scattered, uint32_t& seed);

	__host__ __device__ vec3 emission(const ray& r_in, const hit_record& rec, vec3& attenuation, ray& scattered, uint32_t& seed);
};

struct hit_record {
	vec3 p;
	vec3 normal;
	float t;
	bool front_face;
	material* mat;

	__host__ __device__ void set_face_normal(const ray& r, const vec3& outward_normal) {
		front_face = dot(r.dir, outward_normal) < 0.0;
		normal = front_face ? outward_normal : -outward_normal;
	}
};

__host__ __device__ bool material::scatter(const ray& r_in, const hit_record& rec, vec3& attenuation, ray& scattered, uint32_t& seed) {
	switch (e_type) {
		case lambertian: {
			vec3 scatter_direction = rec.normal + util::random_unit_vector(seed);
			scattered = ray(rec.p, scatter_direction, r_in.tm);
			attenuation = v_albedo;
			return true;
		}

		case metal: {
			vec3 reflected = r_in.dir - 2*dot(r_in.dir, rec.normal)*rec.normal;
			reflected = unit_vector(reflected) + (f_fuzz * util::random_unit_vector(seed));
			scattered = ray(rec.p, reflected, r_in.tm);
			attenuation = v_albedo;
			return dot(scattered.dir, rec.normal) > 0;
		}

		case dielectric: {
			attenuation = vec3(1.0, 1.0, 1.0);
			float ri = rec.front_face ? (1.0 / f_refraction_index) : f_refraction_index;
			vec3 unit_direction = unit_vector(r_in.dir);
			double cos_theta = dot(-unit_direction, rec.normal);
			if (cos_theta > 1.0) cos_theta = 1.0;
			double sin_theta = util::sqrt(1.0 - cos_theta*cos_theta);
			bool cannot_refract = ri * sin_theta > 1.0;
			vec3 direction;

			double r0 = (1 - ri) / (1 + ri);
			r0 = r0*r0;
			double omc = 1.0 - cos_theta;
			omc = omc*omc*omc*omc*omc;
			double reflectance = r0 + (1-r0)*omc;

			if (cannot_refract || reflectance > util::random_float(seed)) direction = unit_direction - 2*dot(unit_direction,rec.normal)*rec.normal;
			else direction = util::refract(unit_direction, rec.normal, ri);

			scattered = ray(rec.p, direction, r_in.tm);
			return true;
		}
	}

	return false;
}

__host__ __device__ vec3 material::emission(const ray& r_in, const hit_record& rec, vec3& attenuation, ray& scattered, uint32_t& seed) {
	switch (e_type) {
		case light: {
			return v_albedo;
		}
	};

	return vec3(0.0, 0.0, 0.0);
}

#endif
