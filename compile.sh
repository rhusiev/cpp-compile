#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

debug_build=true
optimize_build=false
remove_dirs=false
install_prefix=".."
pipeline=false
sanitizers=false

while [[ $# -gt 0 ]]; do
  case $1 in
  -I  | --install_prefix)
    if [ "$2" -eq "$2" ] 2>/dev/null; then
      install_prefix=$2
      shift 2
    else
      echo "Option --install_prefix requires an numerical argument." >&2
      exit 1
    fi
    ;;
  -d | --debug-build)
    debug_build=true
    shift
    ;;
  -o | --optimize-build)
    optimize_build=true
    debug_build=false
    shift
    ;;
  -R | --remove-build-dirs)
    remove_dirs=true
    shift
    ;;
  -p | --pipeline)
    pipeline=true
    shift
    ;;
  --s=*)
    sanitizers=true
    sanitizers_args="${1#*=}"
    shift
    ;;
  -h | --help)
    echo "Usage: ./compile.sh [options]
  Options:
    -h      --help                  Show help message.
    -o      --optimize-build        Compile with optimization before executing.
    -d      --debug-build           Compile with debug options.
    -I      --install_prefix        Installation path.
    -R      --remove-build-dirs     Remove build dirs after the install.
    -p      --pipeline              Enable pipeline of different compilers and sanitizers.
    --s='<args>'                    Arguments for program when run under valgrind and sanitizers. If '--s' not present, valgrind and sanitizers will not be executed."
    exit 0
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    exit 1
    ;;
  :)
    echo "Option -$OPTARG requires an numerical argument." >&2
    exit 1
    ;;
  *)
    break
    ;;
  esac
done


handle_error() {
    echo "Something went wrong, restoring the original CMakeLists.txt"
    sed -i 's/set(ENABLE_UBSan ON)/set(ENABLE_UBSan OFF)/g' ../CMakeLists.txt
    sed -i 's/set(ENABLE_ASAN ON)/set(ENABLE_ASAN OFF)/g' ../CMakeLists.txt
    sed -i 's/set(ENABLE_TSan ON)/set(ENABLE_TSan OFF)/g' ../CMakeLists.txt
    sed -i 's/set(ENABLE_MSan ON)/set(ENABLE_MSan OFF)/g' ../CMakeLists.txt
    sed -i "s/clang-ubsan)/${project_name})/g" ../CMakeLists.txt
    sed -i "s/clang-asan)/${project_name})/g" ../CMakeLists.txt
    sed -i "s/clang-tsan)/${project_name})/g" ../CMakeLists.txt
    sed -i "s/clang-msan)/${project_name})/g" ../CMakeLists.txt
    sed -i "s/ENABLE_PVS_STUDIO ON)/ENABLE_PVS_STUDIO OFF)/g" ../CMakeLists.txt
    sed -i 's/#set(CMAKE_CXX_CLANG_TIDY "clang-tidy;-checks=\*")/set(CMAKE_CXX_CLANG_TIDY "clang-tidy;-checks=\*")/g' ../CMakeLists.txt
    cd ..
    remove_pvs_headers
    cd -
    exit 1
}

add_pvs_headers() {
    cd ..
    find . -type f -name "*.cpp" -o -name "*.c" -o -name "*.hpp" -o -name "*.h" | grep -P '.*\/[^.]*\.(cpp|c|hpp|h)$' > files.txt
    echo "**Adding PVS headers to the files:**" >&2
    # Remove files whose names start with "cmake", "CMake" or "./cmake" or "./CMake"
    sed -i '/^\.\/cmake/d' files.txt
    sed -i '/^\.\/CMake/d' files.txt
    sed -i '/^cmake/d' files.txt
    sed -i '/^CMake/d' files.txt
    cat files.txt >&2
    while IFS= read -r file; do
        if [[ $(head -n 1 "$file") != "// This is a personal academic project. Dear PVS-Studio, please check it." ]]; then
            sed -i '1s/^/\/\/ This is a personal academic project. Dear PVS-Studio, please check it.\n\/\/ PVS-Studio Static Code Analyzer for C, C++, C#, and Java: http:\/\/www.viva64.com\n/' "$file"
        fi
    done < files.txt
    rm files.txt
    cd -
}

remove_pvs_headers() {
    find . -type f -name "*.cpp" -o -name "*.c" -o -name "*.hpp" -o -name "*.h" | grep -P '.*\/[^.]*\.(cpp|c|hpp|h)$' > files.txt
    echo "**Removing PVS headers from files:**" >&2
    # Remove files whose names start with "cmake", "CMake" or "./cmake" or "./CMake"
    sed -i '/^\.\/cmake/d' files.txt
    sed -i '/^\.\/CMake/d' files.txt
    sed -i '/^cmake/d' files.txt
    sed -i '/^CMake/d' files.txt
    # cat files.txt | sed 's/^/ /' >&2
    cat files.txt >&2
    while IFS= read -r file; do
        if [[ $(head -n 1 "$file") == "// This is a personal academic project. Dear PVS-Studio, please check it." ]]; then
            sed -i '1,2d' "$file"
        fi
    done < files.txt
    rm files.txt
}

