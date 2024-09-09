# search for leaks in binary
valgrind-check() {
    valgrind --leak-check=full \
            --show-leak-kinds=all \
            --track-origins=yes \
            --verbose \
            --log-file=valgrind-out.log \
            "$@"
}