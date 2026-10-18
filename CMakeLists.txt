cmake_minimum_required(VERSION 3.18)

project(RayTracer LANGUAGES CXX CUDA)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CUDA_STANDARD 20)
set(CMAKE_CUDA_ARCHITECTURES 89)

add_executable(raytracer src/main.cu src/box.cu src/bvh.cu src/camera.cu src/hit_record.cu src/material.cu src/mesh.cu src/plane.cu src/sphere.cu src/scene.cu src/vec_mesh.cu src/lodepng.cpp)

set_target_properties(raytracer PROPERTIES CUDA_SEPARABLE_COMPILATION ON)

target_compile_options(raytracer PRIVATE $<$<COMPILE_LANGUAGE:CUDA>:-O3>)
