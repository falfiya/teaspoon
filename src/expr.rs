use std::{fmt::Debug};

#[derive(Copy, Clone)]
pub struct MVarId(pub u32);
impl Debug for MVarId {
   fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
      write!(f, "?m.{}", self.0)
   }
}

#[derive(Copy, Clone)]
pub struct FVarId(pub u32);
impl Debug for FVarId {
   fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
      write!(f, "f.{}", self.0)
   }
}

#[derive(Copy, Clone)]
pub struct BVarId(pub u32);
impl Debug for BVarId {
   fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
      write!(f, "#{}", self.0)
   }
}

#[derive(Copy, Clone, Debug)]
pub enum BinderInfo {
   Default,
   Implicit,
}

#[derive(Copy, Clone, Debug)]
pub enum Name<'src> {
   Anon,
   Str(&'src str),
   Num{
      // pre: Box<Name<'src>>,
      i: u32,
   },
}

#[derive(Copy, Clone, Debug)]
pub struct Param<'src, 'f> {
   pub name: Name<'src>,
   pub ty: &'f Expr<'src, 'f>,
}

#[derive(Clone, Debug)]
pub enum Expr<'src, 'f> {
   Sort(u32),

   FVar(FVarId),
   /// Bound variables, De Bruijn Style
   ///
   /// ```ts
   /// a => a;
   /// ```
   /// Is elaborated to:
   /// ```rs
   /// Lam {
   ///   info: BinderInfo::Default,
   ///   param: [Param {name: Name::Str("a")}],
   ///   body: BVar(BVarId(0)),
   /// }
   /// ```
   BVar(BVarId),
   /// Metavariables
   /// `?m.1`
   MVar(MVarId),

   Typeof(&'f Expr<'src, 'f>),
   Pi {
      info: BinderInfo,
      /// This parameter records the names as they were written in the source
      /// code and the arity of the function.
      params: Vec<&'f Param<'src, 'f>>,
      body: &'f Expr<'src, 'f>,
   },
   Lam {
      info: BinderInfo,
      params: Vec<&'f Param<'src, 'f>>,
      body: Block<'src, 'f>,
   },
   // Cast {
   //    expr: Expr<'src>,
   //    ty: Expr<'src>,
   // },
   Eq {
      left: &'f Expr<'src, 'f>,
      right: &'f Expr<'src, 'f>,
   },
   // Binary {
   //    op: BinOp,
   //    left: Box<Expr<'src>>,
   //    right: Box<Expr<'src>>,
   // },
   // ArrayT(Box<Expr<'src>>),
}

type Block<'src, 'f> = Vec<&'f Statement<'src, 'f>>;
#[derive(Debug)]
pub enum Statement<'src, 'f> {
   Const {
      name: &'src str,
      val: &'f Expr<'src, 'f>,
   },
   Let {
      name: &'src str,
      val: Option<&'f Expr<'src, 'f>>,
   },
   If {
      cond: &'f Expr<'src, 'f>,
      then: &'f Expr<'src, 'f>,
      elze: &'f Expr<'src, 'f>,
   },
   Assign {
      lhs: &'f Expr<'src, 'f>,
      rhs: &'f Expr<'src, 'f>,
   },
   Return(&'f Expr<'src, 'f>),

   Expr(&'f Expr<'src, 'f>),
   Check(&'f Expr<'src, 'f>),
   Eval(&'f Expr<'src, 'f>),
}
