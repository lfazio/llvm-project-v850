	.file	"fxu_vector.c"
	.text
	.globl	vec_add                         ; -- Begin function vec_add
	.p2align	2
	.type	vec_add,@function
vec_add:                                ; @vec_add
; %bb.0:                                ; %entry
	cmp	1, r9
	blt	.LBB0_8
; %bb.1:                                ; %for.body.preheader
	andi	3, r9, r10
	cmp	4, r9
	bnc	.LBB0_3
; %bb.2:
	mov	0, r11
	jr	.LBB0_5
.LBB0_3:                                ; %for.body.preheader.new
	mov	2147483644, r11
	mov	r8, r12
	mov	r7, r13
	mov	r6, r14
	and	r11, r9
	add	8, r12
	add	8, r13
	add	8, r14
	mov	0, r11
	add	-4, r9
	shr	2, r9
	add	1, r9
.LBB0_4:                                ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-8[r12], r15
	ld.w	-8[r13], r16
	add	4, r11
	addf.s	r15, r16, r15
	ld.w	-4[r13], r16
	st.w	r15, -8[r14]
	ld.w	-4[r12], r15
	addf.s	r15, r16, r15
	ld.w	0[r13], r16
	st.w	r15, -4[r14]
	ld.w	0[r12], r15
	addf.s	r15, r16, r15
	ld.w	4[r13], r16
	addi	16, r13, r13
	st.w	r15, 0[r14]
	ld.w	4[r12], r15
	addi	16, r12, r12
	addf.s	r15, r16, r15
	st.w	r15, 4[r14]
	addi	16, r14, r14
	loop r9, .LBB0_4
.LBB0_5:                                ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r10
	bz	.LBB0_8
; %bb.6:                                ; %for.body.epil.preheader
	shl	2, r11
	add	r11, r7
	add	r11, r8
	add	r11, r6
.LBB0_7:                                ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r8], r11
	ld.w	0[r7], r12
	add	4, r7
	add	4, r8
	addf.s	r11, r12, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r10, .LBB0_7
.LBB0_8:                                ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end0:
	.size	vec_add, .Lfunc_end0-vec_add
                                        ; -- End function
	.globl	vec_sub                         ; -- Begin function vec_sub
	.p2align	2
	.type	vec_sub,@function
vec_sub:                                ; @vec_sub
; %bb.0:                                ; %entry
	cmp	1, r9
	blt	.LBB1_8
; %bb.1:                                ; %for.body.preheader
	andi	3, r9, r10
	cmp	4, r9
	bnc	.LBB1_3
; %bb.2:
	mov	0, r11
	jr	.LBB1_5
.LBB1_3:                                ; %for.body.preheader.new
	mov	2147483644, r11
	mov	r8, r12
	mov	r7, r13
	mov	r6, r14
	and	r11, r9
	add	8, r12
	add	8, r13
	add	8, r14
	mov	0, r11
	add	-4, r9
	shr	2, r9
	add	1, r9
.LBB1_4:                                ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-8[r12], r15
	ld.w	-8[r13], r16
	add	4, r11
	subf.s	r15, r16, r15
	ld.w	-4[r13], r16
	st.w	r15, -8[r14]
	ld.w	-4[r12], r15
	subf.s	r15, r16, r15
	ld.w	0[r13], r16
	st.w	r15, -4[r14]
	ld.w	0[r12], r15
	subf.s	r15, r16, r15
	ld.w	4[r13], r16
	addi	16, r13, r13
	st.w	r15, 0[r14]
	ld.w	4[r12], r15
	addi	16, r12, r12
	subf.s	r15, r16, r15
	st.w	r15, 4[r14]
	addi	16, r14, r14
	loop r9, .LBB1_4
.LBB1_5:                                ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r10
	bz	.LBB1_8
; %bb.6:                                ; %for.body.epil.preheader
	shl	2, r11
	add	r11, r7
	add	r11, r8
	add	r11, r6
.LBB1_7:                                ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r8], r11
	ld.w	0[r7], r12
	add	4, r7
	add	4, r8
	subf.s	r11, r12, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r10, .LBB1_7
.LBB1_8:                                ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end1:
	.size	vec_sub, .Lfunc_end1-vec_sub
                                        ; -- End function
	.globl	vec_mul                         ; -- Begin function vec_mul
	.p2align	2
	.type	vec_mul,@function
vec_mul:                                ; @vec_mul
; %bb.0:                                ; %entry
	cmp	1, r9
	blt	.LBB2_8
; %bb.1:                                ; %for.body.preheader
	andi	3, r9, r10
	cmp	4, r9
	bnc	.LBB2_3
; %bb.2:
	mov	0, r11
	jr	.LBB2_5
.LBB2_3:                                ; %for.body.preheader.new
	mov	2147483644, r11
	mov	r8, r12
	mov	r7, r13
	mov	r6, r14
	and	r11, r9
	add	8, r12
	add	8, r13
	add	8, r14
	mov	0, r11
	add	-4, r9
	shr	2, r9
	add	1, r9
.LBB2_4:                                ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-8[r12], r15
	ld.w	-8[r13], r16
	add	4, r11
	mulf.s	r15, r16, r15
	ld.w	-4[r13], r16
	st.w	r15, -8[r14]
	ld.w	-4[r12], r15
	mulf.s	r15, r16, r15
	ld.w	0[r13], r16
	st.w	r15, -4[r14]
	ld.w	0[r12], r15
	mulf.s	r15, r16, r15
	ld.w	4[r13], r16
	addi	16, r13, r13
	st.w	r15, 0[r14]
	ld.w	4[r12], r15
	addi	16, r12, r12
	mulf.s	r15, r16, r15
	st.w	r15, 4[r14]
	addi	16, r14, r14
	loop r9, .LBB2_4
.LBB2_5:                                ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r10
	bz	.LBB2_8
; %bb.6:                                ; %for.body.epil.preheader
	shl	2, r11
	add	r11, r7
	add	r11, r8
	add	r11, r6
.LBB2_7:                                ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r8], r11
	ld.w	0[r7], r12
	add	4, r7
	add	4, r8
	mulf.s	r11, r12, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r10, .LBB2_7
.LBB2_8:                                ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end2:
	.size	vec_mul, .Lfunc_end2-vec_mul
                                        ; -- End function
	.globl	vec_div                         ; -- Begin function vec_div
	.p2align	2
	.type	vec_div,@function
vec_div:                                ; @vec_div
; %bb.0:                                ; %entry
	cmp	1, r9
	blt	.LBB3_8
; %bb.1:                                ; %for.body.preheader
	andi	3, r9, r10
	cmp	4, r9
	bnc	.LBB3_3
; %bb.2:
	mov	0, r11
	jr	.LBB3_5
.LBB3_3:                                ; %for.body.preheader.new
	mov	2147483644, r11
	mov	r8, r12
	mov	r7, r13
	mov	r6, r14
	and	r11, r9
	add	8, r12
	add	8, r13
	add	8, r14
	mov	0, r11
	add	-4, r9
	shr	2, r9
	add	1, r9
.LBB3_4:                                ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-8[r12], r15
	ld.w	-8[r13], r16
	add	4, r11
	divf.s	r15, r16, r15
	ld.w	-4[r13], r16
	st.w	r15, -8[r14]
	ld.w	-4[r12], r15
	divf.s	r15, r16, r15
	ld.w	0[r13], r16
	st.w	r15, -4[r14]
	ld.w	0[r12], r15
	divf.s	r15, r16, r15
	ld.w	4[r13], r16
	addi	16, r13, r13
	st.w	r15, 0[r14]
	ld.w	4[r12], r15
	addi	16, r12, r12
	divf.s	r15, r16, r15
	st.w	r15, 4[r14]
	addi	16, r14, r14
	loop r9, .LBB3_4
.LBB3_5:                                ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r10
	bz	.LBB3_8
; %bb.6:                                ; %for.body.epil.preheader
	shl	2, r11
	add	r11, r7
	add	r11, r8
	add	r11, r6
.LBB3_7:                                ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r8], r11
	ld.w	0[r7], r12
	add	4, r7
	add	4, r8
	divf.s	r11, r12, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r10, .LBB3_7
.LBB3_8:                                ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end3:
	.size	vec_div, .Lfunc_end3-vec_div
                                        ; -- End function
	.globl	vec_abs                         ; -- Begin function vec_abs
	.p2align	2
	.type	vec_abs,@function
vec_abs:                                ; @vec_abs
; %bb.0:                                ; %entry
	cmp	1, r8
	blt	.LBB4_8
; %bb.1:                                ; %for.body.preheader
	andi	3, r8, r10
	cmp	4, r8
	bnc	.LBB4_3
; %bb.2:
	mov	0, r11
	jr	.LBB4_5
.LBB4_3:                                ; %for.body.preheader.new
	mov	2147483644, r11
	mov	r6, r12
	mov	r7, r13
	and	r11, r8
	add	8, r12
	add	8, r13
	mov	0, r11
	add	-4, r8
	shr	2, r8
	add	1, r8
.LBB4_4:                                ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-8[r13], r14
	add	4, r11
	negf.s	r14, r15
	cmpf.s	4, r0, r14, 0
	cmovf.s	0, r15, r14, r14
	st.w	r14, -8[r12]
	ld.w	-4[r13], r14
	negf.s	r14, r15
	cmpf.s	4, r0, r14, 0
	cmovf.s	0, r15, r14, r14
	st.w	r14, -4[r12]
	ld.w	0[r13], r14
	negf.s	r14, r15
	cmpf.s	4, r0, r14, 0
	cmovf.s	0, r15, r14, r14
	st.w	r14, 0[r12]
	ld.w	4[r13], r14
	addi	16, r13, r13
	negf.s	r14, r15
	cmpf.s	4, r0, r14, 0
	cmovf.s	0, r15, r14, r14
	st.w	r14, 4[r12]
	addi	16, r12, r12
	loop r8, .LBB4_4
.LBB4_5:                                ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r10
	bz	.LBB4_8
; %bb.6:                                ; %for.body.epil.preheader
	shl	2, r11
	add	r11, r7
	add	r11, r6
.LBB4_7:                                ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r7], r11
	add	4, r7
	negf.s	r11, r12
	cmpf.s	4, r0, r11, 0
	cmovf.s	0, r12, r11, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r10, .LBB4_7
.LBB4_8:                                ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end4:
	.size	vec_abs, .Lfunc_end4-vec_abs
                                        ; -- End function
	.globl	vec_neg                         ; -- Begin function vec_neg
	.p2align	2
	.type	vec_neg,@function
vec_neg:                                ; @vec_neg
; %bb.0:                                ; %entry
	cmp	1, r8
	blt	.LBB5_8
; %bb.1:                                ; %for.body.preheader
	andi	3, r8, r10
	cmp	4, r8
	bnc	.LBB5_3
; %bb.2:
	mov	0, r11
	jr	.LBB5_5
.LBB5_3:                                ; %for.body.preheader.new
	mov	2147483644, r11
	mov	r6, r12
	mov	r7, r13
	and	r11, r8
	add	8, r12
	add	8, r13
	mov	0, r11
	add	-4, r8
	shr	2, r8
	add	1, r8
.LBB5_4:                                ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-8[r13], r14
	add	4, r11
	negf.s	r14, r14
	st.w	r14, -8[r12]
	ld.w	-4[r13], r14
	negf.s	r14, r14
	st.w	r14, -4[r12]
	ld.w	0[r13], r14
	negf.s	r14, r14
	st.w	r14, 0[r12]
	ld.w	4[r13], r14
	addi	16, r13, r13
	negf.s	r14, r14
	st.w	r14, 4[r12]
	addi	16, r12, r12
	loop r8, .LBB5_4
