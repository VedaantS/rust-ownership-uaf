// The Rust version of c/vec_realloc.c. This file does NOT compile, on purpose.
fn main() {
    let mut nums = vec![1, 2];
    let first = &nums[0];   // shared borrow of nums
    nums.push(3);           // might reallocate, so it needs a mutable borrow
    println!("{}", first);  // error[E0502]: cannot borrow `nums` as mutable
}
