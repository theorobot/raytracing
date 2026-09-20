#ifndef BVH_H
#define BVH_H

#include "vec3.cuh"
#include "ray.cuh"
#include "box.cuh"
#include "vec_mesh.cuh"

struct bvh_node {
    box bounds;
    int left_idx;
    int right_idx;
    int firstTri;
    int triCount;

    bvh_node();
    bvh_node(box b);
    bvh_node(box b, int tri_num);
};

std::vector<bvh_node> createBVH(vec_mesh& vm);
box bvh_bounding_box(bvh_node node, vec_mesh& vm);
void divideBVH(int bvh_idx, std::vector<bvh_node>& bvh, vec_mesh& vm);

#endif
