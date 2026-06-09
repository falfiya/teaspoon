// Locally nameless representation of lambda calculus.
use im::{HashMap, HashSet, Vector, vector};
use std::ops::{Coroutine, Index};

use std::sync::atomic::AtomicU32;

use chumsky::{extra::State, span::SpanWrap};

use crate::parser::{self, BinOp, PreExpr, PreStatement};

#[derive(Clone, Debug)]
pub struct MVarId(u32);
#[derive(Clone, Debug)]
pub struct FVarId(u32);
#[derive(Clone, Debug)]
pub struct BVarId(u32);

pub enum BinderInfo {
   Default,
   Implicit,
}

pub enum Name<'src> {
   Anon,
   Str(&'src str),
   Num{
      // pre: Box<Name<'src>>,
      i: u32,
   },
}

pub struct Param<'src> {
   name: Name<'src>,
   ty: Expr<'src>,
}


pub struct FVarCtx(AtomicU32);
impl FVarCtx {
   fn new() -> FVarCtx {
      FVarCtx(AtomicU32::new(1))
   }

   fn fresh(self) -> FVarId {
      let id = self.0.fetch_add(1, std::sync::atomic::Ordering::SeqCst);
      if id == 0 {
         panic!("FVarId overflowed!")
      }
      FVarId(id)
   }
}

pub enum Ident {
   FVar(FVarId),
   /// Don't get it twisted, this is not the actual BVarId.
   /// The outermost BVar has value 0, whereas the innermost BVar has value n.
   BVarReverse(u32),
}
pub struct IdentContext<'src, 'f> {
   fctx: &'f FVarCtx,
   // The number of lambdas we've entered
   depth: u32,
   lookup: HashMap<&'src str, Ident>,
}


impl <'src, 'f> IdentContext<'src, 'f> {
   fn push_bvar(self, name: &'src str) -> IdentContext {
      IdentContext {
         fctx: self.fctx,
         depth: self.depth + 1,
         lookup: self.lookup.insert(name, Ident::BVarReverse(self.depth)),
      }
   }

   fn get(self, name: &'src str) -> Option<Expr<'src>> {
      self.lookup.get(name).map(|x|
         match *x {
            Ident::FVar(id) => Expr::FVar(id),
            Ident::BVarReverse(rev_id) => Expr::BVar(BVarId(self.depth - rev_id)),
         }
      )
   }
}

#[test]
fn test_elab_identity() {
   let identity;
   {
      use parser::*;
      use PreExpr::*;
      identity = Lam {
         implicit: false,
         params: vec![parser::PreParam::Name("a")],
         body: PreLamBody::Return(Ident("a").with_span(0..1)),
      };
   }

   let identity_elab;
   {
      use Expr::*;
      identity_elab = Lam {
         info: BinderInfo::Implicit,
         params: vec![Param {name: Name::Anon, ty: Sort(0)}],
         body: vec![
            Statement::Return(
               Lam {
                  info: BinderInfo::Default,
                  params: vec![Param {name: Name::Str("a"), ty: BVar(BVarId(0))}],
                  body: vec![
                     Statement::Return(
                        BVar(BVarId(0))
                     )
                  ],
               }
            )
         ],
      };
      identity_constraints = vec![];
   }

   identity.elab()
}

trait Elab<'src, 'f, R>: Clone {
   fn elab(self: &Self, id_ctx: IdentContext<'src, 'f>, ty_ctx: TypeContext<'src>) -> (R, TypeContext<'src>, Constraints<'src>);
}

// Proof/type context Gamma
pub enum TypeContext<'src> {
   Con(Vector<Expr<'src>>),
   /// {x : string} ⊔ {x : number} => {x : string | number}
   Join(Box<TypeContext<'src>>, Box<TypeContext<'src>>),
   /// {x : 1 | 2} ⊓ {x : 1 | "foo"} => {x : 1}
   Meet(Box<TypeContext<'src>>, Box<TypeContext<'src>>),
}

/// Should contain only Prop
type Constraints<'src> = Vector<Expr<'src>>;

#[derive(Debug, Clone)]
pub enum Expr<'src> {
   Sort(u32),

