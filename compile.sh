#!/bin/bash
# The Tea-Ware License (Version 2.0)
# Copyright (c) 2024 Radomyr Husiev <h.radomyr@proton.me>
#
# This script is part of a project licensed under the Tea-Ware License.
# Feel free to use, modify, and distribute this script, keeping this notice intact.
# If we meet and you find this useful, a cup of tea would be appreciated!
# 
# Full license: https://github.com/rhusiev/Tea-Ware-License-v2

set -o errexit
set -o nounset
set -o pipefail

install_prefix=".."

call_location=$(pwd)
echo "" > $call_location/compile.log
handle_output() {
    while IFS= read -r line; do
        echo "$line" | tee -a $call_location/compile.log | grep --invert-match ".*\(Consider enabling PVS-Studio\|Sanitizers enabled\|[Ee]nabled in CMakeLists.txt\).*"
    done
}

echo "===Starting===" 2>&1 | handle_output

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
	find . -type f -name "*.cpp" -o -name "*.c" -o -name "*.hpp" -o -name "*.h" | grep -P '.*\/[^.]*\.(cpp|c|hpp|h)$' >files.txt
	echo "**Adding PVS headers to the files:**" 2>&1 | handle_output
	# Remove files whose names start with "cmake", "CMake" or "./cmake" or "./CMake"
	sed -i '/^\.\/cmake/d' files.txt
	sed -i '/^\.\/CMake/d' files.txt
	sed -i '/^cmake/d' files.txt
	sed -i '/^CMake/d' files.txt
	cat files.txt 2>&1 | handle_output
	while IFS= read -r file; do
		if [[ $(head -n 1 "$file") != "// This is a personal academic project. Dear PVS-Studio, please check it." ]]; then
			sed -i '1s/^/\/\/ This is a personal academic project. Dear PVS-Studio, please check it.\n\/\/ PVS-Studio Static Code Analyzer for C, C++, C#, and Java: http:\/\/www.viva64.com\n/' "$file"
		fi
	done <files.txt
	rm files.txt
	cd -
}

remove_pvs_headers() {
	find . -type f -name "*.cpp" -o -name "*.c" -o -name "*.hpp" -o -name "*.h" | grep -P '.*\/[^.]*\.(cpp|c|hpp|h)$' >files.txt
	echo "**Removing PVS headers from files:**" 2>&1 | handle_output
	# Remove files whose names start with "cmake", "CMake" or "./cmake" or "./CMake"
	sed -i '/^\.\/cmake/d' files.txt
	sed -i '/^\.\/CMake/d' files.txt
	sed -i '/^cmake/d' files.txt
	sed -i '/^CMake/d' files.txt
	# cat files.txt | sed 's/^/ /' 2>&1 | handle_output
	cat files.txt 2>&1 | handle_output
	while IFS= read -r file; do
		if [[ $(head -n 1 "$file") == "// This is a personal academic project. Dear PVS-Studio, please check it." ]]; then
			sed -i '1,2d' "$file"
		fi
	done <files.txt
	rm files.txt
}