.LBB5_5:                                ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r10
	bz	.LBB5_8
; %bb.6:                                ; %for.body.epil.preheader
	shl	2, r11
	add	r11, r7
	add	r11, r6
.LBB5_7:                                ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r7], r11
	add	4, r7
	negf.s	r11, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r10, .LBB5_7
.LBB5_8:                                ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end5:
	.size	vec_neg, .Lfunc_end5-vec_neg
                                        ; -- End function
	.globl	vec_recip                       ; -- Begin function vec_recip
	.p2align	2
	.type	vec_recip,@function
vec_recip:                              ; @vec_recip
; %bb.0:                                ; %entry
	cmp	1, r8
	blt	.LBB6_8
; %bb.1:                                ; %for.body.preheader
	andi	3, r8, r10
	cmp	4, r8
	bnc	.LBB6_3
; %bb.2:
	mov	0, r11
	jr	.LBB6_5
.LBB6_3:                                ; %for.body.preheader.new
	mov	2147483644, r11
	mov	r6, r12
	mov	r7, r13
	and	r11, r8
	add	8, r12
	add	8, r13
	mov	0, r11
	add	-4, r8
	shr	2, r8
	add	1, r8
.LBB6_4:                                ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-8[r13], r14
	add	4, r11
	recipf.s	r14, r14
	st.w	r14, -8[r12]
	ld.w	-4[r13], r14
	recipf.s	r14, r14
	st.w	r14, -4[r12]
	ld.w	0[r13], r14
	recipf.s	r14, r14
	st.w	r14, 0[r12]
	ld.w	4[r13], r14
	addi	16, r13, r13
	recipf.s	r14, r14
	st.w	r14, 4[r12]
	addi	16, r12, r12
	loop r8, .LBB6_4
.LBB6_5:                                ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r10
	bz	.LBB6_8
; %bb.6:                                ; %for.body.epil.preheader
	shl	2, r11
	add	r11, r7
	add	r11, r6
.LBB6_7:                                ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r7], r11
	add	4, r7
	recipf.s	r11, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r10, .LBB6_7
.LBB6_8:                                ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end6:
	.size	vec_recip, .Lfunc_end6-vec_recip
                                        ; -- End function
	.globl	vec_fma                         ; -- Begin function vec_fma
	.p2align	2
	.type	vec_fma,@function
vec_fma:                                ; @vec_fma
; %bb.0:                                ; %entry
	addi	0, r3, r10
	ld.w	0[r10], r11
	cmp	1, r11
	blt	.LBB7_8
; %bb.1:                                ; %for.body.preheader
	andi	3, r11, r10
	cmp	4, r11
	bnc	.LBB7_3
; %bb.2:
	mov	0, r12
	jr	.LBB7_5
.LBB7_3:                                ; %for.body.preheader.new
	mov	2147483644, r12
	mov	r8, r13
	mov	r7, r14
	mov	r6, r15
	mov	r9, r16
	and	r12, r11
	add	8, r13
	add	8, r14
	add	8, r15
	add	8, r16
	mov	0, r12
	add	-4, r11
	shr	2, r11
	add	1, r11
.LBB7_4:                                ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-8[r16], r17
	ld.w	-8[r14], r18
	ld.w	-8[r13], r19
	add	4, r12
	maddf.s	r18, r19, r17, r17
	ld.w	-4[r14], r18
	ld.w	-4[r13], r19
	st.w	r17, -8[r15]
	ld.w	-4[r16], r17
	maddf.s	r18, r19, r17, r17
	ld.w	0[r14], r18
	ld.w	0[r13], r19
	st.w	r17, -4[r15]
	ld.w	0[r16], r17
	maddf.s	r18, r19, r17, r17
	ld.w	4[r14], r18
	ld.w	4[r13], r19
	addi	16, r13, r13
	addi	16, r14, r14
	st.w	r17, 0[r15]
	ld.w	4[r16], r17
	addi	16, r16, r16
	maddf.s	r18, r19, r17, r17
	st.w	r17, 4[r15]
	addi	16, r15, r15
	loop r11, .LBB7_4
.LBB7_5:                                ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r10
	bz	.LBB7_8
; %bb.6:                                ; %for.body.epil.preheader
	shl	2, r12
	add	r12, r7
	add	r12, r8
	add	r12, r9
	add	r12, r6
.LBB7_7:                                ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r9], r11
	ld.w	0[r7], r12
	ld.w	0[r8], r13
	add	4, r7
	add	4, r8
	add	4, r9
	maddf.s	r12, r13, r11, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r10, .LBB7_7
.LBB7_8:                                ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end7:
	.size	vec_fma, .Lfunc_end7-vec_fma
                                        ; -- End function
	.globl	vec_fms                         ; -- Begin function vec_fms
	.p2align	2
	.type	vec_fms,@function
vec_fms:                                ; @vec_fms
; %bb.0:                                ; %entry
	addi	0, r3, r10
	ld.w	0[r10], r11
	cmp	1, r11
	blt	.LBB8_8
; %bb.1:                                ; %for.body.preheader
	andi	3, r11, r10
	cmp	4, r11
	bnc	.LBB8_3
; %bb.2:
	mov	0, r12
	jr	.LBB8_5
.LBB8_3:                                ; %for.body.preheader.new
	mov	2147483644, r12
	mov	r8, r13
	mov	r7, r14
	mov	r6, r15
	mov	r9, r16
	and	r12, r11
	add	8, r13
	add	8, r14
	add	8, r15
	add	8, r16
	mov	0, r12
	add	-4, r11
	shr	2, r11
	add	1, r11
.LBB8_4:                                ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-8[r16], r17
	ld.w	-8[r14], r18
	ld.w	-8[r13], r19
	add	4, r12
	msubf.s	r18, r19, r17, r17
	ld.w	-4[r14], r18
	ld.w	-4[r13], r19
	st.w	r17, -8[r15]
	ld.w	-4[r16], r17
	msubf.s	r18, r19, r17, r17
	ld.w	0[r14], r18
	ld.w	0[r13], r19
	st.w	r17, -4[r15]
	ld.w	0[r16], r17
	msubf.s	r18, r19, r17, r17
	ld.w	4[r14], r18
	ld.w	4[r13], r19
	addi	16, r13, r13
	addi	16, r14, r14
	st.w	r17, 0[r15]
	ld.w	4[r16], r17
	addi	16, r16, r16
	msubf.s	r18, r19, r17, r17
	st.w	r17, 4[r15]
	addi	16, r15, r15
	loop r11, .LBB8_4
.LBB8_5:                                ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r10
	bz	.LBB8_8
; %bb.6:                                ; %for.body.epil.preheader
	shl	2, r12
	add	r12, r7
	add	r12, r8
	add	r12, r9
	add	r12, r6
.LBB8_7:                                ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r9], r11
	ld.w	0[r7], r12
	ld.w	0[r8], r13
	add	4, r7
	add	4, r8
	add	4, r9
	msubf.s	r12, r13, r11, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r10, .LBB8_7
.LBB8_8:                                ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end8:
	.size	vec_fms, .Lfunc_end8-vec_fms
                                        ; -- End function
	.globl	vec_nfma                        ; -- Begin function vec_nfma
	.p2align	2
	.type	vec_nfma,@function
vec_nfma:                               ; @vec_nfma
; %bb.0:                                ; %entry
	addi	0, r3, r10
	ld.w	0[r10], r11
	cmp	1, r11
	blt	.LBB9_8
; %bb.1:                                ; %for.body.preheader
	andi	3, r11, r10
	cmp	4, r11
	bnc	.LBB9_3
; %bb.2:
	mov	0, r12
	jr	.LBB9_5
.LBB9_3:                                ; %for.body.preheader.new
	mov	2147483644, r12
	mov	r8, r13
	mov	r7, r14
	mov	r6, r15
	mov	r9, r16
	and	r12, r11
	add	8, r13
	add	8, r14
	add	8, r15
	add	8, r16
	mov	0, r12
	add	-4, r11
	shr	2, r11
	add	1, r11
.LBB9_4:                                ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-8[r14], r19
	ld.w	-8[r16], r17
	ld.w	-8[r13], r18
	add	4, r12
	negf.s	r19, r19
	maddf.s	r19, r18, r17, r17
	ld.w	-4[r14], r19
	ld.w	-4[r13], r18
	negf.s	r19, r19
	st.w	r17, -8[r15]
	ld.w	-4[r16], r17
	maddf.s	r19, r18, r17, r17
	ld.w	0[r14], r19
	ld.w	0[r13], r18
	negf.s	r19, r19
	st.w	r17, -4[r15]
	ld.w	0[r16], r17
	maddf.s	r19, r18, r17, r17
	ld.w	4[r14], r19
	ld.w	4[r13], r18
	addi	16, r13, r13
	addi	16, r14, r14
	negf.s	r19, r19
	st.w	r17, 0[r15]
	ld.w	4[r16], r17
	addi	16, r16, r16
	maddf.s	r19, r18, r17, r17
	st.w	r17, 4[r15]
	addi	16, r15, r15
	loop r11, .LBB9_4
.LBB9_5:                                ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r10
	bz	.LBB9_8
; %bb.6:                                ; %for.body.epil.preheader
	shl	2, r12
	add	r12, r7
	add	r12, r8
	add	r12, r9
	add	r12, r6
.LBB9_7:                                ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r7], r13
	ld.w	0[r9], r11
	ld.w	0[r8], r12
	add	4, r7
	add	4, r8
	add	4, r9
	negf.s	r13, r13
	maddf.s	r13, r12, r11, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r10, .LBB9_7
.LBB9_8:                                ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end9:
	.size	vec_nfma, .Lfunc_end9-vec_nfma
                                        ; -- End function
	.globl	vec_max                         ; -- Begin function vec_max
	.p2align	2
	.type	vec_max,@function
vec_max:                                ; @vec_max
; %bb.0:                                ; %entry
	cmp	1, r9
	blt	.LBB10_8
; %bb.1:                                ; %for.body.preheader
	andi	3, r9, r10
	cmp	4, r9
	bnc	.LBB10_3
; %bb.2:
	mov	0, r11
	jr	.LBB10_5
.LBB10_3:                               ; %for.body.preheader.new
	mov	2147483644, r11
	mov	r8, r12
	mov	r7, r13
	mov	r6, r14
	and	r11, r9
	add	8, r12
	add	8, r13
	add	8, r14
	mov	0, r11
	add	-4, r9
	shr	2, r9
	add	1, r9
.LBB10_4:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-8[r12], r15
	ld.w	-8[r13], r16
	add	4, r11
	cmpf.s	4, r16, r15, 0
	cmovf.s	0, r16, r15, r15
	ld.w	-4[r13], r16
	st.w	r15, -8[r14]
	ld.w	-4[r12], r15
	cmpf.s	4, r16, r15, 0
	cmovf.s	0, r16, r15, r15
	ld.w	0[r13], r16
	st.w	r15, -4[r14]
	ld.w	0[r12], r15
	cmpf.s	4, r16, r15, 0
	cmovf.s	0, r16, r15, r15
	ld.w	4[r13], r16
	addi	16, r13, r13
	st.w	r15, 0[r14]
	ld.w	4[r12], r15
	addi	16, r12, r12
	cmpf.s	4, r16, r15, 0
	cmovf.s	0, r16, r15, r15
	st.w	r15, 4[r14]
	addi	16, r14, r14
	loop r9, .LBB10_4
