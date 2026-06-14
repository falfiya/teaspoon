use bumpalo::Bump;
use pretty::{DocAllocator, DocBuilder, Pretty};
use std::{collections::HashSet, fmt::Display};

use crate::parser::{self, PreBlock, PreExpr, PreStatement};

impl <'src, 'f> Expr2<'src, 'f> {
   fn ty(&self) -> (&'f Expr2<'src, 'f>, Constraints<'src, 'f>) {
      match self.expr {
         Expr::BVar(id) => (self.ctx.query_bvar_type(*id), Constraints::new()),
         Expr::Lam { info, params, body } => {
            let (body_ty, c) = body.ty();
            // THIS IS WRONG
            // When you ask for the type of something, you need to include YOUR context.
            // The type of something may not be assignable to your context super easily.
            let pi = self.ctx.e2(Expr::Pi { info: *info, params: params.clone(), ret: body_ty});
            return (pi, c);
         }
         anything_else => todo!("Cannot get type of {:#?}", anything_else)
      }
   }
}

pub fn elab_block<'src, 'f>(
   ctx: &Context<'src, 'f>,
   pb: &PreBlock<'src>,
) -> &'f Expr2<'src, 'f>
{
   let ctx = ctx.clone();

   let mut acc_ctx = ctx.clone();
   let mut const_names = HashSet::new();
   let mut constraints = Constraints::new();
   let mut block2: Vec<&'f Statement2<'src, 'f>> = Vec::with_capacity(pb.len());
   // Elaborate statements in order, building up the context.
   for ps in pb {
      let (stmt2, c) = elab_statement(&acc_ctx, ps);
      constraints.append(c);
      acc_ctx = stmt2.ctx.clone();
      block2.push(stmt2);

      match stmt2.stmt {
         Statement::Return(r) => {
            return ctx.e2(Expr::Block(block2));
         }
         Statement::Const { name, val: _ } => {
            if const_names.contains(name) {
               panic!("Cannot reassign {}", name);
            } else {
               const_names.insert(name);
            }
         }
         _ => ()
      }
   }

   return ctx.e2(Expr::Block(block2));
}

