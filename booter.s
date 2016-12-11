
booter.o:     file format elf32-tradlittlemips

Disassembly of section .text:

bfc00000 <_start>:
bfc00000:	3c1d8080 	lui	sp,0x8080
bfc00004:	241f0000 	li	ra,0
bfc00008:	241e0000 	li	s8,0
bfc0000c:	0bf00004 	j	bfc00010 <init>

bfc00010 <init>:
bfc00010:	27bdffd8 	addiu	sp,sp,-40
bfc00014:	afbf0024 	sw	ra,36(sp)
bfc00018:	afbe0020 	sw	s8,32(sp)
bfc0001c:	03a0f021 	move	s8,sp
bfc00020:	3c02bfc0 	lui	v0,0xbfc0
bfc00024:	0ff00060 	jal	bfc00180 <printStr>
bfc00028:	24440214 	addiu	a0,v0,532
bfc0002c:	3c02bfc0 	lui	v0,0xbfc0
bfc00030:	0ff00060 	jal	bfc00180 <printStr>
bfc00034:	24440224 	addiu	a0,v0,548
bfc00038:	3c02bfc0 	lui	v0,0xbfc0
bfc0003c:	0ff00060 	jal	bfc00180 <printStr>
bfc00040:	24440238 	addiu	a0,v0,568
bfc00044:	3c02bfc0 	lui	v0,0xbfc0
bfc00048:	8c4302a0 	lw	v1,672(v0)
bfc0004c:	00601021 	move	v0,v1
bfc00050:	40827801 	mtc0	v0,$15,1
bfc00054:	3c02bfc0 	lui	v0,0xbfc0
bfc00058:	8c42028c 	lw	v0,652(v0)
bfc0005c:	afc20018 	sw	v0,24(s8)
bfc00060:	3c02bfc0 	lui	v0,0xbfc0
bfc00064:	8c420290 	lw	v0,656(v0)
bfc00068:	afc20014 	sw	v0,20(s8)
bfc0006c:	0bf0002a 	j	bfc000a8 <init+0x98>
bfc00070:	afc00010 	sw	zero,16(s8)
bfc00074:	8fc20018 	lw	v0,24(s8)
bfc00078:	8c430000 	lw	v1,0(v0)
bfc0007c:	8fc20014 	lw	v0,20(s8)
bfc00080:	ac430000 	sw	v1,0(v0)
bfc00084:	8fc20010 	lw	v0,16(s8)
bfc00088:	24420001 	addiu	v0,v0,1
bfc0008c:	afc20010 	sw	v0,16(s8)
bfc00090:	8fc20018 	lw	v0,24(s8)
bfc00094:	24420004 	addiu	v0,v0,4
bfc00098:	afc20018 	sw	v0,24(s8)
bfc0009c:	8fc20014 	lw	v0,20(s8)
bfc000a0:	24420004 	addiu	v0,v0,4
bfc000a4:	afc20014 	sw	v0,20(s8)
bfc000a8:	8fc30010 	lw	v1,16(s8)
bfc000ac:	3c02bfc0 	lui	v0,0xbfc0
bfc000b0:	8c42029c 	lw	v0,668(v0)
bfc000b4:	00021200 	sll	v0,v0,0x8
bfc000b8:	0062102b 	sltu	v0,v1,v0
bfc000bc:	1440ffed 	bnez	v0,bfc00074 <init+0x64>
bfc000c0:	3c02bfc0 	lui	v0,0xbfc0
bfc000c4:	0bf0003d 	j	bfc000f4 <init+0xe4>
bfc000c8:	8c420298 	lw	v0,664(v0)
bfc000cc:	ac400000 	sw	zero,0(v0)
bfc000d0:	8fc20010 	lw	v0,16(s8)
bfc000d4:	24420001 	addiu	v0,v0,1
bfc000d8:	afc20010 	sw	v0,16(s8)
bfc000dc:	8fc20014 	lw	v0,20(s8)
bfc000e0:	24420004 	addiu	v0,v0,4
bfc000e4:	afc20014 	sw	v0,20(s8)
bfc000e8:	8fc30010 	lw	v1,16(s8)
bfc000ec:	3c02bfc0 	lui	v0,0xbfc0
bfc000f0:	8c420298 	lw	v0,664(v0)
bfc000f4:	00021200 	sll	v0,v0,0x8
bfc000f8:	0062102b 	sltu	v0,v1,v0
bfc000fc:	1440fff3 	bnez	v0,bfc000cc <init+0xbc>
bfc00100:	8fc20014 	lw	v0,20(s8)
bfc00104:	3c02bfc0 	lui	v0,0xbfc0
bfc00108:	0ff00060 	jal	bfc00180 <printStr>
bfc0010c:	24440250 	addiu	a0,v0,592
bfc00110:	3c02bfc0 	lui	v0,0xbfc0
bfc00114:	8c430294 	lw	v1,660(v0)
bfc00118:	00601021 	move	v0,v1
bfc0011c:	00400008 	jr	v0
bfc00120:	03c0e821 	move	sp,s8
bfc00124:	8fbf0024 	lw	ra,36(sp)
bfc00128:	8fbe0020 	lw	s8,32(sp)
bfc0012c:	03e00008 	jr	ra
bfc00130:	27bd0028 	addiu	sp,sp,40

