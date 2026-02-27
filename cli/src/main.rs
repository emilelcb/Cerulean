use std::env;

mod rocli;

fn main() {
    let args: Vec<String> = env::args().collect();
    println!("Hello, world!");
}
