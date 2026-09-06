#include "mesh.cuh"

triangle::triangle() = default;

triangle::triangle(int v0_, int v1_, int v2_, vec3 n) {
    v0 = v0_;
    v1 = v1_;
    v2 = v2_;
    normal = n;
}

void vec_mesh::load_obj(const std::string& filename) {
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

void vec_mesh::set_bounding_box() {
	vec3 bound_min = vertices[0];
	vec3 bound_max = vertices[0];
	for (vec3& v : vertices) {
		bound_min.x = std::fmin(bound_min.x, v.x);
		bound_min.y = std::fmin(bound_min.y, v.y);
		bound_min.z = std::fmin(bound_min.z, v.z);
		bound_max.x = std::fmax(bound_max.x, v.x);
		bound_max.y = std::fmax(bound_max.y, v.y);
		bound_max.z = std::fmax(bound_max.z, v.z);
	}
	
    bounding_box.bounds[0] = bound_min;
	bounding_box.bounds[1] = bound_max;
}

void vec_mesh::set_normals() {
    for (triangle& t : triangles) {
        vec3 e1 = vertices[t.v1] - vertices[t.v0];
        vec3 e2 = vertices[t.v2] - vertices[t.v0];
        t.normal = unit_vector(cross(e1, e2));
    }
}

__host__ __device__ bool mesh::hit_triangle(const triangle& tri, const vec3* vertices, const ray& r, float ray_tmin, float ray_tmax, hit_record& rec) {
    vec3 e1 = vertices[tri.v1] - vertices[tri.v0];
    vec3 e2 = vertices[tri.v2] - vertices[tri.v0];
    if (dot(tri.normal, r.dir) > 0.0f) return false;

    vec3 ray_cross_e2 = cross(r.dir, e2);
    float denom = dot(e1, ray_cross_e2);

    if (util::abs(denom) < 1e-6f) return false;

    float inv_denom = 1.0f / denom;
    vec3 s = r.orig - vertices[tri.v0];
    float u = inv_denom * dot(s, ray_cross_e2);

    if (u < -1e-6f || u-1.0f > 1e-6f) return false;

    vec3 s_cross_e1 = cross(s, e1);
    float v = inv_denom * dot(r.dir, s_cross_e1);

    if (v < -1e-6f || u+v-1.0f > 1e-6f) return false;

    float t = inv_denom * dot(e2, s_cross_e1);

    if (t > ray_tmin && t < ray_tmax) {
        rec.t = t;
        rec.p = r.at(t);
        rec.set_face_normal(r, unit_vector(tri.normal));
        rec.mat = &mat;
        return true;
    }

    return false;
}

__host__ __device__ bool mesh::hit(const ray& r, const vec3* vertices, const triangle* triangles, float ray_tmin, float ray_tmax, hit_record& rec) {
    if (!bounding_box.hit(r, ray_tmin, ray_tmax)) return false;

    hit_record temp_rec;
    bool hit_anything = false;
    float closest_so_far = ray_tmax;

    for (int t = 0; t < num_triangles; t++) {
        if (hit_triangle(triangles[triangles_start+t], vertices, r, ray_tmin, closest_so_far, temp_rec)) {
            hit_anything = true;
            closest_so_far = temp_rec.t;
            rec = temp_rec;
        }
    }

    return hit_anything;
}

__host__ __device__ bool mesh_list::hit(const ray& r, float ray_tmin, float ray_tmax, hit_record& rec) const {
    hit_record temp_rec;
    bool hit_anything = false;
    float closest_so_far = ray_tmax;

    for (int m = 0; m < num_meshes; m++) {
        if (meshes[m].hit(r, vertices, triangles, ray_tmin, closest_so_far, temp_rec)) {
            hit_anything = true;
            closest_so_far = temp_rec.t;
            rec = temp_rec;
        }
    }

    return hit_anything;
}
