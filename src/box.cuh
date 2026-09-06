#ifndef BOX_H
#define BOX_H

#include "vec3.h"
#include "ray.h"

struct box {
    vec3 bounds[2];

    box();
    box(const vec3& min, const vec3& max);
    
    __host__ __device__ bool hit(const ray& r, float ray_tmin, float ray_tmax) const;
};

#endif
