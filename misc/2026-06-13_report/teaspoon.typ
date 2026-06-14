#import "para-lipics/lib.typ": *
#import "@preview/simplebnf:0.2.0": *
#import "@preview/curryst:0.6.0": prooftree, rule, rule-set
#import "@preview/codelst:2.0.2": sourcecode
#import "wavy.typ"

#let program(body, caption: none, ..args) = figure(
   body,
   kind: "program",
   supplement: [Program],
   caption: caption,
   ..args,
)
#show figure.where(kind: "program"): set figure.caption(position: top)

#show: para-lipics.with(
   title: [Teaspoon:#h(-0.8pt) Liquid Types and More for TypeScript],
   authors: (
      (
         name: "Nicola Gannon",
         email: "nicola@ucsc.edu",
         // website: "https://falfia.fi",
         orcid: "https://orcid.org/0009-0000-6248-2728",
         affiliations: "University of California, Santa Cruz, USA",
      ),
      (
         name: "Kyle Miller",
         email: "kymiller@ucsc.edu",
         website: "https://kmill.github.io",
         orcid: "https://orcid.org/0000-0001-7400-5304",
         affiliations: "University of California, Santa Cruz, USA",
      ),
   ),
   hide-lipics: true,
   hide-doi: true,
   ccs-desc: "Theory of computation → Logic → Type Theory; Theory of computation → Semantics and reasoning → Program semantics → Operational semantics",
   keywords: "Dependent Types, Interactive Theorem Proving, Liquid Types",
   category: "Workshop Report",
   funding: "This material was supported by the juice purchased from the Baskin Engineering Perk on 2026-06-11",
   event-short-title: "CSE 290Q",
   abstract: [
      Static type systems for programming languages provide stronger guarantees of program correctness through analysis at compile time. We present Teaspoon, a dependently typed extension to TypeScript with propositions and Liquid Types.
      Teaspoon is grounded in the Calculus of Constructions and backed with the usual operational semantics, type inference, and constraint solving. Its type system is unusual in its support for mutability and imperative programming, allowing a gradual transition from non-dependent TypeScript to more advanced types.
   ],
)

#place(top + right, dy: 5em, text(fill: gray)[#datetime.today().display()])
#show raw: set text(font: "Operator Mono Lig")

= Introduction

Modern software development has benefited enormously from static type systems and compile-time analysis. Nowhere has demonstrated this better than web development. The community at large#cite(<stateofjs>) has moved away from dynamically typed JavaScript and towards TypeScript, a statically typed superset of JavaScript. TypeScript has surprisingly advanced types for a well-adopted industry language. A programmer can create ersatz dependent types using TypeScript's value types and perform calculations on them in an untyped lambda-calculus fashion. Higher-Kinded Types can be bootlegged#ref(<fp-ts-hkt>) using the powerful `infer` construct.

// TypeScript is a compiler-as-specification, which works remarkably well in practice, but a robust theory would prevent soundness bugs.

TypeScript's type system is gradually typed and does not need to be adopted wholesale. The programmer can introduce static types and typechecking to her program slowly and smoothly without a barrage of errors. There remains a gap between TypeScript and more powerful type systems like the Calculus of Constructions#ref(<coc>). One cannot easily verify that a TypeScript program is correct beyond simple type-correctness. Even simple types such as "integer" cannot be elegantly represented, and types such as "even number" are completely out of reach. We propose Teaspoon, an extension to TypeScript with propositions

#table(
   columns: (auto, auto),
   inset: 0pt,
   stroke: none,
   gutter: 2em,
   [
      and Logically Qualified Types#ref(<liquid-types>). We hope that with a solid type theory foundation from the Calculus of Constructions, we may provide strong guarantees about program correctness.
   ],
   program(caption: [Example Teaspoon Program])[
      #sourcecode[
         ```ts
         const x = 5;
         const hx: x @== 5 = with rfl;
         type Int = Liquid (n: number),
            Number.isInteger(n) @== true;
         x satisfies Int;
         ```
      ]
   ]
)

= Overview

The programmer writes her program in an input syntax.
This syntax is flexible by design, but is ill-suited to static analysis.
First, the elaborator translates the input syntax to the core syntax by filling missing information in with metavariables#footnote[Metavariables are also known as "holes"].
It then queries for type information and records all known facts about the program into a context Γ at each step. We illustrate this process with two example programs in #ref(<ex-1>).
#ref(<ex-id5>) is an identity function which calls `takesFive` with its argument.
#ref(<ex-say>) shows Teaspoon's flow-type inference.

