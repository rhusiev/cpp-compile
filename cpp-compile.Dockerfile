# Use a base image
FROM stabletec/build-core:fedora

# Install dependencies
RUN dnf update -y -q 

RUN wget -q -O /etc/yum.repos.d/viva64.repo \
 https://files.pvs-studio.com/etc/viva64.repo \
 && dnf install -y -q pvs-studio strace \
 && pvs-studio --version

RUN dnf install -y -q wget boost-devel valgrind \
 && dnf clean all -y -q

RUN pvs-studio-analyzer credentials PVS-Studio Free FREE-FREE-FREE-FREE

COPY compile.sh /app/compile.sh
