#include "vec_mesh.cuh"

triangle::triangle() = default;

triangle::triangle(int v0_, int v1_, int v2_, vec3 n) {
    v0 = v0_;
    v1 = v1_;
    v2 = v2_;
    normal = n;
}

box triangle::bounding_box(std::vector<vec3> v) {
    box bbox;
    bbox.bounds[0].x = std::fmin(std::fmin(v[v0].x, v[v1].x), v[v2].x);
    bbox.bounds[0].y = std::fmin(std::fmin(v[v0].y, v[v1].y), v[v2].y);
    bbox.bounds[0].z = std::fmin(std::fmin(v[v0].z, v[v1].z), v[v2].z);
    bbox.bounds[1].x = std::fmax(std::fmax(v[v0].x, v[v1].x), v[v2].x);
    bbox.bounds[1].y = std::fmax(std::fmax(v[v0].y, v[v1].y), v[v2].y);
    bbox.bounds[1].z = std::fmax(std::fmax(v[v0].z, v[v1].z), v[v2].z);
    return bbox;
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
