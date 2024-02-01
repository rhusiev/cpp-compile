Files and directories, required to be in project:
- cmake
- CMakeLists.txt
- project.Dockerfile

You can also place `compile.sh` in the project, if you want a modified version

```sh
docker build -t PROJECT -f ./project.Dockerfile
docker run --rm -v .:/app/project:z PROJECT
```