if [[ "$pipeline" == true ]]; then
    mkdir -p ./cmake-build-debug
    (
        pushd ./cmake-build-debug > /dev/null || exit 1
        # Find the project_name in `set(PROJECT project_name)`
        project_name=$(grep -oP '(?<=set\(PROJECT ).*(?=\))' ../CMakeLists.txt)
        # CLANG
        sed -i "s/ENABLE_PVS_STUDIO ON)/ENABLE_PVS_STUDIO OFF)/g" ../CMakeLists.txt
        sed -i 's/set(CMAKE_CXX_CLANG_TIDY "clang-tidy;-checks=\*")/#set(CMAKE_CXX_CLANG_TIDY "clang-tidy;-checks=\*")/g' ../CMakeLists.txt

        sed -i 's/set(ENABLE_UBSan OFF)/set(ENABLE_UBSan ON)/g' ../CMakeLists.txt
        sed -i "s/${project_name})/clang-ubsan)/g" ../CMakeLists.txt
        echo "====Compiling with Clang UBSan====" >&2
        CC=clang CXX=clang++ cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || handle_error
        cmake --build . || handle_error
        cmake --install . || handle_error

        echo "====Compiling with Clang ASan====" >&2
        sed -i 's/set(ENABLE_UBSan ON)/set(ENABLE_UBSan OFF)/g' ../CMakeLists.txt
        sed -i 's/set(ENABLE_ASAN OFF)/set(ENABLE_ASAN ON)/g' ../CMakeLists.txt
        sed -i 's/clang-ubsan)/clang-asan)/g' ../CMakeLists.txt
        CC=clang CXX=clang++ cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || handle_error
        cmake --build . || handle_error
        cmake --install . || handle_error

        echo "====Compiling with Clang TSan====" >&2
        sed -i 's/set(ENABLE_ASAN ON)/set(ENABLE_ASAN OFF)/g' ../CMakeLists.txt
        sed -i 's/set(ENABLE_TSan OFF)/set(ENABLE_TSan ON)/g' ../CMakeLists.txt
        sed -i 's/clang-asan)/clang-tsan)/g' ../CMakeLists.txt
        CC=clang CXX=clang++ cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || handle_error
        cmake --build . || handle_error
        cmake --install . || handle_error

        echo "====Compiling with Clang MSan====" >&2
        sed -i 's/set(ENABLE_TSan ON)/set(ENABLE_TSan OFF)/g' ../CMakeLists.txt
        sed -i 's/set(ENABLE_MSan OFF)/set(ENABLE_MSan ON)/g' ../CMakeLists.txt
        sed -i 's/clang-tsan)/clang-msan)/g' ../CMakeLists.txt
        CC=clang CXX=clang++ cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || handle_error
        cmake --build . || handle_error
        cmake --install . || handle_error
        sed -i 's/set(ENABLE_MSan ON)/set(ENABLE_MSan OFF)/g' ../CMakeLists.txt
        sed -i "s/clang-msan)/${project_name})/g" ../CMakeLists.txt

        # GCC
        echo "====Compiling with GCC + PVS + clang-tidy====" >&2
        add_pvs_headers
        if [ -f /app/project/cmake/extra/PVS-Studio.cmake ]; then sed -i "s/cmake_minimum_required(VERSION 2.8.12)/cmake_minimum_required(VERSION 3.5)/g" /app/project/cmake/extra/PVS-Studio.cmake; fi
        sed -i "s/ENABLE_PVS_STUDIO OFF)/ENABLE_PVS_STUDIO ON)/g" ../CMakeLists.txt
        sed -i 's/#set(CMAKE_CXX_CLANG_TIDY "clang-tidy;-checks=\*")/set(CMAKE_CXX_CLANG_TIDY "clang-tidy;-checks=\*")/g' ../CMakeLists.txt
        CC=gcc CXX=g++ cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || handle_error
        cmake --build . || handle_error
        cmake --install . || handle_error
        sed -i "s/ENABLE_PVS_STUDIO ON)/ENABLE_PVS_STUDIO OFF)/g" ../CMakeLists.txt
        popd
    )
    # Remove PVS things
    remove_pvs_headers
    exit 0
fi

if [[ "$sanitizers" == true ]]; then
    echo "====Running with Valgrind and Sanitizers====" >&2
    echo "Sanitizers args: $sanitizers_args" >&2
    echo "====Valgrind====" >&2
    valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes ./bin/$project_name $sanitizers_args >&2 || handle_error
    echo "====Valgrind Helgrind====" >&2
    valgrind --tool=helgrind ./bin/$project_name $sanitizers_args >&2 || handle_error
    echo "====Valgrind DRD====" >&2
    valgrind --tool=drd ./bin/$project_name $sanitizers_args >&2 || handle_error
    echo "====UBSan====" >&2
    ./bin/clang-ubsan $sanitizers_args >&2 || handle_error
    echo "====ASan====" >&2
    ./bin/clang-asan $sanitizers_args >&2 || handle_error
    echo "====TSan====" >&2
    ./bin/clang-tsan $sanitizers_args >&2 || handle_error
    echo "====MSan====" >&2
    ./bin/clang-msan $sanitizers_args >&2 || handle_error
fi

if [[ "$debug_build" == true ]]; then
  mkdir -p ./cmake-build-debug
  (
    pushd ./cmake-build-debug > /dev/null || exit 1
    echo Compiling...
    cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || exit 1
    cmake --build . || exit 1
    cmake --install . || exit 1
    popd
  )
fi

if [[ "$optimize_build" == true ]]; then
  mkdir -p ./cmake-build-release
  (
    pushd ./cmake-build-release >/dev/null || exit 1
    echo Compiling...
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || exit 1
    cmake --build . || exit 1
    cmake --install . || exit 1
    popd
  )
fi

if [[ "$remove_dirs" == true ]]; then
  rm -rf ./cmake-build-debug ./cmake-build-release
fi
