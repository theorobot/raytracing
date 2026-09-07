#include "vec3.cuh"
#include "ray.cuh"
#include "sphere.cuh"
#include "settings.cuh"
#include "scene.cuh"
#include "render.cuh"
#include "examples.cuh"

int main() {
	cudaFree(0);

	camera cam;
	scene world;
	uint32_t seed = 0;

	cornell_box(cam, world, seed);

	raytrace(world, cam, seed, "renders/image.png");

	return 0;
}