.LBB10_5:                               ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r10
	bz	.LBB10_8
; %bb.6:                                ; %for.body.epil.preheader
	shl	2, r11
	add	r11, r7
	add	r11, r8
	add	r11, r6
.LBB10_7:                               ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r8], r11
	ld.w	0[r7], r12
	add	4, r7
	add	4, r8
	cmpf.s	4, r12, r11, 0
	cmovf.s	0, r12, r11, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r10, .LBB10_7
.LBB10_8:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end10:
	.size	vec_max, .Lfunc_end10-vec_max
                                        ; -- End function
	.globl	vec_min                         ; -- Begin function vec_min
	.p2align	2
	.type	vec_min,@function
vec_min:                                ; @vec_min
; %bb.0:                                ; %entry
	cmp	1, r9
	blt	.LBB11_8
; %bb.1:                                ; %for.body.preheader
	andi	3, r9, r10
	cmp	4, r9
	bnc	.LBB11_3
; %bb.2:
	mov	0, r11
	jr	.LBB11_5
.LBB11_3:                               ; %for.body.preheader.new
	mov	2147483644, r11
	mov	r8, r12
	mov	r7, r13
	mov	r6, r14
	and	r11, r9
	add	8, r12
	add	8, r13
	add	8, r14
	mov	0, r11
	add	-4, r9
	shr	2, r9
	add	1, r9
.LBB11_4:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-8[r12], r15
	ld.w	-8[r13], r16
	add	4, r11
	cmpf.s	4, r15, r16, 0
	cmovf.s	0, r16, r15, r15
	ld.w	-4[r13], r16
	st.w	r15, -8[r14]
	ld.w	-4[r12], r15
	cmpf.s	4, r15, r16, 0
	cmovf.s	0, r16, r15, r15
	ld.w	0[r13], r16
	st.w	r15, -4[r14]
	ld.w	0[r12], r15
	cmpf.s	4, r15, r16, 0
	cmovf.s	0, r16, r15, r15
	ld.w	4[r13], r16
	addi	16, r13, r13
	st.w	r15, 0[r14]
	ld.w	4[r12], r15
	addi	16, r12, r12
	cmpf.s	4, r15, r16, 0
	cmovf.s	0, r16, r15, r15
	st.w	r15, 4[r14]
	addi	16, r14, r14
	loop r9, .LBB11_4
.LBB11_5:                               ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r10
	bz	.LBB11_8
; %bb.6:                                ; %for.body.epil.preheader
	shl	2, r11
	add	r11, r7
	add	r11, r8
	add	r11, r6
.LBB11_7:                               ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r8], r11
	ld.w	0[r7], r12
	add	4, r7
	add	4, r8
	cmpf.s	4, r11, r12, 0
	cmovf.s	0, r12, r11, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r10, .LBB11_7
.LBB11_8:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end11:
	.size	vec_min, .Lfunc_end11-vec_min
                                        ; -- End function
	.globl	vec_clamp                       ; -- Begin function vec_clamp
	.p2align	2
	.type	vec_clamp,@function
vec_clamp:                              ; @vec_clamp
; %bb.0:                                ; %entry
	addi	0, r3, r10
	ld.w	0[r10], r11
	cmp	1, r11
	blt	.LBB12_8
; %bb.1:                                ; %for.body.preheader
	andi	3, r11, r10
	cmp	4, r11
	bnc	.LBB12_3
; %bb.2:
	mov	0, r12
	jr	.LBB12_5
.LBB12_3:                               ; %for.body.preheader.new
	mov	2147483644, r12
	mov	r6, r13
	mov	r7, r14
	and	r12, r11
	add	8, r13
	add	8, r14
	mov	0, r12
	add	-4, r11
	shr	2, r11
	add	1, r11
.LBB12_4:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-8[r14], r15
	add	4, r12
	cmpf.s	4, r8, r15, 0
	cmovf.s	0, r8, r15, r15
	cmpf.s	4, r15, r9, 0
	cmovf.s	0, r9, r15, r15
	st.w	r15, -8[r13]
	ld.w	-4[r14], r15
	cmpf.s	4, r8, r15, 0
	cmovf.s	0, r8, r15, r15
	cmpf.s	4, r15, r9, 0
	cmovf.s	0, r9, r15, r15
	st.w	r15, -4[r13]
	ld.w	0[r14], r15
	cmpf.s	4, r8, r15, 0
	cmovf.s	0, r8, r15, r15
	cmpf.s	4, r15, r9, 0
	cmovf.s	0, r9, r15, r15
	st.w	r15, 0[r13]
	ld.w	4[r14], r15
	addi	16, r14, r14
	cmpf.s	4, r8, r15, 0
	cmovf.s	0, r8, r15, r15
	cmpf.s	4, r15, r9, 0
	cmovf.s	0, r9, r15, r15
	st.w	r15, 4[r13]
	addi	16, r13, r13
	loop r11, .LBB12_4
.LBB12_5:                               ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r10
	bz	.LBB12_8
; %bb.6:                                ; %for.body.epil.preheader
	shl	2, r12
	add	r12, r7
	add	r12, r6
.LBB12_7:                               ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r7], r11
	add	4, r7
	cmpf.s	4, r8, r11, 0
	cmovf.s	0, r8, r11, r11
	cmpf.s	4, r11, r9, 0
	cmovf.s	0, r9, r11, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r10, .LBB12_7
.LBB12_8:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end12:
	.size	vec_clamp, .Lfunc_end12-vec_clamp
                                        ; -- End function
	.globl	vec_sum                         ; -- Begin function vec_sum
	.p2align	2
	.type	vec_sum,@function
vec_sum:                                ; @vec_sum
; %bb.0:                                ; %entry
	cmp	1, r7
	blt	.LBB13_3
; %bb.1:                                ; %for.body.preheader
	andi	3, r7, r11
	cmp	4, r7
	bnc	.LBB13_4
; %bb.2:
	mov	0, r12
	mov	r0, r10
	jr	.LBB13_6
.LBB13_3:
	mov	r0, r10
	jmp	[r31]
.LBB13_4:                               ; %for.body.preheader.new
	mov	2147483644, r10
	mov	r6, r13
	mov	0, r12
	and	r10, r7
	add	8, r13
	mov	r0, r10
	add	-4, r7
	shr	2, r7
	add	1, r7
.LBB13_5:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-8[r13], r14
	add	-1, r7
	add	4, r12
	addf.s	r14, r10, r10
	ld.w	-4[r13], r14
	addf.s	r14, r10, r10
	ld.w	0[r13], r14
	addf.s	r14, r10, r10
	ld.w	4[r13], r14
	addi	16, r13, r13
	cmp	0, r7
	addf.s	r14, r10, r10
	bnz	.LBB13_5
.LBB13_6:                               ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r11
	bz	.LBB13_9
; %bb.7:                                ; %for.body.epil.preheader
	shl	2, r12
	add	r12, r6
.LBB13_8:                               ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r6], r12
	add	-1, r11
	add	4, r6
	cmp	0, r11
	addf.s	r12, r10, r10
	bnz	.LBB13_8
.LBB13_9:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end13:
	.size	vec_sum, .Lfunc_end13-vec_sum
                                        ; -- End function
	.globl	vec_dot                         ; -- Begin function vec_dot
	.p2align	2
	.type	vec_dot,@function
vec_dot:                                ; @vec_dot
; %bb.0:                                ; %entry
	cmp	1, r8
	blt	.LBB14_3
; %bb.1:                                ; %for.body.preheader
	andi	3, r8, r11
	cmp	4, r8
	bnc	.LBB14_4
; %bb.2:
	mov	0, r12
	mov	r0, r10
	jr	.LBB14_6
.LBB14_3:
	mov	r0, r10
	jmp	[r31]
.LBB14_4:                               ; %for.body.preheader.new
	mov	2147483644, r10
	mov	r7, r13
	mov	r6, r14
	mov	0, r12
	and	r10, r8
	add	8, r13
	add	8, r14
	mov	r0, r10
	add	-4, r8
	shr	2, r8
	add	1, r8
.LBB14_5:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-8[r14], r15
	ld.w	-8[r13], r16
	add	-1, r8
	add	4, r12
	maddf.s	r15, r16, r10, r10
	ld.w	-4[r14], r15
	ld.w	-4[r13], r16
	maddf.s	r15, r16, r10, r10
	ld.w	0[r14], r15
	ld.w	0[r13], r16
	maddf.s	r15, r16, r10, r10
	ld.w	4[r14], r15
	ld.w	4[r13], r16
	addi	16, r13, r13
	addi	16, r14, r14
	cmp	0, r8
	maddf.s	r15, r16, r10, r10
	bnz	.LBB14_5
.LBB14_6:                               ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r11
	bz	.LBB14_9
; %bb.7:                                ; %for.body.epil.preheader
	shl	2, r12
	add	r12, r6
	add	r12, r7
.LBB14_8:                               ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r6], r12
	ld.w	0[r7], r13
	add	-1, r11
	add	4, r6
	add	4, r7
	cmp	0, r11
	maddf.s	r12, r13, r10, r10
	bnz	.LBB14_8
.LBB14_9:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end14:
	.size	vec_dot, .Lfunc_end14-vec_dot
                                        ; -- End function
	.globl	vec_max_reduce                  ; -- Begin function vec_max_reduce
	.p2align	2
	.type	vec_max_reduce,@function
vec_max_reduce:                         ; @vec_max_reduce
; %bb.0:                                ; %entry
	ld.w	0[r6], r10
	cmp	2, r7
	blt	.LBB15_8
; %bb.1:                                ; %for.body.preheader
	mov	r7, r13
	add	-2, r7
	add	-1, r13
	andi	3, r13, r11
	cmp	3, r7
	bnc	.LBB15_3
; %bb.2:
	mov	1, r12
	cmp	0, r11
	bnz	.LBB15_6
	jr	.LBB15_8
.LBB15_3:                               ; %for.body.preheader.new
	mov	-4, r12
	addi	16, r6, r14
	and	r12, r13
	mov	0, r12
	add	-4, r13
	shr	2, r13
	add	1, r13
.LBB15_4:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-12[r14], r15
	add	-1, r13
	add	4, r12
	cmpf.s	4, r15, r10, 0
	cmovf.s	0, r15, r10, r10
	ld.w	-8[r14], r15
	cmpf.s	4, r15, r10, 0
	cmovf.s	0, r15, r10, r10
	ld.w	-4[r14], r15
	cmpf.s	4, r15, r10, 0
	cmovf.s	0, r15, r10, r10
	ld.w	0[r14], r15
	addi	16, r14, r14
	cmp	0, r13
	cmpf.s	4, r15, r10, 0
	cmovf.s	0, r15, r10, r10
	bnz	.LBB15_4
; %bb.5:                                ; %for.cond.cleanup.loopexit.unr-lcssa.loopexit
	add	1, r12
	cmp	0, r11
	bz	.LBB15_8
.LBB15_6:                               ; %for.body.epil.preheader
	shl	2, r12
	add	r12, r6
.LBB15_7:                               ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r6], r12
	add	-1, r11
	add	4, r6
	cmp	0, r11
	cmpf.s	4, r12, r10, 0
	cmovf.s	0, r12, r10, r10
	bnz	.LBB15_7
