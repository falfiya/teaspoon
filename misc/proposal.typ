#set page(margin: (left: 6%, right: 6%, top: 2%))

#align(right)[
  #text(gray)[
    CSE 290Q, Spring 2026 \
    #datetime.today().display()
  ]
]

#align(center)[
  = *Teaspoon*: A theorem prover for TypeScript
  Nicola Gannon
]

== Background

Web technologies have become increasingly contagious. Serious applications have moved online; why write the same business logic for three different platforms? Node.js and Electron have allowed web technologies to break containment from the browser and incubate in host operating systems.

// Something stupid about how the web is a virus

 technologies are even being used offline. VSCode, which this document is being written in, is one such example.

JavaScript, the language of the web, is a dynamically typed language; variable types are not tracked when the program is being written. It is therefore the programmer's responsibility to ensure that she provides the correct datatypes to the code that she uses. It seems obvious enough, but code made by third parties is often opaque. In absence of complete, detailed documentation, third party code becomes a mess of trial and error. Proponents of dynamic typing extoll the flexibility of such code. If we're so strict about our input, we may be cutting off _"useful"_ possibilities we never imagined. If it looks like a duck, quacks like a duck, why not treat it as a duck, even if it's a dog?

Static typing constrains the program execution space and generally makes it easier for the programmer to reason about her code. It accomplishes this by making explicit the types of all variables and values. All manner of type errors or type confusion (such as accidental coercions to strings) is effectively eradicated by static typing. TypeScript extends JavaScript to provide this capability and everything is great.

That being said, it lacks many features of the more academic functional programming side of things. Let's see if we can extend the types to their logical extreme and embed an entire goddamn theorem prover inside typescript!

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

Teaspoon will extend a subset of TypeScript and make propositions first class, adding Liquid Types /* also known as subtypes in lean */ by accident.

=== Syntax Extensions

JavaScript's notion of equality makes things complicated.

```js
[] === [] // false
```

Therefore I will be adding a new `@=` definitional equality operator. There will be no such operator emitted in JavaScript, and it's purely for structural equality whatever that means.

JavaScript has a `with` keyword which is largely unused, so that will become the tactic mode.

Function type syntax is somewhat cumbersome in typescript.

```ts
type fn = (_: number) => number;
```

I will add a new type constructor;

```ts
type fn = number -> number;
```

Additionally, all declarations will be extended:

Types will be made first-class citizens within a typing universe.

```ts
const x<a> = e
const x = (infer a: Type) => e
```

To have tactics, lean's `by` will be `with`.

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
