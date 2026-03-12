	.file	"fxu_vector.c"
	.text
	.globl	vec_add                         ; -- Begin function vec_add
	.p2align	2
	.type	vec_add,@function
vec_add:                                ; @vec_add
; %bb.0:                                ; %entry
	cmp	1, r9
	blt	.LBB0_2
.LBB0_1:                                ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r8], r10
	ld.w	0[r7], r11
	add	4, r7
	add	4, r8
	addf.s	r10, r11, r10
	st.w	r10, 0[r6]
	add	4, r6
	loop r9, .LBB0_1
.LBB0_2:                                ; %for.cond.cleanup
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
	blt	.LBB1_2
.LBB1_1:                                ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r8], r10
	ld.w	0[r7], r11
	add	4, r7
	add	4, r8
	subf.s	r10, r11, r10
	st.w	r10, 0[r6]
	add	4, r6
	loop r9, .LBB1_1
.LBB1_2:                                ; %for.cond.cleanup
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
	blt	.LBB2_2
.LBB2_1:                                ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r8], r10
	ld.w	0[r7], r11
	add	4, r7
	add	4, r8
	mulf.s	r10, r11, r10
	st.w	r10, 0[r6]
	add	4, r6
	loop r9, .LBB2_1
.LBB2_2:                                ; %for.cond.cleanup
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
	blt	.LBB3_2
.LBB3_1:                                ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r8], r10
	ld.w	0[r7], r11
	add	4, r7
	add	4, r8
	divf.s	r10, r11, r10
	st.w	r10, 0[r6]
	add	4, r6
	loop r9, .LBB3_1
.LBB3_2:                                ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end3:
	.size	vec_div, .Lfunc_end3-vec_div
                                        ; -- End function
	.section	.sdata,"aw",@progbits
	.p2align	2, 0x0                          ; -- Begin function vec_abs
.LCPI4_0:
	.word	0x00000000                      ; float 0
	.text
	.globl	vec_abs
	.p2align	2
	.type	vec_abs,@function
vec_abs:                                ; @vec_abs
; %bb.0:                                ; %entry
	cmp	1, r8
	blt	.LBB4_3
; %bb.1:                                ; %for.body.preheader
	movhi	.LCPI4_0, r0, r11
	movhi	32768, r0, r10
	movea	.LCPI4_0, r11, r11
	ld.w	0[r11], r11
.LBB4_2:                                ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r7], r12
	mov	r12, r13
	cmpf.s	4, r11, r12, 0
	xor	r10, r13
	trfsr	0
	cmov	z, r13, r12, r12
	add	4, r7
	st.w	r12, [r6]+
	loop r8, .LBB4_2
.LBB4_3:                                ; %for.cond.cleanup
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
	blt	.LBB5_2
.LBB5_1:                                ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r7], r10
	add	4, r7
	negf.s	r10, r10
	st.w	r10, 0[r6]
	add	4, r6
	loop r8, .LBB5_1
.LBB5_2:                                ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end5:
	.size	vec_neg, .Lfunc_end5-vec_neg
                                        ; -- End function
	.section	.sdata,"aw",@progbits
	.p2align	2, 0x0                          ; -- Begin function vec_recip
.LCPI6_0:
	.word	0x3f800000                      ; float 1
	.text
	.globl	vec_recip
	.p2align	2
	.type	vec_recip,@function
vec_recip:                              ; @vec_recip
; %bb.0:                                ; %entry
	cmp	1, r8
	blt	.LBB6_3
; %bb.1:                                ; %for.body.preheader
	movhi	.LCPI6_0, r0, r10
	movea	.LCPI6_0, r10, r10
	ld.w	0[r10], r10
.LBB6_2:                                ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r7], r11
	add	4, r7
	divf.s	r11, r10, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r8, .LBB6_2
.LBB6_3:                                ; %for.cond.cleanup
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
	ld.w	0[r10], r10
	cmp	1, r10
	blt	.LBB7_2
.LBB7_1:                                ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r8], r11
	ld.w	0[r7], r12
	add	4, r7
	add	4, r8
	mulf.s	r11, r12, r11
	ld.w	0[r9], r12
	add	4, r9
	addf.s	r12, r11, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r10, .LBB7_1
.LBB7_2:                                ; %for.cond.cleanup
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
	ld.w	0[r10], r10
	cmp	1, r10
	blt	.LBB8_2
