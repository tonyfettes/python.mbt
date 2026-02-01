---
name: moon-test
description: Guide for running MoonBit tests with `moon test`. Use when running tests, filtering tests by name (-F) or file (-f), selecting packages (-p), or using AddressSanitizer (ASan) with --release flag and PYTHONMALLOC=malloc.
---

# Moon Test Usage

## Basic Usage

```bash
moon test --target native
```

## Filtering Tests

- `-F <pattern>`: Filter by test name using glob patterns (`*` matches any sequence, `?` matches single char)
- `-f <file>`: Filter by file name

```bash
# Exact test name
moon test -p Kaida-Amethyst/python/test -F "PyInteger Test" --target native

# Glob pattern - all RC Bug tests
moon test -p Kaida-Amethyst/python/test -F "RC Bug*" --target native
```

## Package Selection

Use `-p` to specify the package:

```bash
moon test -p Kaida-Amethyst/python/test --target native
```

## ASan with Release Mode

This project has AddressSanitizer enabled. Use `--release` to avoid ASan interceptor issues on macOS:

```bash
moon test --target native --release
```

Without `--release`, you may see: `ERROR: Interceptors are not working`

## ASan with Python Memory Bugs

Python uses pymalloc, a custom memory allocator that pools memory. ASan cannot detect use-after-free within pymalloc's pools.

To detect Python memory bugs (RC bugs, use-after-free), force Python to use system malloc:

```bash
PYTHONMALLOC=malloc moon test -p Kaida-Amethyst/python/test -F "RC Bug*" --target native --release
```

**Warning:** `PYTHONMALLOC=malloc` causes false positives due to MoonBit's RC system. MoonBit reads 8 bytes before object pointers to access reference counts (`Moonbit_object_header(ptr) = ptr - 1`). When `PyObjectRef` (raw Python pointer) is stored in a MoonBit struct, the compiler incorrectly tries to apply MoonBit RC to it, reading into ASan's red zones. This is a MoonBit limitation - tests pass without `PYTHONMALLOC=malloc`.

## Flags Summary

| Flag | Description |
|------|-------------|
| `--target native` | Native target (required for this project) |
| `--release` | Release mode (needed for ASan on macOS) |
| `-p <package>` | Specify package to test |
| `-F <pattern>` | Filter tests by name (glob: `*`, `?`) |
| `-f <file>` | Filter tests by file |
| `--build-only` | Build without running |
| `-u` | Update test expectations |

## Environment Variables

| Variable | Description |
|----------|-------------|
| `PYTHONMALLOC=malloc` | Use system malloc instead of pymalloc (required for ASan to detect Python memory bugs) |
