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
            `else    {` $s$`;`$*$ `}`][if else]
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
      $V$,
      delim: $→$,
      {
        Or[$τ$][]
        Or[$x$ `:` $τ$][dependent]
      }
    ),

    Prod(
      $P$,
      delim: $→$,
      {
        Or[$τ$][]
        Or[`(`$V$`,`$*$`)`][]
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
        Or[$e$][singleton type]
        Or[`typeof` $e$][]
        Or[`infer`$?$ $P$ `-> `$τ$][π-type]
        Or[$τ$`[]`][array type]
        Or[`[`$V$`;`$*$`]`][named tuple]
      },
    ),

    Prod(
      $φ$,
      delim: $→$,
      {
        Or[`True`][]
        Or[`False`][]
        Or[`e₁ @== e₂`][equality]
        Or[`infer`$?$ $P$ `->` $φ$][forall]
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
