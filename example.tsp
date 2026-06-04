let a;

if (Math.random() > 0.5) {
   a = 12;
} else {
   a = "something else"
}

1 + "a" as string;

declare function takesFive(x: 5);
const id5 = a => {takesFive(a); return a};