   // Const(ConstId),
   /// Maybe add something in the future to optimize constant FVars
   FVar(FVarId),
   /// Bound variables, De Bruijn Style
   ///
   /// ```ts
   /// a => a;
   /// ```
   /// ```rs
   /// Lam {
   ///   ty: Pi {
   ///      infer: true,
   ///      params: vec![param::Implicit(Expr::Sort(1))],  // <----------------<
   ///      returns: Pi {                                  //                  |
   ///         infer: false,                               //                  |
   ///         params: vec![param::Explicit("a", BVar(0))] // -----------------^
   ///         returns: BVar(0)
   ///      }
   /// }}
   /// ```
   BVar(BVarId),
   MVar(MVarId),

   Typeof(Box<Expr<'src>>),
   Pi {
      info: BinderInfo,
      /// This parameter records the names as they were written in the source
      /// code and the arity of the function.
      params: Vec<Param<'src>>,
      body: Expr<'src>,
   },
   Lam {
      info: BinderInfo,
      params: Vec<Param<'src>>,
      body: Block<'src>,
   },
   Cast {
      expr: Expr<'src>,
      ty: Expr<'src>,
   },
   Binary {
      op: BinOp,
      left: Box<Expr<'src>>,
      right: Box<Expr<'src>>,
   },
   ArrayT(Box<Expr<'src>>),
}

pub type Expr2<'src> = (Expr<'src>, TypeContext<'src>, Constraints<'src>);
impl <'src, 'f> Elab<'src, 'f, Expr<'src>> for PreExpr<'src> {
   fn elab(self: &Self, id_ctx: IdentContext<'src, 'f>, ty_ctx: TypeContext<'src>) -> Expr2<'src> {
       
   }
}

type Block<'src> = Vec<Statement<'src>>;

pub enum Statement<'src> {
   Const {
      name: &'src str,
      val: Box<Expr<'src>>,
   },
   Let {
      name: &'src str,
      val: Option<Box<Expr<'src>>>,
   },
   If {
      cond: Box<Expr<'src>>,
      then: Box<Expr<'src>>,
      elze: Box<Expr<'src>>,
   },
   AssignFVar {
      name: FVarId,
      val: Box<Expr<'src>>,
   },
   AssignBVar {
      name: BVarId,
      val: Box<Expr<'src>>,
   },
   Return(Expr<'src>),

   Expr(Expr<'src>),
   Check(Expr<'src>),
   Eval(Expr<'src>),
}

impl <'src> Elab<'src, Statement<'src>, > for PreStatement<'src> {
   fn elab(self: &Self, ctx: TypeContext<'src>) -> Statement<'src> {
      match self {
         PreStatement::Error => unimplemented!(),
         PreStatement::Check(e) => Statement::Check(elab_expr(e)),
         PreStatement::Definition { name, ty, val } => {
            // Does not support recursive definition
            let ty_e = ty.elab(ctx);
            let expr_e = val.elab(ctx);
            Statement::Expr(Expr::Let { name, val: ety, body: eexpr })
         }
         PreStatement::If { cond, then, elze } => {
            let cond_e = cond.elab();
            // Add some fresh metavariables that say cond @== true
            let then_e = then.elab();
            let elze_e = elze.elab();
            
         }
      }
   }
}

impl <'src, T: Elab<'src, R>, R> Elab<'src, Spanned<R>> for Spanned<T> {
   fn elab(self: &Self, ctx: TypeContext<'src>) -> Spanned<R> {
      self.inner.elab(ctx).with_span(self.span)
   }
}

// Convert constraints back to function
// 

// impl <'src> Elab<Expr<'src>> for 

// fn elab_statement<'src>(self: PPreStatement<'src>) -> Statement<'src> {
//    match self.inner {

//    }
// }


