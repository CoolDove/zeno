package main

import "core:math/linalg"
import "core:math"
import "core:fmt"

PaintCurve :: struct {
    raw_points : [dynamic]PaintCurvePoint,// xy:position, z:pressure
    lengths : [dynamic]f32,
    idx : i32,
    t : f32,
}
PaintCurvePoint :: struct {
    position : Vec2,
    pressure : f32,
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
    append(&raw_points, PaintCurvePoint{pos, pressure})
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
            // t = paintcurve_length(curve)
            t -= dt
            idx -= 1
            return false
        }
    }
    return true
}

paintcurve_get :: proc(using curve: ^PaintCurve) -> (PaintCurvePoint, bool) {
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
    return {
        linalg.lerp(from.position, to.position, interp), 
        linalg.lerp(from.pressure, to.pressure, interp)}, true
}