.LBB15_8:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end15:
	.size	vec_max_reduce, .Lfunc_end15-vec_max_reduce
                                        ; -- End function
	.globl	vec_min_reduce                  ; -- Begin function vec_min_reduce
	.p2align	2
	.type	vec_min_reduce,@function
vec_min_reduce:                         ; @vec_min_reduce
; %bb.0:                                ; %entry
	ld.w	0[r6], r10
	cmp	2, r7
	blt	.LBB16_8
; %bb.1:                                ; %for.body.preheader
	mov	r7, r13
	add	-2, r7
	add	-1, r13
	andi	3, r13, r11
	cmp	3, r7
	bnc	.LBB16_3
; %bb.2:
	mov	1, r12
	cmp	0, r11
	bnz	.LBB16_6
	jr	.LBB16_8
.LBB16_3:                               ; %for.body.preheader.new
	mov	-4, r12
	addi	16, r6, r14
	and	r12, r13
	mov	0, r12
	add	-4, r13
	shr	2, r13
	add	1, r13
.LBB16_4:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-12[r14], r15
	add	-1, r13
	add	4, r12
	cmpf.s	4, r10, r15, 0
	cmovf.s	0, r15, r10, r10
	ld.w	-8[r14], r15
	cmpf.s	4, r10, r15, 0
	cmovf.s	0, r15, r10, r10
	ld.w	-4[r14], r15
	cmpf.s	4, r10, r15, 0
	cmovf.s	0, r15, r10, r10
	ld.w	0[r14], r15
	addi	16, r14, r14
	cmp	0, r13
	cmpf.s	4, r10, r15, 0
	cmovf.s	0, r15, r10, r10
	bnz	.LBB16_4
; %bb.5:                                ; %for.cond.cleanup.loopexit.unr-lcssa.loopexit
	add	1, r12
	cmp	0, r11
	bz	.LBB16_8
.LBB16_6:                               ; %for.body.epil.preheader
	shl	2, r12
	add	r12, r6
.LBB16_7:                               ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r6], r12
	add	-1, r11
	add	4, r6
	cmp	0, r11
	cmpf.s	4, r10, r12, 0
	cmovf.s	0, r12, r10, r10
	bnz	.LBB16_7
.LBB16_8:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end16:
	.size	vec_min_reduce, .Lfunc_end16-vec_min_reduce
                                        ; -- End function
	.globl	vec_itof                        ; -- Begin function vec_itof
	.p2align	2
	.type	vec_itof,@function
vec_itof:                               ; @vec_itof
; %bb.0:                                ; %entry
	cmp	1, r8
	blt	.LBB17_8
; %bb.1:                                ; %for.body.preheader
	andi	3, r8, r10
	cmp	4, r8
	bnc	.LBB17_3
; %bb.2:
	mov	0, r11
	jr	.LBB17_5
.LBB17_3:                               ; %for.body.preheader.new
	mov	2147483644, r11
	mov	r6, r12
	mov	r7, r13
	and	r11, r8
	add	8, r12
	add	8, r13
	mov	0, r11
	add	-4, r8
	shr	2, r8
	add	1, r8
.LBB17_4:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-8[r13], r14
	add	4, r11
	cvtf.ws	r14, r14
	st.w	r14, -8[r12]
	ld.w	-4[r13], r14
	cvtf.ws	r14, r14
	st.w	r14, -4[r12]
	ld.w	0[r13], r14
	cvtf.ws	r14, r14
	st.w	r14, 0[r12]
	ld.w	4[r13], r14
	addi	16, r13, r13
	cvtf.ws	r14, r14
	st.w	r14, 4[r12]
	addi	16, r12, r12
	loop r8, .LBB17_4
.LBB17_5:                               ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r10
	bz	.LBB17_8
; %bb.6:                                ; %for.body.epil.preheader
	shl	2, r11
	add	r11, r7
	add	r11, r6
.LBB17_7:                               ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	[r7]+, r11
	cvtf.ws	r11, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r10, .LBB17_7
.LBB17_8:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end17:
	.size	vec_itof, .Lfunc_end17-vec_itof
                                        ; -- End function
	.globl	vec_ftoi                        ; -- Begin function vec_ftoi
	.p2align	2
	.type	vec_ftoi,@function
vec_ftoi:                               ; @vec_ftoi
; %bb.0:                                ; %entry
	cmp	1, r8
	blt	.LBB18_8
; %bb.1:                                ; %for.body.preheader
	andi	3, r8, r10
	cmp	4, r8
	bnc	.LBB18_3
; %bb.2:
	mov	0, r11
	jr	.LBB18_5
.LBB18_3:                               ; %for.body.preheader.new
	mov	2147483644, r11
	mov	r6, r12
	mov	r7, r13
	and	r11, r8
	add	8, r12
	add	8, r13
	mov	0, r11
	add	-4, r8
	shr	2, r8
	add	1, r8
.LBB18_4:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-8[r13], r14
	add	4, r11
	trncf.sw	r14, r14
	st.w	r14, -8[r12]
	ld.w	-4[r13], r14
	trncf.sw	r14, r14
	st.w	r14, -4[r12]
	ld.w	0[r13], r14
	trncf.sw	r14, r14
	st.w	r14, 0[r12]
	ld.w	4[r13], r14
	addi	16, r13, r13
	trncf.sw	r14, r14
	st.w	r14, 4[r12]
	addi	16, r12, r12
	loop r8, .LBB18_4
.LBB18_5:                               ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r10
	bz	.LBB18_8
; %bb.6:                                ; %for.body.epil.preheader
	shl	2, r11
	add	r11, r7
	add	r11, r6
.LBB18_7:                               ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r7], r11
	add	-1, r10
	add	4, r7
	cmp	0, r10
	trncf.sw	r11, r11
	st.w	r11, [r6]+
	bnz	.LBB18_7
.LBB18_8:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end18:
	.size	vec_ftoi, .Lfunc_end18-vec_ftoi
                                        ; -- End function
	.globl	vec_utof                        ; -- Begin function vec_utof
	.p2align	2
	.type	vec_utof,@function
vec_utof:                               ; @vec_utof
; %bb.0:                                ; %entry
	cmp	1, r8
	blt	.LBB19_8
; %bb.1:                                ; %for.body.preheader
	andi	3, r8, r10
	cmp	4, r8
	bnc	.LBB19_3
; %bb.2:
	mov	0, r11
	jr	.LBB19_5
.LBB19_3:                               ; %for.body.preheader.new
	mov	2147483644, r11
	mov	r6, r12
	mov	r7, r13
	and	r11, r8
	add	8, r12
	add	8, r13
	mov	0, r11
	add	-4, r8
	shr	2, r8
	add	1, r8
.LBB19_4:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-8[r13], r14
	add	4, r11
	cvtf.uws	r14, r14
	st.w	r14, -8[r12]
	ld.w	-4[r13], r14
	cvtf.uws	r14, r14
	st.w	r14, -4[r12]
	ld.w	0[r13], r14
	cvtf.uws	r14, r14
	st.w	r14, 0[r12]
	ld.w	4[r13], r14
	addi	16, r13, r13
	cvtf.uws	r14, r14
	st.w	r14, 4[r12]
	addi	16, r12, r12
	loop r8, .LBB19_4
.LBB19_5:                               ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r10
	bz	.LBB19_8
; %bb.6:                                ; %for.body.epil.preheader
	shl	2, r11
	add	r11, r7
	add	r11, r6
.LBB19_7:                               ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	[r7]+, r11
	cvtf.uws	r11, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r10, .LBB19_7
.LBB19_8:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end19:
	.size	vec_utof, .Lfunc_end19-vec_utof
                                        ; -- End function
	.globl	fir_float                       ; -- Begin function fir_float
	.p2align	2
	.type	fir_float,@function
fir_float:                              ; @fir_float
; %bb.0:                                ; %entry
	cmp	1, r8
	blt	.LBB20_3
; %bb.1:                                ; %for.body.preheader
	andi	3, r8, r11
	cmp	4, r8
	bnc	.LBB20_4
; %bb.2:
	mov	0, r12
	mov	r0, r10
	jr	.LBB20_6
.LBB20_3:
	mov	r0, r10
	jmp	[r31]
.LBB20_4:                               ; %for.body.preheader.new
	mov	2147483644, r10
	mov	r7, r13
	mov	r6, r14
	mov	0, r12
	and	r10, r8
	add	8, r13
	add	8, r14
	mov	r0, r10
	add	-4, r8
	shr	2, r8
	add	1, r8
.LBB20_5:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-8[r14], r15
	ld.w	-8[r13], r16
	add	-1, r8
	add	4, r12
	maddf.s	r15, r16, r10, r10
	ld.w	-4[r14], r15
	ld.w	-4[r13], r16
	maddf.s	r15, r16, r10, r10
	ld.w	0[r14], r15
	ld.w	0[r13], r16
	maddf.s	r15, r16, r10, r10
	ld.w	4[r14], r15
	ld.w	4[r13], r16
	addi	16, r13, r13
	addi	16, r14, r14
	cmp	0, r8
	maddf.s	r15, r16, r10, r10
	bnz	.LBB20_5
.LBB20_6:                               ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r11
	bz	.LBB20_9
; %bb.7:                                ; %for.body.epil.preheader
	shl	2, r12
	add	r12, r6
	add	r12, r7
.LBB20_8:                               ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r6], r12
	ld.w	0[r7], r13
	add	-1, r11
	add	4, r6
	add	4, r7
	cmp	0, r11
	maddf.s	r12, r13, r10, r10
	bnz	.LBB20_8
.LBB20_9:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end20:
	.size	fir_float, .Lfunc_end20-fir_float
                                        ; -- End function
	.globl	fir_block                       ; -- Begin function fir_block
	.p2align	2
	.type	fir_block,@function
fir_block:                              ; @fir_block
; %bb.0:                                ; %entry
	cmp	1, r9
	blt	.LBB21_13
; %bb.1:                                ; %for.cond1.preheader.lr.ph
	prepare	240, 0
	addi	0, r3, r10
	mov	2147483644, r12
	mov	0, r15
	ld.w	0[r10], r10
	mov	r10, r11
	andi	3, r10, r14
	and	r12, r11
	mov	r7, r12
	mov	r8, r13
	mov	r15, r16
	add	-4, r11
	add	8, r12
	add	8, r13
	shr	2, r11
	add	1, r11
	jr	.LBB21_4
.LBB21_2:                               ;   in Loop: Header=BB21_4 Depth=1
	mov	r0, r17
.LBB21_3:                               ; %for.cond.cleanup3
                                        ;   in Loop: Header=BB21_4 Depth=1
	mov	r16, r18
	mov	r6, r19
	add	4, r7
	add	4, r12
	add	1, r16
	shl	2, r18
	add	r18, r19
	cmp	r9, r16
	st.w	r17, 0[r19]
	bz	.LBB21_12
.LBB21_4:                               ; %for.cond1.preheader
                                        ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB21_8 Depth 2
                                        ;     Child Loop BB21_11 Depth 2
	cmp	1, r10
	blt	.LBB21_2
; %bb.5:                                ; %for.body4.lr.ph
                                        ;   in Loop: Header=BB21_4 Depth=1
	cmp	4, r10
	bnc	.LBB21_7
; %bb.6:                                ;   in Loop: Header=BB21_4 Depth=1
	mov	r15, r18
	mov	r0, r17
	jr	.LBB21_9