.LBB8_1:                                ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r8], r11
	ld.w	0[r7], r12
	add	4, r7
	add	4, r8
	mulf.s	r11, r12, r11
	ld.w	0[r9], r12
	add	4, r9
	subf.s	r12, r11, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r10, .LBB8_1
.LBB8_2:                                ; %for.cond.cleanup
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
	ld.w	0[r10], r10
	cmp	1, r10
	blt	.LBB9_2
.LBB9_1:                                ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r8], r11
	ld.w	0[r7], r12
	add	4, r7
	add	4, r8
	mulf.s	r11, r12, r11
	ld.w	0[r9], r12
	add	4, r9
	subf.s	r11, r12, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r10, .LBB9_1
.LBB9_2:                                ; %for.cond.cleanup
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
	blt	.LBB10_2
.LBB10_1:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r8], r10
	ld.w	0[r7], r11
	cmpf.s	4, r11, r10, 0
	trfsr	0
	cmov	z, r11, r10, r10
	add	4, r7
	add	4, r8
	st.w	r10, [r6]+
	loop r9, .LBB10_1
.LBB10_2:                               ; %for.cond.cleanup
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
	blt	.LBB11_2
.LBB11_1:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r8], r10
	ld.w	0[r7], r11
	cmpf.s	4, r10, r11, 0
	trfsr	0
	cmov	z, r11, r10, r10
	add	4, r7
	add	4, r8
	st.w	r10, [r6]+
	loop r9, .LBB11_1
.LBB11_2:                               ; %for.cond.cleanup
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
	ld.w	0[r10], r10
	cmp	1, r10
	blt	.LBB12_2
.LBB12_1:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r7], r11
	cmpf.s	4, r8, r11, 0
	trfsr	0
	cmov	z, r8, r11, r11
	cmpf.s	4, r11, r9, 0
	trfsr	0
	cmov	z, r9, r11, r11
	add	4, r7
	st.w	r11, [r6]+
	loop r10, .LBB12_1
.LBB12_2:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end12:
	.size	vec_clamp, .Lfunc_end12-vec_clamp
                                        ; -- End function
	.section	.sdata,"aw",@progbits
	.p2align	2, 0x0                          ; -- Begin function vec_sum
.LCPI13_0:
	.word	0x00000000                      ; float 0
	.text
	.globl	vec_sum
	.p2align	2
	.type	vec_sum,@function
vec_sum:                                ; @vec_sum
; %bb.0:                                ; %entry
	movhi	.LCPI13_0, r0, r10
	cmp	1, r7
	movea	.LCPI13_0, r10, r10
	ld.w	0[r10], r10
	blt	.LBB13_2
.LBB13_1:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r6], r11
	add	-1, r7
	add	4, r6
	cmp	0, r7
	addf.s	r11, r10, r10
	bnz	.LBB13_1
.LBB13_2:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end13:
	.size	vec_sum, .Lfunc_end13-vec_sum
                                        ; -- End function
	.section	.sdata,"aw",@progbits
	.p2align	2, 0x0                          ; -- Begin function vec_dot
.LCPI14_0:
	.word	0x00000000                      ; float 0
	.text
	.globl	vec_dot
	.p2align	2
	.type	vec_dot,@function
vec_dot:                                ; @vec_dot
; %bb.0:                                ; %entry
	movhi	.LCPI14_0, r0, r10
	cmp	1, r8
	movea	.LCPI14_0, r10, r10
	ld.w	0[r10], r10
	blt	.LBB14_2
.LBB14_1:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r7], r11
	ld.w	0[r6], r12
	add	-1, r8
	add	4, r6
	add	4, r7
	cmp	0, r8
	mulf.s	r11, r12, r11
	addf.s	r10, r11, r10
	bnz	.LBB14_1
.LBB14_2:                               ; %for.cond.cleanup
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
	blt	.LBB15_3
; %bb.1:                                ; %for.body.preheader
	add	-1, r7
	add	4, r6
.LBB15_2:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r6], r11
	cmpf.s	4, r11, r10, 0
	trfsr	0
	cmov	z, r11, r10, r10
	add	4, r6
	loop r7, .LBB15_2
.LBB15_3:                               ; %for.cond.cleanup
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
	blt	.LBB16_3
; %bb.1:                                ; %for.body.preheader
	add	-1, r7
	add	4, r6
.LBB16_2:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r6], r11
	cmpf.s	4, r10, r11, 0
	trfsr	0
	cmov	z, r11, r10, r10
	add	4, r6
	loop r7, .LBB16_2
