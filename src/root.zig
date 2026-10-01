//! Small, allocation-free presentation components for line-oriented CLI tools.
//! Copyright (c) 2026 Justin Woodring <jwoodrg@gmail.com>
//!
//! SPDX-License-Identifier: MIT
const std = @import("std");

/// ANSI style policy, semantic tones, and writer helpers.
pub const ansi = @import("ansi.zig");
/// Status markers, shared symbols, and ASCII/Unicode glyph selection.
pub const glyphs = @import("glyphs.zig");
/// Percentages and fixed-width line-oriented progress bars.
pub const progress = @import("progress.zig");
/// Caller-ticked spinner frames without timers or cursor control.
pub const spinner = @import("spinner.zig");

/// Explicit or terminal-aware color policy.
pub const ColorMode = ansi.ColorMode;
/// Allocation-free ANSI style operations.
pub const Style = ansi.Style;
/// Semantic text tones for labels and status output.
pub const Tone = ansi.Tone;
/// Shared visual vocabulary for Unicode and ASCII output.
pub const Glyphs = glyphs.Glyphs;
/// Success, information, warning, and failure status kinds.
pub const Status = glyphs.Status;
/// Explicitly advanced spinner component.
pub const Spinner = spinner.Spinner;

/// Prints one status marker and a newline-terminated message without cursor control.
pub fn status(
    out: *std.Io.Writer,
    style: Style,
    symbols: Glyphs,
    kind: Status,
    comptime format: []const u8,
    args: anytype,
) std.Io.Writer.Error!void {
    const tone: Tone = switch (kind) {
        .success => .success,
        .info => .info,
        .warning => .warning,
        .failure => .failure,
    };
    try style.print(out, tone, "{s}", .{symbols.marker(kind)});
    try out.print(" " ++ format ++ "\n", args);
}

test "status renders a stable ASCII line with color disabled" {
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try status(&output.writer, .{}, .{ .unicode = false }, .success, "installed {s}", .{"tool"});
    try std.testing.expectEqualStrings("[ok] installed tool\n", output.written());
}
