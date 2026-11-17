// One way to fix vec_push.rs: copy the value out instead of holding a reference.
fn main() {
    let mut nums = vec![1, 2];
    let first = nums[0];    // i32 is Copy, so this is a copy, not a borrow
    nums.push(3);
    println!("{}", first);  // prints 1
}