pub fn elab_statement<'src, 'f>(
   ctx: &Context<'src, 'f>,
   ps: &PreStatement<'src>,
) -> (&'f Statement2<'src, 'f>, Constraints<'src, 'f>)
{
   use parser::PreStatement::*;
   let mut constraints = Constraints::new();
   match ps {
      Const { name, ty, val } => {
         let (val2, c) = elab_expr(&ctx, val);
         constraints.append(c);
         let (val2_ty, c) = val2.ty();
         constraints.append(c);

         // Elaborate or synthesize the type.
         // Prepare the output context.
         let ctx_next = ctx.new_fvar(name, val2_ty);
         match ty {
            Some(ty) => {
               let (ty2, c) = elab_expr(&ctx, ty);
               constraints.append(c);
               // Enforce that the value extends the explicit type
               constraints.add(ctx.e2(Expr::Extends { sub: val2_ty, sup: ty2 }));
            }
            _ => ()
         }

         let const2 = ctx_next.s2(Statement::Const { name, val: val2 });
         return (const2, constraints);
      },
      s => todo!("{:?}", s),
   }
}

pub fn elab_expr<'src, 'f>(
   ctx: &Context<'src, 'f>,
   pe: &PreExpr<'src>,
) -> (&'f Expr2<'src, 'f>, Constraints<'src, 'f>) {
   use parser::PreExpr::*;
   let mut constraints = Constraints::new();
   match pe {
      Ident(name) => {
         (ctx.ident(name), constraints)
      }
      Lam {
         implicit,
         params,
         body,
      } => {
         if *implicit {
            todo!();
         }

         let mut body_ctx = ctx.clone();
         let mut prevent_dupe_param_names = HashSet::new();
         let mut params2: Vec<&'f Param<'src, 'f>> = Vec::with_capacity(params.len());
         for param in params {
            use parser::PreParam;
            match param {
               PreParam::Name(name) => {
                  if prevent_dupe_param_names.contains(name) {
                     panic!("Cannot bind {} a second time!", name)
                  } else {
                     prevent_dupe_param_names.insert(name);
                  }

                  // Create metavariable ?T
                  let ty2 = body_ctx.e2(body_ctx.id.fresh_mvar());
                  params2.push(
                     body_ctx.owns(Param { name: Name::Str(name), ty: ty2 })
                  );
                  // Bind name -> #0
                  body_ctx.id = body_ctx.id.bind_var(name);
                  // #0 has type ?T
                  body_ctx.ty = body_ctx.ty.push_fact(body_ctx.e2(Expr::Eq {
                     left: body_ctx.e2(Expr::Typeof(body_ctx.bvar0())),
                     right: ty2,
                  }));
               }
               PreParam::Type(ty) => todo!(),
               PreParam::Full { name, ty } => todo!(),
            }
         }

         let body2;
         {
            use parser::PreLamBody::*;
            match body {
               Return(e) => {
                  // This is the easy case.
                  // We make sure to use the body ctx
                  let (e_body, c) = elab_expr(&body_ctx, &e.inner);
                  // your constraints are my constraints
                  constraints.append(c);
                  body2 = e_body;
               }
               Block(b) => todo!(),
            }
         }

         let lam2 = ctx.e2(Expr::Lam {
            info: BinderInfo::Default,
            params: params2,
            body: body2,
         });

         return (lam2, constraints);
      }
      pe => panic!("Cannot elaborate {:#?}!", pe),
   }
}

use std::fmt::Debug;
use std::sync::atomic::AtomicU32;

use im::{HashMap, Vector};
use pub_fields::pub_fields;

#[pub_fields]
#[derive(Clone)]
pub struct Statement2<'src, 'f> {
   pub stmt: &'f Statement<'src, 'f>,
   /// Context after the Statement
   pub ctx: Context<'src, 'f>,
}

#[derive(Clone)]
pub struct Expr2<'src, 'f> {
   pub expr: &'f Expr<'src, 'f>,
   /// Context after the Expr
   pub ctx: Context<'src, 'f>,
}

impl <'src, 'f> Debug for Statement2<'src, 'f> {
   fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
      self.stmt.fmt(f)
   }
}

impl <'src, 'f> Debug for Expr2<'src, 'f> {
   fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
      self.expr.fmt(f)
   }
}

