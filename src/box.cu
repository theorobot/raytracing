#include "box.cuh"

box::box() {
    bounds[0] = vec3(0.0f, 0.0f, 0.0f);
    bounds[1] = vec3(0.0f, 0.0f, 0.0f);
}

box::box(const vec3& min, const vec3& max) {
    bounds[0] = min;
    bounds[1] = max;
}

__host__ __device__ bool box::hit(const ray& r, float ray_tmin, float ray_tmax) const {
	float tmin, tmax, tymin, tymax, tzmin, tzmax;
	/* float divx = 1.0f / r.dir.x;
    float divy = 1.0f / r.dir.y;
    float divz = 1.0f / r.dir.z; */
	if (r.dir.x >= 0.0f) {
		tmin = (bounds[0].x - r.orig.x) * r.dir_rec.x;
		tmax = (bounds[1].x - r.orig.x) * r.dir_rec.x;
	} else {
		tmin = (bounds[1].x - r.orig.x) * r.dir_rec.x;
		tmax = (bounds[0].x - r.orig.x) * r.dir_rec.x;
	}
	if (r.dir.y >= 0.0f) {
		tymin = (bounds[0].y - r.orig.y) * r.dir_rec.y;
		tymax = (bounds[1].y - r.orig.y) * r.dir_rec.y;
	} else {
		tymin = (bounds[1].y - r.orig.y) * r.dir_rec.y;
		tymax = (bounds[0].y - r.orig.y) * r.dir_rec.y;
	}
	if ((tmin > tymax) || (tymin > tmax)) return false;
	if (tymin > tmin) tmin = tymin;
	if (tymax < tmax) tmax = tymax;
	if (r.dir.z >= 0.0f) {
		tzmin = (bounds[0].z - r.orig.z) * r.dir_rec.z;
		tzmax = (bounds[1].z - r.orig.z) * r.dir_rec.z;
	} else {
		tzmin = (bounds[1].z - r.orig.z) * r.dir_rec.z;
		tzmax = (bounds[0].z - r.orig.z) * r.dir_rec.z;
	}
	if ((tmin > tzmax) || (tzmin > tmax)) return false;
	if (tzmin > tmin) tmin = tzmin;
	if (tzmax < tmax) tmax = tzmax;
	return ((tmin < ray_tmax) && (tmax > ray_tmin));
}
