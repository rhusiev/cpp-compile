```sh
docker build -t PROJECT -f ./project.Dockerfile
docker run --rm -v .:/app/project:z PROJECT
```
