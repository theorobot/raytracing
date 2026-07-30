#ifndef MESH_H
#define MESH_H

#include "vec3.h"
#include "ray.h"
#include "box.h"
#include "settings.h"

struct triangle {
	int v0, v1, v2;

	triangle() = default;

	triangle(int v0_, int v1_, int v2_) {
		v0 = v0_;
		v1 = v1_;
		v2 = v2_;
	}
};

struct vec_mesh {
	std::vector<vec3> vertices;
	std::vector<triangle> triangles;
	std::vector<vec3> normals;
	material mat;
	box bounding_box;

	void load_obj(const std::string& filename) {
		std::ifstream file(filename);
		if (!file.is_open()) {
			std::cerr << "Could not open file '" << filename << "'\n";
			return;
		}

		std::string line;
		while (std::getline(file, line)) {
			if (line.empty()) continue;

			std::stringstream ss(line);
			std::string type;
			ss >> type;

			if (type == "v") {
				vec3 v;
				ss >> v.x >> v.y >> v.z;
				vertices.push_back(v);
			} else if (type == "f") {
				triangle t;
				ss >> t.v0 >> t.v1 >> t.v2;
				t.v0--; t.v1--; t.v2--;

				triangles.push_back(t);
			}
		}

		set_bounding_box();
		set_normals();
	}

	void set_bounding_box() {
		float xmin, ymin, zmin = 1000000.0f;
		float xmax, ymax, zmax = -1000000.0f;
		for (vec3& v : vertices) {
			xmin = std::fmin(xmin, v.x);
			ymin = std::fmin(ymin, v.y);
			zmin = std::fmin(zmin, v.z);
			xmax = std::fmax(xmax, v.x);
			ymax = std::fmax(ymax, v.y);
			zmax = std::fmax(zmax, v.z);
		}

		bounding_box.bounds[0] = vec3(xmin-0.01, ymin-0.01, zmin-0.01);
		bounding_box.bounds[1] = vec3(xmax+0.01, ymax+0.01, zmax+0.01);
	}

	void set_normals() {
		normals.resize(triangles.size());
		for (int t = 0; t < triangles.size(); t++) {
			vec3 e1 = vertices[triangles[t].v1] - vertices[triangles[t].v0];
			vec3 e2 = vertices[triangles[t].v2] - vertices[triangles[t].v0];
			normals[t] = unit_vector(cross(e1, e2));
		}
	}
};

struct mesh {
	vec3* vertices;
	triangle* triangles;
	vec3* normals;
	int num_vertices;
	int num_triangles;
	material mat;
	box bounding_box;

	__host__ __device__ bool hit_triangle(const triangle& tri, const vec3& normal, const ray& r, float ray_tmin, float ray_tmax, hit_record& rec) {
		vec3 e1 = vertices[tri.v1] - vertices[tri.v0];
		vec3 e2 = vertices[tri.v2] - vertices[tri.v0];
		if (dot(normal, r.dir) > 0.0) return false;

		vec3 ray_cross_e2 = cross(r.dir, e2);
		float denom = dot(e1, ray_cross_e2);

		if (util::abs(denom) < 1e-6) return false;

		float inv_denom = 1.0 / denom;
		vec3 s = r.orig - vertices[tri.v0];
		float u = inv_denom * dot(s, ray_cross_e2);

		if (u < -1e-6 || u-1 > 1e-6) return false;

		vec3 s_cross_e1 = cross(s, e1);
		float v = inv_denom * dot(r.dir, s_cross_e1);

		if (v < -1e-6 || u+v-1 > 1e-6) return false;

		float t = inv_denom * dot(e2, s_cross_e1);

		if (t > ray_tmin && t < ray_tmax) {
			rec.t = t;
			rec.p = r.at(t);
			rec.set_face_normal(r, unit_vector(normal));
			rec.mat = &mat;
			return true;
		}

		return false;
	}

	__host__ __device__ bool hit(const ray& r, float ray_tmin, float ray_tmax, hit_record& rec) {
		if (!bounding_box.hit(r, ray_tmin, ray_tmax)) return false;

		hit_record temp_rec;
		bool hit_anything = false;
		float closest_so_far = ray_tmax;

		for (int t = 0; t < num_triangles; t++) {
			if (hit_triangle(triangles[t], normals[t], r, ray_tmin, closest_so_far, temp_rec)) {
				hit_anything = true;
				closest_so_far = temp_rec.t;
				rec = temp_rec;
			}
		}

		return hit_anything;
	}
};

struct mesh_list {
	mesh* meshes;
	int num_meshes;

	__host__ __device__ bool hit(const ray& r, float ray_tmin, float ray_tmax, hit_record& rec) const {
		hit_record temp_rec;
		bool hit_anything = false;
		float closest_so_far = ray_tmax;

		for (int m = 0; m < num_meshes; m++) {
			if (meshes[m].hit(r, ray_tmin, closest_so_far, temp_rec)) {
				hit_anything = true;
				closest_so_far = temp_rec.t;
				rec = temp_rec;
			}
		}

		return hit_anything;
	}
};

#endif
