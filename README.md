# sqlite.zig

This repository has [zig][] bindings for sqlite. It trys to make the sqlite c
API more ziggish.

[zig]: https://ziglang.org/ 

## Usage

Add `src/sqlite.zig` as a package in your `build.zig`, and then add the sqlite
and c libraries:

```zig
example.addPackagePath("sqlite", "path/to/deps/sqlite/src/sqlite.zig");
example.linkSystemLibrary("sqlite3");
example.linkSystemLibrary("c");
```

Make sure you have `sqlite3` installed on you system.

`sqlite.zig` was developed with `zig 0.5.0+ab4ea5d3c`.

## Examples

`TODO`
