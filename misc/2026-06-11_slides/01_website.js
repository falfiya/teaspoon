const btn = document.getElementById("btn");
let counter = 0;
btn.onclick = () => {
   counter = counter + 1;
   btn.innerText = counter;
};
