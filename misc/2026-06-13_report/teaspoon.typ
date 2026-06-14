#import "para-lipics/lib.typ": *
#import "@preview/simplebnf:0.2.0": *
#import "@preview/curryst:0.6.0": prooftree, rule, rule-set
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
      Static type systems for programming languages provide stronger guarantees of program correctness through analysis at compile time. They typically eliminate all runtime type errors and enforce proper usage of APIs. The programmer can even lean on the type system to help her reason about the nature of her data. The benefits of static typing are best showcased in web development. JavaScript is the executable language of the web, but most#cite(<stateofjs>) web developers use TypeScript, a statically typed extension to JavaScript. TypeScript is a compiler-as-specification, which works remarkably well in practice, but a robust theory would prevent soundness bugs. Teaspoon aims to do what TypeScript did for JavaScript. It extends a subset of TypeScript, formally backing it with the usual operational semantics, type inference, and constraint solving. Teaspoon's type system is unusual in its support for mutability and imperative programming. The addition of first-class propositions and liquid types effectively create a dependently typed TypeScript.
   ],
)

= Introduction

Modern software development has benefitted enormously from static type systems and compile-time analysis. Nowhere has demonstrated this better than web-development. The community at large has moved away from dynamically typed JavaScript and towards TypeScript, a statically typed superset of JavaScript. TypeScript has surprisingly advanced types for a well-adopted industry language. A programmer can create ersatz dependent types using TypeScript's value types and perform calculations on them in an untyped lambda-calculus fashion. Higher Kinded Types can be bootlegged#ref(<fp-ts-hkt>) using the powerful `infer` construct.

How can we bring TypeScript even closer to advanced type systems like Lean4?

What am I contributing?

// Theorem provers like 
// Languages with more powerful type systems such as 

// This shows that if people are given the option to slowly learn, it's good for them.


// If they tried to learn theorem proving through Coq or Isabelle or Lean, I think they wouldn't want to.



// Formal verification tools such as Coq, Isabelle, and Lean#ref(<lean4>) do something idk. It's pretty great. But they are not widely adopted in industry code. The model is too 

// #ref(<coc>)

// Formal verification is cool, and having proofs of things is cool too. But currently nobody knows how to do proofs in the industry.

// That's why we need to extend something that already exists.



// - What an extension of typescript even looks like.
- Type Theory Foundations? (Model it on CoC?)/

// Let's make web-developers learn theorem proving a Teaspoon of propositions at a time.

= Overview

// Help the readers into the cold water

The programmer writes her program in an input syntax.
This syntax is flexible by design, but is ill-suited to static analysis.
First, the elaborator translates the input syntax to the core syntax by filling missing information in with metavariables#footnote[Metavariables are also known as "holes"].
It then queries for type information and records all known facts about the program into a context Γ at each step.

We illustrate this process with two example programs in #ref(<ex-1>).
#ref(<ex-id5>) is an identity function which calls `takesFive` with its argument.
#ref(<ex-say>) shows Teaspoon's flow-type inference.


#show raw: set text(font: "Operator Mono Lig")

#import "@preview/codelst:2.0.2": sourcecode

#figure(
   kind: "figure",
   supplement: "Figure",
   caption: [Elaboration and Type Inference])[
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
   statements: [
      #show math.equation: set text(fill: blue, weight: "bold")
      $overline(s)$
      #show math.equation: set text(fill: black, weight: "regular")
   ],
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
)

#let mvar = [$?$ #h(-1pt) $m$]

#let D(content) = [$⟦$ #content $⟧$]

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

