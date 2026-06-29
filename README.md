# cpp-app-template

C++ app template.

## Build

```sh
cmake -S . -B build
cmake --build build
```

## Test

```sh
cmake --build build --target test
```

## Install

```sh
cmake --install build --prefix /tmp/root
```

If no prefix is specified, CMake installs to `/usr/local` by default on Unix systems.
