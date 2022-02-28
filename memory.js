const fs = require('fs');
const bytes = fs.readFileSync(__dirname + '/memory.wasm');
const pages = 1;
let memory = new WebAssembly.Memory({ initial: pages });

function log(value) {
  console.log(value);
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

  const heap_bytes = new Uint32Array(memory.buffer);

  //heap_bytes[0] = 8; // header - 8 total bytes
  malloc(4);
  malloc(4);
  console.log(heap_bytes);
})();
