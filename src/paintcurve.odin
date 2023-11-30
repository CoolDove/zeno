package main

import "core:math/linalg"
import "core:math"
import "core:fmt"

PaintCurve :: struct {
    raw_points : [dynamic]PaintCurvePoint,// xy:position, z:pressure
    lengths : [dynamic]f32,
    idx : i32,
    t : f32,

    last_sampled_angle : f32,// Used to smooth the rotation.
}
PaintCurvePoint :: struct {
    position : Vec2,
    pressure : f32,
    angle : f32,
}

paintcurve_init :: proc(using pcurve: ^PaintCurve) {
    raw_points = make([dynamic]PaintCurvePoint, 512)
    lengths = make([dynamic]f32, 512)
}
paintcurve_release :: proc(using pcurve: ^PaintCurve) {
    delete(raw_points)
    delete(lengths)
}
paintcurve_clear :: proc(using pcurve: ^PaintCurve) {
    clear(&raw_points)
    clear(&lengths)
    idx = 0
    t = 0
}
paintcurve_length :: proc(using pcurve: ^PaintCurve) -> f32 {
    return lengths[len(lengths)-1]
}

paintcurve_append :: proc(using curve: ^PaintCurve, pos: Vec2, pressure: f32) {
    append(&raw_points, PaintCurvePoint{pos, pressure, 0})
    if len(lengths) > 0 {
        last := raw_points[len(raw_points)-2].position
        l := linalg.distance(pos, Vec2{last.x, last.y})
        append(&lengths, l+lengths[len(lengths)-1])
    } else {
        append(&lengths, 0)
    }
}


// return: continuable
paintcurve_step :: #force_inline proc(using curve: ^PaintCurve, dt: f32) -> bool {
    t += dt
    for t > lengths[idx] {
        idx += 1
        if auto_cast idx > len(lengths)-1 {
            t -= dt
            idx -= 1
            return false
        }
    }
    return true
}

paintcurve_get :: proc(using curve: ^PaintCurve) -> (PaintCurvePoint, bool) {
    assert(len(raw_points) > 0, "PaintCurve: No points to sample.")
    if len(raw_points) == 0 {
        return {}, false
    } else {
        if t < 0 do return raw_points[0], true
        else if t > lengths[len(lengths)-1] do return raw_points[len(raw_points)-1], false
    }
    l := lengths[idx]
    ld := lengths[idx-1]
    interp := (t - ld)/(l - ld)
    from, to := raw_points[idx-1], raw_points[idx]
    angle := linalg.dot(Vec2{0,1}, linalg.normalize(to.position - from.position))
    angle = linalg.acos(angle)
    last_sampled_angle = linalg.lerp(last_sampled_angle, angle, 0.8)
    return {
        linalg.lerp(from.position, to.position, interp), 
        linalg.lerp(from.pressure, to.pressure, interp),
        last_sampled_angle}, true
}