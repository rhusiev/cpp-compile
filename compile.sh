#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

install_prefix=".."

handle_output() {
	cat /dev/stdin <(cat - | >&2 | 2>&1 | tee compile.log | grep --invert-match ".*\(Consider enabling PVS-Studio\|Sanitizers enabled\|[Ee]nabled in CMakeLists.txt\).*")
}

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
	echo "**Adding PVS headers to the files:**" | handle_output
	# Remove files whose names start with "cmake", "CMake" or "./cmake" or "./CMake"
	sed -i '/^\.\/cmake/d' files.txt
	sed -i '/^\.\/CMake/d' files.txt
	sed -i '/^cmake/d' files.txt
	sed -i '/^CMake/d' files.txt
	cat files.txt | handle_output
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
	echo "**Removing PVS headers from files:**" | handle_output
	# Remove files whose names start with "cmake", "CMake" or "./cmake" or "./CMake"
	sed -i '/^\.\/cmake/d' files.txt
	sed -i '/^\.\/CMake/d' files.txt
	sed -i '/^cmake/d' files.txt
	sed -i '/^CMake/d' files.txt
	# cat files.txt | sed 's/^/ /' | handle_output
	cat files.txt | handle_output
	while IFS= read -r file; do
		if [[ $(head -n 1 "$file") == "// This is a personal academic project. Dear PVS-Studio, please check it." ]]; then
			sed -i '1,2d' "$file"
		fi
	done <files.txt
	rm files.txt
}

pipeline() {
	echo "===Running with Pipeline===" | handle_output
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
		echo "====Compiling with Clang UBSan====" | handle_output
		CC=clang CXX=clang++ cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || handle_error
		cmake --build . || handle_error
		cmake --install . || handle_error

		echo "====Compiling with Clang ASan====" | handle_output
		sed -i 's/set(ENABLE_UBSan ON)/set(ENABLE_UBSan OFF)/g' ../CMakeLists.txt
		sed -i 's/set(ENABLE_ASAN OFF)/set(ENABLE_ASAN ON)/g' ../CMakeLists.txt
		sed -i 's/clang-ubsan)/clang-asan)/g' ../CMakeLists.txt
		CC=clang CXX=clang++ cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || handle_error
		cmake --build . || handle_error
		cmake --install . || handle_error

		echo "====Compiling with Clang TSan====" | handle_output
		sed -i 's/set(ENABLE_ASAN ON)/set(ENABLE_ASAN OFF)/g' ../CMakeLists.txt
		sed -i 's/set(ENABLE_TSan OFF)/set(ENABLE_TSan ON)/g' ../CMakeLists.txt
		sed -i 's/clang-asan)/clang-tsan)/g' ../CMakeLists.txt
		CC=clang CXX=clang++ cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || handle_error
		cmake --build . || handle_error
		cmake --install . || handle_error

		echo "====Compiling with Clang MSan====" | handle_output
		sed -i 's/set(ENABLE_TSan ON)/set(ENABLE_TSan OFF)/g' ../CMakeLists.txt
		sed -i 's/set(ENABLE_MSan OFF)/set(ENABLE_MSan ON)/g' ../CMakeLists.txt
		sed -i 's/clang-tsan)/clang-msan)/g' ../CMakeLists.txt
		CC=clang CXX=clang++ cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || handle_error
		cmake --build . || handle_error
		cmake --install . || handle_error
		sed -i 's/set(ENABLE_MSan ON)/set(ENABLE_MSan OFF)/g' ../CMakeLists.txt
		sed -i "s/clang-msan)/${project_name})/g" ../CMakeLists.txt

		# GCC
		echo "====Compiling with GCC + PVS + clang-tidy====" | handle_output
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
}

sanitizers() {
    sanitizers_args=$1
	echo "====Running with Valgrind and Sanitizers====" | handle_output
	echo "Sanitizers args: $sanitizers_args" | handle_output
	project_name=$(grep -oP '(?<=set\(PROJECT ).*(?=\))' ./CMakeLists.txt)
	echo "====Valgrind====" | handle_output
	valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes ./bin/$project_name $sanitizers_args | handle_output || handle_error
	echo "====Valgrind Helgrind====" | handle_output
	valgrind --tool=helgrind ./bin/$project_name $sanitizers_args | handle_output || handle_error
	echo "====Valgrind DRD====" | handle_output
	valgrind --tool=drd ./bin/$project_name $sanitizers_args | handle_output || handle_error
	echo "====UBSan====" | handle_output
	./bin/clang-ubsan $sanitizers_args | handle_output || handle_error
	echo "====ASan====" | handle_output
	./bin/clang-asan $sanitizers_args | handle_output || handle_error
	echo "====TSan====" | handle_output
	./bin/clang-tsan $sanitizers_args | handle_output || handle_error
	echo "====MSan====" | handle_output
	./bin/clang-msan $sanitizers_args | handle_output || handle_error
}

debug() {
    echo "====Running with Debug Build====" | handle_output
	mkdir -p ./cmake-build-debug
	(
		pushd ./cmake-build-debug >/dev/null || exit 1
		echo Compiling...
		cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || exit 1
		cmake --build . || exit 1
		cmake --install . || exit 1
		popd
	)
}

optimize() {
    echo "====Running with Optimize Build====" | handle_output
	mkdir -p ./cmake-build-release
	(
		pushd ./cmake-build-release >/dev/null || exit 1
		echo Compiling...
		cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || exit 1
		cmake --build . || exit 1
		cmake --install . || exit 1
		popd
	)
}

clean() {
    echo "====Cleaning====" | handle_output
    rm -rf cmake-build-* compile.log
}

run() {
    echo "====Running custom command====" | handle_output
    run_args=$1
    echo "Running command: $run_args" | handle_output
    eval $run_args | handle_output
}

while [[ $# -gt 0 ]]; do
	case $1 in
	-I | --install_prefix)
		if [ "$2" -eq "$2" ] 2>/dev/null; then
			install_prefix=$2
			shift 2
		else
			echo "Option --install_prefix requires an numerical argument." | handle_output
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
    -I      --install_prefix        Installation path
    -p      --pipeline              Enable pipeline of different compilers and sanitizers
    -c      --clean                 Clean cmake-build-* directories and compile.log
    --s='<args>'                    Arguments for program when run under valgrind and sanitizers. If '--s' not present, valgrind and sanitizers will not be executed
    --r='<value>'                   Run the value as a bash command"
		exit 0
		;;
	\?)
		echo "Invalid option: -$OPTARG" | handle_output
		exit 1
		;;
	:)
		echo "Option -$OPTARG requires an numerical argument." | handle_output
		exit 1
		;;
	*)
		break
		;;
	esac
done
