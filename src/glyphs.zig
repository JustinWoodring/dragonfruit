//! Text glyphs with readable ASCII alternatives for constrained terminals.
//! Copyright (c) 2026 Justin Woodring <jwoodrg@gmail.com>
//!
//! SPDX-License-Identifier: MIT
/// Categories accepted by `root.status`.
pub const Status = enum { success, info, warning, failure };

/// Selects a Unicode or ASCII vocabulary once, so every component stays consistent.
pub const Glyphs = struct {
    unicode: bool = true,

    /// A compact decorative mark for package or command identity.
    pub fn logo(self: Glyphs) []const u8 {
        return if (self.unicode) "✦" else "*";
    }

    /// Selects a readable status marker in the active glyph set.
    pub fn marker(self: Glyphs, status: Status) []const u8 {
        return switch (status) {
            .success => if (self.unicode) "✓" else "[ok]",
            .info => if (self.unicode) "ℹ" else "[i]",
            .warning => if (self.unicode) "⚠" else "[!]",
            .failure => if (self.unicode) "✗" else "[x]",
        };
    }

    /// Separates source and destination labels without assuming a font icon set.
    pub fn arrow(self: Glyphs) []const u8 {
        return if (self.unicode) "→" else "->";
    }

    /// Produces a list marker that remains legible in ASCII mode.
    pub fn bullet(self: Glyphs) []const u8 {
        return if (self.unicode) "•" else "*";
    }

    /// Returns the completed segment used by progress bars.
    pub fn filledBar(self: Glyphs) []const u8 {
        return if (self.unicode) "█" else "#";
    }

    /// Returns the remaining segment used by progress bars.
    pub fn emptyBar(self: Glyphs) []const u8 {
        return if (self.unicode) "░" else "-";
    }

    /// Selects a deterministic frame; callers choose when to advance it.
    pub fn spinnerFrame(self: Glyphs, index: usize) []const u8 {
        if (!self.unicode) {
            const frames = [_][]const u8{ "|", "/", "-", "\\" };
            return frames[index % frames.len];
        }
        const frames = [_][]const u8{ "◴", "◷", "◶", "◵" };
        return frames[index % frames.len];
    }
};

test "ASCII glyphs avoid Unicode output and spinner frames wrap" {
    const std = @import("std");
    const ascii = Glyphs{ .unicode = false };
    try std.testing.expectEqualStrings("[ok]", ascii.marker(.success));
    try std.testing.expectEqualStrings("#", ascii.filledBar());
    try std.testing.expectEqualStrings("|", ascii.spinnerFrame(0));
    try std.testing.expectEqualStrings("|", ascii.spinnerFrame(4));
    try std.testing.expectEqualStrings("✗", (Glyphs{}).marker(.failure));
}
