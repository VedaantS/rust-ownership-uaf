CC     ?= gcc
CFLAGS ?= -g -Wall -Wextra
BUILD  := build

.PHONY: all c c-asan rust clean

all: c c-asan rust

$(BUILD):
	mkdir -p $(BUILD)

# Plain builds: these compile (with warnings) and run.
c: $(BUILD)
	$(CC) $(CFLAGS) -o $(BUILD)/drop_uaf c/drop_uaf.c
	$(CC) $(CFLAGS) -o $(BUILD)/vec_realloc c/vec_realloc.c

# AddressSanitizer builds: these report heap-use-after-free at runtime.
c-asan: $(BUILD)
	$(CC) $(CFLAGS) -fsanitize=address -o $(BUILD)/drop_uaf_asan c/drop_uaf.c
	$(CC) $(CFLAGS) -fsanitize=address -o $(BUILD)/vec_realloc_asan c/vec_realloc.c
	-./$(BUILD)/drop_uaf_asan
	-./$(BUILD)/vec_realloc_asan

# Rust: the first two are expected to fail to compile. The fixed one runs.
rust: $(BUILD)
	-rustc --edition 2021 -o $(BUILD)/drop_uaf_rs rust/drop_uaf.rs
	-rustc --edition 2021 -o $(BUILD)/vec_push_rs rust/vec_push.rs
	rustc --edition 2021 -o $(BUILD)/vec_push_fixed rust/vec_push_fixed.rs
	./$(BUILD)/vec_push_fixed

clean:
	rm -rf $(BUILD)