.LBB21_7:                               ; %for.body4.preheader
                                        ;   in Loop: Header=BB21_4 Depth=1
	mov	r12, r19
	mov	r13, r20
	mov	r15, r18
	mov	r0, r17
	mov	r11, r21
.LBB21_8:                               ; %for.body4
                                        ;   Parent Loop BB21_4 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ld.w	-8[r20], r22
	ld.w	-8[r19], r23
	add	-1, r21
	add	4, r18
	maddf.s	r22, r23, r17, r17
	ld.w	-4[r20], r22
	ld.w	-4[r19], r23
	maddf.s	r22, r23, r17, r17
	ld.w	0[r20], r22
	ld.w	0[r19], r23
	maddf.s	r22, r23, r17, r17
	ld.w	4[r20], r22
	ld.w	4[r19], r23
	addi	16, r19, r19
	addi	16, r20, r20
	cmp	0, r21
	maddf.s	r22, r23, r17, r17
	bnz	.LBB21_8
.LBB21_9:                               ; %for.cond.cleanup3.loopexit.unr-lcssa
                                        ;   in Loop: Header=BB21_4 Depth=1
	cmp	0, r14
	bz	.LBB21_3
; %bb.10:                               ; %for.body4.epil.preheader
                                        ;   in Loop: Header=BB21_4 Depth=1
	mov	r8, r19
	shl	2, r18
	mov	r7, r20
	add	r18, r19
	add	r18, r20
	mov	r14, r18
.LBB21_11:                              ; %for.body4.epil
                                        ;   Parent Loop BB21_4 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ld.w	0[r19], r21
	ld.w	0[r20], r22
	add	-1, r18
	add	4, r19
	add	4, r20
	cmp	0, r18
	maddf.s	r21, r22, r17, r17
	bnz	.LBB21_11
	jr	.LBB21_3
.LBB21_12:
	dispose	0, 240
.LBB21_13:                              ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end21:
	.size	fir_block, .Lfunc_end21-fir_block
                                        ; -- End function
	.globl	iir_biquad_float                ; -- Begin function iir_biquad_float
	.p2align	2
	.type	iir_biquad_float,@function
iir_biquad_float:                       ; @iir_biquad_float
; %bb.0:                                ; %entry
	prepare	2288, 0
	addi	20, r3, r10
	ld.w	0[r10], r16
	cmp	1, r16
	bge	.LBB22_1
	jr	.LBB22_8
.LBB22_1:                               ; %for.body.preheader
	addi	16, r3, r10
	addi	12, r3, r11
	addi	8, r3, r12
	addi	4, r3, r13
	addi	0, r3, r14
	andi	3, r16, r15
	ld.w	0[r10], r10
	ld.w	0[r11], r11
	ld.w	0[r12], r12
	ld.w	0[r13], r13
	ld.w	0[r14], r14
	cmp	4, r16
	ld.w	0[r10], r17
	bnc	.LBB22_3
; %bb.2:
	mov	0, r18
	jr	.LBB22_5
.LBB22_3:                               ; %for.body.preheader.new
	mov	2147483644, r18
	mov	r6, r19
	mov	r7, r20
	and	r18, r16
	add	8, r19
	add	8, r20
	mov	0, r18
	add	-4, r16
	shr	2, r16
	add	1, r16
.LBB22_4:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r11], r21
	ld.w	-8[r20], r22
	add	4, r18
	nmaddf.s	r8, r22, r21, r23
	maddf.s	r8, r22, r21, r21
	mulf.s	r23, r13, r24
	maddf.s	r9, r22, r24, r24
	addf.s	r24, r17, r17
	st.w	r17, 0[r11]
	mulf.s	r23, r12, r17
	maddf.s	r14, r22, r17, r17
	st.w	r17, 0[r10]
	st.w	r21, -8[r19]
	ld.w	0[r11], r21
	ld.w	-4[r20], r22
	nmaddf.s	r8, r22, r21, r23
	maddf.s	r8, r22, r21, r21
	mulf.s	r23, r13, r24
	maddf.s	r9, r22, r24, r24
	addf.s	r24, r17, r17
	st.w	r17, 0[r11]
	mulf.s	r23, r12, r17
	maddf.s	r14, r22, r17, r17
	st.w	r17, 0[r10]
	st.w	r21, -4[r19]
	ld.w	0[r11], r21
	ld.w	0[r20], r22
	nmaddf.s	r8, r22, r21, r23
	maddf.s	r8, r22, r21, r21
	mulf.s	r23, r13, r24
	maddf.s	r9, r22, r24, r24
	addf.s	r24, r17, r17
	st.w	r17, 0[r11]
	mulf.s	r23, r12, r17
	maddf.s	r14, r22, r17, r17
	st.w	r17, 0[r10]
	st.w	r21, 0[r19]
	ld.w	4[r20], r22
	ld.w	0[r11], r21
	addi	16, r20, r20
	nmaddf.s	r8, r22, r21, r23
	maddf.s	r8, r22, r21, r21
	mulf.s	r23, r13, r24
	maddf.s	r9, r22, r24, r24
	addf.s	r24, r17, r17
	st.w	r17, 0[r11]
	mulf.s	r23, r12, r17
	maddf.s	r14, r22, r17, r17
	st.w	r17, 0[r10]
	st.w	r21, 4[r19]
	addi	16, r19, r19
	loop r16, .LBB22_4
.LBB22_5:                               ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r15
	bz	.LBB22_8
; %bb.6:                                ; %for.body.epil.preheader
	shl	2, r18
	add	r18, r7
	add	r18, r6
.LBB22_7:                               ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r7], r18
	ld.w	0[r11], r16
	add	4, r7
	nmaddf.s	r8, r18, r16, r19
	maddf.s	r8, r18, r16, r16
	mulf.s	r19, r13, r20
	maddf.s	r9, r18, r20, r20
	addf.s	r20, r17, r17
	st.w	r17, 0[r11]
	mulf.s	r19, r12, r17
	maddf.s	r14, r18, r17, r17
	st.w	r17, 0[r10]
	st.w	r16, 0[r6]
	add	4, r6
	loop r15, .LBB22_7
.LBB22_8:                               ; %for.cond.cleanup
	dispose	0, 2288, [r31]
.Lfunc_end22:
	.size	iir_biquad_float, .Lfunc_end22-iir_biquad_float
                                        ; -- End function
	.globl	mat4_mul                        ; -- Begin function mat4_mul
	.p2align	2
	.type	mat4_mul,@function
mat4_mul:                               ; @mat4_mul
; %bb.0:                                ; %entry
	addi	28, r6, r10
	addi	28, r7, r11
	mov	0, r12
	mov	2, r13
.LBB23_1:                               ; %for.cond1.preheader
                                        ; =>This Inner Loop Header: Depth=1
	mov	r11, r14
	ld.w	0[r8], r16
	ld.w	16[r8], r17
	add	-1, r13
	add	r12, r14
	ld.w	-28[r14], r15
	maddf.s	r15, r16, r0, r15
	ld.w	-24[r14], r16
	maddf.s	r16, r17, r15, r15
	ld.w	-20[r14], r16
	ld.w	32[r8], r17
	maddf.s	r16, r17, r15, r15
	ld.w	-16[r14], r16
	ld.w	48[r8], r17
	maddf.s	r16, r17, r15, r16
	mov	r10, r15
	add	r12, r15
	addi	32, r12, r12
	cmp	0, r13
	st.w	r16, -28[r15]
	ld.w	-28[r14], r16
	ld.w	4[r8], r17
	ld.w	20[r8], r18
	maddf.s	r16, r17, r0, r16
	ld.w	-24[r14], r17
	maddf.s	r17, r18, r16, r16
	ld.w	-20[r14], r17
	ld.w	36[r8], r18
	maddf.s	r17, r18, r16, r16
	ld.w	-16[r14], r17
	ld.w	52[r8], r18
	maddf.s	r17, r18, r16, r16
	st.w	r16, -24[r15]
	ld.w	-28[r14], r16
	ld.w	8[r8], r17
	ld.w	24[r8], r18
	maddf.s	r16, r17, r0, r16
	ld.w	-24[r14], r17
	maddf.s	r17, r18, r16, r16
	ld.w	-20[r14], r17
	ld.w	40[r8], r18
	maddf.s	r17, r18, r16, r16
	ld.w	-16[r14], r17
	ld.w	56[r8], r18
	maddf.s	r17, r18, r16, r16
	st.w	r16, -20[r15]
	ld.w	-28[r14], r16
	ld.w	12[r8], r17
	ld.w	28[r8], r18
	maddf.s	r16, r17, r0, r16
	ld.w	-24[r14], r17
	maddf.s	r17, r18, r16, r16
	ld.w	-20[r14], r17
	ld.w	44[r8], r18
	maddf.s	r17, r18, r16, r16
	ld.w	-16[r14], r17
	ld.w	60[r8], r18
	maddf.s	r17, r18, r16, r16
	st.w	r16, -16[r15]
	ld.w	-12[r14], r16
	ld.w	0[r8], r17
	ld.w	16[r8], r18
	maddf.s	r16, r17, r0, r16
	ld.w	-8[r14], r17
	maddf.s	r17, r18, r16, r16
	ld.w	-4[r14], r17
	ld.w	32[r8], r18
	maddf.s	r17, r18, r16, r16
	ld.w	0[r14], r17
	ld.w	48[r8], r18
	maddf.s	r17, r18, r16, r16
	st.w	r16, -12[r15]
	ld.w	-12[r14], r16
	ld.w	4[r8], r17
	ld.w	20[r8], r18
	maddf.s	r16, r17, r0, r16
	ld.w	-8[r14], r17
	maddf.s	r17, r18, r16, r16
	ld.w	-4[r14], r17
	ld.w	36[r8], r18
	maddf.s	r17, r18, r16, r16
	ld.w	0[r14], r17
	ld.w	52[r8], r18
	maddf.s	r17, r18, r16, r16
	st.w	r16, -8[r15]
	ld.w	-12[r14], r16
	ld.w	8[r8], r17
	ld.w	24[r8], r18
	maddf.s	r16, r17, r0, r16
	ld.w	-8[r14], r17
	maddf.s	r17, r18, r16, r16
	ld.w	-4[r14], r17
	ld.w	40[r8], r18
	maddf.s	r17, r18, r16, r16
	ld.w	0[r14], r17
	ld.w	56[r8], r18
	maddf.s	r17, r18, r16, r16
	st.w	r16, -4[r15]
	ld.w	-12[r14], r16
	ld.w	12[r8], r17
	ld.w	28[r8], r18
	maddf.s	r16, r17, r0, r16
	ld.w	-8[r14], r17
	maddf.s	r17, r18, r16, r16
	ld.w	-4[r14], r17
	ld.w	44[r8], r18
	ld.w	0[r14], r14
	maddf.s	r17, r18, r16, r16
	ld.w	60[r8], r17
	maddf.s	r14, r17, r16, r14
	st.w	r14, 0[r15]
	bz	.LBB23_2
	jr	.LBB23_1
.LBB23_2:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end23:
	.size	mat4_mul, .Lfunc_end23-mat4_mul
                                        ; -- End function
	.globl	mat4_vec_mul                    ; -- Begin function mat4_vec_mul
	.p2align	2
	.type	mat4_vec_mul,@function
