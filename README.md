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
**Rust**
Rust Book, Chapter 4 “Understanding Ownership”: https://doc.rust-lang.org/book/ch04-00-understanding-ownership.html (section 4.1, “What Is Ownership?”, is at ch04-01-what-is-ownership.html, and 4.2, “References and Borrowing”, is at ch04-02-references-and-borrowing.html)
E0382 (use of a moved value): https://doc.rust-lang.org/error_codes/E0382.html
E0502 (can’t borrow as mutable because it’s already borrowed as immutable): https://doc.rust-lang.org/error_codes/E0502.html

**The 70% figure**

Microsoft: the MSRC blog post “A proactive approach to more secure code” from July 2019 is at https://msrc.microsoft.com/blog/2019/07/a-proactive-approach-to-more-secure-code. It credits the number to Matt Miller’s 2019 presentation at BlueHat IL, and its chart is captioned “~70% of the vulnerabilities Microsoft assigns a CVE each year continue to be memory safety issues”. The follow-up post “We need a safer systems programming language” repeats the number and works through examples: https://msrc.microsoft.com/blog/2019/07/we-need-a-safer-systems-programming-language 
microsoft
microsoft
Chromium: the “Memory safety” page is at https://www.chromium.org/Home/chromium-security/memory-safety/. It says around 70% of their high severity security bugs are memory unsafety problems, and half of those are use-after-free bugs. That’s based on 912 high or critical severity security bugs since 2015, affecting the Stable channel. 


Used AI to help create this readme.
https://claude.ai/share/fac20b58-9a9a-49fc-8716-a8bbe3edafe3