const fs = require('fs');
const bytes = fs.readFileSync(__dirname + '/memory.wasm');
const pages = 1;
let memory = new WebAssembly.Memory({ initial: pages });

let imports = {
  env: {
    heap: memory,
    pages: pages,
    alignment: 4
  }
};

(async () => {
  let module = await WebAssembly.instantiate(new Uint8Array(bytes), imports);
  const { malloc, free, find_loc } = module.instance.exports;

  const heap_bytes = new Uint8Array(memory.buffer);
  console.log(heap_bytes);

  malloc(13);

  heap_bytes[0] = 8; // header - 8 bytes
  //heap_bytes[8] = 4; // header - 4 bytes
  console.log(heap_bytes);

  
  console.log(find_loc(3));
})();
