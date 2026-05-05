#set page(margin: (left: 6%, right: 6%, top: 2%))

#align(right)[
  #text(gray)[
    CSE 290Q, Spring 2026 \
    #datetime.today().display()
  ]
]

#align(center)[
  = *Teaspoon*: A theorem prover embedded in typescript
  Nicola Gannon
]

== Background

Web interactivity is getting harder and now it's being used everywhere. Even in vscode there is web technologies, and along with it, JavaScript. Dealing with dynamic typing is kind of a bitch, so they made TypeScript which is a superset of JavaScript with static types. Over time, it has become more complicated and you can do increasingly complex things with it. That being said, it lacks many features of the more academic functional programming side of things. Let's see if we can extend the types to their logical extreme and embed an entire goddamn theorem prover inside typescript!

There is history of extending a type system. Liquid types for haskell add a predicate to types https://goto.ucsd.edu/~rjhala/liquid/liquid_types.pdf, and are essentially just refinement types. My very own idea actually has a previous implementation called PeanoScript. This implementation doesn't have a formal type theory and is just based off of vibes and first order logic. So that's a great starting point, I intend to take a lot of pointers on syntax design and proof terms from PeanoScript.

Providing some formal grounding with the calculus of constructions would be awesome. 

- My specific idea
  - A superset of typescript with proofs
  - https://peanoscript.mjgrzymek.com/tutorial
    - Analysis of [PeanoScript](https://www.reddit.com/r/ProgrammingLanguages/comments/1jfxjn3/i_made_peanoscript_a_typescriptlike_theorem_prover/)

- The foundations I will rely on
  - Adhere to typescript syntax
  - Calculus of Inductive Constructions

// What ideas am I borrowing from

== Overview

- Parse a typescript-like language
  - Support most types of typescript subtyping
- Add tactic syntax
- Implement a Rocq-like viewer of context

What is novel? TypeScript has proper subtyping and it also has value types. There may be finicky things to deal with there. Additionally typescript's type system more or less functions as an untyped lambda calculus where.

TypeScript effectively has two languages:

JavaScript, which is an imperative (or object oriented depending on who you ask) programming language for doing real stuff. The Type system, which is a gradually typed lambda calculus.

```ts
type id<a> = a
```

It's notable that there are no higher kinded types.

```ts
type foo<a extends type<_>> = a<int>
```

#pagebreak()

== Validating a JSON String

#table(columns: (auto, auto), stroke: none, inset: 1em)[
  ```ts

  function assertEven(n: number) {
    if (n % 2 === 1)
      throw new Error()
  }
  ```
][
  ```ts
  declare const even<α extends number>: α → boolean;
  function assertEven(n: number): even<n> {
    if (n % 2 === 1)
      throw new Error()
    else
      sorry
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

#import "@preview/curryst:0.6.0": rule, prooftree, rule-set

#let tree = rule(
  name: [Value Types],
  [Γ ⊢ τ₁ : Type],
  [Γ ⊢ τ₂ : τ₁],
  [Γ ⊢ x : τ₂],
  [Γ ⊢ x : τ₁],
)

#prooftree(tree)

Since we have no focus on actually emitting proof objects, these should only be used as needed.

If we remember lexie lambda's 

== Language Support

Within the features I decide to support, I aim to be a mostly-compatible semi-strict superset of TypeScript.

#let inset = (top: 0em, left: 0em, right: 1em)

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

== Out-of-scope

To keep the scope of this project managable, I have some extra constraints:


#table(columns: (auto, auto), stroke: none, inset: (left: 1em, top: 0em, bottom: 0em))[
  - *No mutability*
  - No objects
  - No record types
][
  - No methods
  - No side effects
  - No code generation
]

I have personally experienced some type unsoundness using the compiler. I intend to have strong foundations and remain faithful to the spirit of TypeScript rather than what's actually going on.

== Considerations

Subtyping might be kinda hairy. I am also not really looking forward to using Rust for this but I will. Something that I know about myself is that I'll get stuck trying to decide the two different types of syntax.

Because TypeScript has a meta language and an object language, trying to pick syntax will be fun but it might also occupy a lot of time that it shouldn't.

```ts
type id<a> = a;
function 
```

== Responsible Language Model Usage

I don't intend to use AI for writing any of this, and that includes this very document. As such, the writing might be a bit choppy.

My preferred usage of AI is for a search engine, though, when I feel something might take a few clicks. PeanoScript I did find on my own though.

I also expect to ask Claude Sonnet 4.6 many questions about the vscode extension context, and it can be helpful for me to see example code.

I don't expect to be using any editor-integrated language models, but perhaps the amount of work might compel me to start taking shortcuts. Ideally, I'd like to