#figure(
   kind: "figure",
   supplement: "Figure",
   caption: [Elaboration and Type Inference Examples])[
   #table(
      columns: (auto, auto),
      inset: (top: 1em, bottom: 1em),
      stroke: (top: 1pt, bottom: 1pt),
      [
         #program(caption: [Monomorphic Identity])[
            #sourcecode[```ts
            declare const takesFive:
               5 -> void;
            // ------------------------ Γ₁₃
            const id5 = a => { // ----- Γ₁₅
               takesFive(a);
               return a;
            };
            // ------------------------ Γ₁₈
            ```]
         ]<ex-id5>
      ],
      [
         #program(caption: [Basic Flow Typing])[
            #sourcecode[```ts
            declare const cond: boolean;
            let say; // --------------- Γ₂₂
            if (cond) { // ------------ Γ₂₃
               say = "hello!";
            } else {
               say = ["goodbye!"];
               // --------------------- Γ₂₇
            }
            // ------------------------ Γ₂₉
            ```]
         ]<ex-say>
      ],
      [
         #place(dx: -6em, dy: 3.2em)[#rotate(-90deg)[Elaborated]]
         #sourcecode[```ts
            declare const takesFive:
               5 -> void;
            const id5: ?m1 = (a: ?m2) => {
               takesFive(a); // ------- C₁₄
               return a; // ----------- C₁₅
            };
         ```]
      ],
      [
         #sourcecode[```ts
         declare const cond: boolean;
         let say: unknown;
         if (cond) {
            say = "hello!"; // ----- C₂₄
         } else {
            say = ["goodbye!"]; // - C₂₆
         }
         ```]
      ],
      [
         $
            C₁₄ &= #[`?m2 extends 5`] \
            C₁₅ &= #[`?m1 extends ?m2`] \
         $
      ],
      [
         $
            C₂₄ &= #[`"hello" extends unknown`] \
            C₂₆ &= #[`["goodbye!"] extends unknown`] \
         $
      ],
      [
         #place(dx: -4.9em, dy: 4em)[#rotate(-90deg)[Solved]]
         $
            Γ₁₃ &= {#[`typeof takesFive @== 5 -> 5`]} \
            Γ₁₅ &= {#[`a @== 5`]} ∪ Γ₁₃ \
            Γ₁₈ &= {#[`typeof id5 @== 5 -> 5`]} ∪ Γ₁₃
         $
      ],
      [
         $
            Γ₂₂ = {&#[`typeof say @== unknown`]} \
            Γ₂₃ = {&#[`(!!cond) @== true`]} ∪ Γ₂₂ \
            Γ₂₇ = {&#[`(!!cond) @== false`] \
                   &#[`say @== ["goodbye!"]`]} ∪ Γ₂₂ \
            Γ₂₉ = {&#[`typeof say @==`] \
                   &#[`"hello" | ["goodbye!"]`]} ∪ Γ₂₂
         $
      ],
   )
]<ex-1>

#v(1em)

TypeScript's subtyping doesn't map cleanly to terms having a single, canonical type. The number `1` is a subtype of `number`, `number | string`, and even `1`. Instead of the usual context $Γ$ containing variables and their types, it now contains only true propositions.

= Elaboration

#let b(content, color) = [
   #show math.equation: set text(fill: color, weight: "bold")
   #eval(content, mode: "math")
   #show math.equation: set text(fill: black, weight: "regular")
]

#let many(content) = [
   #show math.equation: set text(fill: fuchsia, weight: "bold")
   #h(-3pt) $⸨$ #h(-2pt)
   #show math.equation: set text(fill: black, weight: "regular")
   #content
   #show math.equation: set text(fill: fuchsia, weight: "bold")
   #h(-2.1pt) $⸩$ #h(-3pt) $*$ #h(-3.5pt)
]

#let optional(content) = [
   #show math.equation: set text(fill: fuchsia, weight: "bold")
   $⸨$ #h(-2pt)
   #show math.equation: set text(fill: black, weight: "regular")
   #content
   #show math.equation: set text(fill: fuchsia, weight: "bold")
   #h(-2.1pt) $⸩?$
]

#let v = (
   v: b("v", blue),
   x: b("x", olive),
   t: b("τ", blue),
   e: b("e", blue),
   m: [
      `?` #h(-3pt) #b("m", olive)
   ],
   star: b("*", purple),
   infer: `infer`,
   b: b("b", blue),
   bool: text("bool", olive, weight: "bold", style: "oblique"),
   number: text("number", olive, weight: "bold", style: "oblique"),
   string: text("string", olive, weight: "bold", style: "oblique"),
   universe: text("u", olive, weight: "bold", style: "oblique"),
   one: [#h(-2pt) #b("₁", blue)],
   two: [#h(-2pt) #b("₂", blue)],
   prime: [#h(-4pt) #b("'", blue)],
   tactics: text("tactics", olive, weight: "bold", style: "oblique"),
   statement: b("s", blue),
   prim: b("p", blue),
   prop: b("φ", blue),
   param: b("sans(p)", blue),
   params: b("sans(p)", blue),
   // value: b("e", maroon),
)

#let c = (
   t: [#h(-2pt) `:`],
   fresh: text("fresh", olive, weight: "bold"),
   semi: [#h(-3pt) `;` #h(-1pt)],
   comma: [#h(-3pt) `,` #h(-2pt)],
   whnf: text("whnf", olive, font: "CMU Sans Serif", weight: "bold"),
   whnff: text("whnf", olive, font: "CMU Sans Serif", style: "italic"),
)

#let D(content) = [$⟦$ #content $⟧$]


The primary function of elaboration is to translate the input syntax (#ref(<input-syntax>)) to the core syntax seen in #ref(<core-syntax>). It does this by creating metavariables where types are left unspecified.
Unlike Lean 4, Teaspoon's elaboration is not type directed; the elaboration rules can be presented separately from the type inference rules.
In the implementation, the elaborator is also responsible for translating the syntax into a locally nameless#ref(<locally-nameless>) representation and ensuring that variables are defined before use.

#figure(caption: [Core Syntax])[
   #table(
      columns: (45%, auto),
      stroke: none,
      inset: (left: 5pt),

      bnf(
         Prod(
            v.e,
            delim: $→$,
            {
               Or[`                   `][expr]
               Or[#v.x][var]
               Or[#v.m][mvar]
               // Or[`[` $e$`;`$*$ `]`][array]
               Or[#v.e`(`#many[#v.e#v.prime]`)`][call]
               Or[`@`#v.e][unimplicit]
               Or[`(`#v.e`)`][sub-expr]
               Or[`with` #v.tactics][tactics]
               Or[#v.e#v.one `|` #v.e#v.two][bar]
               Or[#v.e#v.one `&` #v.e#v.two][and]
               Or[`!`#h(-4pt)#v.e][logical not]
               Or[`typeof` #v.e][]
               Or[#v.prop][]
            },
         ),

         Prod(
            v.statement,
            delim: $→$,
            {
               Or[][statement]
               Or[`let` #v.x #c.t #v.e][var]
               Or[`const` #v.x #c.t #v.e `=` #v.e][constant]
               Or[
                  `if (` #v.e `)` #v.b#v.one \
                  `else   ` #h(1.4pt) #v.b#v.two
                  ][if]
               Or[`loop` #v.b][]
               Or[`break`][]
               Or[`return` #v.e][]
               Or[#v.x `=` #v.e][assign]
               Or[`#check` #v.e][]
               Or[`#eval` #v.e][]
            },
         ),
      ),
      bnf(
         Prod(
            v.v,
            delim: $→$,
            {
               Or[][value]
               Or[#v.bool][]
               Or[#v.number][]
               Or[#v.string][]
               Or[`undefined`][]
               Or[`sorry`][]
               Or[
                  #optional[#v.infer]
                  `(`#many[#v.x #c.t #v.e #c.comma ]`)` \ `   =>` #v.e#v.prime
               ][lambda]
               Or[`Sort` #v.universe][]
               Or[`unknown`][]
               Or[`True`][true type]
               Or[`False`][false type]
               Or[`Liquid (`#many[#v.x #c.t #v.e]`),` #v.e#v.prime][liquid type]
            }
         ),

         Prod(
            v.prop,
            delim: $→$,
            {
               Or[][propish]
               Or[#v.e#v.one `===` #v.e#v.two][object eq]
               Or[#v.e#v.one `@==` #v.e#v.two][prop eq]
               Or[#v.e#v.one `extends` #v.e#v.two][subtype]
            }
         ),

         Prod(
            v.b,
            delim: $→$,
            {
               Or[`{` #many[#v.statement #c.semi ] `}`][block]
            }
         )
      ),
   )

   #place(bottom+right, dy: -5pt, dx: -5pt, text(gray)[Color guide: #ref(supplement: "Appendix", <how-to-read>)])
]<core-syntax>

Teaspoon's behavior when inferring the type of variables is different than TypeScript's.
#table(
   columns: (auto, auto),
   stroke: none,
   inset: 0pt,
   gutter: 2em,
   [
      Teaspoon allows #ref(<absolute-type-of-var>)a, and rejects #ref(<absolute-type-of-var>)b. In TypeScript, both programs are equivalent and are rejected. TypeScript immediately assigns the absolute type of a variable at the first opportunity. E-LetDef, #hide[on]
   ],
   [
      #std.v(5pt)
      #figure(caption: [Absolute Type of Variable], kind: "program", supplement: "Program")[
         #table(
            columns: (auto, auto),
            stroke: none,
            inset: (left: 10pt, right: 5pt),
            [
               (a)
               ```ts
               let x = 1;
               x = "hello"
               ```
            ],
            [
               (b)
               ```ts
               let x: number = 1;
               x = "hello";
               ```
               #place(dy: -6pt, text(fill: rgb(0, 0, 0, 0), highlight(fill: rgb(255, 0, 0, 30%), `x = "hello"`)))
            ]
         )
      ]<absolute-type-of-var>
   ]
)

#std.v(-1.4em)
on the other hand, does not claim to know an absolute type for a variable without a type ascription. If the user wants to restrict the domain of her variable, she may explicitly annotate it (E-LetDecT) as seen in program b. E-Const matches the behavior of TypeScript.
E-Lam1 handles unary lambdas without parentheses, synthesizing a fresh metavariable for the type of the parameter. E-Lam is superficially complicated: it collects all parameters of the lambda into $overline(sans(p))$, and elaborates a fake marker syntax $sans(P)" "sans(p)$. The parameter $sans(p)$ may be annotated with a type $sans(p)=$#v.x #c.t #v.e or not $sans(p)=$#v.x. The former will be elaborated by E-ParamT and the latter by E-Param. E-Infer is similarly unsightly. It transparently passes `infer` through

#std.v(2em)

#let elet = prooftree(rule(
   name: [E-LetDec],
   [#v.t $=$ `unknown`],
   [
      #set par(leading: 1em)
      #D[`let` #v.x #c.semi $𝓟$]
      $▹$ `let` #v.x #c.t #v.t #c.semi $⟦𝓟⟧$
   ],
))

#let elet2 = prooftree(rule(
   name: [E-LetDecT],
   [#D[#v.e] $▹$ #v.e#v.prime],
   [
      #set par(leading: 1em)
      #h(2pt) #D[`let` #v.x #c.t #v.e #c.semi $𝓟$] \
      $▹$ `let` #v.x #c.t #v.e#v.prime #c.semi $⟦𝓟⟧$
   ],
))

#let elet3 = prooftree(rule(
   name: [E-LetDef],
   [#D[#v.e] $▹$ #v.e#v.prime],
   [#v.t $=$ `unknown`],
   [
      #set par(leading: 1em)
      #D[`let` #v.x `=` #v.e #c.semi $𝓟$] $ ▹$ \
      #h(7pt) `let` #v.x #c.t #v.t #c.semi #v.x `=` #v.e#v.prime  #c.semi $⟦𝓟⟧$
   ],
))

#let elet4 = prooftree(rule(
   name: [E-LetDefT],
   [#D[#v.e#v.one] $▹$ #v.e#v.one#v.prime],
   [#D[#v.e#v.two] $▹$ #v.e#v.two#v.prime],
   [
      #set par(leading: 1em)
      #h(2pt) #D[`let` #v.x #c.t #v.e#v.one `=` #v.e#v.two #c.semi $𝓟$] \
      $ ▹$ `let` #v.x #c.t #v.t #c.semi #v.x `=` #v.e#v.prime  #c.semi $⟦𝓟⟧$
   ],
))

#let econst = prooftree(rule(
   name: [E-Const],
   [#D[#v.e] $▹$ #v.e#v.prime],
   [#c.fresh #v.m],
   [
      #set par(leading: 1em)
      #h(2pt) #D[`const` #v.x `=` #v.e #c.semi $𝓟$] \
      $ ▹$ `const` #v.x #c.t #v.m `=` #v.e#v.prime #c.semi $⟦𝓟⟧$],
))

#let econst2 = prooftree(rule(
   name: [E-ConstT],
   [#D[#v.e#v.one] $▹$ #v.e#v.one#v.prime],
   [#D[#v.e#v.two] $▹$ #v.e#v.two#v.prime],
   [
      #set par(leading: 1em)
      #h(1.9pt) #D[`const` #v.x #c.t #v.e#v.one `=` #v.e#v.two #c.semi $𝓟$] \
      $ ▹$ `const` #v.x #c.t #v.e#v.one#v.prime `=` #v.e#v.two#v.prime #c.semi $⟦𝓟⟧$],
))

#let elam1 = prooftree(rule(
   name: [E-Lam1],
   [#D[#v.e] $▹$ #v.e#v.prime],
   [#c.fresh #v.m],
   [#D[#v.x `=>` #v.e] $ ▹$ `(`#v.x #c.t #v.m `)` `=>` #v.e#v.prime],
))

#let bar-me(length, dy: 0pt, dx: 0pt) = place(dy: dy, dx: dx, line(length: length, stroke: 0.7pt + fuchsia))

#let elam = prooftree(rule(
   name: [E-Lam],
   [
      #bar-me(100%, dy: -7pt)
      #std.v(-4pt)
      #D[$sans(P)$ #v.param] $▹$ $sans(P)$ #v.x #c.t #v.e#v.one#v.prime
   ],
   [#D[#v.e#v.two] $▹$ #v.e#v.two#v.prime],
   [
      #bar-me(28pt, dy: -2pt, dx: 14pt)
      #bar-me(36pt, dy: -2pt, dx: 102pt)
      #D[`(`#many[#v.params #c.comma]`)` `=>` #v.e#v.two] $ ▹$ `(`#v.x #c.t #v.e#v.one#v.prime `)` `=>` #v.e#v.two#v.prime],
))

#let einfer = prooftree(rule(
   name: [E-Infer],
   [#D[`infer` #v.e] $ ▹$ `infer` #D[#v.e]],
))

#let eparam = prooftree(rule(
   name: [E-Param],
   [#c.fresh #v.m],
   [#D[$sans(P)$ #v.x] $ ▹$ $sans(P)$ #v.x #c.t #v.m],
))

#let eparamt = prooftree(rule(
   name: [E-ParamT],
   [#D[#v.e] $▹$ #v.e#v.prime],
   [#D[$sans(P)$ #v.x #c.t #v.e] $ ▹$ $sans(P)$ #v.x #c.t #v.e#v.prime],
))

#figure(caption: [Incomplete Elaboration Rules], kind: "figure", supplement: "Figure")[
   #align(center, rule-set(
      elet,
      elet2,
      elet3,
      elet4,
      econst,
      econst2,
      eparam,
      eparamt,
      einfer,
      elam1,
      elam,
   ))
]<elaboration-rules>

#std.v(2em)

the elaboration process. We assume the elaborator is only called on syntactically valid input programs.

// = Operational Semantics

// Operational semantics are modeled in the big-step fashion. State storage is inspired by capsule environments#ref(<capsules>).

// #let oassign = prooftree(
//    rule(
//       name: [O-Assign],
//       [$⟨$ $σ,$ #v.v$⟩⇓⟨$ $σ',$ #v.e#v.prime $⟩$],
//       [
//          $⟨$ $σ,$ #v.x `=` #v.e #c.semi
//          #many[#v.statement #c.semi]
//          $⟩⇓⟨$
//          $σ'[$ #v.x $∖$ #v.e#v.prime $],$ #v.statement $⟩$
//          #bar-me(6%, dy: -9pt, dx: 55pt)
//       ],
//    )
// )

// #let ocall = prooftree(
//    rule(
//       name: [O-Call],
//       [$⟨$ $σ,$ #v.e$⟩⇓⟨$ $σ',$ #v.x `=>` #v.e $⟩$],
//       [
//          $⟨$ $σ,$ #v.e#v.one `(`
//          #many[#v.e#v.two #c.comma] `)`
//          $⟩⟶⟨$
//          $σ'[$ #v.x $∖$ #v.e#v.prime $],$ #v.statement $⟩$],
//    )
// )

// #figure(kind: "figure", supplement: "Figure", caption: [Big Step Operational Semantics])[
//    #align(center, rule-set(
//       oassign,
//       ocall,
//    ))
// ]

= Type Inference

In Teaspoon's type system, every expression may include function calls which mutate state. Therefore, complete typechecking involves not only learning the type of an expression, but also the variables it clobbers. Consider 
#ref(<context-clobber>): after `z = 2` on line 3, the programmer
#table(
   columns: (50%, auto),
   stroke: none,
   inset: (top: 0pt, bottom: 0pt),
   [
      #std.v(1.4em)
      #program(caption: [Context Clobbering])[
         #sourcecode[
            ```ts
            let z = 1;
            const hz: z @== 1 = with rfl;
            z = 2;
            ```
         ]
      ]<context-clobber>
   ],
   [
      shouldn't have access to `z @== 1`—that would be a contradiction.
      `hz` *must* be clobbered in some way. The type inference system therefore
      keeps track of all uses of `z` and upon reassignment, will remove them
      from the context.
    ]
)
#std.v(1em)

