//! Explicitly ticked spinner frames; no timers, threads, or cursor control.
//! Copyright (c) 2026 Justin Woodring <jwoodrg@gmail.com>
//!
//! SPDX-License-Identifier: MIT
const Io = @import("std").Io;
const Style = @import("ansi.zig").Style;
const Glyphs = @import("glyphs.zig").Glyphs;

/// A caller advances frames when its own work loop makes progress.
pub const Spinner = struct {
    glyphs: Glyphs = .{},
    frame: usize = 0,

    /// Returns the current frame without advancing or doing timed work.
    pub fn current(self: Spinner) []const u8 {
        return self.glyphs.spinnerFrame(self.frame);
    }

    /// Moves to the next frame while keeping the index bounded.
    pub fn advance(self: *Spinner) void {
        self.frame = (self.frame +% 1) % 4;
    }

    /// Writes the current frame as a single styled value.
    pub fn write(self: Spinner, out: *Io.Writer, style: Style) Io.Writer.Error!void {
        try style.write(out, .accent, self.current());
    }
};

test "spinner advances deterministically and wraps its frame set" {
    const std = @import("std");
    var spinner: Spinner = .{ .glyphs = .{ .unicode = false } };
    try std.testing.expectEqualStrings("|", spinner.current());
    spinner.advance();
    try std.testing.expectEqualStrings("/", spinner.current());
    spinner.frame = 3;
    spinner.advance();
    try std.testing.expectEqual(@as(usize, 0), spinner.frame);
    try std.testing.expectEqualStrings("|", spinner.current());
}