pipeline() {
	echo "===Running with Pipeline===" 2>&1 | handle_output
	mkdir -p ./cmake-build-debug
	(
		pushd ./cmake-build-debug >/dev/null || exit 1
		# Find the project_name in `set(PROJECT project_name)`
		project_name=$(grep -oP '(?<=set\(PROJECT ).*(?=\))' ../CMakeLists.txt)
		# CLANG
		sed -i "s/ENABLE_PVS_STUDIO ON)/ENABLE_PVS_STUDIO OFF)/g" ../CMakeLists.txt
		sed -i 's/set(CMAKE_CXX_CLANG_TIDY "clang-tidy;-checks=\*")/#set(CMAKE_CXX_CLANG_TIDY "clang-tidy;-checks=\*")/g' ../CMakeLists.txt

		sed -i 's/set(ENABLE_UBSan OFF)/set(ENABLE_UBSan ON)/g' ../CMakeLists.txt
		sed -i "s/${project_name})/clang-ubsan)/g" ../CMakeLists.txt
		echo "====Compiling with Clang UBSan====" 2>&1 | handle_output
		CC=clang CXX=clang++ cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. 2>&1 | handle_output || handle_error
		cmake --build . 2>&1 | handle_output || handle_error
		cmake --install . 2>&1 | handle_output || handle_error

		echo "====Compiling with Clang ASan====" 2>&1 | handle_output
		sed -i 's/set(ENABLE_UBSan ON)/set(ENABLE_UBSan OFF)/g' ../CMakeLists.txt
		sed -i 's/set(ENABLE_ASAN OFF)/set(ENABLE_ASAN ON)/g' ../CMakeLists.txt
		sed -i 's/clang-ubsan)/clang-asan)/g' ../CMakeLists.txt
		CC=clang CXX=clang++ cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. 2>&1 | handle_output || handle_error
		cmake --build . 2>&1 | handle_output || handle_error
		cmake --install . 2>&1 | handle_output || handle_error

		echo "====Compiling with Clang TSan====" 2>&1 | handle_output
		sed -i 's/set(ENABLE_ASAN ON)/set(ENABLE_ASAN OFF)/g' ../CMakeLists.txt
		sed -i 's/set(ENABLE_TSan OFF)/set(ENABLE_TSan ON)/g' ../CMakeLists.txt
		sed -i 's/clang-asan)/clang-tsan)/g' ../CMakeLists.txt
		CC=clang CXX=clang++ cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. 2>&1 | handle_output || handle_error
		cmake --build . 2>&1 | handle_output || handle_error
		cmake --install . 2>&1 | handle_output || handle_error

		echo "====Compiling with Clang MSan====" 2>&1 | handle_output
		sed -i 's/set(ENABLE_TSan ON)/set(ENABLE_TSan OFF)/g' ../CMakeLists.txt
		sed -i 's/set(ENABLE_MSan OFF)/set(ENABLE_MSan ON)/g' ../CMakeLists.txt
		sed -i 's/clang-tsan)/clang-msan)/g' ../CMakeLists.txt
		CC=clang CXX=clang++ cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. 2>&1 | handle_output || handle_error
		cmake --build . 2>&1 | handle_output || handle_error
		cmake --install . 2>&1 | handle_output || handle_error
		sed -i 's/set(ENABLE_MSan ON)/set(ENABLE_MSan OFF)/g' ../CMakeLists.txt
		sed -i "s/clang-msan)/${project_name})/g" ../CMakeLists.txt

		# GCC
		echo "====Compiling with GCC + PVS + clang-tidy====" 2>&1 | handle_output
		add_pvs_headers
		if [ -f /app/project/cmake/extra/PVS-Studio.cmake ]; then sed -i "s/cmake_minimum_required(VERSION 2.8.12)/cmake_minimum_required(VERSION 3.5)/g" /app/project/cmake/extra/PVS-Studio.cmake; fi
		sed -i "s/ENABLE_PVS_STUDIO OFF)/ENABLE_PVS_STUDIO ON)/g" ../CMakeLists.txt
		sed -i 's/#set(CMAKE_CXX_CLANG_TIDY "clang-tidy;-checks=\*")/set(CMAKE_CXX_CLANG_TIDY "clang-tidy;-checks=\*")/g' ../CMakeLists.txt
		CC=gcc CXX=g++ cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. 2>&1 | handle_output || handle_error
		cmake --build . 2>&1 | handle_output || handle_error
		cmake --install . 2>&1 | handle_output || handle_error
		sed -i "s/ENABLE_PVS_STUDIO ON)/ENABLE_PVS_STUDIO OFF)/g" ../CMakeLists.txt
		popd
	)
	# Remove PVS things
	remove_pvs_headers
	exit 0
}

