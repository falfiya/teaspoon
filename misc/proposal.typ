#set page(margin: (left: 6%, right: 6%, top: 2%))
#show raw: set text(font: "Operator Mono Lig")

#align(right)[
  #text(gray)[
    CSE 290Q, Spring 2026 \
    #datetime.today().display()
  ]
]

#align(center)[
  = *Teaspoon*: A Theorem Prover for TypeScript
  Nicola Gannon
]

== Background

Web technologies have become increasingly contagious. Serious applications have moved online; why write the same UI code for three different platforms when the web works as a common target? Node.js, JavaScript for the server, and Electron, a browser-application bundle, have allowed JavaScript to colonize host operating systems. It's here to stay.

JavaScript isn't without issues though, and its existence spawned many an internet flamewar regarding the quality of the language. One such hotly debated subject is its dynamically typed nature.
In dynamically typed languages, types are not tracked when the program is being written. It is therefore the programmer's responsibility to ensure that she provides correctly typed data to code she uses. It seems obvious enough, but code from third parties is often opaque. In absence of complete, detailed documentation, proper usage often feels like type "whack-a-mole".
// Proponents of dynamic typing extoll its flexibility. If we're strict about input, we may cut off _"useful"_ possibilities we never imagined. If it looks like a duck, quacks like a duck, why not treat it as a duck?

Static typing addresses this issue. Types constrain the program execution space and generally makes it easier for the programmer to reason about her code. It accomplishes this by making explicit the types of all variables and values. All manner of type errors or type confusion, such as accidental coercions to strings or NaN poisoning, is effectively eradicated by static typing. To bring these benefits to the web, TypeScript enhanced JavaScript with gradual, static typing.

// TypeScript has pretty good types, but it really just needs more types. It lacks higher kinded types, liquid types, and all sorts of other fun goodies.

TypeScript is able to accommodate the dynamic nature of JavaScript well, but basic notions such as "this number is even" are not easily expressible. Teaspoon will do what TypeScript did to JavaScript, and extend a subset of TypeScript with proof terms and an interactive theorem prover. There is prior art. Liquid Types for Haskell #cite(<liquid>) add a predicate to types #footnote[Liquid Types are more commonly known as refinement types. In Lean, we call this Subtype.] and, somewhat amusingly, PeanoScript #cite(<peanoscript>) is _also_ a theorem prover for TypeScript. Though PeanoScript is a great start, it lacks a formal type theory and a tactic language.

== Language Support

Within the features I decide to support, I aim to be a mostly-compatible semi-strict superset of TypeScript. I have personally experienced some type unsoundness using the compiler. I intend to have strong foundations but still remain faithful to the spirit of TypeScript.

#let inset = (top: 0em, left: 0em, right: 1em, bottom: 0em)

#table(columns: (auto, auto), stroke: none, inset: inset)[
  === JavaScript
  #table(columns: (auto, auto), stroke: none, inset: inset)[
    - Primitive Values
      - `undefined`
      - `boolean`
      - `number`
      - `string`
  ][
    - Non-primitive Values
      - Arrays
      - Functions
        - Arrow Functions
      - Error Handling
  ]
][
  === TypeScript
  #table(columns: (auto, auto, auto), stroke: none, inset: inset)[
    - Basic Types
      - `never`
      - `undefined`
      - `boolean`
      - `number`
      - `string`
      - `unknown`
  ][
    - Less Basic Types
      - Arrays
      - Functions
      - Intersections
      - Unions
      - Literal Types
  ][
    - Advanced Features
      - Conditional Types
        - `infer T`
      - Type Inference
      - Subtyping
      - Type Assertions
      - Type Guards
  ]
]

=== Syntax Extensions

#table(columns: (40%, auto, auto), stroke: none, inset: inset)[
  #table(columns: (auto, auto), stroke: none, inset: 0pt)[
    - Propositional Equality
    - Structural Equality
    - Tactic mode
  ][
    #hide(" ") `  a @== b : Prop`\
    #hide(" ") `  [] @= []`\
    #hide(" ") `  with`
  ]
][
  A new type constructor for anonymous functions

  ```ts
  let fn = number => number;
  ```
][
  Infer arguments
  ```ts
  let add = (infer T: Type) =>
    (a: T, b: T) => a + b;
  ```
]