// #let tassign = prooftree(
//    rule(
//       name: [T-Assign],
//       [clobber #v.x in $Γ ⊢ 𝓟$],
//       [
//          $⟨$ $σ,$ #v.x `=` #v.e #c.semi
//          #many[#v.statement #c.semi]
//          $⟩⇓⟨$
//          $σ'[$ #v.x $∖$ #v.e#v.prime $],$ #v.statement $⟩$],
//    )
// )

// #let ocall = prooftree(
//    rule(
//       name: [O-Call],
//       [$⟨$ $σ,$ #v.e$⟩⇓⟨$ $σ',$ #v.e#v.prime $⟩$],
//       [
//          $⟨$ $σ,$ #v.x `=` #v.e #c.semi
//          #many[#v.statement #c.semi]
//          $⟩⇓⟨$
//          $σ'[$ #v.x $∖$ #v.e#v.prime $],$ #v.statement $⟩$],
//    )
// )

// #figure(caption: [Incomplete Type Inference Rules], kind: "figure", supplement: "Figure")[
//    #align(center, rule-set(
//       tassign,
//    ))
// ]<type-inference>

// = Type Simplification

= Implementation

Teaspoon is being implemented in Rust. The parser combinator library named `chumsky` has been incredibly helpful. It emits `PreExpr` and `PreStatement`, which are then elaborated into `Expr` and `Statement`. The elaborator also attaches the contexts, turning them into `Expr2` and `Statement2` respectively. `Expr2::ty()` has enough information to synthesize another `Expr2` which is its own type. 

