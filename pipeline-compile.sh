if [ $# -eq 0 ]; then
    echo "===Running normallly==="
    /bin/bash ../compile.sh 2>&1 >/dev/null | tee compile.log | grep --invert-match ".*\(Consider enabling PVS-Studio\|Sanitizers enabled\|[Ee]nabled in CMakeLists.txt\).*" | awk '!x[$0]++'

elif [ $# -eq 1 ]; then
    if [[ $1 == --v=* ]]; then
        echo "===Running with Pipeline and Valgrind==="
        ../compile.sh --v="${1:4}" 2>&1 >/dev/null | tee compile.log | grep --invert-match ".*\(Consider enabling PVS-Studio\|Sanitizers enabled\|[Ee]nabled in CMakeLists.txt\).*" | awk '!x[$0]++'
    elif [[ $1 == --r=* ]]; then
        echo "===Running custom command==="
        eval ${1:4}
    elif [ $1 = "-c" ]; then
        rm -rf cmake-build-* compile.log
    elif [ $1 = "-p" ]; then
        echo "===Running with Pipeline==="
        ../compile.sh -p 2>&1 >/dev/null | tee compile.log | grep --invert-match ".*\(Consider enabling PVS-Studio\|Sanitizers enabled\|[Ee]nabled in CMakeLists.txt\).*" | awk '!x[$0]++'
    elif [ $1 = "-O" ]; then
        echo "===Running with Optimization==="
        ../compile.sh -O 2>&1 >/dev/null | tee compile.log | grep --invert-match ".*\(Consider enabling PVS-Studio\|Sanitizers enabled\|[Ee]nabled in CMakeLists.txt\).*" | awk '!x[$0]++'
    elif [ $1 = "-h" ]; then
        echo "Usage: pipeline-compile.sh [OPTION]"
        echo "Run compile.sh with -p option"
        echo "If no argument - run compile.sh"
        echo "If --v='<value>' - run compile.sh with --v='<value>' argument - run Valgrind afterwards with <value> as arguments"
        echo "If -p argument - run compile.sh with -p argument - do pipeline of different compilers and sanitizers"
        echo "If -O argument - run compile.sh with -O argument - do compilation with optimization"
        echo "If --r='<value>' argument - run the value as a bash command instead of compilation"
        echo "If -c argument - clean cmake-build-* directories and compile.log"
        echo "If -h argument - print help"
    else
        echo "Invalid argument for pipeline"
    fi
else
    echo "Invalid argument for pipeline"
fi
