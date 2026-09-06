#include "vec3.h"
#include "ray.h"
#include "sphere.cuh"
#include "settings.h"
#include "scene.cuh"
#include "render.h"
#include "examples.h"

int main() {
	cudaFree(0);

	camera cam;
	scene world;
	uint32_t seed = 0;

	cornell_box(cam, world, seed);

	raytrace(world, cam, seed, "renders/image.png");

	return 0;
}
