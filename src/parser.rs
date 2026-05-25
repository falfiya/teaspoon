use chumsky::prelude::*;
use chumsky::input::{MappedInput};
use chumsky::error::Rich;

pub type Span = SimpleSpan;
pub type EError<'src, T> = extra::Err<Rich<'src, T, Span>>;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Token<'src> {
   // keywords
   Let,
   Infer,
   Check,
   Eval,
   If,
   Else,
   Sorry,
   Sort,
   Type,
   Prop,
   TyTrue,
   TyFalse,

   AtEqEq,
   // AtEq,
   At, // for metavariables
   EqEqEq,
   // EqEq,
   Eq,
   AtParenL,
   ParenL,
   ParenR,
   BracketL,
   BracketR,
   BraceL,
   BraceR,
   Comma,
   Colon,
   Semi,
   Plus,
   Minus,
   Times,
   Pi,
   Arrow,

   Word(&'src str),

   Number(&'src str),
   String(&'src str),
}

pub fn tokenize<'src>() -> impl Parser<'src, &'src str, Vec<Spanned<Token<'src>>>> {
   use Token::*;
   let kw = choice((
      just("let").to(Let),
      just("#check").to(Check),
      just("#eval").to(Eval),
      just("sorry").to(Sorry),
      just("Sort").to(Sort),
      just("Prop").to(Prop),
      just("Type").to(Type),
      just("True").to(TyTrue),
      just("False").to(TyFalse),
   ));

   let ops = choice((
      just("@==").to(AtEqEq),
      just("@").to(At),
      just("===").to(EqEqEq),
      just('=').to(Eq),
      just("@(").to(AtParenL),
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
      just('*').to(Times),
      just("->").to(Pi),
      just("=>").to(Arrow),
   ));

   let ident = text::ident().map(Word);
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

// Spanned box.
pub type Sox<T> = Box<Spanned<T>>;
pub type SVec<T> = Vec<Spanned<T>>;
pub type PPreExpr<'src> = Sox<PreExpr<'src>>;
pub type VPreExpr<'src> = SVec<PreExpr<'src>>;
pub type PPreStatement<'src> = Sox<PreStatement<'src>>;
pub type VPreStatement<'src> = SVec<PreStatement<'src>>;

#[derive(Clone, Debug)]
pub enum PreParam<'src> {
   Name(&'src str),
   Type(PPreExpr<'src>),
   Full { name: &'src str, ty: PPreExpr<'src> },
}

#[derive(Clone, Copy, Debug)]
pub enum BinOp {
   AtEqEq,
   AtEq,
   EqEqEq,
   EqEq,
   Subtype,
}

#[derive(Clone, Copy, Debug)]
pub enum Unary {
   Plus,
   Minus,
   At,
}

#[derive(Clone, Copy, Debug)]
pub enum Prim<'src> {
   Undefined,
   True,
   False,
   Nat(u64),
   Int(i64),
   Float(f64),
   String(&'src str),
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
   Ident(&'src str),
   Unary(Unary, PPreExpr<'src>),
   App(PPreExpr<'src>, Vec<Spanned<PreExpr<'src>>>),
   BinOp {
      op: BinOp,
      left: PPreExpr<'src>,
      right: PPreExpr<'src>,
   },
   If {
      cond: PPreExpr<'src>,
      then: PPreStatement<'src>,
      elze: Option<PPreStatement<'src>>,
   },
   Lam {
      implicit: bool,
      params: Vec<PreParam<'src>>,
      body: PPreStatement<'src>,
   },
}

static DISALLOWED_IDENT: &[&'static str] = &[
   "undefined", "number", "string", "boolean",
];

pub fn pre_ident<'tokens, 'src: 'tokens>() ->
   impl Parser<
      'tokens,
      MappedInput<'tokens, Token<'src>, Span, &'tokens [Spanned<Token<'src>>]>,
      &'src str,
      EError<'tokens, Token<'src>>,
   >
{
   select! {Token::Word(w) => w}.filter(|w| !DISALLOWED_IDENT.contains(&w))
}

pub fn pre_expr<'tokens, 'src: 'tokens>() ->
   impl Parser<
      'tokens,
      MappedInput<'tokens, Token<'src>, Span, &'tokens [Spanned<Token<'src>>]>,
      Spanned<PreExpr<'src>>,
      EError<'tokens, Token<'src>>,
   >
{
   use Token::*;
   use Prim::*;

   let keywords = select! {
      Sorry => PreExpr::Sorry,
      Sort => PreExpr::Sort,
      Type => PreExpr::Type,
      Prop => PreExpr::Prop,
      TyTrue => PreExpr::TyTrue,
      TyFalse => PreExpr::TyFalse,
      Word("undefined") => PreExpr::Prim(Undefined),
      Word("true") => PreExpr::Prim(True),
      Word("false") => PreExpr::Prim(False),
   };

   let num = select! { Number(s) => s }.validate(|s, e, emit| {
      if let Ok(n) = s.parse::<u64>() {
         return PreExpr::Prim(Nat(n));
      }

      if let Ok(n) = s.parse::<i64>() {
         return PreExpr::Prim(Int(n));
      }

      if let Ok(f) = s.parse::<f64>() {
         return PreExpr::Prim(Float(f));
      }

      emit.emit(Rich::custom(e.span(), format!("Invalid number format: '{}'", s)));
      PreExpr::Error
   });

   // Pratt parse it.
   let unary = select! {
      At => Unary::At,
      Plus => Unary::Plus,
      Minus => Unary::Minus,
   }


   choice((
      keywords,
      num,
      pre_ident().map(PreExpr::Ident)
   )).spanned()
}

#[derive(Clone, Debug)]
pub enum PreStatement<'src> {
   Error,
   Definition {
      name: &'src str,
      ty: Option<PPreExpr<'src>>,
      val: PPreExpr<'src>,
   },
   Check(PPreExpr<'src>),
   Eval(PPreExpr<'src>),
}

pub fn pre_statement<'tokens, 'src: 'tokens>() ->
   impl Parser<
      'tokens,
      MappedInput<'tokens, Token<'src>, Span, &'tokens [Spanned<Token<'src>>]>,
      Vec<Spanned<PreStatement<'src>>>,
      EError<'tokens, Token<'src>>,
   >
{
   use PreStatement::*;

   let type_annotation = just(Token::Colon).ignore_then(pre_expr());

   let defn = just(Token::Let)
      .ignore_then(pre_ident())
      .then(type_annotation.or_not())
      .then_ignore(just(Token::Eq))
      .then(pre_expr())
      .map(|((name, ty), val)| {
         // It's amusing that the name (&str) has a Span.
         // They're both effectively the same as each other.
         // A Span carries the data in indices whereas the &str is a fat pointer.
         Definition { name: name, ty: ty.map(Box::new), val: Box::new(val) }
      });

   let check = just(Token::Check)
      .ignore_then(pre_expr())
      .map(Box::new)
      .map(Check);

   let eval = just(Token::Check)
      .ignore_then(pre_expr())
      .map(Box::new)
      .map(Eval);

   choice((defn, check, eval)).spanned().repeated().collect()
}

pub struct FVarId(u64);
pub struct BVarId(u64);
pub struct MVarId(u64);
pub struct Level(u8);

pub enum Expr<'a> {
   Sort(u16),

   FVar(FVarId),
   BVar(BVarId),
   Const { name: &'a str },

   Lam { params: Vec<Expr<'a>> },
}