#[derive(Debug)]
pub enum Statement<'src, 'f> {
   Const {
      name: &'src str,
      val: &'f Expr2<'src, 'f>,
   },
   Let {
      name: &'src str,
      val: Option<&'f Expr2<'src, 'f>>,
   },
   If {
      cond: &'f Expr2<'src, 'f>,
      then: &'f Expr2<'src, 'f>,
      elze: &'f Expr2<'src, 'f>,
   },
   Assign {
      lhs: &'f Expr2<'src, 'f>,
      rhs: &'f Expr2<'src, 'f>,
   },
   Return(&'f Expr2<'src, 'f>),

   // BareExpr(Expr2<'src, 'f>),
   // Check(Expr2<'src, 'f>),
   // Eval(Expr2<'src, 'f>),
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

   Typeof(&'f Expr2<'src, 'f>),
   Pi {
      info: BinderInfo,
      /// This parameter records the names as they were written in the source
      /// code and the arity of the function.
      params: Vec<&'f Param<'src, 'f>>,
      ret: &'f Expr2<'src, 'f>,
   },
   Lam {
      info: BinderInfo,
      params: Vec<&'f Param<'src, 'f>>,
      body: &'f Expr2<'src, 'f>,
   },
   // Cast {
   //    expr: Expr<'src>,
   //    ty: Expr<'src>,
   // },
   Eq {
      left: &'f Expr2<'src, 'f>,
      right: &'f Expr2<'src, 'f>,
   },

   Extends {
      sub: &'f Expr2<'src, 'f>,
      sup: &'f Expr2<'src, 'f>,
   },

   Liquid {
      params: Vec<&'f Param<'src, 'f>>,
      pred: &'f Expr2<'src, 'f>,
   },

   Block(Vec<&'f Statement2<'src, 'f>>),
   // Binary {
   //    op: BinOp,
   //    left: Box<Expr<'src>>,
   //    right: Box<Expr<'src>>,
   // },
   // ArrayT(Box<Expr<'src>>),
}

impl Expr<'_, '_> {
   
}

#[derive(Copy, Clone)]
pub struct MVarId(pub u32);
impl Debug for MVarId {
   fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
      write!(f, "?m.{}", self.0)
   }
}

#[derive(Copy, Clone, PartialEq, Eq)]
pub struct FVarId(pub u32);
impl Debug for FVarId {
   fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
      write!(f, "f.{}", self.0)
   }
}

#[derive(Copy, Clone, PartialEq, Eq)]
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

#[derive(Clone, Debug)]
pub struct Param<'src, 'f> {
   pub name: Name<'src>,
   pub ty: &'f Expr2<'src, 'f>,
}

#[pub_fields]
#[derive(Clone)]
pub struct Context<'src, 'f> {
   al: &'f Bump,
   id: IdentContext<'src, 'f>,
   ty: TypeContext<'src, 'f>,
}
impl <'src, 'f> Context<'src, 'f> {
   pub fn new(al: &'f Bump, fresh: &'f FreshCtx) -> Self {
      Context {
         al,
         id: IdentContext::new(fresh),
         ty: TypeContext::new(),
      }
   }
   pub fn s2(&self, stmt: Statement<'src, 'f>) -> &'f Statement2<'src, 'f> {
      self.al.alloc(Statement2 { stmt: self.al.alloc(stmt), ctx: self.clone() })
   }
   pub fn e2(&self, expr: Expr<'src, 'f>) -> &'f Expr2<'src, 'f> {
      self.al.alloc(Expr2 { expr: self.al.alloc(expr), ctx: self.clone() })
   }
   pub fn owns<T>(&self, x: T) -> &'f T {
      self.al.alloc(x)
   }

   fn bvar0(&self) -> &'f Expr2<'src, 'f> {
      self.e2(self.id.bvar0())
   }

   pub fn new_fvar(&self, name: &'src str, ty: &'f Expr2<'src, 'f>) -> Self {
      let tmp = Context {
         al: self.al,
         id: self.id.open_fvar(name),
         ty: self.ty.clone(),
      };
      
      let fvar_fact = self.e2(Expr::Eq {
         left: self.e2(Expr::Typeof(tmp.ident(name))),
         right: ty,
      });

      Context {
         al: self.al,
         id: tmp.id,
         ty: tmp.ty.push_fact(fvar_fact),
      }
   }

   pub fn new_bvar(&self, name: &'src str, ty: &'f Expr2<'src, 'f>) -> Self {
      let tmp = Context {
         al: self.al,
         id: self.id.bind_var(name),
         ty: self.ty.clone(),
      };
   
      let bvar_fact = self.e2(Expr::Eq {
         left: self.e2(Expr::Typeof(self.ident(name))),
         right: ty,
      });

      Context {
         al: self.al,
         id: tmp.id,
         ty: tmp.ty.push_fact(bvar_fact),
      }
   }

   pub fn ident(&self, name: &'src str) -> &'f Expr2<'src, 'f> {
      match self.id.get(name).unwrap() {
         BoundIdent::BVar(id) => self.e2(Expr::BVar(id)),
         BoundIdent::FVar(id) => self.e2(Expr::FVar(id)),
      }
   }

   pub fn query_bvar_type(&self, id: BVarId) -> &'f Expr2<'src, 'f> {
      self.ty.query_bvar_type(id)
   }

   pub fn query_fvar_type(&self, id: FVarId) -> &'f Expr2<'src, 'f> {
      self.ty.query_fvar_type(id)
   }
}

/// Context for getting fresh variables.
pub struct FreshCtx {
   fvar: AtomicU32,
   mvar: AtomicU32,
}
impl FreshCtx {
   pub fn new() -> FreshCtx {
      FreshCtx {
         fvar: AtomicU32::new(1),
         mvar: AtomicU32::new(1),
      }
   }

   fn fvar<'src>(&self) -> FVarId {
      let id = self.fvar.fetch_add(1, std::sync::atomic::Ordering::SeqCst);
      if id == 0 {
         panic!("FVarId overflowed!")
      }
      FVarId(id)
   }

   fn mvar<'src>(&self) -> MVarId {
      let id = self.mvar.fetch_add(1, std::sync::atomic::Ordering::SeqCst);
      if id == 0 {
         panic!("MVarId overflowed!")
      }
      MVarId(id)
   }
}

