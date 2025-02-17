const std = @import("std");
const windows = std.os.windows;
const kernel32 = windows.kernel32;

const INT = windows.INT;
const BOOL = windows.BOOL;
const CHAR = windows.CHAR;
const SHORT = windows.SHORT;
const DWORD = windows.DWORD;
const WINAPI = windows.WINAPI;
const LPVOID = windows.LPVOID;
const HMODULE = windows.HMODULE;
const HINSTANCE = windows.HINSTANCE;

extern "user32" fn GetAsyncKeyState(vKey: INT) callconv(WINAPI) SHORT;

var frequency: u64 = 0;
var start: u64 = 0;
var end: u64 = 0;
var reaction_count: i32 = 0;
var total_reaction: f64 = 0.0;

pub const Config = struct {
    target_color: []const u8 = "purple",
    hold_key: []const u8 = "left_alt",
    scan_area_x: i32 = 8,
    scan_area_y: i32 = 8,
    color_sens: i32 = 65,
    tap_time: f64 = 100,
    hold_mode: i32 = 1,
};

fn getRed(rgb: u32) i32 {
    return @as(i32, (rgb >> 16) & 0xFF);
}
fn getGreen(rgb: u32) i32 {
    return @as(i32, (rgb >> 8) & 0xFF);
}
fn getBlue(rgb: u32) i32 {
    return @as(i32, rgb & 0xFF);
}

pub fn isColorFound(pixels: []const u32, targetRed: i32, targetGreen: i32, targetBlue: i32, colorSens: i32) bool {
    for (pixels) |pixel| {
        const r = getRed(pixel);
        const g = getGreen(pixel);
        const b = getBlue(pixel);
        if (r + colorSens >= targetRed and r - colorSens <= targetRed) {
            if (g + colorSens >= targetGreen and g - colorSens <= targetGreen) {
                if (b + colorSens >= targetBlue and b - colorSens <= targetBlue) {
                    return true;
                }
            }
        }
    }
    return false;
}

pub fn getKeyCode(inputKey: []const u8) i32 {
    const keys = [_]struct {
        key_name: []const u8,
        key: i32,
    }{
        .{ "left_mouse_button", 0x01 },
        .{ "right_mouse_button", 0x02 },
        .{ "x1", 0x05 },
        .{ "x2", 0x06 },
        .{ "num_0", 0x30 },
        .{ "num_1", 0x31 },
        .{ "num_2", 0x32 },
        .{ "num_3", 0x33 },
        .{ "num_4", 0x34 },
        .{ "num_5", 0x35 },
        .{ "num_6", 0x36 },
        .{ "num_7", 0x37 },
        .{ "num_8", 0x38 },
        .{ "num_9", 0x39 },
        .{ "a", 0x41 },
        .{ "b", 0x42 },
        .{ "c", 0x43 },
        .{ "d", 0x44 },
        .{ "e", 0x45 },
        .{ "f", 0x46 },
        .{ "g", 0x47 },
        .{ "h", 0x48 },
        .{ "i", 0x49 },
        .{ "j", 0x4A },
        .{ "k", 0x4B },
        .{ "l", 0x4C },
        .{ "m", 0x4D },
        .{ "n", 0x4E },
        .{ "o", 0x4F },
        .{ "p", 0x50 },
        .{ "q", 0x51 },
        .{ "r", 0x52 },
        .{ "s", 0x53 },
        .{ "t", 0x54 },
        .{ "u", 0x55 },
        .{ "v", 0x56 },
        .{ "w", 0x57 },
        .{ "x", 0x58 },
        .{ "y", 0x59 },
        .{ "z", 0x5A },
        .{ "backspace", 0x08 },
        .{ "down_arrow", 0x28 },
        .{ "enter", 0x0D },
        .{ "esc", 0x1B },
        .{ "home", 0x24 },
        .{ "insert", 0x2D },
        .{ "left_alt", 0xA4 },
        .{ "left_ctrl", 0xA2 },
        .{ "left_shift", 0xA0 },
        .{ "page_down", 0x22 },
        .{ "page_up", 0x21 },
        .{ "right_alt", 0xA5 },
        .{ "right_ctrl", 0xA3 },
        .{ "right_shift", 0xA1 },
        .{ "space", 0x20 },
        .{ "tab", 0x09 },
        .{ "up_arrow", 0x26 },
        .{ "f1", 0x70 },
        .{ "f2", 0x71 },
        .{ "f3", 0x72 },
        .{ "f4", 0x73 },
        .{ "f5", 0x74 },
        .{ "f6", 0x75 },
        .{ "f7", 0x76 },
        .{ "f8", 0x77 },
        .{ "f9", 0x78 },
        .{ "f10", 0x79 },
        .{ "f11", 0x7A },
        .{ "f12", 0x7B },
    };
    for (keys) |entry| {
        if (std.mem.eql(u8, entry.key_name, inputKey)) {
            return entry.key;
        }
    }
    return -1;
}

pub fn getValorantColors(pColor: []const u8, pRed: *i32, pGreen: *i32, pBlue: *i32) bool {
    if (std.mem.eql(u8, pColor, "purple")) {
        pRed.* = 250;
        pGreen.* = 100;
        pBlue.* = 250;
        return true;
    } else if (std.mem.eql(u8, pColor, "yellow")) {
        pRed.* = 254;
        pGreen.* = 254;
        pBlue.* = 64;
        return true;
    } else {
        return false;
    }
}

pub fn getReactionAverage(totalReaction: f64, reactionCount: i32) f64 {
    return totalReaction / @as(f64, reactionCount);
}

pub fn initPerformanceCounters() void {
    frequency = windows.QueryPerformanceFrequency();
}

pub fn startCounter() void {
    start = windows.QueryPerformanceCounter();
}

pub fn stopCounter() void {
    end = windows.QueryPerformanceCounter();
    const elapsed_time = (@as(f64, end - start) * 1000.0) / @as(f64, frequency);
    reaction_count += 1;
    total_reaction += elapsed_time;
    std.debug.print("\rReaction time: {:.2} ms ", .{getReactionAverage(total_reaction, reaction_count)});
}

pub fn isKeyPressed(hold_key: i32) bool {
    return (@as(i16, GetAsyncKeyState(hold_key)) & 0x8000) != 0;
}
