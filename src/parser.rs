use chumsky::prelude::*;
use chumsky::input::{MappedInput};
use chumsky::error::Rich;
use chumsky::pratt::*;

pub type Span = SimpleSpan;
pub type EError<'src, T> = extra::Err<Rich<'src, T, Span>>;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Token<'src> {
   // keywords
   Let,
   Infer,
   Extends,
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
   Underscore,

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

// Spanned box.
pub type Sox<T> = Box<Spanned<T>>;
// pub type SVec<T> = Spanned<Vec<Spanned<T>>>;
pub type SVec<T> = Vec<Spanned<T>>;
pub type PPreExpr<'src> = Sox<PreExpr<'src>>;
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
   Plus,
   Minus,
   Times,
   Divide,
   AtEqEq,
   EqEqEq,
   Subtype,
}

#[derive(Clone, Copy, Debug)]
pub enum Unary {
   Plus,
   Minus,
   Not,
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

static DISALLOWED_IDENT: &[&'static str] = &[
   "undefined", "number", "string", "boolean",
];

#[derive(Clone, Debug)]
pub enum PreLamBody<'src> {
   Return(PPreExpr<'src>),
   Block(VPreStatement<'src>),
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
   App(PPreExpr<'src>, Vec<Spanned<PreExpr<'src>>>),
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
   If {
      cond: PPreExpr<'src>,
      then: VPreStatement<'src>,
      elze: Option<VPreStatement<'src>>,
   },
}

pub fn pre_statements<'tokens, 'src: 'tokens>() ->
   impl Parser<
      'tokens,
      MappedInput<'tokens, Token<'src>, Span, &'tokens [Spanned<Token<'src>>]>,
      VPreStatement<'src>,
      EError<'tokens, Token<'src>>,
   > + Clone
{
   let mut stmt = Recursive::declare();
   let mut expr = Recursive::declare();
   let stmts = stmt.clone().separated_by(just(Token::Semi)).allow_trailing().collect();
   let ascription = just(Token::Colon).ignore_then(expr.clone()).map(Box::new);
   let ident_ = select! {Token::Word(w) => w}.filter(|w| !DISALLOWED_IDENT.contains(&w));
   {
      use PreStatement::*;
      let defn = just(Token::Let)
         .ignore_then(ident_)
         .then(ascription.clone().or_not())
         .then_ignore(just(Token::Eq))
         .then(expr.clone())
         .map(|((name, ty), val)| {
            // It's amusing that the name (&str) has a Span.
            // They're both effectively the same as each other.
            // A Span carries the data in indices whereas the &str is a fat pointer.
            Definition { name: name, ty, val: Box::new(val) }
         });

      let check = just(Token::Check)
         .ignore_then(expr.clone())
         .map(Box::new)
         .map(Check);

      let eval = just(Token::Check)
         .ignore_then(expr.clone())
         .map(Box::new)
         .map(Eval);

      stmt.define(choice((defn, check, eval)).spanned());
   }

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

      let metavariable = just(Question).ignore_then(ident_).map(PreExpr::Metavariable);
      let ident = ident_.map(PreExpr::Ident);

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

      let param_anon = just(Underscore)
         .ignore_then(just(Colon))
         .ignore_then(expr.clone())
         .map(|e| PreParam::Type(Box::new(e)));
      let param_nom = ident_
         .then(ascription.or_not())
         .map(|(name, ty)| match ty {
            None => PreParam::Name(name),
            Some(ty) => PreParam::Full { name, ty }
         });

      let single_anon = ident_.map(|p| vec![PreParam::Name(p)]);

      let params = param_nom.or(param_anon)
         .separated_by(just(Comma))
         .allow_trailing()
         .collect()
         .delimited_by(just(ParenL), just(ParenR));

      let lam = just(Infer).or_not().map(|o| o.is_some())
         .then(single_anon.or(params))
         .then_ignore(just(Arrow))
         .then(stmts.clone().delimited_by(just(BraceL), just(BraceR)))
         .map(|((implicit, params), body)| PreExpr::Lam {implicit, params, body});

      let args = expr.clone()
         .separated_by(just(Comma))
         .allow_trailing()
         .collect()
         .delimited_by(just(ParenL), just(ParenR));

      // foo(bar, baz)
      let apply = expr.clone()
         .then(args)
         .map(|(func, args)| PreExpr::App(Box::new(func), args));

      let atom = choice((
         keywords,
         lam,
         metavariable,
         ident,
         num,
         apply,
      )).spanned();

      expr.define(
         atom.pratt((
            // +x -x !x
            prefix(1,
               select!{Plus => Unary::Plus, Minus => Unary::Minus, Bang => Unary::Not},
               |o, x, e| PreExpr::Unary(o, Box::new(x)).with_span(e.span())),
            infix(left(2),
               select!{Plus => BinOp::Plus, Minus => BinOp::Minus},
               |l, o, r, e| PreExpr::BinOp{
                  op: o,
                  left: Box::new(l),
                  right: Box::new(r)
               }.with_span(e.span())
            ),
            infix(left(3),
               select!{Asterisk => BinOp::Plus, Minus => BinOp::Minus},
               |l, o, r, e| PreExpr::BinOp{
                  op: o,
                  left: Box::new(l),
                  right: Box::new(r)
               }.with_span(e.span())
            ),
         ))
      )
   }

   stmts
}

// pub struct FVarId(u64);
// pub struct BVarId(u64);
// pub struct MVarId(u64);
// pub struct Level(u8);

// pub enum Expr<'a> {
//    Sort(u16),

//    FVar(FVarId),
//    BVar(BVarId),
//    Const { name: &'a str },

//    Lam { params: Vec<Expr<'a>> },
// }