bfc00134 <printCh>:
bfc00134:	27bdfff8 	addiu	sp,sp,-8
bfc00138:	afbe0004 	sw	s8,4(sp)
bfc0013c:	03a0f021 	move	s8,sp
bfc00140:	00801021 	move	v0,a0
bfc00144:	a3c20008 	sb	v0,8(s8)
bfc00148:	3c02bfc0 	lui	v0,0xbfc0
bfc0014c:	8c420288 	lw	v0,648(v0)
bfc00150:	24420004 	addiu	v0,v0,4
bfc00154:	90420000 	lbu	v0,0(v0)
bfc00158:	30420001 	andi	v0,v0,0x1
bfc0015c:	1040fffb 	beqz	v0,bfc0014c <printCh+0x18>
bfc00160:	3c02bfc0 	lui	v0,0xbfc0
bfc00164:	8c430288 	lw	v1,648(v0)
bfc00168:	93c20008 	lbu	v0,8(s8)
bfc0016c:	a0620000 	sb	v0,0(v1)
bfc00170:	03c0e821 	move	sp,s8
bfc00174:	8fbe0004 	lw	s8,4(sp)
bfc00178:	03e00008 	jr	ra
bfc0017c:	27bd0008 	addiu	sp,sp,8

bfc00180 <printStr>:
bfc00180:	27bdffe8 	addiu	sp,sp,-24
bfc00184:	afbf0014 	sw	ra,20(sp)
bfc00188:	afbe0010 	sw	s8,16(sp)
bfc0018c:	03a0f021 	move	s8,sp
bfc00190:	0bf0006d 	j	bfc001b4 <printStr+0x34>
bfc00194:	afc40018 	sw	a0,24(s8)
bfc00198:	8fc20018 	lw	v0,24(s8)
bfc0019c:	90420000 	lbu	v0,0(v0)
bfc001a0:	0ff0004d 	jal	bfc00134 <printCh>
bfc001a4:	00402021 	move	a0,v0
bfc001a8:	8fc20018 	lw	v0,24(s8)
bfc001ac:	24420001 	addiu	v0,v0,1
bfc001b0:	afc20018 	sw	v0,24(s8)
bfc001b4:	8fc20018 	lw	v0,24(s8)
bfc001b8:	90420000 	lbu	v0,0(v0)
bfc001bc:	1440fff6 	bnez	v0,bfc00198 <printStr+0x18>
bfc001c0:	8fdf0014 	lw	ra,20(s8)
bfc001c4:	03c0e821 	move	sp,s8
bfc001c8:	8fbe0010 	lw	s8,16(sp)
bfc001cc:	03e00008 	jr	ra
bfc001d0:	27bd0018 	addiu	sp,sp,24