mat4_vec_mul:                           ; @mat4_vec_mul
; %bb.0:                                ; %entry
	ld.w	0[r7], r10
	ld.w	0[r8], r11
	ld.w	4[r8], r12
	maddf.s	r10, r11, r0, r10
	ld.w	4[r7], r11
	maddf.s	r11, r12, r10, r10
	ld.w	8[r7], r11
	ld.w	8[r8], r12
	maddf.s	r11, r12, r10, r10
	ld.w	12[r7], r11
	ld.w	12[r8], r12
	maddf.s	r11, r12, r10, r10
	st.w	r10, 0[r6]
	ld.w	16[r7], r10
	ld.w	0[r8], r11
	ld.w	4[r8], r12
	maddf.s	r10, r11, r0, r10
	ld.w	20[r7], r11
	maddf.s	r11, r12, r10, r10
	ld.w	24[r7], r11
	ld.w	8[r8], r12
	maddf.s	r11, r12, r10, r10
	ld.w	28[r7], r11
	ld.w	12[r8], r12
	maddf.s	r11, r12, r10, r10
	st.w	r10, 4[r6]
	ld.w	32[r7], r10
	ld.w	0[r8], r11
	ld.w	4[r8], r12
	maddf.s	r10, r11, r0, r10
	ld.w	36[r7], r11
	maddf.s	r11, r12, r10, r10
	ld.w	40[r7], r11
	ld.w	8[r8], r12
	maddf.s	r11, r12, r10, r10
	ld.w	44[r7], r11
	ld.w	12[r8], r12
	maddf.s	r11, r12, r10, r10
	st.w	r10, 8[r6]
	ld.w	48[r7], r10
	ld.w	0[r8], r11
	ld.w	4[r8], r12
	maddf.s	r10, r11, r0, r10
	ld.w	52[r7], r11
	maddf.s	r11, r12, r10, r10
	ld.w	56[r7], r11
	ld.w	8[r8], r12
	maddf.s	r11, r12, r10, r10
	ld.w	60[r7], r11
	ld.w	12[r8], r12
	maddf.s	r11, r12, r10, r10
	st.w	r10, 12[r6]
	jmp	[r31]
.Lfunc_end24:
	.size	mat4_vec_mul, .Lfunc_end24-mat4_vec_mul
                                        ; -- End function
	.globl	mat4_transpose                  ; -- Begin function mat4_transpose
	.p2align	2
	.type	mat4_transpose,@function
mat4_transpose:                         ; @mat4_transpose
; %bb.0:                                ; %entry
	ld.w	0[r7], r10
	st.w	r10, 0[r6]
	ld.w	4[r7], r10
	st.w	r10, 16[r6]
	ld.w	8[r7], r10
	st.w	r10, 32[r6]
	ld.w	12[r7], r10
	st.w	r10, 48[r6]
	ld.w	16[r7], r10
	st.w	r10, 4[r6]
	ld.w	20[r7], r10
	st.w	r10, 20[r6]
	ld.w	24[r7], r10
	st.w	r10, 36[r6]
	ld.w	28[r7], r10
	st.w	r10, 52[r6]
	ld.w	32[r7], r10
	st.w	r10, 8[r6]
	ld.w	36[r7], r10
	st.w	r10, 24[r6]
	ld.w	40[r7], r10
	st.w	r10, 40[r6]
	ld.w	44[r7], r10
	st.w	r10, 56[r6]
	ld.w	48[r7], r10
	st.w	r10, 12[r6]
	ld.w	52[r7], r10
	st.w	r10, 28[r6]
	ld.w	56[r7], r10
	st.w	r10, 44[r6]
	ld.w	60[r7], r10
	st.w	r10, 60[r6]
	jmp	[r31]
.Lfunc_end25:
	.size	mat4_transpose, .Lfunc_end25-mat4_transpose
                                        ; -- End function
	.globl	vec3_normalize                  ; -- Begin function vec3_normalize
	.p2align	2
	.type	vec3_normalize,@function
vec3_normalize:                         ; @vec3_normalize
; %bb.0:                                ; %entry
	ld.w	4[r7], r11
	ld.w	0[r7], r10
	ld.w	8[r7], r12
	mulf.s	r11, r11, r11
	maddf.s	r10, r10, r11, r11
	maddf.s	r12, r12, r11, r11
	cmpf.s	7, r0, r11, 0
	trfsr	0
	bz	.LBB26_2
; %bb.1:                                ; %if.then
	movhi	48896, r0, r12
	mov	1597463007, r13
	mulf.s	r12, r11, r12
	shr	1, r11
	sub	r11, r13
	mulf.s	r13, r12, r11
	movhi	16320, r0, r12
	maddf.s	r11, r13, r12, r11
	mulf.s	r13, r11, r11
	jr	.LBB26_3
.LBB26_2:
	movhi	16256, r0, r11
.LBB26_3:                               ; %if.end
	mulf.s	r11, r10, r10
	st.w	r10, 0[r6]
	ld.w	4[r7], r10
	mulf.s	r10, r11, r10
	st.w	r10, 4[r6]
	ld.w	8[r7], r10
	mulf.s	r10, r11, r10
	st.w	r10, 8[r6]
	jmp	[r31]
.Lfunc_end26:
	.size	vec3_normalize, .Lfunc_end26-vec3_normalize
                                        ; -- End function
	.globl	batch_dot3                      ; -- Begin function batch_dot3
	.p2align	2
	.type	batch_dot3,@function
batch_dot3:                             ; @batch_dot3
; %bb.0:                                ; %entry
	cmp	1, r9
	bge	.LBB27_1
	jr	.LBB27_8
.LBB27_1:                               ; %for.body.preheader
	andi	3, r9, r10
	cmp	4, r9
	bnc	.LBB27_3
; %bb.2:
	mov	0, r11
	jr	.LBB27_5
.LBB27_3:                               ; %for.body.preheader.new
	mov	2147483644, r11
	mov	r6, r12
	addi	24, r8, r13
	addi	24, r7, r14
	and	r11, r9
	add	8, r12
	mov	0, r11
	add	-4, r9
	shr	2, r9
	add	1, r9
.LBB27_4:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-20[r13], r15
	ld.w	-20[r14], r16
	ld.w	-24[r13], r17
	add	4, r11
	mulf.s	r15, r16, r15
	ld.w	-24[r14], r16
	maddf.s	r16, r17, r15, r15
	ld.w	-16[r14], r16
	ld.w	-16[r13], r17
	maddf.s	r16, r17, r15, r15
	ld.w	-8[r14], r16
	ld.w	-12[r13], r17
	st.w	r15, -8[r12]
	ld.w	-8[r13], r15
	mulf.s	r15, r16, r15
	ld.w	-12[r14], r16
	maddf.s	r16, r17, r15, r15
	ld.w	-4[r14], r16
	ld.w	-4[r13], r17
	maddf.s	r16, r17, r15, r15
	ld.w	4[r14], r16
	ld.w	0[r13], r17
	st.w	r15, -4[r12]
	ld.w	4[r13], r15
	mulf.s	r15, r16, r15
	ld.w	0[r14], r16
	maddf.s	r16, r17, r15, r15
	ld.w	8[r14], r16
	ld.w	8[r13], r17
	maddf.s	r16, r17, r15, r15
	ld.w	16[r14], r16
	ld.w	12[r13], r17
	st.w	r15, 0[r12]
	ld.w	16[r13], r15
	mulf.s	r15, r16, r15
	ld.w	12[r14], r16
	maddf.s	r16, r17, r15, r15
	ld.w	20[r14], r16
	ld.w	20[r13], r17
	addi	48, r13, r13
	addi	48, r14, r14
	maddf.s	r16, r17, r15, r15
	st.w	r15, 4[r12]
	addi	16, r12, r12
	loop r9, .LBB27_4
.LBB27_5:                               ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r10
	bz	.LBB27_8
; %bb.6:                                ; %for.body.epil.preheader
	mov	r11, r12
	shl	2, r12
	add	r12, r6
	mul	12, r11, r12
	add	4, r11
	add	r11, r8
	add	r11, r7
.LBB27_7:                               ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r8], r11
	ld.w	0[r7], r12
	ld.w	-4[r8], r13
	mulf.s	r11, r12, r11
	ld.w	-4[r7], r12
	maddf.s	r12, r13, r11, r11
	ld.w	4[r7], r12
	ld.w	4[r8], r13
	add	12, r8
	add	12, r7
	maddf.s	r12, r13, r11, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r10, .LBB27_7
.LBB27_8:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end27:
	.size	batch_dot3, .Lfunc_end27-batch_dot3
                                        ; -- End function
	.globl	batch_cross3_soa                ; -- Begin function batch_cross3_soa
	.p2align	2
	.type	batch_cross3_soa,@function
batch_cross3_soa:                       ; @batch_cross3_soa
; %bb.0:                                ; %entry
	prepare	4095, 0
	addi	-48, r3, r3
	addi	68, r3, r10
	ld.w	0[r10], r16
	cmp	1, r16
	bge	.LBB28_1
	jr	.LBB28_8
.LBB28_1:                               ; %for.body.preheader
	addi	64, r3, r10
	andi	3, r16, r15
	st.dw r8, 28[r3]
	st.dw r6, 20[r3]
	ld.w	0[r10], r12
	addi	60, r3, r10
	ld.w	0[r10], r25
	addi	56, r3, r10
	ld.w	0[r10], r13
	addi	52, r3, r10
	ld.w	0[r10], r26
	addi	48, r3, r10
	st.w	r12, 16[r3]                     ; 4-byte Folded Spill
	ld.w	0[r10], r10
	cmp	4, r16
	st.w	r25, 12[r3]                     ; 4-byte Folded Spill
	st.w	r13, 8[r3]                      ; 4-byte Folded Spill
	st.w	r26, 4[r3]                      ; 4-byte Folded Spill
	st.w	r10, 0[r3]                      ; 4-byte Folded Spill
	bnc	.LBB28_3
; %bb.2:
	mov	0, r17
	jr	.LBB28_5
.LBB28_3:                               ; %for.body.preheader.new
	mov	2147483644, r11
	add	8, r12
	add	8, r10
	add	12, r8
	mov	0, r27
	add	12, r9
	add	12, r6
	add	12, r25
	add	8, r26
	and	r11, r16
	st.w	r12, 44[r3]                     ; 4-byte Folded Spill
	st.w	r10, 40[r3]                     ; 4-byte Folded Spill
	st.w	r8, 36[r3]                      ; 4-byte Folded Spill
	mov	r7, r30
	mov	r13, r12
	mov	r27, r17
	add	-4, r16
	add	12, r30
	add	12, r12
	shr	2, r16
	add	1, r16
