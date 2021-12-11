id: mczp9pu884wtf8fjk7uiejflopxg1wjej6yxqa67rb4vy9ji
name: sqlite3
main: src/sqlite3.zig
license: MIT
description: Zig bindings to sqlite3
c_source_files:
 - dep/sqlite/sqlite3.c
c_include_dirs:
 - dep/sqlite
dependencies:
- src: system_lib sqlite3
