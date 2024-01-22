package main

import "core:math/linalg"

// Single file portable rect utils.
// All the Vec4 is represented as (x, y, width, height). xy is left-top.

@(private="file")
Vec4:: linalg.Vector4f32