.LBB28_4:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	mov	r26, r28
	add	-1, r16
	add	4, r17
	add	r27, r28
	ld.w	-8[r28], r20
	mov	r25, r29
	ld.w	40[r3], r19                     ; 4-byte Folded Reload
	add	r27, r29
	ld.w	-12[r29], r31
	add	r27, r19
	ld.w	-8[r19], r8
	negf.s	r31, r18
	mulf.s	r18, r20, r21
	ld.w	44[r3], r18                     ; 4-byte Folded Reload
	add	r27, r18
	ld.w	-8[r18], r22
	mov	r6, r24
	add	r27, r24
	maddf.s	r8, r22, r21, r21
	st.w	r21, -12[r24]
	negf.s	r22, r21
	mov	r9, r22
	add	r27, r22
	ld.w	-12[r22], r13
	mov	r12, r23
	add	r27, r23
	ld.w	-12[r23], r10
	mulf.s	r21, r13, r21
	maddf.s	r20, r10, r21, r20
	negf.s	r10, r10
	mov	r30, r21
	ld.w	-4[r19], r11
	ld.w	-4[r18], r14
	ld.w	-8[r23], r7
	add	r27, r21
	mulf.s	r10, r8, r10
	st.w	r20, -12[r21]
	ld.w	36[r3], r20                     ; 4-byte Folded Reload
	add	r27, r20
	addi	16, r27, r27
	maddf.s	r13, r31, r10, r10
	ld.w	-8[r29], r13
	cmp	0, r16
	negf.s	r13, r8
	st.w	r10, -12[r20]
	ld.w	-4[r28], r10
	mulf.s	r8, r10, r8
	maddf.s	r11, r14, r8, r8
	negf.s	r14, r14
	st.w	r8, -8[r24]
	ld.w	-8[r22], r8
	mulf.s	r14, r8, r14
	maddf.s	r10, r7, r14, r10
	ld.w	0[r19], r14
	st.w	r10, -8[r21]
	negf.s	r7, r10
	ld.w	0[r18], r7
	ld.w	4[r18], r18
	mulf.s	r10, r11, r10
	ld.w	-4[r29], r11
	maddf.s	r8, r13, r10, r10
	negf.s	r11, r13
	ld.w	-4[r23], r8
	st.w	r10, -8[r20]
	ld.w	0[r28], r10
	mulf.s	r13, r10, r13
	maddf.s	r14, r7, r13, r13
	st.w	r13, -4[r24]
	negf.s	r7, r13
	ld.w	-4[r22], r7
	mulf.s	r13, r7, r13
	maddf.s	r10, r8, r13, r10
	st.w	r10, -4[r21]
	negf.s	r8, r10
	mulf.s	r10, r14, r10
	ld.w	4[r19], r14
	ld.w	0[r23], r19
	maddf.s	r7, r11, r10, r10
	ld.w	0[r29], r11
	negf.s	r11, r13
	st.w	r10, -4[r20]
	ld.w	4[r28], r10
	mulf.s	r13, r10, r13
	maddf.s	r14, r18, r13, r13
	st.w	r13, 0[r24]
	negf.s	r18, r13
	ld.w	0[r22], r18
	mulf.s	r13, r18, r13
	maddf.s	r10, r19, r13, r10
	st.w	r10, 0[r21]
	negf.s	r19, r10
	mulf.s	r10, r14, r10
	maddf.s	r18, r11, r10, r10
	st.w	r10, 0[r20]
	bz	.LBB28_5
	jr	.LBB28_4
.LBB28_5:                               ; %for.cond.cleanup.loopexit.unr-lcssa
	ld.w	32[r3], r10                     ; 4-byte Folded Reload
	ld.w	28[r3], r13                     ; 4-byte Folded Reload
	ld.w	24[r3], r6                      ; 4-byte Folded Reload
	ld.w	20[r3], r7                      ; 4-byte Folded Reload
	ld.w	16[r3], r8                      ; 4-byte Folded Reload
	ld.w	12[r3], r9                      ; 4-byte Folded Reload
	ld.w	8[r3], r20                      ; 4-byte Folded Reload
	ld.w	4[r3], r21                      ; 4-byte Folded Reload
	ld.w	0[r3], r22                      ; 4-byte Folded Reload
	cmp	0, r15
	bz	.LBB28_8
; %bb.6:                                ; %for.body.epil.preheader
	shl	2, r15
	shl	2, r17
	mov	0, r11
	add	-4, r15
	add	r17, r22
	add	r17, r8
	add	r17, r21
	add	r17, r9
	add	r17, r7
	add	r17, r20
	add	r17, r10
	add	r17, r6
	add	r17, r13
	shr	2, r15
	add	1, r15
.LBB28_7:                               ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	mov	r21, r12
	add	-1, r15
	add	r11, r12
	ld.w	0[r12], r12
	mov	r9, r14
	add	r11, r14
	ld.w	0[r14], r14
	mov	r22, r17
	add	r11, r17
	ld.w	0[r17], r17
	mov	r8, r18
	negf.s	r14, r16
	add	r11, r18
	ld.w	0[r18], r18
	mov	r7, r19
	add	r11, r19
	mulf.s	r16, r12, r16
	maddf.s	r17, r18, r16, r16
	st.w	r16, 0[r19]
	negf.s	r18, r16
	mov	r10, r18
	add	r11, r18
	ld.w	0[r18], r18
	mov	r20, r19
	add	r11, r19
	ld.w	0[r19], r19
	mulf.s	r16, r18, r16
	maddf.s	r12, r19, r16, r12
	mov	r6, r16
	add	r11, r16
	st.w	r12, 0[r16]
	negf.s	r19, r12
	mulf.s	r12, r17, r12
	maddf.s	r18, r14, r12, r12
	mov	r13, r14
	add	r11, r14
	add	4, r11
	cmp	0, r15
	st.w	r12, 0[r14]
	bnz	.LBB28_7
.LBB28_8:                               ; %for.cond.cleanup
	addi	48, r3, r3
	dispose	0, 4095, [r31]
.Lfunc_end28:
	.size	batch_cross3_soa, .Lfunc_end28-batch_cross3_soa
                                        ; -- End function
	.globl	pid4_update                     ; -- Begin function pid4_update
	.p2align	2
	.type	pid4_update,@function
pid4_update:                            ; @pid4_update
; %bb.0:                                ; %entry
	ld.w	0[r9], r10
	ld.w	0[r8], r11
	ld.w	48[r6], r12
	subf.s	r10, r11, r11
	addi	0, r3, r10
	ld.w	0[r10], r10
	maddf.s	r11, r10, r12, r12
	st.w	r12, 48[r6]
	ld.w	16[r6], r13
	ld.w	32[r6], r14
	mulf.s	r13, r12, r12
	ld.w	0[r6], r13
	maddf.s	r13, r11, r12, r12
	ld.w	64[r6], r13
	subf.s	r13, r11, r13
	divf.s	r10, r13, r13
	maddf.s	r14, r13, r12, r12
	st.w	r12, 0[r7]
	st.w	r11, 64[r6]
	ld.w	4[r9], r11
	ld.w	4[r8], r12
	subf.s	r11, r12, r11
	ld.w	52[r6], r12
	maddf.s	r11, r10, r12, r12
	st.w	r12, 52[r6]
	ld.w	20[r6], r13
	ld.w	36[r6], r14
	mulf.s	r13, r12, r12
	ld.w	4[r6], r13
	maddf.s	r13, r11, r12, r12
	ld.w	68[r6], r13
	subf.s	r13, r11, r13
	divf.s	r10, r13, r13
	maddf.s	r14, r13, r12, r12
	st.w	r12, 4[r7]
	st.w	r11, 68[r6]
	ld.w	8[r9], r11
	ld.w	8[r8], r12
	subf.s	r11, r12, r11
	ld.w	56[r6], r12
	maddf.s	r11, r10, r12, r12
	st.w	r12, 56[r6]
	ld.w	24[r6], r13
	ld.w	40[r6], r14
	mulf.s	r13, r12, r12
	ld.w	8[r6], r13
	maddf.s	r13, r11, r12, r12
	ld.w	72[r6], r13
	subf.s	r13, r11, r13
	divf.s	r10, r13, r13
	maddf.s	r14, r13, r12, r12
	st.w	r12, 8[r7]
	st.w	r11, 72[r6]
	ld.w	12[r9], r11
	ld.w	12[r8], r12
	subf.s	r11, r12, r11
	ld.w	60[r6], r12
	maddf.s	r11, r10, r12, r12
	st.w	r12, 60[r6]
	ld.w	28[r6], r13
	mulf.s	r13, r12, r12
	ld.w	12[r6], r13
	maddf.s	r13, r11, r12, r12
	ld.w	76[r6], r13
	subf.s	r13, r11, r13
	divf.s	r10, r13, r10
	ld.w	44[r6], r13
	maddf.s	r13, r10, r12, r10
	st.w	r10, 12[r7]
	st.w	r11, 76[r6]
	jmp	[r31]
.Lfunc_end29:
	.size	pid4_update, .Lfunc_end29-pid4_update
                                        ; -- End function
	.globl	sensor_scale                    ; -- Begin function sensor_scale
	.p2align	2
	.type	sensor_scale,@function
sensor_scale:                           ; @sensor_scale
; %bb.0:                                ; %entry
	addi	0, r3, r10
	ld.w	0[r10], r11
	cmp	1, r11
	blt	.LBB30_8
; %bb.1:                                ; %for.body.preheader
	andi	3, r11, r10
	cmp	4, r11
	bnc	.LBB30_3
; %bb.2:
	mov	0, r12
	jr	.LBB30_5
.LBB30_3:                               ; %for.body.preheader.new
	mov	2147483644, r12
	mov	r7, r13
	mov	r8, r14
	mov	r6, r15
	mov	r9, r16
	and	r12, r11
	add	8, r13
	add	8, r14
	add	8, r15
	add	8, r16
	mov	0, r12
	add	-4, r11
	shr	2, r11
	add	1, r11
.LBB30_4:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-8[r16], r17
	ld.w	-8[r14], r18
	ld.w	-8[r13], r19
	add	4, r12
	maddf.s	r18, r19, r17, r17
	ld.w	-4[r14], r18
	ld.w	-4[r13], r19
	st.w	r17, -8[r15]
	ld.w	-4[r16], r17
	maddf.s	r18, r19, r17, r17
	ld.w	0[r14], r18
	ld.w	0[r13], r19
	st.w	r17, -4[r15]
	ld.w	0[r16], r17
	maddf.s	r18, r19, r17, r17
	ld.w	4[r14], r18
	ld.w	4[r13], r19
	addi	16, r13, r13
	addi	16, r14, r14
	st.w	r17, 0[r15]
	ld.w	4[r16], r17
	addi	16, r16, r16
	maddf.s	r18, r19, r17, r17
	st.w	r17, 4[r15]
	addi	16, r15, r15
	loop r11, .LBB30_4
.LBB30_5:                               ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r10
	bz	.LBB30_8
; %bb.6:                                ; %for.body.epil.preheader
	shl	2, r12
	add	r12, r8
	add	r12, r7
	add	r12, r9
	add	r12, r6
.LBB30_7:                               ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r9], r11
	ld.w	0[r8], r12
	ld.w	0[r7], r13
	add	4, r8
	add	4, r7
	add	4, r9
	maddf.s	r12, r13, r11, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r10, .LBB30_7
.LBB30_8:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end30:
	.size	sensor_scale, .Lfunc_end30-sensor_scale
                                        ; -- End function
	.globl	sensor_weighted_avg             ; -- Begin function sensor_weighted_avg
	.p2align	2
	.type	sensor_weighted_avg,@function
sensor_weighted_avg:                    ; @sensor_weighted_avg
; %bb.0:                                ; %entry
	ld.w	0[r6], r10
	ld.w	0[r7], r11
	ld.w	4[r6], r12
	ld.w	4[r7], r13
	ld.w	8[r7], r14
	ld.w	12[r7], r15
	maddf.s	r10, r11, r0, r10
	addf.s	r0, r11, r11
	addf.s	r13, r11, r11
	maddf.s	r12, r13, r10, r10
	ld.w	8[r6], r12
	addf.s	r14, r11, r11
	maddf.s	r12, r14, r10, r10
	ld.w	12[r6], r12
	maddf.s	r12, r15, r10, r10
	addf.s	r15, r11, r11
	divf.s	r11, r10, r10
	jmp	[r31]
