#include "bvh.cuh"

bvh_node::bvh_node() = default;

bvh_node::bvh_node(box b) {
    bounds = b;
    left_idx = 0;
    right_idx = 0;
    firstTri = 0;
    triCount = 0;
}

bvh_node::bvh_node(box b, int tri_num) {
    bounds = b;
    left_idx = 0;
    right_idx = 0;
    firstTri = tri_num;
    triCount = 0;
}

box bvh_bounding_box(bvh_node node, vec_mesh& vm) {
    box bbox = vm.triangles[node.firstTri].bounding_box(vm.vertices);
    for (int i = 0; i < node.triCount; i++) {
        box tri_bbox = vm.triangles[node.firstTri+i].bounding_box(vm.vertices);
        bbox.bounds[0].x = std::fmin(bbox.bounds[0].x, tri_bbox.bounds[0].x);
        bbox.bounds[0].y = std::fmin(bbox.bounds[0].y, tri_bbox.bounds[0].y);
        bbox.bounds[0].z = std::fmin(bbox.bounds[0].z, tri_bbox.bounds[0].z);
        bbox.bounds[1].x = std::fmax(bbox.bounds[1].x, tri_bbox.bounds[1].x);
        bbox.bounds[1].y = std::fmax(bbox.bounds[1].y, tri_bbox.bounds[1].y);
        bbox.bounds[1].z = std::fmax(bbox.bounds[1].z, tri_bbox.bounds[1].z);
    }

    return bbox;
}

std::vector<bvh_node> createBVH(vec_mesh& vm) {
    std::vector<bvh_node> bvh;
    bvh_node head;
    head.left_idx = -1;
    head.right_idx = -1;
    head.firstTri = 0;
    head.triCount = vm.triangles.size();
    head.bounds = bvh_bounding_box(head, vm);
    bvh.push_back(head);
    divideBVH(0, bvh, vm);
    return bvh;
}

void divideBVH(int bvh_idx, std::vector<bvh_node>& bvh, vec_mesh& vm) {
    if (bvh[bvh_idx].triCount <= 3) return;

    float x_len = bvh[bvh_idx].bounds.bounds[1].x - bvh[bvh_idx].bounds.bounds[0].x;
    float y_len = bvh[bvh_idx].bounds.bounds[1].y - bvh[bvh_idx].bounds.bounds[0].y;
    float z_len = bvh[bvh_idx].bounds.bounds[1].z - bvh[bvh_idx].bounds.bounds[0].z;
    int longest_axis = 0;
    if (y_len > x_len) {
        longest_axis = 1;
        if (z_len > y_len) {
            longest_axis = 2;
        }
    } else if (z_len > x_len) {
        longest_axis = 2;
    }

    int i = bvh[bvh_idx].firstTri;
    int j = bvh[bvh_idx].firstTri + bvh[bvh_idx].triCount - 1;
    while (i <= j) {
        triangle tri = vm.triangles[i];
        box tri_box = tri.bounding_box(vm.vertices);
        if (longest_axis == 0) {
            float center = (tri_box.bounds[0].x + tri_box.bounds[1].x) / 2.0f;
            if (center < bvh[bvh_idx].bounds.bounds[0].x + x_len / 2.0f) {
                i++;
            } else {
                std::swap(vm.triangles[i], vm.triangles[j]);
                j--;
            }
        } else if (longest_axis == 1) {
            float center = (tri_box.bounds[0].y + tri_box.bounds[1].y) / 2.0f;
            if (center < bvh[bvh_idx].bounds.bounds[0].y + y_len / 2.0f) {
                i++;
            } else {
                std::swap(vm.triangles[i], vm.triangles[j]);
                j--;
            }
        } else {
            float center = (tri_box.bounds[0].z + tri_box.bounds[1].z) / 2.0f;
            if (center < bvh[bvh_idx].bounds.bounds[0].z + z_len / 2.0f) {
                i++;
            } else {
                std::swap(vm.triangles[i], vm.triangles[j]);
                j--;
            }
        }
    }

    bvh_node left_node;
    left_node.left_idx = -1;
    left_node.right_idx = -1;
    left_node.firstTri = bvh[bvh_idx].firstTri;
    left_node.triCount = i - bvh[bvh_idx].firstTri;
    if (left_node.triCount == 0 || left_node.triCount == bvh[bvh_idx].triCount) return;
    left_node.bounds = bvh_bounding_box(left_node, vm);
    bvh.push_back(left_node);
    bvh[bvh_idx].left_idx = bvh.size()-1;
    bvh_node right_node;
    right_node.left_idx = -1;
    right_node.right_idx = -1;
    right_node.firstTri = i;
    right_node.triCount = bvh[bvh_idx].firstTri + bvh[bvh_idx].triCount - i;
    right_node.bounds = bvh_bounding_box(right_node, vm);
    bvh.push_back(right_node);
    bvh[bvh_idx].right_idx = bvh.size()-1;
    divideBVH(bvh[bvh_idx].left_idx, bvh, vm);
    divideBVH(bvh[bvh_idx].right_idx, bvh, vm);
}
