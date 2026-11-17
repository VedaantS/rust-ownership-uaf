// The same three lines as c/drop_uaf.c. This file does NOT compile, on purpose.
fn main() {
    let s = String::from("hi");
    drop(s);
    println!("{}", s); // error[E0382]: borrow of moved value: `s`
}
