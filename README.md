<div align="center">
  <h1>dragonfruit</h1>
  <p><strong>Small presentation components for Zig command-line tools</strong>: readable ANSI styles, status markers, progress bars, percentages, and frame-based spinners without a TUI runtime.</p>
  <p>
    <a href="https://github.com/JustinWoodring/dragonfruit/actions"><img src="https://img.shields.io/badge/zig-0.16.0-f7a41d" alt="Zig 0.16.0"></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT"></a>
    <a href="https://github.com/JustinWoodring/dragonfruit/pulls"><img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs welcome"></a>
  </p>
</div>

---

## What it is

`dragonfruit` is a dependency for ordinary, line-oriented CLI output. It gives
Zig programs consistent color, status icons, percentages, progress bars, and
spinners while leaving argument parsing, scheduling, and terminal ownership to
the application.

It is deliberately **not** a TUI framework: it never enters the alternate
screen, hides the cursor, handles input, or rewrites a line. Components render
to a caller-provided `std.Io.Writer`; they allocate no memory and do not depend
on timers, threads, or a terminal library.

## Add the dependency

```sh
zig fetch --save https://github.com/JustinWoodring/dragonfruit/archive/refs/heads/main.tar.gz
```

Then expose its module from `build.zig`:

```zig
const dragonfruit = b.dependency("dragonfruit", .{});
const module = b.addModule("my_cli", .{
    .root_source_file = b.path("src/root.zig"),
    .target = target,
    .imports = &.{.{ .name = "dragonfruit", .module = dragonfruit.module("dragonfruit") }},
});
```

Use it from a module with `const cli = @import("dragonfruit");`.

## Example

```zig
const std = @import("std");
const cli = @import("dragonfruit");

// Inside a command function that receives `io`, `env`, and `out`.
const no_color = if (env.get("NO_COLOR")) |value| value.len != 0 else false;
const force_color = if (env.get("CLICOLOR_FORCE")) |value| value.len != 0 else false;
const style = cli.Style.resolve(
    .auto,
    std.Io.File.stdout().isTty(io) catch false,
    no_color,
    force_color,
    std.mem.eql(u8, env.get("TERM") orelse "", "dumb"),
);
const glyphs: cli.Glyphs = .{ .unicode = true };

try cli.status(out, style, glyphs, .success, "installed {s}", .{"zest"});
try cli.progress.writeBar(out, style, glyphs, completed, total, 24);
try out.writeAll("\n");

var spinner: cli.Spinner = .{ .glyphs = glyphs };
try spinner.write(out, style);
spinner.advance(); // The application decides when to advance; no background task.
```

`NO_COLOR` disables automatic color; color is otherwise automatic only for a
terminal. `CLICOLOR_FORCE` enables auto-mode color for redirected output unless
`NO_COLOR` is set. `ColorMode.always` and `.never` let applications override
that policy deliberately. Select `Glyphs{ .unicode = false }` for ASCII-only
output.

## Components

- `Style`: named semantic tones; direct writer formatting with ANSI reset codes.
- `status`: success, info, warning, and failure markers in Unicode or ASCII.
- `progress.percentage`: bounded integer percentages; `null` for an unknown
  total (`0 / 0` is not reported as completed).
- `progress.writeBar`: fixed-width bar, safe over-completion, unknown-total
  display, and optional color.
- `Spinner`: deterministic caller-ticked frames; no timing or cursor control.
- `Glyphs`: shared logo, arrows, bullets, status markers, and progress glyphs.

All output is plain text when color is disabled. `--json` and other
machine-readable output should bypass these presentation helpers.

## Development

Requirements: Zig 0.16.0 or newer.

```sh
zig build test
zig fmt --check src build.zig
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow and [CONTRIBUTORS](CONTRIBUTORS)
for credits.

## License

[MIT](LICENSE). Copyright (c) 2026 Justin Woodring.
