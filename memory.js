const fs = require('fs');
const bytes = fs.readFileSync(__dirname + '/memory.wasm');
const pages = 1;
let memory = new WebAssembly.Memory({ initial: pages });

function log(type, value) {
  switch(type) {
    case 0:
      console.log("Requested segments:", value);
      break;
    case 1:
      console.log("$loc:", value);
      break;
    default:
      break;
  }
}

let imports = {
  env: {
    heap: memory,
    pages: pages,
    alignment: 4,
    log
  }
};

(async () => {
  let module = await WebAssembly.instantiate(new Uint8Array(bytes), imports);
  const { malloc, free, find_loc } = module.instance.exports;

  const heap_bytes = new Uint8Array(memory.buffer);

  console.log("=== malloc 4 ===");
  malloc(4);
  console.log("=== malloc 4 ===");
  malloc(4);
  console.log("=== malloc 8 ===");
  malloc(8);
  console.log("=== malloc 4 ===");
  malloc(4);
  console.log(heap_bytes);
})();
