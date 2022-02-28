(module
  (global $pages (import "env" "pages") i32)
  (global $alignment (import "env" "alignment") i32)
  (import "env" "heap" (memory 1))
  (import "env" "log" (func $log (param i32) (param i32)))
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
    (local $loc i32)                       ;; current memory location (4 bytes)
    (local $i i32)                         ;; current iteration ( loc + i )
    (local $requested_segments i32)         ;; bytes / alignment (i32 - 4 bytes)
    (local $sum_segmentbytes i32)          ;; sum of bytes in the iteration segment

    local.get $size_bytes                  ;; calculate the number of segments
    global.get $alignment
    i32.div_s
    local.set $requested_segments

    i32.const 0
    local.get $requested_segments
    call $log

    (loop $segment_loop
      i32.const 1
      local.get $loc
      call $log

      local.get $loc                        ;; load the 4 byte header from the memory location
      i32.load

      i32.eqz                               ;; if the memory location is 0
      if
        i32.const 0                         ;; reset sum of segment bytes
        local.set $sum_segmentbytes

        local.get $i              ;; i++
        i32.const 1
        i32.add
        local.set $i

        (loop $segment_bytes_loop           ;; loop through the bytes in this segment
          local.get $loc                    ;; get the next byte
          local.get $i
          i32.add
          local.tee $i

          i32.load                          ;; add the segment byte to the total sum
          local.get $sum_segmentbytes
          i32.add
          local.set $sum_segmentbytes

          local.get $i                      ;; i++
          i32.const 1
          i32.add
          local.set $i

          local.get $i                      ;; if i < requested_segments
          local.get $requested_segments
          i32.lt_s
          br_if $segment_bytes_loop         ;; jmp to $segment_bytes_loop  
        )

        local.get $sum_segmentbytes         ;; if sum_segmentbytes > 0
        i32.const 0
        i32.gt_s
        if
          local.get $size_bytes             ;; add the requested bytes to the location
          local.get $loc
          i32.add
          local.set $loc

          br $segment_loop                  ;; jmp to $segment_loop
        end
      else                                  ;; if the memory location is not 0
        local.get $loc                      ;; load the 4-byte header
        i32.load

        local.get $loc                      ;; add header bytes to loc
        i32.add
        local.set $loc

        br $segment_loop                    ;; jmp back to $segment_loop
      end
    )

    i32.const 1
    local.get $loc
    call $log

    local.get $loc
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
