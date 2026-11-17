# Solving use-after-free errors in Rust

COMP 211 Checkoff 3: how Rust's ownership system and borrow checker prevent use-after-free bugs at compile time, compared with manual memory management in C.

## The idea

C trusts the programmer. After `free(p)`, the pointer `p` still looks valid, so code that uses it compiles and fails at runtime as a crash, corrupted data, or an exploit.

Rust checks the programmer. Every value has exactly one owner. When the owner goes away, the memory is freed, and the compiler refuses any code that would still use it. No garbage collector, no runtime cost.

| | C | Rust |
|---|---|---|
| Who frees? | The programmer, with `free()` | The owner, at end of scope |
| After free | Pointer still usable | Name no longer usable |
| Caught when? | Runtime, if at all | Compile time |
| Runtime cost | None | None, no garbage collector |

## Examples

### 1. Free, then use

The same three lines in both languages.

| C: [`c/drop_uaf.c`](c/drop_uaf.c) | Rust: [`rust/drop_uaf.rs`](rust/drop_uaf.rs) |
|---|---|
| `char *s = strdup("hi");` | `let s = String::from("hi");` |
| `free(s);` | `drop(s);` |
| `printf("%s\n", s);` | `println!("{}", s);` |
| Compiles and runs. Use after free. | `error[E0382]: borrow of moved value: s` |

### 2. The growing array

The sneakier case: nothing on the broken line calls `free`. When the array runs out of room, it moves to a bigger buffer and frees the old one, and any pointer into the old buffer is left dangling.

- C: [`c/vec_realloc.c`](c/vec_realloc.c) — `realloc` may move the array; `first` still points at the old, freed buffer.
- Rust: [`rust/vec_push.rs`](rust/vec_push.rs) — `error[E0502]: cannot borrow nums as mutable because it is also borrowed as immutable`. While `first` borrows `nums`, nothing is allowed to change it.
- Fix: [`rust/vec_push_fixed.rs`](rust/vec_push_fixed.rs) — copy the value out instead of holding a reference.

## Running the examples

Requires `gcc` or `clang` and `rustc` (install with [rustup](https://rustup.rs)).

```sh
make c        # plain C builds: compile (with warnings) and run
make c-asan   # C with AddressSanitizer: reports heap-use-after-free
make rust     # Rust: the two broken examples fail to compile; the fixed one runs
make clean
```

Or by hand:

```sh
gcc -g -fsanitize=address c/vec_realloc.c -o vec_realloc && ./vec_realloc
rustc rust/vec_push.rs
```

Expected AddressSanitizer output (abridged):

```
ERROR: AddressSanitizer: heap-use-after-free on address 0x502000000010
READ of size 4 at 0x502000000010 thread T0
    #0 in main c/vec_realloc.c:13
```

### A note on C compiler warnings

Recent GCC (12+) catches both C examples with `-Wuse-after-free`. That's a warning, not an error, and it's a heuristic: it works on short, obvious code like this but can't follow pointers across functions, data structures, or threads the way Rust's ownership rules do. The programs still compile and run.

## Slides

See [`slides/`](slides/).

## Resources

<!-- Add the sources you actually used. -->
