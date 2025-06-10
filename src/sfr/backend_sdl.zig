const std = @import("std");
const platform = @import("platform.zig");
const framebuffer = @import("framebuffer.zig");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));

const FRAMEBUFFER_COUNT = 2;
const BYTES_PER_PIXEL = 4;

pub fn get_backend(mode: platform.Model) !platform {
    const backend = try mode.allocator.create(SDLBackend);

    backend.* = .{
        .fb = [_]?framebuffer{null} ** FRAMEBUFFER_COUNT,
        .current_fb = 0,
        .win = null,
        .surf = null,
        .alloc = mode.allocator,
    };

    return .{
        .context = backend,
        .dispatch = .{
            .init = &vt_init,
            .deinit = &vt_deinit,
            .request_framebuffer = &vt_request_framebuffer,
            .present = &vt_present,
        },
    };
}

fn vt_init(ctx: *anyopaque, model: platform.Model) anyerror!void {
    const _backend: *SDLBackend = @ptrCast(ctx);
    return _backend.init(model);
}

fn vt_deinit(ctx: *anyopaque) void {
    const _backend: *SDLBackend = @ptrCast(ctx);
    return _backend.deinit();
}

fn vt_request_framebuffer(ctx: *anyopaque) anyerror!*framebuffer {
    const _backend: *SDLBackend = @ptrCast(ctx);
    return _backend.request_framebuffer();
}

fn vt_present(ctx: *anyopaque, fb: framebuffer) anyerror!void {
    const _backend: *SDLBackend = @ptrCast(ctx);
    return _backend.present(fb);
}

pub const SDLBackend = struct {
    const This = @This();
    fb: [FRAMEBUFFER_COUNT]?framebuffer,
    current_fb: usize = 0,
    win: ?*sdl.SDL_Window,
    surf: ?*sdl.SDL_Surface,
    alloc: std.mem.Allocator,

    pub fn init(this: This, mode: platform.Model) !void {
        if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO)) {
            return error.SDL_INIT;
        }
        errdefer sdl.SDL_Quit();

        const native_size = mode.native_size;
        const resolution_size = mode.resolution.get_size();

        std.debug.assert(native_size.width >= resolution_size[0] and
            native_size.height >= resolution_size[1]);

        this.win = sdl.SDL_CreateWindow(
            mode.name,
            native_size.width,
            native_size.height,
            0,
        );

        if (this.win == null) {
            return error.WINDOW_INIT;
        }
        errdefer sdl.SDL_DestroyWindow(this.win);

        this.surf = sdl.SDL_GetWindowSurface(this.win);
        if (this.surf == null) {
            return error.APP_SURFACE_INIT;
        }
        errdefer sdl.SDL_DestroyWindowSurface(this.win);

        for (this.fb) |*buffer| {
            if (buffer) |buf| {
                this.alloc.free(buf.data);
            }
            buffer.* = .{
                .width = resolution_size[0],
                .height = resolution_size[1],
                .data = try this.alloc.allocate(u8, @reduce(.Mul, resolution_size) * BYTES_PER_PIXEL),
            };
            errdefer this.alloc.free(buffer.?.data);
        }
    }

    pub fn request_framebuffer(this: This) !*framebuffer {
        defer this.current_fb = (this.current_fb + 1) % this.fb.len;
        return &this.fb[this.current_fb];
    }

    pub fn present(this: This, fb: framebuffer) !void {
        if (this.surf) |surf| {
            const dest: [*]u8 = @ptrCast(surf.pixels.?);
            const src: [*]u8 = @ptrCast(fb.data);

            for (0..fb.height) |yy| {
                const framebuffer_width = fb.width * BYTES_PER_PIXEL;
                const surface_width = surf.w * BYTES_PER_PIXEL;

                const srow = src[yy * framebuffer_width .. (yy + 1) * framebuffer_width];
                const drow = dest[yy * surface_width .. yy * surface_width + framebuffer_width];

                @memcpy(drow, srow);
            }
            _ = sdl.SDL_UpdateWindowSurface(this.win);
            return;
        }
        return error.NULL_SURFACE;
    }

    pub fn deinit(this: This) void {
        sdl.SDL_DestroyWindow(this.win);
        sdl.SDL_Quit();
    }
};

