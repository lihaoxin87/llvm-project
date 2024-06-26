; RUN: llc -mcpu=mvp -filetype=obj -o %t.o %s
; RUN: llc -mcpu=mvp -filetype=obj %S/Inputs/global-ctor-dtor.ll -o %t.global-ctor-dtor.o

target triple = "wasm32-unknown-unknown"

define hidden void @func1() {
entry:
  ret void
}

define hidden void @func2() {
entry:
  ret void
}

define hidden void @func3() {
entry:
  ret void
}

define hidden void @func4() {
entry:
  ret void
}

declare hidden void @externCtor()
declare hidden void @externDtor()
declare hidden void @__wasm_call_ctors()
declare i32 @__cxa_atexit(i32 %func, i32 %arg, i32 %dso_handle)

define hidden void @_start() {
entry:
  call void @__wasm_call_ctors();
  ret void
}

@llvm.global_ctors = appending global [4 x { i32, ptr, ptr }] [
  { i32, ptr, ptr } { i32 1001, ptr @func1, ptr null },
  { i32, ptr, ptr } { i32 101, ptr @func1, ptr null },
  { i32, ptr, ptr } { i32 101, ptr @func2, ptr null },
  { i32, ptr, ptr } { i32 4000, ptr @externCtor, ptr null }
]

@llvm.global_dtors = appending global [4 x { i32, ptr, ptr }] [
  { i32, ptr, ptr } { i32 1001, ptr @func3, ptr null },
  { i32, ptr, ptr } { i32 101, ptr @func3, ptr null },
  { i32, ptr, ptr } { i32 101, ptr @func4, ptr null },
  { i32, ptr, ptr } { i32 4000, ptr @externDtor, ptr null }
]

; RUN: wasm-ld --allow-undefined %t.o %t.global-ctor-dtor.o -o %t.wasm
; RUN: obj2yaml %t.wasm | FileCheck %s

; CHECK:        - Type:            IMPORT
; CHECK-NEXT:     Imports:
; CHECK-NEXT:       - Module:          env
; CHECK-NEXT:         Field:           __cxa_atexit
; CHECK-NEXT:         Kind:            FUNCTION
; CHECK-NEXT:         SigIndex:        0
; CHECK-NEXT:       - Module:          env
; CHECK-NEXT:         Field:           externDtor
; CHECK-NEXT:         Kind:            FUNCTION
; CHECK-NEXT:         SigIndex:        1
; CHECK-NEXT:       - Module:          env
; CHECK-NEXT:         Field:           externCtor
; CHECK-NEXT:         Kind:            FUNCTION
; CHECK-NEXT:         SigIndex:        1
; CHECK:        - Type:            ELEM
; CHECK-NEXT:     Segments:
; CHECK-NEXT:       - Offset:
; CHECK-NEXT:           Opcode:          I32_CONST
; CHECK-NEXT:           Value:           1
; CHECK-NEXT:         Functions:       [ 9, 11, 13, 17, 19, 21 ]
; CHECK-NEXT:   - Type:            CODE
; CHECK-NEXT:     Functions:
; CHECK-NEXT:       - Index:           3
; CHECK-NEXT:         Locals:
; CHECK-NEXT:         Body:            10041005100A100F1012100F10141004100C100F10161002100E0B
; CHECK:            - Index:           22
; CHECK-NEXT:         Locals:
; CHECK-NEXT:         Body:            02404186808080004100418088808000108080808000450D00000B0B
; CHECK-NEXT:   - Type:            CUSTOM
; CHECK-NEXT:     Name:            name
; CHECK-NEXT:     FunctionNames:
; CHECK-NEXT:       - Index:           0
; CHECK-NEXT:         Name:            __cxa_atexit
; CHECK-NEXT:       - Index:           1
; CHECK-NEXT:         Name:            externDtor
; CHECK-NEXT:       - Index:           2
; CHECK-NEXT:         Name:            externCtor
; CHECK-NEXT:       - Index:           3
; CHECK-NEXT:         Name:            __wasm_call_ctors
; CHECK-NEXT:       - Index:           4
; CHECK-NEXT:         Name:            func1
; CHECK-NEXT:       - Index:           5
; CHECK-NEXT:         Name:            func2
; CHECK-NEXT:       - Index:           6
; CHECK-NEXT:         Name:            func3
; CHECK-NEXT:       - Index:           7
; CHECK-NEXT:         Name:            func4
; CHECK-NEXT:       - Index:           8
; CHECK-NEXT:         Name:            _start
; CHECK-NEXT:       - Index:           9
; CHECK-NEXT:         Name:            .Lcall_dtors.101
; CHECK-NEXT:       - Index:           10
; CHECK-NEXT:         Name:            .Lregister_call_dtors.101
; CHECK-NEXT:       - Index:           11
; CHECK-NEXT:         Name:            .Lcall_dtors.1001
; CHECK-NEXT:       - Index:           12
; CHECK-NEXT:         Name:            .Lregister_call_dtors.1001
; CHECK-NEXT:       - Index:           13
; CHECK-NEXT:         Name:            .Lcall_dtors.4000
; CHECK-NEXT:       - Index:           14
; CHECK-NEXT:         Name:            .Lregister_call_dtors.4000
; CHECK-NEXT:       - Index:           15
; CHECK-NEXT:         Name:            myctor
; CHECK-NEXT:       - Index:           16
; CHECK-NEXT:         Name:            mydtor
; CHECK-NEXT:       - Index:           17
; CHECK-NEXT:         Name:            .Lcall_dtors.101
; CHECK-NEXT:       - Index:           18
; CHECK-NEXT:         Name:            .Lregister_call_dtors.101
; CHECK-NEXT:       - Index:           19
; CHECK-NEXT:         Name:            .Lcall_dtors.202
; CHECK-NEXT:       - Index:           20
; CHECK-NEXT:         Name:            .Lregister_call_dtors.202
; CHECK-NEXT:       - Index:           21
; CHECK-NEXT:         Name:            .Lcall_dtors.2002
; CHECK-NEXT:       - Index:           22
; CHECK-NEXT:         Name:            .Lregister_call_dtors.2002
; CHECK-NEXT:     GlobalNames:
; CHECK-NEXT:       - Index:           0
; CHECK-NEXT:         Name:            __stack_pointer
; CHECK-NEXT: ...

; RUN: wasm-ld -r %t.o %t.global-ctor-dtor.o -o %t.reloc.wasm
; RUN: llvm-readobj --symbols --sections %t.reloc.wasm | FileCheck -check-prefix=RELOC %s

; RELOC:       Name: linking
; RELOC-NEXT:  InitFunctions [
; RELOC-NEXT:    0 (priority=101)
; RELOC-NEXT:    1 (priority=101)
; RELOC-NEXT:    15 (priority=101)
; RELOC-NEXT:    11 (priority=101)
; RELOC-NEXT:    21 (priority=101)
; RELOC-NEXT:    11 (priority=202)
; RELOC-NEXT:    23 (priority=202)
; RELOC-NEXT:    0 (priority=1001)
; RELOC-NEXT:    17 (priority=1001)
; RELOC-NEXT:    11 (priority=2002)
; RELOC-NEXT:    25 (priority=2002)
; RELOC-NEXT:    9 (priority=4000)
; RELOC-NEXT:    19 (priority=4000)
; RELOC-NEXT:  ]