#program(caption: [Declarations in `elab.rs` _(lifetimes and references omitted)_])[
   #table(
      columns: (auto, auto),
      stroke: none,
      gutter: 2em,
      [
         ```rs
            pub enum Expr {
               Sort(u32),
               FVar(FVarId),
               BVar(BVarId),
               MVar(MVarId),
               Typeof(Expr2),
               Pi { info, params, ret },
               Lam { info, params, ret },
               Eq { left, right },
               Extends { sub, sup },
               Liquid { params, prop},
               Block(Vec<Statement2>),
            }
         ```
      ],
      [
         ```rs
         pub struct Expr2 {
            pub expr: Expr,
            pub ctx: Context,
         }

         pub struct Context {
            al: Bump,
            id: IdentContext,
            ty: TypeContext,
         }
         ```
      ]
   )
]

The context contains an `IdentContext` which is a mapping from `&str` to either `BVar` or `FVar`. Internally, it uses De Bruijn Levels. The `TypeContext` is a list of expressions which are known to be propositions.

#table(
   columns: (55%, auto),
   stroke: none,
   inset: 0pt,
   gutter: 1.5em,
   [
      #program(caption: [Elaboration of Const])[
         ```rs
         Const { name, explicit_ty, val } => {
            let (val2, c) = elab_expr(&ctx, val);
            constraints.append(c);
            let (val2_ty, c) = val2.ty();
            constraints.append(c);

            let ctx_next =
               ctx.new_fvar(name, val2_ty);
            if let Some(ty) = explicit_ty {
               let (ty2, c) = elab_expr(&ctx, ty);
               constraints.append(c);
               constraints.append(
                  Expr::Extends {
                     sub: val2_ty,
                     sup: ty2,
                  }
               );
            }

            let const2 =
               ctx_next.promote_to_statement2(
                  Statement::Const {
                     name, val: val2
                  },
               );
            return (const2, constraints)
         },
         ```
      ]
   ],
   [
      #prooftree(rule(
         [#D[#v.e#v.one] $▹$ #v.e#v.one#v.prime],
         [#D[#v.e#v.two] $▹$ #v.e#v.two#v.prime],
         [
            #set par(leading: 1em)
            #h(4pt) #D[`const` #v.x #c.t #v.e#v.one `=` #v.e#v.two #c.semi $𝓟$] \
            $ ▹$ `const` #v.x #c.t #v.e#v.one#v.prime `=` #v.e#v.two#v.prime #c.semi $⟦𝓟⟧$],
      ))

      #std.v(1em)

      Seen here is the E-ConstT elaboration rule along with some _simplified_ Rust code for elaborating `const`. The elaborator implementation queries type information and captures constraints at the same time as filling in metavariables.
      First, the right hand side of the constant is elaborated and its type is computed. If an explicit type was present, a constraint is recorded—the value must be a term of the explicit type.
      Before returning, the `Statement` must be contextualized using the new context.

      #std.v(5em)
\
      The new statement and the accumulated constraints are returned.
   ]
)