#set page(margin: (left: 6%, right: 6%, top: 6%))

== Out-of-scope

To keep the scope of this project managable, I have some extra constraints:


#table(columns: (auto, auto, auto, auto), stroke: none, inset: (left: 1em, top: 0em, bottom: 0em))[
  - *No mutability*
  - No objects
  - No record types
  - No classes
][
  - No methods
  - No side effects
  - No code generation
  - No template string types
][
  Function syntax is not allowed. Use `let` instead.
  #linebreak()
  #linebreak()
  ```ts
  function not_allowed() {}
  ```
][
  Generic syntax is not allowed. Use `infer T` instead.
  ```ts
  function no_fun<T>() {}
  ```
]

There is a little complexity in namespaces in TypeScript. The following is acceptable:
```ts
type hello = "Hello!";
const hello = "Goodbye!";
```

The type `hello` and value `hello` live in two different worlds. To simplify matters, there will only be _one namespace_ in Teaspoon. Additionally, there will be no `type` keyword.

== Type Model

I will be #strike([stealing]) borrowing Lean4's model of types and therefore also the Calculus of Constructions #cite(<cock>).

== Considerations

TypeScript has proper subtyping and value types. This causes strange rules like the following to exist.

#import "@preview/curryst:0.6.0": rule, prooftree, rule-set

#align(center, prooftree(rule(
  name: [],
  [Γ ⊢ τ : Type],
  [Γ ⊢ x : τ],
  [Γ ⊢ x : x],
)))

I imagine this will get hairy fast.


I intend to implement this using the Rust Language. This may prove to be a mistake as I am a novice. I'm worried that due to my relative inexperience, I may get hung up on design decisions that don't ultimately matter. I hope to learn to overcome this.

/*
There may be finicky things to deal with there. Additionally typescript's type system more or less functions as an untyped lambda calculus where.

TypeScript effectively has two languages:

JavaScript, which is an imperative (or object oriented depending on who you ask) programming language for doing real stuff. The Type system, which is a gradually typed lambda calculus.

```ts
type id<a> = a
```

It's notable that there are no higher kinded types.

```ts
type foo<a extends type<_>> = a<int>
```

== Validating a Natural Number

#table(columns: (auto, auto), stroke: none, inset: 1em)[
  ```ts


  function assertNat(n: number) {
    if (!Number.isInteger(n) || n < 0)
      throw new Error
  }
  ```
][
  ```ts
  const isNat: number -> boolean =
    n => Number.isInteger(n) && n > 0
  function assertNat(n: number): isNat(n) @= true {
    if (isNat(n))
      throw new Error
  }
  ```
]

We'd like to return a proof that for all subsequent `JSON.parse(s)`, there won't be an error.
Now I don't really want to write a whole program logic to properly verify this. We're just trying to extend typescript types to be a little more useful.

Prop can actually be thought as something like this:
```ts
declare const hp: unique symbol;
type p = typeof hp;
```

It's worth mentioning that you can do weird things with typescript:

```ts
type bar<a> = a extends number ? a : 0;
```

```ts
const id<α>: (a: α) => a === a = with
  intro
  rfl
```

TypeScript has value types.




Since we have no focus on actually emitting proof objects, these should only be used as needed.

If we remember lexie lambda's 

== Type Model

Lean's type theory except that all 


*/

#pagebreak()


== Responsible Language Model Usage

I don't intend to use AI for writing any of this, and that includes this very document. As such, the writing might be a bit choppy. My preferred usage of AI is for a search engine when I feel something might take more clicking around then I'd like. Claude Sonnet 4.6 many questions about the vscode extension context should I have enough time to make an extension. I don't expect to be using any editor-integrated language models or Claude Code, but perhaps the amount of work might compel me to start taking shortcuts. If such a tragedy occurs, I will report it.

#bibliography("hayagriva.yml", full: true)

#image("reddit_comment.svg")