#let elam1 = prooftree(rule(
   name: [E-Lam1],
   [#D[#v.e] $▹$ #v.e#v.prime],
   [#c.fresh #v.m],
   [#D[#v.x `=>` #v.e] $ ▹$ `(`#v.x #c.t #v.m `)` `=>` #v.e#v.prime],
))

#let elam = prooftree(rule(
   name: [E-Lam],
   [
      #line(length: 100%, stroke: 0.5pt + fuchsia)
      #std.v(-4pt)
      #D[$sans(P)$ #v.param] $▹$ $sans(P)$ #v.x #c.t #v.e#v.one#v.prime
   ],
   [#D[#v.e#v.two] $▹$ #v.e#v.two#v.prime],
   [
      #place(dy: -2pt, dx: 15pt)[#line(length: 28pt, stroke: 0.5pt + fuchsia)]
      #place(dy: -2pt, dx: 102pt)[#line(length: 36pt, stroke: 0.5pt + fuchsia)]
      #D[`(`#many[#v.params #h(-3pt) `,` #h(-2pt) ]`)` `=>` #v.e#v.two] $ ▹$ `(`#v.x #c.t #v.e#v.one#v.prime `)` `=>` #v.e#v.two#v.prime],
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


The primary function of elaboration is to translate the input syntax (#ref(<input-syntax>)) to the core syntax seen in #ref(<core-syntax>). It does this by creating metavariables where types are left unspecified.
Unlike Lean 4, Teaspoon's elaboration is not type directed; the elaboration rules can be presented separately from the type inference rules.
In the implementation, the elaborator is also responsible for translating the syntax into a locally nameless#ref(<locally-nameless>) representation and ensuring that variables are defined before use.


Teaspoon's behavior when  inferring the type of variables is different than TypeScript's.
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
on the other hand,  does not claim to know an absolute type for a variable without a type ascription. If the user wants to restrict the domain of her variable, she may explicitly annotate it (E-LetDecT) as seen in program b. E-Const matches the behavior of TypeScript.

#std.v(2em)

#figure(caption: [Elaboration Rules], kind: "figure", supplement: "Figure")[
   #align(center, rule-set(
      elet,
      elet2,
      elet3,
      elet4,
      econst,
      eparam,
      eparamt,
      elam1,
      elam,
   ))
]<elaboration-rules>

E-Lam1 handles unary lambdas without parentheses, synthesizing a fresh metavariable for the type of the parameter. E-Lam is superficially complicated: it collects all parameters of the lambda into $overline(sans(p))$, and elaborates a fake marker syntax $sans(P)" "sans(p)$. The parameter $sans(p)$ may be annotated with a type $sans(p)=$#v.x #c.t #v.e or not $sans(p)=$#v.x. The former will be elaborated by E-Param and the latter E-ParamT.

#figure(caption: [Core Syntax])[
   #table(
      columns: (auto, auto),
      stroke: none,
      inset: (left: 5pt),

      bnf(
         
         Prod(
            v.e,
            delim: $→$,
            {
               Or[`                   `][expr]
               Or[#v.bool][]
               Or[#v.number][]
               Or[#v.string][]
               Or[`undefined`][]
               Or[#v.x][var]
               Or[#v.m][mvar]
               Or[`sorry`][]
               Or[
                  #optional[#v.infer] \
                  `(`#many[#v.x #c.t #v.e #h(-3pt) `,` #h(-2pt) ]`)` `=>` #v.e#v.prime
               ][lambda]
               // Or[`[` $e$`;`$*$ `]`][array]
               Or[#v.e`(`#many[#v.e#v.prime]`)`][call]
               Or[`@`#v.e][unimplicit]
               Or[`(`#v.e`)`][sub-expr]
               Or[`with` #v.tactics][tactics]
               Or[#v.e#v.one `|` #v.e#v.two][bar]
               Or[#v.e#v.one `&` #v.e#v.two][and]
               Or[`!`#h(-4pt)#v.e][logical not]
               Or[#v.prop][]
               Or[#v.t][]
            },
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
      ),
      bnf(
         Prod(
            v.t,
            delim: $→$,
            {
               Or[`                 `][typeish]
               Or[`Sort` #v.universe][]
               Or[`unknown`][]
               Or[`True`][true type]
               Or[`False`][false type]
               Or[`typeof` #v.e][]
               Or[`Liquid` \
               `(`#many[#v.x #c.t #v.e]`),` #v.e#v.prime][liquid type]
            }
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

         Prod(
            v.b,
            delim: $→$,
            {
               Or[`{` #many[#v.statement #c.semi ] `}`][block]
            }
         )
      ),
   )
]<core-syntax>

= Operational Semantics

Operational semantics are modeled in a big-step way using something similar to capsule environments#ref(<capsules>).


#let oassign = prooftree(
   rule(
      name: [O-Assign],
      [$⟨$ $σ,$ #v.e$⟩⇓⟨$ $σ',$ #v.e#v.prime $⟩$],
      [
         $⟨$ $σ,$ #v.x `=` #v.e #c.semi
         #many[#v.statements #c.semi]
         $⟩⇓⟨$
         $σ'[$ #v.x $∖$ #v.e#v.prime $],$ #v.statements $⟩$],
   )
)

#let ocall = prooftree(
   rule(
      name: [O-Call],
      [$⟨$ $σ,$ #v.e$⟩⇓⟨$ $σ',$ #v.e#v.prime $⟩$],
      [
         $⟨$ $σ,$ #v.x `=` #v.e #c.semi
         #many[#v.statements #c.semi]
         $⟩⇓⟨$
         $σ'[$ #v.x $∖$ #v.e#v.prime $],$ #v.statements $⟩$],
   )
)

#figure(kind: "figure", supplement: "Figure", caption: [Big Step Operational Semantics])[
   #align(center, rule-set(
      oassign,
      ocall,
   ))
]

#let var = $x$

#show math.equation: set text(fill: black, weight: "regular")

#let cconst = `const`
#let ceq = `=`
#let lam = `=>`;

// #prooftree(rule(
//   name: [E-Const],
//   $Γ ⊢ e ▹ e'$,
//   $"fresh " #mvar$,
//   $Γ ⊢ (#cconst x #ceq e) ▹ (#cconst x#ascribe #mvar #ceq e')$,
// ))

// #prooftree(rule(
//   name: [E-Lam],
//   [$Γ ⊢ e ▹ e',C$],
//   [$"fresh " #mvar$],
//   [$Γ ⊢ (x #lam e) ▹ ((x#ascribe #mvar)#lam e')$],
// ))

#pagebreak()

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
#std.v(-0.5em)

#let tassign = prooftree(
   rule(
      name: [T-Assign],
      [$Γ ⊢ $],
      [
         $⟨$ $σ,$ #v.x `=` #v.e #c.semi
         #many[#v.statements #c.semi]
         $⟩⇓⟨$
         $σ'[$ #v.x $∖$ #v.e#v.prime $],$ #v.statements $⟩$],
   )
)

#let ocall = prooftree(
   rule(
      name: [O-Call],
      [$⟨$ $σ,$ #v.e$⟩⇓⟨$ $σ',$ #v.e#v.prime $⟩$],
      [
         $⟨$ $σ,$ #v.x `=` #v.e #c.semi
         #many[#v.statements #c.semi]
         $⟩⇓⟨$
         $σ'[$ #v.x $∖$ #v.e#v.prime $],$ #v.statements $⟩$],
   )
)

#figure(caption: [Type Inference Rules], kind: "figure", supplement: "Figure")[
   #align(center, rule-set(
      tassign,
   ))
]<type-inference>

With mutable variables something something something.

Have to forget proofs about what they are, and widen to what they can be.

With constants, all new information you learn stays with you.

There's something similar about how you can't "keep" information between function calls.

// = Program Logic

== Type Simplification

= Implementation

Teaspoon is being implemented in Rust using the parser combinator called `chumsky`. The parser emits `PreExpr`s and `PreStatement`s, which are then elaborated into `Expr` and `Statement`. The elaborator also attaches the contexts, turning them into `Expr2` and `Statement2` respectively.

= Future Work

Though the theory feels sound at the moment and correct so-far, the actual implementation is extremely incomplete.
Essentially nothing is _completely_ written out, not the elaboration rules, operational semantics, or type inference system. All of it lives in the author's mind. In that regard, there is immediate, well-specified future work.

There are still open questions, too:

- What should the tactic language look like? How should it be parsed?
- Does `unknown` need a universe level? Will there be paradoxes if it doesn't have one?
- How should a hoare-like program-logic be embedded?
- It remains troubling that `1 | 2` in type context means something totally different. Perhaps in the implementation, there should be more than `Expr`.

#align(bottom)[
   #bibliography("bibliography.bib")
]

#pagebreak()

= Appendix

#counter(heading).update(1)
#counter(figure.where(kind: image)).update(0)
#counter(figure.where(kind: table)).update(0)
#counter(figure.where(kind: raw)).update(0)

#set figure(numbering: n => {
   let hdr = counter(heading).get()
   // Replace 'hdr.first()' by '..hdr' to display
   // all heading levels
   [appx.#numbering("1.1", hdr.first(), n)]
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
               Or[#v.e#v.one `satisfies` #v.e#v.one][]
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
               Or[`let` #v.x #c.t #v.e][]
               Or[`const` #v.x #c.t #v.e `=` #v.e][]
               Or[
                  `if (` #v.e `)` #v.b
               ][]
               Or[
                  `if (` #v.e `)` #v.b#v.one \
                  `else   ` #h(1.4pt) #v.b#v.two
               ][]
               Or[`loop` #v.b][]
               Or[`break`][]
               Or[`return`][]
               Or[`return` #v.e][]
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

// #align(bottom)[
//    The primary author had so much fun with this project :3 \
//    They would like to thank the CSE 290Q workshop for its generous sponsorship.
// ]
