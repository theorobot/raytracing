#include "material.cuh"
#include "hit_record.cuh"

material::material() = default;

material::material(mat_type type, vec3 albedo, float fuzz, float refraction_index) {
    e_type = type;
    v_albedo = albedo;
    f_fuzz = fuzz;
    f_refraction_index = refraction_index;
}

void material::set_lambertian(vec3 albedo) {
    e_type = lambertian;
    v_albedo = albedo;
}

void material::set_metal(vec3 albedo, float fuzz) {
    e_type = metal;
    v_albedo = albedo;
    f_fuzz = fuzz;
}

void material::set_dielectric(vec3 albedo, float refraction_index) {
    e_type = dielectric;
    v_albedo = albedo;
    f_refraction_index = refraction_index;
}

void material::set_light(vec3 albedo) {
    e_type = light;
    v_albedo = albedo;
}

__host__ __device__ bool material::scatter(const ray& r_in, const hit_record& rec, vec3& attenuation, ray& scattered, uint32_t& seed) {
	switch (e_type) {
		case lambertian: {
			vec3 scatter_direction = rec.normal + util::random_unit_vector(seed);
			scattered = ray(rec.p, scatter_direction);
			attenuation = v_albedo;
			return true;
		}

		case metal: {
			vec3 reflected = r_in.dir - 2.0f*dot(r_in.dir, rec.normal)*rec.normal;
			reflected = unit_vector(reflected) + (f_fuzz * util::random_unit_vector(seed));
			scattered = ray(rec.p, reflected);
			attenuation = v_albedo;
			return dot(scattered.dir, rec.normal) > 0.0f;
		}

		case dielectric: {
			attenuation = vec3(1.0f, 1.0f, 1.0f);
			float ri = rec.front_face ? (1.0f / f_refraction_index) : f_refraction_index;
			vec3 unit_direction = unit_vector(r_in.dir);
			float cos_theta = dot(-unit_direction, rec.normal);
			if (cos_theta > 1.0f) cos_theta = 1.0f;
			float sin_theta = util::sqrt(1.0f - cos_theta*cos_theta);
			bool cannot_refract = ri * sin_theta > 1.0f;
			vec3 direction;

			float r0 = (1.0f - ri) / (1.0f + ri);
			r0 = r0*r0;
			float omc = 1.0f - cos_theta;
			omc = omc*omc*omc*omc*omc;
			float reflectance = r0 + (1.0f-r0)*omc;

			if (cannot_refract || reflectance > util::random_float(seed)) direction = unit_direction - 2.0f*dot(unit_direction,rec.normal)*rec.normal;
			else direction = util::refract(unit_direction, rec.normal, ri);

			scattered = ray(rec.p, direction);
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

	return vec3(0.0f, 0.0f, 0.0f);
}
