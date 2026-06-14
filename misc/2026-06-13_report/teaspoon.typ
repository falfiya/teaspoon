#import "para-lipics/lib.typ": *
#import "@preview/simplebnf:0.2.0": *
#import "@preview/curryst:0.6.0": prooftree, rule, rule-set

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
  keywords: "Liquid Types, Dependent Types, Interactive Theorem Proving",
  category: "Workshop Report",
  funding: "This material was supported by the juice purchased from the Baskin Engineering Perk on 2026-06-11",
  event-short-title: "CSE 290Q",
  abstract: [
    Static type systems for programming languages provide stronger guarantees of program correctness through analysis at compile time. They typically eliminate all runtime type errors and enforce proper usage of APIs. The programmer can even lean on the type system to help her reason about the nature of her data. The benefits of static typing are best showcased in web development. JavaScript is the executable language of the web, but most #cite(<stateofjs>) web developers use TypeScript, a statically typed extension to JavaScript. TypeScript is a compiler-as-specification, which works remarkably well in practice, but a robust theory would prevent soundness bugs. Teaspoon aims to do what TypeScript did for JavaScript. It extends a subset of TypeScript, formally backing it with the usual operational semantics, type inference, and constraint solving. Teaspoon's type system is unusual in its support for mutability and imperative programming. The addition of first-class propositions and liquid types effectively create a dependently typed TypeScript.
  ],
)

// body of the paper

// #bibliography("bibliography.bib")

= Introduction

= Overview

== Example 1 (id5)

#show raw: set text(font: "Operator Mono Lig")
```ts
declare const takesFive: 5 -> 5;

const id5 = x => {
   takesFive(x);
   return x;
};
```

== Example 2 (Flow Typing)

```ts
declare const a: boolean;
let x;
if (a) {
   x = "hello";
} else {
   x = ["goodbye"];
}
```

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
   [#D[`let` #v.x #c.semi $𝓟$] $▹⟦𝓟⟧$],
))

#let elet2 = prooftree(rule(
   name: [E-LetDecT],
   [#D[#v.e] $▹$ #v.e#v.prime],
   [#D[`let` #v.x #c.t #v.e #c.semi $𝓟$] $ ▹$ `let` #v.x #c.t #v.e#v.prime #c.semi $⟦𝓟⟧$],
))

#let elet3 = prooftree(rule(
   name: [E-LetDef],
   [#D[#v.e] $▹$ #v.e#v.prime],
   [#c.fresh #v.m],
   [#D[`let` #v.x `=` #v.e #c.semi $𝓟$] $ ▹$ `let` #v.x #c.t #v.m #c.semi #v.x `=` #v.e#v.prime $⟦𝓟⟧$],
))

#let elam = prooftree(rule(
   name: [E-Lam1],
   [#D[#v.e] $▹$ #v.e#v.prime],
   [#c.fresh #v.m],
   [#D[#v.x `=>` #v.e] $ ▹$ `(`#v.x #c.t #v.m `)` `=>` #v.e#v.prime],
))

#figure(caption: [Elaboration Rules])[
   #align(center, rule-set(
      elet,
      elet2,
      elet3,
      elam,
      // oec,
      // abstraction,
   ))
]<elaboration-rules>

The primary function of elaboration is to translate the input syntax (#ref(<input-syntax>)) to the core syntax. It does this by creating metavariables.
Unlike Lean 4, Teaspoon's elaboration is not type directed so the elaboration rules can be presented separately from the type inference.
#ref(<elaboration-rules>)
includes some of the more interesting elaboration rules.



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

#let cconst = `const`
#let ceq = `=`
#let lam = `=>`;

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

#let abstraction = prooftree(rule(
  name: [Abstraction],
  $Gamma, x: A tack P : B$,
  $Gamma tack lambda x . P : A => B$,
))

#figure(caption: [Big Step Operational Semantics])[
   #align(center, rule-set(
      oassign,
      ocall,
      abstraction,
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




== The difficulties of mutable variables

With mutable variables something something something.

Have to forget proofs about what they are, and widen to what they can be.

With constants, all new information you learn stays with you.

There's something similar about how you can't "keep" information between function calls.

== Querying for Type

= Future Work


#bibliography("bibliography.bib")

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
