== Abstract

Static type systems for programming languages provide stronger guarantees of program correctness. Through analysis at compile time, static type systems typically eliminate all runtime type errors and enforce proper usage of APIs. The programmer can even lean on the type system to help her reason about the nature of her data. The benefits of static typing are best showcased in web development. Webpages are programmed in JavaScript, a dynamically typed programming language. But most(1) web developers use TypeScript, a statically typed extension to JavaScript. TypeScript is a compiler-as-specification, which works remarkably well in practice, but a robust theory would prevent soundness bugs. Teaspoon aims to do what TypeScript did for JavaScript. It extends a subset of TypeScript, formally backing it with the usual operational semantics, type inference, and constraint solving. Teaspoon's type system is unusual in its support for mutability and imperative programming. The addition of first-class propositions and liquid types effectively create a dependently typed TypeScript.

(1) https://2025.stateofjs.com/en-US/usage/#js_ts_balance

== Syntax

#import "@preview/simplebnf:0.2.0": *
#show math.equation: set text(fill: blue, weight: "bold")

#table(
  columns: (auto, auto),
  stroke: none,
  inset: (left: 5pt),

  bnf(
    Prod(
      $v$,
      delim: $→$,
      {
        Or[$x$][ident]
        Or[$x$ `:` $τ$][type ascripted ident]
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

== Operational Semantics

#import "@preview/curryst:0.6.0": rule, prooftree, rule-set

#prooftree(rule(
  label: [Label],
  name: [Rule name],
  [Premise 1],
  [Premise 2],
  [Premise 3],
  [Conclusion],
))

== The difficulties of mutable variables

With mutable variables something something something.

Have to forget proofs about what they are, and widen to what they can be.

With constants, all new information you learn stays with you.

There's something similar about how you can't "keep" information between function calls.

== Querying for Type