.Lfunc_end31:
	.size	sensor_weighted_avg, .Lfunc_end31-sensor_weighted_avg
                                        ; -- End function
	.globl	stereo_to_mono                  ; -- Begin function stereo_to_mono
	.p2align	2
	.type	stereo_to_mono,@function
stereo_to_mono:                         ; @stereo_to_mono
; %bb.0:                                ; %entry
	cmp	1, r8
	blt	.LBB32_8
; %bb.1:                                ; %for.body.preheader
	andi	3, r8, r10
	cmp	4, r8
	bnc	.LBB32_3
; %bb.2:
	mov	0, r11
	jr	.LBB32_5
.LBB32_3:                               ; %for.body.preheader.new
	mov	2147483644, r11
	mov	r6, r13
	addi	16, r7, r12
	movhi	16128, r0, r14
	and	r11, r8
	add	8, r13
	mov	0, r11
	add	-4, r8
	shr	2, r8
	add	1, r8
.LBB32_4:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-12[r12], r15
	ld.w	-16[r12], r16
	add	4, r11
	addf.s	r15, r16, r15
	ld.w	-8[r12], r16
	mulf.s	r14, r15, r15
	st.w	r15, -8[r13]
	ld.w	-4[r12], r15
	addf.s	r15, r16, r15
	ld.w	0[r12], r16
	mulf.s	r14, r15, r15
	st.w	r15, -4[r13]
	ld.w	4[r12], r15
	addf.s	r15, r16, r15
	ld.w	8[r12], r16
	mulf.s	r14, r15, r15
	st.w	r15, 0[r13]
	ld.w	12[r12], r15
	addi	32, r12, r12
	addf.s	r15, r16, r15
	mulf.s	r14, r15, r15
	st.w	r15, 4[r13]
	addi	16, r13, r13
	loop r8, .LBB32_4
.LBB32_5:                               ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r10
	bz	.LBB32_8
; %bb.6:                                ; %for.body.epil.preheader
	mov	r11, r12
	shl	3, r11
	add	r7, r11
	shl	2, r12
	add	r12, r6
	add	4, r11
	movhi	16128, r0, r12
.LBB32_7:                               ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r11], r13
	ld.w	-4[r11], r14
	add	8, r11
	addf.s	r13, r14, r13
	mulf.s	r12, r13, r13
	st.w	r13, 0[r6]
	add	4, r6
	loop r10, .LBB32_7
.LBB32_8:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end32:
	.size	stereo_to_mono, .Lfunc_end32-stereo_to_mono
                                        ; -- End function
	.globl	audio_gain                      ; -- Begin function audio_gain
	.p2align	2
	.type	audio_gain,@function
audio_gain:                             ; @audio_gain
; %bb.0:                                ; %entry
	cmp	1, r8
	blt	.LBB33_8
; %bb.1:                                ; %for.body.preheader
	andi	3, r8, r10
	cmp	4, r8
	bnc	.LBB33_3
; %bb.2:
	mov	0, r11
	jr	.LBB33_5
.LBB33_3:                               ; %for.body.preheader.new
	mov	2147483644, r11
	mov	r6, r12
	and	r11, r8
	add	8, r12
	mov	0, r11
	add	-4, r8
	shr	2, r8
	add	1, r8
.LBB33_4:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-8[r12], r13
	add	4, r11
	mulf.s	r13, r7, r13
	st.w	r13, -8[r12]
	ld.w	-4[r12], r13
	mulf.s	r13, r7, r13
	st.w	r13, -4[r12]
	ld.w	0[r12], r13
	mulf.s	r13, r7, r13
	st.w	r13, 0[r12]
	ld.w	4[r12], r13
	mulf.s	r13, r7, r13
	st.w	r13, 4[r12]
	addi	16, r12, r12
	loop r8, .LBB33_4
.LBB33_5:                               ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r10
	bz	.LBB33_8
; %bb.6:                                ; %for.body.epil.preheader
	shl	2, r11
	add	r11, r6
.LBB33_7:                               ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r6], r11
	mulf.s	r11, r7, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r10, .LBB33_7
.LBB33_8:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end33:
	.size	audio_gain, .Lfunc_end33-audio_gain
                                        ; -- End function
	.globl	audio_mix                       ; -- Begin function audio_mix
	.p2align	2
	.type	audio_mix,@function
audio_mix:                              ; @audio_mix
; %bb.0:                                ; %entry
	addi	4, r3, r10
	ld.w	0[r10], r12
	cmp	1, r12
	blt	.LBB34_8
; %bb.1:                                ; %for.body.preheader
	addi	0, r3, r10
	andi	3, r12, r11
	ld.w	0[r10], r10
	cmp	4, r12
	bnc	.LBB34_3
; %bb.2:
	mov	0, r13
	jr	.LBB34_5
.LBB34_3:                               ; %for.body.preheader.new
	mov	2147483644, r13
	mov	r9, r14
	mov	r7, r15
	mov	r6, r16
	and	r13, r12
	add	8, r14
	add	8, r15
	add	8, r16
	mov	0, r13
	add	-4, r12
	shr	2, r12
	add	1, r12
.LBB34_4:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-8[r14], r17
	ld.w	-8[r15], r18
	add	4, r13
	mulf.s	r17, r10, r17
	maddf.s	r18, r8, r17, r17
	ld.w	-4[r15], r18
	st.w	r17, -8[r16]
	ld.w	-4[r14], r17
	mulf.s	r17, r10, r17
	maddf.s	r18, r8, r17, r17
	ld.w	0[r15], r18
	st.w	r17, -4[r16]
	ld.w	0[r14], r17
	mulf.s	r17, r10, r17
	maddf.s	r18, r8, r17, r17
	ld.w	4[r15], r18
	addi	16, r15, r15
	st.w	r17, 0[r16]
	ld.w	4[r14], r17
	addi	16, r14, r14
	mulf.s	r17, r10, r17
	maddf.s	r18, r8, r17, r17
	st.w	r17, 4[r16]
	addi	16, r16, r16
	loop r12, .LBB34_4
.LBB34_5:                               ; %for.cond.cleanup.loopexit.unr-lcssa
	cmp	0, r11
	bz	.LBB34_8
; %bb.6:                                ; %for.body.epil.preheader
	shl	2, r13
	add	r13, r7
	add	r13, r9
	add	r13, r6
.LBB34_7:                               ; %for.body.epil
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r9], r12
	ld.w	0[r7], r13
	add	4, r7
	add	4, r9
	mulf.s	r12, r10, r12
	maddf.s	r13, r8, r12, r12
	st.w	r12, 0[r6]
	add	4, r6
	loop r11, .LBB34_7
.LBB34_8:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end34:
	.size	audio_mix, .Lfunc_end34-audio_mix
                                        ; -- End function
	.globl	add4                            ; -- Begin function add4
	.p2align	2
	.type	add4,@function
add4:                                   ; @add4
; %bb.0:                                ; %entry
	ld.w	0[r8], r10
	ld.w	0[r7], r11
	addf.s	r10, r11, r10
	st.w	r10, 0[r6]
	ld.w	4[r8], r10
	ld.w	4[r7], r11
	addf.s	r10, r11, r10
	st.w	r10, 4[r6]
	ld.w	8[r8], r10
	ld.w	8[r7], r11
	addf.s	r10, r11, r10
	st.w	r10, 8[r6]
	ld.w	12[r8], r10
	ld.w	12[r7], r11
	addf.s	r10, r11, r10
	st.w	r10, 12[r6]
	jmp	[r31]
.Lfunc_end35:
	.size	add4, .Lfunc_end35-add4
                                        ; -- End function
	.globl	mul4                            ; -- Begin function mul4
	.p2align	2
	.type	mul4,@function
mul4:                                   ; @mul4
; %bb.0:                                ; %entry
	ld.w	0[r8], r10
	ld.w	0[r7], r11
	mulf.s	r10, r11, r10
	st.w	r10, 0[r6]
	ld.w	4[r8], r10
	ld.w	4[r7], r11
	mulf.s	r10, r11, r10
	st.w	r10, 4[r6]
	ld.w	8[r8], r10
	ld.w	8[r7], r11
	mulf.s	r10, r11, r10
	st.w	r10, 8[r6]
	ld.w	12[r8], r10
	ld.w	12[r7], r11
	mulf.s	r10, r11, r10
	st.w	r10, 12[r6]
	jmp	[r31]
.Lfunc_end36:
	.size	mul4, .Lfunc_end36-mul4
                                        ; -- End function
	.globl	fma4                            ; -- Begin function fma4
	.p2align	2
	.type	fma4,@function
fma4:                                   ; @fma4
; %bb.0:                                ; %entry
	ld.w	0[r9], r10
	ld.w	0[r7], r11
	ld.w	0[r8], r12
	maddf.s	r11, r12, r10, r10
	st.w	r10, 0[r6]
	ld.w	4[r9], r10
	ld.w	4[r7], r11
	ld.w	4[r8], r12
	maddf.s	r11, r12, r10, r10
	st.w	r10, 4[r6]
	ld.w	8[r9], r10
	ld.w	8[r7], r11
	ld.w	8[r8], r12
	maddf.s	r11, r12, r10, r10
	st.w	r10, 8[r6]
	ld.w	12[r9], r10
	ld.w	12[r7], r11
	ld.w	12[r8], r12
	maddf.s	r11, r12, r10, r10
	st.w	r10, 12[r6]
	jmp	[r31]
.Lfunc_end37:
	.size	fma4, .Lfunc_end37-fma4
                                        ; -- End function
	.globl	dot4                            ; -- Begin function dot4
	.p2align	2
	.type	dot4,@function
dot4:                                   ; @dot4
; %bb.0:                                ; %entry
	ld.w	4[r7], r10
	ld.w	4[r6], r11
	ld.w	0[r7], r12
	mulf.s	r10, r11, r10
	ld.w	0[r6], r11
	maddf.s	r11, r12, r10, r10
	ld.w	8[r6], r11
	ld.w	8[r7], r12
	maddf.s	r11, r12, r10, r10
	ld.w	12[r6], r11
	ld.w	12[r7], r12
	maddf.s	r11, r12, r10, r10
	jmp	[r31]
.Lfunc_end38:
	.size	dot4, .Lfunc_end38-dot4
                                        ; -- End function
	.globl	saxpy4                          ; -- Begin function saxpy4
	.p2align	2
	.type	saxpy4,@function
saxpy4:                                 ; @saxpy4
; %bb.0:                                ; %entry
	ld.w	0[r6], r10
	ld.w	0[r8], r11
	maddf.s	r7, r11, r10, r10
	st.w	r10, 0[r6]
	ld.w	4[r6], r10
	ld.w	4[r8], r11
	maddf.s	r7, r11, r10, r10
	st.w	r10, 4[r6]
	ld.w	8[r6], r10
	ld.w	8[r8], r11
	maddf.s	r7, r11, r10, r10
	st.w	r10, 8[r6]
	ld.w	12[r6], r10
	ld.w	12[r8], r11
	maddf.s	r7, r11, r10, r10
	st.w	r10, 12[r6]
	jmp	[r31]
.Lfunc_end39:
	.size	saxpy4, .Lfunc_end39-saxpy4
                                        ; -- End function
	.ident	"clang version 21.1.8 (git@github.com:lfazio/llvm-project-v850.git b07cd996907f42971a0b6c55609e3813955d2653)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