.LBB16_3:                               ; %for.cond.cleanup
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
	blt	.LBB17_2
.LBB17_1:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	[r7]+, r10
	cvtf.ws	r10, r10
	st.w	r10, 0[r6]
	add	4, r6
	loop r8, .LBB17_1
.LBB17_2:                               ; %for.cond.cleanup
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
	blt	.LBB18_2
.LBB18_1:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r7], r10
	add	-1, r8
	add	4, r7
	cmp	0, r8
	trncf.sw	r10, r10
	st.w	r10, [r6]+
	bnz	.LBB18_1
.LBB18_2:                               ; %for.cond.cleanup
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
	blt	.LBB19_2
.LBB19_1:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	[r7]+, r10
	cvtf.uws	r10, r10
	st.w	r10, 0[r6]
	add	4, r6
	loop r8, .LBB19_1
.LBB19_2:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end19:
	.size	vec_utof, .Lfunc_end19-vec_utof
                                        ; -- End function
	.section	.sdata,"aw",@progbits
	.p2align	2, 0x0                          ; -- Begin function fir_float
.LCPI20_0:
	.word	0x00000000                      ; float 0
	.text
	.globl	fir_float
	.p2align	2
	.type	fir_float,@function
fir_float:                              ; @fir_float
; %bb.0:                                ; %entry
	movhi	.LCPI20_0, r0, r10
	cmp	1, r8
	movea	.LCPI20_0, r10, r10
	ld.w	0[r10], r10
	blt	.LBB20_2
.LBB20_1:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r7], r11
	ld.w	0[r6], r12
	add	-1, r8
	add	4, r6
	add	4, r7
	cmp	0, r8
	mulf.s	r11, r12, r11
	addf.s	r10, r11, r10
	bnz	.LBB20_1
.LBB20_2:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end20:
	.size	fir_float, .Lfunc_end20-fir_float
                                        ; -- End function
	.section	.sdata,"aw",@progbits
	.p2align	2, 0x0                          ; -- Begin function fir_block
.LCPI21_0:
	.word	0x00000000                      ; float 0
	.text
	.globl	fir_block
	.p2align	2
	.type	fir_block,@function
fir_block:                              ; @fir_block
; %bb.0:                                ; %entry
	cmp	1, r9
	blt	.LBB21_6
; %bb.1:                                ; %for.cond1.preheader.lr.ph
	movhi	.LCPI21_0, r0, r12
	addi	0, r3, r10
	mov	0, r11
	movea	.LCPI21_0, r12, r12
	ld.w	0[r10], r10
	ld.w	0[r12], r12
	jr	.LBB21_3
.LBB21_2:                               ; %for.cond.cleanup3
                                        ;   in Loop: Header=BB21_3 Depth=1
	mov	r11, r14
	mov	r6, r15
	add	4, r7
	add	1, r11
	shl	2, r14
	add	r14, r15
	cmp	r9, r11
	st.w	r13, 0[r15]
	bz	.LBB21_6
.LBB21_3:                               ; %for.cond1.preheader
                                        ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB21_5 Depth 2
	cmp	1, r10
	mov	r12, r13
	blt	.LBB21_2
; %bb.4:                                ; %for.body4.lr.ph
                                        ;   in Loop: Header=BB21_3 Depth=1
	mov	r7, r14
	mov	r8, r15
	mov	r12, r13
	mov	r10, r16
.LBB21_5:                               ; %for.body4
                                        ;   Parent Loop BB21_3 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ld.w	0[r14], r17
	ld.w	0[r15], r18
	add	-1, r16
	add	4, r14
	add	4, r15
	cmp	0, r16
	mulf.s	r17, r18, r17
	addf.s	r13, r17, r13
	bnz	.LBB21_5
	jr	.LBB21_2
.LBB21_6:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end21:
	.size	fir_block, .Lfunc_end21-fir_block
                                        ; -- End function
	.globl	iir_biquad_float                ; -- Begin function iir_biquad_float
	.p2align	2
	.type	iir_biquad_float,@function
iir_biquad_float:                       ; @iir_biquad_float
; %bb.0:                                ; %entry
	prepare	128, 0
	addi	20, r3, r10
	ld.w	0[r10], r10
	cmp	1, r10
	blt	.LBB22_3
