#import "para-lipics/lib.typ": *

#show: para-lipics.with(
  title: [Teaspoon: Liquid Types and More for TypeScript],
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
    )
  ),
  hide-lipics: true,
  hide-doi: true,
  ccs-desc: "Theory of computation → Logic → Type Theory; Theory of computation → Semantics and reasoning → Program semantics → Operational semantics",
  keywords: "Liquid Types, Dependent Types, Interactive Theorem Proving",
  category: "Workshop Report",
  funding: "This material was supported by the juice purchased from the Baskin Engineering Perk on 2026-06-11",
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

== Core Syntax



== Operational Semantics

#import "@preview/simplebnf:0.2.0": *

== Elaboration


== Elaboration

For simplicity the elaboration rules will be presented separate from the type inference rules.
In the implementation, elaboration and type inference are the same module.
Unlike Lean 4, Teaspoon's elaboration is not type directed.
The primary function of elaboration is to fill in implicit type arguments with metavariables.

#import "@preview/curryst:0.6.0": rule, prooftree, rule-set

#let var = $x$

#show math.equation: set text(fill: black, weight: "regular")

#let cconst = `const`
#let ceq = `=`
#let lam = `=>`;

#let mvar = [$?$ #h(-1pt) $m$]
#let ascribe = [#h(-2pt) `:` #h(2pt)]

#prooftree(rule(
  name: [E-Const],
  $Γ ⊢ e ▹ e'$,
  $"fresh " #mvar$,
  $Γ ⊢ (#cconst x #ceq e) ▹ (#cconst x#ascribe #mvar #ceq e')$,
))

#prooftree(rule(
  name: [E-Const],
  $Γ ⊢ e ▹ e'$,
  $"fresh " #mvar$,
  $Γ ⊢ (#cconst x #ceq e) ▹ (#cconst x#ascribe #mvar #ceq e')$,
))

#prooftree(rule(
  name: [E-Lam],
  [$Γ ⊢ e ▹ e',C$],
  [$"fresh " #mvar$],
  [$Γ ⊢ (x #lam e) ▹ ((x#ascribe #mvar)#lam e')$],
))




== The difficulties of mutable variables

With mutable variables something something something.

Have to forget proofs about what they are, and widen to what they can be.

With constants, all new information you learn stays with you.

There's something similar about how you can't "keep" information between function calls.

== Querying for Type


#bibliography("bibliography.bib")

= Appendix

#pagebreak()

== Input Language


#let b(content, color) = [
   #show math.equation: set text(fill: color, weight: "bold")
   #eval(content, mode: "math")
   #show math.equation: set text(fill: black, weight: "regular")
]

#let v = (
   x: b("x", blue),
   τ: b("τ", blue),
   star: b("*", purple),
)

#table(
  columns: (auto, auto),
  stroke: none,
  inset: (left: 5pt),

  bnf(
    Prod(
      $v$,
      delim: $→$,
      {
        Or[#v.x][ident]
        Or[#v.x #ascribe #v.τ][type ascripted ident]
        Or[`_ :` $τ$][ignored]
      }
    ),

    Prod(
      $p$,
      delim: $→$,
      {
        Or[$x$][single parameter]
        Or[`(`$v$`,`$*$`)`][]
      }
    ),

    Prod(
      $s$,
      delim: $→$,
      {
        Or[`let` $v$][undefined]
        Or[`let` $v$ `=` $e$][var]
        Or[`const` $v$ `=` $e$][constant]
        Or[`if (` $e$ `) {` $s$`;`$*$ `}`][if]
        Or[
            `if (` $e$ `) {` $s$`;`$*$ `}`\
            `else    `#h(1.2pt)`{` $s$`;`$*$ `}`][if else]
        Or[`loop {` $s$`;`$*$ `}`][]
        Or[`break`][break innermost loop]
        Or[`return`][]
        Or[`#check` e][check type]
        Or[`#eval`][application]
      },
    ),

    Prod(
      $e$,
      delim: $→$,
      {
        Or[`b`][boolean]
        Or[`n`][number]
        Or[`s`][string]
        Or[`undefined`][]
        Or[`sorry`][]
        Or[$x$][ident]
        Or[`infer`$?$ $p$` => `$l$][lambda]
        Or[`[` $e$`;`$*$ `]`][array]
        Or[`!`$e$][logical not]
        Or[$e$`(` $e$`,`$*$ `)` $T?$][function call]
        Or[`@`$e$][unimplicit]
        Or[`(`$e$`)`][sub-expression]
        Or[$T$][tactics]
      }
    ),
  ),
  bnf(
    Prod(
      $v_τ$,
      delim: $→$,
      {
        Or[$τ$][]
        Or[$x$ `:` $τ$][dependent]
      }
    ),

    Prod(
      $p_τ$,
      delim: $→$,
      {
        Or[$τ$][]
        Or[`(`$v_τ$`,`$*$`)`][]
      }
    ),

    Prod(
      $v_l$,
      delim: $→$,
      {
        Or[$x$][]
        Or[`(`$x$ `:` $τ$`)`][]
      }
    ),

    Prod(
      $τ$,
      delim: $→$,
      {
        Or[`Sort` $n$][sort]
        Or[`Type` $n$][type]
        Or[`Type`][type 0]
        Or[`Prop`][type of propositions]
        Or[$φ$][proposition]
        Or[$x$][type ident]
        Or[$e$][singleton type]
        Or[`typeof` $e$][]
        Or[`infer`$?$ $p_τ$ `-> `$τ$][π-type]
        Or[$τ$`[]`][array type]
        Or[`[`$v_τ$`;`$*$`]`][named tuple]
        Or[`Liquid` $v_l$`, `$φ$][liquid type]
      },
    ),

    Prod(
      $φ$,
      delim: $→$,
      {
        Or[`True`][]
        Or[`False`][]
        Or[$e₁$` @== `$e₂$][equality]
        Or[$e₁$` | `$e₂$][or]
        Or[$e₁$` & `$e₂$][and]
        Or[`infer`$?$ $p_τ$ `->` $φ$][forall]
        Or[$τ₁$` extends `$τ₂$][subtype relation]
      },
    ),

    Prod(
      $T$,
      delim: $→$,
      {
        Or[`with` $t$`;`$*$][tactics]
      }
    ),

    Prod(
      $"t"$,
      delim: $→$,
      {
        Or[$x$ $e *$][tactic]
      }
    )
  )
)


#prooftree(rule(
  label: [Label],
  name: [Rule name],
  [Premise 1],
  [Premise 2],
  [Premise 3],
  [Conclusion],
))
