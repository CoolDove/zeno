package main

import "core:fmt"
import gl "vendor:OpenGL"
import nvg "vendor:nanovg"

import "dgl"

SHADER_COMPOSE_DEFAULT : dgl.ShaderId
SHADER_COMPOSE_PIGMENT : dgl.ShaderId

TEXTURE_MIXBOX_LUT : u32

ComposeEngine :: struct {
    fbo : dgl.FramebufferId,
}

@(private="file")
_compose_engine : ComposeEngine


@(private="file")
_PigmentComposeUniforms :: struct {
    src_texture, dst_texture, mixbox_lut : dgl.UniformLocTexture,
}
@(private="file")
_pigment_compose_uniforms : _PigmentComposeUniforms

@(private="file")
_DefaultComposeUniforms :: struct {
    src_texture, dst_texture : dgl.UniformLocTexture,
}
@(private="file")
_default_compose_uniforms : _DefaultComposeUniforms

// This is stored in canvas.
CanvasComposeData :: struct {
    compose_result : u32,
    compose_above : u32,
    compose_below : u32,
    compose_brush : u32,
}

ComposeType :: enum {
    Default, Pigment,
}

compose_engine_init :: proc() {
    _compose_engine.fbo = dgl.framebuffer_create()
    {// Pigment
        shader_frag := dgl.shader_preprocess(_SHADER_COMPOSE_PIGMENT_FRAG); defer delete(shader_frag)
        SHADER_COMPOSE_PIGMENT = dgl.blit_make_blit_shader(shader_frag)
    }
    {// Default
        shader_frag := dgl.shader_preprocess(_SHADER_COMPOSE_DEFAULT_FRAG); defer delete(shader_frag)
        SHADER_COMPOSE_DEFAULT = dgl.blit_make_blit_shader(shader_frag)
    }

    dgl.uniform_load(&_pigment_compose_uniforms, SHADER_COMPOSE_PIGMENT)
    dgl.uniform_load(&_default_compose_uniforms, SHADER_COMPOSE_DEFAULT)

    TEXTURE_MIXBOX_LUT = dgl.texture_load_from_mem(#load("../res/mixbox_lut.png", []u8)).id
}
compose_engine_release :: proc() {
    gl.DeleteTextures(1, &TEXTURE_MIXBOX_LUT);
    gl.DeleteProgram(SHADER_COMPOSE_DEFAULT)
    gl.DeleteProgram(SHADER_COMPOSE_PIGMENT)
    dgl.framebuffer_destroy(_compose_engine.fbo)
}

compose_engine_init_canvas :: proc(using canvas: ^Canvas) {
    using compose, dgl
    w, h :int= auto_cast width, auto_cast height
    compose_result = texture_create_empty(w, h)
    compose_above = texture_create_empty(w, h)
    compose_below = texture_create_empty(w, h)
    compose_brush = texture_create_empty(w, h)
}
compose_engine_release_canvas :: proc(using canvas: ^Canvas) {
    using compose, dgl
    if compose_result != 0 do gl.DeleteTextures(3, &compose_result)
    compose = {}
}

compose_engine_compose_all :: proc(using canvas: ^Canvas) {
    using dgl
    rem_viewport := state_get_viewport(); defer state_set_viewport(rem_viewport)
    rem_fbo := framebuffer_current(); defer framebuffer_bind(rem_fbo)
    gl.Disable(gl.BLEND); defer gl.Enable(gl.BLEND)

    comp := &canvas.compose
    framebuffer_bind(_compose_engine.fbo)
    gl.Viewport(0,0,width,height)
    shader_bind(SHADER_COMPOSE_DEFAULT)
    bl, br := canvas_get_clean_buffers(canvas, {1,1,1,0})
    for l, idx in canvas.layers {
        framebuffer_attach_color(0, br)
        uniform_set_texture(_default_compose_uniforms.src_texture, l.tex, 0)
        uniform_set_texture(_default_compose_uniforms.dst_texture, bl, 1)
        blit_draw_unit_quad(SHADER_COMPOSE_DEFAULT)

        bl, br = br, bl
        if idx == auto_cast canvas.current_layer {
            compose_pigment(canvas.compose.compose_brush, bl, br, width, height)
            bl, br = br, bl
        }
    }
    blit(bl, canvas.compose.compose_result, width, height)
}

compose_engine_compose_dirty :: proc(using canvas: ^Canvas) {
}

compose_pigment :: proc(src,dst, target: u32, width, height: i32) {
    using dgl
    rem_viewport := state_get_viewport(); defer state_set_viewport(rem_viewport)
    rem_fbo := framebuffer_current(); defer framebuffer_bind(rem_fbo)
    rem_shader := shader_current(); defer shader_bind(rem_shader)

    framebuffer_bind(_compose_engine.fbo)
    framebuffer_attach_color(0, target)
    gl.Viewport(0,0,width,height)
    shader_bind(SHADER_COMPOSE_PIGMENT)

    uniform_set(_pigment_compose_uniforms.src_texture, src, 0)
    uniform_set(_pigment_compose_uniforms.dst_texture, dst, 1)
    uniform_set(_pigment_compose_uniforms.mixbox_lut, TEXTURE_MIXBOX_LUT, 2)
    blit_draw_unit_quad(SHADER_COMPOSE_PIGMENT)
}
compose_default :: proc(src,dst, target: u32, width, height: i32) {
    using dgl
    rem_viewport := state_get_viewport(); defer state_set_viewport(rem_viewport)
    rem_fbo := framebuffer_current(); defer framebuffer_bind(rem_fbo)
    rem_shader := shader_current(); defer shader_bind(rem_shader)

    framebuffer_bind(_compose_engine.fbo)
    framebuffer_attach_color(0, target)
    gl.Viewport(0,0,width,height)
    shader_bind(SHADER_COMPOSE_DEFAULT)
    uniform := &_default_compose_uniforms

    uniform_set_texture(uniform.src_texture, src, 0)
    uniform_set_texture(uniform.dst_texture, dst, 1)
    blit_draw_unit_quad(SHADER_COMPOSE_DEFAULT)
}

@(private="file")
_SHADER_COMPOSE_PIGMENT_FRAG :string: `
#version 440 core
out vec4 FragColor;

layout(location = 0) in vec2 _uv;
layout(location = 1) in vec4 _color;

uniform sampler2D src_texture;
uniform sampler2D dst_texture;
uniform sampler2D mixbox_lut;

#include "mixbox"

void main() {
    vec4 src = texture(src_texture, _uv);
    vec4 dst = texture(dst_texture, _uv);
    FragColor = mixbox_lerp(dst, src, src.a);
}
`

@(private="file")
_SHADER_COMPOSE_DEFAULT_FRAG :string: `
#version 440 core
out vec4 FragColor;

layout(location = 0) in vec2 _uv;
layout(location = 1) in vec4 _color;

uniform sampler2D src_texture;
uniform sampler2D dst_texture;

void main() {
    vec4 src = texture(src_texture, _uv);
    vec4 dst = texture(dst_texture, _uv);

    float outa = src.a + dst.a * (1 - src.a);
    vec3 col = (src.rgb * src.a + dst.rgb * dst.a * (1 - src.a)) / outa;

    FragColor = vec4(col.r, col.g, col.b, outa);
}
`