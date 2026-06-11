#![feature(allocator_api)]
// #![feature(impl_trait_in_bindings)]
// #![feature(coroutines, coroutine_trait, stmt_expr_attributes)]

use std::fs;


use bumpalo::Bump;
use chumsky::prelude::{Parser, Input};

mod parser;
mod elab;

use argh::FromArgs;
use pretty::Pretty;

#[derive(FromArgs)]
/// Teaspoon Compiler
#[argh(help_triggers("-h", "--help", "help", "/?", "/help"))]
struct TeaspoonArgs {
   /// input.tsp file
   #[argh(positional)]
   src: String,

   // /// whether or not to jump
   // #[argh(switch, short = 'j')]
   // jump: bool,
}

fn main() {
   let args: TeaspoonArgs = argh::from_env();

   let src_file = fs::read_to_string(&args.src).expect("File does not exist!");
   println!("Read {}:", &args.src);
   println!("{}", &src_file);

   let tokens;
   let res = parser::lex().parse(&src_file);
   {
      let errs = res.errors();
      if errs.len() > 0 {
         eprintln!("Tokenization Errors:");
      }
      for err in errs {
         eprintln!("{:?}", err);
      }
      tokens = res.output().expect("Tokenizing Failed!");
   }
   println!("Tokens:");
   println!("{:?}", tokens.iter().map(|t| t.inner).collect::<Vec<_>>());

   let pre_block;
   let res = parser::pre_block().parse(tokens.split_spanned((0..src_file.len()).into()));
   {
      let errs = res.errors();
      if errs.len() > 0 {
         eprintln!("Parse Errors:");
      }
      for err in errs {
         eprintln!("{:?}", err);
      }
      pre_block = res.output().expect("Parsing Failed!");
   }
   println!("Pre-parse:");
   println!("{:#?}", pre_block);

   let al = Bump::new();
   let fresh = elab::FreshCtx::new();
   let ctx = elab::Context::new(&al, &fresh);
   let res = elab::elab_block(&ctx, pre_block);
   println!("Elaboration:");
   println!("{:#?}", res.expr);
   if let elab::Expr::Block(v) = res.expr {
      print!("{}", v.len().to_string());
      if v.len() == 1 {
         print!(" statement");
      } else {
         print!(" statements");
      }
      println!(" elaborated.");
      if v.len() > 0 {
         println!("Final Scope:");
         println!("{}", v.last().unwrap().ctx);
      }
   }
}
