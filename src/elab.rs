use crate::shared::*;

use bumpalo::Bump;
use im::{HashMap, Vector, vector};
use std::collections::HashSet;

use std::fmt::{Debug, Pointer};
// use std::ops::{Coroutine, Index};

use std::sync::atomic::{AtomicU32};

use chumsky::{extra::State, span::SpanWrap};

use crate::expr::{self, Expr};

use crate::parser::{self, PreExpr, PreStatement};

/// Context for getting fresh variables.
pub struct FreshCtx {
   fvar: AtomicU32,
   mvar: AtomicU32,
}
impl FreshCtx {
   pub fn new() -> FreshCtx {
      FreshCtx {
         fvar: AtomicU32::new(0),
         mvar: AtomicU32::new(0),
      }
   }

   fn fvar<'src>(&self) -> expr::FVarId {
      let id = self.fvar.fetch_add(1, std::sync::atomic::Ordering::SeqCst);
      if id == 0 {
         panic!("FVarId overflowed!")
      }
      expr::FVarId(id)
   }

   fn mvar<'src>(&self) -> expr::MVarId {
      let id = self.mvar.fetch_add(1, std::sync::atomic::Ordering::SeqCst);
      if id == 0 {
         panic!("MVarId overflowed!")
      }
      expr::MVarId(id)
   }
}

#[derive(Clone)]
pub enum Ident {
   FVar(expr::FVarId),
   /// Don't get it twisted, this is not the actual BVarId.
   /// The outermost BVar has value 0, whereas the innermost BVar has value n.
   BVarReverse(u32),
}
#[derive(Clone)]
pub struct IdentContext<'src, 'f> {
   fresh: &'f FreshCtx,
   // The number of lambdas we've entered
   depth: u32,
   lookup: HashMap<&'src str, Ident>,
}
impl <'src, 'f> IdentContext<'src, 'f> {
   fn bind_var(&self, name: &'src str) -> Self {
      IdentContext {
         fresh: self.fresh,
         depth: self.depth + 1,
         lookup: self.lookup.update(name, Ident::BVarReverse(self.depth)),
      }
   }

   fn push_bvar(&self) -> Self {
      IdentContext {
         fresh: self.fresh,
         depth: self.depth + 1,
         lookup: self.lookup.clone(),
      }
   }

   fn open_fvar(&self, name: &'src str) -> Self {
      IdentContext {
         fresh: self.fresh,
         depth: self.depth,
         lookup: self.lookup.update(name, Ident::FVar(self.fresh.fvar()))
      }
   }

   fn fresh_mvar<'src2, 'f2>(&self) -> Expr<'src2, 'f2> {
      Expr::MVar(self.fresh.mvar())
   }

   fn get<'src2, 'f2>(&self, name: &'src str) -> Option<Expr<'src2, 'f2>> {
      self.lookup.get(name).map(|x|
         match x.clone() {
            Ident::FVar(id) => Expr::FVar(id),
            Ident::BVarReverse(rev_id) => Expr::BVar(
               expr::BVarId(self.depth - rev_id)
            ),
         }
      )
   }

   fn bvar0<'f2>(&self) -> Expr<'src, 'f> {
      if self.depth == 0 {
         panic!("#0 is not bound!")
      }
      Expr::BVar(expr::BVarId(0))
   }
}

