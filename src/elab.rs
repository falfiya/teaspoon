// pub struct FVarId(u64);
// pub struct BVarId(u64);
// pub struct MVarId(u64);
// pub struct Level(u8);

type Uni = u16;

// Notably, statements do not have if or let
pub enum Statement<'src> {
   Expr(Expr<'src>),
   Check(PExpr<'src>),
   Eval(PExpr<'src>),
}

pub enum Expr<'src> {
   Sort(Uni),

   FVar(FVarId),
   BVar(BVarId),
   Const { name: &'src str },

   Pi {},
   Lam { params: VExpr<'src> },
   Let { name: &'src str, val: PExpr<'src>, body: PExpr<'src> },
   If {
      cond: PExpr<'src>,
      then: VStatement<'src>,
      elze: Option<VPreStatement<'src>>,
   },
}