pub const intern_Keymap = enum(c_int) {
    UNKNOWN = sdl.SDL_SCANCODE_UNKNOWN,

    A = sdl.SDL_SCANCODE_A,
    B = sdl.SDL_SCANCODE_B,
    C = sdl.SDL_SCANCODE_C,
    D = sdl.SDL_SCANCODE_D,
    E = sdl.SDL_SCANCODE_E,
    F = sdl.SDL_SCANCODE_F,
    G = sdl.SDL_SCANCODE_G,
    H = sdl.SDL_SCANCODE_H,
    I = sdl.SDL_SCANCODE_I,
    J = sdl.SDL_SCANCODE_J,
    K = sdl.SDL_SCANCODE_K,
    L = sdl.SDL_SCANCODE_L,
    M = sdl.SDL_SCANCODE_M,
    N = sdl.SDL_SCANCODE_N,
    O = sdl.SDL_SCANCODE_O,
    P = sdl.SDL_SCANCODE_P,
    Q = sdl.SDL_SCANCODE_Q,
    R = sdl.SDL_SCANCODE_R,
    S = sdl.SDL_SCANCODE_S,
    T = sdl.SDL_SCANCODE_T,
    U = sdl.SDL_SCANCODE_U,
    V = sdl.SDL_SCANCODE_V,
    W = sdl.SDL_SCANCODE_W,
    X = sdl.SDL_SCANCODE_X,
    Y = sdl.SDL_SCANCODE_Y,
    Z = sdl.SDL_SCANCODE_Z,

    Num1 = sdl.SDL_SCANCODE_1,
    Num2 = sdl.SDL_SCANCODE_2,
    Num3 = sdl.SDL_SCANCODE_3,
    Num4 = sdl.SDL_SCANCODE_4,
    Num5 = sdl.SDL_SCANCODE_5,
    Num6 = sdl.SDL_SCANCODE_6,
    Num7 = sdl.SDL_SCANCODE_7,
    Num8 = sdl.SDL_SCANCODE_8,
    Num9 = sdl.SDL_SCANCODE_9,
    Num0 = sdl.SDL_SCANCODE_0,

    Return = sdl.SDL_SCANCODE_RETURN,
    Escape = sdl.SDL_SCANCODE_ESCAPE,
    Backspace = sdl.SDL_SCANCODE_BACKSPACE,
    Tab = sdl.SDL_SCANCODE_TAB,
    Space = sdl.SDL_SCANCODE_SPACE,

    Minus = sdl.SDL_SCANCODE_MINUS, // "-"
    Equals = sdl.SDL_SCANCODE_EQUALS, // "="
    LeftBracket = sdl.SDL_SCANCODE_LEFTBRACKET, // "["
    RightBracket = sdl.SDL_SCANCODE_RIGHTBRACKET, // "]"
    Backslash = sdl.SDL_SCANCODE_BACKSLASH, // "\"
    NonUSHash = sdl.SDL_SCANCODE_NONUSHASH, // Non‑US "#"
    Semicolon = sdl.SDL_SCANCODE_SEMICOLON, // ";"
    Apostrophe = sdl.SDL_SCANCODE_APOSTROPHE, // "'"
    Grave = sdl.SDL_SCANCODE_GRAVE, // "`"
    Comma = sdl.SDL_SCANCODE_COMMA, // ","
    Period = sdl.SDL_SCANCODE_PERIOD, // "."
    Slash = sdl.SDL_SCANCODE_SLASH, // "/"

    CapsLock = sdl.SDL_SCANCODE_CAPSLOCK,

    F1 = sdl.SDL_SCANCODE_F1,
    F2 = sdl.SDL_SCANCODE_F2,
    F3 = sdl.SDL_SCANCODE_F3,
    F4 = sdl.SDL_SCANCODE_F4,
    F5 = sdl.SDL_SCANCODE_F5,
    F6 = sdl.SDL_SCANCODE_F6,
    F7 = sdl.SDL_SCANCODE_F7,
    F8 = sdl.SDL_SCANCODE_F8,
    F9 = sdl.SDL_SCANCODE_F9,
    F10 = sdl.SDL_SCANCODE_F10,
    F11 = sdl.SDL_SCANCODE_F11,
    F12 = sdl.SDL_SCANCODE_F12,

    PrintScreen = sdl.SDL_SCANCODE_PRINTSCREEN,
    ScrollLock = sdl.SDL_SCANCODE_SCROLLLOCK,
    Pause = sdl.SDL_SCANCODE_PAUSE,

    Insert = sdl.SDL_SCANCODE_INSERT,
    Home = sdl.SDL_SCANCODE_HOME,
    PageUp = sdl.SDL_SCANCODE_PAGEUP,
    Delete = sdl.SDL_SCANCODE_DELETE,
    End = sdl.SDL_SCANCODE_END,
    PageDown = sdl.SDL_SCANCODE_PAGEDOWN,

    Right = sdl.SDL_SCANCODE_RIGHT,
    Left = sdl.SDL_SCANCODE_LEFT,
    Down = sdl.SDL_SCANCODE_DOWN,
    Up = sdl.SDL_SCANCODE_UP,

    NumLockClear = sdl.SDL_SCANCODE_NUMLOCKCLEAR,
    KP_Divide = sdl.SDL_SCANCODE_KP_DIVIDE,
    KP_Multiply = sdl.SDL_SCANCODE_KP_MULTIPLY,
    KP_Minus = sdl.SDL_SCANCODE_KP_MINUS,
    KP_Plus = sdl.SDL_SCANCODE_KP_PLUS,
    KP_Enter = sdl.SDL_SCANCODE_KP_ENTER,
    KP_1 = sdl.SDL_SCANCODE_KP_1,
    KP_2 = sdl.SDL_SCANCODE_KP_2,
    KP_3 = sdl.SDL_SCANCODE_KP_3,
    KP_4 = sdl.SDL_SCANCODE_KP_4,
    KP_5 = sdl.SDL_SCANCODE_KP_5,
    KP_6 = sdl.SDL_SCANCODE_KP_6,
    KP_7 = sdl.SDL_SCANCODE_KP_7,
    KP_8 = sdl.SDL_SCANCODE_KP_8,
    KP_9 = sdl.SDL_SCANCODE_KP_9,
    KP_0 = sdl.SDL_SCANCODE_KP_0,
    KP_Period = sdl.SDL_SCANCODE_KP_PERIOD,
};

pub const intern_MouseMap = enum(c_int) {
    Left = sdl.SDL_BUTTON_LEFT,
    Right = sdl.SDL_BUTTON_RIGHT,
    Middle = sdl.SDL_BUTTON_MIDDLE,
};