sanitizers() {
    sanitizers_args=$1
	echo "===Running with Valgrind and Sanitizers===" 2>&1 | handle_output
	echo "Sanitizers args: $sanitizers_args" 2>&1 | handle_output
	project_name=$(grep -oP '(?<=set\(PROJECT ).*(?=\))' ./CMakeLists.txt)
	echo "====Valgrind====" 2>&1 | handle_output
	valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes ./bin/$project_name $sanitizers_args 2>&1 | handle_output || handle_error
	echo "====Valgrind Helgrind====" 2>&1 | handle_output
	valgrind --tool=helgrind ./bin/$project_name $sanitizers_args 2>&1 | handle_output || handle_error
	echo "====Valgrind DRD====" 2>&1 | handle_output
	valgrind --tool=drd ./bin/$project_name $sanitizers_args 2>&1 | handle_output || handle_error
	echo "====UBSan====" 2>&1 | handle_output
	./bin/clang-ubsan $sanitizers_args 2>&1 | handle_output || handle_error
	echo "====ASan====" 2>&1 | handle_output
	./bin/clang-asan $sanitizers_args 2>&1 | handle_output || handle_error
	echo "====TSan====" 2>&1 | handle_output
	./bin/clang-tsan $sanitizers_args 2>&1 | handle_output || handle_error
	echo "====MSan====" 2>&1 | handle_output
	./bin/clang-msan $sanitizers_args 2>&1 | handle_output || handle_error
}

debug() {
    echo "===Running with Debug Build===" 2>&1 | handle_output
	mkdir -p ./cmake-build-debug
	(
		pushd ./cmake-build-debug >/dev/null || exit 1
		cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. 2>&1 | handle_output || exit 1
		cmake --build . 2>&1 | handle_output || exit 1
		cmake --install . 2>&1 | handle_output || exit 1
		popd
	)
}

optimize() {
    echo "===Running with Optimize Build===" 2>&1 | handle_output
	mkdir -p ./cmake-build-release
	(
		pushd ./cmake-build-release >/dev/null || exit 1
		cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. 2>&1 | handle_output || exit 1
		cmake --build . 2>&1 | handle_output || exit 1
		cmake --install . 2>&1 | handle_output || exit 1
		popd
	)
}

relwithdebinfo() {
    echo "===Running with Release Debug Info===" 2>&1 | handle_output
    mkdir -p ./cmake-build-relwithdebinfo
    (
        pushd ./cmake-build-relwithdebinfo >/dev/null || exit 1
        cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. 2>&1 | handle_output || exit 1
		cmake --build . 2>&1 | handle_output || exit 1
		cmake --install . 2>&1 | handle_output || exit 1
		popd
    )
}

clean() {
    echo "===Cleaning===" 2>&1 | handle_output
    rm -rf cmake-build-* compile.log
}

run() {
    echo "===Running custom command===" 2>&1 | handle_output
    run_args=$1
    echo "Running command: '$run_args'" 2>&1 | handle_output
    eval $run_args 2>&1 | handle_output
}

while [[ $# -gt 0 ]]; do
	case $1 in
	-I | --install_prefix)
		if [ "$2" -eq "$2" ] 2>/dev/null; then
			install_prefix=$2
			shift 2
		else
			echo "Option --install_prefix requires an numerical argument." 2>&1 | handle_output
			exit 1
		fi
		;;
	-d | --debug-build)
        debug
		shift
		;;
	-o | --optimize-build)
        optimize
		shift
		;;
    -i | --relwithdebinfo-build)
        relwithdebinfo
		shift
		;;
	-p | --pipeline)
        pipeline
		shift
		;;
	-c | --clean)
        clean
		shift
		;;
	--s=*)
		sanitizers_args="${1#*=}"
        sanitizers $sanitizers_args
		shift
		;;
	--r=*)
		run_args="${1#*=}"
        run "$run_args"
		shift
		;;
	-h | --help)
		echo "Usage: ./compile.sh [options]
  Options:
    -h      --help                  Show help message
    -o      --optimize-build        Compile with optimization before executing
    -d      --debug-build           Compile with debug options
    -i      --relwithdebinfo-build  Compile with release debug info
    -I      --install_prefix        Installation path
    -p      --pipeline              Enable pipeline of different compilers and sanitizers
    -c      --clean                 Clean cmake-build-* directories and compile.log
    --s='<args>'                    Arguments for program when run under valgrind and sanitizers. If '--s' not present, valgrind and sanitizers will not be executed
    --r='<value>'                   Run the value as a bash command"
		exit 0
		;;
	\?)
		echo "Invalid option: -$OPTARG" 2>&1 | handle_output
		exit 1
		;;
	:)
		echo "Option -$OPTARG requires an numerical argument." 2>&1 | handle_output
		exit 1
		;;
	*)
		break
		;;
	esac
done