// Proof/type context Gamma
#[derive(Clone)]
pub enum TypeContext<'src, 'f> {
   Flat(Vector<&'f Expr<'src, 'f>>),
   /// {x : string} ⊔ {x : number} => {x : string | number}
   Join(&'f TypeContext<'src, 'f>, &'f TypeContext<'src, 'f>),
   /// {x : 1 | 2} ⊓ {x : 1 | "foo"} => {x : 1}
   Meet(&'f TypeContext<'src, 'f>, &'f TypeContext<'src, 'f>),
}
impl <'src, 'f> TypeContext<'src, 'f> {
   fn push_fact(&self, e: &'f Expr<'src, 'f>) -> TypeContext<'src, 'f> {
      use TypeContext::*;
      match self {
         Flat(v) => {
            let mut v = v.clone();
            v.push_back(e);
            Flat(v)
         },
         _ => todo!(),
      }
   }
   fn query(e: Expr<'src, 'f>) {
      match e {
         Expr::BVar(bvar_id) => todo!(),
         Expr::FVar(fvar_id) => todo!(),
         Expr::MVar(_) =>
            unimplemented!("Querying the type context for metavariables may be supported"),
         _ => unimplemented!("Only query the type context for idents currently!")
      }
   }
}

/// Should contain only Prop
struct Constraints<'src, 'f>(Vector<&'f Expr<'src, 'f>>);
impl <'src, 'f> Constraints<'src, 'f> {
   fn append(&mut self, c: Constraints<'src, 'f>) {
      self.0.append(c.0);
   }
}

struct ElaboratedExpr<'src, 'f> {
   expr: &'f Expr<'src, 'f>,
   ty: &'f Expr<'src, 'f>,
   c: Constraints<'src, 'f>,
}

pub fn elab_expr<'src, 'f>(
   pe: &PreExpr<'src>,
   al: &'f Bump,
   it_ctx: IdentContext<'src, 'f>,
   ty_ctx: TypeContext<'src, 'f>
) -> ElaboratedExpr<'src, 'f>
{
   use parser::PreExpr::*;
   let mut constraints = Constraints(Vector::new());
   match pe {
      Lam { implicit, params, body } => {
         if *implicit {
            todo!();
         }
         let mut param_names = HashSet::new();
         let mut eparams = Vec::with_capacity(params.len());
         let mut it_ctx = it_ctx;
         let mut ty_ctx = ty_ctx;
         for param in params {
            use parser::PreParam::*;
            match param {
               Name(name) => {
                  if param_names.contains(name) {
                     panic!("Cannot bind {} a second time!", name)
                  } else {
                     param_names.insert(name);
                  }
                  let ty = it_ctx.fresh_mvar().b(al);
                  eparams.push(
                     expr::Param {
                        name: expr::Name::Str(name),
                        ty,
                     }.b(al)
                  );
                  it_ctx = it_ctx.bind_var(name);
                  ty_ctx = ty_ctx.push_fact(
                     Expr::Eq {
                        left: Expr::Typeof(it_ctx.bvar0().b(al)).b(al),
                        right: ty.b(al),
                     }.b(al)
                  );
               }
               Type(ty) => {
                  // Elaborate the type
                  let ety = elab_expr(pe, al, it_ctx.clone(), ty_ctx.clone());
                  // Your constraints are my constraints now.
                  constraints.append(ety.c);
                  // Throw away the type of the type. I don't care.
                  let ety = ety.ty;
                  eparams.push(
                     expr::Param {
                        name: expr::Name::Anon,
                        ty: ety,
                     }.b(al)
                  );
                  it_ctx = it_ctx.push_bvar();
               }
               Full { name, ty } => {
                  let ety = elab_expr(pe, al, it_ctx.clone(), ty_ctx.clone());
                  constraints.append(ety.c);
                  let ety = ety.ty;
                  eparams.push(
                     expr::Param {
                        name: expr::Name::Str(name),
                        ty: ety,
                     }.b(al)
                  );
                  it_ctx = it_ctx.bind_var(name);
                  ty_ctx = ty_ctx.push_fact(
                     Expr::Eq {
                        left: Expr::Typeof(it_ctx.bvar0().b(al)).b(al),
                        right: ety.b(al),
                     }.b(al)
                  )
               }
            }
         }

         let return_ty;
         let ebody;
         {
            use parser::PreLamBody::*;
            match body {
               Return(e) => {
                  // This is the easy case.
                  let ee = elab_expr(&e.inner, al, it_ctx.clone(), ty_ctx.clone());
                  // your constraints are my constraints
                  constraints.0.append(ee.c.0);
                  return_ty = ee.ty;
                  ebody = vec![expr::Statement::Return(ee.expr).b(al)];
               },
               Block(b) => todo!(),
            }
         }

         let elam = Expr::Lam {
            info: expr::BinderInfo::Default,
            params: eparams.clone(),
            body: ebody,
         }.b(al);

         return ElaboratedExpr {
            expr: elam,
            ty: Expr::Pi {
               info: expr::BinderInfo::Default,
               params: eparams,
               body: return_ty.b(al),
            }.b(al),
            c: constraints,
         }
      }

      pe => panic!("Cannot elaborate {:#?}!", pe),
   }
}

// pub fn elab_statement<'src, 'f>(
   
// )
