; RUN: llc -mtriple=v850-unknown-elf -mcpu=g4mh -O2 < %s | FileCheck %s
; RUN: llc -mtriple=v850-unknown-elf -mcpu=g4mh2 -O2 < %s | FileCheck %s

; Test that post-increment/decrement load/store instructions are generated
; for RH850G4MH+ when a pointer is incremented/decremented by the access size.

;===----------------------------------------------------------------------===;
; Post-increment loads
;===----------------------------------------------------------------------===;

; CHECK-LABEL: load_byte_postinc:
; CHECK: ld.b [r{{[0-9]+}}]+, r{{[0-9]+}}
define i32 @load_byte_postinc(ptr %p, ptr %out) {
  %val = load i8, ptr %p, align 1
  %ext = sext i8 %val to i32
  %next = getelementptr inbounds i8, ptr %p, i32 1
  store ptr %next, ptr %out, align 4
  ret i32 %ext
}

; CHECK-LABEL: load_byte_postdec:
; CHECK: ld.b [r{{[0-9]+}}]-, r{{[0-9]+}}
define i32 @load_byte_postdec(ptr %p, ptr %out) {
  %val = load i8, ptr %p, align 1
  %ext = sext i8 %val to i32
  %next = getelementptr inbounds i8, ptr %p, i32 -1
  store ptr %next, ptr %out, align 4
  ret i32 %ext
}

; CHECK-LABEL: load_ubyte_postinc:
; CHECK: ld.bu [r{{[0-9]+}}]+, r{{[0-9]+}}
define i32 @load_ubyte_postinc(ptr %p, ptr %out) {
  %val = load i8, ptr %p, align 1
  %ext = zext i8 %val to i32
  %next = getelementptr inbounds i8, ptr %p, i32 1
  store ptr %next, ptr %out, align 4
  ret i32 %ext
}

; CHECK-LABEL: load_half_postinc:
; CHECK: ld.h [r{{[0-9]+}}]+, r{{[0-9]+}}
define i32 @load_half_postinc(ptr %p, ptr %out) {
  %val = load i16, ptr %p, align 2
  %ext = sext i16 %val to i32
  %next = getelementptr inbounds i16, ptr %p, i32 1
  store ptr %next, ptr %out, align 4
  ret i32 %ext
}

; CHECK-LABEL: load_uhalf_postinc:
; CHECK: ld.hu [r{{[0-9]+}}]+, r{{[0-9]+}}
define i32 @load_uhalf_postinc(ptr %p, ptr %out) {
  %val = load i16, ptr %p, align 2
  %ext = zext i16 %val to i32
  %next = getelementptr inbounds i16, ptr %p, i32 1
  store ptr %next, ptr %out, align 4
  ret i32 %ext
}

; CHECK-LABEL: load_word_postinc:
; CHECK: ld.w [r{{[0-9]+}}]+, r{{[0-9]+}}
define i32 @load_word_postinc(ptr %p, ptr %out) {
  %val = load i32, ptr %p, align 4
  %next = getelementptr inbounds i32, ptr %p, i32 1
  store ptr %next, ptr %out, align 4
  ret i32 %val
}

; CHECK-LABEL: load_word_postdec:
; CHECK: ld.w [r{{[0-9]+}}]-, r{{[0-9]+}}
define i32 @load_word_postdec(ptr %p, ptr %out) {
  %val = load i32, ptr %p, align 4
  %next = getelementptr inbounds i32, ptr %p, i32 -1
  store ptr %next, ptr %out, align 4
  ret i32 %val
}

;===----------------------------------------------------------------------===;
; Post-increment stores
;===----------------------------------------------------------------------===;

; CHECK-LABEL: store_byte_postinc:
; CHECK: st.b r{{[0-9]+}}, [r{{[0-9]+}}]+
define ptr @store_byte_postinc(ptr %p, i8 %val) {
  store i8 %val, ptr %p, align 1
  %next = getelementptr inbounds i8, ptr %p, i32 1
  ret ptr %next
}

; CHECK-LABEL: store_half_postinc:
; CHECK: st.h r{{[0-9]+}}, [r{{[0-9]+}}]+
define ptr @store_half_postinc(ptr %p, i16 %val) {
  store i16 %val, ptr %p, align 2
  %next = getelementptr inbounds i16, ptr %p, i32 1
  ret ptr %next
}

; CHECK-LABEL: store_word_postinc:
; CHECK: st.w r{{[0-9]+}}, [r{{[0-9]+}}]+
define ptr @store_word_postinc(ptr %p, i32 %val) {
  store i32 %val, ptr %p, align 4
  %next = getelementptr inbounds i32, ptr %p, i32 1
  ret ptr %next
}

; CHECK-LABEL: store_word_postdec:
; CHECK: st.w r{{[0-9]+}}, [r{{[0-9]+}}]-
define ptr @store_word_postdec(ptr %p, i32 %val) {
  store i32 %val, ptr %p, align 4
  %next = getelementptr inbounds i32, ptr %p, i32 -1
  ret ptr %next
}

;===----------------------------------------------------------------------===;
; Loop pattern - the most common use case
;===----------------------------------------------------------------------===;

; CHECK-LABEL: memcpy_bytes:
; CHECK: ld.b{{u?}} [r{{[0-9]+}}]+, r{{[0-9]+}}
; CHECK: st.b r{{[0-9]+}}, [r{{[0-9]+}}]+
define void @memcpy_bytes(ptr %dst, ptr %src, i32 %n) {
entry:
  %cmp = icmp sgt i32 %n, 0
  br i1 %cmp, label %loop, label %exit

loop:
  %i = phi i32 [ 0, %entry ], [ %inc, %loop ]
  %s = phi ptr [ %src, %entry ], [ %snext, %loop ]
  %d = phi ptr [ %dst, %entry ], [ %dnext, %loop ]
  %val = load i8, ptr %s, align 1
  store i8 %val, ptr %d, align 1
  %snext = getelementptr inbounds i8, ptr %s, i32 1
  %dnext = getelementptr inbounds i8, ptr %d, i32 1
  %inc = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inc, %n
  br i1 %done, label %exit, label %loop

exit:
  ret void
}
