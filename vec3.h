#ifndef VEC3_H
#define VEC3_H

#include <cmath>
#include "settings.h"

struct vec3 {
	float x, y, z;

	__host__ __device__ vec3() {
		x = 0.0; y = 0.0; z = 0.0;
	}

	__host__ __device__ vec3(float x_, float y_, float z_) {
		x = x_; y = y_; z = z_;
	}

	__host__ __device__ vec3 operator-() const {
		return vec3(-x, -y, -z);
	}

	__host__ __device__ vec3& operator+=(const vec3& v) {
		x += v.x; y += v.y; z += v.z;
		return *this;
	}

	__host__ __device__ vec3& operator*=(float t) {
		x *= t; y *= t; z *= t;
		return *this;
	}

	__host__ __device__ vec3& operator/=(float t) {
		return *this *= 1/t;
	}

	__host__ __device__ float length_squared() const {
		return x*x + y*y + z*z;
	}

	__host__ __device__ float length() const {
		return util::sqrt(length_squared());
	}
};

__host__ __device__ inline vec3 operator+(const vec3& u, const vec3& v) {
	return vec3(u.x+v.x, u.y+v.y, u.z+v.z);
}

__host__ __device__ inline vec3 operator-(const vec3& u, const vec3& v) {
	return vec3(u.x-v.x, u.y-v.y, u.z-v.z);
}

__host__ __device__ inline vec3 operator*(const vec3& u, const vec3& v) {
	return vec3(u.x*v.x, u.y*v.y, u.z*v.z);
}

__host__ __device__ inline vec3 operator*(const vec3& v, float t) {
	return vec3(v.x*t, v.y*t, v.z*t);
}

__host__ __device__ inline vec3 operator*(float t, const vec3& v) {
	return v * t;
}

__host__ __device__ inline vec3 operator/(const vec3& v, float t) {
	return (1/t) * v;
}

__host__ __device__ inline float dot(const vec3& u, const vec3& v) {
	return u.x*v.x + u.y*v.y + u.z*v.z;
}

__host__ __device__ inline vec3 cross(const vec3& u, const vec3& v) {
	return vec3(u.y*v.z-u.z*v.y, u.z*v.x-u.x*v.z, u.x*v.y-u.y*v.x);
}

__host__ __device__ inline vec3 unit_vector(const vec3& v) {
	return v / v.length();
}

namespace util {

__host__ __device__ inline vec3 random_unit_vector(uint32_t& seed) {
	while (true) {
		vec3 p;
		p.x = random_float(seed, -1.0, 1.0);
		p.y = random_float(seed, -1.0, 1.0);
		p.z = random_float(seed, -1.0, 1.0);
		float lensq = p.length_squared();
		if (lensq > 1e-80 && lensq <= 1) return unit_vector(p);
	}
}

__host__ __device__ inline vec3 random_on_hemisphere(uint32_t& seed, const vec3& normal) {
	vec3 on_unit_sphere = random_unit_vector(seed);
	if (dot(on_unit_sphere, normal) > 0.0) return on_unit_sphere;
	else return -on_unit_sphere;
}

__host__ __device__ inline vec3 random_in_unit_disk(uint32_t& seed) {
	while (true) {
		vec3 p(random_float(seed, -1.0, 1.0), random_float(seed, -1.0, 1.0), 0.0);
		if (p.length_squared() < 1) return p;
	}
}

__host__ __device__ inline vec3 refract(const vec3& uv, const vec3& n, double etai_over_etat) {
	double cos_theta = dot(-uv, n);
	if (cos_theta > 1.0) cos_theta = 1.0;
	vec3 r_out_perp = etai_over_etat*(uv+cos_theta*n);
	vec3 r_out_parallel = -sqrt(abs(1.0-r_out_perp.length_squared()))*n;
	return r_out_perp + r_out_parallel;
}

}

#endif
