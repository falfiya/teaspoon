// Locally nameless representation of lambda calculus.
use im::{HashMap, HashSet, Vector};
use std::{ops::Coroutine};

use chumsky::{extra::State, span::{SpanWrap, Spanned}};

use crate::parser::{PPreStatement, PreStatement};

#[derive(Clone, Debug)]
pub struct MVarId(u32);
#[derive(Clone, Debug)]
pub struct FVarId(u32);
#[derive(Clone, Debug)]
pub struct BVarId(u32);

//
pub struct Fresh {
   mvar_max: MVarId,
   fvar_max: FVarId,
}

pub trait Contextualized<'src, T> {
   fn named() -> HashMap<BVarId, Spanned<Expr<'src>>>;
   /// Lean's †
   fn unnamed() -> HashMap<Spanned<String>, Spanned<Expr<'src>>>;
   fn constraints() -> Vector<Spanned<Expr<'src>>>;
}

/// Constraints on the type
/// Consider the following program:
/// ```ts
/// const takesFive = (f: 5) => undefined;
/// takesFive(5);
/// takesFive(10);
/// ```
///
/// Two constraints are emitted: `5 : 5`, which is trivially true, and `10 : 5`,
/// which is false by noConfusion.
///
/// Continuing:
/// ```ts
/// const id = infer (a: Type) => a;
/// takesFive(id(5));
/// ```
/// Calling `id` emits a metavariable statically. Let's call that `?m0`.
/// From `id(5)`, we have that `5 : ?m0`. At that point, we *could* work out
/// that `?m0` is `number`, but then after `takesFive`, we have an additional
/// constraint: namely `?m0 : 5`.
///
/// The full constraints are
/// ```
/// 5 : 5
/// 10 : 5
/// 5 : ?m0
/// ?m0 : 5
/// ```
/// Because of the property of subtype, `?m0 = 5`, immediately.
/// There are no other satisfying assignments.
pub struct Constraint<'src> {
   sub: Expr<'src>,
   sup: Expr<'src>,
}

/// CTXpr! Contextualized Expression.
/// This is the bread and butter of the elaborator.
/// It's everything you want to know about expressions.
/// - What is the type of the expression?
/// - Since this is an expression, when is it valid? (Constraints)
/// - After this expression runs, what is the state of the program (Hoare)
/// - Facts that compiler knows that the user hasn't explicitly named (Unnamed)
///
/// This last one's a little more tricky:
/// ```ts
///    let y = 1;
///    const onlyPermissibleWhenY2 = (y @= 2) -> void;
///    if (y === 2) {
/// labelA:
///      onlyPermissibleWhenY2();
///    }
/// ```
/// What happens here? Is it OK to call `onlyPermissibleWhenY2`?
/// I'd argue yes, because at `labelA`, the if statement implicitly adds `y @= 2`
/// to the unnamed context.
pub struct CtExpr<'src> {
   /// None if the type can be found in the context.
   /// For instance, BVars are always found in the context and do not require
   /// Extra type info.
   /// Same with FVars.
   /// Also, Sort
   ty: Option<Expr<'src>>,
   constraints: Vector<Constraint<'src>>,
   gamma: HashMap<BVarId, Spanned<Expr<'src>>>,
   unnamed: Vector<Spanned<Expr<'src>>>,
   expr: Expr<'src>,
}

pub enum Prop<'src> {
   
}

pub enum Uni {
   Level(u16),
   Succ(Uni),
   Max(Uni, Uni),
}

#[derive(Debug, Clone)]
pub enum Expr<'src> {
   Sort(Uni),

   /// Maybe add something in the future to optimize constant FVars
   FVar(FVarId),
   BVar(BVarId),
   MVar(MVarId),

   Pi {
      
   },
   Abs {
      ty: PExpr<'src>,
      body: Contextualized<'src, Block>,
   },
   Cast {
      expr: PExpr<'src>,
      ty: PExpr<'src>,
   },
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