= Future Work: A Lot

Though the theory feels sound at the moment and correct so far, the actual implementation is extremely incomplete.
Essentially nothing is _completely_ written out, not the elaboration rules, operational semantics, or type inference system. Some of it lives in some kind of nebulous state in the author's mind. In that regard, there is immediate, well-specified future work. There are still open questions, too:

- What should the tactic language look like? How should it be parsed?
- I could write the pseudocode for how variable clobbering works, but how do I write what's going on in typing rules?
- Does `unknown` need a universe level? Will there be paradoxes if it doesn't have one?
- How should a Hoare-like program logic be embedded?
- It remains troubling that `1 | 2` in type context means something totally different. Perhaps in the implementation, there should be more than `Expr`.
- When can one use a type? Types aren't valid in all contexts.
- `Expr2`'s `ctx` is the context in which it was created in. This makes sense because we need the original for requesting type information later on. `Statement2`'s `ctx` is the context _after_ the statement runs. This is gross.

#align(bottom)[
   #bibliography("bibliography.bib")
]

#pagebreak()

= Appendix

#counter(heading).update(1)
#counter(figure.where(kind: image)).update(0)
#counter(figure.where(kind: table)).update(0)
#counter(figure.where(kind: raw)).update(0)

#set heading(numbering: "A.1")

