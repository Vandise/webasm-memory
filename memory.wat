(module
  (global $pages (import "env" "pages") i32)
  (global $alignment (import "env" "alignment") i32)
  (import "env" "heap" (memory 1))
  (import "env" "log" (func $log (param i32)))
  (global $mem_header i32 (i32.const 4))

  (func $align_malloc (param $size_bytes i32) (result i32)
    local.get $size_bytes
    f32.convert_i32_u
    global.get $alignment
    f32.convert_i32_u
    f32.div
    f32.ceil
    i32.trunc_f32_u
    global.get $alignment
    i32.mul
  )

  (func $find_loc (export "find_loc") (param $size_bytes i32) (result i32)
    (local $loc i32)              ;; current memory location (4 bytes)
    (local $i i32)                ;; current iteration
    (local $segments i32)         ;; bytes / alignment (i32 - 4 bytes)
    (local $segmentbytes i32)     ;; sum of bytes in the iteration segment

    local.get $size_bytes         ;; calculate the number of iterations
    global.get $alignment
    i32.div_s
    local.set $segments

    ;; todo: track pages and max memory buffer
    (loop $position_loop          ;; cycle through memory
      local.get $loc
      global.get $alignment
      i32.mul
      local.tee $loc
      i32.load                    ;; push the value at the current memory position
      i32.eqz                     ;; if the value equals zero
      if
        i32.const 0
        local.set $segmentbytes   ;; reset $segmentbytes

        local.get $i            ;; we'll always have req+padding + header
        i32.const 1
        i32.add
        local.set $i            ;; i++

        (loop $bytes_loop
          local.get $i
          i32.load                ;; get the next memory segment
          local.get $segmentbytes
          i32.add
          local.set $segmentbytes ;; add to current segment count

          local.get $i            ;; i++
          i32.const 1
          i32.add
          local.set $i
  
          local.get $i
          local.get $segments
          i32.le_s
          br_if $bytes_loop      ;; jmp $bytes_loop if i <= segments
        )

        local.get $segmentbytes
        i32.const 0
        i32.gt_s                 ;; if segmentbytes > 0
        if
          local.get $segments    ;; add segments to loc
          local.get $loc
          i32.add
          local.set $loc
        end
      else
        local.get $loc
        i32.load                  ;; pull the bytes from the header
        global.get $alignment
        i32.div_s                 ;; calculate segments
        local.get $loc            ;; add segments to loc
        i32.add
        local.set $loc
        br $position_loop         ;; jmp to $position_loop
      end
    )

    global.get $alignment
    local.get  $loc
    i32.mul
  )

  (func (export "malloc") (param $size_bytes i32) (result i32)
    (local $total_bytes i32)
    (local $ptr i32)
    global.get $mem_header
    local.get $size_bytes
    i32.add                 ;; size_bytes + 4
    call $align_malloc      ;; align base2 size_bytes + 4

    local.tee $total_bytes  ;; $total_bytes = aligned bytes
    call $find_loc
    local.tee $ptr

    local.get $total_bytes
    i32.store

    local.get $ptr
  )

  (func (export "free")
    nop
  )
)
