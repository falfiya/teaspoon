use chumsky::prelude::*;
use chumsky::input::{MappedInput};
use chumsky::error::Rich;
use chumsky::pratt::*;
use pretty::{DocAllocator, DocBuilder, Pretty};

pub type Span = SimpleSpan;
pub type EError<'src, T> = extra::Err<Rich<'src, T, Span>>;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Token<'src> {
   // Statements
   Let, Const,
   If, Else,
   Loop,
   Check, Eval,
   Declare, Return,

   // Keywords
   Infer, Extends,
   Underscore, As,

   Sorry,
   Sort,
   Type,
   Prop,
   TyTrue,
   TyFalse,

   // Punctuation
   ParenL,
   ParenR,
   BracketL,
   BracketR,
   BraceL,
   BraceR,
   Comma,
   Colon,
   Semi,
   Eq,

   AtEqEq,
   EqEqEq,

   Bang,
   Plus,
   Minus,
   Asterisk,
   Slash,

   Question,
   At,
   Pi,
   Arrow,

   Word(&'src str),

   Number(&'src str),
   String(&'src str),
}

pub fn lex<'src>() -> impl Parser<'src, &'src str, Vec<Spanned<Token<'src>>>> {
   use Token::*;
   let kw = choice((
      just("let").to(Let),
      just("const").to(Const),
      just("declare").to(Declare),
      just("return").to(Return),
      just("loop").to(Loop),
      just("#check").to(Check),
      just("#eval").to(Eval),
      just("sorry").to(Sorry),
      just("as").to(As),
      just("Sort").to(Sort),
      just("Prop").to(Prop),
      just("Type").to(Type),
      just("True").to(TyTrue),
      just("False").to(TyFalse),
   ));

   let ops = choice((
      just("===").to(EqEqEq),
      just("@==").to(AtEqEq),
      just("=>").to(Arrow),
      just("->").to(Pi),
      just("@").to(At),
      just('?').to(Question),
      just('=').to(Eq),
      just('(').to(ParenL),
      just(')').to(ParenR),
      just('[').to(BracketL),
      just(']').to(BracketR),
      just('{').to(BraceL),
      just('}').to(BraceR),
      just(',').to(Comma),
      just(':').to(Colon),
      just(';').to(Semi),
      just('+').to(Plus),
      just('-').to(Minus),
      just('*').to(Asterisk),
      just('!').to(Bang),
   ));

   let ident = text::ident().map(|s| if s == "_" { Underscore } else { Word(s) });
   let number = text::int(10).map(Number);
   let string = just('"')
   .ignore_then(none_of('"').repeated())
   .then_ignore(just('"'))
   .map_with(|(), e| String(e.slice()));

   choice((kw, ops, number, string, ident))
   .spanned()
   .padded()
   .repeated()
   .collect()
}


pub type PPreExpr<'src> = Box<Spanned<PreExpr<'src>>>;
pub type PPreStatement<'src> = Box<Spanned<PreStatement<'src>>>;
pub type PreBlock<'src> = Vec<Spanned<PreStatement<'src>>>;

#[derive(Clone, Debug)]
pub enum PreParam<'src> {
   Name(&'src str),
   #[deprecated(note="use name with anonymous")]
   Type(PPreExpr<'src>),
   Full { name: &'src str, ty: PPreExpr<'src> },
}

#[derive(Clone, Copy, Debug)]
pub enum BinOp {
   Plus,
   Minus,
   Times,
   Divide,
   AtEqEq,
   EqEqEq,
   SubType,
   HasType,
   Cast,
}

#[derive(Clone, Copy, Debug)]
pub enum Unary {
   Plus,
   Minus,
   Not,
}

#[derive(Clone, Copy, Debug)]
pub enum Prim<'src> {
   Int(i64),
   Float(f64),
   String(&'src str),
}

#[derive(Clone, Debug)]
pub enum PreLamBody<'src> {
   Return(PPreExpr<'src>),
   Block(PreBlock<'src>),
}

#[derive(Clone, Debug)]
pub enum PreExpr<'src> {
   Error,
   Sorry,
   Sort,
   Type,
   Prop,
   TyTrue,
   TyFalse,
   Prim(Prim<'src>),
   Metavariable(&'src str),
   Ident(&'src str),
   Unary(Unary, PPreExpr<'src>),
   Call(PPreExpr<'src>, Vec<Spanned<PreExpr<'src>>>),
   BinOp {
      op: BinOp,
      left: PPreExpr<'src>,
      right: PPreExpr<'src>,
   },
   Lam {
      implicit: bool,
      params: Vec<PreParam<'src>>,
      body: PreLamBody<'src>,
   },
   Pi {
      implicit: bool,
      params: Vec<PreParam<'src>>,
      ret: PPreExpr<'src>,
   }
}

#[derive(Clone, Debug)]
pub enum PreStatement<'src> {
   Error,
   Let {
      name: &'src str,
      ty: Option<PPreExpr<'src>>,
      val: Option<PPreExpr<'src>>,
   },
   Const {
      name: &'src str,
      ty: Option<PPreExpr<'src>>,
      val: PPreExpr<'src>,
   },
   DeclareConst {
      name: &'src str,
      ty: PPreExpr<'src>,
   },
   Check(PPreExpr<'src>),
   Eval(PPreExpr<'src>),
   If {
      cond: PPreExpr<'src>,
      then: PreBlock<'src>,
      elze: Option<PreBlock<'src>>,
   },
   Loop(PreBlock<'src>),
   BareExpr(PPreExpr<'src>),
   Return(PPreExpr<'src>),
}

impl <'src, 'a, D, A> Pretty<'a, D, A> for &PreStatement<'src>
where
   A: 'a,
   D: DocAllocator<'a, A>,
   D::Doc: Clone,
{
   fn pretty(self, allocator: &'a D) -> DocBuilder<'a, D, A>
   {
      use PreStatement::*;
      match self {
         Error => allocator.text("Error"),
         // Let {name, ty, val} => allocator.text("let").,
         _ => todo!(),
      }
   }
}

pub fn pre_block<'tokens, 'src: 'tokens>() ->
   impl Parser<
      'tokens,
      MappedInput<'tokens, Token<'src>, Span, &'tokens [Spanned<Token<'src>>]>,
      PreBlock<'src>,
      EError<'tokens, Token<'src>>,
   > + Clone
{
   let mut stmt = Recursive::declare();
   let mut expr = Recursive::declare();
   let stmts = stmt.clone().separated_by(just(Token::Semi)).allow_trailing().collect();
   let ascription = just(Token::Colon).ignore_then(expr.clone()).map(Box::new).labelled("type ascription");
   let ident_bind = select! {Token::Word(w) => w}.labelled("ident");
   {
      use PreStatement::*;
      let def = just(Token::Eq).ignore_then(expr.clone()).map(Box::new);

      let r#let = just(Token::Let)
         .ignore_then(ident_bind)
         .then(ascription.clone().or_not())
         .then(def.clone().or_not())
         .map(|((name, ty), val)| {
            // It's amusing that the name (&str) has a Span.
            // They're both effectively the same as each other.
            // A Span carries the data in indices whereas the &str is a fat pointer.
            Let { name: name, ty, val }
         });

      let r#const = just(Token::Const)
         .ignore_then(ident_bind)
         .then(ascription.clone().or_not())
         .then(def)
         .map(|((name, ty), val)| Const { name, ty, val });

      let declare_const = just(Token::Declare)
         .ignore_then(just(Token::Const))
         .ignore_then(ident_bind)
         .then(ascription.clone())
         .map(|(name, ty)| DeclareConst { name, ty });

      let check = just(Token::Check)
         .ignore_then(expr.clone())
         .map(Box::new)
         .map(Check);

      let eval = just(Token::Check)
         .ignore_then(expr.clone())
         .map(Box::new)
         .map(Eval);

      let ret = just(Token::Return)
         .ignore_then(expr.clone())
         .map(Box::new)
         .map(Return);

      let raw_expr = expr.clone().map(Box::new).map(BareExpr);

      stmt.define(choice((r#let, r#const, declare_const, check, eval, raw_expr, ret)).spanned());
   }

   {
      use Token::*;
      use Prim::*;
      let special_ident = select! {
         Sorry => PreExpr::Sorry,
         Sort => PreExpr::Sort,
         Type => PreExpr::Type,
         Prop => PreExpr::Prop,
         TyTrue => PreExpr::TyTrue,
         TyFalse => PreExpr::TyFalse,
      };

      let metavariable = just(Question).ignore_then(
         select! {Token::Word(w) => PreExpr::Metavariable(w)})
         .labelled("metavariable");

      let ident =
         select! {Token::Word(w) => PreExpr::Ident(w)}
         .labelled("identifier");

      let num = select! { Number(s) => s }.validate(|s, e, emit| {
         if let Ok(n) = s.parse::<i64>() {
            return PreExpr::Prim(Int(n));
         }

         if let Ok(f) = s.parse::<f64>() {
            return PreExpr::Prim(Float(f));
         }

         emit.emit(Rich::custom(e.span(), format!("Invalid number format: '{}'", s)));
         PreExpr::Error
      }).labelled("number");

      let param_anon = just(Underscore)
         .ignore_then(just(Colon))
         .ignore_then(expr.clone())
         .map(Box::new)
         .map(PreParam::Type);

      let param_nom = ident_bind.clone()
         .then(ascription.or_not())
         .map(|(name, ty)| match ty {
            None => PreParam::Name(name),
            Some(ty) => PreParam::Full { name, ty }
         });

      let single_anon = ident_bind.clone().map(|p| vec![PreParam::Name(p)]);

      let params = param_nom.or(param_anon)
         .separated_by(just(Comma))
         .allow_trailing()
         .collect()
         .delimited_by(just(ParenL), just(ParenR));

      let braced_body = stmts.clone()
         .delimited_by(just(BraceL), just(BraceR))
         .map(PreLamBody::Block);
      let expr_body = expr.clone().map(Box::new).map(PreLamBody::Return);

      let sub_expr = expr.clone()
         .delimited_by(just(ParenL), just(ParenR));

      let atom = choice((
         special_ident.spanned(),
         sub_expr,
         metavariable.spanned(),
         ident.spanned(),
         num.spanned(),
      ));

      let args = expr.clone()
         .separated_by(just(Comma))
         .allow_trailing()
         .collect()
         .delimited_by(just(ParenL), just(ParenR))
         .labelled("function args");

      // foo(bar, baz)
      let apply = atom
         .foldl_with(args.repeated(), |f, args, e|
            PreExpr::Call(Box::new(f), args).with_span(e.span()));

      let nl_expr = apply.pratt((
         // x as number
         infix(left(1),
            just(As).map(|_| BinOp::Cast),
            |l, o, r, e| PreExpr::BinOp {
               op: o,
               left: Box::new(l),
               right: Box::new(r),
            }.with_span(e.span())
         ),
         // +x -x !x
         prefix(2,
            select!{Plus => Unary::Plus, Minus => Unary::Minus, Bang => Unary::Not},
            |o, x, e| PreExpr::Unary(o, Box::new(x)).with_span(e.span())),
         infix(left(3),
            select!{
               Plus => BinOp::Plus,
               Minus => BinOp::Minus,
            },
            |l, o, r, e| PreExpr::BinOp{
               op: o,
               left: Box::new(l),
               right: Box::new(r)
            }.with_span(e.span())
         ),
         infix(left(10),
            select!{Asterisk => BinOp::Plus, Minus => BinOp::Minus},
            |l, o, r, e| PreExpr::BinOp{
               op: o,
               left: Box::new(l),
               right: Box::new(r)
            }.with_span(e.span())
         ),
      ));

      let lam = just(Infer).or_not().map(|o| o.is_some())
         .then(single_anon.or(params.clone()))
         .then_ignore(just(Arrow))
         .then(braced_body.or(expr_body))
         .map(|((implicit, params), body)| PreExpr::Lam {implicit, params, body})
         .spanned();

      let single_anon_type = nl_expr.clone().map(|e| vec![PreParam::Type(Box::new(e))]);

      let pi_type = just(Infer).or_not().map(|o| o.is_some())
         .then(params.or(single_anon_type))
         .then_ignore(just(Pi))
         .then(expr.clone().map(Box::new))
         .map(|((implicit, params), ret)| PreExpr::Pi {implicit, params, ret})
         .spanned();

      expr.define(choice((
         lam,
         pi_type,
         nl_expr,
      )))
   }

   stmts
}
