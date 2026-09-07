#ifndef SETTINGS_H
#define SETTINGS_H

#include <cuda_runtime_api.h>
#include <memory.h>
#include <cstdlib>
#include <ctime>
#include <cstring>
#include <stdio.h>
#include <cuda/cmath>
#include <iostream>
#include <chrono>
#include <random>
#include <cmath>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <filesystem>

#include "lodepng.h"

#define WIDTH 400
#define HEIGHT 225
#define SAMPLES_PER_PIXEL 10;

#define num_threads 256

#define stack_size 8192

#define PI 3.14159265358979

namespace util {

__host__ __device__ inline float sqrt(float x) {
#ifdef __CUDA_ARCH__
	return __fsqrt_rn(x);
#else
	return std::sqrt(x);
#endif
}

__host__ __device__ inline float abs(float x) {
#ifdef __CUDA_ARCH__
	return fabsf(x);
#else
	return std::fabs(x);
#endif
}

__host__ __device__ inline float tan(float x) {
#ifdef __CUDA_ARCH__
	return tanf(x);
#else
	return std::tan(x);
#endif
}

__device__ uint32_t inline pcg_hash(uint32_t input) {
	uint32_t state = input * 747796405u + 2891336453u;
	uint32_t word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
	return (word >> 22u) ^ word;
}

__host__ __device__ inline float random_float(uint32_t& seed) {
#ifdef __CUDA_ARCH__
	seed = pcg_hash(seed);
	return seed * (1.0f / 4294967296.0f);
#else
	static std::uniform_real_distribution<float> distribution(0.0, 1.0);
	static std::mt19937 generator;
	return distribution(generator);
#endif
}

__host__ __device__ inline float random_float(uint32_t& seed, float min, float max) {
	return min + (max-min)*random_float(seed);
}

__host__ __device__ inline float clamp(float x, float min, float max) {
	if (x < min) return min;
	if (x > max) return max;
	return x;
}

inline float linear_to_gamma(float linear_component) {
	if (linear_component > 0) return std::sqrt(linear_component);
	return 0;
}

}

#endif