; %bb.1:                                ; %for.body.preheader
	addi	16, r3, r11
	addi	12, r3, r12
	addi	8, r3, r13
	addi	4, r3, r14
	addi	0, r3, r15
	ld.w	0[r11], r11
	ld.w	0[r12], r12
	ld.w	0[r13], r13
	ld.w	0[r14], r14
	ld.w	0[r15], r15
	ld.w	0[r11], r16
.LBB22_2:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r7], r17
	ld.w	0[r12], r20
	add	4, r7
	mulf.s	r17, r8, r19
	mulf.s	r17, r9, r18
	addf.s	r20, r19, r19
	mulf.s	r19, r14, r20
	subf.s	r20, r18, r18
	addf.s	r18, r16, r16
	st.w	r16, 0[r12]
	mulf.s	r17, r15, r16
	mulf.s	r19, r13, r17
	subf.s	r17, r16, r16
	st.w	r16, 0[r11]
	st.w	r19, 0[r6]
	add	4, r6
	loop r10, .LBB22_2
.LBB22_3:                               ; %for.cond.cleanup
	dispose	0, 128, [r31]
.Lfunc_end22:
	.size	iir_biquad_float, .Lfunc_end22-iir_biquad_float
                                        ; -- End function
	.section	.sdata,"aw",@progbits
	.p2align	2, 0x0                          ; -- Begin function mat4_mul
.LCPI23_0:
	.word	0x00000000                      ; float 0
	.text
	.globl	mat4_mul
	.p2align	2
	.type	mat4_mul,@function
mat4_mul:                               ; @mat4_mul
; %bb.0:                                ; %entry
	movhi	.LCPI23_0, r0, r12
	add	12, r7
	mov	0, r10
	mov	4, r11
	movea	.LCPI23_0, r12, r12
	ld.w	0[r12], r12
.LBB23_1:                               ; %for.cond1.preheader
                                        ; =>This Inner Loop Header: Depth=1
	mov	r7, r13
	ld.w	16[r8], r15
	ld.w	0[r8], r16
	add	-1, r11
	add	r10, r13
	ld.w	-8[r13], r14
	mulf.s	r15, r14, r14
	ld.w	-12[r13], r15
	mulf.s	r16, r15, r15
	ld.w	32[r8], r16
	addf.s	r12, r15, r15
	addf.s	r15, r14, r14
	ld.w	-4[r13], r15
	mulf.s	r16, r15, r15
	ld.w	48[r8], r16
	addf.s	r14, r15, r14
	ld.w	0[r13], r15
	mulf.s	r16, r15, r15
	addf.s	r14, r15, r15
	mov	r6, r14
	add	r10, r14
	addi	16, r10, r10
	cmp	0, r11
	st.w	r15, 0[r14]
	ld.w	-8[r13], r15
	ld.w	20[r8], r16
	ld.w	4[r8], r17
	mulf.s	r16, r15, r15
	ld.w	-12[r13], r16
	mulf.s	r17, r16, r16
	ld.w	36[r8], r17
	addf.s	r12, r16, r16
	addf.s	r16, r15, r15
	ld.w	-4[r13], r16
	mulf.s	r17, r16, r16
	ld.w	52[r8], r17
	addf.s	r15, r16, r15
	ld.w	0[r13], r16
	mulf.s	r17, r16, r16
	addf.s	r15, r16, r15
	st.w	r15, 4[r14]
	ld.w	-8[r13], r15
	ld.w	24[r8], r16
	ld.w	8[r8], r17
	mulf.s	r16, r15, r15
	ld.w	-12[r13], r16
	mulf.s	r17, r16, r16
	ld.w	40[r8], r17
	addf.s	r12, r16, r16
	addf.s	r16, r15, r15
	ld.w	-4[r13], r16
	mulf.s	r17, r16, r16
	ld.w	56[r8], r17
	addf.s	r15, r16, r15
	ld.w	0[r13], r16
	mulf.s	r17, r16, r16
	addf.s	r15, r16, r15
	st.w	r15, 8[r14]
	ld.w	-8[r13], r15
	ld.w	28[r8], r16
	ld.w	12[r8], r17
	mulf.s	r16, r15, r15
	ld.w	-12[r13], r16
	mulf.s	r17, r16, r16
	ld.w	44[r8], r17
	addf.s	r12, r16, r16
	addf.s	r16, r15, r15
	ld.w	-4[r13], r16
	ld.w	0[r13], r13
	mulf.s	r17, r16, r16
	addf.s	r15, r16, r15
	ld.w	60[r8], r16
	mulf.s	r16, r13, r13
	addf.s	r15, r13, r13
	st.w	r13, 12[r14]
	bz	.LBB23_2
	jr	.LBB23_1
