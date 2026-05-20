use chumsky::prelude::*;

mod parser;

fn main() {
   loop {
      print!("> ");
      std::io::Write::flush(&mut std::io::stdout()).unwrap();

      let mut input = String::new();
      match std::io::stdin().read_line(&mut input) {
         Ok(0) => break, // EOF
         Ok(_) => {}
         Err(_) => break,
      }

      let input = input.trim();
      if input.is_empty() {
         continue;
      }

      let res = parser::tokenize().parse(input);
      match res.output() {
         Some(tokens) => {
            for t in tokens {
               println!("  {:?} at {:?}", t.inner, t.span);
            }
         }
         None => {
            for err in res.errors() {
               println!("  Error: {:?}", err);
            }
         }
      }
   }
}
