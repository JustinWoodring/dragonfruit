# Contributing to dragonfruit

Thanks for improving dragonfruit. Keep changes focused on predictable, line-oriented CLI presentation.

## Getting set up

Requirements: Zig 0.16.0 or newer.

```sh
git clone https://github.com/JustinWoodring/dragonfruit
cd dragonfruit
zig build test
```

## Development workflow

Run the relevant checks before opening a pull request:

```sh
zig build test
zig fmt --check src build.zig
```

Every behavior change needs an assertion that protects a consumer-visible
invariant. Keep tests deterministic and independent of terminal state; pass
color policy and glyph choices explicitly.

## Code style

- Format with canonical `zig fmt`; use four spaces and prefer `const`.
- Keep public declarations documented with `///` comments that explain their
  contract and edge cases.
- Put a copyright and `SPDX-License-Identifier: MIT` header in each Zig source
  file.
- Keep rendering allocation-free and scoped to caller-provided writers.
- Do not add cursor control, input handling, timers, threads, hidden global
  state, or a terminal dependency. Applications own those policies.
- Keep JSON and other machine-readable output separate from human presentation.
- Preserve graceful output with `NO_COLOR`, redirected streams, unknown totals,
  and ASCII-only terminals.

## Pull requests

1. Make a focused change and add behavior-level coverage.
2. Run `zig build test` and `zig fmt --check src build.zig`.
3. Update `README.md` for public API or output changes.
4. Open a pull request describing the behavior and compatibility impact.

## Versioning and releases

`main` is the development branch. Releases are made by the maintainer with
annotated `vX.Y.Z` tags. Contributors should open a pull request rather than
pushing tags.

## Licensing

Contributions are licensed under this project's MIT license. Add your name to
[CONTRIBUTORS](CONTRIBUTORS) if you would like credit.
