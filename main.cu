#include "vec3.h"
#include "ray.h"
#include "sphere.h"
#include "settings.h"
#include "camera.h"
#include "material.h"
#include "scene.h"
#include "render.h"
#include "examples.h"

int main() {
	cudaFree(0);

	camera cam;
	scene world;
	uint32_t seed = 0;

	cornell_box(cam, world, seed);

	raytrace(world, cam, seed, "images/image2.png");

	return 0;
}