== Color-coding and Meta-syntax <how-to-read>

- Variables declared within BNF will be #v.b #h(-3pt) lue
- The parsing of intrinsics like #v.bool is either omitted because they're not the focus of the paper.
   - Except for #v.tactics. I have no idea what that even is.
- Things in #text(fuchsia, weight: "bold")[fuchsia] are meta-meta-syntax.
   - #optional[`dog`] ` ` zero to one `dog`s. e.g.
      - ``
      - `dog`
   - #many[`woof`] ` ` zero to infinity `woof`s. e.g.
      - `woof`
      - #box(width: 200%)[
         #hide[`woof`]
         #place(dy: -5pt, `woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof`)
      ]
   - #many[`mice`,] ` ` if it ends with punctuation, the final element may omit it. e.g.
      - `mice, mice, mice`
   - The horizontal line indicates that multiple items are being captured into one variable.
      #bar-me(17.5%, dy: -9pt, dx: 20pt)

== Responsible AI Disclosure

I have an "agentic" toolchain installed on my device called #link("https://github.com/earendil-works/pi")["Pi"]. It's hooked up to Z.AI's GLM 5.1 running on Fireworks serverless. For programming in Rust, I did admittedly have GLM help me debug gnarly type errors:
#[
   #show raw: set text(size: 4pt)
   ```
The method `separated_by` exists for struct `Or<Map<Then<Labelled<..., ...>, ..., ..., ..., _>, ..., ...>, ...>`, but its trait bounds were not satisfied
the following trait bounds were not satisfied:
`chumsky::combinator::Map<IgnoreThen<IgnoreThen<Just<parser::Token<'_>, _, _>, Just<parser::Token<'_>, _, _>, parser::Token<'_>, _>, chumsky::recursive::Recursive<Indirect<'_, '_, _, chumsky::span::Spanned<PreExpr<'_>>, _>>, parser::Token<'_>, _>, chumsky::span::Spanned<PreExpr<'_>>, fn(Box<chumsky::span::Spanned<PreExpr<'_>>>) -> PreParam<'_> {PreParam::<'_>::Type}>: chumsky::Parser<'_, _, _, _>`
which is required by `Or<chumsky::combinator::Map<Then<Labelled<chumsky::primitive::Select<{closure@C:\Users\billgates\.cargo\registry\src\index.crates.io-1949cf8c6b5b557f\chumsky-0.13.0\src\lib.rs:3170:13: 3170:28}, _, &str, _>, &str>, OrNot<Labelled<chumsky::combinator::Map<IgnoreThen<Just<parser::Token<'_>, _, _>, chumsky::recursive::Recursive<Indirect<'_, '_, _, chumsky::span::Spanned<PreExpr<'_>>, _>>, parser::Token<'_>, _>, chumsky::span::Spanned<PreExpr<'_>>, fn(chumsky::span::Spanned<PreExpr<'_>>) -> Box<chumsky::span::Spanned<PreExpr<'_>>> {Box::<chumsky::span::Spanned<PreExpr<'_>>>::new}>, &str>>, &str, std::option::Option<Box<chumsky::span::Spanned<PreExpr<'_>>>>, _>, (&str, std::option::Option<Box<chumsky::span::Spanned<PreExpr<'_>>>>), {closure@src\parser.rs:341:15: 341:27}>, chumsky::combinator::Map<IgnoreThen<IgnoreThen<Just<parser::Token<'_>, _, _>, Just<parser::Token<'_>, _, _>, parser::Token<'_>, _>, chumsky::recursive::Recursive<Indirect<'_, '_, _, chumsky::span::Spanned<PreExpr<'_>>, _>>, parser::Token<'_>, _>, chumsky::span::Spanned<PreExpr<'_>>, fn(Box<chumsky::span::Spanned<PreExpr<'_>>>) -> PreParam<'_> {PreParam::<'_>::Type}>>: chumsky::Parser<'_, _, _, _>`
`Or<chumsky::combinator::Map<Then<Labelled<chumsky::primitive::Select<{closure@C:\Users\billgates\.cargo\registry\src\index.crates.io-1949cf8c6b5b557f\chumsky-0.13.0\src\lib.rs:3170:13: 3170:28}, _, &str, _>, &str>, OrNot<Labelled<chumsky::combinator::Map<IgnoreThen<Just<parser::Token<'_>, _, _>, chumsky::recursive::Recursive<Indirect<'_, '_, _, chumsky::span::Spanned<PreExpr<'_>>, _>>, parser::Token<'_>, _>, chumsky::span::Spanned<PreExpr<'_>>, fn(chumsky::span::Spanned<PreExpr<'_>>) -> Box<chumsky::span::Spanned<PreExpr<'_>>> {Box::<chumsky::span::Spanned<PreExpr<'_>>>::new}>, &str>>, &str, std::option::Option<Box<chumsky::span::Spanned<PreExpr<'_>>>>, _>, (&str, std::option::Option<Box<chumsky::span::Spanned<PreExpr<'_>>>>), {closure@src\parser.rs:341:15: 341:27}>, chumsky::combinator::Map<IgnoreThen<IgnoreThen<Just<parser::Token<'_>, _, _>, Just<parser::Token<'_>, _, _>, parser::Token<'_>, _>, chumsky::recursive::Recursive<Indirect<'_, '_, _, chumsky::span::Spanned<PreExpr<'_>>, _>>, parser::Token<'_>, _>, chumsky::span::Spanned<PreExpr<'_>>, fn(Box<chumsky::span::Spanned<PreExpr<'_>>>) -> PreParam<'_> {PreParam::<'_>::Type}>>: chumsky::Parser<'_, _, _, _>`
which is required by `&Or<chumsky::combinator::Map<Then<Labelled<chumsky::primitive::Select<{closure@C:\Users\billgates\.cargo\registry\src\index.crates.io-1949cf8c6b5b557f\chumsky-0.13.0\src\lib.rs:3170:13: 3170:28}, _, &str, _>, &str>, OrNot<Labelled<chumsky::combinator::Map<IgnoreThen<Just<parser::Token<'_>, _, _>, chumsky::recursive::Recursive<Indirect<'_, '_, _, chumsky::span::Spanned<PreExpr<'_>>, _>>, parser::Token<'_>, _>, chumsky::span::Spanned<PreExpr<'_>>, fn(chumsky::span::Spanned<PreExpr<'_>>) -> Box<chumsky::span::Spanned<PreExpr<'_>>> {Box::<chumsky::span::Spanned<PreExpr<'_>>>::new}>, &str>>, &str, std::option::Option<Box<chumsky::span::Spanned<PreExpr<'_>>>>, _>, (&str, std::option::Option<Box<chumsky::span::Spanned<PreExpr<'_>>>>), {closure@src\parser.rs:341:15: 341:27}>, chumsky::combinator::Map<IgnoreThen<IgnoreThen<Just<parser::Token<'_>, _, _>, Just<parser::Token<'_>, _, _>, parser::Token<'_>, _>, chumsky::recursive::Recursive<Indirect<'_, '_, _, chumsky::span::Spanned<PreExpr<'_>>, _>>, parser::Token<'_>, _>, chumsky::span::Spanned<PreExpr<'_>>, fn(Box<chumsky::span::Spanned<PreExpr<'_>>>) -> PreParam<'_> {PreParam::<'_>::Type}>>: chumsky::Parser<'_, _, _, _>`
```
]
I have no regrets. This is because I forgot to `Box::new` something. It also helped me proofread this document. Several typos and grammatical errors were fixed because of it. I use "Pi" _maybe_ once per week.

I also use Claude Sonnet 4.6 regularly. Since the start of this project, I have opened 79 different chats. I estimate that about 65 of those chats were related to this project. I don't tend to ask it more than 3 questions per context. I would estimate the average context consumes about 5 minutes of my time. The project has spanned roughly 45 days which means that over the course of about 45 days, I have spent about 5-10 minutes per day using Claude Sonnet 4.6 daily. I find this slightly concerning.

Commonly I tend to ask if there's a good way to do X in Rust or Typst, or if there's a library for it. I find that it's very good at finding libraries and giving me the gist of it. When it comes to actually giving me concrete information, it's better for me to just read the documentation or source code of the library.

== Input Syntax

#set figure(numbering: n => {
   let hdr = counter(heading).get()
   // Replace 'hdr.first()' by '..hdr' to display
   // all heading levels
   [A.#numbering("1", ..hdr)]
})

#figure(caption: [Input Syntax])[
   #table(
      columns: (auto, auto),
      stroke: none,
      inset: (left: 5pt),

      bnf(
         
         Prod(
            v.e,
            delim: $→$,
            {
               Or[`                   `][]
               Or[#v.bool][]
               Or[#v.number][]
               Or[#v.string][]
               Or[`undefined`][]
               Or[#v.x][]
               Or[#v.m][]
               Or[`sorry`][]
               Or[`_`][]
               Or[
                  #optional[#v.infer] #v.x `=>` #v.e
               ][]
               Or[
                  #optional[#v.infer] \
                  `(`#many[#v.x #c.t #v.e #h(-3pt) `,` #h(-2pt) ]`)` `=>` #v.e#v.prime
               ][]
               // Or[`[` $e$`;`$*$ `]`][array]
               Or[#v.e`(`#many[#v.e#v.prime]`)`][]
               Or[`@`#v.e][]
               Or[`(`#v.e`)`][]
               Or[`with` #v.tactics][]
               Or[#v.e#v.one `|` #v.e#v.two][]
               Or[#v.e#v.one `&` #v.e#v.two][]
               Or[`!`#h(-4pt)#v.e][]
               Or[#v.prop][]
               Or[#v.t][]
            },
         ),

         Prod(
            v.prop,
            delim: $→$,
            {
               Or[][]
               Or[#v.e#v.one `===` #v.e#v.two][]
               Or[#v.e#v.one `@==` #v.e#v.two][]
               Or[#v.e#v.one `extends` #v.e#v.two][]
               Or[#v.e#v.one `satisfies` #v.e#v.two][]
            }
         ),
      ),
      bnf(
         Prod(
            v.t,
            delim: $→$,
            {
               Or[`                 `][]
               Or[`Prop`][]
               Or[`Type`][]
               Or[`Sort` #v.universe][]
               Or[`Type` #v.universe][]
               Or[`True`][]
               Or[`False`][]
               Or[`typeof` #v.e][]
               Or[`Liquid (`#many[#v.x #c.t #v.e]`),` #v.e#v.prime][]
            }
         ),

         Prod(
            v.statement,
            delim: $→$,
            {
               Or[][]
               Or[`let` #v.x #optional[#c.t #v.e] #optional[`=` #v.e]][]
               Or[`const` #v.x #optional[#c.t #v.e] `=` #v.e][]
               Or[
                  `if (` #v.e `)` #v.b
               ][]
               Or[
                  `if (` #v.e `)` #v.b#v.one \
                  `else   ` #h(1.4pt) #v.b#v.two
               ][]
               Or[`loop` #v.b][]
               Or[`break`][]
               Or[`return` #optional[#v.e]][]
               Or[#v.x `=` #v.e][]
               Or[`#check` #v.e][]
               Or[`#eval` #v.e][]
            },
         ),

         Prod(
            v.b,
            delim: $→$,
            {
               Or[`{` #many[#v.statement #c.semi ] `}`][]
            }
         )
      ),
   )
]<input-syntax>

#align(bottom)[
   The primary author had so much fun with this project :3 \
   They would like to thank the CSE 290Q workshop for its generous sponsorship.
]
