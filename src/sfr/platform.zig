const Platform = @This();
const std = @import("std");
pub const Framebuffer = @import("framebuffer.zig");

context: *anyopaque,
dispatch: VTable,

pub fn init(this: Platform, model: Model) anyerror!void {
    return this.dispatch.init(this.context, model);
}
pub fn deinit(this: Platform) void {
    return this.dispatch.deinit(this.context);
}
pub fn request_framebuffer(this: Platform) anyerror!*Framebuffer {
    return this.dispatch.request_framebuffer(this.context);
}
pub fn present(this: Platform, fb: Framebuffer) anyerror!void {
    return this.dispatch.present(this.context, fb);
}

pub const VTable = struct {
    init: *const fn (ctx: *anyopaque, model: Model) anyerror!void,
    deinit: *const fn (ctx: *anyopaque) void,
    request_framebuffers: *const fn (ctx: *anyopaque) anyerror![]Framebuffer,
    present: *const fn (ctx: *anyopaque, fb: Framebuffer) anyerror!void,
    poll_event: *const fn (ctx: *anyopaque) ?Event,
};

pub const Resolution = enum {
    Tiny,
    Small,
    Medium,
    Large,

    pub fn get_size(this: @This()) @Vector(2, u32) {
        return switch (this) {
            .Tiny => @Vector(2, u32){ 320, 240 },
            .Small => @Vector(2, u32){ 640, 480 },
            .Medium => @Vector(2, u32){ 800, 600 },
            .Large => @Vector(2, u32){ 1280, 720 },
        };
    }
};

pub const Model = struct {
    resolution: Resolution,
    name: [*c]const u8,
    native_size: struct { width: u32, height: u32 },
    allocator: std.mem.Allocator,
};

pub const Event = union(enum) {
    key: Key,
    mouse: Mouse,
    wheel: Wheel,
    app: App,

    pub const Key = struct {
        key: c_int,
        pressed: bool,
    };
    pub const Mouse = struct {
        button: c_int,
        pressed: bool,
        x: f32,
        y: f32,
    };
    pub const Wheel = struct {
        h: f32,
        v: f32,
    };
    pub const App = struct {
        should_close: bool,
    };
};

pub const KeyMap = enum(c_int) {
    UNKNOWN,

    A,
    B,
    C,
    D,
    E,
    F,
    G,
    H,
    I,
    J,
    K,
    L,
    M,
    N,
    O,
    P,
    Q,
    R,
    S,
    T,
    U,
    V,
    W,
    X,
    Y,
    Z,

    Num1,
    Num2,
    Num3,
    Num4,
    Num5,
    Num6,
    Num7,
    Num8,
    Num9,
    Num0,

    Return,
    Escape,
    Backspace,
    Tab,
    Space,

    Minus, // "-"
    Equals, // "="
    LeftBracket, // "["
    RightBracket, // "]"
    Backslash, // "\"
    NonUSHash, // Non‑US "#"
    Semicolon, // ";"
    Apostrophe, // "'"
    Grave, // "`"
    Comma, // ","
    Period, // "."
    Slash, // "/"

    CapsLock,

    F1,
    F2,
    F3,
    F4,
    F5,
    F6,
    F7,
    F8,
    F9,
    F10,
    F11,
    F12,

    PrintScreen,
    ScrollLock,
    Pause,

    Insert,
    Home,
    PageUp,
    Delete,
    End,
    PageDown,

    Right,
    Left,
    Down,
    Up,

    NumLockClear,
    KP_Divide,
    KP_Multiply,
    KP_Minus,
    KP_Plus,
    KP_Enter,
    KP_1,
    KP_2,
    KP_3,
    KP_4,
    KP_5,
    KP_6,
    KP_7,
    KP_8,
    KP_9,
    KP_0,
    KP_Period,
};

pub const MouseMap = enum(c_int) {
    Left,
    Right,
    Middle,
};