.LBB23_2:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end23:
	.size	mat4_mul, .Lfunc_end23-mat4_mul
                                        ; -- End function
	.section	.sdata,"aw",@progbits
	.p2align	2, 0x0                          ; -- Begin function mat4_vec_mul
.LCPI24_0:
	.word	0x00000000                      ; float 0
	.text
	.globl	mat4_vec_mul
	.p2align	2
	.type	mat4_vec_mul,@function
mat4_vec_mul:                           ; @mat4_vec_mul
; %bb.0:                                ; %entry
	ld.w	4[r8], r10
	ld.w	4[r7], r11
	ld.w	0[r7], r12
	ld.w	8[r7], r13
	mulf.s	r10, r11, r10
	ld.w	0[r8], r11
	mulf.s	r11, r12, r11
	movhi	.LCPI24_0, r0, r12
	movea	.LCPI24_0, r12, r12
	ld.w	0[r12], r12
	addf.s	r12, r11, r11
	addf.s	r11, r10, r10
	ld.w	8[r8], r11
	mulf.s	r11, r13, r11
	ld.w	12[r7], r13
	addf.s	r10, r11, r10
	ld.w	12[r8], r11
	mulf.s	r11, r13, r11
	addf.s	r10, r11, r10
	st.w	r10, 0[r6]
	ld.w	4[r8], r10
	ld.w	20[r7], r11
	ld.w	16[r7], r13
	mulf.s	r10, r11, r10
	ld.w	0[r8], r11
	mulf.s	r11, r13, r11
	ld.w	24[r7], r13
	addf.s	r12, r11, r11
	addf.s	r11, r10, r10
	ld.w	8[r8], r11
	mulf.s	r11, r13, r11
	ld.w	28[r7], r13
	addf.s	r10, r11, r10
	ld.w	12[r8], r11
	mulf.s	r11, r13, r11
	addf.s	r10, r11, r10
	st.w	r10, 4[r6]
	ld.w	4[r8], r10
	ld.w	36[r7], r11
	ld.w	32[r7], r13
	mulf.s	r10, r11, r10
	ld.w	0[r8], r11
	mulf.s	r11, r13, r11
	ld.w	40[r7], r13
	addf.s	r12, r11, r11
	addf.s	r11, r10, r10
	ld.w	8[r8], r11
	mulf.s	r11, r13, r11
	ld.w	44[r7], r13
	addf.s	r10, r11, r10
	ld.w	12[r8], r11
	mulf.s	r11, r13, r11
	addf.s	r10, r11, r10
	st.w	r10, 8[r6]
	ld.w	4[r8], r10
	ld.w	52[r7], r11
	ld.w	48[r7], r13
	mulf.s	r10, r11, r10
	ld.w	0[r8], r11
	mulf.s	r11, r13, r11
	addf.s	r12, r11, r11
	ld.w	56[r7], r12
	addf.s	r11, r10, r10
	ld.w	8[r8], r11
	mulf.s	r11, r12, r11
	ld.w	60[r7], r12
	addf.s	r10, r11, r10
	ld.w	12[r8], r11
	mulf.s	r11, r12, r11
	addf.s	r10, r11, r10
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
	.section	.sdata,"aw",@progbits
	.p2align	2, 0x0                          ; -- Begin function vec3_normalize
.LCPI26_0:
	.word	0x3f800000                      ; float 1
.LCPI26_1:
	.word	0x00000000                      ; float 0
.LCPI26_2:
	.word	0xbf000000                      ; float -0.5
.LCPI26_3:
	.word	0x3fc00000                      ; float 1.5
	.text
	.globl	vec3_normalize
	.p2align	2
	.type	vec3_normalize,@function
vec3_normalize:                         ; @vec3_normalize
; %bb.0:                                ; %entry
	ld.w	4[r7], r10
	mulf.s	r10, r10, r11
	ld.w	0[r7], r10
	mulf.s	r10, r10, r12
	addf.s	r11, r12, r11
	ld.w	8[r7], r12
	mulf.s	r12, r12, r12
	addf.s	r11, r12, r11
	movhi	.LCPI26_1, r0, r12
	movea	.LCPI26_1, r12, r12
	ld.w	0[r12], r12
	cmpf.s	7, r12, r11, 0
	trfsr	0
	bz	.LBB26_2
