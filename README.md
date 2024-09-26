# cpp-compile

A script and a docker image to compile `c++` programs efficiently.

# Requirements

- docker or podman
- bash

Files and directories, required to be in project:
- cmake
- CMakeLists.txt
- project.Dockerfile

You can also place `compile.sh` in the project, if you want to customize it.

If you do not place your custom `compile.sh`, the default one will be used.

# Run

Replace `PROJECT` with your project name.

```sh
docker build -t PROJECT -f ./project.Dockerfile
docker run --rm -ti -v .:/app/project:z PROJECT -h
```

When using this command to run, the current directory will be mounted into `/app/project` inside docker. Therefore you do not need to rebuild the image after changing some files (except for `compile.sh` and `CMakeLists.txt` - after changing them, you need to rebuild).

The default behavior of `docker run --rm -ti -v .:/app/project:z PROJECT` is to run `compile.sh`. All the arguments after it are passed to `compile.sh`.

If you do not need dockerization, you can just copy `compile.sh` to your project and run it with same arguments.

## Debug

To run a docker and compile (using `cmake`) in debug mode:

```sh
docker run --rm -ti -v .:/app/project:z PROJECT -d
```

## Release/optimized

To run a docker and compile (using `cmake`) in optimized (release) mode:

```sh
docker run --rm -ti -v .:/app/project:z PROJECT -o
```

## Pipeline

If you want to run docker with a pipeline run the command below. It will compile with different sanitizers, pvs studio and clang-tidy (if you replace `##set(CMAKE_CXX_CLANG_TIDY "clang-tidy;-checks=*")` with `#set(CMAKE_CXX_CLANG_TIDY "clang-tidy;-checks=*")`)

```sh
docker run --rm -ti -v .:/app/project:z PROJECT -p
```

## Valgrind and sanitizers

If you want to also run valgrind and sanitizers after the compilation, run the following command:

```sh
docker run --rm -ti -v .:/app/project:z PROJECT --s="<options>"
```

It will run with valgrind and sanitizers on your program after the run and pass the options to your program.

# Docker image

The docker image is fedora based, which means you will need to use `dnf` as a package manager in `project.Dockerfile`, if you want to change installed programs.

However, the image comes preinstalled with:
- CMake, Make, Ninja
- Clang, GCC
- Git, Wget
- Python 3
- Valgrind
- Boost (a `c++` library)
- PVS Studio
- clang-tidy, clang-format, cppcheck

# Headers for lsp

To make lsp (such as clangd) know about headers included in cmake, you can run the following command after runnign with `-d`:

```sh
sed -i "s/\/app\/project/$(echo ${PWD} | sed 's/\//\\\//g')/g" cmake-build-debug/compile_commands.json && cp cmake-build-debug/compile_commands.json .
```
