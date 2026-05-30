// pub struct FVarId(u64);
// pub struct BVarId(u64);
// pub struct MVarId(u64);
// pub struct Level(u8);

use im::{HashMap, HashSet};
use std::{ops::Coroutine};

use chumsky::{extra::State, span::{SpanWrap, Spanned}};

use crate::parser::{PPreStatement, PreStatement};

type Uni = u16;

pub struct MVarId(u32);
pub struct FVarId(u32);

// Gamma
pub struct Fresh {
   mvar_max: MVarId,
   fvar_max: FVarId,
}

impl Fresh {
   fn mvar(&mut self) -> MVarId {
      let v = self.mvar_max;
      self.mvar_max += 1;
      return v;
   }
   fn fvar(&mut fresh) -> FVarId {
      let v = self.fvar_max;
      self.fvar_max += 1;
      return v;
   }
}

#[derive(Debug, Clone)]
pub enum Expr<'src> {
   Sort(Uni),

   FConst(FVarId),
   BVar(BVarId),
   Const { name: &'src str, ty: PExpr<'src> },

   Pi {},
   Abs { params: VExpr<'src>, ty: PExpr<'src> },
   Let { name: &'src str, ty: PExpr<'src>, val: PExpr<'src>, body: PExpr<'src> },
   If {
      cond: PExpr<'src>,
      then: VStatement<'src>,
      elze: Option<VPreStatement<'src>>,
   },
   Cast {
      expr: PExpr<'src>,
      ty: PExpr<'src>,
   },
}

pub struct Constraint<'src> {
   
}

pub struct Context<'src> {
   named: HashMap<String, Expr<'src>>,
   /// Lean's †
   unnamed: HashMap<String, Expr<'src>>,
   constraints: HashSet<>
}

trait Elab<'src, R>: Clone {
   fn elab(self: &Self, ctx: Context<'src>) -> R;
}

type Block<'src> = Vec<Spanned<Statement<'src>>>;

pub enum Statement<'src> {
   Const {
      name: ConstId,
      ty: PExpr<'src>,
      val: PExpr<'src>,
   },
   Let {
      name: &'src str,
      val: PExpr<'src>,
      ty: PExpr<'src>,
   },
   If {
      cond: PExpr<'src>,
      then: Block<'src>,
      elze: Block<'src>,
   },
   Assign {
      name: &'src str,
      val: PExpr<'src>,
   },
   Expr(Expr<'src>),
   Check(Expr<'src>),
   Eval(Expr<'src>),
}

impl <'src> Elab<'src, Statement<'src>, > for PreStatement<'src> {
   fn elab(self: &Self, ctx: Context<'src>) -> Statement<'src> {
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
   fn elab(self: &Self, ctx: Context<'src>) -> Spanned<R> {
      self.inner.elab(ctx).with_span(self.span)
   }
}



// impl <'src> Elab<Expr<'src>> for 

// fn elab_statement<'src>(self: PPreStatement<'src>) -> Statement<'src> {
//    match self.inner {

//    }
// }