; %bb.1:                                ; %if.then
	movhi	.LCPI26_2, r0, r12
	mov	1597463007, r13
	movea	.LCPI26_2, r12, r12
	ld.w	0[r12], r12
	mulf.s	r12, r11, r12
	shr	1, r11
	sub	r11, r13
	mulf.s	r13, r12, r11
	movhi	.LCPI26_3, r0, r12
	movea	.LCPI26_3, r12, r12
	ld.w	0[r12], r12
	mulf.s	r13, r11, r11
	addf.s	r12, r11, r11
	mulf.s	r13, r11, r11
	jr	.LBB26_3
.LBB26_2:
	movhi	.LCPI26_0, r0, r11
	movea	.LCPI26_0, r11, r11
	ld.w	0[r11], r11
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
	blt	.LBB27_3
; %bb.1:                                ; %for.body.preheader
	add	8, r7
	add	8, r8
.LBB27_2:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	-4[r8], r10
	ld.w	-4[r7], r11
	ld.w	-8[r7], r12
	mulf.s	r10, r11, r10
	ld.w	-8[r8], r11
	mulf.s	r11, r12, r11
	ld.w	0[r7], r12
	add	12, r7
	addf.s	r10, r11, r10
	ld.w	0[r8], r11
	add	12, r8
	mulf.s	r11, r12, r11
	addf.s	r10, r11, r10
	st.w	r10, 0[r6]
	add	4, r6
	loop r9, .LBB27_2
.LBB27_3:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end27:
	.size	batch_dot3, .Lfunc_end27-batch_dot3
                                        ; -- End function
	.globl	batch_cross3_soa                ; -- Begin function batch_cross3_soa
	.p2align	2
	.type	batch_cross3_soa,@function
batch_cross3_soa:                       ; @batch_cross3_soa
; %bb.0:                                ; %entry
	prepare	192, 0
	addi	20, r3, r10
	ld.w	0[r10], r10
	cmp	1, r10
	blt	.LBB28_3
; %bb.1:                                ; %for.body.preheader
	addi	16, r3, r11
	addi	12, r3, r12
	addi	8, r3, r13
	addi	4, r3, r14
	addi	0, r3, r15
	ld.w	0[r11], r11
	ld.w	0[r12], r12
	ld.w	0[r13], r13
	ld.w	0[r14], r14
	ld.w	0[r15], r15
.LBB28_2:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r12], r16
	ld.w	0[r14], r17
	ld.w	0[r11], r19
	ld.w	0[r15], r20
	add	4, r15
	add	4, r11
	add	4, r14
	add	4, r12
	mulf.s	r16, r17, r18
	mulf.s	r19, r20, r21
	subf.s	r18, r21, r18
	ld.w	0[r13], r21
	add	4, r13
	mulf.s	r21, r17, r17
	st.w	r18, 0[r6]
	ld.w	0[r9], r18
	add	4, r6
	add	4, r9
	mulf.s	r19, r18, r19
	mulf.s	r16, r18, r16
	subf.s	r19, r17, r17
	st.w	r17, 0[r7]
	mulf.s	r21, r20, r17
	add	4, r7
	subf.s	r17, r16, r16
	st.w	r16, 0[r8]
	add	4, r8
	loop r10, .LBB28_2
