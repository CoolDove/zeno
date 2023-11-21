package main

import "core:math/linalg"
import "core:mem"
import "core:slice"
import "core:math"
import "core:log"
import "core:time"
import "core:fmt"
import "core:reflect"
import "core:runtime"
import "core:strings"

StatePhase :: enum {
    Enter, Update, Exit,
}

Vector2i :: #type Vec2i
Vector3i :: #type Vec3i
Vector4i :: #type Vec4i

vec_i2f :: proc {
    vec_i2f_2,
    vec_i2f_3,
    vec_i2f_4,
}
vec_f2i :: proc {
    vec_f2i_2,
    vec_f2i_3,
    vec_f2i_4,
}

vec_i2f_2 :: #force_inline proc "contextless" (input: Vector2i) -> linalg.Vector2f32 {
    return { cast(f32)input.x, cast(f32)input.y }
}
vec_i2f_3 :: #force_inline proc "contextless" (input: Vector3i) -> linalg.Vector3f32 {
    return { cast(f32)input.x, cast(f32)input.y, cast(f32)input.z }
}
vec_i2f_4 :: #force_inline proc "contextless" (input: Vector4i) -> linalg.Vector4f32 {
    return { cast(f32)input.x, cast(f32)input.y, cast(f32)input.z, cast(f32)input.w }
}

vec_f2i_2 :: #force_inline proc "contextless" (input: linalg.Vector2f32, method: RoundingMethod = .Floor) -> Vector2i {
    switch method {
    case .Floor: return { cast(i32)input.x, cast(i32)input.y }
    case .Ceil: return { cast(i32)math.ceil(input.x), cast(i32)math.ceil(input.y) }
    case .Nearest: return { cast(i32)math.round(input.x), cast(i32)math.round(input.y) }
    }
    return {}
}
vec_f2i_3 :: #force_inline proc "contextless" (input: linalg.Vector3f32, method: RoundingMethod = .Floor) -> Vector3i {
    switch method {
    case .Floor: return { cast(i32)input.x, cast(i32)input.y, cast(i32)input.z }
    case .Ceil: return { cast(i32)math.ceil(input.x), cast(i32)math.ceil(input.y), cast(i32)math.ceil(input.z)}
    case .Nearest: return { cast(i32)math.round(input.x), cast(i32)math.round(input.y), cast(i32)math.round(input.z) }
    }
    return {}
}
vec_f2i_4 :: #force_inline proc "contextless" (input: linalg.Vector4f32, method: RoundingMethod = .Floor) -> Vector4i {
    switch method {
    case .Floor: return { cast(i32)input.x, cast(i32)input.y, cast(i32)input.z, cast(i32)input.w, }
    case .Ceil: return { cast(i32)math.ceil(input.x), cast(i32)math.ceil(input.y), cast(i32)math.ceil(input.z), cast(i32)math.ceil(input.w)}
    case .Nearest: return { cast(i32)math.round(input.x), cast(i32)math.round(input.y), cast(i32)math.round(input.z), cast(i32)math.round(input.w) }
    }
    return {}
}


color_u2f :: proc(color : [4]u8) -> [4]f32 {
    return {cast(f32)color.x/255.0, cast(f32)color.y/255.0, cast(f32)color.z/255.0, cast(f32)color.w/255.0}
}

RoundingMethod :: enum {
    Floor, Ceil, Nearest,
}

enum_step :: proc($E: typeid, value: E) -> E {
    values := reflect.enum_field_values(typeid_of(E))
    for v, idx in values {
        if transmute(reflect.Type_Info_Enum_Value)value == v {
            if idx == len(values) - 1 do return transmute(E)values[0]
            else do return transmute(E)values[idx + 1]
        }
    }
    return {}
}

readable_format_bytes :: proc(bytes_count: int, allocator:=context.allocator) -> string {
    context.allocator = allocator;
    kb := cast(f64)(bytes_count % 1024.0)/1024.0 + cast(f64)(bytes_count/1024.0);
    mb := kb / 1024.0;
    gb := mb / 1024.0;

    value : f64;
    unit  : string;

    if kb < 1.0 {
        value = f64(bytes_count);
        unit = "Bytes";
    } else if kb < 1024.0 {
        value = kb;
        unit = "KB";
    } else if mb < 1024.0 {
        value = mb;
        unit = "MB";
    } else {
        value = gb;
        unit = "GB";
    }
    
    return fmt.aprintf("% 8.3f %s", value, unit);
}


// Strings
string_bytes :: proc(str: string) -> []byte {
    rstr := transmute(runtime.Raw_String)str
    return rstr.data[0:rstr.len]
}

sb_reset :: proc(sb: ^strings.Builder, content: string) {
    using strings
    builder_reset(sb)
    write_string(sb, content)
}


ActionProcess :: struct {
    process : proc(data: rawptr),
    data : rawptr,
}
execute_process :: proc(process: ActionProcess) {
    process.process(process.data)
}