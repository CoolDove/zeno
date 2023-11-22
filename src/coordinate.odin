package main


Coordinate :: struct {
    wnd2cvs : proc(canvas: ^Canvas, wc:Vec2)->Vec2,
    cvs2wnd : proc(canvas: ^Canvas, cc:Vec2)->Vec2,
}

canvas_coord : Coordinate = {
    wnd2cvs = _wnd2cvs,
    cvs2wnd = _cvs2wnd,
}

// coordinates:
//  wnd: window space. Left-top is (0,0), right-bottom is (ww,wh)
//  cvs: canvas space. Left-top is (0,0), right-bottom is (cw,ch)
@(private="file")
_wnd2cvs :: proc(using canvas: ^Canvas, wc:Vec2)->Vec2 {
    return (wc - 0.5 * app.window_size - offset) / scale + {0.5*cast(f32)width, 0.5*cast(f32)height}
}
@(private="file")
_cvs2wnd :: proc(using canvas: ^Canvas, wc:Vec2)->Vec2 {
    return scale * (wc-{0.5*cast(f32)width, 0.5*cast(f32)height}) + offset + 0.5 * app.window_size
}