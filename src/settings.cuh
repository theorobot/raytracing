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
#include <iomanip>
#include <chrono>
#include <random>
#include <cmath>
#include <fstream>
#include <format>
#include <sstream>
#include <string>
#include <vector>
#include <filesystem>
#include <algorithm>

#include <sys/ioctl.h>
#include <unistd.h>

#include "lodepng.h"

#define WIDTH 400
#define HEIGHT 225
#define SAMPLES_PER_PIXEL 10;

#define NUM_THREADS 256

#define STACK_SIZE 8192

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

inline void print_progress_bar(int sample_num, int samples_per_pixel, double time_taken, int bar_width) {
    float progress = (float)sample_num / samples_per_pixel;

    winsize ws{};
    int terminal_width = 80;

    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0 && ws.ws_col > 0) {
        terminal_width = ws.ws_col;
    }

    int digits = std::to_string(samples_per_pixel).length();

    int fixed_width = 2*digits + 42;

    bar_width = std::max(0, std::min(bar_width, terminal_width - fixed_width));

    int pos = (int)(bar_width * progress);

    std::cout << "\r\033[1;31m|";
    for (int i = 0; i < bar_width; i++) {
        if (i < pos) std::cout << "\u2588";
        else std::cout << ' ';
    }

    std::cout << "| \033[0m";
    std::cout << std::format("{:3d}%", (int)(progress*100));
    std::cout << " | " << std::format("{:0{}}", sample_num, digits) << "/" << samples_per_pixel;
    std::cout << " | " << std::format("{:.2f}", time_taken) << "s";

    double remaining = time_taken / progress - time_taken;

    std::cout << " | ETA: " << std::format("{:.2f}", remaining) << "s\033[K";

    std::cout.flush();
}

}

#endif
