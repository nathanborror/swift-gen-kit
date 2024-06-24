main:
    @swift build
    @cp .build/debug/GenCmd gen
    @chmod +x gen
    @echo "Run the program with ./gen"
