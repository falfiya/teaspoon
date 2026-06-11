const five: 5 = 5 - 1;
// Works because 5 extends number
const x: Type = five;

const y: 1 | string = "foo"
const z: 1 | string = 1;

const id = infer (T: Type) => (x: T): T => x;
// We would expect this to work transparently
const id5: 5 -> 5 = id;
