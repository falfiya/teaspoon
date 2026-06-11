#set page(width: 100cm, height: 100cm)
#set page(fill: rgb("#f8efe7"))
#set text(size: 120pt)


$Γ = x₁:τ₁...$

$Γ = φ₁...$


$x₁:$` number`

`typeof` $x₁$ `extends number`

#pagebreak()

#import "@preview/simplebnf:0.2.0": *

#bnf(
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
)
