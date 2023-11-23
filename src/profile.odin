package main

import "core:time"


// Single thread temporary profiler

Profile :: struct {
    name : string,
    timer : time.Stopwatch,
    duration : time.Duration,
    closed : bool,
}

@(private="file")
_profiles : [dynamic]Profile

profile_init :: proc() {
    _profiles = make([dynamic]Profile)
}
profile_clear :: proc() {
    clear(&_profiles)
}
profile_release :: proc() {
    delete(_profiles)
}
profile_collect :: #force_inline proc() -> ^[dynamic]Profile {
    return &_profiles
}

profile_begin :: proc(region: string) {
    idx := len(_profiles)
    append(&_profiles, Profile{name=region, timer = {}})
    time.stopwatch_start(&_profiles[idx].timer)
}
profile_end :: proc() {
    #reverse for &p in _profiles {
        if p.closed do continue
        p.duration = time.stopwatch_duration(p.timer)
        time.stopwatch_stop(&p.timer)
        p.closed = true
        return
    }
    assert(false, "Invalid profile_end.")
}