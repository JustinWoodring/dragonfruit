//! Terminal-safe ANSI styling primitives for plain command-line output.
//! Copyright (c) 2026 Justin Woodring <jwoodrg@gmail.com>
//!
//! SPDX-License-Identifier: MIT
const Io = @import("std").Io;

/// Controls whether style output follows terminal detection or an explicit override.
pub const ColorMode = enum { auto, always, never };

/// Named semantic styles keep callers independent from raw SGR sequences.
pub const Tone = enum { plain, strong, muted, accent, success, warning, failure, info };

/// Styles text without allocating; disabled styles write the original bytes unchanged.
/// Auto mode never adds escape codes to redirected output or when NO_COLOR is set.
pub const Style = struct {
    enabled: bool = false,

    /// Resolves automatic color without requiring process-global environment access.
    pub fn resolve(
        mode: ColorMode,
        is_terminal: bool,
        no_color: bool,
        force_color: bool,
        dumb_terminal: bool,
    ) Style {
        return .{ .enabled = switch (mode) {
            .never => false,
            .always => true,
            .auto => !no_color and (force_color or (is_terminal and !dumb_terminal)),
        } };
    }

    /// Begins a style for callers that need to render a value in several writes.
    pub fn begin(self: Style, out: *Io.Writer, tone: Tone) Io.Writer.Error!void {
        if (self.enabled) try out.writeAll(sequence(tone));
    }

    /// Resets styling after a sequence started with `begin`.
    pub fn end(self: Style, out: *Io.Writer) Io.Writer.Error!void {
        if (self.enabled) try out.writeAll("\x1b[0m");
    }

    /// Writes one value and restores the terminal's prior default style.
    pub fn write(self: Style, out: *Io.Writer, tone: Tone, text: []const u8) Io.Writer.Error!void {
        if (tone == .plain) {
            try out.writeAll(text);
            return;
        }
        try self.begin(out, tone);
        try out.writeAll(text);
        try self.end(out);
    }

    /// Formats directly into the destination writer without allocating an intermediate string.
    pub fn print(
        self: Style,
        out: *Io.Writer,
        tone: Tone,
        comptime format: []const u8,
        args: anytype,
    ) Io.Writer.Error!void {
        if (tone == .plain) {
            try out.print(format, args);
            return;
        }
        try self.begin(out, tone);
        try out.print(format, args);
        try self.end(out);
    }

    fn sequence(tone: Tone) []const u8 {
        return switch (tone) {
            .plain => "",
            .strong => "\x1b[1m",
            .muted => "\x1b[2m",
            .accent => "\x1b[36m",
            .success => "\x1b[32m",
            .warning => "\x1b[33m",
            .failure => "\x1b[31m",
            .info => "\x1b[34m",
        };
    }
};

test "auto color respects terminal, NO_COLOR, force, and dumb terminals" {
    try @import("std").testing.expect(Style.resolve(.auto, true, false, false, false).enabled);
    try @import("std").testing.expect(!Style.resolve(.auto, false, false, false, false).enabled);
    try @import("std").testing.expect(!Style.resolve(.auto, true, true, true, false).enabled);
    try @import("std").testing.expect(Style.resolve(.auto, false, false, true, true).enabled);
    try @import("std").testing.expect(!Style.resolve(.auto, true, false, false, true).enabled);
    try @import("std").testing.expect(Style.resolve(.always, false, true, false, true).enabled);
    try @import("std").testing.expect(!Style.resolve(.never, true, false, true, false).enabled);
}

test "disabled styling preserves bytes and enabled styling resets" {
    const std = @import("std");
    var plain: Io.Writer.Allocating = .init(std.testing.allocator);
    defer plain.deinit();
    try (Style{}).write(&plain.writer, .success, "ready");
    try std.testing.expectEqualStrings("ready", plain.written());
    var plain_tone: Io.Writer.Allocating = .init(std.testing.allocator);
    defer plain_tone.deinit();
    try (Style{ .enabled = true }).write(&plain_tone.writer, .plain, "plain");
    try std.testing.expectEqualStrings("plain", plain_tone.written());

    var colored: Io.Writer.Allocating = .init(std.testing.allocator);
    defer colored.deinit();
    try (Style{ .enabled = true }).write(&colored.writer, .success, "ready");
    try std.testing.expectEqualStrings("\x1b[32mready\x1b[0m", colored.written());
}