#[derive(Clone)]
pub enum InternalIdentDoNotUse {
   FVar(FVarId),
   /// Don't get it twisted, this is not the actual BVarId.
   /// The outermost BVar has value 0, whereas the innermost BVar has value n.
   BVarReverse(u32),
}
pub enum BoundIdent {
   FVar(FVarId),
   BVar(BVarId),
}
#[derive(Clone)]
pub struct IdentContext<'src, 'f> {
   fresh: &'f FreshCtx,
   // The number of lambdas we've entered
   depth: u32,
   lookup: HashMap<&'src str, InternalIdentDoNotUse>,
}
impl <'src, 'f> IdentContext<'src, 'f> {
   fn new(fresh: &'f FreshCtx) -> Self {
      IdentContext { fresh, depth: 0, lookup: HashMap::new() }
   }

   pub fn bind_var(&self, name: &'src str) -> Self {
      IdentContext {
         fresh: self.fresh,
         depth: self.depth + 1,
         lookup: self.lookup.update(name, InternalIdentDoNotUse::BVarReverse(self.depth)),
      }
   }

   pub fn push_bvar(&self) -> Self {
      IdentContext {
         fresh: self.fresh,
         depth: self.depth + 1,
         lookup: self.lookup.clone(),
      }
   }

   pub fn open_fvar(&self, name: &'src str) -> Self {
      IdentContext {
         fresh: self.fresh,
         depth: self.depth,
         lookup: self.lookup.update(name, InternalIdentDoNotUse::FVar(self.fresh.fvar()))
      }
   }

   pub fn fresh_mvar<'src2, 'f2>(&self) -> Expr<'src2, 'f2> {
      Expr::MVar(self.fresh.mvar())
   }

   pub fn get(&self, name: &'src str) -> Option<BoundIdent> {
      self.lookup.get(name).map(|x|
         match x.clone() {
            InternalIdentDoNotUse::FVar(id) => BoundIdent::FVar(id),
            InternalIdentDoNotUse::BVarReverse(rev_id) => BoundIdent::BVar(
               // Minus one because they start at 1
               BVarId(self.depth - rev_id - 1)
            ),
         }
      )
   }

   pub fn bvar0<'f2>(&self) -> Expr<'src, 'f> {
      if self.depth == 0 {
         panic!("#0 is not bound!")
      }
      Expr::BVar(BVarId(0))
   }

   pub fn list(&self) -> Vec<&'src str> {
      self.lookup.keys().map(|k| *k).collect()
   }
}

// Proof/type context Gamma
#[derive(Clone)]
pub enum TypeContext<'src, 'f> {
   Flat(Vector<&'f Expr2<'src, 'f>>),
   /// {x : string} ⊔ {x : number} => {x : string | number}
   Join(&'f TypeContext<'src, 'f>, &'f TypeContext<'src, 'f>),
   /// {x : 1 | 2} ⊓ {x : 1 | "foo"} => {x : 1}
   Meet(&'f TypeContext<'src, 'f>, &'f TypeContext<'src, 'f>),
}
impl <'src, 'f> TypeContext<'src, 'f> {
   pub fn new() -> Self {
      TypeContext::Flat(Vector::new())
   }

   pub fn push_fact(&self, e: &'f Expr2<'src, 'f>) -> TypeContext<'src, 'f> {
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

   pub fn query_bvar_type(&self, id: BVarId) -> &'f Expr2<'src, 'f> {
      use TypeContext::*;
      match self {
         Flat(v) => {
            for fact in v {
               match fact.expr {
                  Expr::Eq { left, right } => {
                     if let Expr::Typeof(x) = left.expr {
                        if let Expr::BVar(id2) = x.expr && id == *id2 {
                           return right;
                        }
                     }
                  }
                  _ => ()
               }
            }
            panic!("Could not compute type for {:?}", id);
         }
         _ => todo!(),
      }
   }

