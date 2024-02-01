# Use the first image as a base
FROM ghcr.io/rhusiev/cpp-compile:latest

# Set the working directory
WORKDIR /app/project

# Mount the project directory instead of copying it
VOLUME /app/project

COPY CMakeLists.txt compile.s[h] /app/

# Run the ./compile.sh script
ENTRYPOINT ["/bin/bash", "../pipeline-compile.sh"]
