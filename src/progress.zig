//! Allocation-free progress and percentage rendering for line-oriented CLIs.
//! Copyright (c) 2026 Justin Woodring <jwoodrg@gmail.com>
//!
//! SPDX-License-Identifier: MIT
const std = @import("std");
const Io = std.Io;
const Style = @import("ansi.zig").Style;
const Glyphs = @import("glyphs.zig").Glyphs;

/// Returns null when the total is unknown; over-completion is capped at 100%.
pub fn percentage(completed: u64, total: u64) ?u8 {
    if (total == 0) return null;
    const bounded = @min(completed, total);
    return @intCast((@as(u128, bounded) * 100) / @as(u128, total));
}

/// Writes a percentage or `--%` when a meaningful denominator is unavailable.
pub fn writePercentage(out: *Io.Writer, completed: u64, total: u64) Io.Writer.Error!void {
    if (percentage(completed, total)) |value| {
        try out.print("{d}%", .{value});
    } else {
        try out.writeAll("--%");
    }
}

/// Writes a fixed-width bar and percentage without moving the cursor or allocating.
pub fn writeBar(
    out: *Io.Writer,
    style: Style,
    glyphs: Glyphs,
    completed: u64,
    total: u64,
    width: usize,
) Io.Writer.Error!void {
    const filled: usize = if (total == 0) 0 else @intCast((@as(u128, @min(completed, total)) * @as(u128, @intCast(width))) / @as(u128, total));
    try out.writeAll("[");

    try style.begin(out, .accent);
    for (0..filled) |_| try out.writeAll(glyphs.filledBar());
    try style.end(out);

    try style.begin(out, .muted);
    for (filled..width) |_| try out.writeAll(glyphs.emptyBar());
    try style.end(out);

    try out.writeAll("] ");
    try writePercentage(out, completed, total);
}

test "percentage is bounded and represents unknown totals explicitly" {
    const testing = std.testing;
    try testing.expectEqual(@as(?u8, 0), percentage(0, 9));
    try testing.expectEqual(@as(?u8, 50), percentage(1, 2));
    try testing.expectEqual(@as(?u8, 100), percentage(10, 10));
    try testing.expectEqual(@as(?u8, 100), percentage(std.math.maxInt(u64), 1));
    try testing.expectEqual(@as(?u8, null), percentage(4, 0));
}

test "bar handles empty totals, width zero, and over-completion" {
    const testing = std.testing;
    var full: Io.Writer.Allocating = .init(testing.allocator);
    defer full.deinit();
    try writeBar(&full.writer, .{}, .{ .unicode = false }, 7, 3, 4);
    try testing.expectEqualStrings("[####] 100%", full.written());

    var unknown: Io.Writer.Allocating = .init(testing.allocator);
    defer unknown.deinit();
    try writeBar(&unknown.writer, .{}, .{ .unicode = false }, 0, 0, 3);
    try testing.expectEqualStrings("[---] --%", unknown.written());

    var no_width: Io.Writer.Allocating = .init(testing.allocator);
    defer no_width.deinit();
    try writeBar(&no_width.writer, .{}, .{ .unicode = false }, 1, 2, 0);
    try testing.expectEqualStrings("[] 50%", no_width.written());
}
