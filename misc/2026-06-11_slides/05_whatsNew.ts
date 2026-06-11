const x = 5;

// New Proposition Type!
const hx: x @== 5 = with() rfl;

// Subtype, Refinement Type, or Liquid Type
type int = Liquid (n: number), Number.isInteger(n) @== true;

export {}
