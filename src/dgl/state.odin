package dgl

import gl "vendor:OpenGL"

GlStateViewport :: Vec4i
GlStateBlend :: Vec4i

state_get_viewport :: proc() -> GlStateViewport {
    vp : GlStateViewport
    gl.GetIntegerv(gl.VIEWPORT, auto_cast &vp)
    return vp
}

state_set_viewport :: proc(viewport: GlStateViewport) {
    gl.Viewport(viewport.x, viewport.y, viewport.z, viewport.w)
}