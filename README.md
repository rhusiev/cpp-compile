# Requirements

Files and directories, required to be in project:
- cmake
- CMakeLists.txt
- project.Dockerfile

You can also place `compile.sh` in the project, if you want a modified version

# Run

```sh
docker build -t PROJECT -f ./project.Dockerfile
docker run --rm -v .:/app/project:z PROJECT
```

## Pipeline

If you want to run with a pipeline (using different sanitizers, linters etc), run the following command:

```sh
docker run --rm -v .:/app/project:z PROJECT -p
```

## Valgrind

If you want to also run with valgrind, run the following command:

```sh
docker run --rm -v .:/app/project:z PROJECT --v="<valgrind options>"
```

It will run with valgrind after the run and pass the options to valgrind

# Headers for lsp

To make lsp (such as clangd) know about headers included in cmake, you can run the following command:

```sh
sed -i "s/\/app\/project/$(echo ${PWD} | sed 's/\//\\\//g')/g" cmake-build-debug/compile_commands.json && cp cmake-build-debug/compile_commands.json .
```