bfc001d4 <readCh>:
bfc001d4:	27bdfff8 	addiu	sp,sp,-8
bfc001d8:	afbe0004 	sw	s8,4(sp)
bfc001dc:	03a0f021 	move	s8,sp
bfc001e0:	3c02bfc0 	lui	v0,0xbfc0
bfc001e4:	8c420288 	lw	v0,648(v0)
bfc001e8:	24420004 	addiu	v0,v0,4
bfc001ec:	90420000 	lbu	v0,0(v0)
bfc001f0:	30420002 	andi	v0,v0,0x2
bfc001f4:	1040fffb 	beqz	v0,bfc001e4 <readCh+0x10>
bfc001f8:	3c02bfc0 	lui	v0,0xbfc0
bfc001fc:	8c420288 	lw	v0,648(v0)
bfc00200:	90420000 	lbu	v0,0(v0)
bfc00204:	03c0e821 	move	sp,s8
bfc00208:	8fbe0004 	lw	s8,4(sp)
bfc0020c:	03e00008 	jr	ra
bfc00210:	27bd0008 	addiu	sp,sp,8
Disassembly of section .err:

bfc00800 <error>:
bfc00800:	27bdffe0 	addiu	sp,sp,-32
bfc00804:	afbf001c 	sw	ra,28(sp)
bfc00808:	afbe0018 	sw	s8,24(sp)
bfc0080c:	03a0f021 	move	s8,sp
bfc00810:	3c02bfc0 	lui	v0,0xbfc0
bfc00814:	0ff00060 	jal	bfc00180 <printStr>
bfc00818:	24440260 	addiu	a0,v0,608
bfc0081c:	3c02bfc0 	lui	v0,0xbfc0
bfc00820:	0ff00060 	jal	bfc00180 <printStr>
bfc00824:	24440270 	addiu	a0,v0,624
bfc00828:	0ff00075 	jal	bfc001d4 <readCh>
bfc0082c:	00000000 	nop
bfc00830:	a3c20010 	sb	v0,16(s8)
bfc00834:	93c30010 	lbu	v1,16(s8)
bfc00838:	24020052 	li	v0,82
bfc0083c:	10620003 	beq	v1,v0,bfc0084c <error+0x4c>
bfc00840:	24020072 	li	v0,114
bfc00844:	1462fff8 	bne	v1,v0,bfc00828 <error+0x28>
bfc00848:	00000000 	nop
bfc0084c:	3c02bfc0 	lui	v0,0xbfc0
bfc00850:	8c4302a4 	lw	v1,676(v0)
bfc00854:	00601021 	move	v0,v1
bfc00858:	00400008 	jr	v0
bfc0085c:	03c0e821 	move	sp,s8
bfc00860:	8fbf001c 	lw	ra,28(sp)
bfc00864:	8fbe0018 	lw	s8,24(sp)
bfc00868:	03e00008 	jr	ra
bfc0086c:	27bd0020 	addiu	sp,sp,32
Disassembly of section .rodata:

bfc00214 <.rodata>:
bfc00214:	6d6d6153 	0x6d6d6153
bfc00218:	20676e69 	addi	a3,v1,28265
bfc0021c:	0a555043 	j	b955410c <_start-0x66abef4>
bfc00220:	00000000 	nop
bfc00224:	457e7e7e 	0x457e7e7e
bfc00228:	6772656e 	0x6772656e
bfc0022c:	6f4d2079 	0x6f4d2079
bfc00230:	7e7e6e6f 	0x7e7e6e6f
bfc00234:	00000a7e 	0xa7e
bfc00238:	2a2a2a2a 	slti	t2,s1,10794
bfc0023c:	4f4c202a 	c3	0x14c202a
bfc00240:	4e494441 	c3	0x494441
bfc00244:	2e2e2e47 	sltiu	t6,s1,11847
bfc00248:	2a2a2a20 	slti	t2,s1,10784
bfc0024c:	000a2a2a 	0xa2a2a
bfc00250:	44414f4c 	0x44414f4c
bfc00254:	20474e49 	addi	a3,v0,20041
bfc00258:	696e6966 	0x696e6966
bfc0025c:	000a6873 	tltu	zero,t2,0x1a1
bfc00260:	746f6f42 	jalx	b1bdbd08 <_start-0xe0242f8>
bfc00264:	72726520 	0x72726520
bfc00268:	0a2e726f 	j	b8b9c9bc <_start-0x7063644>
bfc0026c:	00000000 	nop
bfc00270:	73657250 	0x73657250
bfc00274:	20522073 	addi	s2,v0,8307
bfc00278:	72206f74 	0x72206f74
bfc0027c:	61747365 	0x61747365
bfc00280:	0a2e7472 	j	b8b9d1c8 <_start-0x7062e38>
bfc00284:	00000000 	nop
Disassembly of section .data:

