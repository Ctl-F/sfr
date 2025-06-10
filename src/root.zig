const std = @import("std");
const platform = @import("sfr/platform.zig");
const backend_sdl = @import("sfr/backend_sdl.zig");

pub const InitConfig = platform.Model;
pub const Resolution = platform.Resolution;
pub const Framebuffer = platform.Framebuffer;

pub fn begin(config: InitConfig) !platform {
    const backend = try backend_sdl.get_backend(config);
    return backend;
}