.LBB28_3:                               ; %for.cond.cleanup
	dispose	0, 192, [r31]
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
	ld.w	48[r6], r13
	subf.s	r10, r11, r11
	addi	0, r3, r10
	ld.w	0[r10], r10
	mulf.s	r10, r11, r12
	addf.s	r13, r12, r12
	st.w	r12, 48[r6]
	ld.w	0[r6], r13
	ld.w	16[r6], r14
	mulf.s	r14, r12, r12
	mulf.s	r11, r13, r13
	ld.w	32[r6], r14
	addf.s	r12, r13, r12
	ld.w	64[r6], r13
	subf.s	r13, r11, r13
	divf.s	r10, r13, r13
	mulf.s	r13, r14, r13
	addf.s	r12, r13, r12
	st.w	r12, 0[r7]
	st.w	r11, 64[r6]
	ld.w	4[r9], r11
	ld.w	4[r8], r12
	ld.w	52[r6], r13
	subf.s	r11, r12, r11
	mulf.s	r10, r11, r12
	addf.s	r13, r12, r12
	st.w	r12, 52[r6]
	ld.w	4[r6], r13
	ld.w	20[r6], r14
	mulf.s	r14, r12, r12
	mulf.s	r11, r13, r13
	ld.w	36[r6], r14
	addf.s	r12, r13, r12
	ld.w	68[r6], r13
	subf.s	r13, r11, r13
	divf.s	r10, r13, r13
	mulf.s	r13, r14, r13
	addf.s	r12, r13, r12
	st.w	r12, 4[r7]
	st.w	r11, 68[r6]
	ld.w	8[r9], r11
	ld.w	8[r8], r12
	ld.w	56[r6], r13
	subf.s	r11, r12, r11
	mulf.s	r10, r11, r12
	addf.s	r13, r12, r12
	st.w	r12, 56[r6]
	ld.w	8[r6], r13
	ld.w	24[r6], r14
	mulf.s	r14, r12, r12
	mulf.s	r11, r13, r13
	ld.w	40[r6], r14
	addf.s	r12, r13, r12
	ld.w	72[r6], r13
	subf.s	r13, r11, r13
	divf.s	r10, r13, r13
	mulf.s	r13, r14, r13
	addf.s	r12, r13, r12
	st.w	r12, 8[r7]
	st.w	r11, 72[r6]
	ld.w	12[r9], r11
	ld.w	12[r8], r12
	ld.w	60[r6], r13
	subf.s	r11, r12, r11
	mulf.s	r10, r11, r12
	addf.s	r13, r12, r12
	st.w	r12, 60[r6]
	ld.w	12[r6], r13
	ld.w	28[r6], r14
	mulf.s	r11, r13, r13
	mulf.s	r14, r12, r12
	addf.s	r12, r13, r12
	ld.w	76[r6], r13
	subf.s	r13, r11, r13
	divf.s	r10, r13, r10
	ld.w	44[r6], r13
	mulf.s	r10, r13, r10
	addf.s	r12, r10, r10
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
	ld.w	0[r10], r10
	cmp	1, r10
	blt	.LBB30_2
.LBB30_1:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r7], r11
	ld.w	0[r8], r12
	add	4, r8
	add	4, r7
	mulf.s	r11, r12, r11
	ld.w	0[r9], r12
	add	4, r9
	addf.s	r12, r11, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r10, .LBB30_1
.LBB30_2:                               ; %for.cond.cleanup
	jmp	[r31]
.Lfunc_end30:
	.size	sensor_scale, .Lfunc_end30-sensor_scale
                                        ; -- End function
	.section	.sdata,"aw",@progbits
	.p2align	2, 0x0                          ; -- Begin function sensor_weighted_avg
.LCPI31_0:
	.word	0x00000000                      ; float 0
	.text
	.globl	sensor_weighted_avg
	.p2align	2
	.type	sensor_weighted_avg,@function
sensor_weighted_avg:                    ; @sensor_weighted_avg
; %bb.0:                                ; %entry
	ld.w	0[r7], r12
	ld.w	0[r6], r13
	movhi	.LCPI31_0, r0, r14
	ld.w	4[r7], r10
	ld.w	4[r6], r11
	ld.w	8[r6], r15
	ld.w	12[r6], r16
	movea	.LCPI31_0, r14, r14
	ld.w	0[r14], r14
	mulf.s	r12, r13, r13
	mulf.s	r10, r11, r11
	addf.s	r14, r12, r12
	addf.s	r14, r13, r13
	addf.s	r10, r12, r10
	addf.s	r13, r11, r11
	ld.w	8[r7], r13
	mulf.s	r13, r15, r15
	addf.s	r13, r10, r10
	addf.s	r11, r15, r11
	ld.w	12[r7], r15
	mulf.s	r15, r16, r16
	addf.s	r15, r10, r10
	addf.s	r11, r16, r11
	divf.s	r10, r11, r10
	jmp	[r31]
.Lfunc_end31:
	.size	sensor_weighted_avg, .Lfunc_end31-sensor_weighted_avg
                                        ; -- End function
	.section	.sdata,"aw",@progbits
	.p2align	2, 0x0                          ; -- Begin function stereo_to_mono
.LCPI32_0:
	.word	0x3f000000                      ; float 0.5
	.text
	.globl	stereo_to_mono
	.p2align	2
	.type	stereo_to_mono,@function
