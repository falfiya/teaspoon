# Teaspoon, Proof terms for TypeScript

## Abstract

Static type systems for programming languages provide stronger guarantees of program correctness. Through analysis at compile time, static type systems typically eliminate all runtime type errors and enforce proper usage of APIs. The programmer can even lean on the type system to help her reason about the nature of her data. The benefits of static typing are best showcased in web development. Webpages are programmed in JavaScript, a dynamically typed programming language. But most(1) web developers use TypeScript, a statically typed extension to JavaScript. TypeScript is a compiler-as-specification, which works remarkably well in practice, but a robust theory would prevent soundness bugs. Teaspoon aims to do what TypeScript did for JavaScript. It extends a subset of TypeScript, formally backing it with the usual operational semantics, type inference, and constraint solving. Teaspoon's type system is unusual in its support for mutability and imperative programming. The addition of first-class propositions and liquid types effectively create a dependently typed TypeScript.

## Prior Art

https://peanoscript.mjgrzymek.com/tutorial

## Example

```ts
let nat =
   | 0
   | [nat];

let p: Prop = 0 @== 0;
let 
```

Γ ⊢ f : t₁ → t₂, C        Γ ⊢ x : unknown, _
--------------------------------------------- app
          Γ ⊢ f(x), C ∪ {x : t₁}

