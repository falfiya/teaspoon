use chumsky::prelude::*;
use chumsky::input::ValueInput;
use chumsky::error::Rich;

pub type Span = SimpleSpan;
pub type EError<'src, T> = extra::Err<Rich<'src, T, Span>>;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Token<'src> {
   // KW
   Let,
   Infer,
   Lemma,
   Sorry,
   // Special idents
   Sort,
   Type,
   Undefined,

   AtEqEq,
   AtEq,
   At, // for metavariables
   EqEqEq,
   EqEq,
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
   Arrow,

   Ident(&'src str),

   Bool(bool),
   Number(&'src str),
   String(&'src str),
}

pub fn tokenize<'src>() -> impl Parser<'src, &'src str, Vec<Spanned<Token<'src>>>, > {
   use Token::*;
   let kw = choice((
      just("let").to(Let),
      just("infer").to(Infer),
      just("sorry").to(Sorry),
      just("Sort").to(Sort),
      just("Type").to(Type),
      just("Undefined").to(Undefined),
   ));

   let ops = choice((
      just("@==").to(AtEqEq),
      just("@=").to(AtEq),
      just("@").to(At),
      just("===").to(EqEqEq),
      just("==").to(EqEq),
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
      just("=>").to(Arrow),
   ));
   
   let ident = text::ident().map(Ident);
   let boolean = just("true").to(true).or(just("false").to(false)).map(Bool);
   let number = text::int(10).map(Number);
   let string = just('"')
   .ignore_then(none_of('"').repeated())
   .then_ignore(just('"'))
   .map_with(|(), e| String(e.slice()));
   
   choice((kw, ops, boolean, number, string, ident))
   .spanned()
   .padded()
   .repeated()
   .collect()
}

#[derive(Clone, Debug)]
pub enum SynParam<'src> {
   Name(Box<Syntax<'src>>),
   Type(Box<Syntax<'src>>),
   Full { name: Box<Syntax<'src>> },
}

#[derive(Clone, Copy, Debug)]
pub enum BinOp {
   AtEqEq,
   AtEq,
   EqEqEq,
   EqEq,
   HasType,
}

#[derive(Clone, Copy, Debug)]
pub enum Unop {
   Plus,
   Minus,
   At,
}

#[derive(Clone, Copy, Debug)]
pub enum Prim<'src> {
   Undefined,
   Bool(bool),
   Nat(u64),
   Int(i64),
   Float(f64),
   String(&'src str),
}

#[derive(Clone, Debug)]
pub enum Syntax<'src> {
   Error,
   Sort,
   Type,
   Sorry,
   Prim(Prim<'src>),
   Ident(&'src str),
   Unary(Unop, Box<Syntax<'src>>),
   BinOp {
      op: BinOp,
      left: Box<Syntax<'src>>,
      right: Box<Syntax<'src>>,
   },
   Lam {
      params: Vec<SynParam<'src>>,
   },
   Definition {
      name: &'src str,
      typ: Option<Box<Syntax<'src>>>,
      val: Box<Syntax<'src>>,
   },
}

pub fn syntax<'src, I>() ->
impl Parser<'src, I, Vec<Spanned<Syntax<'src>>>, EError<'src, Token<'src>>>
where I: ValueInput<'src, Token = Token<'src>, Span = Span>
{
   /*
      // KW
   Let,
   Infer,
   Lemma,
   Sorry,
   // Special idents
   Sort,
   Type,
   Undefined,
    */
   let kw = choice((
      just(Token::Undefined).to(Syntax::Prim(Prim::Undefined)),
      just(Token::Sort).to(Syntax::Sort),
      just(Token::Type).to(Syntax::Type),
      just(Token::Sorry).to(Syntax::Sorry),
   ));

   let num = select! { Token::Number(s) => s }.validate(|s, e, emit| {
      if let Ok(n) = s.parse::<u64>() {
         return Syntax::Prim(Prim::Nat(n));
      }

      if let Ok(n) = s.parse::<i64>() {
         return Syntax::Prim(Prim::Int(n));
      }

      if let Ok(f) = s.parse::<f64>() {
         return Syntax::Prim(Prim::Float(f));
      }

      emit.emit(Rich::custom(e.span(), format!("Invalid number format: '{}'", s)));
      Syntax::Error
   });

   choice((kw, num))
   .spanned()
   .repeated()
   .collect()
}

struct FVarId(u64);
struct BVarId(u64);
struct MVarId(u64);
struct Level(u8);

pub enum Expr<'a> {
   FVar(FVarId),
   BVar(BVarId),
   Const { name: &'a str },
   
   Lam { params: Vec<Syntax<'a>> },
}