stereo_to_mono:                         ; @stereo_to_mono
; %bb.0:                                ; %entry
	cmp	1, r8
	blt	.LBB32_3
; %bb.1:                                ; %for.body.preheader
	movhi	.LCPI32_0, r0, r10
	add	4, r7
	movea	.LCPI32_0, r10, r10
	ld.w	0[r10], r10
.LBB32_2:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r7], r11
	ld.w	-4[r7], r12
	add	8, r7
	addf.s	r11, r12, r11
	mulf.s	r10, r11, r11
	st.w	r11, 0[r6]
	add	4, r6
	loop r8, .LBB32_2
.LBB32_3:                               ; %for.cond.cleanup
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
	blt	.LBB33_2
.LBB33_1:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r6], r10
	mulf.s	r10, r7, r10
	st.w	r10, 0[r6]
	add	4, r6
	loop r8, .LBB33_1
.LBB33_2:                               ; %for.cond.cleanup
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
	ld.w	0[r10], r10
	cmp	1, r10
	blt	.LBB34_3
; %bb.1:                                ; %for.body.preheader
	addi	0, r3, r11
	ld.w	0[r11], r11
.LBB34_2:                               ; %for.body
                                        ; =>This Inner Loop Header: Depth=1
	ld.w	0[r9], r12
	ld.w	0[r7], r13
	add	4, r7
	add	4, r9
	mulf.s	r12, r11, r12
	mulf.s	r8, r13, r13
	addf.s	r12, r13, r12
	st.w	r12, 0[r6]
	add	4, r6
	loop r10, .LBB34_2
.LBB34_3:                               ; %for.cond.cleanup
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
	ld.w	0[r8], r10
	ld.w	0[r7], r11
	mulf.s	r10, r11, r10
	ld.w	0[r9], r11
	addf.s	r11, r10, r10
	st.w	r10, 0[r6]
	ld.w	4[r8], r10
	ld.w	4[r7], r11
	mulf.s	r10, r11, r10
	ld.w	4[r9], r11
	addf.s	r11, r10, r10
	st.w	r10, 4[r6]
	ld.w	8[r8], r10
	ld.w	8[r7], r11
	mulf.s	r10, r11, r10
	ld.w	8[r9], r11
	addf.s	r11, r10, r10
	st.w	r10, 8[r6]
	ld.w	12[r8], r10
	ld.w	12[r7], r11
	mulf.s	r10, r11, r10
	ld.w	12[r9], r11
	addf.s	r11, r10, r10
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
	ld.w	0[r6], r12
	mulf.s	r10, r11, r10
	ld.w	0[r7], r11
	mulf.s	r11, r12, r11
	ld.w	8[r6], r12
	addf.s	r10, r11, r10
	ld.w	8[r7], r11
	mulf.s	r11, r12, r11
	ld.w	12[r6], r12
	addf.s	r10, r11, r10
	ld.w	12[r7], r11
	mulf.s	r11, r12, r11
	addf.s	r10, r11, r10
	jmp	[r31]
.Lfunc_end38:
	.size	dot4, .Lfunc_end38-dot4
                                        ; -- End function
	.globl	saxpy4                          ; -- Begin function saxpy4
	.p2align	2
	.type	saxpy4,@function
saxpy4:                                 ; @saxpy4
; %bb.0:                                ; %entry
	ld.w	0[r8], r10
	ld.w	0[r6], r11
	mulf.s	r10, r7, r10
	addf.s	r11, r10, r10
	st.w	r10, 0[r6]
	ld.w	4[r8], r10
	ld.w	4[r6], r11
	mulf.s	r10, r7, r10
	addf.s	r11, r10, r10
	st.w	r10, 4[r6]
	ld.w	8[r8], r10
	ld.w	8[r6], r11
	mulf.s	r10, r7, r10
	addf.s	r11, r10, r10
	st.w	r10, 8[r6]
	ld.w	12[r8], r10
	ld.w	12[r6], r11
	mulf.s	r10, r7, r10
	addf.s	r11, r10, r10
	st.w	r10, 12[r6]
	jmp	[r31]
.Lfunc_end39:
	.size	saxpy4, .Lfunc_end39-saxpy4
                                        ; -- End function
	.ident	"clang version 21.1.8 (git@github.com:lfazio/llvm-project-v850.git bec441f749ae522442d6d05c5e23cfa8d4919190)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