bfc00288 <COMM1>:
bfc00288:	bfd003f8 	cache	0x10,1016(s8)

bfc0028c <SOURCE>:
bfc0028c:	be000000 	cache	0x0,0(s0)

bfc00290 <END>:
bfc00290:	80000000 	lb	zero,0(zero)

bfc00294 <RUN_START>:
bfc00294:	80000000 	lb	zero,0(zero)

bfc00298 <COPY_LEN>:
bfc00298:	00001000 	sll	v0,zero,0x0

bfc0029c <UCORE_LEN>:
bfc0029c:	00000800 	sll	at,zero,0x0

bfc002a0 <ERROR_ADDR>:
bfc002a0:	bfc00800 	cache	0x0,2048(s8)

bfc002a4 <BOOT_ADDR>:
bfc002a4:	bfc00000 	cache	0x0,0(s8)
Disassembly of section .reginfo:

00000000 <.reginfo>:
   0:	e0000000 	sc	zero,0(zero)
	...
Disassembly of section .pdr:

00000000 <.pdr>:
   0:	bfc00010 	cache	0x0,16(s8)
   4:	c0000000 	ll	zero,0(zero)
   8:	fffffffc 	sdc3	$31,-4(ra)
	...
  14:	00000028 	0x28
  18:	0000001e 	0x1e
  1c:	0000001f 	0x1f
  20:	bfc00134 	cache	0x0,308(s8)
  24:	40000000 	mfc0	zero,c0_index
  28:	fffffffc 	sdc3	$31,-4(ra)
	...
  34:	00000008 	jr	zero
  38:	0000001e 	0x1e
  3c:	0000001f 	0x1f
  40:	bfc00180 	cache	0x0,384(s8)
  44:	c0000000 	ll	zero,0(zero)
  48:	fffffffc 	sdc3	$31,-4(ra)
	...
  54:	00000018 	mult	zero,zero
  58:	0000001e 	0x1e
  5c:	0000001f 	0x1f
  60:	bfc001d4 	cache	0x0,468(s8)
  64:	40000000 	mfc0	zero,c0_index
  68:	fffffffc 	sdc3	$31,-4(ra)
	...
  74:	00000008 	jr	zero
  78:	0000001e 	0x1e
  7c:	0000001f 	0x1f
  80:	bfc00800 	cache	0x0,2048(s8)
  84:	c0000000 	ll	zero,0(zero)
  88:	fffffffc 	sdc3	$31,-4(ra)
	...
  94:	00000020 	add	zero,zero,zero
  98:	0000001e 	0x1e
  9c:	0000001f 	0x1f
Disassembly of section .comment:

00000000 <.comment>:
   0:	43434700 	c0	0x1434700
   4:	5328203a 	beql	t9,t0,80f0 <_start-0xbfbf7f10>
   8:	6372756f 	0x6372756f
   c:	20797265 	addi	t9,v1,29285
  10:	202b2b47 	addi	t3,at,11079
  14:	6574694c 	0x6574694c
  18:	332e3420 	andi	t6,t9,0x3420
  1c:	2931382d 	slti	s1,t1,14381
  20:	332e3420 	andi	t6,t9,0x3420
  24:	Address 0x0000000000000024 is out of bounds.

Disassembly of section .gnu.attributes:

00000000 <.gnu.attributes>:
   0:	00000f41 	0xf41
   4:	756e6700 	jalx	5b99c00 <_start-0xba066400>
   8:	00070100 	sll	zero,a3,0x4
   c:	01040000 	0x1040000