   pub fn query_fvar_type(&self, id: FVarId) -> &'f Expr2<'src, 'f> {
      use TypeContext::*;
      match self {
         Flat(v) => {
            for fact in v {
               match fact.expr {
                  Expr::Eq { left, right } => {
                     if let Expr::Typeof(x) = left.expr {
                        if let Expr::FVar(id2) = x.expr && id == *id2 {
                           return right;
                        }
                     }
                  }
                  _ => ()
               }
            }
            panic!("Could not compute type for {:?}", id);
         }
         _ => todo!(),
      }
   }
}

/// Should contain only Prop
#[derive(Clone)]
pub struct Constraints<'src, 'f>(Vector<&'f Expr2<'src, 'f>>);
impl <'src, 'f> Constraints<'src, 'f> {
   pub fn new() -> Self {
      Constraints(Vector::new())
   }

   pub fn append(&mut self, c: Constraints<'src, 'f>) {
      self.0.append(c.0);
   }

   pub fn add(&mut self, e: &'f Expr2<'src, 'f>) {
      self.0.push_back(e);
   }
}

impl <'src: 'a, 'f, 'a, D, A> Pretty<'a, D, A> for &Expr2<'src, 'f>
where
   A: 'a,
   D: DocAllocator<'a, A>,
   D::Doc: Clone,
{
   fn pretty(self, pty: &'a D) -> DocBuilder<'a, D, A> {
      match self.expr {
         Expr::BVar(id) => pty.text(format!("{:?}", id)),
         Expr::FVar(id) => pty.text(format!("{:?}", id)),
         Expr::MVar(id) => pty.text(format!("{:?}", id)),
         Expr::Eq { left, right } => left.pretty(pty).parens().append(" @== ").append(right.pretty(pty).parens()),
         Expr::Typeof(e) => pty.text("typeof ").append(*e),
         Expr::Pi { info: BinderInfo::Default, params, ret } =>
            pty.intersperse(params.iter().map(|p| *p), ", ").parens().append(" -> ").append(*ret),
         idk => pty.text(format!("{:?}", idk))
      }
   }
}

impl <'src: 'a, 'f, 'a, D, A> Pretty<'a, D, A> for &Context<'src, 'f>
where
   A: 'a,
   D: DocAllocator<'a, A>,
   D::Doc: Clone,
   A: Clone,
{
   fn pretty(self, pty: &'a D) -> DocBuilder<'a, D, A>
   {
      let depth = pty.text("at depth ").append(pty.text(self.id.depth.to_string()));
      let separator = pty.text(",").append(pty.hardline());
      let bindings = pty.intersperse(self.id.list().iter().map(|k| pty.text(*k).append(" is ").append(self.ident(k))), separator.clone());
      let props;
      if let TypeContext::Flat(v) = &self.ty {
         props = pty.intersperse(v.clone(), separator);
      } else {
         todo!();
      }
      let inside =
         depth.append(pty.hardline())
         .append(bindings).append(pty.hardline()).append(pty.hardline())
         .append(props);

      pty.text("Context")
         .append(pty.hardline().append(inside).append(pty.hardline()).group().nest(3).enclose(" {", "}"))
   }
}

impl Display for Context<'_, '_> {
   fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
      let allocator = pretty::BoxAllocator;
      let mut mem = Vec::new();
      _ = Pretty::<_, ()>::pretty(self, &allocator).1.render(70, &mut mem);
      f.write_str(str::from_utf8(&mem).unwrap())
   }
}

impl <'src: 'a, 'f, 'a, D, A> Pretty<'a, D, A> for &Param<'src, 'f>
where
   A: 'a,
   D: DocAllocator<'a, A>,
   D::Doc: Clone,
{
   fn pretty(self, pty: &'a D) -> DocBuilder<'a, D, A> {
      self.name.pretty(pty).append(": ").append(self.ty)
   }
}

impl <'src: 'a, 'f, 'a, D, A> Pretty<'a, D, A> for Name<'src>
where
   A: 'a,
   D: DocAllocator<'a, A>,
   D::Doc: Clone,
{
   fn pretty(self, pty: &'a D) -> DocBuilder<'a, D, A> {
      match self {
         Name::Anon => pty.text("_"),
         Name::Str(s) => pty.text(s),
         rest => pty.text(format!("{:?}", rest))
      }
   }
}
