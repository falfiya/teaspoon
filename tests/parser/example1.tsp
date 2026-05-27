let x = 1;
let y = 2;

declare function log<T extends number>(x: T, y: T): never;

let onlyTake5 = (x: 5, y: number) => log(x, y);

let onlyTake5Elab = (x: 5, y: string) => log(y, x);

// subtype <: supertype
// subtype extends supertype
// 5 extends number
5 satisfies number;
5 satisfies 1;

// ?T extends number
// string extends ?T
// 5 extends ?T
// string extends number

declare const string_v: string;
// string_v satisfies number;

type isNumber<a> = a extends number ? true : false;

let five: unknown = 5;
let six: unknown = 6;

type concern = (_: unknown) => boolean;

parseInput(x => x === "hello!")

function parseInput(x: unknown, Hx0: x extends never -> unknown ? x extends number -> unknown : nothing) {
   if (typeof x === "function") {
      // Hx1 : x extends never -> unknown
      x(unsafe("hello!"))
   }
}

// Check if it's a function

type q = concern extends unknown ? true : false;

// five == six?

let id = <T>(a: T) => a;


type Nat = 0 | [Nat];

function add(a: Nat, b: Nat): Nat {
   
}

/*
step 1, both types are elaborated
  id : infer (T: Type) -> T -> T
  1  : number

step 2, instantiateMVars
  id : ?t -> ?t
  1  : number

step 3, check for argument equality
  is number <: ?t
*/

#eval x + y;

#example : 1 = 1 = with rfl;
