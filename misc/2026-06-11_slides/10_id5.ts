declare const takesFive: 5 -> void;
const id5 = x => { takesFive(x); return x}

const id5 = (x: ?T) => { takesFive(x); return x}

const id5 = infer (T: Liquid (t: Type), t extends 5) =>
   (x: T): T => { takesFive(x); return x}
