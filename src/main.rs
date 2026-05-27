#![feature(impl_trait_in_bindings)]

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

      let res = parser::lex().parse(input);
      match res.output() {
         Some(tokens) => {
            for t in tokens {
               println!("  {:?} at {:?}", t.inner, t.span);
            }
            let q = tokens.split_spanned((0..input.len()).into());
            let res2 = parser::pre_statements().parse(q);
            match res2.output() {
               Some(exprs) => {
                  println!("  {:#?}", exprs);
               },
               None => {
                  println!("  Parse Error")
               }
            }
         }
         None => {
            for err in res.errors() {
               println!("  Token Error: {:?}", err);
            }
         }
      }
   }
}
