---
name: dragonfruit
description: Build readable line-oriented output in Zig CLI tools with dragonfruit. Use when adding status messages, ANSI styling, progress bars, percentages, or spinners to a non-TUI command-line application.
---

# dragonfruit

`dragonfruit` provides allocation-free presentation components that write to a
caller-owned `std.Io.Writer`. It does not take over the terminal: no cursor
control, alternate screen, input loop, timers, or threads.

## Set color and glyph policy

Resolve color from the destination stream, environment, and command policy.
Automatic color stays off for redirected output and when `NO_COLOR` is set.
Use ASCII glyphs for terminals or output consumers that do not support Unicode.

```zig
const cli = @import("dragonfruit");

const style = cli.Style.resolve(.auto, stdout_is_tty, no_color, force_color, term_is_dumb);
const glyphs: cli.Glyphs = .{ .unicode = supports_unicode };
```

Construct styles for the actual destination: stdout and stderr can have
different terminal capabilities. Keep `--json` output on its existing
machine-readable path rather than styling it.

## Emit status and progress

```zig
try cli.status(out, style, glyphs, .success, "installed {s}", .{name});
try cli.status(err, error_style, glyphs, .warning, "could not read {s}", .{path});
try cli.progress.writeBar(out, style, glyphs, completed, total, 24);
try out.writeAll("\n");

var spinner: cli.Spinner = .{ .glyphs = glyphs };
try spinner.write(out, style);
spinner.advance();
```

A spinner is only a frame value. The application decides whether and when to
redraw it; dragonfruit never starts background work. Unknown totals return
`null` from `progress.percentage` and render as `--%` in the progress bar.
Progress values above the total clamp to 100%.

## Public pieces

- `Style` and `Tone`: semantic ANSI colors with reset handling.
- `status` and `Status`: success, info, warning, and failure markers.
- `Glyphs`: logo, status, arrow, bullet, spinner, and bar glyphs.
- `progress.percentage`, `writePercentage`, and `writeBar`.
- `Spinner`: deterministic `current`, `advance`, and `write` operations.

See the package README for dependency setup and complete API notes. Run
`zig build test` when changing behavior.
