# Teaspoon, Proof terms for TypeScript

Goal: compile to typescript.

Lift more complicated typescript things into teaspoon.

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
