cmake_minimum_required(VERSION 3.18)

project(RayTracer LANGUAGES CXX CUDA)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_ARCHITECTURES 89)

add_executable(raytracer src/main.cu src/lodepng.cpp)

target_compile_options(raytracer PRIVATE $<$<COMPILE_LANGUAGE:CUDA>:-O3>)
