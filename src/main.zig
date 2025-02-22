const std = @import("std");
const helper = @import("helper.zig");

const E = error{ScreenshotFailed};

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn();

    var red: i32 = 0;
    var green: i32 = 0;
    var blue: i32 = 0;

    const cfg = helper.Config;

    helper.getValorantColors(cfg.target_color, &red, &green, &blue);

    helper.initPerformanceCounters();
    const pixel_count = cfg.scan_area_x * cfg.scan_area_y;

    try stdout.print("triggerbot is running\n", .{});

    while (true) {
        helper.startCounter();

        if (cfg.hold_mode == 0 or helper.isKeyPressed(helper.getKeyCode(cfg.hold_key))) {
            const pPixels_opt = helper.getScreenshot(null, cfg.scan_area_x, cfg.scan_area_y);
            if (pPixels_opt == null) {
                try stdout.print("ERROR: getScreenshot() failed!\nPress enter to exit: ", .{});
                _ = stdin.readUntilDelimiterOrEof(&[_]u8{'\n'});
                return E.ScreenshotFailed;
            }
            const pPixels = pPixels_opt.?;
            const pixels_slice = std.mem.sliceFromPtr(pPixels, pixel_count);
            if (helper.isColorFound(pixels_slice, red, green, blue, cfg.color_sens)) {
                helper.leftClick();
                helper.stopCounter();
                try std.time.sleep(std.time.millisecond * @as(u64, cfg.tap_time));
            }
            std.heap.c_allocator.free(pPixels);
        } else {
            try std.time.sleep(std.time.millisecond);
        }
    }
}
