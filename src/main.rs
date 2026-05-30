#![feature(impl_trait_in_bindings)]
#![feature(coroutines, coroutine_trait, stmt_expr_attributes)]

use core::time;
use std::ops::{Coroutine, CoroutineState};
use std::pin::Pin;
use std::thread::sleep;

use chumsky::prelude::*;

mod parser;
mod elab;

fn main() {
   let mut coroutine = #[coroutine]
   || {
      yield 1;
      yield 2;
      yield 3;
      return "foo";
   };

   loop {
      sleep(time::Duration::from_secs(1));
      match Pin::new(&mut coroutine).resume(()) {
         CoroutineState::Yielded(x) => println!("Yielded {}", x),
         CoroutineState::Complete(x) => {
            println!("Completed with {}", x);
            break;
         }
      }

   }
   /*
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
               }
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
   */
}

