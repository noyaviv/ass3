
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	18010113          	addi	sp,sp,384 # 8000a180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	0000a717          	auipc	a4,0xa
    80000056:	fee70713          	addi	a4,a4,-18 # 8000a040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00007797          	auipc	a5,0x7
    80000068:	a1c78793          	addi	a5,a5,-1508 # 80006a80 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd07ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dbe78793          	addi	a5,a5,-578 # 80000e6c <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00003097          	auipc	ra,0x3
    80000122:	cf2080e7          	jalr	-782(ra) # 80002e10 <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	77a080e7          	jalr	1914(ra) # 800008a8 <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7159                	addi	sp,sp,-112
    80000158:	f486                	sd	ra,104(sp)
    8000015a:	f0a2                	sd	s0,96(sp)
    8000015c:	eca6                	sd	s1,88(sp)
    8000015e:	e8ca                	sd	s2,80(sp)
    80000160:	e4ce                	sd	s3,72(sp)
    80000162:	e0d2                	sd	s4,64(sp)
    80000164:	fc56                	sd	s5,56(sp)
    80000166:	f85a                	sd	s6,48(sp)
    80000168:	f45e                	sd	s7,40(sp)
    8000016a:	f062                	sd	s8,32(sp)
    8000016c:	ec66                	sd	s9,24(sp)
    8000016e:	e86a                	sd	s10,16(sp)
    80000170:	1880                	addi	s0,sp,112
    80000172:	8aaa                	mv	s5,a0
    80000174:	8a2e                	mv	s4,a1
    80000176:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000178:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000017c:	00012517          	auipc	a0,0x12
    80000180:	00450513          	addi	a0,a0,4 # 80012180 <cons>
    80000184:	00001097          	auipc	ra,0x1
    80000188:	a3e080e7          	jalr	-1474(ra) # 80000bc2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018c:	00012497          	auipc	s1,0x12
    80000190:	ff448493          	addi	s1,s1,-12 # 80012180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000194:	00012917          	auipc	s2,0x12
    80000198:	08490913          	addi	s2,s2,132 # 80012218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    8000019c:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000019e:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a0:	4ca9                	li	s9,10
  while(n > 0){
    800001a2:	07305863          	blez	s3,80000212 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001a6:	0984a783          	lw	a5,152(s1)
    800001aa:	09c4a703          	lw	a4,156(s1)
    800001ae:	02f71463          	bne	a4,a5,800001d6 <consoleread+0x80>
      if(myproc()->killed){
    800001b2:	00002097          	auipc	ra,0x2
    800001b6:	052080e7          	jalr	82(ra) # 80002204 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00003097          	auipc	ra,0x3
    800001c6:	83e080e7          	jalr	-1986(ra) # 80002a00 <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef700e3          	beq	a4,a5,800001b2 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001d6:	0017871b          	addiw	a4,a5,1
    800001da:	08e4ac23          	sw	a4,152(s1)
    800001de:	07f7f713          	andi	a4,a5,127
    800001e2:	9726                	add	a4,a4,s1
    800001e4:	01874703          	lbu	a4,24(a4)
    800001e8:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001ec:	077d0563          	beq	s10,s7,80000256 <consoleread+0x100>
    cbuf = c;
    800001f0:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f4:	4685                	li	a3,1
    800001f6:	f9f40613          	addi	a2,s0,-97
    800001fa:	85d2                	mv	a1,s4
    800001fc:	8556                	mv	a0,s5
    800001fe:	00003097          	auipc	ra,0x3
    80000202:	bbc080e7          	jalr	-1092(ra) # 80002dba <either_copyout>
    80000206:	01850663          	beq	a0,s8,80000212 <consoleread+0xbc>
    dst++;
    8000020a:	0a05                	addi	s4,s4,1
    --n;
    8000020c:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000020e:	f99d1ae3          	bne	s10,s9,800001a2 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000212:	00012517          	auipc	a0,0x12
    80000216:	f6e50513          	addi	a0,a0,-146 # 80012180 <cons>
    8000021a:	00001097          	auipc	ra,0x1
    8000021e:	a5c080e7          	jalr	-1444(ra) # 80000c76 <release>

  return target - n;
    80000222:	413b053b          	subw	a0,s6,s3
    80000226:	a811                	j	8000023a <consoleread+0xe4>
        release(&cons.lock);
    80000228:	00012517          	auipc	a0,0x12
    8000022c:	f5850513          	addi	a0,a0,-168 # 80012180 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a46080e7          	jalr	-1466(ra) # 80000c76 <release>
        return -1;
    80000238:	557d                	li	a0,-1
}
    8000023a:	70a6                	ld	ra,104(sp)
    8000023c:	7406                	ld	s0,96(sp)
    8000023e:	64e6                	ld	s1,88(sp)
    80000240:	6946                	ld	s2,80(sp)
    80000242:	69a6                	ld	s3,72(sp)
    80000244:	6a06                	ld	s4,64(sp)
    80000246:	7ae2                	ld	s5,56(sp)
    80000248:	7b42                	ld	s6,48(sp)
    8000024a:	7ba2                	ld	s7,40(sp)
    8000024c:	7c02                	ld	s8,32(sp)
    8000024e:	6ce2                	ld	s9,24(sp)
    80000250:	6d42                	ld	s10,16(sp)
    80000252:	6165                	addi	sp,sp,112
    80000254:	8082                	ret
      if(n < target){
    80000256:	0009871b          	sext.w	a4,s3
    8000025a:	fb677ce3          	bgeu	a4,s6,80000212 <consoleread+0xbc>
        cons.r--;
    8000025e:	00012717          	auipc	a4,0x12
    80000262:	faf72d23          	sw	a5,-70(a4) # 80012218 <cons+0x98>
    80000266:	b775                	j	80000212 <consoleread+0xbc>

0000000080000268 <consputc>:
{
    80000268:	1141                	addi	sp,sp,-16
    8000026a:	e406                	sd	ra,8(sp)
    8000026c:	e022                	sd	s0,0(sp)
    8000026e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000270:	10000793          	li	a5,256
    80000274:	00f50a63          	beq	a0,a5,80000288 <consputc+0x20>
    uartputc_sync(c);
    80000278:	00000097          	auipc	ra,0x0
    8000027c:	55e080e7          	jalr	1374(ra) # 800007d6 <uartputc_sync>
}
    80000280:	60a2                	ld	ra,8(sp)
    80000282:	6402                	ld	s0,0(sp)
    80000284:	0141                	addi	sp,sp,16
    80000286:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000288:	4521                	li	a0,8
    8000028a:	00000097          	auipc	ra,0x0
    8000028e:	54c080e7          	jalr	1356(ra) # 800007d6 <uartputc_sync>
    80000292:	02000513          	li	a0,32
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	540080e7          	jalr	1344(ra) # 800007d6 <uartputc_sync>
    8000029e:	4521                	li	a0,8
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	536080e7          	jalr	1334(ra) # 800007d6 <uartputc_sync>
    800002a8:	bfe1                	j	80000280 <consputc+0x18>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	e04a                	sd	s2,0(sp)
    800002b4:	1000                	addi	s0,sp,32
    800002b6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b8:	00012517          	auipc	a0,0x12
    800002bc:	ec850513          	addi	a0,a0,-312 # 80012180 <cons>
    800002c0:	00001097          	auipc	ra,0x1
    800002c4:	902080e7          	jalr	-1790(ra) # 80000bc2 <acquire>

  switch(c){
    800002c8:	47d5                	li	a5,21
    800002ca:	0af48663          	beq	s1,a5,80000376 <consoleintr+0xcc>
    800002ce:	0297ca63          	blt	a5,s1,80000302 <consoleintr+0x58>
    800002d2:	47a1                	li	a5,8
    800002d4:	0ef48763          	beq	s1,a5,800003c2 <consoleintr+0x118>
    800002d8:	47c1                	li	a5,16
    800002da:	10f49a63          	bne	s1,a5,800003ee <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002de:	00003097          	auipc	ra,0x3
    800002e2:	b88080e7          	jalr	-1144(ra) # 80002e66 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002e6:	00012517          	auipc	a0,0x12
    800002ea:	e9a50513          	addi	a0,a0,-358 # 80012180 <cons>
    800002ee:	00001097          	auipc	ra,0x1
    800002f2:	988080e7          	jalr	-1656(ra) # 80000c76 <release>
}
    800002f6:	60e2                	ld	ra,24(sp)
    800002f8:	6442                	ld	s0,16(sp)
    800002fa:	64a2                	ld	s1,8(sp)
    800002fc:	6902                	ld	s2,0(sp)
    800002fe:	6105                	addi	sp,sp,32
    80000300:	8082                	ret
  switch(c){
    80000302:	07f00793          	li	a5,127
    80000306:	0af48e63          	beq	s1,a5,800003c2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000030a:	00012717          	auipc	a4,0x12
    8000030e:	e7670713          	addi	a4,a4,-394 # 80012180 <cons>
    80000312:	0a072783          	lw	a5,160(a4)
    80000316:	09872703          	lw	a4,152(a4)
    8000031a:	9f99                	subw	a5,a5,a4
    8000031c:	07f00713          	li	a4,127
    80000320:	fcf763e3          	bltu	a4,a5,800002e6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000324:	47b5                	li	a5,13
    80000326:	0cf48763          	beq	s1,a5,800003f4 <consoleintr+0x14a>
      consputc(c);
    8000032a:	8526                	mv	a0,s1
    8000032c:	00000097          	auipc	ra,0x0
    80000330:	f3c080e7          	jalr	-196(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000334:	00012797          	auipc	a5,0x12
    80000338:	e4c78793          	addi	a5,a5,-436 # 80012180 <cons>
    8000033c:	0a07a703          	lw	a4,160(a5)
    80000340:	0017069b          	addiw	a3,a4,1
    80000344:	0006861b          	sext.w	a2,a3
    80000348:	0ad7a023          	sw	a3,160(a5)
    8000034c:	07f77713          	andi	a4,a4,127
    80000350:	97ba                	add	a5,a5,a4
    80000352:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000356:	47a9                	li	a5,10
    80000358:	0cf48563          	beq	s1,a5,80000422 <consoleintr+0x178>
    8000035c:	4791                	li	a5,4
    8000035e:	0cf48263          	beq	s1,a5,80000422 <consoleintr+0x178>
    80000362:	00012797          	auipc	a5,0x12
    80000366:	eb67a783          	lw	a5,-330(a5) # 80012218 <cons+0x98>
    8000036a:	0807879b          	addiw	a5,a5,128
    8000036e:	f6f61ce3          	bne	a2,a5,800002e6 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000372:	863e                	mv	a2,a5
    80000374:	a07d                	j	80000422 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000376:	00012717          	auipc	a4,0x12
    8000037a:	e0a70713          	addi	a4,a4,-502 # 80012180 <cons>
    8000037e:	0a072783          	lw	a5,160(a4)
    80000382:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000386:	00012497          	auipc	s1,0x12
    8000038a:	dfa48493          	addi	s1,s1,-518 # 80012180 <cons>
    while(cons.e != cons.w &&
    8000038e:	4929                	li	s2,10
    80000390:	f4f70be3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	37fd                	addiw	a5,a5,-1
    80000396:	07f7f713          	andi	a4,a5,127
    8000039a:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000039c:	01874703          	lbu	a4,24(a4)
    800003a0:	f52703e3          	beq	a4,s2,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003a4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003a8:	10000513          	li	a0,256
    800003ac:	00000097          	auipc	ra,0x0
    800003b0:	ebc080e7          	jalr	-324(ra) # 80000268 <consputc>
    while(cons.e != cons.w &&
    800003b4:	0a04a783          	lw	a5,160(s1)
    800003b8:	09c4a703          	lw	a4,156(s1)
    800003bc:	fcf71ce3          	bne	a4,a5,80000394 <consoleintr+0xea>
    800003c0:	b71d                	j	800002e6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c2:	00012717          	auipc	a4,0x12
    800003c6:	dbe70713          	addi	a4,a4,-578 # 80012180 <cons>
    800003ca:	0a072783          	lw	a5,160(a4)
    800003ce:	09c72703          	lw	a4,156(a4)
    800003d2:	f0f70ae3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003d6:	37fd                	addiw	a5,a5,-1
    800003d8:	00012717          	auipc	a4,0x12
    800003dc:	e4f72423          	sw	a5,-440(a4) # 80012220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e0:	10000513          	li	a0,256
    800003e4:	00000097          	auipc	ra,0x0
    800003e8:	e84080e7          	jalr	-380(ra) # 80000268 <consputc>
    800003ec:	bded                	j	800002e6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003ee:	ee048ce3          	beqz	s1,800002e6 <consoleintr+0x3c>
    800003f2:	bf21                	j	8000030a <consoleintr+0x60>
      consputc(c);
    800003f4:	4529                	li	a0,10
    800003f6:	00000097          	auipc	ra,0x0
    800003fa:	e72080e7          	jalr	-398(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    800003fe:	00012797          	auipc	a5,0x12
    80000402:	d8278793          	addi	a5,a5,-638 # 80012180 <cons>
    80000406:	0a07a703          	lw	a4,160(a5)
    8000040a:	0017069b          	addiw	a3,a4,1
    8000040e:	0006861b          	sext.w	a2,a3
    80000412:	0ad7a023          	sw	a3,160(a5)
    80000416:	07f77713          	andi	a4,a4,127
    8000041a:	97ba                	add	a5,a5,a4
    8000041c:	4729                	li	a4,10
    8000041e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000422:	00012797          	auipc	a5,0x12
    80000426:	dec7ad23          	sw	a2,-518(a5) # 8001221c <cons+0x9c>
        wakeup(&cons.r);
    8000042a:	00012517          	auipc	a0,0x12
    8000042e:	dee50513          	addi	a0,a0,-530 # 80012218 <cons+0x98>
    80000432:	00002097          	auipc	ra,0x2
    80000436:	75a080e7          	jalr	1882(ra) # 80002b8c <wakeup>
    8000043a:	b575                	j	800002e6 <consoleintr+0x3c>

000000008000043c <consoleinit>:

void
consoleinit(void)
{
    8000043c:	1141                	addi	sp,sp,-16
    8000043e:	e406                	sd	ra,8(sp)
    80000440:	e022                	sd	s0,0(sp)
    80000442:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000444:	00009597          	auipc	a1,0x9
    80000448:	bcc58593          	addi	a1,a1,-1076 # 80009010 <etext+0x10>
    8000044c:	00012517          	auipc	a0,0x12
    80000450:	d3450513          	addi	a0,a0,-716 # 80012180 <cons>
    80000454:	00000097          	auipc	ra,0x0
    80000458:	6de080e7          	jalr	1758(ra) # 80000b32 <initlock>

  uartinit();
    8000045c:	00000097          	auipc	ra,0x0
    80000460:	32a080e7          	jalr	810(ra) # 80000786 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000464:	00029797          	auipc	a5,0x29
    80000468:	4b478793          	addi	a5,a5,1204 # 80029918 <devsw>
    8000046c:	00000717          	auipc	a4,0x0
    80000470:	cea70713          	addi	a4,a4,-790 # 80000156 <consoleread>
    80000474:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000476:	00000717          	auipc	a4,0x0
    8000047a:	c7e70713          	addi	a4,a4,-898 # 800000f4 <consolewrite>
    8000047e:	ef98                	sd	a4,24(a5)
}
    80000480:	60a2                	ld	ra,8(sp)
    80000482:	6402                	ld	s0,0(sp)
    80000484:	0141                	addi	sp,sp,16
    80000486:	8082                	ret

0000000080000488 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000488:	7179                	addi	sp,sp,-48
    8000048a:	f406                	sd	ra,40(sp)
    8000048c:	f022                	sd	s0,32(sp)
    8000048e:	ec26                	sd	s1,24(sp)
    80000490:	e84a                	sd	s2,16(sp)
    80000492:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000494:	c219                	beqz	a2,8000049a <printint+0x12>
    80000496:	08054663          	bltz	a0,80000522 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    8000049a:	2501                	sext.w	a0,a0
    8000049c:	4881                	li	a7,0
    8000049e:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004a4:	2581                	sext.w	a1,a1
    800004a6:	00009617          	auipc	a2,0x9
    800004aa:	b9a60613          	addi	a2,a2,-1126 # 80009040 <digits>
    800004ae:	883a                	mv	a6,a4
    800004b0:	2705                	addiw	a4,a4,1
    800004b2:	02b577bb          	remuw	a5,a0,a1
    800004b6:	1782                	slli	a5,a5,0x20
    800004b8:	9381                	srli	a5,a5,0x20
    800004ba:	97b2                	add	a5,a5,a2
    800004bc:	0007c783          	lbu	a5,0(a5)
    800004c0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004c4:	0005079b          	sext.w	a5,a0
    800004c8:	02b5553b          	divuw	a0,a0,a1
    800004cc:	0685                	addi	a3,a3,1
    800004ce:	feb7f0e3          	bgeu	a5,a1,800004ae <printint+0x26>

  if(sign)
    800004d2:	00088b63          	beqz	a7,800004e8 <printint+0x60>
    buf[i++] = '-';
    800004d6:	fe040793          	addi	a5,s0,-32
    800004da:	973e                	add	a4,a4,a5
    800004dc:	02d00793          	li	a5,45
    800004e0:	fef70823          	sb	a5,-16(a4)
    800004e4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004e8:	02e05763          	blez	a4,80000516 <printint+0x8e>
    800004ec:	fd040793          	addi	a5,s0,-48
    800004f0:	00e784b3          	add	s1,a5,a4
    800004f4:	fff78913          	addi	s2,a5,-1
    800004f8:	993a                	add	s2,s2,a4
    800004fa:	377d                	addiw	a4,a4,-1
    800004fc:	1702                	slli	a4,a4,0x20
    800004fe:	9301                	srli	a4,a4,0x20
    80000500:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000504:	fff4c503          	lbu	a0,-1(s1)
    80000508:	00000097          	auipc	ra,0x0
    8000050c:	d60080e7          	jalr	-672(ra) # 80000268 <consputc>
  while(--i >= 0)
    80000510:	14fd                	addi	s1,s1,-1
    80000512:	ff2499e3          	bne	s1,s2,80000504 <printint+0x7c>
}
    80000516:	70a2                	ld	ra,40(sp)
    80000518:	7402                	ld	s0,32(sp)
    8000051a:	64e2                	ld	s1,24(sp)
    8000051c:	6942                	ld	s2,16(sp)
    8000051e:	6145                	addi	sp,sp,48
    80000520:	8082                	ret
    x = -xx;
    80000522:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000526:	4885                	li	a7,1
    x = -xx;
    80000528:	bf9d                	j	8000049e <printint+0x16>

000000008000052a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000052a:	1101                	addi	sp,sp,-32
    8000052c:	ec06                	sd	ra,24(sp)
    8000052e:	e822                	sd	s0,16(sp)
    80000530:	e426                	sd	s1,8(sp)
    80000532:	1000                	addi	s0,sp,32
    80000534:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000536:	00012797          	auipc	a5,0x12
    8000053a:	d007a523          	sw	zero,-758(a5) # 80012240 <pr+0x18>
  printf("panic: ");
    8000053e:	00009517          	auipc	a0,0x9
    80000542:	ada50513          	addi	a0,a0,-1318 # 80009018 <etext+0x18>
    80000546:	00000097          	auipc	ra,0x0
    8000054a:	02e080e7          	jalr	46(ra) # 80000574 <printf>
  printf(s);
    8000054e:	8526                	mv	a0,s1
    80000550:	00000097          	auipc	ra,0x0
    80000554:	024080e7          	jalr	36(ra) # 80000574 <printf>
  printf("\n");
    80000558:	00009517          	auipc	a0,0x9
    8000055c:	e8050513          	addi	a0,a0,-384 # 800093d8 <digits+0x398>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	014080e7          	jalr	20(ra) # 80000574 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000568:	4785                	li	a5,1
    8000056a:	0000a717          	auipc	a4,0xa
    8000056e:	a8f72b23          	sw	a5,-1386(a4) # 8000a000 <panicked>
  for(;;)
    80000572:	a001                	j	80000572 <panic+0x48>

0000000080000574 <printf>:
{
    80000574:	7131                	addi	sp,sp,-192
    80000576:	fc86                	sd	ra,120(sp)
    80000578:	f8a2                	sd	s0,112(sp)
    8000057a:	f4a6                	sd	s1,104(sp)
    8000057c:	f0ca                	sd	s2,96(sp)
    8000057e:	ecce                	sd	s3,88(sp)
    80000580:	e8d2                	sd	s4,80(sp)
    80000582:	e4d6                	sd	s5,72(sp)
    80000584:	e0da                	sd	s6,64(sp)
    80000586:	fc5e                	sd	s7,56(sp)
    80000588:	f862                	sd	s8,48(sp)
    8000058a:	f466                	sd	s9,40(sp)
    8000058c:	f06a                	sd	s10,32(sp)
    8000058e:	ec6e                	sd	s11,24(sp)
    80000590:	0100                	addi	s0,sp,128
    80000592:	8a2a                	mv	s4,a0
    80000594:	e40c                	sd	a1,8(s0)
    80000596:	e810                	sd	a2,16(s0)
    80000598:	ec14                	sd	a3,24(s0)
    8000059a:	f018                	sd	a4,32(s0)
    8000059c:	f41c                	sd	a5,40(s0)
    8000059e:	03043823          	sd	a6,48(s0)
    800005a2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005a6:	00012d97          	auipc	s11,0x12
    800005aa:	c9adad83          	lw	s11,-870(s11) # 80012240 <pr+0x18>
  if(locking)
    800005ae:	020d9b63          	bnez	s11,800005e4 <printf+0x70>
  if (fmt == 0)
    800005b2:	040a0263          	beqz	s4,800005f6 <printf+0x82>
  va_start(ap, fmt);
    800005b6:	00840793          	addi	a5,s0,8
    800005ba:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005be:	000a4503          	lbu	a0,0(s4)
    800005c2:	14050f63          	beqz	a0,80000720 <printf+0x1ac>
    800005c6:	4981                	li	s3,0
    if(c != '%'){
    800005c8:	02500a93          	li	s5,37
    switch(c){
    800005cc:	07000b93          	li	s7,112
  consputc('x');
    800005d0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d2:	00009b17          	auipc	s6,0x9
    800005d6:	a6eb0b13          	addi	s6,s6,-1426 # 80009040 <digits>
    switch(c){
    800005da:	07300c93          	li	s9,115
    800005de:	06400c13          	li	s8,100
    800005e2:	a82d                	j	8000061c <printf+0xa8>
    acquire(&pr.lock);
    800005e4:	00012517          	auipc	a0,0x12
    800005e8:	c4450513          	addi	a0,a0,-956 # 80012228 <pr>
    800005ec:	00000097          	auipc	ra,0x0
    800005f0:	5d6080e7          	jalr	1494(ra) # 80000bc2 <acquire>
    800005f4:	bf7d                	j	800005b2 <printf+0x3e>
    panic("null fmt");
    800005f6:	00009517          	auipc	a0,0x9
    800005fa:	a3250513          	addi	a0,a0,-1486 # 80009028 <etext+0x28>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	f2c080e7          	jalr	-212(ra) # 8000052a <panic>
      consputc(c);
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	c62080e7          	jalr	-926(ra) # 80000268 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000060e:	2985                	addiw	s3,s3,1
    80000610:	013a07b3          	add	a5,s4,s3
    80000614:	0007c503          	lbu	a0,0(a5)
    80000618:	10050463          	beqz	a0,80000720 <printf+0x1ac>
    if(c != '%'){
    8000061c:	ff5515e3          	bne	a0,s5,80000606 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000620:	2985                	addiw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c783          	lbu	a5,0(a5)
    8000062a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000062e:	cbed                	beqz	a5,80000720 <printf+0x1ac>
    switch(c){
    80000630:	05778a63          	beq	a5,s7,80000684 <printf+0x110>
    80000634:	02fbf663          	bgeu	s7,a5,80000660 <printf+0xec>
    80000638:	09978863          	beq	a5,s9,800006c8 <printf+0x154>
    8000063c:	07800713          	li	a4,120
    80000640:	0ce79563          	bne	a5,a4,8000070a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000644:	f8843783          	ld	a5,-120(s0)
    80000648:	00878713          	addi	a4,a5,8
    8000064c:	f8e43423          	sd	a4,-120(s0)
    80000650:	4605                	li	a2,1
    80000652:	85ea                	mv	a1,s10
    80000654:	4388                	lw	a0,0(a5)
    80000656:	00000097          	auipc	ra,0x0
    8000065a:	e32080e7          	jalr	-462(ra) # 80000488 <printint>
      break;
    8000065e:	bf45                	j	8000060e <printf+0x9a>
    switch(c){
    80000660:	09578f63          	beq	a5,s5,800006fe <printf+0x18a>
    80000664:	0b879363          	bne	a5,s8,8000070a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000668:	f8843783          	ld	a5,-120(s0)
    8000066c:	00878713          	addi	a4,a5,8
    80000670:	f8e43423          	sd	a4,-120(s0)
    80000674:	4605                	li	a2,1
    80000676:	45a9                	li	a1,10
    80000678:	4388                	lw	a0,0(a5)
    8000067a:	00000097          	auipc	ra,0x0
    8000067e:	e0e080e7          	jalr	-498(ra) # 80000488 <printint>
      break;
    80000682:	b771                	j	8000060e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000684:	f8843783          	ld	a5,-120(s0)
    80000688:	00878713          	addi	a4,a5,8
    8000068c:	f8e43423          	sd	a4,-120(s0)
    80000690:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000694:	03000513          	li	a0,48
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	bd0080e7          	jalr	-1072(ra) # 80000268 <consputc>
  consputc('x');
    800006a0:	07800513          	li	a0,120
    800006a4:	00000097          	auipc	ra,0x0
    800006a8:	bc4080e7          	jalr	-1084(ra) # 80000268 <consputc>
    800006ac:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006ae:	03c95793          	srli	a5,s2,0x3c
    800006b2:	97da                	add	a5,a5,s6
    800006b4:	0007c503          	lbu	a0,0(a5)
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bb0080e7          	jalr	-1104(ra) # 80000268 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c0:	0912                	slli	s2,s2,0x4
    800006c2:	34fd                	addiw	s1,s1,-1
    800006c4:	f4ed                	bnez	s1,800006ae <printf+0x13a>
    800006c6:	b7a1                	j	8000060e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006c8:	f8843783          	ld	a5,-120(s0)
    800006cc:	00878713          	addi	a4,a5,8
    800006d0:	f8e43423          	sd	a4,-120(s0)
    800006d4:	6384                	ld	s1,0(a5)
    800006d6:	cc89                	beqz	s1,800006f0 <printf+0x17c>
      for(; *s; s++)
    800006d8:	0004c503          	lbu	a0,0(s1)
    800006dc:	d90d                	beqz	a0,8000060e <printf+0x9a>
        consputc(*s);
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	b8a080e7          	jalr	-1142(ra) # 80000268 <consputc>
      for(; *s; s++)
    800006e6:	0485                	addi	s1,s1,1
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	f96d                	bnez	a0,800006de <printf+0x16a>
    800006ee:	b705                	j	8000060e <printf+0x9a>
        s = "(null)";
    800006f0:	00009497          	auipc	s1,0x9
    800006f4:	93048493          	addi	s1,s1,-1744 # 80009020 <etext+0x20>
      for(; *s; s++)
    800006f8:	02800513          	li	a0,40
    800006fc:	b7cd                	j	800006de <printf+0x16a>
      consputc('%');
    800006fe:	8556                	mv	a0,s5
    80000700:	00000097          	auipc	ra,0x0
    80000704:	b68080e7          	jalr	-1176(ra) # 80000268 <consputc>
      break;
    80000708:	b719                	j	8000060e <printf+0x9a>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b5c080e7          	jalr	-1188(ra) # 80000268 <consputc>
      consputc(c);
    80000714:	8526                	mv	a0,s1
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b52080e7          	jalr	-1198(ra) # 80000268 <consputc>
      break;
    8000071e:	bdc5                	j	8000060e <printf+0x9a>
  if(locking)
    80000720:	020d9163          	bnez	s11,80000742 <printf+0x1ce>
}
    80000724:	70e6                	ld	ra,120(sp)
    80000726:	7446                	ld	s0,112(sp)
    80000728:	74a6                	ld	s1,104(sp)
    8000072a:	7906                	ld	s2,96(sp)
    8000072c:	69e6                	ld	s3,88(sp)
    8000072e:	6a46                	ld	s4,80(sp)
    80000730:	6aa6                	ld	s5,72(sp)
    80000732:	6b06                	ld	s6,64(sp)
    80000734:	7be2                	ld	s7,56(sp)
    80000736:	7c42                	ld	s8,48(sp)
    80000738:	7ca2                	ld	s9,40(sp)
    8000073a:	7d02                	ld	s10,32(sp)
    8000073c:	6de2                	ld	s11,24(sp)
    8000073e:	6129                	addi	sp,sp,192
    80000740:	8082                	ret
    release(&pr.lock);
    80000742:	00012517          	auipc	a0,0x12
    80000746:	ae650513          	addi	a0,a0,-1306 # 80012228 <pr>
    8000074a:	00000097          	auipc	ra,0x0
    8000074e:	52c080e7          	jalr	1324(ra) # 80000c76 <release>
}
    80000752:	bfc9                	j	80000724 <printf+0x1b0>

0000000080000754 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000754:	1101                	addi	sp,sp,-32
    80000756:	ec06                	sd	ra,24(sp)
    80000758:	e822                	sd	s0,16(sp)
    8000075a:	e426                	sd	s1,8(sp)
    8000075c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000075e:	00012497          	auipc	s1,0x12
    80000762:	aca48493          	addi	s1,s1,-1334 # 80012228 <pr>
    80000766:	00009597          	auipc	a1,0x9
    8000076a:	8d258593          	addi	a1,a1,-1838 # 80009038 <etext+0x38>
    8000076e:	8526                	mv	a0,s1
    80000770:	00000097          	auipc	ra,0x0
    80000774:	3c2080e7          	jalr	962(ra) # 80000b32 <initlock>
  pr.locking = 1;
    80000778:	4785                	li	a5,1
    8000077a:	cc9c                	sw	a5,24(s1)
}
    8000077c:	60e2                	ld	ra,24(sp)
    8000077e:	6442                	ld	s0,16(sp)
    80000780:	64a2                	ld	s1,8(sp)
    80000782:	6105                	addi	sp,sp,32
    80000784:	8082                	ret

0000000080000786 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000786:	1141                	addi	sp,sp,-16
    80000788:	e406                	sd	ra,8(sp)
    8000078a:	e022                	sd	s0,0(sp)
    8000078c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000078e:	100007b7          	lui	a5,0x10000
    80000792:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000796:	f8000713          	li	a4,-128
    8000079a:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000079e:	470d                	li	a4,3
    800007a0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007a4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007a8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007ac:	469d                	li	a3,7
    800007ae:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007b2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007b6:	00009597          	auipc	a1,0x9
    800007ba:	8a258593          	addi	a1,a1,-1886 # 80009058 <digits+0x18>
    800007be:	00012517          	auipc	a0,0x12
    800007c2:	a8a50513          	addi	a0,a0,-1398 # 80012248 <uart_tx_lock>
    800007c6:	00000097          	auipc	ra,0x0
    800007ca:	36c080e7          	jalr	876(ra) # 80000b32 <initlock>
}
    800007ce:	60a2                	ld	ra,8(sp)
    800007d0:	6402                	ld	s0,0(sp)
    800007d2:	0141                	addi	sp,sp,16
    800007d4:	8082                	ret

00000000800007d6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007d6:	1101                	addi	sp,sp,-32
    800007d8:	ec06                	sd	ra,24(sp)
    800007da:	e822                	sd	s0,16(sp)
    800007dc:	e426                	sd	s1,8(sp)
    800007de:	1000                	addi	s0,sp,32
    800007e0:	84aa                	mv	s1,a0
  push_off();
    800007e2:	00000097          	auipc	ra,0x0
    800007e6:	394080e7          	jalr	916(ra) # 80000b76 <push_off>

  if(panicked){
    800007ea:	0000a797          	auipc	a5,0xa
    800007ee:	8167a783          	lw	a5,-2026(a5) # 8000a000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007f2:	10000737          	lui	a4,0x10000
  if(panicked){
    800007f6:	c391                	beqz	a5,800007fa <uartputc_sync+0x24>
    for(;;)
    800007f8:	a001                	j	800007f8 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fa:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800007fe:	0207f793          	andi	a5,a5,32
    80000802:	dfe5                	beqz	a5,800007fa <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000804:	0ff4f513          	andi	a0,s1,255
    80000808:	100007b7          	lui	a5,0x10000
    8000080c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000810:	00000097          	auipc	ra,0x0
    80000814:	406080e7          	jalr	1030(ra) # 80000c16 <pop_off>
}
    80000818:	60e2                	ld	ra,24(sp)
    8000081a:	6442                	ld	s0,16(sp)
    8000081c:	64a2                	ld	s1,8(sp)
    8000081e:	6105                	addi	sp,sp,32
    80000820:	8082                	ret

0000000080000822 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000822:	00009797          	auipc	a5,0x9
    80000826:	7e67b783          	ld	a5,2022(a5) # 8000a008 <uart_tx_r>
    8000082a:	00009717          	auipc	a4,0x9
    8000082e:	7e673703          	ld	a4,2022(a4) # 8000a010 <uart_tx_w>
    80000832:	06f70a63          	beq	a4,a5,800008a6 <uartstart+0x84>
{
    80000836:	7139                	addi	sp,sp,-64
    80000838:	fc06                	sd	ra,56(sp)
    8000083a:	f822                	sd	s0,48(sp)
    8000083c:	f426                	sd	s1,40(sp)
    8000083e:	f04a                	sd	s2,32(sp)
    80000840:	ec4e                	sd	s3,24(sp)
    80000842:	e852                	sd	s4,16(sp)
    80000844:	e456                	sd	s5,8(sp)
    80000846:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000848:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000084c:	00012a17          	auipc	s4,0x12
    80000850:	9fca0a13          	addi	s4,s4,-1540 # 80012248 <uart_tx_lock>
    uart_tx_r += 1;
    80000854:	00009497          	auipc	s1,0x9
    80000858:	7b448493          	addi	s1,s1,1972 # 8000a008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000085c:	00009997          	auipc	s3,0x9
    80000860:	7b498993          	addi	s3,s3,1972 # 8000a010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000864:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000868:	02077713          	andi	a4,a4,32
    8000086c:	c705                	beqz	a4,80000894 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086e:	01f7f713          	andi	a4,a5,31
    80000872:	9752                	add	a4,a4,s4
    80000874:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000878:	0785                	addi	a5,a5,1
    8000087a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000087c:	8526                	mv	a0,s1
    8000087e:	00002097          	auipc	ra,0x2
    80000882:	30e080e7          	jalr	782(ra) # 80002b8c <wakeup>
    
    WriteReg(THR, c);
    80000886:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000088a:	609c                	ld	a5,0(s1)
    8000088c:	0009b703          	ld	a4,0(s3)
    80000890:	fcf71ae3          	bne	a4,a5,80000864 <uartstart+0x42>
  }
}
    80000894:	70e2                	ld	ra,56(sp)
    80000896:	7442                	ld	s0,48(sp)
    80000898:	74a2                	ld	s1,40(sp)
    8000089a:	7902                	ld	s2,32(sp)
    8000089c:	69e2                	ld	s3,24(sp)
    8000089e:	6a42                	ld	s4,16(sp)
    800008a0:	6aa2                	ld	s5,8(sp)
    800008a2:	6121                	addi	sp,sp,64
    800008a4:	8082                	ret
    800008a6:	8082                	ret

00000000800008a8 <uartputc>:
{
    800008a8:	7179                	addi	sp,sp,-48
    800008aa:	f406                	sd	ra,40(sp)
    800008ac:	f022                	sd	s0,32(sp)
    800008ae:	ec26                	sd	s1,24(sp)
    800008b0:	e84a                	sd	s2,16(sp)
    800008b2:	e44e                	sd	s3,8(sp)
    800008b4:	e052                	sd	s4,0(sp)
    800008b6:	1800                	addi	s0,sp,48
    800008b8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ba:	00012517          	auipc	a0,0x12
    800008be:	98e50513          	addi	a0,a0,-1650 # 80012248 <uart_tx_lock>
    800008c2:	00000097          	auipc	ra,0x0
    800008c6:	300080e7          	jalr	768(ra) # 80000bc2 <acquire>
  if(panicked){
    800008ca:	00009797          	auipc	a5,0x9
    800008ce:	7367a783          	lw	a5,1846(a5) # 8000a000 <panicked>
    800008d2:	c391                	beqz	a5,800008d6 <uartputc+0x2e>
    for(;;)
    800008d4:	a001                	j	800008d4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008d6:	00009717          	auipc	a4,0x9
    800008da:	73a73703          	ld	a4,1850(a4) # 8000a010 <uart_tx_w>
    800008de:	00009797          	auipc	a5,0x9
    800008e2:	72a7b783          	ld	a5,1834(a5) # 8000a008 <uart_tx_r>
    800008e6:	02078793          	addi	a5,a5,32
    800008ea:	02e79b63          	bne	a5,a4,80000920 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008ee:	00012997          	auipc	s3,0x12
    800008f2:	95a98993          	addi	s3,s3,-1702 # 80012248 <uart_tx_lock>
    800008f6:	00009497          	auipc	s1,0x9
    800008fa:	71248493          	addi	s1,s1,1810 # 8000a008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fe:	00009917          	auipc	s2,0x9
    80000902:	71290913          	addi	s2,s2,1810 # 8000a010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000906:	85ce                	mv	a1,s3
    80000908:	8526                	mv	a0,s1
    8000090a:	00002097          	auipc	ra,0x2
    8000090e:	0f6080e7          	jalr	246(ra) # 80002a00 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00093703          	ld	a4,0(s2)
    80000916:	609c                	ld	a5,0(s1)
    80000918:	02078793          	addi	a5,a5,32
    8000091c:	fee785e3          	beq	a5,a4,80000906 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000920:	00012497          	auipc	s1,0x12
    80000924:	92848493          	addi	s1,s1,-1752 # 80012248 <uart_tx_lock>
    80000928:	01f77793          	andi	a5,a4,31
    8000092c:	97a6                	add	a5,a5,s1
    8000092e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000932:	0705                	addi	a4,a4,1
    80000934:	00009797          	auipc	a5,0x9
    80000938:	6ce7be23          	sd	a4,1756(a5) # 8000a010 <uart_tx_w>
      uartstart();
    8000093c:	00000097          	auipc	ra,0x0
    80000940:	ee6080e7          	jalr	-282(ra) # 80000822 <uartstart>
      release(&uart_tx_lock);
    80000944:	8526                	mv	a0,s1
    80000946:	00000097          	auipc	ra,0x0
    8000094a:	330080e7          	jalr	816(ra) # 80000c76 <release>
}
    8000094e:	70a2                	ld	ra,40(sp)
    80000950:	7402                	ld	s0,32(sp)
    80000952:	64e2                	ld	s1,24(sp)
    80000954:	6942                	ld	s2,16(sp)
    80000956:	69a2                	ld	s3,8(sp)
    80000958:	6a02                	ld	s4,0(sp)
    8000095a:	6145                	addi	sp,sp,48
    8000095c:	8082                	ret

000000008000095e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000095e:	1141                	addi	sp,sp,-16
    80000960:	e422                	sd	s0,8(sp)
    80000962:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000964:	100007b7          	lui	a5,0x10000
    80000968:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000096c:	8b85                	andi	a5,a5,1
    8000096e:	cb91                	beqz	a5,80000982 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000970:	100007b7          	lui	a5,0x10000
    80000974:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000978:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000097c:	6422                	ld	s0,8(sp)
    8000097e:	0141                	addi	sp,sp,16
    80000980:	8082                	ret
    return -1;
    80000982:	557d                	li	a0,-1
    80000984:	bfe5                	j	8000097c <uartgetc+0x1e>

0000000080000986 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000986:	1101                	addi	sp,sp,-32
    80000988:	ec06                	sd	ra,24(sp)
    8000098a:	e822                	sd	s0,16(sp)
    8000098c:	e426                	sd	s1,8(sp)
    8000098e:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000990:	54fd                	li	s1,-1
    80000992:	a029                	j	8000099c <uartintr+0x16>
      break;
    consoleintr(c);
    80000994:	00000097          	auipc	ra,0x0
    80000998:	916080e7          	jalr	-1770(ra) # 800002aa <consoleintr>
    int c = uartgetc();
    8000099c:	00000097          	auipc	ra,0x0
    800009a0:	fc2080e7          	jalr	-62(ra) # 8000095e <uartgetc>
    if(c == -1)
    800009a4:	fe9518e3          	bne	a0,s1,80000994 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009a8:	00012497          	auipc	s1,0x12
    800009ac:	8a048493          	addi	s1,s1,-1888 # 80012248 <uart_tx_lock>
    800009b0:	8526                	mv	a0,s1
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	210080e7          	jalr	528(ra) # 80000bc2 <acquire>
  uartstart();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	e68080e7          	jalr	-408(ra) # 80000822 <uartstart>
  release(&uart_tx_lock);
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	2b2080e7          	jalr	690(ra) # 80000c76 <release>
}
    800009cc:	60e2                	ld	ra,24(sp)
    800009ce:	6442                	ld	s0,16(sp)
    800009d0:	64a2                	ld	s1,8(sp)
    800009d2:	6105                	addi	sp,sp,32
    800009d4:	8082                	ret

00000000800009d6 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009d6:	1101                	addi	sp,sp,-32
    800009d8:	ec06                	sd	ra,24(sp)
    800009da:	e822                	sd	s0,16(sp)
    800009dc:	e426                	sd	s1,8(sp)
    800009de:	e04a                	sd	s2,0(sp)
    800009e0:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009e2:	03451793          	slli	a5,a0,0x34
    800009e6:	ebb9                	bnez	a5,80000a3c <kfree+0x66>
    800009e8:	84aa                	mv	s1,a0
    800009ea:	0002d797          	auipc	a5,0x2d
    800009ee:	61678793          	addi	a5,a5,1558 # 8002e000 <end>
    800009f2:	04f56563          	bltu	a0,a5,80000a3c <kfree+0x66>
    800009f6:	47c5                	li	a5,17
    800009f8:	07ee                	slli	a5,a5,0x1b
    800009fa:	04f57163          	bgeu	a0,a5,80000a3c <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    800009fe:	6605                	lui	a2,0x1
    80000a00:	4585                	li	a1,1
    80000a02:	00000097          	auipc	ra,0x0
    80000a06:	2bc080e7          	jalr	700(ra) # 80000cbe <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a0a:	00012917          	auipc	s2,0x12
    80000a0e:	87690913          	addi	s2,s2,-1930 # 80012280 <kmem>
    80000a12:	854a                	mv	a0,s2
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	1ae080e7          	jalr	430(ra) # 80000bc2 <acquire>
  r->next = kmem.freelist;
    80000a1c:	01893783          	ld	a5,24(s2)
    80000a20:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a22:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	24e080e7          	jalr	590(ra) # 80000c76 <release>
}
    80000a30:	60e2                	ld	ra,24(sp)
    80000a32:	6442                	ld	s0,16(sp)
    80000a34:	64a2                	ld	s1,8(sp)
    80000a36:	6902                	ld	s2,0(sp)
    80000a38:	6105                	addi	sp,sp,32
    80000a3a:	8082                	ret
    panic("kfree");
    80000a3c:	00008517          	auipc	a0,0x8
    80000a40:	62450513          	addi	a0,a0,1572 # 80009060 <digits+0x20>
    80000a44:	00000097          	auipc	ra,0x0
    80000a48:	ae6080e7          	jalr	-1306(ra) # 8000052a <panic>

0000000080000a4c <freerange>:
{
    80000a4c:	7179                	addi	sp,sp,-48
    80000a4e:	f406                	sd	ra,40(sp)
    80000a50:	f022                	sd	s0,32(sp)
    80000a52:	ec26                	sd	s1,24(sp)
    80000a54:	e84a                	sd	s2,16(sp)
    80000a56:	e44e                	sd	s3,8(sp)
    80000a58:	e052                	sd	s4,0(sp)
    80000a5a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a5c:	6785                	lui	a5,0x1
    80000a5e:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a62:	94aa                	add	s1,s1,a0
    80000a64:	757d                	lui	a0,0xfffff
    80000a66:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a68:	94be                	add	s1,s1,a5
    80000a6a:	0095ee63          	bltu	a1,s1,80000a86 <freerange+0x3a>
    80000a6e:	892e                	mv	s2,a1
    kfree(p);
    80000a70:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a72:	6985                	lui	s3,0x1
    kfree(p);
    80000a74:	01448533          	add	a0,s1,s4
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	f5e080e7          	jalr	-162(ra) # 800009d6 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	94ce                	add	s1,s1,s3
    80000a82:	fe9979e3          	bgeu	s2,s1,80000a74 <freerange+0x28>
}
    80000a86:	70a2                	ld	ra,40(sp)
    80000a88:	7402                	ld	s0,32(sp)
    80000a8a:	64e2                	ld	s1,24(sp)
    80000a8c:	6942                	ld	s2,16(sp)
    80000a8e:	69a2                	ld	s3,8(sp)
    80000a90:	6a02                	ld	s4,0(sp)
    80000a92:	6145                	addi	sp,sp,48
    80000a94:	8082                	ret

0000000080000a96 <kinit>:
{
    80000a96:	1141                	addi	sp,sp,-16
    80000a98:	e406                	sd	ra,8(sp)
    80000a9a:	e022                	sd	s0,0(sp)
    80000a9c:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000a9e:	00008597          	auipc	a1,0x8
    80000aa2:	5ca58593          	addi	a1,a1,1482 # 80009068 <digits+0x28>
    80000aa6:	00011517          	auipc	a0,0x11
    80000aaa:	7da50513          	addi	a0,a0,2010 # 80012280 <kmem>
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	084080e7          	jalr	132(ra) # 80000b32 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ab6:	45c5                	li	a1,17
    80000ab8:	05ee                	slli	a1,a1,0x1b
    80000aba:	0002d517          	auipc	a0,0x2d
    80000abe:	54650513          	addi	a0,a0,1350 # 8002e000 <end>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	f8a080e7          	jalr	-118(ra) # 80000a4c <freerange>
}
    80000aca:	60a2                	ld	ra,8(sp)
    80000acc:	6402                	ld	s0,0(sp)
    80000ace:	0141                	addi	sp,sp,16
    80000ad0:	8082                	ret

0000000080000ad2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ad2:	1101                	addi	sp,sp,-32
    80000ad4:	ec06                	sd	ra,24(sp)
    80000ad6:	e822                	sd	s0,16(sp)
    80000ad8:	e426                	sd	s1,8(sp)
    80000ada:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000adc:	00011497          	auipc	s1,0x11
    80000ae0:	7a448493          	addi	s1,s1,1956 # 80012280 <kmem>
    80000ae4:	8526                	mv	a0,s1
    80000ae6:	00000097          	auipc	ra,0x0
    80000aea:	0dc080e7          	jalr	220(ra) # 80000bc2 <acquire>
  r = kmem.freelist;
    80000aee:	6c84                	ld	s1,24(s1)
  if(r)
    80000af0:	c885                	beqz	s1,80000b20 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000af2:	609c                	ld	a5,0(s1)
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	78c50513          	addi	a0,a0,1932 # 80012280 <kmem>
    80000afc:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	178080e7          	jalr	376(ra) # 80000c76 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b06:	6605                	lui	a2,0x1
    80000b08:	4595                	li	a1,5
    80000b0a:	8526                	mv	a0,s1
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	1b2080e7          	jalr	434(ra) # 80000cbe <memset>
  return (void*)r;
}
    80000b14:	8526                	mv	a0,s1
    80000b16:	60e2                	ld	ra,24(sp)
    80000b18:	6442                	ld	s0,16(sp)
    80000b1a:	64a2                	ld	s1,8(sp)
    80000b1c:	6105                	addi	sp,sp,32
    80000b1e:	8082                	ret
  release(&kmem.lock);
    80000b20:	00011517          	auipc	a0,0x11
    80000b24:	76050513          	addi	a0,a0,1888 # 80012280 <kmem>
    80000b28:	00000097          	auipc	ra,0x0
    80000b2c:	14e080e7          	jalr	334(ra) # 80000c76 <release>
  if(r)
    80000b30:	b7d5                	j	80000b14 <kalloc+0x42>

0000000080000b32 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b32:	1141                	addi	sp,sp,-16
    80000b34:	e422                	sd	s0,8(sp)
    80000b36:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b38:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b3a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b3e:	00053823          	sd	zero,16(a0)
}
    80000b42:	6422                	ld	s0,8(sp)
    80000b44:	0141                	addi	sp,sp,16
    80000b46:	8082                	ret

0000000080000b48 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b48:	411c                	lw	a5,0(a0)
    80000b4a:	e399                	bnez	a5,80000b50 <holding+0x8>
    80000b4c:	4501                	li	a0,0
  return r;
}
    80000b4e:	8082                	ret
{
    80000b50:	1101                	addi	sp,sp,-32
    80000b52:	ec06                	sd	ra,24(sp)
    80000b54:	e822                	sd	s0,16(sp)
    80000b56:	e426                	sd	s1,8(sp)
    80000b58:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b5a:	6904                	ld	s1,16(a0)
    80000b5c:	00001097          	auipc	ra,0x1
    80000b60:	68c080e7          	jalr	1676(ra) # 800021e8 <mycpu>
    80000b64:	40a48533          	sub	a0,s1,a0
    80000b68:	00153513          	seqz	a0,a0
}
    80000b6c:	60e2                	ld	ra,24(sp)
    80000b6e:	6442                	ld	s0,16(sp)
    80000b70:	64a2                	ld	s1,8(sp)
    80000b72:	6105                	addi	sp,sp,32
    80000b74:	8082                	ret

0000000080000b76 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b76:	1101                	addi	sp,sp,-32
    80000b78:	ec06                	sd	ra,24(sp)
    80000b7a:	e822                	sd	s0,16(sp)
    80000b7c:	e426                	sd	s1,8(sp)
    80000b7e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b80:	100024f3          	csrr	s1,sstatus
    80000b84:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b88:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b8a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b8e:	00001097          	auipc	ra,0x1
    80000b92:	65a080e7          	jalr	1626(ra) # 800021e8 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	64e080e7          	jalr	1614(ra) # 800021e8 <mycpu>
    80000ba2:	5d3c                	lw	a5,120(a0)
    80000ba4:	2785                	addiw	a5,a5,1
    80000ba6:	dd3c                	sw	a5,120(a0)
}
    80000ba8:	60e2                	ld	ra,24(sp)
    80000baa:	6442                	ld	s0,16(sp)
    80000bac:	64a2                	ld	s1,8(sp)
    80000bae:	6105                	addi	sp,sp,32
    80000bb0:	8082                	ret
    mycpu()->intena = old;
    80000bb2:	00001097          	auipc	ra,0x1
    80000bb6:	636080e7          	jalr	1590(ra) # 800021e8 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bba:	8085                	srli	s1,s1,0x1
    80000bbc:	8885                	andi	s1,s1,1
    80000bbe:	dd64                	sw	s1,124(a0)
    80000bc0:	bfe9                	j	80000b9a <push_off+0x24>

0000000080000bc2 <acquire>:
{
    80000bc2:	1101                	addi	sp,sp,-32
    80000bc4:	ec06                	sd	ra,24(sp)
    80000bc6:	e822                	sd	s0,16(sp)
    80000bc8:	e426                	sd	s1,8(sp)
    80000bca:	1000                	addi	s0,sp,32
    80000bcc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bce:	00000097          	auipc	ra,0x0
    80000bd2:	fa8080e7          	jalr	-88(ra) # 80000b76 <push_off>
  if(holding(lk))
    80000bd6:	8526                	mv	a0,s1
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	f70080e7          	jalr	-144(ra) # 80000b48 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be0:	4705                	li	a4,1
  if(holding(lk))
    80000be2:	e115                	bnez	a0,80000c06 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be4:	87ba                	mv	a5,a4
    80000be6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bea:	2781                	sext.w	a5,a5
    80000bec:	ffe5                	bnez	a5,80000be4 <acquire+0x22>
  __sync_synchronize();
    80000bee:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000bf2:	00001097          	auipc	ra,0x1
    80000bf6:	5f6080e7          	jalr	1526(ra) # 800021e8 <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire");
    80000c06:	00008517          	auipc	a0,0x8
    80000c0a:	46a50513          	addi	a0,a0,1130 # 80009070 <digits+0x30>
    80000c0e:	00000097          	auipc	ra,0x0
    80000c12:	91c080e7          	jalr	-1764(ra) # 8000052a <panic>

0000000080000c16 <pop_off>:

void
pop_off(void)
{
    80000c16:	1141                	addi	sp,sp,-16
    80000c18:	e406                	sd	ra,8(sp)
    80000c1a:	e022                	sd	s0,0(sp)
    80000c1c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c1e:	00001097          	auipc	ra,0x1
    80000c22:	5ca080e7          	jalr	1482(ra) # 800021e8 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c26:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c2a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c2c:	e78d                	bnez	a5,80000c56 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	02f05b63          	blez	a5,80000c66 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c34:	37fd                	addiw	a5,a5,-1
    80000c36:	0007871b          	sext.w	a4,a5
    80000c3a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c3c:	eb09                	bnez	a4,80000c4e <pop_off+0x38>
    80000c3e:	5d7c                	lw	a5,124(a0)
    80000c40:	c799                	beqz	a5,80000c4e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c42:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c46:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c4a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c4e:	60a2                	ld	ra,8(sp)
    80000c50:	6402                	ld	s0,0(sp)
    80000c52:	0141                	addi	sp,sp,16
    80000c54:	8082                	ret
    panic("pop_off - interruptible");
    80000c56:	00008517          	auipc	a0,0x8
    80000c5a:	42250513          	addi	a0,a0,1058 # 80009078 <digits+0x38>
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	8cc080e7          	jalr	-1844(ra) # 8000052a <panic>
    panic("pop_off");
    80000c66:	00008517          	auipc	a0,0x8
    80000c6a:	42a50513          	addi	a0,a0,1066 # 80009090 <digits+0x50>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8bc080e7          	jalr	-1860(ra) # 8000052a <panic>

0000000080000c76 <release>:
{
    80000c76:	1101                	addi	sp,sp,-32
    80000c78:	ec06                	sd	ra,24(sp)
    80000c7a:	e822                	sd	s0,16(sp)
    80000c7c:	e426                	sd	s1,8(sp)
    80000c7e:	1000                	addi	s0,sp,32
    80000c80:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	ec6080e7          	jalr	-314(ra) # 80000b48 <holding>
    80000c8a:	c115                	beqz	a0,80000cae <release+0x38>
  lk->cpu = 0;
    80000c8c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c90:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000c94:	0f50000f          	fence	iorw,ow
    80000c98:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000c9c:	00000097          	auipc	ra,0x0
    80000ca0:	f7a080e7          	jalr	-134(ra) # 80000c16 <pop_off>
}
    80000ca4:	60e2                	ld	ra,24(sp)
    80000ca6:	6442                	ld	s0,16(sp)
    80000ca8:	64a2                	ld	s1,8(sp)
    80000caa:	6105                	addi	sp,sp,32
    80000cac:	8082                	ret
    panic("release");
    80000cae:	00008517          	auipc	a0,0x8
    80000cb2:	3ea50513          	addi	a0,a0,1002 # 80009098 <digits+0x58>
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	874080e7          	jalr	-1932(ra) # 8000052a <panic>

0000000080000cbe <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cbe:	1141                	addi	sp,sp,-16
    80000cc0:	e422                	sd	s0,8(sp)
    80000cc2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cc4:	ca19                	beqz	a2,80000cda <memset+0x1c>
    80000cc6:	87aa                	mv	a5,a0
    80000cc8:	1602                	slli	a2,a2,0x20
    80000cca:	9201                	srli	a2,a2,0x20
    80000ccc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cd0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cd4:	0785                	addi	a5,a5,1
    80000cd6:	fee79de3          	bne	a5,a4,80000cd0 <memset+0x12>
  }
  return dst;
}
    80000cda:	6422                	ld	s0,8(sp)
    80000cdc:	0141                	addi	sp,sp,16
    80000cde:	8082                	ret

0000000080000ce0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000ce6:	ca05                	beqz	a2,80000d16 <memcmp+0x36>
    80000ce8:	fff6069b          	addiw	a3,a2,-1
    80000cec:	1682                	slli	a3,a3,0x20
    80000cee:	9281                	srli	a3,a3,0x20
    80000cf0:	0685                	addi	a3,a3,1
    80000cf2:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000cf4:	00054783          	lbu	a5,0(a0)
    80000cf8:	0005c703          	lbu	a4,0(a1)
    80000cfc:	00e79863          	bne	a5,a4,80000d0c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d00:	0505                	addi	a0,a0,1
    80000d02:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d04:	fed518e3          	bne	a0,a3,80000cf4 <memcmp+0x14>
  }

  return 0;
    80000d08:	4501                	li	a0,0
    80000d0a:	a019                	j	80000d10 <memcmp+0x30>
      return *s1 - *s2;
    80000d0c:	40e7853b          	subw	a0,a5,a4
}
    80000d10:	6422                	ld	s0,8(sp)
    80000d12:	0141                	addi	sp,sp,16
    80000d14:	8082                	ret
  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	bfe5                	j	80000d10 <memcmp+0x30>

0000000080000d1a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d1a:	1141                	addi	sp,sp,-16
    80000d1c:	e422                	sd	s0,8(sp)
    80000d1e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d20:	02a5e563          	bltu	a1,a0,80000d4a <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d24:	fff6069b          	addiw	a3,a2,-1
    80000d28:	ce11                	beqz	a2,80000d44 <memmove+0x2a>
    80000d2a:	1682                	slli	a3,a3,0x20
    80000d2c:	9281                	srli	a3,a3,0x20
    80000d2e:	0685                	addi	a3,a3,1
    80000d30:	96ae                	add	a3,a3,a1
    80000d32:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d34:	0585                	addi	a1,a1,1
    80000d36:	0785                	addi	a5,a5,1
    80000d38:	fff5c703          	lbu	a4,-1(a1)
    80000d3c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d40:	fed59ae3          	bne	a1,a3,80000d34 <memmove+0x1a>

  return dst;
}
    80000d44:	6422                	ld	s0,8(sp)
    80000d46:	0141                	addi	sp,sp,16
    80000d48:	8082                	ret
  if(s < d && s + n > d){
    80000d4a:	02061713          	slli	a4,a2,0x20
    80000d4e:	9301                	srli	a4,a4,0x20
    80000d50:	00e587b3          	add	a5,a1,a4
    80000d54:	fcf578e3          	bgeu	a0,a5,80000d24 <memmove+0xa>
    d += n;
    80000d58:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d5a:	fff6069b          	addiw	a3,a2,-1
    80000d5e:	d27d                	beqz	a2,80000d44 <memmove+0x2a>
    80000d60:	02069613          	slli	a2,a3,0x20
    80000d64:	9201                	srli	a2,a2,0x20
    80000d66:	fff64613          	not	a2,a2
    80000d6a:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d6c:	17fd                	addi	a5,a5,-1
    80000d6e:	177d                	addi	a4,a4,-1
    80000d70:	0007c683          	lbu	a3,0(a5)
    80000d74:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d78:	fef61ae3          	bne	a2,a5,80000d6c <memmove+0x52>
    80000d7c:	b7e1                	j	80000d44 <memmove+0x2a>

0000000080000d7e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d7e:	1141                	addi	sp,sp,-16
    80000d80:	e406                	sd	ra,8(sp)
    80000d82:	e022                	sd	s0,0(sp)
    80000d84:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d86:	00000097          	auipc	ra,0x0
    80000d8a:	f94080e7          	jalr	-108(ra) # 80000d1a <memmove>
}
    80000d8e:	60a2                	ld	ra,8(sp)
    80000d90:	6402                	ld	s0,0(sp)
    80000d92:	0141                	addi	sp,sp,16
    80000d94:	8082                	ret

0000000080000d96 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e422                	sd	s0,8(sp)
    80000d9a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d9c:	ce11                	beqz	a2,80000db8 <strncmp+0x22>
    80000d9e:	00054783          	lbu	a5,0(a0)
    80000da2:	cf89                	beqz	a5,80000dbc <strncmp+0x26>
    80000da4:	0005c703          	lbu	a4,0(a1)
    80000da8:	00f71a63          	bne	a4,a5,80000dbc <strncmp+0x26>
    n--, p++, q++;
    80000dac:	367d                	addiw	a2,a2,-1
    80000dae:	0505                	addi	a0,a0,1
    80000db0:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db2:	f675                	bnez	a2,80000d9e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000db4:	4501                	li	a0,0
    80000db6:	a809                	j	80000dc8 <strncmp+0x32>
    80000db8:	4501                	li	a0,0
    80000dba:	a039                	j	80000dc8 <strncmp+0x32>
  if(n == 0)
    80000dbc:	ca09                	beqz	a2,80000dce <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dbe:	00054503          	lbu	a0,0(a0)
    80000dc2:	0005c783          	lbu	a5,0(a1)
    80000dc6:	9d1d                	subw	a0,a0,a5
}
    80000dc8:	6422                	ld	s0,8(sp)
    80000dca:	0141                	addi	sp,sp,16
    80000dcc:	8082                	ret
    return 0;
    80000dce:	4501                	li	a0,0
    80000dd0:	bfe5                	j	80000dc8 <strncmp+0x32>

0000000080000dd2 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e422                	sd	s0,8(sp)
    80000dd6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dd8:	872a                	mv	a4,a0
    80000dda:	8832                	mv	a6,a2
    80000ddc:	367d                	addiw	a2,a2,-1
    80000dde:	01005963          	blez	a6,80000df0 <strncpy+0x1e>
    80000de2:	0705                	addi	a4,a4,1
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	fef70fa3          	sb	a5,-1(a4)
    80000dec:	0585                	addi	a1,a1,1
    80000dee:	f7f5                	bnez	a5,80000dda <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df0:	86ba                	mv	a3,a4
    80000df2:	00c05c63          	blez	a2,80000e0a <strncpy+0x38>
    *s++ = 0;
    80000df6:	0685                	addi	a3,a3,1
    80000df8:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000dfc:	fff6c793          	not	a5,a3
    80000e00:	9fb9                	addw	a5,a5,a4
    80000e02:	010787bb          	addw	a5,a5,a6
    80000e06:	fef048e3          	bgtz	a5,80000df6 <strncpy+0x24>
  return os;
}
    80000e0a:	6422                	ld	s0,8(sp)
    80000e0c:	0141                	addi	sp,sp,16
    80000e0e:	8082                	ret

0000000080000e10 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e10:	1141                	addi	sp,sp,-16
    80000e12:	e422                	sd	s0,8(sp)
    80000e14:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e16:	02c05363          	blez	a2,80000e3c <safestrcpy+0x2c>
    80000e1a:	fff6069b          	addiw	a3,a2,-1
    80000e1e:	1682                	slli	a3,a3,0x20
    80000e20:	9281                	srli	a3,a3,0x20
    80000e22:	96ae                	add	a3,a3,a1
    80000e24:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e26:	00d58963          	beq	a1,a3,80000e38 <safestrcpy+0x28>
    80000e2a:	0585                	addi	a1,a1,1
    80000e2c:	0785                	addi	a5,a5,1
    80000e2e:	fff5c703          	lbu	a4,-1(a1)
    80000e32:	fee78fa3          	sb	a4,-1(a5)
    80000e36:	fb65                	bnez	a4,80000e26 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e38:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e3c:	6422                	ld	s0,8(sp)
    80000e3e:	0141                	addi	sp,sp,16
    80000e40:	8082                	ret

0000000080000e42 <strlen>:

int
strlen(const char *s)
{
    80000e42:	1141                	addi	sp,sp,-16
    80000e44:	e422                	sd	s0,8(sp)
    80000e46:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e48:	00054783          	lbu	a5,0(a0)
    80000e4c:	cf91                	beqz	a5,80000e68 <strlen+0x26>
    80000e4e:	0505                	addi	a0,a0,1
    80000e50:	87aa                	mv	a5,a0
    80000e52:	4685                	li	a3,1
    80000e54:	9e89                	subw	a3,a3,a0
    80000e56:	00f6853b          	addw	a0,a3,a5
    80000e5a:	0785                	addi	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	fb7d                	bnez	a4,80000e56 <strlen+0x14>
    ;
  return n;
}
    80000e62:	6422                	ld	s0,8(sp)
    80000e64:	0141                	addi	sp,sp,16
    80000e66:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e68:	4501                	li	a0,0
    80000e6a:	bfe5                	j	80000e62 <strlen+0x20>

0000000080000e6c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e6c:	1141                	addi	sp,sp,-16
    80000e6e:	e406                	sd	ra,8(sp)
    80000e70:	e022                	sd	s0,0(sp)
    80000e72:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e74:	00001097          	auipc	ra,0x1
    80000e78:	364080e7          	jalr	868(ra) # 800021d8 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e7c:	00009717          	auipc	a4,0x9
    80000e80:	19c70713          	addi	a4,a4,412 # 8000a018 <started>
  if(cpuid() == 0){
    80000e84:	c139                	beqz	a0,80000eca <main+0x5e>
    while(started == 0)
    80000e86:	431c                	lw	a5,0(a4)
    80000e88:	2781                	sext.w	a5,a5
    80000e8a:	dff5                	beqz	a5,80000e86 <main+0x1a>
      ;
    __sync_synchronize();
    80000e8c:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e90:	00001097          	auipc	ra,0x1
    80000e94:	348080e7          	jalr	840(ra) # 800021d8 <cpuid>
    80000e98:	85aa                	mv	a1,a0
    80000e9a:	00008517          	auipc	a0,0x8
    80000e9e:	21e50513          	addi	a0,a0,542 # 800090b8 <digits+0x78>
    80000ea2:	fffff097          	auipc	ra,0xfffff
    80000ea6:	6d2080e7          	jalr	1746(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000eaa:	00000097          	auipc	ra,0x0
    80000eae:	0d8080e7          	jalr	216(ra) # 80000f82 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb2:	00002097          	auipc	ra,0x2
    80000eb6:	0f6080e7          	jalr	246(ra) # 80002fa8 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00006097          	auipc	ra,0x6
    80000ebe:	c06080e7          	jalr	-1018(ra) # 80006ac0 <plicinithart>
  }

  scheduler();        
    80000ec2:	00002097          	auipc	ra,0x2
    80000ec6:	984080e7          	jalr	-1660(ra) # 80002846 <scheduler>
    consoleinit();
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	572080e7          	jalr	1394(ra) # 8000043c <consoleinit>
    printfinit();
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	882080e7          	jalr	-1918(ra) # 80000754 <printfinit>
    printf("\n");
    80000eda:	00008517          	auipc	a0,0x8
    80000ede:	4fe50513          	addi	a0,a0,1278 # 800093d8 <digits+0x398>
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	692080e7          	jalr	1682(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000eea:	00008517          	auipc	a0,0x8
    80000eee:	1b650513          	addi	a0,a0,438 # 800090a0 <digits+0x60>
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	682080e7          	jalr	1666(ra) # 80000574 <printf>
    printf("\n");
    80000efa:	00008517          	auipc	a0,0x8
    80000efe:	4de50513          	addi	a0,a0,1246 # 800093d8 <digits+0x398>
    80000f02:	fffff097          	auipc	ra,0xfffff
    80000f06:	672080e7          	jalr	1650(ra) # 80000574 <printf>
    kinit();         // physical page allocator
    80000f0a:	00000097          	auipc	ra,0x0
    80000f0e:	b8c080e7          	jalr	-1140(ra) # 80000a96 <kinit>
    kvminit();       // create kernel page table
    80000f12:	00000097          	auipc	ra,0x0
    80000f16:	356080e7          	jalr	854(ra) # 80001268 <kvminit>
    kvminithart();   // turn on paging
    80000f1a:	00000097          	auipc	ra,0x0
    80000f1e:	068080e7          	jalr	104(ra) # 80000f82 <kvminithart>
    procinit();      // process table
    80000f22:	00001097          	auipc	ra,0x1
    80000f26:	206080e7          	jalr	518(ra) # 80002128 <procinit>
    trapinit();      // trap vectors
    80000f2a:	00002097          	auipc	ra,0x2
    80000f2e:	056080e7          	jalr	86(ra) # 80002f80 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	076080e7          	jalr	118(ra) # 80002fa8 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00006097          	auipc	ra,0x6
    80000f3e:	b70080e7          	jalr	-1168(ra) # 80006aaa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00006097          	auipc	ra,0x6
    80000f46:	b7e080e7          	jalr	-1154(ra) # 80006ac0 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	7d6080e7          	jalr	2006(ra) # 80003720 <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	e68080e7          	jalr	-408(ra) # 80003dba <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	128080e7          	jalr	296(ra) # 80005082 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00006097          	auipc	ra,0x6
    80000f66:	c80080e7          	jalr	-896(ra) # 80006be2 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	5de080e7          	jalr	1502(ra) # 80002548 <userinit>
    __sync_synchronize();
    80000f72:	0ff0000f          	fence
    started = 1;
    80000f76:	4785                	li	a5,1
    80000f78:	00009717          	auipc	a4,0x9
    80000f7c:	0af72023          	sw	a5,160(a4) # 8000a018 <started>
    80000f80:	b789                	j	80000ec2 <main+0x56>

0000000080000f82 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f82:	1141                	addi	sp,sp,-16
    80000f84:	e422                	sd	s0,8(sp)
    80000f86:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f88:	00009797          	auipc	a5,0x9
    80000f8c:	0987b783          	ld	a5,152(a5) # 8000a020 <kernel_pagetable>
    80000f90:	83b1                	srli	a5,a5,0xc
    80000f92:	577d                	li	a4,-1
    80000f94:	177e                	slli	a4,a4,0x3f
    80000f96:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f98:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f9c:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa0:	6422                	ld	s0,8(sp)
    80000fa2:	0141                	addi	sp,sp,16
    80000fa4:	8082                	ret

0000000080000fa6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fa6:	7139                	addi	sp,sp,-64
    80000fa8:	fc06                	sd	ra,56(sp)
    80000faa:	f822                	sd	s0,48(sp)
    80000fac:	f426                	sd	s1,40(sp)
    80000fae:	f04a                	sd	s2,32(sp)
    80000fb0:	ec4e                	sd	s3,24(sp)
    80000fb2:	e852                	sd	s4,16(sp)
    80000fb4:	e456                	sd	s5,8(sp)
    80000fb6:	e05a                	sd	s6,0(sp)
    80000fb8:	0080                	addi	s0,sp,64
    80000fba:	84aa                	mv	s1,a0
    80000fbc:	89ae                	mv	s3,a1
    80000fbe:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc0:	57fd                	li	a5,-1
    80000fc2:	83e9                	srli	a5,a5,0x1a
    80000fc4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fc6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fc8:	04b7f263          	bgeu	a5,a1,8000100c <walk+0x66>
    panic("walk");
    80000fcc:	00008517          	auipc	a0,0x8
    80000fd0:	10450513          	addi	a0,a0,260 # 800090d0 <digits+0x90>
    80000fd4:	fffff097          	auipc	ra,0xfffff
    80000fd8:	556080e7          	jalr	1366(ra) # 8000052a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fdc:	060a8663          	beqz	s5,80001048 <walk+0xa2>
    80000fe0:	00000097          	auipc	ra,0x0
    80000fe4:	af2080e7          	jalr	-1294(ra) # 80000ad2 <kalloc>
    80000fe8:	84aa                	mv	s1,a0
    80000fea:	c529                	beqz	a0,80001034 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000fec:	6605                	lui	a2,0x1
    80000fee:	4581                	li	a1,0
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	cce080e7          	jalr	-818(ra) # 80000cbe <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ff8:	00c4d793          	srli	a5,s1,0xc
    80000ffc:	07aa                	slli	a5,a5,0xa
    80000ffe:	0017e793          	ori	a5,a5,1
    80001002:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001006:	3a5d                	addiw	s4,s4,-9
    80001008:	036a0063          	beq	s4,s6,80001028 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000100c:	0149d933          	srl	s2,s3,s4
    80001010:	1ff97913          	andi	s2,s2,511
    80001014:	090e                	slli	s2,s2,0x3
    80001016:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001018:	00093483          	ld	s1,0(s2)
    8000101c:	0014f793          	andi	a5,s1,1
    80001020:	dfd5                	beqz	a5,80000fdc <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001022:	80a9                	srli	s1,s1,0xa
    80001024:	04b2                	slli	s1,s1,0xc
    80001026:	b7c5                	j	80001006 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001028:	00c9d513          	srli	a0,s3,0xc
    8000102c:	1ff57513          	andi	a0,a0,511
    80001030:	050e                	slli	a0,a0,0x3
    80001032:	9526                	add	a0,a0,s1
}
    80001034:	70e2                	ld	ra,56(sp)
    80001036:	7442                	ld	s0,48(sp)
    80001038:	74a2                	ld	s1,40(sp)
    8000103a:	7902                	ld	s2,32(sp)
    8000103c:	69e2                	ld	s3,24(sp)
    8000103e:	6a42                	ld	s4,16(sp)
    80001040:	6aa2                	ld	s5,8(sp)
    80001042:	6b02                	ld	s6,0(sp)
    80001044:	6121                	addi	sp,sp,64
    80001046:	8082                	ret
        return 0;
    80001048:	4501                	li	a0,0
    8000104a:	b7ed                	j	80001034 <walk+0x8e>

000000008000104c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000104c:	57fd                	li	a5,-1
    8000104e:	83e9                	srli	a5,a5,0x1a
    80001050:	00b7f463          	bgeu	a5,a1,80001058 <walkaddr+0xc>
    return 0;
    80001054:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001056:	8082                	ret
{
    80001058:	1141                	addi	sp,sp,-16
    8000105a:	e406                	sd	ra,8(sp)
    8000105c:	e022                	sd	s0,0(sp)
    8000105e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001060:	4601                	li	a2,0
    80001062:	00000097          	auipc	ra,0x0
    80001066:	f44080e7          	jalr	-188(ra) # 80000fa6 <walk>
  if(pte == 0)
    8000106a:	c105                	beqz	a0,8000108a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000106c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000106e:	0117f693          	andi	a3,a5,17
    80001072:	4745                	li	a4,17
    return 0;
    80001074:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001076:	00e68663          	beq	a3,a4,80001082 <walkaddr+0x36>
}
    8000107a:	60a2                	ld	ra,8(sp)
    8000107c:	6402                	ld	s0,0(sp)
    8000107e:	0141                	addi	sp,sp,16
    80001080:	8082                	ret
  pa = PTE2PA(*pte);
    80001082:	00a7d513          	srli	a0,a5,0xa
    80001086:	0532                	slli	a0,a0,0xc
  return pa;
    80001088:	bfcd                	j	8000107a <walkaddr+0x2e>
    return 0;
    8000108a:	4501                	li	a0,0
    8000108c:	b7fd                	j	8000107a <walkaddr+0x2e>

000000008000108e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000108e:	715d                	addi	sp,sp,-80
    80001090:	e486                	sd	ra,72(sp)
    80001092:	e0a2                	sd	s0,64(sp)
    80001094:	fc26                	sd	s1,56(sp)
    80001096:	f84a                	sd	s2,48(sp)
    80001098:	f44e                	sd	s3,40(sp)
    8000109a:	f052                	sd	s4,32(sp)
    8000109c:	ec56                	sd	s5,24(sp)
    8000109e:	e85a                	sd	s6,16(sp)
    800010a0:	e45e                	sd	s7,8(sp)
    800010a2:	e062                	sd	s8,0(sp)
    800010a4:	0880                	addi	s0,sp,80
    800010a6:	8b2a                	mv	s6,a0
    800010a8:	8c2e                	mv	s8,a1
    800010aa:	89ba                	mv	s3,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010ac:	777d                	lui	a4,0xfffff
    800010ae:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010b2:	fff60a13          	addi	s4,a2,-1 # fff <_entry-0x7ffff001>
    800010b6:	9a2e                	add	s4,s4,a1
    800010b8:	00ea7a33          	and	s4,s4,a4
  a = PGROUNDDOWN(va);
    800010bc:	893e                	mv	s2,a5
    800010be:	40f68ab3          	sub	s5,a3,a5
    if(*pte & PTE_PG){ //if paged out, turn off valid flag 
       *pte &= ~PTE_V;
     }
    if(a == last)
      break;
    a += PGSIZE;
    800010c2:	6b85                	lui	s7,0x1
    800010c4:	a0ad                	j	8000112e <mappages+0xa0>
      printf("In mappages: walk operation failed \n") ;
    800010c6:	00008517          	auipc	a0,0x8
    800010ca:	01250513          	addi	a0,a0,18 # 800090d8 <digits+0x98>
    800010ce:	fffff097          	auipc	ra,0xfffff
    800010d2:	4a6080e7          	jalr	1190(ra) # 80000574 <printf>
      return -1;
    800010d6:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800010d8:	60a6                	ld	ra,72(sp)
    800010da:	6406                	ld	s0,64(sp)
    800010dc:	74e2                	ld	s1,56(sp)
    800010de:	7942                	ld	s2,48(sp)
    800010e0:	79a2                	ld	s3,40(sp)
    800010e2:	7a02                	ld	s4,32(sp)
    800010e4:	6ae2                	ld	s5,24(sp)
    800010e6:	6b42                	ld	s6,16(sp)
    800010e8:	6ba2                	ld	s7,8(sp)
    800010ea:	6c02                	ld	s8,0(sp)
    800010ec:	6161                	addi	sp,sp,80
    800010ee:	8082                	ret
      printf("a is %d \n", a);
    800010f0:	85ca                	mv	a1,s2
    800010f2:	00008517          	auipc	a0,0x8
    800010f6:	00e50513          	addi	a0,a0,14 # 80009100 <digits+0xc0>
    800010fa:	fffff097          	auipc	ra,0xfffff
    800010fe:	47a080e7          	jalr	1146(ra) # 80000574 <printf>
      printf("va is %d \n", va);
    80001102:	85e2                	mv	a1,s8
    80001104:	00008517          	auipc	a0,0x8
    80001108:	20c50513          	addi	a0,a0,524 # 80009310 <digits+0x2d0>
    8000110c:	fffff097          	auipc	ra,0xfffff
    80001110:	468080e7          	jalr	1128(ra) # 80000574 <printf>
      panic("remap");
    80001114:	00008517          	auipc	a0,0x8
    80001118:	ffc50513          	addi	a0,a0,-4 # 80009110 <digits+0xd0>
    8000111c:	fffff097          	auipc	ra,0xfffff
    80001120:	40e080e7          	jalr	1038(ra) # 8000052a <panic>
       *pte &= ~PTE_V;
    80001124:	98f9                	andi	s1,s1,-2
    80001126:	e104                	sd	s1,0(a0)
    if(a == last)
    80001128:	03490b63          	beq	s2,s4,8000115e <mappages+0xd0>
    a += PGSIZE;
    8000112c:	995e                	add	s2,s2,s7
  for(;;){
    8000112e:	012a84b3          	add	s1,s5,s2
    if((pte = walk(pagetable, a, 1)) == 0){
    80001132:	4605                	li	a2,1
    80001134:	85ca                	mv	a1,s2
    80001136:	855a                	mv	a0,s6
    80001138:	00000097          	auipc	ra,0x0
    8000113c:	e6e080e7          	jalr	-402(ra) # 80000fa6 <walk>
    80001140:	d159                	beqz	a0,800010c6 <mappages+0x38>
    if(*pte & PTE_V){
    80001142:	611c                	ld	a5,0(a0)
    80001144:	8b85                	andi	a5,a5,1
    80001146:	f7cd                	bnez	a5,800010f0 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001148:	80b1                	srli	s1,s1,0xc
    8000114a:	04aa                	slli	s1,s1,0xa
    8000114c:	0134e4b3          	or	s1,s1,s3
    if(*pte & PTE_PG){ //if paged out, turn off valid flag 
    80001150:	2009f793          	andi	a5,s3,512
    80001154:	fbe1                	bnez	a5,80001124 <mappages+0x96>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001156:	0014e493          	ori	s1,s1,1
    8000115a:	e104                	sd	s1,0(a0)
    8000115c:	b7f1                	j	80001128 <mappages+0x9a>
  return 0;
    8000115e:	4501                	li	a0,0
    80001160:	bfa5                	j	800010d8 <mappages+0x4a>

0000000080001162 <kvmmap>:
{
    80001162:	1141                	addi	sp,sp,-16
    80001164:	e406                	sd	ra,8(sp)
    80001166:	e022                	sd	s0,0(sp)
    80001168:	0800                	addi	s0,sp,16
    8000116a:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000116c:	86b2                	mv	a3,a2
    8000116e:	863e                	mv	a2,a5
    80001170:	00000097          	auipc	ra,0x0
    80001174:	f1e080e7          	jalr	-226(ra) # 8000108e <mappages>
    80001178:	e509                	bnez	a0,80001182 <kvmmap+0x20>
}
    8000117a:	60a2                	ld	ra,8(sp)
    8000117c:	6402                	ld	s0,0(sp)
    8000117e:	0141                	addi	sp,sp,16
    80001180:	8082                	ret
    panic("kvmmap");
    80001182:	00008517          	auipc	a0,0x8
    80001186:	f9650513          	addi	a0,a0,-106 # 80009118 <digits+0xd8>
    8000118a:	fffff097          	auipc	ra,0xfffff
    8000118e:	3a0080e7          	jalr	928(ra) # 8000052a <panic>

0000000080001192 <kvmmake>:
{
    80001192:	1101                	addi	sp,sp,-32
    80001194:	ec06                	sd	ra,24(sp)
    80001196:	e822                	sd	s0,16(sp)
    80001198:	e426                	sd	s1,8(sp)
    8000119a:	e04a                	sd	s2,0(sp)
    8000119c:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	934080e7          	jalr	-1740(ra) # 80000ad2 <kalloc>
    800011a6:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a8:	6605                	lui	a2,0x1
    800011aa:	4581                	li	a1,0
    800011ac:	00000097          	auipc	ra,0x0
    800011b0:	b12080e7          	jalr	-1262(ra) # 80000cbe <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011b4:	4719                	li	a4,6
    800011b6:	6685                	lui	a3,0x1
    800011b8:	10000637          	lui	a2,0x10000
    800011bc:	100005b7          	lui	a1,0x10000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	fa0080e7          	jalr	-96(ra) # 80001162 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011ca:	4719                	li	a4,6
    800011cc:	6685                	lui	a3,0x1
    800011ce:	10001637          	lui	a2,0x10001
    800011d2:	100015b7          	lui	a1,0x10001
    800011d6:	8526                	mv	a0,s1
    800011d8:	00000097          	auipc	ra,0x0
    800011dc:	f8a080e7          	jalr	-118(ra) # 80001162 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011e0:	4719                	li	a4,6
    800011e2:	004006b7          	lui	a3,0x400
    800011e6:	0c000637          	lui	a2,0xc000
    800011ea:	0c0005b7          	lui	a1,0xc000
    800011ee:	8526                	mv	a0,s1
    800011f0:	00000097          	auipc	ra,0x0
    800011f4:	f72080e7          	jalr	-142(ra) # 80001162 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f8:	00008917          	auipc	s2,0x8
    800011fc:	e0890913          	addi	s2,s2,-504 # 80009000 <etext>
    80001200:	4729                	li	a4,10
    80001202:	80008697          	auipc	a3,0x80008
    80001206:	dfe68693          	addi	a3,a3,-514 # 9000 <_entry-0x7fff7000>
    8000120a:	4605                	li	a2,1
    8000120c:	067e                	slli	a2,a2,0x1f
    8000120e:	85b2                	mv	a1,a2
    80001210:	8526                	mv	a0,s1
    80001212:	00000097          	auipc	ra,0x0
    80001216:	f50080e7          	jalr	-176(ra) # 80001162 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000121a:	4719                	li	a4,6
    8000121c:	46c5                	li	a3,17
    8000121e:	06ee                	slli	a3,a3,0x1b
    80001220:	412686b3          	sub	a3,a3,s2
    80001224:	864a                	mv	a2,s2
    80001226:	85ca                	mv	a1,s2
    80001228:	8526                	mv	a0,s1
    8000122a:	00000097          	auipc	ra,0x0
    8000122e:	f38080e7          	jalr	-200(ra) # 80001162 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001232:	4729                	li	a4,10
    80001234:	6685                	lui	a3,0x1
    80001236:	00007617          	auipc	a2,0x7
    8000123a:	dca60613          	addi	a2,a2,-566 # 80008000 <_trampoline>
    8000123e:	040005b7          	lui	a1,0x4000
    80001242:	15fd                	addi	a1,a1,-1
    80001244:	05b2                	slli	a1,a1,0xc
    80001246:	8526                	mv	a0,s1
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	f1a080e7          	jalr	-230(ra) # 80001162 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001250:	8526                	mv	a0,s1
    80001252:	00001097          	auipc	ra,0x1
    80001256:	e40080e7          	jalr	-448(ra) # 80002092 <proc_mapstacks>
}
    8000125a:	8526                	mv	a0,s1
    8000125c:	60e2                	ld	ra,24(sp)
    8000125e:	6442                	ld	s0,16(sp)
    80001260:	64a2                	ld	s1,8(sp)
    80001262:	6902                	ld	s2,0(sp)
    80001264:	6105                	addi	sp,sp,32
    80001266:	8082                	ret

0000000080001268 <kvminit>:
{
    80001268:	1141                	addi	sp,sp,-16
    8000126a:	e406                	sd	ra,8(sp)
    8000126c:	e022                	sd	s0,0(sp)
    8000126e:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001270:	00000097          	auipc	ra,0x0
    80001274:	f22080e7          	jalr	-222(ra) # 80001192 <kvmmake>
    80001278:	00009797          	auipc	a5,0x9
    8000127c:	daa7b423          	sd	a0,-600(a5) # 8000a020 <kernel_pagetable>
}
    80001280:	60a2                	ld	ra,8(sp)
    80001282:	6402                	ld	s0,0(sp)
    80001284:	0141                	addi	sp,sp,16
    80001286:	8082                	ret

0000000080001288 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001288:	715d                	addi	sp,sp,-80
    8000128a:	e486                	sd	ra,72(sp)
    8000128c:	e0a2                	sd	s0,64(sp)
    8000128e:	fc26                	sd	s1,56(sp)
    80001290:	f84a                	sd	s2,48(sp)
    80001292:	f44e                	sd	s3,40(sp)
    80001294:	f052                	sd	s4,32(sp)
    80001296:	ec56                	sd	s5,24(sp)
    80001298:	e85a                	sd	s6,16(sp)
    8000129a:	e45e                	sd	s7,8(sp)
    8000129c:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000129e:	03459793          	slli	a5,a1,0x34
    800012a2:	e795                	bnez	a5,800012ce <uvmunmap+0x46>
    800012a4:	8a2a                	mv	s4,a0
    800012a6:	892e                	mv	s2,a1
    800012a8:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012aa:	0632                	slli	a2,a2,0xc
    800012ac:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0 && (*pte & PTE_PG) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012b0:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012b2:	6b05                	lui	s6,0x1
    800012b4:	0735e263          	bltu	a1,s3,80001318 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b8:	60a6                	ld	ra,72(sp)
    800012ba:	6406                	ld	s0,64(sp)
    800012bc:	74e2                	ld	s1,56(sp)
    800012be:	7942                	ld	s2,48(sp)
    800012c0:	79a2                	ld	s3,40(sp)
    800012c2:	7a02                	ld	s4,32(sp)
    800012c4:	6ae2                	ld	s5,24(sp)
    800012c6:	6b42                	ld	s6,16(sp)
    800012c8:	6ba2                	ld	s7,8(sp)
    800012ca:	6161                	addi	sp,sp,80
    800012cc:	8082                	ret
    panic("uvmunmap: not aligned");
    800012ce:	00008517          	auipc	a0,0x8
    800012d2:	e5250513          	addi	a0,a0,-430 # 80009120 <digits+0xe0>
    800012d6:	fffff097          	auipc	ra,0xfffff
    800012da:	254080e7          	jalr	596(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    800012de:	00008517          	auipc	a0,0x8
    800012e2:	e5a50513          	addi	a0,a0,-422 # 80009138 <digits+0xf8>
    800012e6:	fffff097          	auipc	ra,0xfffff
    800012ea:	244080e7          	jalr	580(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012ee:	00008517          	auipc	a0,0x8
    800012f2:	e5a50513          	addi	a0,a0,-422 # 80009148 <digits+0x108>
    800012f6:	fffff097          	auipc	ra,0xfffff
    800012fa:	234080e7          	jalr	564(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012fe:	00008517          	auipc	a0,0x8
    80001302:	e6250513          	addi	a0,a0,-414 # 80009160 <digits+0x120>
    80001306:	fffff097          	auipc	ra,0xfffff
    8000130a:	224080e7          	jalr	548(ra) # 8000052a <panic>
    *pte = 0;
    8000130e:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001312:	995a                	add	s2,s2,s6
    80001314:	fb3972e3          	bgeu	s2,s3,800012b8 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001318:	4601                	li	a2,0
    8000131a:	85ca                	mv	a1,s2
    8000131c:	8552                	mv	a0,s4
    8000131e:	00000097          	auipc	ra,0x0
    80001322:	c88080e7          	jalr	-888(ra) # 80000fa6 <walk>
    80001326:	84aa                	mv	s1,a0
    80001328:	d95d                	beqz	a0,800012de <uvmunmap+0x56>
    if((*pte & PTE_V) == 0 && (*pte & PTE_PG) == 0)
    8000132a:	6108                	ld	a0,0(a0)
    8000132c:	20157793          	andi	a5,a0,513
    80001330:	dfdd                	beqz	a5,800012ee <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001332:	3ff57793          	andi	a5,a0,1023
    80001336:	fd7784e3          	beq	a5,s7,800012fe <uvmunmap+0x76>
    if(do_free){
    8000133a:	fc0a8ae3          	beqz	s5,8000130e <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000133e:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001340:	0532                	slli	a0,a0,0xc
    80001342:	fffff097          	auipc	ra,0xfffff
    80001346:	694080e7          	jalr	1684(ra) # 800009d6 <kfree>
    8000134a:	b7d1                	j	8000130e <uvmunmap+0x86>

000000008000134c <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000134c:	1101                	addi	sp,sp,-32
    8000134e:	ec06                	sd	ra,24(sp)
    80001350:	e822                	sd	s0,16(sp)
    80001352:	e426                	sd	s1,8(sp)
    80001354:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001356:	fffff097          	auipc	ra,0xfffff
    8000135a:	77c080e7          	jalr	1916(ra) # 80000ad2 <kalloc>
    8000135e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001360:	c519                	beqz	a0,8000136e <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001362:	6605                	lui	a2,0x1
    80001364:	4581                	li	a1,0
    80001366:	00000097          	auipc	ra,0x0
    8000136a:	958080e7          	jalr	-1704(ra) # 80000cbe <memset>
  return pagetable;
}
    8000136e:	8526                	mv	a0,s1
    80001370:	60e2                	ld	ra,24(sp)
    80001372:	6442                	ld	s0,16(sp)
    80001374:	64a2                	ld	s1,8(sp)
    80001376:	6105                	addi	sp,sp,32
    80001378:	8082                	ret

000000008000137a <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000137a:	7179                	addi	sp,sp,-48
    8000137c:	f406                	sd	ra,40(sp)
    8000137e:	f022                	sd	s0,32(sp)
    80001380:	ec26                	sd	s1,24(sp)
    80001382:	e84a                	sd	s2,16(sp)
    80001384:	e44e                	sd	s3,8(sp)
    80001386:	e052                	sd	s4,0(sp)
    80001388:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000138a:	6785                	lui	a5,0x1
    8000138c:	04f67863          	bgeu	a2,a5,800013dc <uvminit+0x62>
    80001390:	8a2a                	mv	s4,a0
    80001392:	89ae                	mv	s3,a1
    80001394:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001396:	fffff097          	auipc	ra,0xfffff
    8000139a:	73c080e7          	jalr	1852(ra) # 80000ad2 <kalloc>
    8000139e:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013a0:	6605                	lui	a2,0x1
    800013a2:	4581                	li	a1,0
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	91a080e7          	jalr	-1766(ra) # 80000cbe <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013ac:	4779                	li	a4,30
    800013ae:	86ca                	mv	a3,s2
    800013b0:	6605                	lui	a2,0x1
    800013b2:	4581                	li	a1,0
    800013b4:	8552                	mv	a0,s4
    800013b6:	00000097          	auipc	ra,0x0
    800013ba:	cd8080e7          	jalr	-808(ra) # 8000108e <mappages>
  memmove(mem, src, sz);
    800013be:	8626                	mv	a2,s1
    800013c0:	85ce                	mv	a1,s3
    800013c2:	854a                	mv	a0,s2
    800013c4:	00000097          	auipc	ra,0x0
    800013c8:	956080e7          	jalr	-1706(ra) # 80000d1a <memmove>
}
    800013cc:	70a2                	ld	ra,40(sp)
    800013ce:	7402                	ld	s0,32(sp)
    800013d0:	64e2                	ld	s1,24(sp)
    800013d2:	6942                	ld	s2,16(sp)
    800013d4:	69a2                	ld	s3,8(sp)
    800013d6:	6a02                	ld	s4,0(sp)
    800013d8:	6145                	addi	sp,sp,48
    800013da:	8082                	ret
    panic("inituvm: more than a page");
    800013dc:	00008517          	auipc	a0,0x8
    800013e0:	d9c50513          	addi	a0,a0,-612 # 80009178 <digits+0x138>
    800013e4:	fffff097          	auipc	ra,0xfffff
    800013e8:	146080e7          	jalr	326(ra) # 8000052a <panic>

00000000800013ec <update_pages_counters>:


// task 1 

void
update_pages_counters(){
    800013ec:	7139                	addi	sp,sp,-64
    800013ee:	fc06                	sd	ra,56(sp)
    800013f0:	f822                	sd	s0,48(sp)
    800013f2:	f426                	sd	s1,40(sp)
    800013f4:	f04a                	sd	s2,32(sp)
    800013f6:	ec4e                	sd	s3,24(sp)
    800013f8:	e852                	sd	s4,16(sp)
    800013fa:	e456                	sd	s5,8(sp)
    800013fc:	0080                	addi	s0,sp,64
  struct proc *p=myproc();
    800013fe:	00001097          	auipc	ra,0x1
    80001402:	e06080e7          	jalr	-506(ra) # 80002204 <myproc>
    80001406:	8a2a                	mv	s4,a0
  for(int i=0 ; i<MAX_PSYC_PAGES; i++){
    80001408:	17050493          	addi	s1,a0,368
    8000140c:	23050993          	addi	s3,a0,560
    if (p->ram_pages.pages[i].is_used){
      pte_t *pte=walk(p->pagetable,p->ram_pages.pages[i].virtual_address,0);
      p->ram_pages.pages[i].page_counter>>=1; //shift counter right
      if (*pte & PTE_A){
        p->ram_pages.pages[i].page_counter |= 1<<31; //put 1 in the msb
    80001410:	80000ab7          	lui	s5,0x80000
    80001414:	a021                	j	8000141c <update_pages_counters+0x30>
  for(int i=0 ; i<MAX_PSYC_PAGES; i++){
    80001416:	04b1                	addi	s1,s1,12
    80001418:	03348d63          	beq	s1,s3,80001452 <update_pages_counters+0x66>
    if (p->ram_pages.pages[i].is_used){
    8000141c:	40dc                	lw	a5,4(s1)
    8000141e:	dfe5                	beqz	a5,80001416 <update_pages_counters+0x2a>
      pte_t *pte=walk(p->pagetable,p->ram_pages.pages[i].virtual_address,0);
    80001420:	4601                	li	a2,0
    80001422:	0004e583          	lwu	a1,0(s1)
    80001426:	050a3503          	ld	a0,80(s4) # fffffffffffff050 <end+0xffffffff7ffd1050>
    8000142a:	00000097          	auipc	ra,0x0
    8000142e:	b7c080e7          	jalr	-1156(ra) # 80000fa6 <walk>
      p->ram_pages.pages[i].page_counter>>=1; //shift counter right
    80001432:	449c                	lw	a5,8(s1)
    80001434:	0017d79b          	srliw	a5,a5,0x1
    80001438:	c49c                	sw	a5,8(s1)
      if (*pte & PTE_A){
    8000143a:	6118                	ld	a4,0(a0)
    8000143c:	04077713          	andi	a4,a4,64
    80001440:	db79                	beqz	a4,80001416 <update_pages_counters+0x2a>
        p->ram_pages.pages[i].page_counter |= 1<<31; //put 1 in the msb
    80001442:	0157e7b3          	or	a5,a5,s5
    80001446:	c49c                	sw	a5,8(s1)
        *pte &= ~PTE_A; //turn off flag
    80001448:	611c                	ld	a5,0(a0)
    8000144a:	fbf7f793          	andi	a5,a5,-65
    8000144e:	e11c                	sd	a5,0(a0)
    80001450:	b7d9                	j	80001416 <update_pages_counters+0x2a>
      }
    }
  }
}
    80001452:	70e2                	ld	ra,56(sp)
    80001454:	7442                	ld	s0,48(sp)
    80001456:	74a2                	ld	s1,40(sp)
    80001458:	7902                	ld	s2,32(sp)
    8000145a:	69e2                	ld	s3,24(sp)
    8000145c:	6a42                	ld	s4,16(sp)
    8000145e:	6aa2                	ld	s5,8(sp)
    80001460:	6121                	addi	sp,sp,64
    80001462:	8082                	ret

0000000080001464 <find_free_page_in_ram>:

//check if there is a free page in ram mem, of so, return it's PSYC addr
int
find_free_page_in_ram(void){
    80001464:	1141                	addi	sp,sp,-16
    80001466:	e406                	sd	ra,8(sp)
    80001468:	e022                	sd	s0,0(sp)
    8000146a:	0800                	addi	s0,sp,16
  int free_index=0;
  struct proc *p =  myproc();
    8000146c:	00001097          	auipc	ra,0x1
    80001470:	d98080e7          	jalr	-616(ra) # 80002204 <myproc>
  while(free_index<16){
    80001474:	17450793          	addi	a5,a0,372
  int free_index=0;
    80001478:	4501                	li	a0,0
  while(free_index<16){
    8000147a:	46c1                	li	a3,16
    //finidng free page in swap file memory
    if(!p->ram_pages.pages[free_index].is_used)
    8000147c:	4398                	lw	a4,0(a5)
    8000147e:	c711                	beqz	a4,8000148a <find_free_page_in_ram+0x26>
      return free_index; 
    else
      free_index++;
    80001480:	2505                	addiw	a0,a0,1
  while(free_index<16){
    80001482:	07b1                	addi	a5,a5,12
    80001484:	fed51ce3          	bne	a0,a3,8000147c <find_free_page_in_ram+0x18>
  }
  return -1;
    80001488:	557d                	li	a0,-1
}
    8000148a:	60a2                	ld	ra,8(sp)
    8000148c:	6402                	ld	s0,0(sp)
    8000148e:	0141                	addi	sp,sp,16
    80001490:	8082                	ret

0000000080001492 <ones_counter>:

// for SELECTION=LAPA ; count num of '1' in page counter
uint 
ones_counter(uint page_counter){
    80001492:	1141                	addi	sp,sp,-16
    80001494:	e422                	sd	s0,8(sp)
    80001496:	0800                	addi	s0,sp,16
    80001498:	87aa                	mv	a5,a0
  uint ones_counter=0;
  uint page_counter_val=page_counter;
  while (page_counter_val > 0){
    8000149a:	c919                	beqz	a0,800014b0 <ones_counter+0x1e>
  uint ones_counter=0;
    8000149c:	4501                	li	a0,0
    8000149e:	a021                	j	800014a6 <ones_counter+0x14>
    if (page_counter_val % 2 != 0)
      ones_counter++;
    page_counter_val = (page_counter_val >> 1);
    800014a0:	0017d79b          	srliw	a5,a5,0x1
  while (page_counter_val > 0){
    800014a4:	c791                	beqz	a5,800014b0 <ones_counter+0x1e>
    if (page_counter_val % 2 != 0)
    800014a6:	0017f713          	andi	a4,a5,1
    800014aa:	db7d                	beqz	a4,800014a0 <ones_counter+0xe>
      ones_counter++;
    800014ac:	2505                	addiw	a0,a0,1
    800014ae:	bfcd                	j	800014a0 <ones_counter+0xe>
  }
  return ones_counter;
}
    800014b0:	6422                	ld	s0,8(sp)
    800014b2:	0141                	addi	sp,sp,16
    800014b4:	8082                	ret

00000000800014b6 <use_NFUA>:

uint
use_NFUA(){
    800014b6:	715d                	addi	sp,sp,-80
    800014b8:	e486                	sd	ra,72(sp)
    800014ba:	e0a2                	sd	s0,64(sp)
    800014bc:	fc26                	sd	s1,56(sp)
    800014be:	f84a                	sd	s2,48(sp)
    800014c0:	f44e                	sd	s3,40(sp)
    800014c2:	f052                	sd	s4,32(sp)
    800014c4:	ec56                	sd	s5,24(sp)
    800014c6:	e85a                	sd	s6,16(sp)
    800014c8:	e45e                	sd	s7,8(sp)
    800014ca:	e062                	sd	s8,0(sp)
    800014cc:	0880                	addi	s0,sp,80
  uint min_page_index=0;
  uint min_page_counter=0xffffffff; //max int value
  struct proc *p =  myproc();
    800014ce:	00001097          	auipc	ra,0x1
    800014d2:	d36080e7          	jalr	-714(ra) # 80002204 <myproc>
    800014d6:	8aaa                	mv	s5,a0
  for (int i=0; i<MAX_PSYC_PAGES; i++){
    800014d8:	17050493          	addi	s1,a0,368
    800014dc:	4901                	li	s2,0
  uint min_page_counter=0xffffffff; //max int value
    800014de:	5bfd                	li	s7,-1
  uint min_page_index=0;
    800014e0:	4c01                	li	s8,0
    //finidng occupied page in swap file memory
    if(p->ram_pages.pages[i].is_used){
      uint64 a = PGROUNDDOWN(p->ram_pages.pages[i].virtual_address);
    800014e2:	7b7d                	lui	s6,0xfffff
  for (int i=0; i<MAX_PSYC_PAGES; i++){
    800014e4:	4a41                	li	s4,16
    800014e6:	a029                	j	800014f0 <use_NFUA+0x3a>
    800014e8:	2905                	addiw	s2,s2,1
    800014ea:	04b1                	addi	s1,s1,12
    800014ec:	03490b63          	beq	s2,s4,80001522 <use_NFUA+0x6c>
    if(p->ram_pages.pages[i].is_used){
    800014f0:	40dc                	lw	a5,4(s1)
    800014f2:	dbfd                	beqz	a5,800014e8 <use_NFUA+0x32>
      uint64 a = PGROUNDDOWN(p->ram_pages.pages[i].virtual_address);
    800014f4:	408c                	lw	a1,0(s1)
    800014f6:	0165f5b3          	and	a1,a1,s6
    800014fa:	1582                	slli	a1,a1,0x20
    800014fc:	9181                	srli	a1,a1,0x20
      pte_t *pte;
      if(((pte = walk(p->pagetable, a, 0)) != 0) && (*pte & PTE_V)){
    800014fe:	4601                	li	a2,0
    80001500:	050ab503          	ld	a0,80(s5) # ffffffff80000050 <end+0xfffffffefffd2050>
    80001504:	00000097          	auipc	ra,0x0
    80001508:	aa2080e7          	jalr	-1374(ra) # 80000fa6 <walk>
    8000150c:	dd71                	beqz	a0,800014e8 <use_NFUA+0x32>
    8000150e:	611c                	ld	a5,0(a0)
    80001510:	8b85                	andi	a5,a5,1
    80001512:	dbf9                	beqz	a5,800014e8 <use_NFUA+0x32>
        if (p->ram_pages.pages[i].page_counter<min_page_counter ){
    80001514:	449c                	lw	a5,8(s1)
    80001516:	fd77f9e3          	bgeu	a5,s7,800014e8 <use_NFUA+0x32>
          min_page_counter=p->ram_pages.pages[i].page_counter;
          min_page_index=i;
    8000151a:	00090c1b          	sext.w	s8,s2
          min_page_counter=p->ram_pages.pages[i].page_counter;
    8000151e:	8bbe                	mv	s7,a5
    80001520:	b7e1                	j	800014e8 <use_NFUA+0x32>
        }
      }
    }
  }
  return min_page_index;
}
    80001522:	8562                	mv	a0,s8
    80001524:	60a6                	ld	ra,72(sp)
    80001526:	6406                	ld	s0,64(sp)
    80001528:	74e2                	ld	s1,56(sp)
    8000152a:	7942                	ld	s2,48(sp)
    8000152c:	79a2                	ld	s3,40(sp)
    8000152e:	7a02                	ld	s4,32(sp)
    80001530:	6ae2                	ld	s5,24(sp)
    80001532:	6b42                	ld	s6,16(sp)
    80001534:	6ba2                	ld	s7,8(sp)
    80001536:	6c02                	ld	s8,0(sp)
    80001538:	6161                	addi	sp,sp,80
    8000153a:	8082                	ret

000000008000153c <use_LAPA>:

uint
use_LAPA(){
    8000153c:	7159                	addi	sp,sp,-112
    8000153e:	f486                	sd	ra,104(sp)
    80001540:	f0a2                	sd	s0,96(sp)
    80001542:	eca6                	sd	s1,88(sp)
    80001544:	e8ca                	sd	s2,80(sp)
    80001546:	e4ce                	sd	s3,72(sp)
    80001548:	e0d2                	sd	s4,64(sp)
    8000154a:	fc56                	sd	s5,56(sp)
    8000154c:	f85a                	sd	s6,48(sp)
    8000154e:	f45e                	sd	s7,40(sp)
    80001550:	f062                	sd	s8,32(sp)
    80001552:	ec66                	sd	s9,24(sp)
    80001554:	e86a                	sd	s10,16(sp)
    80001556:	e46e                	sd	s11,8(sp)
    80001558:	1880                	addi	s0,sp,112
  uint min_page_index=0;
  uint min_num_of_ones=0xffffffff; //max int value
  uint min_page_counter=0xffffffff;
  uint same_amount_of_ones_counter=0;
  struct proc *p =  myproc();
    8000155a:	00001097          	auipc	ra,0x1
    8000155e:	caa080e7          	jalr	-854(ra) # 80002204 <myproc>
    80001562:	8b2a                	mv	s6,a0
  // find page with minimal appears of '1'
  for (int i=0; i<MAX_PSYC_PAGES; i++){
    80001564:	17050993          	addi	s3,a0,368
  struct proc *p =  myproc();
    80001568:	84ce                	mv	s1,s3
  for (int i=0; i<MAX_PSYC_PAGES; i++){
    8000156a:	4901                	li	s2,0
  uint same_amount_of_ones_counter=0;
    8000156c:	4c81                	li	s9,0
  uint min_num_of_ones=0xffffffff; //max int value
    8000156e:	5c7d                	li	s8,-1
  uint min_page_index=0;
    80001570:	4d01                	li	s10,0
    uint cur_num_of_ones=0;
    //find occupied page in swap file memory
    if(p->ram_pages.pages[i].is_used){
      uint64 a = PGROUNDDOWN(p->ram_pages.pages[i].virtual_address);
    80001572:	7bfd                	lui	s7,0xfffff
      if(((pte = walk(p->pagetable, a, 0)) != 0) && (*pte & PTE_V)){
        cur_num_of_ones=ones_counter(p->ram_pages.pages[i].page_counter);
        if (cur_num_of_ones==min_num_of_ones)
          same_amount_of_ones_counter++; //CHECK IF BREAKS OUT TOTALLY
        else if(cur_num_of_ones<min_num_of_ones){
          same_amount_of_ones_counter=1;
    80001574:	4d85                	li	s11,1
  for (int i=0; i<MAX_PSYC_PAGES; i++){
    80001576:	4ac1                	li	s5,16
    80001578:	a031                	j	80001584 <use_LAPA+0x48>
          same_amount_of_ones_counter++; //CHECK IF BREAKS OUT TOTALLY
    8000157a:	2c85                	addiw	s9,s9,1
  for (int i=0; i<MAX_PSYC_PAGES; i++){
    8000157c:	2905                	addiw	s2,s2,1
    8000157e:	04b1                	addi	s1,s1,12
    80001580:	05590363          	beq	s2,s5,800015c6 <use_LAPA+0x8a>
    if(p->ram_pages.pages[i].is_used){
    80001584:	40dc                	lw	a5,4(s1)
    80001586:	dbfd                	beqz	a5,8000157c <use_LAPA+0x40>
      uint64 a = PGROUNDDOWN(p->ram_pages.pages[i].virtual_address);
    80001588:	408c                	lw	a1,0(s1)
    8000158a:	0175f5b3          	and	a1,a1,s7
    8000158e:	1582                	slli	a1,a1,0x20
    80001590:	9181                	srli	a1,a1,0x20
      if(((pte = walk(p->pagetable, a, 0)) != 0) && (*pte & PTE_V)){
    80001592:	4601                	li	a2,0
    80001594:	050b3503          	ld	a0,80(s6) # fffffffffffff050 <end+0xffffffff7ffd1050>
    80001598:	00000097          	auipc	ra,0x0
    8000159c:	a0e080e7          	jalr	-1522(ra) # 80000fa6 <walk>
    800015a0:	dd71                	beqz	a0,8000157c <use_LAPA+0x40>
    800015a2:	611c                	ld	a5,0(a0)
    800015a4:	8b85                	andi	a5,a5,1
    800015a6:	dbf9                	beqz	a5,8000157c <use_LAPA+0x40>
        cur_num_of_ones=ones_counter(p->ram_pages.pages[i].page_counter);
    800015a8:	4488                	lw	a0,8(s1)
    800015aa:	00000097          	auipc	ra,0x0
    800015ae:	ee8080e7          	jalr	-280(ra) # 80001492 <ones_counter>
    800015b2:	2501                	sext.w	a0,a0
        if (cur_num_of_ones==min_num_of_ones)
    800015b4:	fd8503e3          	beq	a0,s8,8000157a <use_LAPA+0x3e>
        else if(cur_num_of_ones<min_num_of_ones){
    800015b8:	fd8572e3          	bgeu	a0,s8,8000157c <use_LAPA+0x40>
          min_page_index=i;
    800015bc:	00090d1b          	sext.w	s10,s2
          min_num_of_ones=cur_num_of_ones;
    800015c0:	8c2a                	mv	s8,a0
          same_amount_of_ones_counter=1;
    800015c2:	8cee                	mv	s9,s11
    800015c4:	bf65                	j	8000157c <use_LAPA+0x40>
        }
      }
    }
  }
  // find page by minimal counter
  if (same_amount_of_ones_counter>1){
    800015c6:	4785                	li	a5,1
    800015c8:	0597f763          	bgeu	a5,s9,80001616 <use_LAPA+0xda>
    for (int i=0; i<MAX_PSYC_PAGES; i++){
    800015cc:	4481                	li	s1,0
  uint min_page_counter=0xffffffff;
    800015ce:	5bfd                	li	s7,-1
    //find occupied page in swap file memory
      if(p->ram_pages.pages[i].is_used){
        uint64 a = PGROUNDDOWN(p->ram_pages.pages[i].virtual_address);
    800015d0:	7afd                	lui	s5,0xfffff
    for (int i=0; i<MAX_PSYC_PAGES; i++){
    800015d2:	4a41                	li	s4,16
    800015d4:	a029                	j	800015de <use_LAPA+0xa2>
    800015d6:	2485                	addiw	s1,s1,1
    800015d8:	09b1                	addi	s3,s3,12
    800015da:	03448e63          	beq	s1,s4,80001616 <use_LAPA+0xda>
      if(p->ram_pages.pages[i].is_used){
    800015de:	0049a783          	lw	a5,4(s3) # 1004 <_entry-0x7fffeffc>
    800015e2:	dbf5                	beqz	a5,800015d6 <use_LAPA+0x9a>
        uint64 a = PGROUNDDOWN(p->ram_pages.pages[i].virtual_address);
    800015e4:	0009a583          	lw	a1,0(s3)
    800015e8:	0155f5b3          	and	a1,a1,s5
    800015ec:	1582                	slli	a1,a1,0x20
    800015ee:	9181                	srli	a1,a1,0x20
        pte_t *pte;
        if(((pte = walk(p->pagetable, a, 0)) != 0) && (*pte & PTE_V)){
    800015f0:	4601                	li	a2,0
    800015f2:	050b3503          	ld	a0,80(s6)
    800015f6:	00000097          	auipc	ra,0x0
    800015fa:	9b0080e7          	jalr	-1616(ra) # 80000fa6 <walk>
    800015fe:	dd61                	beqz	a0,800015d6 <use_LAPA+0x9a>
    80001600:	611c                	ld	a5,0(a0)
    80001602:	8b85                	andi	a5,a5,1
    80001604:	dbe9                	beqz	a5,800015d6 <use_LAPA+0x9a>
          if (p->ram_pages.pages[i].page_counter<min_page_counter ){
    80001606:	0089a783          	lw	a5,8(s3)
    8000160a:	fd77f6e3          	bgeu	a5,s7,800015d6 <use_LAPA+0x9a>
            min_page_counter=p->ram_pages.pages[i].page_counter;
            min_page_index=i;
    8000160e:	00048d1b          	sext.w	s10,s1
            min_page_counter=p->ram_pages.pages[i].page_counter;
    80001612:	8bbe                	mv	s7,a5
    80001614:	b7c9                	j	800015d6 <use_LAPA+0x9a>
        }
      }
    }
  }
  return min_page_index;
}
    80001616:	856a                	mv	a0,s10
    80001618:	70a6                	ld	ra,104(sp)
    8000161a:	7406                	ld	s0,96(sp)
    8000161c:	64e6                	ld	s1,88(sp)
    8000161e:	6946                	ld	s2,80(sp)
    80001620:	69a6                	ld	s3,72(sp)
    80001622:	6a06                	ld	s4,64(sp)
    80001624:	7ae2                	ld	s5,56(sp)
    80001626:	7b42                	ld	s6,48(sp)
    80001628:	7ba2                	ld	s7,40(sp)
    8000162a:	7c02                	ld	s8,32(sp)
    8000162c:	6ce2                	ld	s9,24(sp)
    8000162e:	6d42                	ld	s10,16(sp)
    80001630:	6da2                	ld	s11,8(sp)
    80001632:	6165                	addi	sp,sp,112
    80001634:	8082                	ret

0000000080001636 <find_occupied_page_in_ram>:
//   // }
  
// }

uint64
find_occupied_page_in_ram(void){
    80001636:	1141                	addi	sp,sp,-16
    80001638:	e406                	sd	ra,8(sp)
    8000163a:	e022                	sd	s0,0(sp)
    8000163c:	0800                	addi	s0,sp,16
  uint occupied_index=0;
  #if SELECTION == NFUA
    occupied_index=use_NFUA();
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	e78080e7          	jalr	-392(ra) # 800014b6 <use_NFUA>
    80001646:	2501                	sext.w	a0,a0

  #if SELECTION == LAPA
    occupied_index=use_LAPA();
  #endif

  if( occupied_index > 15){
    80001648:	47bd                	li	a5,15
    8000164a:	00a7e863          	bltu	a5,a0,8000165a <find_occupied_page_in_ram+0x24>
    //proc has a MAX_PSYC_PAGES pages
    panic("ram memory: somthing's wrong from find occupied page");
  }
  return occupied_index;
}
    8000164e:	1502                	slli	a0,a0,0x20
    80001650:	9101                	srli	a0,a0,0x20
    80001652:	60a2                	ld	ra,8(sp)
    80001654:	6402                	ld	s0,0(sp)
    80001656:	0141                	addi	sp,sp,16
    80001658:	8082                	ret
    panic("ram memory: somthing's wrong from find occupied page");
    8000165a:	00008517          	auipc	a0,0x8
    8000165e:	b3e50513          	addi	a0,a0,-1218 # 80009198 <digits+0x158>
    80001662:	fffff097          	auipc	ra,0xfffff
    80001666:	ec8080e7          	jalr	-312(ra) # 8000052a <panic>

000000008000166a <find_free_page_in_swapped>:

uint64
find_free_page_in_swapped(void){
    8000166a:	1141                	addi	sp,sp,-16
    8000166c:	e406                	sd	ra,8(sp)
    8000166e:	e022                	sd	s0,0(sp)
    80001670:	0800                	addi	s0,sp,16
  uint sp_index=0;
  struct proc *p =  myproc();
    80001672:	00001097          	auipc	ra,0x1
    80001676:	b92080e7          	jalr	-1134(ra) # 80002204 <myproc>
  while(sp_index<16){
    8000167a:	23c50513          	addi	a0,a0,572
  uint sp_index=0;
    8000167e:	4781                	li	a5,0
  while(sp_index<16){
    80001680:	46c1                	li	a3,16
    //finidng occupied page in swap file memory
    if(!p->swapped_pages.pages[sp_index].is_used)
    80001682:	4118                	lw	a4,0(a0)
    80001684:	cb11                	beqz	a4,80001698 <find_free_page_in_swapped+0x2e>
      return sp_index;
    else
      sp_index++;
    80001686:	2785                	addiw	a5,a5,1
  while(sp_index<16){
    80001688:	0531                	addi	a0,a0,12
    8000168a:	fed79ce3          	bne	a5,a3,80001682 <find_free_page_in_swapped+0x18>
  }

  //proc has a MAX_PSYC_PAGES pages
  return -1;
    8000168e:	557d                	li	a0,-1
}
    80001690:	60a2                	ld	ra,8(sp)
    80001692:	6402                	ld	s0,0(sp)
    80001694:	0141                	addi	sp,sp,16
    80001696:	8082                	ret
      return sp_index;
    80001698:	02079513          	slli	a0,a5,0x20
    8000169c:	9101                	srli	a0,a0,0x20
    8000169e:	bfcd                	j	80001690 <find_free_page_in_swapped+0x26>

00000000800016a0 <swap>:

//moves random page from main memory to swaped file. return ot's free index in the ram array   
uint64
swap(int index){
    800016a0:	715d                	addi	sp,sp,-80
    800016a2:	e486                	sd	ra,72(sp)
    800016a4:	e0a2                	sd	s0,64(sp)
    800016a6:	fc26                	sd	s1,56(sp)
    800016a8:	f84a                	sd	s2,48(sp)
    800016aa:	f44e                	sd	s3,40(sp)
    800016ac:	f052                	sd	s4,32(sp)
    800016ae:	ec56                	sd	s5,24(sp)
    800016b0:	e85a                	sd	s6,16(sp)
    800016b2:	e45e                	sd	s7,8(sp)
    800016b4:	0880                	addi	s0,sp,80
  struct proc *p = myproc();
    800016b6:	00001097          	auipc	ra,0x1
    800016ba:	b4e080e7          	jalr	-1202(ra) # 80002204 <myproc>
    800016be:	84aa                	mv	s1,a0

  uint sp_index = find_free_page_in_swapped();
    800016c0:	00000097          	auipc	ra,0x0
    800016c4:	faa080e7          	jalr	-86(ra) # 8000166a <find_free_page_in_swapped>
    800016c8:	00050b1b          	sext.w	s6,a0
  // if(sp_index == -1){
  //   if(index == -1)
  //     panic("In swap, can't find free page in file");
  //   sp_index = index; 
  // }
  uint occupied_index = find_occupied_page_in_ram();
    800016cc:	00000097          	auipc	ra,0x0
    800016d0:	f6a080e7          	jalr	-150(ra) # 80001636 <find_occupied_page_in_ram>
    800016d4:	892a                	mv	s2,a0
    800016d6:	0005099b          	sext.w	s3,a0
  // printf("In swap, with page index from ram %d \n", occupied_index);

  // if sp_index==-1 then there are MAX_PSYC_PAGES 
  uint64 mm_va = p->ram_pages.pages[occupied_index].virtual_address;
    800016da:	02051713          	slli	a4,a0,0x20
    800016de:	9301                	srli	a4,a4,0x20
    800016e0:	00171793          	slli	a5,a4,0x1
    800016e4:	97ba                	add	a5,a5,a4
    800016e6:	078a                	slli	a5,a5,0x2
    800016e8:	97a6                	add	a5,a5,s1
    800016ea:	1707ab83          	lw	s7,368(a5) # 1170 <_entry-0x7fffee90>
    800016ee:	020b9593          	slli	a1,s7,0x20
    800016f2:	9181                	srli	a1,a1,0x20
  //uint64 mm_va_pointer = p->ram_pages.pages[occupied_index].virtual_address;
  
  pte_t *pte;
  uint64 a = PGROUNDDOWN(mm_va);
  if((pte = walk(p->pagetable, a, 0)) == 0)
    800016f4:	4601                	li	a2,0
    800016f6:	77fd                	lui	a5,0xfffff
    800016f8:	8dfd                	and	a1,a1,a5
    800016fa:	68a8                	ld	a0,80(s1)
    800016fc:	00000097          	auipc	ra,0x0
    80001700:	8aa080e7          	jalr	-1878(ra) # 80000fa6 <walk>
    80001704:	c151                	beqz	a0,80001788 <swap+0xe8>
    80001706:	8a2a                	mv	s4,a0
      return -1;
  uint64 pa = PTE2PA(*pte);
    80001708:	00053a83          	ld	s5,0(a0)
    8000170c:	00aada93          	srli	s5,s5,0xa
    80001710:	0ab2                	slli	s5,s5,0xc
  
  writeToSwapFile(p, (char*)pa, sp_index*PGSIZE, PGSIZE);
    80001712:	6685                	lui	a3,0x1
    80001714:	00cb161b          	slliw	a2,s6,0xc
    80001718:	85d6                	mv	a1,s5
    8000171a:	8526                	mv	a0,s1
    8000171c:	00003097          	auipc	ra,0x3
    80001720:	350080e7          	jalr	848(ra) # 80004a6c <writeToSwapFile>
  
  p->swapped_pages.pages[sp_index].virtual_address = mm_va;
    80001724:	020b1713          	slli	a4,s6,0x20
    80001728:	9301                	srli	a4,a4,0x20
    8000172a:	00171793          	slli	a5,a4,0x1
    8000172e:	00e786b3          	add	a3,a5,a4
    80001732:	068a                	slli	a3,a3,0x2
    80001734:	96a6                	add	a3,a3,s1
    80001736:	2376ac23          	sw	s7,568(a3) # 1238 <_entry-0x7fffedc8>
  p->swapped_pages.pages[sp_index].is_used = 1; 
    8000173a:	4705                	li	a4,1
    8000173c:	22e6ae23          	sw	a4,572(a3)
  p->ram_pages.pages[occupied_index].is_used = 0; //this index is no more occupied
    80001740:	1982                	slli	s3,s3,0x20
    80001742:	0209d993          	srli	s3,s3,0x20
    80001746:	00199513          	slli	a0,s3,0x1
    8000174a:	954e                	add	a0,a0,s3
    8000174c:	050a                	slli	a0,a0,0x2
    8000174e:	94aa                	add	s1,s1,a0
    80001750:	1604aa23          	sw	zero,372(s1)
  

  kfree((void*)pa); //Free the page of physical memory
    80001754:	8556                	mv	a0,s5
    80001756:	fffff097          	auipc	ra,0xfffff
    8000175a:	280080e7          	jalr	640(ra) # 800009d6 <kfree>

  // update pte flags
  *pte |= PTE_PG; //page is on disc
  // printf("In swap, turning off valid for %d\n", a); 
  *pte &= ~PTE_V; //page is not valid
    8000175e:	000a3783          	ld	a5,0(s4)
    80001762:	9bf9                	andi	a5,a5,-2
    80001764:	2007e793          	ori	a5,a5,512
    80001768:	00fa3023          	sd	a5,0(s4)
  if (*pte & PTE_V){
    printf("Hi there\n"); 
  }

  
  return occupied_index; //this physical addres is available now
    8000176c:	02091513          	slli	a0,s2,0x20
    80001770:	9101                	srli	a0,a0,0x20
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6161                	addi	sp,sp,80
    80001786:	8082                	ret
      return -1;
    80001788:	557d                	li	a0,-1
    8000178a:	b7e5                	j	80001772 <swap+0xd2>

000000008000178c <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000178c:	7179                	addi	sp,sp,-48
    8000178e:	f406                	sd	ra,40(sp)
    80001790:	f022                	sd	s0,32(sp)
    80001792:	ec26                	sd	s1,24(sp)
    80001794:	e84a                	sd	s2,16(sp)
    80001796:	e44e                	sd	s3,8(sp)
    80001798:	1800                	addi	s0,sp,48
    8000179a:	89aa                	mv	s3,a0
    8000179c:	84ae                	mv	s1,a1
    8000179e:	8932                	mv	s2,a2
  printf("******In uvmdealloc****** \n"); 
    800017a0:	00008517          	auipc	a0,0x8
    800017a4:	a3050513          	addi	a0,a0,-1488 # 800091d0 <digits+0x190>
    800017a8:	fffff097          	auipc	ra,0xfffff
    800017ac:	dcc080e7          	jalr	-564(ra) # 80000574 <printf>
  if(newsz >= oldsz)
    800017b0:	02997f63          	bgeu	s2,s1,800017ee <uvmdealloc+0x62>
    return oldsz;

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800017b4:	6785                	lui	a5,0x1
    800017b6:	17fd                	addi	a5,a5,-1
    800017b8:	00f905b3          	add	a1,s2,a5
    800017bc:	767d                	lui	a2,0xfffff
    800017be:	8df1                	and	a1,a1,a2
    800017c0:	94be                	add	s1,s1,a5
    800017c2:	8cf1                	and	s1,s1,a2
    800017c4:	0095ea63          	bltu	a1,s1,800017d8 <uvmdealloc+0x4c>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800017c8:	854a                	mv	a0,s2
    800017ca:	70a2                	ld	ra,40(sp)
    800017cc:	7402                	ld	s0,32(sp)
    800017ce:	64e2                	ld	s1,24(sp)
    800017d0:	6942                	ld	s2,16(sp)
    800017d2:	69a2                	ld	s3,8(sp)
    800017d4:	6145                	addi	sp,sp,48
    800017d6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800017d8:	8c8d                	sub	s1,s1,a1
    800017da:	80b1                	srli	s1,s1,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800017dc:	4685                	li	a3,1
    800017de:	0004861b          	sext.w	a2,s1
    800017e2:	854e                	mv	a0,s3
    800017e4:	00000097          	auipc	ra,0x0
    800017e8:	aa4080e7          	jalr	-1372(ra) # 80001288 <uvmunmap>
    800017ec:	bff1                	j	800017c8 <uvmdealloc+0x3c>
    return oldsz;
    800017ee:	8926                	mv	s2,s1
    800017f0:	bfe1                	j	800017c8 <uvmdealloc+0x3c>

00000000800017f2 <init_free_ram_page>:
init_free_ram_page(pagetable_t pagetable, uint64 va, uint64 pa , int index){
    800017f2:	7139                	addi	sp,sp,-64
    800017f4:	fc06                	sd	ra,56(sp)
    800017f6:	f822                	sd	s0,48(sp)
    800017f8:	f426                	sd	s1,40(sp)
    800017fa:	f04a                	sd	s2,32(sp)
    800017fc:	ec4e                	sd	s3,24(sp)
    800017fe:	e852                	sd	s4,16(sp)
    80001800:	e456                	sd	s5,8(sp)
    80001802:	0080                	addi	s0,sp,64
    80001804:	8aaa                	mv	s5,a0
    80001806:	8a2e                	mv	s4,a1
    80001808:	89b2                	mv	s3,a2
    8000180a:	8936                	mv	s2,a3
  struct proc *p = myproc();
    8000180c:	00001097          	auipc	ra,0x1
    80001810:	9f8080e7          	jalr	-1544(ra) # 80002204 <myproc>
    80001814:	84aa                	mv	s1,a0
  if(mappages(pagetable, a, PGSIZE, pa, PTE_W|PTE_X|PTE_R|PTE_U) < 0){
    80001816:	4779                	li	a4,30
    80001818:	86ce                	mv	a3,s3
    8000181a:	6605                	lui	a2,0x1
    8000181c:	75fd                	lui	a1,0xfffff
    8000181e:	00ba75b3          	and	a1,s4,a1
    80001822:	8556                	mv	a0,s5
    80001824:	00000097          	auipc	ra,0x0
    80001828:	86a080e7          	jalr	-1942(ra) # 8000108e <mappages>
    8000182c:	04054063          	bltz	a0,8000186c <init_free_ram_page+0x7a>
  p->ram_pages.pages[index].virtual_address = va; //TODO or va ? 
    80001830:	00191993          	slli	s3,s2,0x1
    80001834:	012987b3          	add	a5,s3,s2
    80001838:	078a                	slli	a5,a5,0x2
    8000183a:	97a6                	add	a5,a5,s1
    8000183c:	1747a823          	sw	s4,368(a5) # 1170 <_entry-0x7fffee90>
  p->ram_pages.pages[index].is_used = 1;
    80001840:	4705                	li	a4,1
    80001842:	16e7aa23          	sw	a4,372(a5)
  p->ram_pages.pages[index].page_counter=reset_counter();
    80001846:	00001097          	auipc	ra,0x1
    8000184a:	a82080e7          	jalr	-1406(ra) # 800022c8 <reset_counter>
    8000184e:	99ca                	add	s3,s3,s2
    80001850:	098a                	slli	s3,s3,0x2
    80001852:	99a6                	add	s3,s3,s1
    80001854:	16a9ac23          	sw	a0,376(s3)
  return 1; //success
    80001858:	4505                	li	a0,1
}
    8000185a:	70e2                	ld	ra,56(sp)
    8000185c:	7442                	ld	s0,48(sp)
    8000185e:	74a2                	ld	s1,40(sp)
    80001860:	7902                	ld	s2,32(sp)
    80001862:	69e2                	ld	s3,24(sp)
    80001864:	6a42                	ld	s4,16(sp)
    80001866:	6aa2                	ld	s5,8(sp)
    80001868:	6121                	addi	sp,sp,64
    8000186a:	8082                	ret
    uvmdealloc(pagetable, PGSIZE, PGSIZE);
    8000186c:	6605                	lui	a2,0x1
    8000186e:	6585                	lui	a1,0x1
    80001870:	8556                	mv	a0,s5
    80001872:	00000097          	auipc	ra,0x0
    80001876:	f1a080e7          	jalr	-230(ra) # 8000178c <uvmdealloc>
    kfree((void*)pa); //Free the page of physical memory
    8000187a:	854e                	mv	a0,s3
    8000187c:	fffff097          	auipc	ra,0xfffff
    80001880:	15a080e7          	jalr	346(ra) # 800009d6 <kfree>
    return 0; //init page failed
    80001884:	4501                	li	a0,0
    80001886:	bfd1                	j	8000185a <init_free_ram_page+0x68>

0000000080001888 <find_and_init_page>:
find_and_init_page(uint64 pa, uint64 va){
    80001888:	1101                	addi	sp,sp,-32
    8000188a:	ec06                	sd	ra,24(sp)
    8000188c:	e822                	sd	s0,16(sp)
    8000188e:	e426                	sd	s1,8(sp)
    80001890:	e04a                	sd	s2,0(sp)
    80001892:	1000                	addi	s0,sp,32
    80001894:	892a                	mv	s2,a0
    80001896:	84ae                	mv	s1,a1
  struct proc *p =  myproc();
    80001898:	00001097          	auipc	ra,0x1
    8000189c:	96c080e7          	jalr	-1684(ra) # 80002204 <myproc>
  while(index<MAX_PSYC_PAGES){
    800018a0:	17450793          	addi	a5,a0,372
  int index =0;
    800018a4:	4681                	li	a3,0
  while(index<MAX_PSYC_PAGES){
    800018a6:	4841                	li	a6,16
    if(!p->ram_pages.pages[index].is_used){
    800018a8:	4398                	lw	a4,0(a5)
    800018aa:	cf01                	beqz	a4,800018c2 <find_and_init_page+0x3a>
    index++;
    800018ac:	2685                	addiw	a3,a3,1
  while(index<MAX_PSYC_PAGES){
    800018ae:	07b1                	addi	a5,a5,12
    800018b0:	ff069ce3          	bne	a3,a6,800018a8 <find_and_init_page+0x20>
  return -1;
    800018b4:	557d                	li	a0,-1
}
    800018b6:	60e2                	ld	ra,24(sp)
    800018b8:	6442                	ld	s0,16(sp)
    800018ba:	64a2                	ld	s1,8(sp)
    800018bc:	6902                	ld	s2,0(sp)
    800018be:	6105                	addi	sp,sp,32
    800018c0:	8082                	ret
      return init_free_ram_page(p->pagetable, va, pa, index);
    800018c2:	864a                	mv	a2,s2
    800018c4:	85a6                	mv	a1,s1
    800018c6:	6928                	ld	a0,80(a0)
    800018c8:	00000097          	auipc	ra,0x0
    800018cc:	f2a080e7          	jalr	-214(ra) # 800017f2 <init_free_ram_page>
    800018d0:	b7dd                	j	800018b6 <find_and_init_page+0x2e>

00000000800018d2 <handle_page_fault>:
handle_page_fault(uint64 va){
    800018d2:	7119                	addi	sp,sp,-128
    800018d4:	fc86                	sd	ra,120(sp)
    800018d6:	f8a2                	sd	s0,112(sp)
    800018d8:	f4a6                	sd	s1,104(sp)
    800018da:	f0ca                	sd	s2,96(sp)
    800018dc:	ecce                	sd	s3,88(sp)
    800018de:	e8d2                	sd	s4,80(sp)
    800018e0:	e4d6                	sd	s5,72(sp)
    800018e2:	e0da                	sd	s6,64(sp)
    800018e4:	fc5e                	sd	s7,56(sp)
    800018e6:	f862                	sd	s8,48(sp)
    800018e8:	f466                	sd	s9,40(sp)
    800018ea:	f06a                	sd	s10,32(sp)
    800018ec:	ec6e                	sd	s11,24(sp)
    800018ee:	0100                	addi	s0,sp,128
    800018f0:	8aaa                	mv	s5,a0
  struct proc *p = myproc();
    800018f2:	00001097          	auipc	ra,0x1
    800018f6:	912080e7          	jalr	-1774(ra) # 80002204 <myproc>
    800018fa:	8d2a                	mv	s10,a0
  uint64 align_va = PGROUNDDOWN(va);
    800018fc:	79fd                	lui	s3,0xfffff
    800018fe:	013af9b3          	and	s3,s5,s3
  pte_t *pte = walk(p->pagetable, align_va, 0);
    80001902:	4601                	li	a2,0
    80001904:	85ce                	mv	a1,s3
    80001906:	6928                	ld	a0,80(a0)
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	69e080e7          	jalr	1694(ra) # 80000fa6 <walk>
    80001910:	8daa                	mv	s11,a0
  void * buffer =  kalloc(); 
    80001912:	fffff097          	auipc	ra,0xfffff
    80001916:	1c0080e7          	jalr	448(ra) # 80000ad2 <kalloc>
    8000191a:	f8a43423          	sd	a0,-120(s0)
  if(pte == 0){
    8000191e:	040d8a63          	beqz	s11,80001972 <handle_page_fault+0xa0>
  else if(!(*pte & PTE_PG)){ //enter when flag PTE_PG is off  
    80001922:	000db783          	ld	a5,0(s11)
    80001926:	2007f793          	andi	a5,a5,512
    8000192a:	cfa1                	beqz	a5,80001982 <handle_page_fault+0xb0>
  printf("In handle_page_fault, desired va page is: %d \n", va); 
    8000192c:	85d6                	mv	a1,s5
    8000192e:	00008517          	auipc	a0,0x8
    80001932:	92a50513          	addi	a0,a0,-1750 # 80009258 <digits+0x218>
    80001936:	fffff097          	auipc	ra,0xfffff
    8000193a:	c3e080e7          	jalr	-962(ra) # 80000574 <printf>
  printf("In handle_page_fault, desired align va page  is: %d \n", align_va); 
    8000193e:	85ce                	mv	a1,s3
    80001940:	00008517          	auipc	a0,0x8
    80001944:	94850513          	addi	a0,a0,-1720 # 80009288 <digits+0x248>
    80001948:	fffff097          	auipc	ra,0xfffff
    8000194c:	c2c080e7          	jalr	-980(ra) # 80000574 <printf>
  while(i<16){
    80001950:	170d0493          	addi	s1,s10,368
  int i = 0; 
    80001954:	4901                	li	s2,0
    printf("swaped page num %d va is %d \n",i, p->swapped_pages.pages[i].virtual_address);
    80001956:	00008c17          	auipc	s8,0x8
    8000195a:	96ac0c13          	addi	s8,s8,-1686 # 800092c0 <digits+0x280>
    printf("swaped page num %d is used %d \n",i, p->swapped_pages.pages[i].is_used); 
    8000195e:	00008b97          	auipc	s7,0x8
    80001962:	982b8b93          	addi	s7,s7,-1662 # 800092e0 <digits+0x2a0>
    printf("ram page num %d va is %d \n",i, p->ram_pages.pages[i].virtual_address); 
    80001966:	00008b17          	auipc	s6,0x8
    8000196a:	99ab0b13          	addi	s6,s6,-1638 # 80009300 <digits+0x2c0>
  while(i<16){
    8000196e:	4cc1                	li	s9,16
    80001970:	a805                	j	800019a0 <handle_page_fault+0xce>
    panic("in handle_page_fault, page table don't exists \n");
    80001972:	00008517          	auipc	a0,0x8
    80001976:	87e50513          	addi	a0,a0,-1922 # 800091f0 <digits+0x1b0>
    8000197a:	fffff097          	auipc	ra,0xfffff
    8000197e:	bb0080e7          	jalr	-1104(ra) # 8000052a <panic>
    panic("in handle_page_fault, page is not in the swap file");
    80001982:	00008517          	auipc	a0,0x8
    80001986:	89e50513          	addi	a0,a0,-1890 # 80009220 <digits+0x1e0>
    8000198a:	fffff097          	auipc	ra,0xfffff
    8000198e:	ba0080e7          	jalr	-1120(ra) # 8000052a <panic>
      if(p->swapped_pages.pages[i].is_used){
    80001992:	0cca2783          	lw	a5,204(s4)
    80001996:	e7a1                	bnez	a5,800019de <handle_page_fault+0x10c>
    i++; 
    80001998:	2905                	addiw	s2,s2,1
  while(i<16){
    8000199a:	04b1                	addi	s1,s1,12
    8000199c:	0f990263          	beq	s2,s9,80001a80 <handle_page_fault+0x1ae>
    printf("swaped page num %d va is %d \n",i, p->swapped_pages.pages[i].virtual_address);
    800019a0:	8a26                	mv	s4,s1
    800019a2:	0c84a603          	lw	a2,200(s1)
    800019a6:	85ca                	mv	a1,s2
    800019a8:	8562                	mv	a0,s8
    800019aa:	fffff097          	auipc	ra,0xfffff
    800019ae:	bca080e7          	jalr	-1078(ra) # 80000574 <printf>
    printf("swaped page num %d is used %d \n",i, p->swapped_pages.pages[i].is_used); 
    800019b2:	0cc4a603          	lw	a2,204(s1)
    800019b6:	85ca                	mv	a1,s2
    800019b8:	855e                	mv	a0,s7
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	bba080e7          	jalr	-1094(ra) # 80000574 <printf>
    printf("ram page num %d va is %d \n",i, p->ram_pages.pages[i].virtual_address); 
    800019c2:	4090                	lw	a2,0(s1)
    800019c4:	85ca                	mv	a1,s2
    800019c6:	855a                	mv	a0,s6
    800019c8:	fffff097          	auipc	ra,0xfffff
    800019cc:	bac080e7          	jalr	-1108(ra) # 80000574 <printf>
    uint64 curr_va = (uint64)p->swapped_pages.pages[i].virtual_address;
    800019d0:	0c84e783          	lwu	a5,200(s1)
    if(curr_va == align_va || curr_va == va){
    800019d4:	faf98fe3          	beq	s3,a5,80001992 <handle_page_fault+0xc0>
    800019d8:	fcfa90e3          	bne	s5,a5,80001998 <handle_page_fault+0xc6>
    800019dc:	bf5d                	j	80001992 <handle_page_fault+0xc0>
  if (i>15){
    800019de:	47bd                	li	a5,15
    800019e0:	0b27c063          	blt	a5,s2,80001a80 <handle_page_fault+0x1ae>
  p->swapped_pages.pages[i].virtual_address = 0;
    800019e4:	00191793          	slli	a5,s2,0x1
    800019e8:	97ca                	add	a5,a5,s2
    800019ea:	078a                	slli	a5,a5,0x2
    800019ec:	97ea                	add	a5,a5,s10
    800019ee:	2207ac23          	sw	zero,568(a5)
  p->swapped_pages.pages[i].is_used = 0; 
    800019f2:	2207ae23          	sw	zero,572(a5)
  free_pa_index = find_free_page_in_ram(); 
    800019f6:	00000097          	auipc	ra,0x0
    800019fa:	a6e080e7          	jalr	-1426(ra) # 80001464 <find_free_page_in_ram>
    800019fe:	84aa                	mv	s1,a0
  if (free_pa_index == -1){
    80001a00:	57fd                	li	a5,-1
    80001a02:	08f50763          	beq	a0,a5,80001a90 <handle_page_fault+0x1be>
  memset(buffer,0,PGSIZE);
    80001a06:	6605                	lui	a2,0x1
    80001a08:	4581                	li	a1,0
    80001a0a:	f8843a03          	ld	s4,-120(s0)
    80001a0e:	8552                	mv	a0,s4
    80001a10:	fffff097          	auipc	ra,0xfffff
    80001a14:	2ae080e7          	jalr	686(ra) # 80000cbe <memset>
  readFromSwapFile(p, buffer, i*PGSIZE, PGSIZE); //reading page to pa 
    80001a18:	6685                	lui	a3,0x1
    80001a1a:	00c9161b          	slliw	a2,s2,0xc
    80001a1e:	85d2                	mv	a1,s4
    80001a20:	856a                	mv	a0,s10
    80001a22:	00003097          	auipc	ra,0x3
    80001a26:	06e080e7          	jalr	110(ra) # 80004a90 <readFromSwapFile>
   *pte &= ~PTE_PG;
    80001a2a:	000db783          	ld	a5,0(s11)
    80001a2e:	dff7f713          	andi	a4,a5,-513
    80001a32:	00edb023          	sd	a4,0(s11)
   if(*pte & PTE_V){
    80001a36:	8b85                	andi	a5,a5,1
    80001a38:	ebc1                	bnez	a5,80001ac8 <handle_page_fault+0x1f6>
  printf("page %d is not valid!!! \n",align_va); 
    80001a3a:	85ce                	mv	a1,s3
    80001a3c:	00008517          	auipc	a0,0x8
    80001a40:	98450513          	addi	a0,a0,-1660 # 800093c0 <digits+0x380>
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	b30080e7          	jalr	-1232(ra) # 80000574 <printf>
  if(!init_free_ram_page(p->pagetable, va, (uint64)buffer, free_pa_index)){
    80001a4c:	86a6                	mv	a3,s1
    80001a4e:	f8843603          	ld	a2,-120(s0)
    80001a52:	85d6                	mv	a1,s5
    80001a54:	050d3503          	ld	a0,80(s10)
    80001a58:	00000097          	auipc	ra,0x0
    80001a5c:	d9a080e7          	jalr	-614(ra) # 800017f2 <init_free_ram_page>
    80001a60:	cd35                	beqz	a0,80001adc <handle_page_fault+0x20a>
}
    80001a62:	70e6                	ld	ra,120(sp)
    80001a64:	7446                	ld	s0,112(sp)
    80001a66:	74a6                	ld	s1,104(sp)
    80001a68:	7906                	ld	s2,96(sp)
    80001a6a:	69e6                	ld	s3,88(sp)
    80001a6c:	6a46                	ld	s4,80(sp)
    80001a6e:	6aa6                	ld	s5,72(sp)
    80001a70:	6b06                	ld	s6,64(sp)
    80001a72:	7be2                	ld	s7,56(sp)
    80001a74:	7c42                	ld	s8,48(sp)
    80001a76:	7ca2                	ld	s9,40(sp)
    80001a78:	7d02                	ld	s10,32(sp)
    80001a7a:	6de2                	ld	s11,24(sp)
    80001a7c:	6109                	addi	sp,sp,128
    80001a7e:	8082                	ret
    panic("in handle_page_fault, page not exists \n"); 
    80001a80:	00008517          	auipc	a0,0x8
    80001a84:	8a050513          	addi	a0,a0,-1888 # 80009320 <digits+0x2e0>
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	aa2080e7          	jalr	-1374(ra) # 8000052a <panic>
    free_pa_index = swap(i); 
    80001a90:	854a                	mv	a0,s2
    80001a92:	00000097          	auipc	ra,0x0
    80001a96:	c0e080e7          	jalr	-1010(ra) # 800016a0 <swap>
    80001a9a:	0005049b          	sext.w	s1,a0
    printf("i value : %d     free_pa_index : %d \n",i,free_pa_index);
    80001a9e:	8626                	mv	a2,s1
    80001aa0:	85ca                	mv	a1,s2
    80001aa2:	00008517          	auipc	a0,0x8
    80001aa6:	8a650513          	addi	a0,a0,-1882 # 80009348 <digits+0x308>
    80001aaa:	fffff097          	auipc	ra,0xfffff
    80001aae:	aca080e7          	jalr	-1334(ra) # 80000574 <printf>
    if(free_pa_index == -1){
    80001ab2:	57fd                	li	a5,-1
    80001ab4:	f4f499e3          	bne	s1,a5,80001a06 <handle_page_fault+0x134>
      panic("in handle_page_fault, no unused page in swap file \n");
    80001ab8:	00008517          	auipc	a0,0x8
    80001abc:	8b850513          	addi	a0,a0,-1864 # 80009370 <digits+0x330>
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	a6a080e7          	jalr	-1430(ra) # 8000052a <panic>
     printf("page %d is valid!!! \n",align_va); 
    80001ac8:	85ce                	mv	a1,s3
    80001aca:	00008517          	auipc	a0,0x8
    80001ace:	8de50513          	addi	a0,a0,-1826 # 800093a8 <digits+0x368>
    80001ad2:	fffff097          	auipc	ra,0xfffff
    80001ad6:	aa2080e7          	jalr	-1374(ra) # 80000574 <printf>
    80001ada:	b785                	j	80001a3a <handle_page_fault+0x168>
    panic("in Handle_PGFLT, unexpectedly failed to find unused entry in main_mem array of the process");
    80001adc:	00008517          	auipc	a0,0x8
    80001ae0:	90450513          	addi	a0,a0,-1788 # 800093e0 <digits+0x3a0>
    80001ae4:	fffff097          	auipc	ra,0xfffff
    80001ae8:	a46080e7          	jalr	-1466(ra) # 8000052a <panic>

0000000080001aec <uvmalloc>:
{
    80001aec:	7159                	addi	sp,sp,-112
    80001aee:	f486                	sd	ra,104(sp)
    80001af0:	f0a2                	sd	s0,96(sp)
    80001af2:	eca6                	sd	s1,88(sp)
    80001af4:	e8ca                	sd	s2,80(sp)
    80001af6:	e4ce                	sd	s3,72(sp)
    80001af8:	e0d2                	sd	s4,64(sp)
    80001afa:	fc56                	sd	s5,56(sp)
    80001afc:	f85a                	sd	s6,48(sp)
    80001afe:	f45e                	sd	s7,40(sp)
    80001b00:	f062                	sd	s8,32(sp)
    80001b02:	ec66                	sd	s9,24(sp)
    80001b04:	e86a                	sd	s10,16(sp)
    80001b06:	e46e                	sd	s11,8(sp)
    80001b08:	1880                	addi	s0,sp,112
    80001b0a:	8a2a                	mv	s4,a0
    80001b0c:	8aae                	mv	s5,a1
    80001b0e:	8bb2                	mv	s7,a2
  printf("In uvmalloc with pid: %d \n", myproc()->pid); 
    80001b10:	00000097          	auipc	ra,0x0
    80001b14:	6f4080e7          	jalr	1780(ra) # 80002204 <myproc>
    80001b18:	590c                	lw	a1,48(a0)
    80001b1a:	00008517          	auipc	a0,0x8
    80001b1e:	92650513          	addi	a0,a0,-1754 # 80009440 <digits+0x400>
    80001b22:	fffff097          	auipc	ra,0xfffff
    80001b26:	a52080e7          	jalr	-1454(ra) # 80000574 <printf>
  printf("oldsize is : %d \n", oldsz); 
    80001b2a:	85d6                	mv	a1,s5
    80001b2c:	00008517          	auipc	a0,0x8
    80001b30:	93450513          	addi	a0,a0,-1740 # 80009460 <digits+0x420>
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	a40080e7          	jalr	-1472(ra) # 80000574 <printf>
  printf("newsize is : %d \n", newsz); 
    80001b3c:	85de                	mv	a1,s7
    80001b3e:	00008517          	auipc	a0,0x8
    80001b42:	93a50513          	addi	a0,a0,-1734 # 80009478 <digits+0x438>
    80001b46:	fffff097          	auipc	ra,0xfffff
    80001b4a:	a2e080e7          	jalr	-1490(ra) # 80000574 <printf>
  if(newsz >= KERNBASE)
    80001b4e:	800007b7          	lui	a5,0x80000
    80001b52:	fff7c793          	not	a5,a5
    80001b56:	1977e863          	bltu	a5,s7,80001ce6 <uvmalloc+0x1fa>
  if(newsz < oldsz)
    80001b5a:	1b5be663          	bltu	s7,s5,80001d06 <uvmalloc+0x21a>
  a = PGROUNDUP(oldsz);
    80001b5e:	6905                	lui	s2,0x1
    80001b60:	197d                	addi	s2,s2,-1
    80001b62:	9956                	add	s2,s2,s5
    80001b64:	77fd                	lui	a5,0xfffff
    80001b66:	00f97933          	and	s2,s2,a5
  for(int l=0; l<16; l++){
    80001b6a:	4481                	li	s1,0
  int curr_pages =0; 
    80001b6c:	4981                	li	s3,0
  for(int l=0; l<16; l++){
    80001b6e:	4b41                	li	s6,16
    80001b70:	a021                	j	80001b78 <uvmalloc+0x8c>
    80001b72:	2485                	addiw	s1,s1,1
    80001b74:	03648d63          	beq	s1,s6,80001bae <uvmalloc+0xc2>
    if(myproc()->ram_pages.pages[l].is_used)
    80001b78:	00000097          	auipc	ra,0x0
    80001b7c:	68c080e7          	jalr	1676(ra) # 80002204 <myproc>
    80001b80:	00149793          	slli	a5,s1,0x1
    80001b84:	97a6                	add	a5,a5,s1
    80001b86:	078a                	slli	a5,a5,0x2
    80001b88:	97aa                	add	a5,a5,a0
    80001b8a:	1747a783          	lw	a5,372(a5) # fffffffffffff174 <end+0xffffffff7ffd1174>
    80001b8e:	c391                	beqz	a5,80001b92 <uvmalloc+0xa6>
      curr_pages++; 
    80001b90:	2985                	addiw	s3,s3,1
    if(myproc()->swapped_pages.pages[l].is_used)
    80001b92:	00000097          	auipc	ra,0x0
    80001b96:	672080e7          	jalr	1650(ra) # 80002204 <myproc>
    80001b9a:	00149793          	slli	a5,s1,0x1
    80001b9e:	97a6                	add	a5,a5,s1
    80001ba0:	078a                	slli	a5,a5,0x2
    80001ba2:	97aa                	add	a5,a5,a0
    80001ba4:	23c7a783          	lw	a5,572(a5)
    80001ba8:	d7e9                	beqz	a5,80001b72 <uvmalloc+0x86>
      curr_pages++; 
    80001baa:	2985                	addiw	s3,s3,1
    80001bac:	b7d9                	j	80001b72 <uvmalloc+0x86>
  if (curr_pages == 32){
    80001bae:	02000793          	li	a5,32
    80001bb2:	02f98963          	beq	s3,a5,80001be4 <uvmalloc+0xf8>
  for(; a < newsz; a += PGSIZE){
    80001bb6:	11797d63          	bgeu	s2,s7,80001cd0 <uvmalloc+0x1e4>
    80001bba:	fffb8b13          	addi	s6,s7,-1
    80001bbe:	412b0b33          	sub	s6,s6,s2
    80001bc2:	77fd                	lui	a5,0xfffff
    80001bc4:	00fb7b33          	and	s6,s6,a5
    80001bc8:	6785                	lui	a5,0x1
    80001bca:	97ca                	add	a5,a5,s2
    80001bcc:	9b3e                	add	s6,s6,a5
    if(myproc()->pid > 2){
    80001bce:	4c09                	li	s8,2
      if(ram_page_index ==  -1){ //no free ram page
    80001bd0:	5cfd                	li	s9,-1
        printf("In uvmalloc, no free page in ram\n");
    80001bd2:	00008d97          	auipc	s11,0x8
    80001bd6:	8e6d8d93          	addi	s11,s11,-1818 # 800094b8 <digits+0x478>
        printf("In uvmalloc, after swap free ram page index is : %d \n", ram_page_index); 
    80001bda:	00008d17          	auipc	s10,0x8
    80001bde:	906d0d13          	addi	s10,s10,-1786 # 800094e0 <digits+0x4a0>
    80001be2:	a835                	j	80001c1e <uvmalloc+0x132>
    panic("In uvmalloc, not enough space for pages"); 
    80001be4:	00008517          	auipc	a0,0x8
    80001be8:	8ac50513          	addi	a0,a0,-1876 # 80009490 <digits+0x450>
    80001bec:	fffff097          	auipc	ra,0xfffff
    80001bf0:	93e080e7          	jalr	-1730(ra) # 8000052a <panic>
      uvmdealloc(pagetable, a, oldsz);
    80001bf4:	8656                	mv	a2,s5
    80001bf6:	85ca                	mv	a1,s2
    80001bf8:	8552                	mv	a0,s4
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	b92080e7          	jalr	-1134(ra) # 8000178c <uvmdealloc>
      return 0;
    80001c02:	4501                	li	a0,0
    80001c04:	a0d5                	j	80001ce8 <uvmalloc+0x1fc>
      init_free_ram_page(pagetable, a, (uint64)mem, ram_page_index); 
    80001c06:	86ce                	mv	a3,s3
    80001c08:	8626                	mv	a2,s1
    80001c0a:	85ca                	mv	a1,s2
    80001c0c:	8552                	mv	a0,s4
    80001c0e:	00000097          	auipc	ra,0x0
    80001c12:	be4080e7          	jalr	-1052(ra) # 800017f2 <init_free_ram_page>
  for(; a < newsz; a += PGSIZE){
    80001c16:	6785                	lui	a5,0x1
    80001c18:	993e                	add	s2,s2,a5
    80001c1a:	0b690b63          	beq	s2,s6,80001cd0 <uvmalloc+0x1e4>
    mem = kalloc();
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	eb4080e7          	jalr	-332(ra) # 80000ad2 <kalloc>
    80001c26:	84aa                	mv	s1,a0
    if(mem == 0){
    80001c28:	d571                	beqz	a0,80001bf4 <uvmalloc+0x108>
    memset(mem, 0, PGSIZE);
    80001c2a:	6605                	lui	a2,0x1
    80001c2c:	4581                	li	a1,0
    80001c2e:	fffff097          	auipc	ra,0xfffff
    80001c32:	090080e7          	jalr	144(ra) # 80000cbe <memset>
    if(myproc()->pid > 2){
    80001c36:	00000097          	auipc	ra,0x0
    80001c3a:	5ce080e7          	jalr	1486(ra) # 80002204 <myproc>
    80001c3e:	591c                	lw	a5,48(a0)
    80001c40:	06fc5063          	bge	s8,a5,80001ca0 <uvmalloc+0x1b4>
      ram_page_index = find_free_page_in_ram(); 
    80001c44:	00000097          	auipc	ra,0x0
    80001c48:	820080e7          	jalr	-2016(ra) # 80001464 <find_free_page_in_ram>
    80001c4c:	89aa                	mv	s3,a0
      if(ram_page_index ==  -1){ //no free ram page
    80001c4e:	fb951ce3          	bne	a0,s9,80001c06 <uvmalloc+0x11a>
        printf("In uvmalloc, no free page in ram\n");
    80001c52:	856e                	mv	a0,s11
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	920080e7          	jalr	-1760(ra) # 80000574 <printf>
        ram_page_index = swap(-1);
    80001c5c:	8566                	mv	a0,s9
    80001c5e:	00000097          	auipc	ra,0x0
    80001c62:	a42080e7          	jalr	-1470(ra) # 800016a0 <swap>
    80001c66:	0005099b          	sext.w	s3,a0
        printf("In uvmalloc, after swap free ram page index is : %d \n", ram_page_index); 
    80001c6a:	85ce                	mv	a1,s3
    80001c6c:	856a                	mv	a0,s10
    80001c6e:	fffff097          	auipc	ra,0xfffff
    80001c72:	906080e7          	jalr	-1786(ra) # 80000574 <printf>
        if (ram_page_index == -1) { // if swap failed
    80001c76:	f99998e3          	bne	s3,s9,80001c06 <uvmalloc+0x11a>
          printf("error: process %d needs more than 32 page, exits...\n", myproc()->pid);
    80001c7a:	00000097          	auipc	ra,0x0
    80001c7e:	58a080e7          	jalr	1418(ra) # 80002204 <myproc>
    80001c82:	590c                	lw	a1,48(a0)
    80001c84:	00008517          	auipc	a0,0x8
    80001c88:	89450513          	addi	a0,a0,-1900 # 80009518 <digits+0x4d8>
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	8e8080e7          	jalr	-1816(ra) # 80000574 <printf>
          exit(-1);   
    80001c94:	8566                	mv	a0,s9
    80001c96:	00001097          	auipc	ra,0x1
    80001c9a:	fc6080e7          	jalr	-58(ra) # 80002c5c <exit>
    80001c9e:	b7a5                	j	80001c06 <uvmalloc+0x11a>
      if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001ca0:	4779                	li	a4,30
    80001ca2:	86a6                	mv	a3,s1
    80001ca4:	6605                	lui	a2,0x1
    80001ca6:	85ca                	mv	a1,s2
    80001ca8:	8552                	mv	a0,s4
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	3e4080e7          	jalr	996(ra) # 8000108e <mappages>
    80001cb2:	d135                	beqz	a0,80001c16 <uvmalloc+0x12a>
        kfree(mem);
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	fffff097          	auipc	ra,0xfffff
    80001cba:	d20080e7          	jalr	-736(ra) # 800009d6 <kfree>
        uvmdealloc(pagetable, a, oldsz);
    80001cbe:	8656                	mv	a2,s5
    80001cc0:	85ca                	mv	a1,s2
    80001cc2:	8552                	mv	a0,s4
    80001cc4:	00000097          	auipc	ra,0x0
    80001cc8:	ac8080e7          	jalr	-1336(ra) # 8000178c <uvmdealloc>
        return 0;
    80001ccc:	4501                	li	a0,0
    80001cce:	a829                	j	80001ce8 <uvmalloc+0x1fc>
  printf("End uvmalloc, return newsz is: %d \n", newsz);
    80001cd0:	85de                	mv	a1,s7
    80001cd2:	00008517          	auipc	a0,0x8
    80001cd6:	87e50513          	addi	a0,a0,-1922 # 80009550 <digits+0x510>
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	89a080e7          	jalr	-1894(ra) # 80000574 <printf>
  return newsz;
    80001ce2:	855e                	mv	a0,s7
    80001ce4:	a011                	j	80001ce8 <uvmalloc+0x1fc>
    return 0;
    80001ce6:	4501                	li	a0,0
}
    80001ce8:	70a6                	ld	ra,104(sp)
    80001cea:	7406                	ld	s0,96(sp)
    80001cec:	64e6                	ld	s1,88(sp)
    80001cee:	6946                	ld	s2,80(sp)
    80001cf0:	69a6                	ld	s3,72(sp)
    80001cf2:	6a06                	ld	s4,64(sp)
    80001cf4:	7ae2                	ld	s5,56(sp)
    80001cf6:	7b42                	ld	s6,48(sp)
    80001cf8:	7ba2                	ld	s7,40(sp)
    80001cfa:	7c02                	ld	s8,32(sp)
    80001cfc:	6ce2                	ld	s9,24(sp)
    80001cfe:	6d42                	ld	s10,16(sp)
    80001d00:	6da2                	ld	s11,8(sp)
    80001d02:	6165                	addi	sp,sp,112
    80001d04:	8082                	ret
    return oldsz;
    80001d06:	8556                	mv	a0,s5
    80001d08:	b7c5                	j	80001ce8 <uvmalloc+0x1fc>

0000000080001d0a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001d0a:	7179                	addi	sp,sp,-48
    80001d0c:	f406                	sd	ra,40(sp)
    80001d0e:	f022                	sd	s0,32(sp)
    80001d10:	ec26                	sd	s1,24(sp)
    80001d12:	e84a                	sd	s2,16(sp)
    80001d14:	e44e                	sd	s3,8(sp)
    80001d16:	e052                	sd	s4,0(sp)
    80001d18:	1800                	addi	s0,sp,48
    80001d1a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001d1c:	84aa                	mv	s1,a0
    80001d1e:	6905                	lui	s2,0x1
    80001d20:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001d22:	4985                	li	s3,1
    80001d24:	a821                	j	80001d3c <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001d26:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001d28:	0532                	slli	a0,a0,0xc
    80001d2a:	00000097          	auipc	ra,0x0
    80001d2e:	fe0080e7          	jalr	-32(ra) # 80001d0a <freewalk>
      pagetable[i] = 0;
    80001d32:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001d36:	04a1                	addi	s1,s1,8
    80001d38:	03248163          	beq	s1,s2,80001d5a <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001d3c:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001d3e:	00f57793          	andi	a5,a0,15
    80001d42:	ff3782e3          	beq	a5,s3,80001d26 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001d46:	8905                	andi	a0,a0,1
    80001d48:	d57d                	beqz	a0,80001d36 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001d4a:	00008517          	auipc	a0,0x8
    80001d4e:	82e50513          	addi	a0,a0,-2002 # 80009578 <digits+0x538>
    80001d52:	ffffe097          	auipc	ra,0xffffe
    80001d56:	7d8080e7          	jalr	2008(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    80001d5a:	8552                	mv	a0,s4
    80001d5c:	fffff097          	auipc	ra,0xfffff
    80001d60:	c7a080e7          	jalr	-902(ra) # 800009d6 <kfree>
}
    80001d64:	70a2                	ld	ra,40(sp)
    80001d66:	7402                	ld	s0,32(sp)
    80001d68:	64e2                	ld	s1,24(sp)
    80001d6a:	6942                	ld	s2,16(sp)
    80001d6c:	69a2                	ld	s3,8(sp)
    80001d6e:	6a02                	ld	s4,0(sp)
    80001d70:	6145                	addi	sp,sp,48
    80001d72:	8082                	ret

0000000080001d74 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001d74:	1101                	addi	sp,sp,-32
    80001d76:	ec06                	sd	ra,24(sp)
    80001d78:	e822                	sd	s0,16(sp)
    80001d7a:	e426                	sd	s1,8(sp)
    80001d7c:	1000                	addi	s0,sp,32
    80001d7e:	84aa                	mv	s1,a0
  if(sz > 0)
    80001d80:	e999                	bnez	a1,80001d96 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001d82:	8526                	mv	a0,s1
    80001d84:	00000097          	auipc	ra,0x0
    80001d88:	f86080e7          	jalr	-122(ra) # 80001d0a <freewalk>
}
    80001d8c:	60e2                	ld	ra,24(sp)
    80001d8e:	6442                	ld	s0,16(sp)
    80001d90:	64a2                	ld	s1,8(sp)
    80001d92:	6105                	addi	sp,sp,32
    80001d94:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001d96:	6605                	lui	a2,0x1
    80001d98:	167d                	addi	a2,a2,-1
    80001d9a:	962e                	add	a2,a2,a1
    80001d9c:	4685                	li	a3,1
    80001d9e:	8231                	srli	a2,a2,0xc
    80001da0:	4581                	li	a1,0
    80001da2:	fffff097          	auipc	ra,0xfffff
    80001da6:	4e6080e7          	jalr	1254(ra) # 80001288 <uvmunmap>
    80001daa:	bfe1                	j	80001d82 <uvmfree+0xe>

0000000080001dac <uvmcopy>:
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    80001dac:	715d                	addi	sp,sp,-80
    80001dae:	e486                	sd	ra,72(sp)
    80001db0:	e0a2                	sd	s0,64(sp)
    80001db2:	fc26                	sd	s1,56(sp)
    80001db4:	f84a                	sd	s2,48(sp)
    80001db6:	f44e                	sd	s3,40(sp)
    80001db8:	f052                	sd	s4,32(sp)
    80001dba:	ec56                	sd	s5,24(sp)
    80001dbc:	e85a                	sd	s6,16(sp)
    80001dbe:	e45e                	sd	s7,8(sp)
    80001dc0:	0880                	addi	s0,sp,80
    80001dc2:	8b2a                	mv	s6,a0
    80001dc4:	8aae                	mv	s5,a1
    80001dc6:	8a32                	mv	s4,a2
  printf("In uvmcopy, with sz %d \n", sz); 
    80001dc8:	85b2                	mv	a1,a2
    80001dca:	00007517          	auipc	a0,0x7
    80001dce:	7be50513          	addi	a0,a0,1982 # 80009588 <digits+0x548>
    80001dd2:	ffffe097          	auipc	ra,0xffffe
    80001dd6:	7a2080e7          	jalr	1954(ra) # 80000574 <printf>
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001dda:	0a0a0a63          	beqz	s4,80001e8e <uvmcopy+0xe2>
    80001dde:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001de0:	4601                	li	a2,0
    80001de2:	85ce                	mv	a1,s3
    80001de4:	855a                	mv	a0,s6
    80001de6:	fffff097          	auipc	ra,0xfffff
    80001dea:	1c0080e7          	jalr	448(ra) # 80000fa6 <walk>
    80001dee:	c531                	beqz	a0,80001e3a <uvmcopy+0x8e>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001df0:	6118                	ld	a4,0(a0)
    80001df2:	00177793          	andi	a5,a4,1
    80001df6:	cbb1                	beqz	a5,80001e4a <uvmcopy+0x9e>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001df8:	00a75593          	srli	a1,a4,0xa
    80001dfc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001e00:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001e04:	fffff097          	auipc	ra,0xfffff
    80001e08:	cce080e7          	jalr	-818(ra) # 80000ad2 <kalloc>
    80001e0c:	892a                	mv	s2,a0
    80001e0e:	c939                	beqz	a0,80001e64 <uvmcopy+0xb8>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001e10:	6605                	lui	a2,0x1
    80001e12:	85de                	mv	a1,s7
    80001e14:	fffff097          	auipc	ra,0xfffff
    80001e18:	f06080e7          	jalr	-250(ra) # 80000d1a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001e1c:	8726                	mv	a4,s1
    80001e1e:	86ca                	mv	a3,s2
    80001e20:	6605                	lui	a2,0x1
    80001e22:	85ce                	mv	a1,s3
    80001e24:	8556                	mv	a0,s5
    80001e26:	fffff097          	auipc	ra,0xfffff
    80001e2a:	268080e7          	jalr	616(ra) # 8000108e <mappages>
    80001e2e:	e515                	bnez	a0,80001e5a <uvmcopy+0xae>
  for(i = 0; i < sz; i += PGSIZE){
    80001e30:	6785                	lui	a5,0x1
    80001e32:	99be                	add	s3,s3,a5
    80001e34:	fb49e6e3          	bltu	s3,s4,80001de0 <uvmcopy+0x34>
    80001e38:	a081                	j	80001e78 <uvmcopy+0xcc>
      panic("uvmcopy: pte should exist");
    80001e3a:	00007517          	auipc	a0,0x7
    80001e3e:	76e50513          	addi	a0,a0,1902 # 800095a8 <digits+0x568>
    80001e42:	ffffe097          	auipc	ra,0xffffe
    80001e46:	6e8080e7          	jalr	1768(ra) # 8000052a <panic>
      panic("uvmcopy: page not present");
    80001e4a:	00007517          	auipc	a0,0x7
    80001e4e:	77e50513          	addi	a0,a0,1918 # 800095c8 <digits+0x588>
    80001e52:	ffffe097          	auipc	ra,0xffffe
    80001e56:	6d8080e7          	jalr	1752(ra) # 8000052a <panic>
      kfree(mem);
    80001e5a:	854a                	mv	a0,s2
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	b7a080e7          	jalr	-1158(ra) # 800009d6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001e64:	4685                	li	a3,1
    80001e66:	00c9d613          	srli	a2,s3,0xc
    80001e6a:	4581                	li	a1,0
    80001e6c:	8556                	mv	a0,s5
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	41a080e7          	jalr	1050(ra) # 80001288 <uvmunmap>
  return -1;
    80001e76:	557d                	li	a0,-1
}
    80001e78:	60a6                	ld	ra,72(sp)
    80001e7a:	6406                	ld	s0,64(sp)
    80001e7c:	74e2                	ld	s1,56(sp)
    80001e7e:	7942                	ld	s2,48(sp)
    80001e80:	79a2                	ld	s3,40(sp)
    80001e82:	7a02                	ld	s4,32(sp)
    80001e84:	6ae2                	ld	s5,24(sp)
    80001e86:	6b42                	ld	s6,16(sp)
    80001e88:	6ba2                	ld	s7,8(sp)
    80001e8a:	6161                	addi	sp,sp,80
    80001e8c:	8082                	ret
  return 0;
    80001e8e:	4501                	li	a0,0
    80001e90:	b7e5                	j	80001e78 <uvmcopy+0xcc>

0000000080001e92 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001e92:	1141                	addi	sp,sp,-16
    80001e94:	e406                	sd	ra,8(sp)
    80001e96:	e022                	sd	s0,0(sp)
    80001e98:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001e9a:	4601                	li	a2,0
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	10a080e7          	jalr	266(ra) # 80000fa6 <walk>
  if(pte == 0)
    80001ea4:	c901                	beqz	a0,80001eb4 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001ea6:	611c                	ld	a5,0(a0)
    80001ea8:	9bbd                	andi	a5,a5,-17
    80001eaa:	e11c                	sd	a5,0(a0)
}
    80001eac:	60a2                	ld	ra,8(sp)
    80001eae:	6402                	ld	s0,0(sp)
    80001eb0:	0141                	addi	sp,sp,16
    80001eb2:	8082                	ret
    panic("uvmclear");
    80001eb4:	00007517          	auipc	a0,0x7
    80001eb8:	73450513          	addi	a0,a0,1844 # 800095e8 <digits+0x5a8>
    80001ebc:	ffffe097          	auipc	ra,0xffffe
    80001ec0:	66e080e7          	jalr	1646(ra) # 8000052a <panic>

0000000080001ec4 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001ec4:	c6bd                	beqz	a3,80001f32 <copyout+0x6e>
{
    80001ec6:	715d                	addi	sp,sp,-80
    80001ec8:	e486                	sd	ra,72(sp)
    80001eca:	e0a2                	sd	s0,64(sp)
    80001ecc:	fc26                	sd	s1,56(sp)
    80001ece:	f84a                	sd	s2,48(sp)
    80001ed0:	f44e                	sd	s3,40(sp)
    80001ed2:	f052                	sd	s4,32(sp)
    80001ed4:	ec56                	sd	s5,24(sp)
    80001ed6:	e85a                	sd	s6,16(sp)
    80001ed8:	e45e                	sd	s7,8(sp)
    80001eda:	e062                	sd	s8,0(sp)
    80001edc:	0880                	addi	s0,sp,80
    80001ede:	8b2a                	mv	s6,a0
    80001ee0:	8c2e                	mv	s8,a1
    80001ee2:	8a32                	mv	s4,a2
    80001ee4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001ee6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001ee8:	6a85                	lui	s5,0x1
    80001eea:	a015                	j	80001f0e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001eec:	9562                	add	a0,a0,s8
    80001eee:	0004861b          	sext.w	a2,s1
    80001ef2:	85d2                	mv	a1,s4
    80001ef4:	41250533          	sub	a0,a0,s2
    80001ef8:	fffff097          	auipc	ra,0xfffff
    80001efc:	e22080e7          	jalr	-478(ra) # 80000d1a <memmove>

    len -= n;
    80001f00:	409989b3          	sub	s3,s3,s1
    src += n;
    80001f04:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001f06:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001f0a:	02098263          	beqz	s3,80001f2e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001f0e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001f12:	85ca                	mv	a1,s2
    80001f14:	855a                	mv	a0,s6
    80001f16:	fffff097          	auipc	ra,0xfffff
    80001f1a:	136080e7          	jalr	310(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    80001f1e:	cd01                	beqz	a0,80001f36 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001f20:	418904b3          	sub	s1,s2,s8
    80001f24:	94d6                	add	s1,s1,s5
    if(n > len)
    80001f26:	fc99f3e3          	bgeu	s3,s1,80001eec <copyout+0x28>
    80001f2a:	84ce                	mv	s1,s3
    80001f2c:	b7c1                	j	80001eec <copyout+0x28>
  }
  return 0;
    80001f2e:	4501                	li	a0,0
    80001f30:	a021                	j	80001f38 <copyout+0x74>
    80001f32:	4501                	li	a0,0
}
    80001f34:	8082                	ret
      return -1;
    80001f36:	557d                	li	a0,-1
}
    80001f38:	60a6                	ld	ra,72(sp)
    80001f3a:	6406                	ld	s0,64(sp)
    80001f3c:	74e2                	ld	s1,56(sp)
    80001f3e:	7942                	ld	s2,48(sp)
    80001f40:	79a2                	ld	s3,40(sp)
    80001f42:	7a02                	ld	s4,32(sp)
    80001f44:	6ae2                	ld	s5,24(sp)
    80001f46:	6b42                	ld	s6,16(sp)
    80001f48:	6ba2                	ld	s7,8(sp)
    80001f4a:	6c02                	ld	s8,0(sp)
    80001f4c:	6161                	addi	sp,sp,80
    80001f4e:	8082                	ret

0000000080001f50 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001f50:	caa5                	beqz	a3,80001fc0 <copyin+0x70>
{
    80001f52:	715d                	addi	sp,sp,-80
    80001f54:	e486                	sd	ra,72(sp)
    80001f56:	e0a2                	sd	s0,64(sp)
    80001f58:	fc26                	sd	s1,56(sp)
    80001f5a:	f84a                	sd	s2,48(sp)
    80001f5c:	f44e                	sd	s3,40(sp)
    80001f5e:	f052                	sd	s4,32(sp)
    80001f60:	ec56                	sd	s5,24(sp)
    80001f62:	e85a                	sd	s6,16(sp)
    80001f64:	e45e                	sd	s7,8(sp)
    80001f66:	e062                	sd	s8,0(sp)
    80001f68:	0880                	addi	s0,sp,80
    80001f6a:	8b2a                	mv	s6,a0
    80001f6c:	8a2e                	mv	s4,a1
    80001f6e:	8c32                	mv	s8,a2
    80001f70:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001f72:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001f74:	6a85                	lui	s5,0x1
    80001f76:	a01d                	j	80001f9c <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001f78:	018505b3          	add	a1,a0,s8
    80001f7c:	0004861b          	sext.w	a2,s1
    80001f80:	412585b3          	sub	a1,a1,s2
    80001f84:	8552                	mv	a0,s4
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	d94080e7          	jalr	-620(ra) # 80000d1a <memmove>

    len -= n;
    80001f8e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001f92:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001f94:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001f98:	02098263          	beqz	s3,80001fbc <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001f9c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001fa0:	85ca                	mv	a1,s2
    80001fa2:	855a                	mv	a0,s6
    80001fa4:	fffff097          	auipc	ra,0xfffff
    80001fa8:	0a8080e7          	jalr	168(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    80001fac:	cd01                	beqz	a0,80001fc4 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001fae:	418904b3          	sub	s1,s2,s8
    80001fb2:	94d6                	add	s1,s1,s5
    if(n > len)
    80001fb4:	fc99f2e3          	bgeu	s3,s1,80001f78 <copyin+0x28>
    80001fb8:	84ce                	mv	s1,s3
    80001fba:	bf7d                	j	80001f78 <copyin+0x28>
  }
  return 0;
    80001fbc:	4501                	li	a0,0
    80001fbe:	a021                	j	80001fc6 <copyin+0x76>
    80001fc0:	4501                	li	a0,0
}
    80001fc2:	8082                	ret
      return -1;
    80001fc4:	557d                	li	a0,-1
}
    80001fc6:	60a6                	ld	ra,72(sp)
    80001fc8:	6406                	ld	s0,64(sp)
    80001fca:	74e2                	ld	s1,56(sp)
    80001fcc:	7942                	ld	s2,48(sp)
    80001fce:	79a2                	ld	s3,40(sp)
    80001fd0:	7a02                	ld	s4,32(sp)
    80001fd2:	6ae2                	ld	s5,24(sp)
    80001fd4:	6b42                	ld	s6,16(sp)
    80001fd6:	6ba2                	ld	s7,8(sp)
    80001fd8:	6c02                	ld	s8,0(sp)
    80001fda:	6161                	addi	sp,sp,80
    80001fdc:	8082                	ret

0000000080001fde <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001fde:	c6c5                	beqz	a3,80002086 <copyinstr+0xa8>
{
    80001fe0:	715d                	addi	sp,sp,-80
    80001fe2:	e486                	sd	ra,72(sp)
    80001fe4:	e0a2                	sd	s0,64(sp)
    80001fe6:	fc26                	sd	s1,56(sp)
    80001fe8:	f84a                	sd	s2,48(sp)
    80001fea:	f44e                	sd	s3,40(sp)
    80001fec:	f052                	sd	s4,32(sp)
    80001fee:	ec56                	sd	s5,24(sp)
    80001ff0:	e85a                	sd	s6,16(sp)
    80001ff2:	e45e                	sd	s7,8(sp)
    80001ff4:	0880                	addi	s0,sp,80
    80001ff6:	8a2a                	mv	s4,a0
    80001ff8:	8b2e                	mv	s6,a1
    80001ffa:	8bb2                	mv	s7,a2
    80001ffc:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001ffe:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80002000:	6985                	lui	s3,0x1
    80002002:	a035                	j	8000202e <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80002004:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80002008:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000200a:	0017b793          	seqz	a5,a5
    8000200e:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80002012:	60a6                	ld	ra,72(sp)
    80002014:	6406                	ld	s0,64(sp)
    80002016:	74e2                	ld	s1,56(sp)
    80002018:	7942                	ld	s2,48(sp)
    8000201a:	79a2                	ld	s3,40(sp)
    8000201c:	7a02                	ld	s4,32(sp)
    8000201e:	6ae2                	ld	s5,24(sp)
    80002020:	6b42                	ld	s6,16(sp)
    80002022:	6ba2                	ld	s7,8(sp)
    80002024:	6161                	addi	sp,sp,80
    80002026:	8082                	ret
    srcva = va0 + PGSIZE;
    80002028:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000202c:	c8a9                	beqz	s1,8000207e <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000202e:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80002032:	85ca                	mv	a1,s2
    80002034:	8552                	mv	a0,s4
    80002036:	fffff097          	auipc	ra,0xfffff
    8000203a:	016080e7          	jalr	22(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    8000203e:	c131                	beqz	a0,80002082 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80002040:	41790833          	sub	a6,s2,s7
    80002044:	984e                	add	a6,a6,s3
    if(n > max)
    80002046:	0104f363          	bgeu	s1,a6,8000204c <copyinstr+0x6e>
    8000204a:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000204c:	955e                	add	a0,a0,s7
    8000204e:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80002052:	fc080be3          	beqz	a6,80002028 <copyinstr+0x4a>
    80002056:	985a                	add	a6,a6,s6
    80002058:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000205a:	41650633          	sub	a2,a0,s6
    8000205e:	14fd                	addi	s1,s1,-1
    80002060:	9b26                	add	s6,s6,s1
    80002062:	00f60733          	add	a4,a2,a5
    80002066:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd1000>
    8000206a:	df49                	beqz	a4,80002004 <copyinstr+0x26>
        *dst = *p;
    8000206c:	00e78023          	sb	a4,0(a5)
      --max;
    80002070:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80002074:	0785                	addi	a5,a5,1
    while(n > 0){
    80002076:	ff0796e3          	bne	a5,a6,80002062 <copyinstr+0x84>
      dst++;
    8000207a:	8b42                	mv	s6,a6
    8000207c:	b775                	j	80002028 <copyinstr+0x4a>
    8000207e:	4781                	li	a5,0
    80002080:	b769                	j	8000200a <copyinstr+0x2c>
      return -1;
    80002082:	557d                	li	a0,-1
    80002084:	b779                	j	80002012 <copyinstr+0x34>
  int got_null = 0;
    80002086:	4781                	li	a5,0
  if(got_null){
    80002088:	0017b793          	seqz	a5,a5
    8000208c:	40f00533          	neg	a0,a5
}
    80002090:	8082                	ret

0000000080002092 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80002092:	7139                	addi	sp,sp,-64
    80002094:	fc06                	sd	ra,56(sp)
    80002096:	f822                	sd	s0,48(sp)
    80002098:	f426                	sd	s1,40(sp)
    8000209a:	f04a                	sd	s2,32(sp)
    8000209c:	ec4e                	sd	s3,24(sp)
    8000209e:	e852                	sd	s4,16(sp)
    800020a0:	e456                	sd	s5,8(sp)
    800020a2:	e05a                	sd	s6,0(sp)
    800020a4:	0080                	addi	s0,sp,64
    800020a6:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800020a8:	00011497          	auipc	s1,0x11
    800020ac:	62848493          	addi	s1,s1,1576 # 800136d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800020b0:	8b26                	mv	s6,s1
    800020b2:	00007a97          	auipc	s5,0x7
    800020b6:	f4ea8a93          	addi	s5,s5,-178 # 80009000 <etext>
    800020ba:	04000937          	lui	s2,0x4000
    800020be:	197d                	addi	s2,s2,-1
    800020c0:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800020c2:	0001da17          	auipc	s4,0x1d
    800020c6:	60ea0a13          	addi	s4,s4,1550 # 8001f6d0 <tickslock>
    char *pa = kalloc();
    800020ca:	fffff097          	auipc	ra,0xfffff
    800020ce:	a08080e7          	jalr	-1528(ra) # 80000ad2 <kalloc>
    800020d2:	862a                	mv	a2,a0
    if(pa == 0)
    800020d4:	c131                	beqz	a0,80002118 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800020d6:	416485b3          	sub	a1,s1,s6
    800020da:	85a1                	srai	a1,a1,0x8
    800020dc:	000ab783          	ld	a5,0(s5)
    800020e0:	02f585b3          	mul	a1,a1,a5
    800020e4:	2585                	addiw	a1,a1,1
    800020e6:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800020ea:	4719                	li	a4,6
    800020ec:	6685                	lui	a3,0x1
    800020ee:	40b905b3          	sub	a1,s2,a1
    800020f2:	854e                	mv	a0,s3
    800020f4:	fffff097          	auipc	ra,0xfffff
    800020f8:	06e080e7          	jalr	110(ra) # 80001162 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020fc:	30048493          	addi	s1,s1,768
    80002100:	fd4495e3          	bne	s1,s4,800020ca <proc_mapstacks+0x38>
  }
}
    80002104:	70e2                	ld	ra,56(sp)
    80002106:	7442                	ld	s0,48(sp)
    80002108:	74a2                	ld	s1,40(sp)
    8000210a:	7902                	ld	s2,32(sp)
    8000210c:	69e2                	ld	s3,24(sp)
    8000210e:	6a42                	ld	s4,16(sp)
    80002110:	6aa2                	ld	s5,8(sp)
    80002112:	6b02                	ld	s6,0(sp)
    80002114:	6121                	addi	sp,sp,64
    80002116:	8082                	ret
      panic("kalloc");
    80002118:	00007517          	auipc	a0,0x7
    8000211c:	4e050513          	addi	a0,a0,1248 # 800095f8 <digits+0x5b8>
    80002120:	ffffe097          	auipc	ra,0xffffe
    80002124:	40a080e7          	jalr	1034(ra) # 8000052a <panic>

0000000080002128 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80002128:	7139                	addi	sp,sp,-64
    8000212a:	fc06                	sd	ra,56(sp)
    8000212c:	f822                	sd	s0,48(sp)
    8000212e:	f426                	sd	s1,40(sp)
    80002130:	f04a                	sd	s2,32(sp)
    80002132:	ec4e                	sd	s3,24(sp)
    80002134:	e852                	sd	s4,16(sp)
    80002136:	e456                	sd	s5,8(sp)
    80002138:	e05a                	sd	s6,0(sp)
    8000213a:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    8000213c:	00007597          	auipc	a1,0x7
    80002140:	4c458593          	addi	a1,a1,1220 # 80009600 <digits+0x5c0>
    80002144:	00010517          	auipc	a0,0x10
    80002148:	15c50513          	addi	a0,a0,348 # 800122a0 <pid_lock>
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	9e6080e7          	jalr	-1562(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    80002154:	00007597          	auipc	a1,0x7
    80002158:	4b458593          	addi	a1,a1,1204 # 80009608 <digits+0x5c8>
    8000215c:	00010517          	auipc	a0,0x10
    80002160:	15c50513          	addi	a0,a0,348 # 800122b8 <wait_lock>
    80002164:	fffff097          	auipc	ra,0xfffff
    80002168:	9ce080e7          	jalr	-1586(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000216c:	00011497          	auipc	s1,0x11
    80002170:	56448493          	addi	s1,s1,1380 # 800136d0 <proc>
      initlock(&p->lock, "proc");
    80002174:	00007b17          	auipc	s6,0x7
    80002178:	4a4b0b13          	addi	s6,s6,1188 # 80009618 <digits+0x5d8>
      p->kstack = KSTACK((int) (p - proc));
    8000217c:	8aa6                	mv	s5,s1
    8000217e:	00007a17          	auipc	s4,0x7
    80002182:	e82a0a13          	addi	s4,s4,-382 # 80009000 <etext>
    80002186:	04000937          	lui	s2,0x4000
    8000218a:	197d                	addi	s2,s2,-1
    8000218c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000218e:	0001d997          	auipc	s3,0x1d
    80002192:	54298993          	addi	s3,s3,1346 # 8001f6d0 <tickslock>
      initlock(&p->lock, "proc");
    80002196:	85da                	mv	a1,s6
    80002198:	8526                	mv	a0,s1
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	998080e7          	jalr	-1640(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    800021a2:	415487b3          	sub	a5,s1,s5
    800021a6:	87a1                	srai	a5,a5,0x8
    800021a8:	000a3703          	ld	a4,0(s4)
    800021ac:	02e787b3          	mul	a5,a5,a4
    800021b0:	2785                	addiw	a5,a5,1
    800021b2:	00d7979b          	slliw	a5,a5,0xd
    800021b6:	40f907b3          	sub	a5,s2,a5
    800021ba:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800021bc:	30048493          	addi	s1,s1,768
    800021c0:	fd349be3          	bne	s1,s3,80002196 <procinit+0x6e>
  }
}
    800021c4:	70e2                	ld	ra,56(sp)
    800021c6:	7442                	ld	s0,48(sp)
    800021c8:	74a2                	ld	s1,40(sp)
    800021ca:	7902                	ld	s2,32(sp)
    800021cc:	69e2                	ld	s3,24(sp)
    800021ce:	6a42                	ld	s4,16(sp)
    800021d0:	6aa2                	ld	s5,8(sp)
    800021d2:	6b02                	ld	s6,0(sp)
    800021d4:	6121                	addi	sp,sp,64
    800021d6:	8082                	ret

00000000800021d8 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800021d8:	1141                	addi	sp,sp,-16
    800021da:	e422                	sd	s0,8(sp)
    800021dc:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800021de:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800021e0:	2501                	sext.w	a0,a0
    800021e2:	6422                	ld	s0,8(sp)
    800021e4:	0141                	addi	sp,sp,16
    800021e6:	8082                	ret

00000000800021e8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800021e8:	1141                	addi	sp,sp,-16
    800021ea:	e422                	sd	s0,8(sp)
    800021ec:	0800                	addi	s0,sp,16
    800021ee:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800021f0:	2781                	sext.w	a5,a5
    800021f2:	079e                	slli	a5,a5,0x7
  return c;
}
    800021f4:	00010517          	auipc	a0,0x10
    800021f8:	0dc50513          	addi	a0,a0,220 # 800122d0 <cpus>
    800021fc:	953e                	add	a0,a0,a5
    800021fe:	6422                	ld	s0,8(sp)
    80002200:	0141                	addi	sp,sp,16
    80002202:	8082                	ret

0000000080002204 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80002204:	1101                	addi	sp,sp,-32
    80002206:	ec06                	sd	ra,24(sp)
    80002208:	e822                	sd	s0,16(sp)
    8000220a:	e426                	sd	s1,8(sp)
    8000220c:	1000                	addi	s0,sp,32
  push_off();
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	968080e7          	jalr	-1688(ra) # 80000b76 <push_off>
    80002216:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80002218:	2781                	sext.w	a5,a5
    8000221a:	079e                	slli	a5,a5,0x7
    8000221c:	00010717          	auipc	a4,0x10
    80002220:	08470713          	addi	a4,a4,132 # 800122a0 <pid_lock>
    80002224:	97ba                	add	a5,a5,a4
    80002226:	7b84                	ld	s1,48(a5)
  pop_off();
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	9ee080e7          	jalr	-1554(ra) # 80000c16 <pop_off>
  return p;
}
    80002230:	8526                	mv	a0,s1
    80002232:	60e2                	ld	ra,24(sp)
    80002234:	6442                	ld	s0,16(sp)
    80002236:	64a2                	ld	s1,8(sp)
    80002238:	6105                	addi	sp,sp,32
    8000223a:	8082                	ret

000000008000223c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    8000223c:	1141                	addi	sp,sp,-16
    8000223e:	e406                	sd	ra,8(sp)
    80002240:	e022                	sd	s0,0(sp)
    80002242:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80002244:	00000097          	auipc	ra,0x0
    80002248:	fc0080e7          	jalr	-64(ra) # 80002204 <myproc>
    8000224c:	fffff097          	auipc	ra,0xfffff
    80002250:	a2a080e7          	jalr	-1494(ra) # 80000c76 <release>

  if (first) {
    80002254:	00008797          	auipc	a5,0x8
    80002258:	a8c7a783          	lw	a5,-1396(a5) # 80009ce0 <first.1>
    8000225c:	eb89                	bnez	a5,8000226e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    8000225e:	00001097          	auipc	ra,0x1
    80002262:	d62080e7          	jalr	-670(ra) # 80002fc0 <usertrapret>
}
    80002266:	60a2                	ld	ra,8(sp)
    80002268:	6402                	ld	s0,0(sp)
    8000226a:	0141                	addi	sp,sp,16
    8000226c:	8082                	ret
    first = 0;
    8000226e:	00008797          	auipc	a5,0x8
    80002272:	a607a923          	sw	zero,-1422(a5) # 80009ce0 <first.1>
    fsinit(ROOTDEV);
    80002276:	4505                	li	a0,1
    80002278:	00002097          	auipc	ra,0x2
    8000227c:	ac2080e7          	jalr	-1342(ra) # 80003d3a <fsinit>
    80002280:	bff9                	j	8000225e <forkret+0x22>

0000000080002282 <allocpid>:
allocpid() {
    80002282:	1101                	addi	sp,sp,-32
    80002284:	ec06                	sd	ra,24(sp)
    80002286:	e822                	sd	s0,16(sp)
    80002288:	e426                	sd	s1,8(sp)
    8000228a:	e04a                	sd	s2,0(sp)
    8000228c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    8000228e:	00010917          	auipc	s2,0x10
    80002292:	01290913          	addi	s2,s2,18 # 800122a0 <pid_lock>
    80002296:	854a                	mv	a0,s2
    80002298:	fffff097          	auipc	ra,0xfffff
    8000229c:	92a080e7          	jalr	-1750(ra) # 80000bc2 <acquire>
  pid = nextpid;
    800022a0:	00008797          	auipc	a5,0x8
    800022a4:	a4478793          	addi	a5,a5,-1468 # 80009ce4 <nextpid>
    800022a8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    800022aa:	0014871b          	addiw	a4,s1,1
    800022ae:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    800022b0:	854a                	mv	a0,s2
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9c4080e7          	jalr	-1596(ra) # 80000c76 <release>
}
    800022ba:	8526                	mv	a0,s1
    800022bc:	60e2                	ld	ra,24(sp)
    800022be:	6442                	ld	s0,16(sp)
    800022c0:	64a2                	ld	s1,8(sp)
    800022c2:	6902                	ld	s2,0(sp)
    800022c4:	6105                	addi	sp,sp,32
    800022c6:	8082                	ret

00000000800022c8 <reset_counter>:
reset_counter(){
    800022c8:	1141                	addi	sp,sp,-16
    800022ca:	e422                	sd	s0,8(sp)
    800022cc:	0800                	addi	s0,sp,16
}
    800022ce:	4501                	li	a0,0
    800022d0:	6422                	ld	s0,8(sp)
    800022d2:	0141                	addi	sp,sp,16
    800022d4:	8082                	ret

00000000800022d6 <proc_pagetable>:
{
    800022d6:	1101                	addi	sp,sp,-32
    800022d8:	ec06                	sd	ra,24(sp)
    800022da:	e822                	sd	s0,16(sp)
    800022dc:	e426                	sd	s1,8(sp)
    800022de:	e04a                	sd	s2,0(sp)
    800022e0:	1000                	addi	s0,sp,32
    800022e2:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	068080e7          	jalr	104(ra) # 8000134c <uvmcreate>
    800022ec:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800022ee:	c121                	beqz	a0,8000232e <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800022f0:	4729                	li	a4,10
    800022f2:	00006697          	auipc	a3,0x6
    800022f6:	d0e68693          	addi	a3,a3,-754 # 80008000 <_trampoline>
    800022fa:	6605                	lui	a2,0x1
    800022fc:	040005b7          	lui	a1,0x4000
    80002300:	15fd                	addi	a1,a1,-1
    80002302:	05b2                	slli	a1,a1,0xc
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	d8a080e7          	jalr	-630(ra) # 8000108e <mappages>
    8000230c:	02054863          	bltz	a0,8000233c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80002310:	4719                	li	a4,6
    80002312:	05893683          	ld	a3,88(s2)
    80002316:	6605                	lui	a2,0x1
    80002318:	020005b7          	lui	a1,0x2000
    8000231c:	15fd                	addi	a1,a1,-1
    8000231e:	05b6                	slli	a1,a1,0xd
    80002320:	8526                	mv	a0,s1
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	d6c080e7          	jalr	-660(ra) # 8000108e <mappages>
    8000232a:	02054163          	bltz	a0,8000234c <proc_pagetable+0x76>
}
    8000232e:	8526                	mv	a0,s1
    80002330:	60e2                	ld	ra,24(sp)
    80002332:	6442                	ld	s0,16(sp)
    80002334:	64a2                	ld	s1,8(sp)
    80002336:	6902                	ld	s2,0(sp)
    80002338:	6105                	addi	sp,sp,32
    8000233a:	8082                	ret
    uvmfree(pagetable, 0);
    8000233c:	4581                	li	a1,0
    8000233e:	8526                	mv	a0,s1
    80002340:	00000097          	auipc	ra,0x0
    80002344:	a34080e7          	jalr	-1484(ra) # 80001d74 <uvmfree>
    return 0;
    80002348:	4481                	li	s1,0
    8000234a:	b7d5                	j	8000232e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    8000234c:	4681                	li	a3,0
    8000234e:	4605                	li	a2,1
    80002350:	040005b7          	lui	a1,0x4000
    80002354:	15fd                	addi	a1,a1,-1
    80002356:	05b2                	slli	a1,a1,0xc
    80002358:	8526                	mv	a0,s1
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	f2e080e7          	jalr	-210(ra) # 80001288 <uvmunmap>
    uvmfree(pagetable, 0);
    80002362:	4581                	li	a1,0
    80002364:	8526                	mv	a0,s1
    80002366:	00000097          	auipc	ra,0x0
    8000236a:	a0e080e7          	jalr	-1522(ra) # 80001d74 <uvmfree>
    return 0;
    8000236e:	4481                	li	s1,0
    80002370:	bf7d                	j	8000232e <proc_pagetable+0x58>

0000000080002372 <proc_freepagetable>:
{
    80002372:	1101                	addi	sp,sp,-32
    80002374:	ec06                	sd	ra,24(sp)
    80002376:	e822                	sd	s0,16(sp)
    80002378:	e426                	sd	s1,8(sp)
    8000237a:	e04a                	sd	s2,0(sp)
    8000237c:	1000                	addi	s0,sp,32
    8000237e:	84aa                	mv	s1,a0
    80002380:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002382:	4681                	li	a3,0
    80002384:	4605                	li	a2,1
    80002386:	040005b7          	lui	a1,0x4000
    8000238a:	15fd                	addi	a1,a1,-1
    8000238c:	05b2                	slli	a1,a1,0xc
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	efa080e7          	jalr	-262(ra) # 80001288 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80002396:	4681                	li	a3,0
    80002398:	4605                	li	a2,1
    8000239a:	020005b7          	lui	a1,0x2000
    8000239e:	15fd                	addi	a1,a1,-1
    800023a0:	05b6                	slli	a1,a1,0xd
    800023a2:	8526                	mv	a0,s1
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	ee4080e7          	jalr	-284(ra) # 80001288 <uvmunmap>
  uvmfree(pagetable, sz);
    800023ac:	85ca                	mv	a1,s2
    800023ae:	8526                	mv	a0,s1
    800023b0:	00000097          	auipc	ra,0x0
    800023b4:	9c4080e7          	jalr	-1596(ra) # 80001d74 <uvmfree>
}
    800023b8:	60e2                	ld	ra,24(sp)
    800023ba:	6442                	ld	s0,16(sp)
    800023bc:	64a2                	ld	s1,8(sp)
    800023be:	6902                	ld	s2,0(sp)
    800023c0:	6105                	addi	sp,sp,32
    800023c2:	8082                	ret

00000000800023c4 <freeproc>:
{
    800023c4:	1101                	addi	sp,sp,-32
    800023c6:	ec06                	sd	ra,24(sp)
    800023c8:	e822                	sd	s0,16(sp)
    800023ca:	e426                	sd	s1,8(sp)
    800023cc:	1000                	addi	s0,sp,32
    800023ce:	84aa                	mv	s1,a0
  if(p->trapframe)
    800023d0:	6d28                	ld	a0,88(a0)
    800023d2:	c509                	beqz	a0,800023dc <freeproc+0x18>
    kfree((void*)p->trapframe);
    800023d4:	ffffe097          	auipc	ra,0xffffe
    800023d8:	602080e7          	jalr	1538(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    800023dc:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    800023e0:	68a8                	ld	a0,80(s1)
    800023e2:	c511                	beqz	a0,800023ee <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    800023e4:	64ac                	ld	a1,72(s1)
    800023e6:	00000097          	auipc	ra,0x0
    800023ea:	f8c080e7          	jalr	-116(ra) # 80002372 <proc_freepagetable>
  p->pagetable = 0;
    800023ee:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    800023f2:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    800023f6:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    800023fa:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    800023fe:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80002402:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80002406:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    8000240a:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    8000240e:	0004ac23          	sw	zero,24(s1)
}
    80002412:	60e2                	ld	ra,24(sp)
    80002414:	6442                	ld	s0,16(sp)
    80002416:	64a2                	ld	s1,8(sp)
    80002418:	6105                	addi	sp,sp,32
    8000241a:	8082                	ret

000000008000241c <allocproc>:
{
    8000241c:	7179                	addi	sp,sp,-48
    8000241e:	f406                	sd	ra,40(sp)
    80002420:	f022                	sd	s0,32(sp)
    80002422:	ec26                	sd	s1,24(sp)
    80002424:	e84a                	sd	s2,16(sp)
    80002426:	e44e                	sd	s3,8(sp)
    80002428:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    8000242a:	00011497          	auipc	s1,0x11
    8000242e:	2a648493          	addi	s1,s1,678 # 800136d0 <proc>
    80002432:	0001d997          	auipc	s3,0x1d
    80002436:	29e98993          	addi	s3,s3,670 # 8001f6d0 <tickslock>
    acquire(&p->lock);
    8000243a:	8926                	mv	s2,s1
    8000243c:	8526                	mv	a0,s1
    8000243e:	ffffe097          	auipc	ra,0xffffe
    80002442:	784080e7          	jalr	1924(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80002446:	4c9c                	lw	a5,24(s1)
    80002448:	cf81                	beqz	a5,80002460 <allocproc+0x44>
      release(&p->lock);
    8000244a:	8526                	mv	a0,s1
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	82a080e7          	jalr	-2006(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002454:	30048493          	addi	s1,s1,768
    80002458:	ff3491e3          	bne	s1,s3,8000243a <allocproc+0x1e>
  return 0;
    8000245c:	4481                	li	s1,0
    8000245e:	a069                	j	800024e8 <allocproc+0xcc>
  p->pid = allocpid();
    80002460:	00000097          	auipc	ra,0x0
    80002464:	e22080e7          	jalr	-478(ra) # 80002282 <allocpid>
    80002468:	d888                	sw	a0,48(s1)
  p->state = USED;
    8000246a:	4785                	li	a5,1
    8000246c:	cc9c                	sw	a5,24(s1)
  if (p->pid>2){
    8000246e:	4789                	li	a5,2
    80002470:	08a7c463          	blt	a5,a0,800024f8 <allocproc+0xdc>
    p->swapped_pages.page_counter=0;
    80002474:	2e04ac23          	sw	zero,760(s1)
    p->ram_pages.page_counter=0;
    80002478:	2204aa23          	sw	zero,564(s1)
    p->ram_pages.first_page_in=0; 
    8000247c:	2204a823          	sw	zero,560(s1)
    for (int i=0 ; i<MAX_PSYC_PAGES ; i++){
    80002480:	17048793          	addi	a5,s1,368
    80002484:	23090913          	addi	s2,s2,560
      p->swapped_pages.pages[i].virtual_address = 0;
    80002488:	0c07a423          	sw	zero,200(a5)
      p->swapped_pages.pages[i].is_used = 0;
    8000248c:	0c07a623          	sw	zero,204(a5)
      p->swapped_pages.pages[i].page_counter=reset_counter();
    80002490:	0c07a823          	sw	zero,208(a5)
      p->ram_pages.pages[i].virtual_address = 0;
    80002494:	0007a023          	sw	zero,0(a5)
      p->ram_pages.pages[i].is_used = 0;
    80002498:	0007a223          	sw	zero,4(a5)
      p->ram_pages.pages[i].page_counter = reset_counter();
    8000249c:	0007a423          	sw	zero,8(a5)
    for (int i=0 ; i<MAX_PSYC_PAGES ; i++){
    800024a0:	07b1                	addi	a5,a5,12
    800024a2:	ff2793e3          	bne	a5,s2,80002488 <allocproc+0x6c>
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800024a6:	ffffe097          	auipc	ra,0xffffe
    800024aa:	62c080e7          	jalr	1580(ra) # 80000ad2 <kalloc>
    800024ae:	892a                	mv	s2,a0
    800024b0:	eca8                	sd	a0,88(s1)
    800024b2:	c13d                	beqz	a0,80002518 <allocproc+0xfc>
  p->pagetable = proc_pagetable(p);
    800024b4:	8526                	mv	a0,s1
    800024b6:	00000097          	auipc	ra,0x0
    800024ba:	e20080e7          	jalr	-480(ra) # 800022d6 <proc_pagetable>
    800024be:	892a                	mv	s2,a0
    800024c0:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    800024c2:	c53d                	beqz	a0,80002530 <allocproc+0x114>
  memset(&p->context, 0, sizeof(p->context));
    800024c4:	07000613          	li	a2,112
    800024c8:	4581                	li	a1,0
    800024ca:	06048513          	addi	a0,s1,96
    800024ce:	ffffe097          	auipc	ra,0xffffe
    800024d2:	7f0080e7          	jalr	2032(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    800024d6:	00000797          	auipc	a5,0x0
    800024da:	d6678793          	addi	a5,a5,-666 # 8000223c <forkret>
    800024de:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    800024e0:	60bc                	ld	a5,64(s1)
    800024e2:	6705                	lui	a4,0x1
    800024e4:	97ba                	add	a5,a5,a4
    800024e6:	f4bc                	sd	a5,104(s1)
}
    800024e8:	8526                	mv	a0,s1
    800024ea:	70a2                	ld	ra,40(sp)
    800024ec:	7402                	ld	s0,32(sp)
    800024ee:	64e2                	ld	s1,24(sp)
    800024f0:	6942                	ld	s2,16(sp)
    800024f2:	69a2                	ld	s3,8(sp)
    800024f4:	6145                	addi	sp,sp,48
    800024f6:	8082                	ret
    release(&p->lock); 
    800024f8:	8526                	mv	a0,s1
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	77c080e7          	jalr	1916(ra) # 80000c76 <release>
    createSwapFile(p);
    80002502:	8526                	mv	a0,s1
    80002504:	00002097          	auipc	ra,0x2
    80002508:	4b8080e7          	jalr	1208(ra) # 800049bc <createSwapFile>
    acquire(&p->lock); 
    8000250c:	8526                	mv	a0,s1
    8000250e:	ffffe097          	auipc	ra,0xffffe
    80002512:	6b4080e7          	jalr	1716(ra) # 80000bc2 <acquire>
    80002516:	bfb9                	j	80002474 <allocproc+0x58>
    freeproc(p);
    80002518:	8526                	mv	a0,s1
    8000251a:	00000097          	auipc	ra,0x0
    8000251e:	eaa080e7          	jalr	-342(ra) # 800023c4 <freeproc>
    release(&p->lock);
    80002522:	8526                	mv	a0,s1
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	752080e7          	jalr	1874(ra) # 80000c76 <release>
    return 0;
    8000252c:	84ca                	mv	s1,s2
    8000252e:	bf6d                	j	800024e8 <allocproc+0xcc>
    freeproc(p);
    80002530:	8526                	mv	a0,s1
    80002532:	00000097          	auipc	ra,0x0
    80002536:	e92080e7          	jalr	-366(ra) # 800023c4 <freeproc>
    release(&p->lock);
    8000253a:	8526                	mv	a0,s1
    8000253c:	ffffe097          	auipc	ra,0xffffe
    80002540:	73a080e7          	jalr	1850(ra) # 80000c76 <release>
    return 0;
    80002544:	84ca                	mv	s1,s2
    80002546:	b74d                	j	800024e8 <allocproc+0xcc>

0000000080002548 <userinit>:
{
    80002548:	1101                	addi	sp,sp,-32
    8000254a:	ec06                	sd	ra,24(sp)
    8000254c:	e822                	sd	s0,16(sp)
    8000254e:	e426                	sd	s1,8(sp)
    80002550:	1000                	addi	s0,sp,32
  p = allocproc();
    80002552:	00000097          	auipc	ra,0x0
    80002556:	eca080e7          	jalr	-310(ra) # 8000241c <allocproc>
    8000255a:	84aa                	mv	s1,a0
  initproc = p;
    8000255c:	00008797          	auipc	a5,0x8
    80002560:	aca7b623          	sd	a0,-1332(a5) # 8000a028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002564:	03400613          	li	a2,52
    80002568:	00007597          	auipc	a1,0x7
    8000256c:	78858593          	addi	a1,a1,1928 # 80009cf0 <initcode>
    80002570:	6928                	ld	a0,80(a0)
    80002572:	fffff097          	auipc	ra,0xfffff
    80002576:	e08080e7          	jalr	-504(ra) # 8000137a <uvminit>
  p->sz = PGSIZE;
    8000257a:	6785                	lui	a5,0x1
    8000257c:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    8000257e:	6cb8                	ld	a4,88(s1)
    80002580:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002584:	6cb8                	ld	a4,88(s1)
    80002586:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002588:	4641                	li	a2,16
    8000258a:	00007597          	auipc	a1,0x7
    8000258e:	09658593          	addi	a1,a1,150 # 80009620 <digits+0x5e0>
    80002592:	15848513          	addi	a0,s1,344
    80002596:	fffff097          	auipc	ra,0xfffff
    8000259a:	87a080e7          	jalr	-1926(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    8000259e:	00007517          	auipc	a0,0x7
    800025a2:	09250513          	addi	a0,a0,146 # 80009630 <digits+0x5f0>
    800025a6:	00002097          	auipc	ra,0x2
    800025aa:	1c2080e7          	jalr	450(ra) # 80004768 <namei>
    800025ae:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    800025b2:	478d                	li	a5,3
    800025b4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    800025b6:	8526                	mv	a0,s1
    800025b8:	ffffe097          	auipc	ra,0xffffe
    800025bc:	6be080e7          	jalr	1726(ra) # 80000c76 <release>
}
    800025c0:	60e2                	ld	ra,24(sp)
    800025c2:	6442                	ld	s0,16(sp)
    800025c4:	64a2                	ld	s1,8(sp)
    800025c6:	6105                	addi	sp,sp,32
    800025c8:	8082                	ret

00000000800025ca <growproc>:
{
    800025ca:	7179                	addi	sp,sp,-48
    800025cc:	f406                	sd	ra,40(sp)
    800025ce:	f022                	sd	s0,32(sp)
    800025d0:	ec26                	sd	s1,24(sp)
    800025d2:	e84a                	sd	s2,16(sp)
    800025d4:	e44e                	sd	s3,8(sp)
    800025d6:	e052                	sd	s4,0(sp)
    800025d8:	1800                	addi	s0,sp,48
    800025da:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800025dc:	00000097          	auipc	ra,0x0
    800025e0:	c28080e7          	jalr	-984(ra) # 80002204 <myproc>
    800025e4:	89aa                	mv	s3,a0
  sz = p->sz;
    800025e6:	04853a03          	ld	s4,72(a0)
    800025ea:	000a049b          	sext.w	s1,s4
  if(n > 0){
    800025ee:	03204163          	bgtz	s2,80002610 <growproc+0x46>
  } else if(n < 0){
    800025f2:	04094963          	bltz	s2,80002644 <growproc+0x7a>
  p->sz = sz;
    800025f6:	1482                	slli	s1,s1,0x20
    800025f8:	9081                	srli	s1,s1,0x20
    800025fa:	0499b423          	sd	s1,72(s3)
  return 0;
    800025fe:	4501                	li	a0,0
}
    80002600:	70a2                	ld	ra,40(sp)
    80002602:	7402                	ld	s0,32(sp)
    80002604:	64e2                	ld	s1,24(sp)
    80002606:	6942                	ld	s2,16(sp)
    80002608:	69a2                	ld	s3,8(sp)
    8000260a:	6a02                	ld	s4,0(sp)
    8000260c:	6145                	addi	sp,sp,48
    8000260e:	8082                	ret
    printf("Call uvmalloc from growproc, line 281"); 
    80002610:	00007517          	auipc	a0,0x7
    80002614:	02850513          	addi	a0,a0,40 # 80009638 <digits+0x5f8>
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	f5c080e7          	jalr	-164(ra) # 80000574 <printf>
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002620:	0099063b          	addw	a2,s2,s1
    80002624:	1602                	slli	a2,a2,0x20
    80002626:	9201                	srli	a2,a2,0x20
    80002628:	020a1593          	slli	a1,s4,0x20
    8000262c:	9181                	srli	a1,a1,0x20
    8000262e:	0509b503          	ld	a0,80(s3)
    80002632:	fffff097          	auipc	ra,0xfffff
    80002636:	4ba080e7          	jalr	1210(ra) # 80001aec <uvmalloc>
    8000263a:	0005049b          	sext.w	s1,a0
    8000263e:	fcc5                	bnez	s1,800025f6 <growproc+0x2c>
      return -1;
    80002640:	557d                	li	a0,-1
    80002642:	bf7d                	j	80002600 <growproc+0x36>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002644:	0099063b          	addw	a2,s2,s1
    80002648:	1602                	slli	a2,a2,0x20
    8000264a:	9201                	srli	a2,a2,0x20
    8000264c:	020a1593          	slli	a1,s4,0x20
    80002650:	9181                	srli	a1,a1,0x20
    80002652:	6928                	ld	a0,80(a0)
    80002654:	fffff097          	auipc	ra,0xfffff
    80002658:	138080e7          	jalr	312(ra) # 8000178c <uvmdealloc>
    8000265c:	0005049b          	sext.w	s1,a0
    80002660:	bf59                	j	800025f6 <growproc+0x2c>

0000000080002662 <fork>:
{
    80002662:	711d                	addi	sp,sp,-96
    80002664:	ec86                	sd	ra,88(sp)
    80002666:	e8a2                	sd	s0,80(sp)
    80002668:	e4a6                	sd	s1,72(sp)
    8000266a:	e0ca                	sd	s2,64(sp)
    8000266c:	fc4e                	sd	s3,56(sp)
    8000266e:	f852                	sd	s4,48(sp)
    80002670:	f456                	sd	s5,40(sp)
    80002672:	f05a                	sd	s6,32(sp)
    80002674:	ec5e                	sd	s7,24(sp)
    80002676:	e862                	sd	s8,16(sp)
    80002678:	e466                	sd	s9,8(sp)
    8000267a:	1080                	addi	s0,sp,96
  struct proc *p = myproc();
    8000267c:	00000097          	auipc	ra,0x0
    80002680:	b88080e7          	jalr	-1144(ra) # 80002204 <myproc>
    80002684:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80002686:	00000097          	auipc	ra,0x0
    8000268a:	d96080e7          	jalr	-618(ra) # 8000241c <allocproc>
    8000268e:	1a050a63          	beqz	a0,80002842 <fork+0x1e0>
    80002692:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002694:	048ab603          	ld	a2,72(s5)
    80002698:	692c                	ld	a1,80(a0)
    8000269a:	050ab503          	ld	a0,80(s5)
    8000269e:	fffff097          	auipc	ra,0xfffff
    800026a2:	70e080e7          	jalr	1806(ra) # 80001dac <uvmcopy>
    800026a6:	04054863          	bltz	a0,800026f6 <fork+0x94>
  np->sz = p->sz;
    800026aa:	048ab783          	ld	a5,72(s5)
    800026ae:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    800026b2:	058ab683          	ld	a3,88(s5)
    800026b6:	87b6                	mv	a5,a3
    800026b8:	058a3703          	ld	a4,88(s4)
    800026bc:	12068693          	addi	a3,a3,288
    800026c0:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800026c4:	6788                	ld	a0,8(a5)
    800026c6:	6b8c                	ld	a1,16(a5)
    800026c8:	6f90                	ld	a2,24(a5)
    800026ca:	01073023          	sd	a6,0(a4)
    800026ce:	e708                	sd	a0,8(a4)
    800026d0:	eb0c                	sd	a1,16(a4)
    800026d2:	ef10                	sd	a2,24(a4)
    800026d4:	02078793          	addi	a5,a5,32
    800026d8:	02070713          	addi	a4,a4,32
    800026dc:	fed792e3          	bne	a5,a3,800026c0 <fork+0x5e>
  np->trapframe->a0 = 0;
    800026e0:	058a3783          	ld	a5,88(s4)
    800026e4:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    800026e8:	0d0a8493          	addi	s1,s5,208
    800026ec:	0d0a0913          	addi	s2,s4,208
    800026f0:	150a8993          	addi	s3,s5,336
    800026f4:	a00d                	j	80002716 <fork+0xb4>
    freeproc(np);
    800026f6:	8552                	mv	a0,s4
    800026f8:	00000097          	auipc	ra,0x0
    800026fc:	ccc080e7          	jalr	-820(ra) # 800023c4 <freeproc>
    release(&np->lock);
    80002700:	8552                	mv	a0,s4
    80002702:	ffffe097          	auipc	ra,0xffffe
    80002706:	574080e7          	jalr	1396(ra) # 80000c76 <release>
    return -1;
    8000270a:	5cfd                	li	s9,-1
    8000270c:	aa29                	j	80002826 <fork+0x1c4>
  for(i = 0; i < NOFILE; i++)
    8000270e:	04a1                	addi	s1,s1,8
    80002710:	0921                	addi	s2,s2,8
    80002712:	01348b63          	beq	s1,s3,80002728 <fork+0xc6>
    if(p->ofile[i])
    80002716:	6088                	ld	a0,0(s1)
    80002718:	d97d                	beqz	a0,8000270e <fork+0xac>
      np->ofile[i] = filedup(p->ofile[i]);
    8000271a:	00003097          	auipc	ra,0x3
    8000271e:	9fa080e7          	jalr	-1542(ra) # 80005114 <filedup>
    80002722:	00a93023          	sd	a0,0(s2)
    80002726:	b7e5                	j	8000270e <fork+0xac>
  np->cwd = idup(p->cwd);
    80002728:	150ab503          	ld	a0,336(s5)
    8000272c:	00002097          	auipc	ra,0x2
    80002730:	848080e7          	jalr	-1976(ra) # 80003f74 <idup>
    80002734:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002738:	4641                	li	a2,16
    8000273a:	158a8593          	addi	a1,s5,344
    8000273e:	158a0513          	addi	a0,s4,344
    80002742:	ffffe097          	auipc	ra,0xffffe
    80002746:	6ce080e7          	jalr	1742(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    8000274a:	030a2c83          	lw	s9,48(s4)
  release(&np->lock);
    8000274e:	8552                	mv	a0,s4
    80002750:	ffffe097          	auipc	ra,0xffffe
    80002754:	526080e7          	jalr	1318(ra) # 80000c76 <release>
  if(p->pid > 2) {
    80002758:	030aa703          	lw	a4,48(s5)
    8000275c:	4789                	li	a5,2
    8000275e:	08e7d763          	bge	a5,a4,800027ec <fork+0x18a>
    np->swapped_pages.page_counter = p->swapped_pages.page_counter;
    80002762:	2f8aa783          	lw	a5,760(s5)
    80002766:	2efa2c23          	sw	a5,760(s4)
    np->ram_pages.page_counter = p->ram_pages.page_counter;
    8000276a:	234aa783          	lw	a5,564(s5)
    8000276e:	22fa2a23          	sw	a5,564(s4)
    np->ram_pages.first_page_in = p->ram_pages.page_counter; 
    80002772:	22fa2823          	sw	a5,560(s4)
    for (int i=0 ; i<MAX_PSYC_PAGES ; i++){
    80002776:	170a8493          	addi	s1,s5,368
    8000277a:	170a0913          	addi	s2,s4,368
    8000277e:	230a8b93          	addi	s7,s5,560
    np->ram_pages.first_page_in = p->ram_pages.page_counter; 
    80002782:	4981                	li	s3,0
        readFromSwapFile(p, buffer, i*PGSIZE, (PGSIZE));
    80002784:	00010c17          	auipc	s8,0x10
    80002788:	f4cc0c13          	addi	s8,s8,-180 # 800126d0 <buffer>
    for (int i=0 ; i<MAX_PSYC_PAGES ; i++){
    8000278c:	6b05                	lui	s6,0x1
    8000278e:	a03d                	j	800027bc <fork+0x15a>
        readFromSwapFile(p, buffer, i*PGSIZE, (PGSIZE));
    80002790:	6685                	lui	a3,0x1
    80002792:	864e                	mv	a2,s3
    80002794:	85e2                	mv	a1,s8
    80002796:	8556                	mv	a0,s5
    80002798:	00002097          	auipc	ra,0x2
    8000279c:	2f8080e7          	jalr	760(ra) # 80004a90 <readFromSwapFile>
        writeToSwapFile(np, buffer, i*PGSIZE, (PGSIZE));
    800027a0:	6685                	lui	a3,0x1
    800027a2:	864e                	mv	a2,s3
    800027a4:	85e2                	mv	a1,s8
    800027a6:	8552                	mv	a0,s4
    800027a8:	00002097          	auipc	ra,0x2
    800027ac:	2c4080e7          	jalr	708(ra) # 80004a6c <writeToSwapFile>
    for (int i=0 ; i<MAX_PSYC_PAGES ; i++){
    800027b0:	04b1                	addi	s1,s1,12
    800027b2:	0931                	addi	s2,s2,12
    800027b4:	013b09bb          	addw	s3,s6,s3
    800027b8:	03748a63          	beq	s1,s7,800027ec <fork+0x18a>
      np->swapped_pages.pages[i].virtual_address = p->swapped_pages.pages[i].virtual_address;
    800027bc:	0c84a783          	lw	a5,200(s1)
    800027c0:	0cf92423          	sw	a5,200(s2)
      np->swapped_pages.pages[i].is_used = p->swapped_pages.pages[i].is_used;
    800027c4:	0cc4a783          	lw	a5,204(s1)
    800027c8:	0cf92623          	sw	a5,204(s2)
      np->swapped_pages.pages[i].page_counter = p->swapped_pages.pages[i].page_counter;
    800027cc:	0d04a783          	lw	a5,208(s1)
    800027d0:	0cf92823          	sw	a5,208(s2)
      np->ram_pages.pages[i].virtual_address = p->ram_pages.pages[i].virtual_address;
    800027d4:	409c                	lw	a5,0(s1)
    800027d6:	00f92023          	sw	a5,0(s2)
      np->ram_pages.pages[i].is_used = p->ram_pages.pages[i].is_used;
    800027da:	40dc                	lw	a5,4(s1)
    800027dc:	00f92223          	sw	a5,4(s2)
      np->ram_pages.pages[i].page_counter = p->ram_pages.pages[i].page_counter;
    800027e0:	449c                	lw	a5,8(s1)
    800027e2:	00f92423          	sw	a5,8(s2)
      if (p->ram_pages.pages[i].is_used){
    800027e6:	40dc                	lw	a5,4(s1)
    800027e8:	d7e1                	beqz	a5,800027b0 <fork+0x14e>
    800027ea:	b75d                	j	80002790 <fork+0x12e>
  acquire(&wait_lock);
    800027ec:	00010497          	auipc	s1,0x10
    800027f0:	acc48493          	addi	s1,s1,-1332 # 800122b8 <wait_lock>
    800027f4:	8526                	mv	a0,s1
    800027f6:	ffffe097          	auipc	ra,0xffffe
    800027fa:	3cc080e7          	jalr	972(ra) # 80000bc2 <acquire>
  np->parent = p;
    800027fe:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80002802:	8526                	mv	a0,s1
    80002804:	ffffe097          	auipc	ra,0xffffe
    80002808:	472080e7          	jalr	1138(ra) # 80000c76 <release>
  acquire(&np->lock);
    8000280c:	8552                	mv	a0,s4
    8000280e:	ffffe097          	auipc	ra,0xffffe
    80002812:	3b4080e7          	jalr	948(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80002816:	478d                	li	a5,3
    80002818:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    8000281c:	8552                	mv	a0,s4
    8000281e:	ffffe097          	auipc	ra,0xffffe
    80002822:	458080e7          	jalr	1112(ra) # 80000c76 <release>
}
    80002826:	8566                	mv	a0,s9
    80002828:	60e6                	ld	ra,88(sp)
    8000282a:	6446                	ld	s0,80(sp)
    8000282c:	64a6                	ld	s1,72(sp)
    8000282e:	6906                	ld	s2,64(sp)
    80002830:	79e2                	ld	s3,56(sp)
    80002832:	7a42                	ld	s4,48(sp)
    80002834:	7aa2                	ld	s5,40(sp)
    80002836:	7b02                	ld	s6,32(sp)
    80002838:	6be2                	ld	s7,24(sp)
    8000283a:	6c42                	ld	s8,16(sp)
    8000283c:	6ca2                	ld	s9,8(sp)
    8000283e:	6125                	addi	sp,sp,96
    80002840:	8082                	ret
    return -1;
    80002842:	5cfd                	li	s9,-1
    80002844:	b7cd                	j	80002826 <fork+0x1c4>

0000000080002846 <scheduler>:
{
    80002846:	7139                	addi	sp,sp,-64
    80002848:	fc06                	sd	ra,56(sp)
    8000284a:	f822                	sd	s0,48(sp)
    8000284c:	f426                	sd	s1,40(sp)
    8000284e:	f04a                	sd	s2,32(sp)
    80002850:	ec4e                	sd	s3,24(sp)
    80002852:	e852                	sd	s4,16(sp)
    80002854:	e456                	sd	s5,8(sp)
    80002856:	e05a                	sd	s6,0(sp)
    80002858:	0080                	addi	s0,sp,64
    8000285a:	8792                	mv	a5,tp
  int id = r_tp();
    8000285c:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000285e:	00779a93          	slli	s5,a5,0x7
    80002862:	00010717          	auipc	a4,0x10
    80002866:	a3e70713          	addi	a4,a4,-1474 # 800122a0 <pid_lock>
    8000286a:	9756                	add	a4,a4,s5
    8000286c:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002870:	00010717          	auipc	a4,0x10
    80002874:	a6870713          	addi	a4,a4,-1432 # 800122d8 <cpus+0x8>
    80002878:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    8000287a:	498d                	li	s3,3
        p->state = RUNNING;
    8000287c:	4b11                	li	s6,4
        c->proc = p;
    8000287e:	079e                	slli	a5,a5,0x7
    80002880:	00010a17          	auipc	s4,0x10
    80002884:	a20a0a13          	addi	s4,s4,-1504 # 800122a0 <pid_lock>
    80002888:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000288a:	0001d917          	auipc	s2,0x1d
    8000288e:	e4690913          	addi	s2,s2,-442 # 8001f6d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002892:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002896:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000289a:	10079073          	csrw	sstatus,a5
    8000289e:	00011497          	auipc	s1,0x11
    800028a2:	e3248493          	addi	s1,s1,-462 # 800136d0 <proc>
    800028a6:	a811                	j	800028ba <scheduler+0x74>
      release(&p->lock);
    800028a8:	8526                	mv	a0,s1
    800028aa:	ffffe097          	auipc	ra,0xffffe
    800028ae:	3cc080e7          	jalr	972(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800028b2:	30048493          	addi	s1,s1,768
    800028b6:	fd248ee3          	beq	s1,s2,80002892 <scheduler+0x4c>
      acquire(&p->lock);
    800028ba:	8526                	mv	a0,s1
    800028bc:	ffffe097          	auipc	ra,0xffffe
    800028c0:	306080e7          	jalr	774(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    800028c4:	4c9c                	lw	a5,24(s1)
    800028c6:	ff3791e3          	bne	a5,s3,800028a8 <scheduler+0x62>
        p->state = RUNNING;
    800028ca:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    800028ce:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    800028d2:	06048593          	addi	a1,s1,96
    800028d6:	8556                	mv	a0,s5
    800028d8:	00000097          	auipc	ra,0x0
    800028dc:	63e080e7          	jalr	1598(ra) # 80002f16 <swtch>
          update_pages_counters();
    800028e0:	fffff097          	auipc	ra,0xfffff
    800028e4:	b0c080e7          	jalr	-1268(ra) # 800013ec <update_pages_counters>
        c->proc = 0;
    800028e8:	020a3823          	sd	zero,48(s4)
    800028ec:	bf75                	j	800028a8 <scheduler+0x62>

00000000800028ee <sched>:
{
    800028ee:	7179                	addi	sp,sp,-48
    800028f0:	f406                	sd	ra,40(sp)
    800028f2:	f022                	sd	s0,32(sp)
    800028f4:	ec26                	sd	s1,24(sp)
    800028f6:	e84a                	sd	s2,16(sp)
    800028f8:	e44e                	sd	s3,8(sp)
    800028fa:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800028fc:	00000097          	auipc	ra,0x0
    80002900:	908080e7          	jalr	-1784(ra) # 80002204 <myproc>
    80002904:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	242080e7          	jalr	578(ra) # 80000b48 <holding>
    8000290e:	c93d                	beqz	a0,80002984 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002910:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002912:	2781                	sext.w	a5,a5
    80002914:	079e                	slli	a5,a5,0x7
    80002916:	00010717          	auipc	a4,0x10
    8000291a:	98a70713          	addi	a4,a4,-1654 # 800122a0 <pid_lock>
    8000291e:	97ba                	add	a5,a5,a4
    80002920:	0a87a703          	lw	a4,168(a5)
    80002924:	4785                	li	a5,1
    80002926:	06f71763          	bne	a4,a5,80002994 <sched+0xa6>
  if(p->state == RUNNING)
    8000292a:	4c98                	lw	a4,24(s1)
    8000292c:	4791                	li	a5,4
    8000292e:	06f70b63          	beq	a4,a5,800029a4 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002932:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002936:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002938:	efb5                	bnez	a5,800029b4 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000293a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000293c:	00010917          	auipc	s2,0x10
    80002940:	96490913          	addi	s2,s2,-1692 # 800122a0 <pid_lock>
    80002944:	2781                	sext.w	a5,a5
    80002946:	079e                	slli	a5,a5,0x7
    80002948:	97ca                	add	a5,a5,s2
    8000294a:	0ac7a983          	lw	s3,172(a5)
    8000294e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002950:	2781                	sext.w	a5,a5
    80002952:	079e                	slli	a5,a5,0x7
    80002954:	00010597          	auipc	a1,0x10
    80002958:	98458593          	addi	a1,a1,-1660 # 800122d8 <cpus+0x8>
    8000295c:	95be                	add	a1,a1,a5
    8000295e:	06048513          	addi	a0,s1,96
    80002962:	00000097          	auipc	ra,0x0
    80002966:	5b4080e7          	jalr	1460(ra) # 80002f16 <swtch>
    8000296a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000296c:	2781                	sext.w	a5,a5
    8000296e:	079e                	slli	a5,a5,0x7
    80002970:	97ca                	add	a5,a5,s2
    80002972:	0b37a623          	sw	s3,172(a5)
}
    80002976:	70a2                	ld	ra,40(sp)
    80002978:	7402                	ld	s0,32(sp)
    8000297a:	64e2                	ld	s1,24(sp)
    8000297c:	6942                	ld	s2,16(sp)
    8000297e:	69a2                	ld	s3,8(sp)
    80002980:	6145                	addi	sp,sp,48
    80002982:	8082                	ret
    panic("sched p->lock");
    80002984:	00007517          	auipc	a0,0x7
    80002988:	cdc50513          	addi	a0,a0,-804 # 80009660 <digits+0x620>
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	b9e080e7          	jalr	-1122(ra) # 8000052a <panic>
    panic("sched locks");
    80002994:	00007517          	auipc	a0,0x7
    80002998:	cdc50513          	addi	a0,a0,-804 # 80009670 <digits+0x630>
    8000299c:	ffffe097          	auipc	ra,0xffffe
    800029a0:	b8e080e7          	jalr	-1138(ra) # 8000052a <panic>
    panic("sched running");
    800029a4:	00007517          	auipc	a0,0x7
    800029a8:	cdc50513          	addi	a0,a0,-804 # 80009680 <digits+0x640>
    800029ac:	ffffe097          	auipc	ra,0xffffe
    800029b0:	b7e080e7          	jalr	-1154(ra) # 8000052a <panic>
    panic("sched interruptible");
    800029b4:	00007517          	auipc	a0,0x7
    800029b8:	cdc50513          	addi	a0,a0,-804 # 80009690 <digits+0x650>
    800029bc:	ffffe097          	auipc	ra,0xffffe
    800029c0:	b6e080e7          	jalr	-1170(ra) # 8000052a <panic>

00000000800029c4 <yield>:
{
    800029c4:	1101                	addi	sp,sp,-32
    800029c6:	ec06                	sd	ra,24(sp)
    800029c8:	e822                	sd	s0,16(sp)
    800029ca:	e426                	sd	s1,8(sp)
    800029cc:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800029ce:	00000097          	auipc	ra,0x0
    800029d2:	836080e7          	jalr	-1994(ra) # 80002204 <myproc>
    800029d6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800029d8:	ffffe097          	auipc	ra,0xffffe
    800029dc:	1ea080e7          	jalr	490(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    800029e0:	478d                	li	a5,3
    800029e2:	cc9c                	sw	a5,24(s1)
  sched();
    800029e4:	00000097          	auipc	ra,0x0
    800029e8:	f0a080e7          	jalr	-246(ra) # 800028ee <sched>
  release(&p->lock);
    800029ec:	8526                	mv	a0,s1
    800029ee:	ffffe097          	auipc	ra,0xffffe
    800029f2:	288080e7          	jalr	648(ra) # 80000c76 <release>
}
    800029f6:	60e2                	ld	ra,24(sp)
    800029f8:	6442                	ld	s0,16(sp)
    800029fa:	64a2                	ld	s1,8(sp)
    800029fc:	6105                	addi	sp,sp,32
    800029fe:	8082                	ret

0000000080002a00 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002a00:	7179                	addi	sp,sp,-48
    80002a02:	f406                	sd	ra,40(sp)
    80002a04:	f022                	sd	s0,32(sp)
    80002a06:	ec26                	sd	s1,24(sp)
    80002a08:	e84a                	sd	s2,16(sp)
    80002a0a:	e44e                	sd	s3,8(sp)
    80002a0c:	1800                	addi	s0,sp,48
    80002a0e:	89aa                	mv	s3,a0
    80002a10:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a12:	fffff097          	auipc	ra,0xfffff
    80002a16:	7f2080e7          	jalr	2034(ra) # 80002204 <myproc>
    80002a1a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	1a6080e7          	jalr	422(ra) # 80000bc2 <acquire>
  release(lk);
    80002a24:	854a                	mv	a0,s2
    80002a26:	ffffe097          	auipc	ra,0xffffe
    80002a2a:	250080e7          	jalr	592(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    80002a2e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002a32:	4789                	li	a5,2
    80002a34:	cc9c                	sw	a5,24(s1)

  sched();
    80002a36:	00000097          	auipc	ra,0x0
    80002a3a:	eb8080e7          	jalr	-328(ra) # 800028ee <sched>

  // Tidy up.
  p->chan = 0;
    80002a3e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002a42:	8526                	mv	a0,s1
    80002a44:	ffffe097          	auipc	ra,0xffffe
    80002a48:	232080e7          	jalr	562(ra) # 80000c76 <release>
  acquire(lk);
    80002a4c:	854a                	mv	a0,s2
    80002a4e:	ffffe097          	auipc	ra,0xffffe
    80002a52:	174080e7          	jalr	372(ra) # 80000bc2 <acquire>
}
    80002a56:	70a2                	ld	ra,40(sp)
    80002a58:	7402                	ld	s0,32(sp)
    80002a5a:	64e2                	ld	s1,24(sp)
    80002a5c:	6942                	ld	s2,16(sp)
    80002a5e:	69a2                	ld	s3,8(sp)
    80002a60:	6145                	addi	sp,sp,48
    80002a62:	8082                	ret

0000000080002a64 <wait>:
{
    80002a64:	715d                	addi	sp,sp,-80
    80002a66:	e486                	sd	ra,72(sp)
    80002a68:	e0a2                	sd	s0,64(sp)
    80002a6a:	fc26                	sd	s1,56(sp)
    80002a6c:	f84a                	sd	s2,48(sp)
    80002a6e:	f44e                	sd	s3,40(sp)
    80002a70:	f052                	sd	s4,32(sp)
    80002a72:	ec56                	sd	s5,24(sp)
    80002a74:	e85a                	sd	s6,16(sp)
    80002a76:	e45e                	sd	s7,8(sp)
    80002a78:	e062                	sd	s8,0(sp)
    80002a7a:	0880                	addi	s0,sp,80
    80002a7c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002a7e:	fffff097          	auipc	ra,0xfffff
    80002a82:	786080e7          	jalr	1926(ra) # 80002204 <myproc>
    80002a86:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002a88:	00010517          	auipc	a0,0x10
    80002a8c:	83050513          	addi	a0,a0,-2000 # 800122b8 <wait_lock>
    80002a90:	ffffe097          	auipc	ra,0xffffe
    80002a94:	132080e7          	jalr	306(ra) # 80000bc2 <acquire>
    havekids = 0;
    80002a98:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002a9a:	4a15                	li	s4,5
        havekids = 1;
    80002a9c:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002a9e:	0001d997          	auipc	s3,0x1d
    80002aa2:	c3298993          	addi	s3,s3,-974 # 8001f6d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002aa6:	00010c17          	auipc	s8,0x10
    80002aaa:	812c0c13          	addi	s8,s8,-2030 # 800122b8 <wait_lock>
    havekids = 0;
    80002aae:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002ab0:	00011497          	auipc	s1,0x11
    80002ab4:	c2048493          	addi	s1,s1,-992 # 800136d0 <proc>
    80002ab8:	a0bd                	j	80002b26 <wait+0xc2>
          pid = np->pid;
    80002aba:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002abe:	000b0e63          	beqz	s6,80002ada <wait+0x76>
    80002ac2:	4691                	li	a3,4
    80002ac4:	02c48613          	addi	a2,s1,44
    80002ac8:	85da                	mv	a1,s6
    80002aca:	05093503          	ld	a0,80(s2)
    80002ace:	fffff097          	auipc	ra,0xfffff
    80002ad2:	3f6080e7          	jalr	1014(ra) # 80001ec4 <copyout>
    80002ad6:	02054563          	bltz	a0,80002b00 <wait+0x9c>
          freeproc(np);
    80002ada:	8526                	mv	a0,s1
    80002adc:	00000097          	auipc	ra,0x0
    80002ae0:	8e8080e7          	jalr	-1816(ra) # 800023c4 <freeproc>
          release(&np->lock);
    80002ae4:	8526                	mv	a0,s1
    80002ae6:	ffffe097          	auipc	ra,0xffffe
    80002aea:	190080e7          	jalr	400(ra) # 80000c76 <release>
          release(&wait_lock);
    80002aee:	0000f517          	auipc	a0,0xf
    80002af2:	7ca50513          	addi	a0,a0,1994 # 800122b8 <wait_lock>
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	180080e7          	jalr	384(ra) # 80000c76 <release>
          return pid;
    80002afe:	a09d                	j	80002b64 <wait+0x100>
            release(&np->lock);
    80002b00:	8526                	mv	a0,s1
    80002b02:	ffffe097          	auipc	ra,0xffffe
    80002b06:	174080e7          	jalr	372(ra) # 80000c76 <release>
            release(&wait_lock);
    80002b0a:	0000f517          	auipc	a0,0xf
    80002b0e:	7ae50513          	addi	a0,a0,1966 # 800122b8 <wait_lock>
    80002b12:	ffffe097          	auipc	ra,0xffffe
    80002b16:	164080e7          	jalr	356(ra) # 80000c76 <release>
            return -1;
    80002b1a:	59fd                	li	s3,-1
    80002b1c:	a0a1                	j	80002b64 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002b1e:	30048493          	addi	s1,s1,768
    80002b22:	03348463          	beq	s1,s3,80002b4a <wait+0xe6>
      if(np->parent == p){
    80002b26:	7c9c                	ld	a5,56(s1)
    80002b28:	ff279be3          	bne	a5,s2,80002b1e <wait+0xba>
        acquire(&np->lock);
    80002b2c:	8526                	mv	a0,s1
    80002b2e:	ffffe097          	auipc	ra,0xffffe
    80002b32:	094080e7          	jalr	148(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    80002b36:	4c9c                	lw	a5,24(s1)
    80002b38:	f94781e3          	beq	a5,s4,80002aba <wait+0x56>
        release(&np->lock);
    80002b3c:	8526                	mv	a0,s1
    80002b3e:	ffffe097          	auipc	ra,0xffffe
    80002b42:	138080e7          	jalr	312(ra) # 80000c76 <release>
        havekids = 1;
    80002b46:	8756                	mv	a4,s5
    80002b48:	bfd9                	j	80002b1e <wait+0xba>
    if(!havekids || p->killed){
    80002b4a:	c701                	beqz	a4,80002b52 <wait+0xee>
    80002b4c:	02892783          	lw	a5,40(s2)
    80002b50:	c79d                	beqz	a5,80002b7e <wait+0x11a>
      release(&wait_lock);
    80002b52:	0000f517          	auipc	a0,0xf
    80002b56:	76650513          	addi	a0,a0,1894 # 800122b8 <wait_lock>
    80002b5a:	ffffe097          	auipc	ra,0xffffe
    80002b5e:	11c080e7          	jalr	284(ra) # 80000c76 <release>
      return -1;
    80002b62:	59fd                	li	s3,-1
}
    80002b64:	854e                	mv	a0,s3
    80002b66:	60a6                	ld	ra,72(sp)
    80002b68:	6406                	ld	s0,64(sp)
    80002b6a:	74e2                	ld	s1,56(sp)
    80002b6c:	7942                	ld	s2,48(sp)
    80002b6e:	79a2                	ld	s3,40(sp)
    80002b70:	7a02                	ld	s4,32(sp)
    80002b72:	6ae2                	ld	s5,24(sp)
    80002b74:	6b42                	ld	s6,16(sp)
    80002b76:	6ba2                	ld	s7,8(sp)
    80002b78:	6c02                	ld	s8,0(sp)
    80002b7a:	6161                	addi	sp,sp,80
    80002b7c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002b7e:	85e2                	mv	a1,s8
    80002b80:	854a                	mv	a0,s2
    80002b82:	00000097          	auipc	ra,0x0
    80002b86:	e7e080e7          	jalr	-386(ra) # 80002a00 <sleep>
    havekids = 0;
    80002b8a:	b715                	j	80002aae <wait+0x4a>

0000000080002b8c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002b8c:	7139                	addi	sp,sp,-64
    80002b8e:	fc06                	sd	ra,56(sp)
    80002b90:	f822                	sd	s0,48(sp)
    80002b92:	f426                	sd	s1,40(sp)
    80002b94:	f04a                	sd	s2,32(sp)
    80002b96:	ec4e                	sd	s3,24(sp)
    80002b98:	e852                	sd	s4,16(sp)
    80002b9a:	e456                	sd	s5,8(sp)
    80002b9c:	0080                	addi	s0,sp,64
    80002b9e:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002ba0:	00011497          	auipc	s1,0x11
    80002ba4:	b3048493          	addi	s1,s1,-1232 # 800136d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002ba8:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002baa:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002bac:	0001d917          	auipc	s2,0x1d
    80002bb0:	b2490913          	addi	s2,s2,-1244 # 8001f6d0 <tickslock>
    80002bb4:	a811                	j	80002bc8 <wakeup+0x3c>
      }
      release(&p->lock);
    80002bb6:	8526                	mv	a0,s1
    80002bb8:	ffffe097          	auipc	ra,0xffffe
    80002bbc:	0be080e7          	jalr	190(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002bc0:	30048493          	addi	s1,s1,768
    80002bc4:	03248663          	beq	s1,s2,80002bf0 <wakeup+0x64>
    if(p != myproc()){
    80002bc8:	fffff097          	auipc	ra,0xfffff
    80002bcc:	63c080e7          	jalr	1596(ra) # 80002204 <myproc>
    80002bd0:	fea488e3          	beq	s1,a0,80002bc0 <wakeup+0x34>
      acquire(&p->lock);
    80002bd4:	8526                	mv	a0,s1
    80002bd6:	ffffe097          	auipc	ra,0xffffe
    80002bda:	fec080e7          	jalr	-20(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002bde:	4c9c                	lw	a5,24(s1)
    80002be0:	fd379be3          	bne	a5,s3,80002bb6 <wakeup+0x2a>
    80002be4:	709c                	ld	a5,32(s1)
    80002be6:	fd4798e3          	bne	a5,s4,80002bb6 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002bea:	0154ac23          	sw	s5,24(s1)
    80002bee:	b7e1                	j	80002bb6 <wakeup+0x2a>
    }
  }
}
    80002bf0:	70e2                	ld	ra,56(sp)
    80002bf2:	7442                	ld	s0,48(sp)
    80002bf4:	74a2                	ld	s1,40(sp)
    80002bf6:	7902                	ld	s2,32(sp)
    80002bf8:	69e2                	ld	s3,24(sp)
    80002bfa:	6a42                	ld	s4,16(sp)
    80002bfc:	6aa2                	ld	s5,8(sp)
    80002bfe:	6121                	addi	sp,sp,64
    80002c00:	8082                	ret

0000000080002c02 <reparent>:
{
    80002c02:	7179                	addi	sp,sp,-48
    80002c04:	f406                	sd	ra,40(sp)
    80002c06:	f022                	sd	s0,32(sp)
    80002c08:	ec26                	sd	s1,24(sp)
    80002c0a:	e84a                	sd	s2,16(sp)
    80002c0c:	e44e                	sd	s3,8(sp)
    80002c0e:	e052                	sd	s4,0(sp)
    80002c10:	1800                	addi	s0,sp,48
    80002c12:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002c14:	00011497          	auipc	s1,0x11
    80002c18:	abc48493          	addi	s1,s1,-1348 # 800136d0 <proc>
      pp->parent = initproc;
    80002c1c:	00007a17          	auipc	s4,0x7
    80002c20:	40ca0a13          	addi	s4,s4,1036 # 8000a028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002c24:	0001d997          	auipc	s3,0x1d
    80002c28:	aac98993          	addi	s3,s3,-1364 # 8001f6d0 <tickslock>
    80002c2c:	a029                	j	80002c36 <reparent+0x34>
    80002c2e:	30048493          	addi	s1,s1,768
    80002c32:	01348d63          	beq	s1,s3,80002c4c <reparent+0x4a>
    if(pp->parent == p){
    80002c36:	7c9c                	ld	a5,56(s1)
    80002c38:	ff279be3          	bne	a5,s2,80002c2e <reparent+0x2c>
      pp->parent = initproc;
    80002c3c:	000a3503          	ld	a0,0(s4)
    80002c40:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002c42:	00000097          	auipc	ra,0x0
    80002c46:	f4a080e7          	jalr	-182(ra) # 80002b8c <wakeup>
    80002c4a:	b7d5                	j	80002c2e <reparent+0x2c>
}
    80002c4c:	70a2                	ld	ra,40(sp)
    80002c4e:	7402                	ld	s0,32(sp)
    80002c50:	64e2                	ld	s1,24(sp)
    80002c52:	6942                	ld	s2,16(sp)
    80002c54:	69a2                	ld	s3,8(sp)
    80002c56:	6a02                	ld	s4,0(sp)
    80002c58:	6145                	addi	sp,sp,48
    80002c5a:	8082                	ret

0000000080002c5c <exit>:
{
    80002c5c:	7179                	addi	sp,sp,-48
    80002c5e:	f406                	sd	ra,40(sp)
    80002c60:	f022                	sd	s0,32(sp)
    80002c62:	ec26                	sd	s1,24(sp)
    80002c64:	e84a                	sd	s2,16(sp)
    80002c66:	e44e                	sd	s3,8(sp)
    80002c68:	e052                	sd	s4,0(sp)
    80002c6a:	1800                	addi	s0,sp,48
    80002c6c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002c6e:	fffff097          	auipc	ra,0xfffff
    80002c72:	596080e7          	jalr	1430(ra) # 80002204 <myproc>
    80002c76:	89aa                	mv	s3,a0
  if(p == initproc)
    80002c78:	00007797          	auipc	a5,0x7
    80002c7c:	3b07b783          	ld	a5,944(a5) # 8000a028 <initproc>
    80002c80:	0d050493          	addi	s1,a0,208
    80002c84:	15050913          	addi	s2,a0,336
    80002c88:	02a79363          	bne	a5,a0,80002cae <exit+0x52>
    panic("init exiting");
    80002c8c:	00007517          	auipc	a0,0x7
    80002c90:	a1c50513          	addi	a0,a0,-1508 # 800096a8 <digits+0x668>
    80002c94:	ffffe097          	auipc	ra,0xffffe
    80002c98:	896080e7          	jalr	-1898(ra) # 8000052a <panic>
      fileclose(f);
    80002c9c:	00002097          	auipc	ra,0x2
    80002ca0:	4ca080e7          	jalr	1226(ra) # 80005166 <fileclose>
      p->ofile[fd] = 0;
    80002ca4:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002ca8:	04a1                	addi	s1,s1,8
    80002caa:	01248563          	beq	s1,s2,80002cb4 <exit+0x58>
    if(p->ofile[fd]){
    80002cae:	6088                	ld	a0,0(s1)
    80002cb0:	f575                	bnez	a0,80002c9c <exit+0x40>
    80002cb2:	bfdd                	j	80002ca8 <exit+0x4c>
  begin_op();
    80002cb4:	00002097          	auipc	ra,0x2
    80002cb8:	fe6080e7          	jalr	-26(ra) # 80004c9a <begin_op>
  iput(p->cwd);
    80002cbc:	1509b503          	ld	a0,336(s3)
    80002cc0:	00001097          	auipc	ra,0x1
    80002cc4:	4ac080e7          	jalr	1196(ra) # 8000416c <iput>
  end_op();
    80002cc8:	00002097          	auipc	ra,0x2
    80002ccc:	052080e7          	jalr	82(ra) # 80004d1a <end_op>
  p->cwd = 0;
    80002cd0:	1409b823          	sd	zero,336(s3)
  if(p->pid > 2) {  //task 1.1
    80002cd4:	0309a703          	lw	a4,48(s3)
    80002cd8:	4789                	li	a5,2
    80002cda:	06e7c163          	blt	a5,a4,80002d3c <exit+0xe0>
  acquire(&wait_lock);
    80002cde:	0000f497          	auipc	s1,0xf
    80002ce2:	5da48493          	addi	s1,s1,1498 # 800122b8 <wait_lock>
    80002ce6:	8526                	mv	a0,s1
    80002ce8:	ffffe097          	auipc	ra,0xffffe
    80002cec:	eda080e7          	jalr	-294(ra) # 80000bc2 <acquire>
  reparent(p);
    80002cf0:	854e                	mv	a0,s3
    80002cf2:	00000097          	auipc	ra,0x0
    80002cf6:	f10080e7          	jalr	-240(ra) # 80002c02 <reparent>
  wakeup(p->parent);
    80002cfa:	0389b503          	ld	a0,56(s3)
    80002cfe:	00000097          	auipc	ra,0x0
    80002d02:	e8e080e7          	jalr	-370(ra) # 80002b8c <wakeup>
  acquire(&p->lock);
    80002d06:	854e                	mv	a0,s3
    80002d08:	ffffe097          	auipc	ra,0xffffe
    80002d0c:	eba080e7          	jalr	-326(ra) # 80000bc2 <acquire>
  p->xstate = status;
    80002d10:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002d14:	4795                	li	a5,5
    80002d16:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002d1a:	8526                	mv	a0,s1
    80002d1c:	ffffe097          	auipc	ra,0xffffe
    80002d20:	f5a080e7          	jalr	-166(ra) # 80000c76 <release>
  sched();
    80002d24:	00000097          	auipc	ra,0x0
    80002d28:	bca080e7          	jalr	-1078(ra) # 800028ee <sched>
  panic("zombie exit");
    80002d2c:	00007517          	auipc	a0,0x7
    80002d30:	98c50513          	addi	a0,a0,-1652 # 800096b8 <digits+0x678>
    80002d34:	ffffd097          	auipc	ra,0xffffd
    80002d38:	7f6080e7          	jalr	2038(ra) # 8000052a <panic>
    removeSwapFile(p);
    80002d3c:	854e                	mv	a0,s3
    80002d3e:	00002097          	auipc	ra,0x2
    80002d42:	ad6080e7          	jalr	-1322(ra) # 80004814 <removeSwapFile>
    80002d46:	bf61                	j	80002cde <exit+0x82>

0000000080002d48 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002d48:	7179                	addi	sp,sp,-48
    80002d4a:	f406                	sd	ra,40(sp)
    80002d4c:	f022                	sd	s0,32(sp)
    80002d4e:	ec26                	sd	s1,24(sp)
    80002d50:	e84a                	sd	s2,16(sp)
    80002d52:	e44e                	sd	s3,8(sp)
    80002d54:	1800                	addi	s0,sp,48
    80002d56:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002d58:	00011497          	auipc	s1,0x11
    80002d5c:	97848493          	addi	s1,s1,-1672 # 800136d0 <proc>
    80002d60:	0001d997          	auipc	s3,0x1d
    80002d64:	97098993          	addi	s3,s3,-1680 # 8001f6d0 <tickslock>
    acquire(&p->lock);
    80002d68:	8526                	mv	a0,s1
    80002d6a:	ffffe097          	auipc	ra,0xffffe
    80002d6e:	e58080e7          	jalr	-424(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    80002d72:	589c                	lw	a5,48(s1)
    80002d74:	01278d63          	beq	a5,s2,80002d8e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002d78:	8526                	mv	a0,s1
    80002d7a:	ffffe097          	auipc	ra,0xffffe
    80002d7e:	efc080e7          	jalr	-260(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002d82:	30048493          	addi	s1,s1,768
    80002d86:	ff3491e3          	bne	s1,s3,80002d68 <kill+0x20>
  }
  return -1;
    80002d8a:	557d                	li	a0,-1
    80002d8c:	a829                	j	80002da6 <kill+0x5e>
      p->killed = 1;
    80002d8e:	4785                	li	a5,1
    80002d90:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002d92:	4c98                	lw	a4,24(s1)
    80002d94:	4789                	li	a5,2
    80002d96:	00f70f63          	beq	a4,a5,80002db4 <kill+0x6c>
      release(&p->lock);
    80002d9a:	8526                	mv	a0,s1
    80002d9c:	ffffe097          	auipc	ra,0xffffe
    80002da0:	eda080e7          	jalr	-294(ra) # 80000c76 <release>
      return 0;
    80002da4:	4501                	li	a0,0
}
    80002da6:	70a2                	ld	ra,40(sp)
    80002da8:	7402                	ld	s0,32(sp)
    80002daa:	64e2                	ld	s1,24(sp)
    80002dac:	6942                	ld	s2,16(sp)
    80002dae:	69a2                	ld	s3,8(sp)
    80002db0:	6145                	addi	sp,sp,48
    80002db2:	8082                	ret
        p->state = RUNNABLE;
    80002db4:	478d                	li	a5,3
    80002db6:	cc9c                	sw	a5,24(s1)
    80002db8:	b7cd                	j	80002d9a <kill+0x52>

0000000080002dba <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002dba:	7179                	addi	sp,sp,-48
    80002dbc:	f406                	sd	ra,40(sp)
    80002dbe:	f022                	sd	s0,32(sp)
    80002dc0:	ec26                	sd	s1,24(sp)
    80002dc2:	e84a                	sd	s2,16(sp)
    80002dc4:	e44e                	sd	s3,8(sp)
    80002dc6:	e052                	sd	s4,0(sp)
    80002dc8:	1800                	addi	s0,sp,48
    80002dca:	84aa                	mv	s1,a0
    80002dcc:	892e                	mv	s2,a1
    80002dce:	89b2                	mv	s3,a2
    80002dd0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002dd2:	fffff097          	auipc	ra,0xfffff
    80002dd6:	432080e7          	jalr	1074(ra) # 80002204 <myproc>
  if(user_dst){
    80002dda:	c08d                	beqz	s1,80002dfc <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002ddc:	86d2                	mv	a3,s4
    80002dde:	864e                	mv	a2,s3
    80002de0:	85ca                	mv	a1,s2
    80002de2:	6928                	ld	a0,80(a0)
    80002de4:	fffff097          	auipc	ra,0xfffff
    80002de8:	0e0080e7          	jalr	224(ra) # 80001ec4 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002dec:	70a2                	ld	ra,40(sp)
    80002dee:	7402                	ld	s0,32(sp)
    80002df0:	64e2                	ld	s1,24(sp)
    80002df2:	6942                	ld	s2,16(sp)
    80002df4:	69a2                	ld	s3,8(sp)
    80002df6:	6a02                	ld	s4,0(sp)
    80002df8:	6145                	addi	sp,sp,48
    80002dfa:	8082                	ret
    memmove((char *)dst, src, len);
    80002dfc:	000a061b          	sext.w	a2,s4
    80002e00:	85ce                	mv	a1,s3
    80002e02:	854a                	mv	a0,s2
    80002e04:	ffffe097          	auipc	ra,0xffffe
    80002e08:	f16080e7          	jalr	-234(ra) # 80000d1a <memmove>
    return 0;
    80002e0c:	8526                	mv	a0,s1
    80002e0e:	bff9                	j	80002dec <either_copyout+0x32>

0000000080002e10 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002e10:	7179                	addi	sp,sp,-48
    80002e12:	f406                	sd	ra,40(sp)
    80002e14:	f022                	sd	s0,32(sp)
    80002e16:	ec26                	sd	s1,24(sp)
    80002e18:	e84a                	sd	s2,16(sp)
    80002e1a:	e44e                	sd	s3,8(sp)
    80002e1c:	e052                	sd	s4,0(sp)
    80002e1e:	1800                	addi	s0,sp,48
    80002e20:	892a                	mv	s2,a0
    80002e22:	84ae                	mv	s1,a1
    80002e24:	89b2                	mv	s3,a2
    80002e26:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002e28:	fffff097          	auipc	ra,0xfffff
    80002e2c:	3dc080e7          	jalr	988(ra) # 80002204 <myproc>
  if(user_src){
    80002e30:	c08d                	beqz	s1,80002e52 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002e32:	86d2                	mv	a3,s4
    80002e34:	864e                	mv	a2,s3
    80002e36:	85ca                	mv	a1,s2
    80002e38:	6928                	ld	a0,80(a0)
    80002e3a:	fffff097          	auipc	ra,0xfffff
    80002e3e:	116080e7          	jalr	278(ra) # 80001f50 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002e42:	70a2                	ld	ra,40(sp)
    80002e44:	7402                	ld	s0,32(sp)
    80002e46:	64e2                	ld	s1,24(sp)
    80002e48:	6942                	ld	s2,16(sp)
    80002e4a:	69a2                	ld	s3,8(sp)
    80002e4c:	6a02                	ld	s4,0(sp)
    80002e4e:	6145                	addi	sp,sp,48
    80002e50:	8082                	ret
    memmove(dst, (char*)src, len);
    80002e52:	000a061b          	sext.w	a2,s4
    80002e56:	85ce                	mv	a1,s3
    80002e58:	854a                	mv	a0,s2
    80002e5a:	ffffe097          	auipc	ra,0xffffe
    80002e5e:	ec0080e7          	jalr	-320(ra) # 80000d1a <memmove>
    return 0;
    80002e62:	8526                	mv	a0,s1
    80002e64:	bff9                	j	80002e42 <either_copyin+0x32>

0000000080002e66 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002e66:	715d                	addi	sp,sp,-80
    80002e68:	e486                	sd	ra,72(sp)
    80002e6a:	e0a2                	sd	s0,64(sp)
    80002e6c:	fc26                	sd	s1,56(sp)
    80002e6e:	f84a                	sd	s2,48(sp)
    80002e70:	f44e                	sd	s3,40(sp)
    80002e72:	f052                	sd	s4,32(sp)
    80002e74:	ec56                	sd	s5,24(sp)
    80002e76:	e85a                	sd	s6,16(sp)
    80002e78:	e45e                	sd	s7,8(sp)
    80002e7a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002e7c:	00006517          	auipc	a0,0x6
    80002e80:	55c50513          	addi	a0,a0,1372 # 800093d8 <digits+0x398>
    80002e84:	ffffd097          	auipc	ra,0xffffd
    80002e88:	6f0080e7          	jalr	1776(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002e8c:	00011497          	auipc	s1,0x11
    80002e90:	99c48493          	addi	s1,s1,-1636 # 80013828 <proc+0x158>
    80002e94:	0001d917          	auipc	s2,0x1d
    80002e98:	99490913          	addi	s2,s2,-1644 # 8001f828 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002e9c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002e9e:	00007997          	auipc	s3,0x7
    80002ea2:	82a98993          	addi	s3,s3,-2006 # 800096c8 <digits+0x688>
    printf("%d %s %s", p->pid, state, p->name);
    80002ea6:	00007a97          	auipc	s5,0x7
    80002eaa:	82aa8a93          	addi	s5,s5,-2006 # 800096d0 <digits+0x690>
    printf("\n");
    80002eae:	00006a17          	auipc	s4,0x6
    80002eb2:	52aa0a13          	addi	s4,s4,1322 # 800093d8 <digits+0x398>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002eb6:	00007b97          	auipc	s7,0x7
    80002eba:	852b8b93          	addi	s7,s7,-1966 # 80009708 <states.0>
    80002ebe:	a00d                	j	80002ee0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002ec0:	ed86a583          	lw	a1,-296(a3) # ed8 <_entry-0x7ffff128>
    80002ec4:	8556                	mv	a0,s5
    80002ec6:	ffffd097          	auipc	ra,0xffffd
    80002eca:	6ae080e7          	jalr	1710(ra) # 80000574 <printf>
    printf("\n");
    80002ece:	8552                	mv	a0,s4
    80002ed0:	ffffd097          	auipc	ra,0xffffd
    80002ed4:	6a4080e7          	jalr	1700(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ed8:	30048493          	addi	s1,s1,768
    80002edc:	03248263          	beq	s1,s2,80002f00 <procdump+0x9a>
    if(p->state == UNUSED)
    80002ee0:	86a6                	mv	a3,s1
    80002ee2:	ec04a783          	lw	a5,-320(s1)
    80002ee6:	dbed                	beqz	a5,80002ed8 <procdump+0x72>
      state = "???";
    80002ee8:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002eea:	fcfb6be3          	bltu	s6,a5,80002ec0 <procdump+0x5a>
    80002eee:	02079713          	slli	a4,a5,0x20
    80002ef2:	01d75793          	srli	a5,a4,0x1d
    80002ef6:	97de                	add	a5,a5,s7
    80002ef8:	6390                	ld	a2,0(a5)
    80002efa:	f279                	bnez	a2,80002ec0 <procdump+0x5a>
      state = "???";
    80002efc:	864e                	mv	a2,s3
    80002efe:	b7c9                	j	80002ec0 <procdump+0x5a>
  }
}
    80002f00:	60a6                	ld	ra,72(sp)
    80002f02:	6406                	ld	s0,64(sp)
    80002f04:	74e2                	ld	s1,56(sp)
    80002f06:	7942                	ld	s2,48(sp)
    80002f08:	79a2                	ld	s3,40(sp)
    80002f0a:	7a02                	ld	s4,32(sp)
    80002f0c:	6ae2                	ld	s5,24(sp)
    80002f0e:	6b42                	ld	s6,16(sp)
    80002f10:	6ba2                	ld	s7,8(sp)
    80002f12:	6161                	addi	sp,sp,80
    80002f14:	8082                	ret

0000000080002f16 <swtch>:
    80002f16:	00153023          	sd	ra,0(a0)
    80002f1a:	00253423          	sd	sp,8(a0)
    80002f1e:	e900                	sd	s0,16(a0)
    80002f20:	ed04                	sd	s1,24(a0)
    80002f22:	03253023          	sd	s2,32(a0)
    80002f26:	03353423          	sd	s3,40(a0)
    80002f2a:	03453823          	sd	s4,48(a0)
    80002f2e:	03553c23          	sd	s5,56(a0)
    80002f32:	05653023          	sd	s6,64(a0)
    80002f36:	05753423          	sd	s7,72(a0)
    80002f3a:	05853823          	sd	s8,80(a0)
    80002f3e:	05953c23          	sd	s9,88(a0)
    80002f42:	07a53023          	sd	s10,96(a0)
    80002f46:	07b53423          	sd	s11,104(a0)
    80002f4a:	0005b083          	ld	ra,0(a1)
    80002f4e:	0085b103          	ld	sp,8(a1)
    80002f52:	6980                	ld	s0,16(a1)
    80002f54:	6d84                	ld	s1,24(a1)
    80002f56:	0205b903          	ld	s2,32(a1)
    80002f5a:	0285b983          	ld	s3,40(a1)
    80002f5e:	0305ba03          	ld	s4,48(a1)
    80002f62:	0385ba83          	ld	s5,56(a1)
    80002f66:	0405bb03          	ld	s6,64(a1)
    80002f6a:	0485bb83          	ld	s7,72(a1)
    80002f6e:	0505bc03          	ld	s8,80(a1)
    80002f72:	0585bc83          	ld	s9,88(a1)
    80002f76:	0605bd03          	ld	s10,96(a1)
    80002f7a:	0685bd83          	ld	s11,104(a1)
    80002f7e:	8082                	ret

0000000080002f80 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002f80:	1141                	addi	sp,sp,-16
    80002f82:	e406                	sd	ra,8(sp)
    80002f84:	e022                	sd	s0,0(sp)
    80002f86:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002f88:	00006597          	auipc	a1,0x6
    80002f8c:	7b058593          	addi	a1,a1,1968 # 80009738 <states.0+0x30>
    80002f90:	0001c517          	auipc	a0,0x1c
    80002f94:	74050513          	addi	a0,a0,1856 # 8001f6d0 <tickslock>
    80002f98:	ffffe097          	auipc	ra,0xffffe
    80002f9c:	b9a080e7          	jalr	-1126(ra) # 80000b32 <initlock>
}
    80002fa0:	60a2                	ld	ra,8(sp)
    80002fa2:	6402                	ld	s0,0(sp)
    80002fa4:	0141                	addi	sp,sp,16
    80002fa6:	8082                	ret

0000000080002fa8 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002fa8:	1141                	addi	sp,sp,-16
    80002faa:	e422                	sd	s0,8(sp)
    80002fac:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002fae:	00004797          	auipc	a5,0x4
    80002fb2:	a4278793          	addi	a5,a5,-1470 # 800069f0 <kernelvec>
    80002fb6:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002fba:	6422                	ld	s0,8(sp)
    80002fbc:	0141                	addi	sp,sp,16
    80002fbe:	8082                	ret

0000000080002fc0 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002fc0:	1141                	addi	sp,sp,-16
    80002fc2:	e406                	sd	ra,8(sp)
    80002fc4:	e022                	sd	s0,0(sp)
    80002fc6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002fc8:	fffff097          	auipc	ra,0xfffff
    80002fcc:	23c080e7          	jalr	572(ra) # 80002204 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fd0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002fd4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fd6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002fda:	00005617          	auipc	a2,0x5
    80002fde:	02660613          	addi	a2,a2,38 # 80008000 <_trampoline>
    80002fe2:	00005697          	auipc	a3,0x5
    80002fe6:	01e68693          	addi	a3,a3,30 # 80008000 <_trampoline>
    80002fea:	8e91                	sub	a3,a3,a2
    80002fec:	040007b7          	lui	a5,0x4000
    80002ff0:	17fd                	addi	a5,a5,-1
    80002ff2:	07b2                	slli	a5,a5,0xc
    80002ff4:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ff6:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ffa:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002ffc:	180026f3          	csrr	a3,satp
    80003000:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80003002:	6d38                	ld	a4,88(a0)
    80003004:	6134                	ld	a3,64(a0)
    80003006:	6585                	lui	a1,0x1
    80003008:	96ae                	add	a3,a3,a1
    8000300a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000300c:	6d38                	ld	a4,88(a0)
    8000300e:	00000697          	auipc	a3,0x0
    80003012:	13868693          	addi	a3,a3,312 # 80003146 <usertrap>
    80003016:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80003018:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000301a:	8692                	mv	a3,tp
    8000301c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000301e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80003022:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80003026:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000302a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000302e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003030:	6f18                	ld	a4,24(a4)
    80003032:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80003036:	692c                	ld	a1,80(a0)
    80003038:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000303a:	00005717          	auipc	a4,0x5
    8000303e:	05670713          	addi	a4,a4,86 # 80008090 <userret>
    80003042:	8f11                	sub	a4,a4,a2
    80003044:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80003046:	577d                	li	a4,-1
    80003048:	177e                	slli	a4,a4,0x3f
    8000304a:	8dd9                	or	a1,a1,a4
    8000304c:	02000537          	lui	a0,0x2000
    80003050:	157d                	addi	a0,a0,-1
    80003052:	0536                	slli	a0,a0,0xd
    80003054:	9782                	jalr	a5
}
    80003056:	60a2                	ld	ra,8(sp)
    80003058:	6402                	ld	s0,0(sp)
    8000305a:	0141                	addi	sp,sp,16
    8000305c:	8082                	ret

000000008000305e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000305e:	1101                	addi	sp,sp,-32
    80003060:	ec06                	sd	ra,24(sp)
    80003062:	e822                	sd	s0,16(sp)
    80003064:	e426                	sd	s1,8(sp)
    80003066:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003068:	0001c497          	auipc	s1,0x1c
    8000306c:	66848493          	addi	s1,s1,1640 # 8001f6d0 <tickslock>
    80003070:	8526                	mv	a0,s1
    80003072:	ffffe097          	auipc	ra,0xffffe
    80003076:	b50080e7          	jalr	-1200(ra) # 80000bc2 <acquire>
  ticks++;
    8000307a:	00007517          	auipc	a0,0x7
    8000307e:	fb650513          	addi	a0,a0,-74 # 8000a030 <ticks>
    80003082:	411c                	lw	a5,0(a0)
    80003084:	2785                	addiw	a5,a5,1
    80003086:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80003088:	00000097          	auipc	ra,0x0
    8000308c:	b04080e7          	jalr	-1276(ra) # 80002b8c <wakeup>
  release(&tickslock);
    80003090:	8526                	mv	a0,s1
    80003092:	ffffe097          	auipc	ra,0xffffe
    80003096:	be4080e7          	jalr	-1052(ra) # 80000c76 <release>
}
    8000309a:	60e2                	ld	ra,24(sp)
    8000309c:	6442                	ld	s0,16(sp)
    8000309e:	64a2                	ld	s1,8(sp)
    800030a0:	6105                	addi	sp,sp,32
    800030a2:	8082                	ret

00000000800030a4 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800030a4:	1101                	addi	sp,sp,-32
    800030a6:	ec06                	sd	ra,24(sp)
    800030a8:	e822                	sd	s0,16(sp)
    800030aa:	e426                	sd	s1,8(sp)
    800030ac:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030ae:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800030b2:	00074d63          	bltz	a4,800030cc <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800030b6:	57fd                	li	a5,-1
    800030b8:	17fe                	slli	a5,a5,0x3f
    800030ba:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800030bc:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800030be:	06f70363          	beq	a4,a5,80003124 <devintr+0x80>
  }
}
    800030c2:	60e2                	ld	ra,24(sp)
    800030c4:	6442                	ld	s0,16(sp)
    800030c6:	64a2                	ld	s1,8(sp)
    800030c8:	6105                	addi	sp,sp,32
    800030ca:	8082                	ret
     (scause & 0xff) == 9){
    800030cc:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800030d0:	46a5                	li	a3,9
    800030d2:	fed792e3          	bne	a5,a3,800030b6 <devintr+0x12>
    int irq = plic_claim();
    800030d6:	00004097          	auipc	ra,0x4
    800030da:	a22080e7          	jalr	-1502(ra) # 80006af8 <plic_claim>
    800030de:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800030e0:	47a9                	li	a5,10
    800030e2:	02f50763          	beq	a0,a5,80003110 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800030e6:	4785                	li	a5,1
    800030e8:	02f50963          	beq	a0,a5,8000311a <devintr+0x76>
    return 1;
    800030ec:	4505                	li	a0,1
    } else if(irq){
    800030ee:	d8f1                	beqz	s1,800030c2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800030f0:	85a6                	mv	a1,s1
    800030f2:	00006517          	auipc	a0,0x6
    800030f6:	64e50513          	addi	a0,a0,1614 # 80009740 <states.0+0x38>
    800030fa:	ffffd097          	auipc	ra,0xffffd
    800030fe:	47a080e7          	jalr	1146(ra) # 80000574 <printf>
      plic_complete(irq);
    80003102:	8526                	mv	a0,s1
    80003104:	00004097          	auipc	ra,0x4
    80003108:	a18080e7          	jalr	-1512(ra) # 80006b1c <plic_complete>
    return 1;
    8000310c:	4505                	li	a0,1
    8000310e:	bf55                	j	800030c2 <devintr+0x1e>
      uartintr();
    80003110:	ffffe097          	auipc	ra,0xffffe
    80003114:	876080e7          	jalr	-1930(ra) # 80000986 <uartintr>
    80003118:	b7ed                	j	80003102 <devintr+0x5e>
      virtio_disk_intr();
    8000311a:	00004097          	auipc	ra,0x4
    8000311e:	e94080e7          	jalr	-364(ra) # 80006fae <virtio_disk_intr>
    80003122:	b7c5                	j	80003102 <devintr+0x5e>
    if(cpuid() == 0){
    80003124:	fffff097          	auipc	ra,0xfffff
    80003128:	0b4080e7          	jalr	180(ra) # 800021d8 <cpuid>
    8000312c:	c901                	beqz	a0,8000313c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000312e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003132:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003134:	14479073          	csrw	sip,a5
    return 2;
    80003138:	4509                	li	a0,2
    8000313a:	b761                	j	800030c2 <devintr+0x1e>
      clockintr();
    8000313c:	00000097          	auipc	ra,0x0
    80003140:	f22080e7          	jalr	-222(ra) # 8000305e <clockintr>
    80003144:	b7ed                	j	8000312e <devintr+0x8a>

0000000080003146 <usertrap>:
{
    80003146:	1101                	addi	sp,sp,-32
    80003148:	ec06                	sd	ra,24(sp)
    8000314a:	e822                	sd	s0,16(sp)
    8000314c:	e426                	sd	s1,8(sp)
    8000314e:	e04a                	sd	s2,0(sp)
    80003150:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003152:	14302973          	csrr	s2,stval
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003156:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000315a:	1007f793          	andi	a5,a5,256
    8000315e:	e7ad                	bnez	a5,800031c8 <usertrap+0x82>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003160:	00004797          	auipc	a5,0x4
    80003164:	89078793          	addi	a5,a5,-1904 # 800069f0 <kernelvec>
    80003168:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000316c:	fffff097          	auipc	ra,0xfffff
    80003170:	098080e7          	jalr	152(ra) # 80002204 <myproc>
    80003174:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003176:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003178:	14102773          	csrr	a4,sepc
    8000317c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000317e:	14202773          	csrr	a4,scause
  if(r_scause() == 13 || r_scause() == 15|| r_scause() == 12){
    80003182:	47b5                	li	a5,13
    80003184:	04f70a63          	beq	a4,a5,800031d8 <usertrap+0x92>
    80003188:	14202773          	csrr	a4,scause
    8000318c:	47bd                	li	a5,15
    8000318e:	04f70563          	beq	a4,a5,800031d8 <usertrap+0x92>
    80003192:	14202773          	csrr	a4,scause
    80003196:	47b1                	li	a5,12
    80003198:	04f70063          	beq	a4,a5,800031d8 <usertrap+0x92>
    8000319c:	14202773          	csrr	a4,scause
  else if(r_scause() == 8){
    800031a0:	47a1                	li	a5,8
    800031a2:	06f71763          	bne	a4,a5,80003210 <usertrap+0xca>
    if(p->killed)
    800031a6:	551c                	lw	a5,40(a0)
    800031a8:	efb1                	bnez	a5,80003204 <usertrap+0xbe>
    p->trapframe->epc += 4;
    800031aa:	6cb8                	ld	a4,88(s1)
    800031ac:	6f1c                	ld	a5,24(a4)
    800031ae:	0791                	addi	a5,a5,4
    800031b0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031b2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800031b6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031ba:	10079073          	csrw	sstatus,a5
    syscall();
    800031be:	00000097          	auipc	ra,0x0
    800031c2:	2f6080e7          	jalr	758(ra) # 800034b4 <syscall>
    800031c6:	a829                	j	800031e0 <usertrap+0x9a>
  panic("usertrap: not from user mode");
    800031c8:	00006517          	auipc	a0,0x6
    800031cc:	59850513          	addi	a0,a0,1432 # 80009760 <states.0+0x58>
    800031d0:	ffffd097          	auipc	ra,0xffffd
    800031d4:	35a080e7          	jalr	858(ra) # 8000052a <panic>
    if(p->pid>2)
    800031d8:	5898                	lw	a4,48(s1)
    800031da:	4789                	li	a5,2
    800031dc:	00e7ce63          	blt	a5,a4,800031f8 <usertrap+0xb2>
  if(p->killed)
    800031e0:	549c                	lw	a5,40(s1)
    800031e2:	ebb5                	bnez	a5,80003256 <usertrap+0x110>
  usertrapret();
    800031e4:	00000097          	auipc	ra,0x0
    800031e8:	ddc080e7          	jalr	-548(ra) # 80002fc0 <usertrapret>
}
    800031ec:	60e2                	ld	ra,24(sp)
    800031ee:	6442                	ld	s0,16(sp)
    800031f0:	64a2                	ld	s1,8(sp)
    800031f2:	6902                	ld	s2,0(sp)
    800031f4:	6105                	addi	sp,sp,32
    800031f6:	8082                	ret
      handle_page_fault(va); 
    800031f8:	854a                	mv	a0,s2
    800031fa:	ffffe097          	auipc	ra,0xffffe
    800031fe:	6d8080e7          	jalr	1752(ra) # 800018d2 <handle_page_fault>
    80003202:	bff9                	j	800031e0 <usertrap+0x9a>
      exit(-1);
    80003204:	557d                	li	a0,-1
    80003206:	00000097          	auipc	ra,0x0
    8000320a:	a56080e7          	jalr	-1450(ra) # 80002c5c <exit>
    8000320e:	bf71                	j	800031aa <usertrap+0x64>
  else if((which_dev = devintr()) != 0){
    80003210:	00000097          	auipc	ra,0x0
    80003214:	e94080e7          	jalr	-364(ra) # 800030a4 <devintr>
    80003218:	892a                	mv	s2,a0
    8000321a:	c501                	beqz	a0,80003222 <usertrap+0xdc>
  if(p->killed)
    8000321c:	549c                	lw	a5,40(s1)
    8000321e:	c3b1                	beqz	a5,80003262 <usertrap+0x11c>
    80003220:	a825                	j	80003258 <usertrap+0x112>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003222:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003226:	5890                	lw	a2,48(s1)
    80003228:	00006517          	auipc	a0,0x6
    8000322c:	55850513          	addi	a0,a0,1368 # 80009780 <states.0+0x78>
    80003230:	ffffd097          	auipc	ra,0xffffd
    80003234:	344080e7          	jalr	836(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003238:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000323c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003240:	00006517          	auipc	a0,0x6
    80003244:	57050513          	addi	a0,a0,1392 # 800097b0 <states.0+0xa8>
    80003248:	ffffd097          	auipc	ra,0xffffd
    8000324c:	32c080e7          	jalr	812(ra) # 80000574 <printf>
    p->killed = 1;
    80003250:	4785                	li	a5,1
    80003252:	d49c                	sw	a5,40(s1)
  if(p->killed)
    80003254:	a011                	j	80003258 <usertrap+0x112>
    80003256:	4901                	li	s2,0
    exit(-1);
    80003258:	557d                	li	a0,-1
    8000325a:	00000097          	auipc	ra,0x0
    8000325e:	a02080e7          	jalr	-1534(ra) # 80002c5c <exit>
  if(which_dev == 2)
    80003262:	4789                	li	a5,2
    80003264:	f8f910e3          	bne	s2,a5,800031e4 <usertrap+0x9e>
    yield();
    80003268:	fffff097          	auipc	ra,0xfffff
    8000326c:	75c080e7          	jalr	1884(ra) # 800029c4 <yield>
    80003270:	bf95                	j	800031e4 <usertrap+0x9e>

0000000080003272 <kerneltrap>:
{
    80003272:	7179                	addi	sp,sp,-48
    80003274:	f406                	sd	ra,40(sp)
    80003276:	f022                	sd	s0,32(sp)
    80003278:	ec26                	sd	s1,24(sp)
    8000327a:	e84a                	sd	s2,16(sp)
    8000327c:	e44e                	sd	s3,8(sp)
    8000327e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003280:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003284:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003288:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000328c:	1004f793          	andi	a5,s1,256
    80003290:	cb85                	beqz	a5,800032c0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003292:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003296:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003298:	ef85                	bnez	a5,800032d0 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000329a:	00000097          	auipc	ra,0x0
    8000329e:	e0a080e7          	jalr	-502(ra) # 800030a4 <devintr>
    800032a2:	cd1d                	beqz	a0,800032e0 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800032a4:	4789                	li	a5,2
    800032a6:	06f50a63          	beq	a0,a5,8000331a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800032aa:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800032ae:	10049073          	csrw	sstatus,s1
}
    800032b2:	70a2                	ld	ra,40(sp)
    800032b4:	7402                	ld	s0,32(sp)
    800032b6:	64e2                	ld	s1,24(sp)
    800032b8:	6942                	ld	s2,16(sp)
    800032ba:	69a2                	ld	s3,8(sp)
    800032bc:	6145                	addi	sp,sp,48
    800032be:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800032c0:	00006517          	auipc	a0,0x6
    800032c4:	51050513          	addi	a0,a0,1296 # 800097d0 <states.0+0xc8>
    800032c8:	ffffd097          	auipc	ra,0xffffd
    800032cc:	262080e7          	jalr	610(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    800032d0:	00006517          	auipc	a0,0x6
    800032d4:	52850513          	addi	a0,a0,1320 # 800097f8 <states.0+0xf0>
    800032d8:	ffffd097          	auipc	ra,0xffffd
    800032dc:	252080e7          	jalr	594(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    800032e0:	85ce                	mv	a1,s3
    800032e2:	00006517          	auipc	a0,0x6
    800032e6:	53650513          	addi	a0,a0,1334 # 80009818 <states.0+0x110>
    800032ea:	ffffd097          	auipc	ra,0xffffd
    800032ee:	28a080e7          	jalr	650(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800032f2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800032f6:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800032fa:	00006517          	auipc	a0,0x6
    800032fe:	52e50513          	addi	a0,a0,1326 # 80009828 <states.0+0x120>
    80003302:	ffffd097          	auipc	ra,0xffffd
    80003306:	272080e7          	jalr	626(ra) # 80000574 <printf>
    panic("kerneltrap");
    8000330a:	00006517          	auipc	a0,0x6
    8000330e:	53650513          	addi	a0,a0,1334 # 80009840 <states.0+0x138>
    80003312:	ffffd097          	auipc	ra,0xffffd
    80003316:	218080e7          	jalr	536(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000331a:	fffff097          	auipc	ra,0xfffff
    8000331e:	eea080e7          	jalr	-278(ra) # 80002204 <myproc>
    80003322:	d541                	beqz	a0,800032aa <kerneltrap+0x38>
    80003324:	fffff097          	auipc	ra,0xfffff
    80003328:	ee0080e7          	jalr	-288(ra) # 80002204 <myproc>
    8000332c:	4d18                	lw	a4,24(a0)
    8000332e:	4791                	li	a5,4
    80003330:	f6f71de3          	bne	a4,a5,800032aa <kerneltrap+0x38>
    yield();
    80003334:	fffff097          	auipc	ra,0xfffff
    80003338:	690080e7          	jalr	1680(ra) # 800029c4 <yield>
    8000333c:	b7bd                	j	800032aa <kerneltrap+0x38>

000000008000333e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000333e:	1101                	addi	sp,sp,-32
    80003340:	ec06                	sd	ra,24(sp)
    80003342:	e822                	sd	s0,16(sp)
    80003344:	e426                	sd	s1,8(sp)
    80003346:	1000                	addi	s0,sp,32
    80003348:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000334a:	fffff097          	auipc	ra,0xfffff
    8000334e:	eba080e7          	jalr	-326(ra) # 80002204 <myproc>
  switch (n) {
    80003352:	4795                	li	a5,5
    80003354:	0497e163          	bltu	a5,s1,80003396 <argraw+0x58>
    80003358:	048a                	slli	s1,s1,0x2
    8000335a:	00006717          	auipc	a4,0x6
    8000335e:	51e70713          	addi	a4,a4,1310 # 80009878 <states.0+0x170>
    80003362:	94ba                	add	s1,s1,a4
    80003364:	409c                	lw	a5,0(s1)
    80003366:	97ba                	add	a5,a5,a4
    80003368:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000336a:	6d3c                	ld	a5,88(a0)
    8000336c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000336e:	60e2                	ld	ra,24(sp)
    80003370:	6442                	ld	s0,16(sp)
    80003372:	64a2                	ld	s1,8(sp)
    80003374:	6105                	addi	sp,sp,32
    80003376:	8082                	ret
    return p->trapframe->a1;
    80003378:	6d3c                	ld	a5,88(a0)
    8000337a:	7fa8                	ld	a0,120(a5)
    8000337c:	bfcd                	j	8000336e <argraw+0x30>
    return p->trapframe->a2;
    8000337e:	6d3c                	ld	a5,88(a0)
    80003380:	63c8                	ld	a0,128(a5)
    80003382:	b7f5                	j	8000336e <argraw+0x30>
    return p->trapframe->a3;
    80003384:	6d3c                	ld	a5,88(a0)
    80003386:	67c8                	ld	a0,136(a5)
    80003388:	b7dd                	j	8000336e <argraw+0x30>
    return p->trapframe->a4;
    8000338a:	6d3c                	ld	a5,88(a0)
    8000338c:	6bc8                	ld	a0,144(a5)
    8000338e:	b7c5                	j	8000336e <argraw+0x30>
    return p->trapframe->a5;
    80003390:	6d3c                	ld	a5,88(a0)
    80003392:	6fc8                	ld	a0,152(a5)
    80003394:	bfe9                	j	8000336e <argraw+0x30>
  panic("argraw");
    80003396:	00006517          	auipc	a0,0x6
    8000339a:	4ba50513          	addi	a0,a0,1210 # 80009850 <states.0+0x148>
    8000339e:	ffffd097          	auipc	ra,0xffffd
    800033a2:	18c080e7          	jalr	396(ra) # 8000052a <panic>

00000000800033a6 <fetchaddr>:
{
    800033a6:	1101                	addi	sp,sp,-32
    800033a8:	ec06                	sd	ra,24(sp)
    800033aa:	e822                	sd	s0,16(sp)
    800033ac:	e426                	sd	s1,8(sp)
    800033ae:	e04a                	sd	s2,0(sp)
    800033b0:	1000                	addi	s0,sp,32
    800033b2:	84aa                	mv	s1,a0
    800033b4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800033b6:	fffff097          	auipc	ra,0xfffff
    800033ba:	e4e080e7          	jalr	-434(ra) # 80002204 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800033be:	653c                	ld	a5,72(a0)
    800033c0:	02f4f863          	bgeu	s1,a5,800033f0 <fetchaddr+0x4a>
    800033c4:	00848713          	addi	a4,s1,8
    800033c8:	02e7e663          	bltu	a5,a4,800033f4 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800033cc:	46a1                	li	a3,8
    800033ce:	8626                	mv	a2,s1
    800033d0:	85ca                	mv	a1,s2
    800033d2:	6928                	ld	a0,80(a0)
    800033d4:	fffff097          	auipc	ra,0xfffff
    800033d8:	b7c080e7          	jalr	-1156(ra) # 80001f50 <copyin>
    800033dc:	00a03533          	snez	a0,a0
    800033e0:	40a00533          	neg	a0,a0
}
    800033e4:	60e2                	ld	ra,24(sp)
    800033e6:	6442                	ld	s0,16(sp)
    800033e8:	64a2                	ld	s1,8(sp)
    800033ea:	6902                	ld	s2,0(sp)
    800033ec:	6105                	addi	sp,sp,32
    800033ee:	8082                	ret
    return -1;
    800033f0:	557d                	li	a0,-1
    800033f2:	bfcd                	j	800033e4 <fetchaddr+0x3e>
    800033f4:	557d                	li	a0,-1
    800033f6:	b7fd                	j	800033e4 <fetchaddr+0x3e>

00000000800033f8 <fetchstr>:
{
    800033f8:	7179                	addi	sp,sp,-48
    800033fa:	f406                	sd	ra,40(sp)
    800033fc:	f022                	sd	s0,32(sp)
    800033fe:	ec26                	sd	s1,24(sp)
    80003400:	e84a                	sd	s2,16(sp)
    80003402:	e44e                	sd	s3,8(sp)
    80003404:	1800                	addi	s0,sp,48
    80003406:	892a                	mv	s2,a0
    80003408:	84ae                	mv	s1,a1
    8000340a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000340c:	fffff097          	auipc	ra,0xfffff
    80003410:	df8080e7          	jalr	-520(ra) # 80002204 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003414:	86ce                	mv	a3,s3
    80003416:	864a                	mv	a2,s2
    80003418:	85a6                	mv	a1,s1
    8000341a:	6928                	ld	a0,80(a0)
    8000341c:	fffff097          	auipc	ra,0xfffff
    80003420:	bc2080e7          	jalr	-1086(ra) # 80001fde <copyinstr>
  if(err < 0)
    80003424:	00054763          	bltz	a0,80003432 <fetchstr+0x3a>
  return strlen(buf);
    80003428:	8526                	mv	a0,s1
    8000342a:	ffffe097          	auipc	ra,0xffffe
    8000342e:	a18080e7          	jalr	-1512(ra) # 80000e42 <strlen>
}
    80003432:	70a2                	ld	ra,40(sp)
    80003434:	7402                	ld	s0,32(sp)
    80003436:	64e2                	ld	s1,24(sp)
    80003438:	6942                	ld	s2,16(sp)
    8000343a:	69a2                	ld	s3,8(sp)
    8000343c:	6145                	addi	sp,sp,48
    8000343e:	8082                	ret

0000000080003440 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003440:	1101                	addi	sp,sp,-32
    80003442:	ec06                	sd	ra,24(sp)
    80003444:	e822                	sd	s0,16(sp)
    80003446:	e426                	sd	s1,8(sp)
    80003448:	1000                	addi	s0,sp,32
    8000344a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000344c:	00000097          	auipc	ra,0x0
    80003450:	ef2080e7          	jalr	-270(ra) # 8000333e <argraw>
    80003454:	c088                	sw	a0,0(s1)
  return 0;
}
    80003456:	4501                	li	a0,0
    80003458:	60e2                	ld	ra,24(sp)
    8000345a:	6442                	ld	s0,16(sp)
    8000345c:	64a2                	ld	s1,8(sp)
    8000345e:	6105                	addi	sp,sp,32
    80003460:	8082                	ret

0000000080003462 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003462:	1101                	addi	sp,sp,-32
    80003464:	ec06                	sd	ra,24(sp)
    80003466:	e822                	sd	s0,16(sp)
    80003468:	e426                	sd	s1,8(sp)
    8000346a:	1000                	addi	s0,sp,32
    8000346c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000346e:	00000097          	auipc	ra,0x0
    80003472:	ed0080e7          	jalr	-304(ra) # 8000333e <argraw>
    80003476:	e088                	sd	a0,0(s1)
  return 0;
}
    80003478:	4501                	li	a0,0
    8000347a:	60e2                	ld	ra,24(sp)
    8000347c:	6442                	ld	s0,16(sp)
    8000347e:	64a2                	ld	s1,8(sp)
    80003480:	6105                	addi	sp,sp,32
    80003482:	8082                	ret

0000000080003484 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003484:	1101                	addi	sp,sp,-32
    80003486:	ec06                	sd	ra,24(sp)
    80003488:	e822                	sd	s0,16(sp)
    8000348a:	e426                	sd	s1,8(sp)
    8000348c:	e04a                	sd	s2,0(sp)
    8000348e:	1000                	addi	s0,sp,32
    80003490:	84ae                	mv	s1,a1
    80003492:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003494:	00000097          	auipc	ra,0x0
    80003498:	eaa080e7          	jalr	-342(ra) # 8000333e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    8000349c:	864a                	mv	a2,s2
    8000349e:	85a6                	mv	a1,s1
    800034a0:	00000097          	auipc	ra,0x0
    800034a4:	f58080e7          	jalr	-168(ra) # 800033f8 <fetchstr>
}
    800034a8:	60e2                	ld	ra,24(sp)
    800034aa:	6442                	ld	s0,16(sp)
    800034ac:	64a2                	ld	s1,8(sp)
    800034ae:	6902                	ld	s2,0(sp)
    800034b0:	6105                	addi	sp,sp,32
    800034b2:	8082                	ret

00000000800034b4 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    800034b4:	1101                	addi	sp,sp,-32
    800034b6:	ec06                	sd	ra,24(sp)
    800034b8:	e822                	sd	s0,16(sp)
    800034ba:	e426                	sd	s1,8(sp)
    800034bc:	e04a                	sd	s2,0(sp)
    800034be:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800034c0:	fffff097          	auipc	ra,0xfffff
    800034c4:	d44080e7          	jalr	-700(ra) # 80002204 <myproc>
    800034c8:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800034ca:	05853903          	ld	s2,88(a0)
    800034ce:	0a893783          	ld	a5,168(s2)
    800034d2:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800034d6:	37fd                	addiw	a5,a5,-1
    800034d8:	4751                	li	a4,20
    800034da:	00f76f63          	bltu	a4,a5,800034f8 <syscall+0x44>
    800034de:	00369713          	slli	a4,a3,0x3
    800034e2:	00006797          	auipc	a5,0x6
    800034e6:	3ae78793          	addi	a5,a5,942 # 80009890 <syscalls>
    800034ea:	97ba                	add	a5,a5,a4
    800034ec:	639c                	ld	a5,0(a5)
    800034ee:	c789                	beqz	a5,800034f8 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800034f0:	9782                	jalr	a5
    800034f2:	06a93823          	sd	a0,112(s2)
    800034f6:	a839                	j	80003514 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800034f8:	15848613          	addi	a2,s1,344
    800034fc:	588c                	lw	a1,48(s1)
    800034fe:	00006517          	auipc	a0,0x6
    80003502:	35a50513          	addi	a0,a0,858 # 80009858 <states.0+0x150>
    80003506:	ffffd097          	auipc	ra,0xffffd
    8000350a:	06e080e7          	jalr	110(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000350e:	6cbc                	ld	a5,88(s1)
    80003510:	577d                	li	a4,-1
    80003512:	fbb8                	sd	a4,112(a5)
  }
}
    80003514:	60e2                	ld	ra,24(sp)
    80003516:	6442                	ld	s0,16(sp)
    80003518:	64a2                	ld	s1,8(sp)
    8000351a:	6902                	ld	s2,0(sp)
    8000351c:	6105                	addi	sp,sp,32
    8000351e:	8082                	ret

0000000080003520 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003520:	1101                	addi	sp,sp,-32
    80003522:	ec06                	sd	ra,24(sp)
    80003524:	e822                	sd	s0,16(sp)
    80003526:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003528:	fec40593          	addi	a1,s0,-20
    8000352c:	4501                	li	a0,0
    8000352e:	00000097          	auipc	ra,0x0
    80003532:	f12080e7          	jalr	-238(ra) # 80003440 <argint>
    return -1;
    80003536:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003538:	00054963          	bltz	a0,8000354a <sys_exit+0x2a>
  exit(n);
    8000353c:	fec42503          	lw	a0,-20(s0)
    80003540:	fffff097          	auipc	ra,0xfffff
    80003544:	71c080e7          	jalr	1820(ra) # 80002c5c <exit>
  return 0;  // not reached
    80003548:	4781                	li	a5,0
}
    8000354a:	853e                	mv	a0,a5
    8000354c:	60e2                	ld	ra,24(sp)
    8000354e:	6442                	ld	s0,16(sp)
    80003550:	6105                	addi	sp,sp,32
    80003552:	8082                	ret

0000000080003554 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003554:	1141                	addi	sp,sp,-16
    80003556:	e406                	sd	ra,8(sp)
    80003558:	e022                	sd	s0,0(sp)
    8000355a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000355c:	fffff097          	auipc	ra,0xfffff
    80003560:	ca8080e7          	jalr	-856(ra) # 80002204 <myproc>
}
    80003564:	5908                	lw	a0,48(a0)
    80003566:	60a2                	ld	ra,8(sp)
    80003568:	6402                	ld	s0,0(sp)
    8000356a:	0141                	addi	sp,sp,16
    8000356c:	8082                	ret

000000008000356e <sys_fork>:

uint64
sys_fork(void)
{
    8000356e:	1141                	addi	sp,sp,-16
    80003570:	e406                	sd	ra,8(sp)
    80003572:	e022                	sd	s0,0(sp)
    80003574:	0800                	addi	s0,sp,16
  return fork();
    80003576:	fffff097          	auipc	ra,0xfffff
    8000357a:	0ec080e7          	jalr	236(ra) # 80002662 <fork>
}
    8000357e:	60a2                	ld	ra,8(sp)
    80003580:	6402                	ld	s0,0(sp)
    80003582:	0141                	addi	sp,sp,16
    80003584:	8082                	ret

0000000080003586 <sys_wait>:

uint64
sys_wait(void)
{
    80003586:	1101                	addi	sp,sp,-32
    80003588:	ec06                	sd	ra,24(sp)
    8000358a:	e822                	sd	s0,16(sp)
    8000358c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000358e:	fe840593          	addi	a1,s0,-24
    80003592:	4501                	li	a0,0
    80003594:	00000097          	auipc	ra,0x0
    80003598:	ece080e7          	jalr	-306(ra) # 80003462 <argaddr>
    8000359c:	87aa                	mv	a5,a0
    return -1;
    8000359e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800035a0:	0007c863          	bltz	a5,800035b0 <sys_wait+0x2a>
  return wait(p);
    800035a4:	fe843503          	ld	a0,-24(s0)
    800035a8:	fffff097          	auipc	ra,0xfffff
    800035ac:	4bc080e7          	jalr	1212(ra) # 80002a64 <wait>
}
    800035b0:	60e2                	ld	ra,24(sp)
    800035b2:	6442                	ld	s0,16(sp)
    800035b4:	6105                	addi	sp,sp,32
    800035b6:	8082                	ret

00000000800035b8 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800035b8:	7179                	addi	sp,sp,-48
    800035ba:	f406                	sd	ra,40(sp)
    800035bc:	f022                	sd	s0,32(sp)
    800035be:	ec26                	sd	s1,24(sp)
    800035c0:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800035c2:	fdc40593          	addi	a1,s0,-36
    800035c6:	4501                	li	a0,0
    800035c8:	00000097          	auipc	ra,0x0
    800035cc:	e78080e7          	jalr	-392(ra) # 80003440 <argint>
    return -1;
    800035d0:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    800035d2:	00054f63          	bltz	a0,800035f0 <sys_sbrk+0x38>
  addr = myproc()->sz;
    800035d6:	fffff097          	auipc	ra,0xfffff
    800035da:	c2e080e7          	jalr	-978(ra) # 80002204 <myproc>
    800035de:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800035e0:	fdc42503          	lw	a0,-36(s0)
    800035e4:	fffff097          	auipc	ra,0xfffff
    800035e8:	fe6080e7          	jalr	-26(ra) # 800025ca <growproc>
    800035ec:	00054863          	bltz	a0,800035fc <sys_sbrk+0x44>
    return -1;
  return addr;
}
    800035f0:	8526                	mv	a0,s1
    800035f2:	70a2                	ld	ra,40(sp)
    800035f4:	7402                	ld	s0,32(sp)
    800035f6:	64e2                	ld	s1,24(sp)
    800035f8:	6145                	addi	sp,sp,48
    800035fa:	8082                	ret
    return -1;
    800035fc:	54fd                	li	s1,-1
    800035fe:	bfcd                	j	800035f0 <sys_sbrk+0x38>

0000000080003600 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003600:	7139                	addi	sp,sp,-64
    80003602:	fc06                	sd	ra,56(sp)
    80003604:	f822                	sd	s0,48(sp)
    80003606:	f426                	sd	s1,40(sp)
    80003608:	f04a                	sd	s2,32(sp)
    8000360a:	ec4e                	sd	s3,24(sp)
    8000360c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000360e:	fcc40593          	addi	a1,s0,-52
    80003612:	4501                	li	a0,0
    80003614:	00000097          	auipc	ra,0x0
    80003618:	e2c080e7          	jalr	-468(ra) # 80003440 <argint>
    return -1;
    8000361c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000361e:	06054563          	bltz	a0,80003688 <sys_sleep+0x88>
  acquire(&tickslock);
    80003622:	0001c517          	auipc	a0,0x1c
    80003626:	0ae50513          	addi	a0,a0,174 # 8001f6d0 <tickslock>
    8000362a:	ffffd097          	auipc	ra,0xffffd
    8000362e:	598080e7          	jalr	1432(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80003632:	00007917          	auipc	s2,0x7
    80003636:	9fe92903          	lw	s2,-1538(s2) # 8000a030 <ticks>
  while(ticks - ticks0 < n){
    8000363a:	fcc42783          	lw	a5,-52(s0)
    8000363e:	cf85                	beqz	a5,80003676 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003640:	0001c997          	auipc	s3,0x1c
    80003644:	09098993          	addi	s3,s3,144 # 8001f6d0 <tickslock>
    80003648:	00007497          	auipc	s1,0x7
    8000364c:	9e848493          	addi	s1,s1,-1560 # 8000a030 <ticks>
    if(myproc()->killed){
    80003650:	fffff097          	auipc	ra,0xfffff
    80003654:	bb4080e7          	jalr	-1100(ra) # 80002204 <myproc>
    80003658:	551c                	lw	a5,40(a0)
    8000365a:	ef9d                	bnez	a5,80003698 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000365c:	85ce                	mv	a1,s3
    8000365e:	8526                	mv	a0,s1
    80003660:	fffff097          	auipc	ra,0xfffff
    80003664:	3a0080e7          	jalr	928(ra) # 80002a00 <sleep>
  while(ticks - ticks0 < n){
    80003668:	409c                	lw	a5,0(s1)
    8000366a:	412787bb          	subw	a5,a5,s2
    8000366e:	fcc42703          	lw	a4,-52(s0)
    80003672:	fce7efe3          	bltu	a5,a4,80003650 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003676:	0001c517          	auipc	a0,0x1c
    8000367a:	05a50513          	addi	a0,a0,90 # 8001f6d0 <tickslock>
    8000367e:	ffffd097          	auipc	ra,0xffffd
    80003682:	5f8080e7          	jalr	1528(ra) # 80000c76 <release>
  return 0;
    80003686:	4781                	li	a5,0
}
    80003688:	853e                	mv	a0,a5
    8000368a:	70e2                	ld	ra,56(sp)
    8000368c:	7442                	ld	s0,48(sp)
    8000368e:	74a2                	ld	s1,40(sp)
    80003690:	7902                	ld	s2,32(sp)
    80003692:	69e2                	ld	s3,24(sp)
    80003694:	6121                	addi	sp,sp,64
    80003696:	8082                	ret
      release(&tickslock);
    80003698:	0001c517          	auipc	a0,0x1c
    8000369c:	03850513          	addi	a0,a0,56 # 8001f6d0 <tickslock>
    800036a0:	ffffd097          	auipc	ra,0xffffd
    800036a4:	5d6080e7          	jalr	1494(ra) # 80000c76 <release>
      return -1;
    800036a8:	57fd                	li	a5,-1
    800036aa:	bff9                	j	80003688 <sys_sleep+0x88>

00000000800036ac <sys_kill>:

uint64
sys_kill(void)
{
    800036ac:	1101                	addi	sp,sp,-32
    800036ae:	ec06                	sd	ra,24(sp)
    800036b0:	e822                	sd	s0,16(sp)
    800036b2:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800036b4:	fec40593          	addi	a1,s0,-20
    800036b8:	4501                	li	a0,0
    800036ba:	00000097          	auipc	ra,0x0
    800036be:	d86080e7          	jalr	-634(ra) # 80003440 <argint>
    800036c2:	87aa                	mv	a5,a0
    return -1;
    800036c4:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800036c6:	0007c863          	bltz	a5,800036d6 <sys_kill+0x2a>
  return kill(pid);
    800036ca:	fec42503          	lw	a0,-20(s0)
    800036ce:	fffff097          	auipc	ra,0xfffff
    800036d2:	67a080e7          	jalr	1658(ra) # 80002d48 <kill>
}
    800036d6:	60e2                	ld	ra,24(sp)
    800036d8:	6442                	ld	s0,16(sp)
    800036da:	6105                	addi	sp,sp,32
    800036dc:	8082                	ret

00000000800036de <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800036de:	1101                	addi	sp,sp,-32
    800036e0:	ec06                	sd	ra,24(sp)
    800036e2:	e822                	sd	s0,16(sp)
    800036e4:	e426                	sd	s1,8(sp)
    800036e6:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800036e8:	0001c517          	auipc	a0,0x1c
    800036ec:	fe850513          	addi	a0,a0,-24 # 8001f6d0 <tickslock>
    800036f0:	ffffd097          	auipc	ra,0xffffd
    800036f4:	4d2080e7          	jalr	1234(ra) # 80000bc2 <acquire>
  xticks = ticks;
    800036f8:	00007497          	auipc	s1,0x7
    800036fc:	9384a483          	lw	s1,-1736(s1) # 8000a030 <ticks>
  release(&tickslock);
    80003700:	0001c517          	auipc	a0,0x1c
    80003704:	fd050513          	addi	a0,a0,-48 # 8001f6d0 <tickslock>
    80003708:	ffffd097          	auipc	ra,0xffffd
    8000370c:	56e080e7          	jalr	1390(ra) # 80000c76 <release>
  return xticks;
}
    80003710:	02049513          	slli	a0,s1,0x20
    80003714:	9101                	srli	a0,a0,0x20
    80003716:	60e2                	ld	ra,24(sp)
    80003718:	6442                	ld	s0,16(sp)
    8000371a:	64a2                	ld	s1,8(sp)
    8000371c:	6105                	addi	sp,sp,32
    8000371e:	8082                	ret

0000000080003720 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003720:	7179                	addi	sp,sp,-48
    80003722:	f406                	sd	ra,40(sp)
    80003724:	f022                	sd	s0,32(sp)
    80003726:	ec26                	sd	s1,24(sp)
    80003728:	e84a                	sd	s2,16(sp)
    8000372a:	e44e                	sd	s3,8(sp)
    8000372c:	e052                	sd	s4,0(sp)
    8000372e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003730:	00006597          	auipc	a1,0x6
    80003734:	21058593          	addi	a1,a1,528 # 80009940 <syscalls+0xb0>
    80003738:	0001c517          	auipc	a0,0x1c
    8000373c:	fb050513          	addi	a0,a0,-80 # 8001f6e8 <bcache>
    80003740:	ffffd097          	auipc	ra,0xffffd
    80003744:	3f2080e7          	jalr	1010(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003748:	00024797          	auipc	a5,0x24
    8000374c:	fa078793          	addi	a5,a5,-96 # 800276e8 <bcache+0x8000>
    80003750:	00024717          	auipc	a4,0x24
    80003754:	20070713          	addi	a4,a4,512 # 80027950 <bcache+0x8268>
    80003758:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000375c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003760:	0001c497          	auipc	s1,0x1c
    80003764:	fa048493          	addi	s1,s1,-96 # 8001f700 <bcache+0x18>
    b->next = bcache.head.next;
    80003768:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000376a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000376c:	00006a17          	auipc	s4,0x6
    80003770:	1dca0a13          	addi	s4,s4,476 # 80009948 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003774:	2b893783          	ld	a5,696(s2)
    80003778:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000377a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000377e:	85d2                	mv	a1,s4
    80003780:	01048513          	addi	a0,s1,16
    80003784:	00001097          	auipc	ra,0x1
    80003788:	7d4080e7          	jalr	2004(ra) # 80004f58 <initsleeplock>
    bcache.head.next->prev = b;
    8000378c:	2b893783          	ld	a5,696(s2)
    80003790:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003792:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003796:	45848493          	addi	s1,s1,1112
    8000379a:	fd349de3          	bne	s1,s3,80003774 <binit+0x54>
  }
}
    8000379e:	70a2                	ld	ra,40(sp)
    800037a0:	7402                	ld	s0,32(sp)
    800037a2:	64e2                	ld	s1,24(sp)
    800037a4:	6942                	ld	s2,16(sp)
    800037a6:	69a2                	ld	s3,8(sp)
    800037a8:	6a02                	ld	s4,0(sp)
    800037aa:	6145                	addi	sp,sp,48
    800037ac:	8082                	ret

00000000800037ae <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800037ae:	7179                	addi	sp,sp,-48
    800037b0:	f406                	sd	ra,40(sp)
    800037b2:	f022                	sd	s0,32(sp)
    800037b4:	ec26                	sd	s1,24(sp)
    800037b6:	e84a                	sd	s2,16(sp)
    800037b8:	e44e                	sd	s3,8(sp)
    800037ba:	1800                	addi	s0,sp,48
    800037bc:	892a                	mv	s2,a0
    800037be:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800037c0:	0001c517          	auipc	a0,0x1c
    800037c4:	f2850513          	addi	a0,a0,-216 # 8001f6e8 <bcache>
    800037c8:	ffffd097          	auipc	ra,0xffffd
    800037cc:	3fa080e7          	jalr	1018(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800037d0:	00024497          	auipc	s1,0x24
    800037d4:	1d04b483          	ld	s1,464(s1) # 800279a0 <bcache+0x82b8>
    800037d8:	00024797          	auipc	a5,0x24
    800037dc:	17878793          	addi	a5,a5,376 # 80027950 <bcache+0x8268>
    800037e0:	02f48f63          	beq	s1,a5,8000381e <bread+0x70>
    800037e4:	873e                	mv	a4,a5
    800037e6:	a021                	j	800037ee <bread+0x40>
    800037e8:	68a4                	ld	s1,80(s1)
    800037ea:	02e48a63          	beq	s1,a4,8000381e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800037ee:	449c                	lw	a5,8(s1)
    800037f0:	ff279ce3          	bne	a5,s2,800037e8 <bread+0x3a>
    800037f4:	44dc                	lw	a5,12(s1)
    800037f6:	ff3799e3          	bne	a5,s3,800037e8 <bread+0x3a>
      b->refcnt++;
    800037fa:	40bc                	lw	a5,64(s1)
    800037fc:	2785                	addiw	a5,a5,1
    800037fe:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003800:	0001c517          	auipc	a0,0x1c
    80003804:	ee850513          	addi	a0,a0,-280 # 8001f6e8 <bcache>
    80003808:	ffffd097          	auipc	ra,0xffffd
    8000380c:	46e080e7          	jalr	1134(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003810:	01048513          	addi	a0,s1,16
    80003814:	00001097          	auipc	ra,0x1
    80003818:	77e080e7          	jalr	1918(ra) # 80004f92 <acquiresleep>
      return b;
    8000381c:	a8b9                	j	8000387a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000381e:	00024497          	auipc	s1,0x24
    80003822:	17a4b483          	ld	s1,378(s1) # 80027998 <bcache+0x82b0>
    80003826:	00024797          	auipc	a5,0x24
    8000382a:	12a78793          	addi	a5,a5,298 # 80027950 <bcache+0x8268>
    8000382e:	00f48863          	beq	s1,a5,8000383e <bread+0x90>
    80003832:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003834:	40bc                	lw	a5,64(s1)
    80003836:	cf81                	beqz	a5,8000384e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003838:	64a4                	ld	s1,72(s1)
    8000383a:	fee49de3          	bne	s1,a4,80003834 <bread+0x86>
  panic("bget: no buffers");
    8000383e:	00006517          	auipc	a0,0x6
    80003842:	11250513          	addi	a0,a0,274 # 80009950 <syscalls+0xc0>
    80003846:	ffffd097          	auipc	ra,0xffffd
    8000384a:	ce4080e7          	jalr	-796(ra) # 8000052a <panic>
      b->dev = dev;
    8000384e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003852:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003856:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000385a:	4785                	li	a5,1
    8000385c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000385e:	0001c517          	auipc	a0,0x1c
    80003862:	e8a50513          	addi	a0,a0,-374 # 8001f6e8 <bcache>
    80003866:	ffffd097          	auipc	ra,0xffffd
    8000386a:	410080e7          	jalr	1040(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    8000386e:	01048513          	addi	a0,s1,16
    80003872:	00001097          	auipc	ra,0x1
    80003876:	720080e7          	jalr	1824(ra) # 80004f92 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000387a:	409c                	lw	a5,0(s1)
    8000387c:	cb89                	beqz	a5,8000388e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000387e:	8526                	mv	a0,s1
    80003880:	70a2                	ld	ra,40(sp)
    80003882:	7402                	ld	s0,32(sp)
    80003884:	64e2                	ld	s1,24(sp)
    80003886:	6942                	ld	s2,16(sp)
    80003888:	69a2                	ld	s3,8(sp)
    8000388a:	6145                	addi	sp,sp,48
    8000388c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000388e:	4581                	li	a1,0
    80003890:	8526                	mv	a0,s1
    80003892:	00003097          	auipc	ra,0x3
    80003896:	494080e7          	jalr	1172(ra) # 80006d26 <virtio_disk_rw>
    b->valid = 1;
    8000389a:	4785                	li	a5,1
    8000389c:	c09c                	sw	a5,0(s1)
  return b;
    8000389e:	b7c5                	j	8000387e <bread+0xd0>

00000000800038a0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800038a0:	1101                	addi	sp,sp,-32
    800038a2:	ec06                	sd	ra,24(sp)
    800038a4:	e822                	sd	s0,16(sp)
    800038a6:	e426                	sd	s1,8(sp)
    800038a8:	1000                	addi	s0,sp,32
    800038aa:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800038ac:	0541                	addi	a0,a0,16
    800038ae:	00001097          	auipc	ra,0x1
    800038b2:	77e080e7          	jalr	1918(ra) # 8000502c <holdingsleep>
    800038b6:	cd01                	beqz	a0,800038ce <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800038b8:	4585                	li	a1,1
    800038ba:	8526                	mv	a0,s1
    800038bc:	00003097          	auipc	ra,0x3
    800038c0:	46a080e7          	jalr	1130(ra) # 80006d26 <virtio_disk_rw>
}
    800038c4:	60e2                	ld	ra,24(sp)
    800038c6:	6442                	ld	s0,16(sp)
    800038c8:	64a2                	ld	s1,8(sp)
    800038ca:	6105                	addi	sp,sp,32
    800038cc:	8082                	ret
    panic("bwrite");
    800038ce:	00006517          	auipc	a0,0x6
    800038d2:	09a50513          	addi	a0,a0,154 # 80009968 <syscalls+0xd8>
    800038d6:	ffffd097          	auipc	ra,0xffffd
    800038da:	c54080e7          	jalr	-940(ra) # 8000052a <panic>

00000000800038de <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800038de:	1101                	addi	sp,sp,-32
    800038e0:	ec06                	sd	ra,24(sp)
    800038e2:	e822                	sd	s0,16(sp)
    800038e4:	e426                	sd	s1,8(sp)
    800038e6:	e04a                	sd	s2,0(sp)
    800038e8:	1000                	addi	s0,sp,32
    800038ea:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800038ec:	01050913          	addi	s2,a0,16
    800038f0:	854a                	mv	a0,s2
    800038f2:	00001097          	auipc	ra,0x1
    800038f6:	73a080e7          	jalr	1850(ra) # 8000502c <holdingsleep>
    800038fa:	c92d                	beqz	a0,8000396c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800038fc:	854a                	mv	a0,s2
    800038fe:	00001097          	auipc	ra,0x1
    80003902:	6ea080e7          	jalr	1770(ra) # 80004fe8 <releasesleep>

  acquire(&bcache.lock);
    80003906:	0001c517          	auipc	a0,0x1c
    8000390a:	de250513          	addi	a0,a0,-542 # 8001f6e8 <bcache>
    8000390e:	ffffd097          	auipc	ra,0xffffd
    80003912:	2b4080e7          	jalr	692(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003916:	40bc                	lw	a5,64(s1)
    80003918:	37fd                	addiw	a5,a5,-1
    8000391a:	0007871b          	sext.w	a4,a5
    8000391e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003920:	eb05                	bnez	a4,80003950 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003922:	68bc                	ld	a5,80(s1)
    80003924:	64b8                	ld	a4,72(s1)
    80003926:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003928:	64bc                	ld	a5,72(s1)
    8000392a:	68b8                	ld	a4,80(s1)
    8000392c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000392e:	00024797          	auipc	a5,0x24
    80003932:	dba78793          	addi	a5,a5,-582 # 800276e8 <bcache+0x8000>
    80003936:	2b87b703          	ld	a4,696(a5)
    8000393a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000393c:	00024717          	auipc	a4,0x24
    80003940:	01470713          	addi	a4,a4,20 # 80027950 <bcache+0x8268>
    80003944:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003946:	2b87b703          	ld	a4,696(a5)
    8000394a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000394c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003950:	0001c517          	auipc	a0,0x1c
    80003954:	d9850513          	addi	a0,a0,-616 # 8001f6e8 <bcache>
    80003958:	ffffd097          	auipc	ra,0xffffd
    8000395c:	31e080e7          	jalr	798(ra) # 80000c76 <release>
}
    80003960:	60e2                	ld	ra,24(sp)
    80003962:	6442                	ld	s0,16(sp)
    80003964:	64a2                	ld	s1,8(sp)
    80003966:	6902                	ld	s2,0(sp)
    80003968:	6105                	addi	sp,sp,32
    8000396a:	8082                	ret
    panic("brelse");
    8000396c:	00006517          	auipc	a0,0x6
    80003970:	00450513          	addi	a0,a0,4 # 80009970 <syscalls+0xe0>
    80003974:	ffffd097          	auipc	ra,0xffffd
    80003978:	bb6080e7          	jalr	-1098(ra) # 8000052a <panic>

000000008000397c <bpin>:

void
bpin(struct buf *b) {
    8000397c:	1101                	addi	sp,sp,-32
    8000397e:	ec06                	sd	ra,24(sp)
    80003980:	e822                	sd	s0,16(sp)
    80003982:	e426                	sd	s1,8(sp)
    80003984:	1000                	addi	s0,sp,32
    80003986:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003988:	0001c517          	auipc	a0,0x1c
    8000398c:	d6050513          	addi	a0,a0,-672 # 8001f6e8 <bcache>
    80003990:	ffffd097          	auipc	ra,0xffffd
    80003994:	232080e7          	jalr	562(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003998:	40bc                	lw	a5,64(s1)
    8000399a:	2785                	addiw	a5,a5,1
    8000399c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000399e:	0001c517          	auipc	a0,0x1c
    800039a2:	d4a50513          	addi	a0,a0,-694 # 8001f6e8 <bcache>
    800039a6:	ffffd097          	auipc	ra,0xffffd
    800039aa:	2d0080e7          	jalr	720(ra) # 80000c76 <release>
}
    800039ae:	60e2                	ld	ra,24(sp)
    800039b0:	6442                	ld	s0,16(sp)
    800039b2:	64a2                	ld	s1,8(sp)
    800039b4:	6105                	addi	sp,sp,32
    800039b6:	8082                	ret

00000000800039b8 <bunpin>:

void
bunpin(struct buf *b) {
    800039b8:	1101                	addi	sp,sp,-32
    800039ba:	ec06                	sd	ra,24(sp)
    800039bc:	e822                	sd	s0,16(sp)
    800039be:	e426                	sd	s1,8(sp)
    800039c0:	1000                	addi	s0,sp,32
    800039c2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800039c4:	0001c517          	auipc	a0,0x1c
    800039c8:	d2450513          	addi	a0,a0,-732 # 8001f6e8 <bcache>
    800039cc:	ffffd097          	auipc	ra,0xffffd
    800039d0:	1f6080e7          	jalr	502(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800039d4:	40bc                	lw	a5,64(s1)
    800039d6:	37fd                	addiw	a5,a5,-1
    800039d8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800039da:	0001c517          	auipc	a0,0x1c
    800039de:	d0e50513          	addi	a0,a0,-754 # 8001f6e8 <bcache>
    800039e2:	ffffd097          	auipc	ra,0xffffd
    800039e6:	294080e7          	jalr	660(ra) # 80000c76 <release>
}
    800039ea:	60e2                	ld	ra,24(sp)
    800039ec:	6442                	ld	s0,16(sp)
    800039ee:	64a2                	ld	s1,8(sp)
    800039f0:	6105                	addi	sp,sp,32
    800039f2:	8082                	ret

00000000800039f4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800039f4:	1101                	addi	sp,sp,-32
    800039f6:	ec06                	sd	ra,24(sp)
    800039f8:	e822                	sd	s0,16(sp)
    800039fa:	e426                	sd	s1,8(sp)
    800039fc:	e04a                	sd	s2,0(sp)
    800039fe:	1000                	addi	s0,sp,32
    80003a00:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003a02:	00d5d59b          	srliw	a1,a1,0xd
    80003a06:	00024797          	auipc	a5,0x24
    80003a0a:	3be7a783          	lw	a5,958(a5) # 80027dc4 <sb+0x1c>
    80003a0e:	9dbd                	addw	a1,a1,a5
    80003a10:	00000097          	auipc	ra,0x0
    80003a14:	d9e080e7          	jalr	-610(ra) # 800037ae <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003a18:	0074f713          	andi	a4,s1,7
    80003a1c:	4785                	li	a5,1
    80003a1e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003a22:	14ce                	slli	s1,s1,0x33
    80003a24:	90d9                	srli	s1,s1,0x36
    80003a26:	00950733          	add	a4,a0,s1
    80003a2a:	05874703          	lbu	a4,88(a4)
    80003a2e:	00e7f6b3          	and	a3,a5,a4
    80003a32:	c69d                	beqz	a3,80003a60 <bfree+0x6c>
    80003a34:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003a36:	94aa                	add	s1,s1,a0
    80003a38:	fff7c793          	not	a5,a5
    80003a3c:	8ff9                	and	a5,a5,a4
    80003a3e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003a42:	00001097          	auipc	ra,0x1
    80003a46:	430080e7          	jalr	1072(ra) # 80004e72 <log_write>
  brelse(bp);
    80003a4a:	854a                	mv	a0,s2
    80003a4c:	00000097          	auipc	ra,0x0
    80003a50:	e92080e7          	jalr	-366(ra) # 800038de <brelse>
}
    80003a54:	60e2                	ld	ra,24(sp)
    80003a56:	6442                	ld	s0,16(sp)
    80003a58:	64a2                	ld	s1,8(sp)
    80003a5a:	6902                	ld	s2,0(sp)
    80003a5c:	6105                	addi	sp,sp,32
    80003a5e:	8082                	ret
    panic("freeing free block");
    80003a60:	00006517          	auipc	a0,0x6
    80003a64:	f1850513          	addi	a0,a0,-232 # 80009978 <syscalls+0xe8>
    80003a68:	ffffd097          	auipc	ra,0xffffd
    80003a6c:	ac2080e7          	jalr	-1342(ra) # 8000052a <panic>

0000000080003a70 <balloc>:
{
    80003a70:	711d                	addi	sp,sp,-96
    80003a72:	ec86                	sd	ra,88(sp)
    80003a74:	e8a2                	sd	s0,80(sp)
    80003a76:	e4a6                	sd	s1,72(sp)
    80003a78:	e0ca                	sd	s2,64(sp)
    80003a7a:	fc4e                	sd	s3,56(sp)
    80003a7c:	f852                	sd	s4,48(sp)
    80003a7e:	f456                	sd	s5,40(sp)
    80003a80:	f05a                	sd	s6,32(sp)
    80003a82:	ec5e                	sd	s7,24(sp)
    80003a84:	e862                	sd	s8,16(sp)
    80003a86:	e466                	sd	s9,8(sp)
    80003a88:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003a8a:	00024797          	auipc	a5,0x24
    80003a8e:	3227a783          	lw	a5,802(a5) # 80027dac <sb+0x4>
    80003a92:	cbd1                	beqz	a5,80003b26 <balloc+0xb6>
    80003a94:	8baa                	mv	s7,a0
    80003a96:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003a98:	00024b17          	auipc	s6,0x24
    80003a9c:	310b0b13          	addi	s6,s6,784 # 80027da8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003aa0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003aa2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003aa4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003aa6:	6c89                	lui	s9,0x2
    80003aa8:	a831                	j	80003ac4 <balloc+0x54>
    brelse(bp);
    80003aaa:	854a                	mv	a0,s2
    80003aac:	00000097          	auipc	ra,0x0
    80003ab0:	e32080e7          	jalr	-462(ra) # 800038de <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003ab4:	015c87bb          	addw	a5,s9,s5
    80003ab8:	00078a9b          	sext.w	s5,a5
    80003abc:	004b2703          	lw	a4,4(s6)
    80003ac0:	06eaf363          	bgeu	s5,a4,80003b26 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003ac4:	41fad79b          	sraiw	a5,s5,0x1f
    80003ac8:	0137d79b          	srliw	a5,a5,0x13
    80003acc:	015787bb          	addw	a5,a5,s5
    80003ad0:	40d7d79b          	sraiw	a5,a5,0xd
    80003ad4:	01cb2583          	lw	a1,28(s6)
    80003ad8:	9dbd                	addw	a1,a1,a5
    80003ada:	855e                	mv	a0,s7
    80003adc:	00000097          	auipc	ra,0x0
    80003ae0:	cd2080e7          	jalr	-814(ra) # 800037ae <bread>
    80003ae4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ae6:	004b2503          	lw	a0,4(s6)
    80003aea:	000a849b          	sext.w	s1,s5
    80003aee:	8662                	mv	a2,s8
    80003af0:	faa4fde3          	bgeu	s1,a0,80003aaa <balloc+0x3a>
      m = 1 << (bi % 8);
    80003af4:	41f6579b          	sraiw	a5,a2,0x1f
    80003af8:	01d7d69b          	srliw	a3,a5,0x1d
    80003afc:	00c6873b          	addw	a4,a3,a2
    80003b00:	00777793          	andi	a5,a4,7
    80003b04:	9f95                	subw	a5,a5,a3
    80003b06:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003b0a:	4037571b          	sraiw	a4,a4,0x3
    80003b0e:	00e906b3          	add	a3,s2,a4
    80003b12:	0586c683          	lbu	a3,88(a3)
    80003b16:	00d7f5b3          	and	a1,a5,a3
    80003b1a:	cd91                	beqz	a1,80003b36 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b1c:	2605                	addiw	a2,a2,1
    80003b1e:	2485                	addiw	s1,s1,1
    80003b20:	fd4618e3          	bne	a2,s4,80003af0 <balloc+0x80>
    80003b24:	b759                	j	80003aaa <balloc+0x3a>
  panic("balloc: out of blocks");
    80003b26:	00006517          	auipc	a0,0x6
    80003b2a:	e6a50513          	addi	a0,a0,-406 # 80009990 <syscalls+0x100>
    80003b2e:	ffffd097          	auipc	ra,0xffffd
    80003b32:	9fc080e7          	jalr	-1540(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003b36:	974a                	add	a4,a4,s2
    80003b38:	8fd5                	or	a5,a5,a3
    80003b3a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003b3e:	854a                	mv	a0,s2
    80003b40:	00001097          	auipc	ra,0x1
    80003b44:	332080e7          	jalr	818(ra) # 80004e72 <log_write>
        brelse(bp);
    80003b48:	854a                	mv	a0,s2
    80003b4a:	00000097          	auipc	ra,0x0
    80003b4e:	d94080e7          	jalr	-620(ra) # 800038de <brelse>
  bp = bread(dev, bno);
    80003b52:	85a6                	mv	a1,s1
    80003b54:	855e                	mv	a0,s7
    80003b56:	00000097          	auipc	ra,0x0
    80003b5a:	c58080e7          	jalr	-936(ra) # 800037ae <bread>
    80003b5e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003b60:	40000613          	li	a2,1024
    80003b64:	4581                	li	a1,0
    80003b66:	05850513          	addi	a0,a0,88
    80003b6a:	ffffd097          	auipc	ra,0xffffd
    80003b6e:	154080e7          	jalr	340(ra) # 80000cbe <memset>
  log_write(bp);
    80003b72:	854a                	mv	a0,s2
    80003b74:	00001097          	auipc	ra,0x1
    80003b78:	2fe080e7          	jalr	766(ra) # 80004e72 <log_write>
  brelse(bp);
    80003b7c:	854a                	mv	a0,s2
    80003b7e:	00000097          	auipc	ra,0x0
    80003b82:	d60080e7          	jalr	-672(ra) # 800038de <brelse>
}
    80003b86:	8526                	mv	a0,s1
    80003b88:	60e6                	ld	ra,88(sp)
    80003b8a:	6446                	ld	s0,80(sp)
    80003b8c:	64a6                	ld	s1,72(sp)
    80003b8e:	6906                	ld	s2,64(sp)
    80003b90:	79e2                	ld	s3,56(sp)
    80003b92:	7a42                	ld	s4,48(sp)
    80003b94:	7aa2                	ld	s5,40(sp)
    80003b96:	7b02                	ld	s6,32(sp)
    80003b98:	6be2                	ld	s7,24(sp)
    80003b9a:	6c42                	ld	s8,16(sp)
    80003b9c:	6ca2                	ld	s9,8(sp)
    80003b9e:	6125                	addi	sp,sp,96
    80003ba0:	8082                	ret

0000000080003ba2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003ba2:	7179                	addi	sp,sp,-48
    80003ba4:	f406                	sd	ra,40(sp)
    80003ba6:	f022                	sd	s0,32(sp)
    80003ba8:	ec26                	sd	s1,24(sp)
    80003baa:	e84a                	sd	s2,16(sp)
    80003bac:	e44e                	sd	s3,8(sp)
    80003bae:	e052                	sd	s4,0(sp)
    80003bb0:	1800                	addi	s0,sp,48
    80003bb2:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003bb4:	47ad                	li	a5,11
    80003bb6:	04b7fe63          	bgeu	a5,a1,80003c12 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003bba:	ff45849b          	addiw	s1,a1,-12
    80003bbe:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003bc2:	0ff00793          	li	a5,255
    80003bc6:	0ae7e463          	bltu	a5,a4,80003c6e <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003bca:	08052583          	lw	a1,128(a0)
    80003bce:	c5b5                	beqz	a1,80003c3a <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003bd0:	00092503          	lw	a0,0(s2)
    80003bd4:	00000097          	auipc	ra,0x0
    80003bd8:	bda080e7          	jalr	-1062(ra) # 800037ae <bread>
    80003bdc:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003bde:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003be2:	02049713          	slli	a4,s1,0x20
    80003be6:	01e75593          	srli	a1,a4,0x1e
    80003bea:	00b784b3          	add	s1,a5,a1
    80003bee:	0004a983          	lw	s3,0(s1)
    80003bf2:	04098e63          	beqz	s3,80003c4e <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003bf6:	8552                	mv	a0,s4
    80003bf8:	00000097          	auipc	ra,0x0
    80003bfc:	ce6080e7          	jalr	-794(ra) # 800038de <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003c00:	854e                	mv	a0,s3
    80003c02:	70a2                	ld	ra,40(sp)
    80003c04:	7402                	ld	s0,32(sp)
    80003c06:	64e2                	ld	s1,24(sp)
    80003c08:	6942                	ld	s2,16(sp)
    80003c0a:	69a2                	ld	s3,8(sp)
    80003c0c:	6a02                	ld	s4,0(sp)
    80003c0e:	6145                	addi	sp,sp,48
    80003c10:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003c12:	02059793          	slli	a5,a1,0x20
    80003c16:	01e7d593          	srli	a1,a5,0x1e
    80003c1a:	00b504b3          	add	s1,a0,a1
    80003c1e:	0504a983          	lw	s3,80(s1)
    80003c22:	fc099fe3          	bnez	s3,80003c00 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003c26:	4108                	lw	a0,0(a0)
    80003c28:	00000097          	auipc	ra,0x0
    80003c2c:	e48080e7          	jalr	-440(ra) # 80003a70 <balloc>
    80003c30:	0005099b          	sext.w	s3,a0
    80003c34:	0534a823          	sw	s3,80(s1)
    80003c38:	b7e1                	j	80003c00 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003c3a:	4108                	lw	a0,0(a0)
    80003c3c:	00000097          	auipc	ra,0x0
    80003c40:	e34080e7          	jalr	-460(ra) # 80003a70 <balloc>
    80003c44:	0005059b          	sext.w	a1,a0
    80003c48:	08b92023          	sw	a1,128(s2)
    80003c4c:	b751                	j	80003bd0 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003c4e:	00092503          	lw	a0,0(s2)
    80003c52:	00000097          	auipc	ra,0x0
    80003c56:	e1e080e7          	jalr	-482(ra) # 80003a70 <balloc>
    80003c5a:	0005099b          	sext.w	s3,a0
    80003c5e:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003c62:	8552                	mv	a0,s4
    80003c64:	00001097          	auipc	ra,0x1
    80003c68:	20e080e7          	jalr	526(ra) # 80004e72 <log_write>
    80003c6c:	b769                	j	80003bf6 <bmap+0x54>
  panic("bmap: out of range");
    80003c6e:	00006517          	auipc	a0,0x6
    80003c72:	d3a50513          	addi	a0,a0,-710 # 800099a8 <syscalls+0x118>
    80003c76:	ffffd097          	auipc	ra,0xffffd
    80003c7a:	8b4080e7          	jalr	-1868(ra) # 8000052a <panic>

0000000080003c7e <iget>:
{
    80003c7e:	7179                	addi	sp,sp,-48
    80003c80:	f406                	sd	ra,40(sp)
    80003c82:	f022                	sd	s0,32(sp)
    80003c84:	ec26                	sd	s1,24(sp)
    80003c86:	e84a                	sd	s2,16(sp)
    80003c88:	e44e                	sd	s3,8(sp)
    80003c8a:	e052                	sd	s4,0(sp)
    80003c8c:	1800                	addi	s0,sp,48
    80003c8e:	89aa                	mv	s3,a0
    80003c90:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003c92:	00024517          	auipc	a0,0x24
    80003c96:	13650513          	addi	a0,a0,310 # 80027dc8 <itable>
    80003c9a:	ffffd097          	auipc	ra,0xffffd
    80003c9e:	f28080e7          	jalr	-216(ra) # 80000bc2 <acquire>
  empty = 0;
    80003ca2:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ca4:	00024497          	auipc	s1,0x24
    80003ca8:	13c48493          	addi	s1,s1,316 # 80027de0 <itable+0x18>
    80003cac:	00026697          	auipc	a3,0x26
    80003cb0:	bc468693          	addi	a3,a3,-1084 # 80029870 <log>
    80003cb4:	a039                	j	80003cc2 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003cb6:	02090b63          	beqz	s2,80003cec <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003cba:	08848493          	addi	s1,s1,136
    80003cbe:	02d48a63          	beq	s1,a3,80003cf2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003cc2:	449c                	lw	a5,8(s1)
    80003cc4:	fef059e3          	blez	a5,80003cb6 <iget+0x38>
    80003cc8:	4098                	lw	a4,0(s1)
    80003cca:	ff3716e3          	bne	a4,s3,80003cb6 <iget+0x38>
    80003cce:	40d8                	lw	a4,4(s1)
    80003cd0:	ff4713e3          	bne	a4,s4,80003cb6 <iget+0x38>
      ip->ref++;
    80003cd4:	2785                	addiw	a5,a5,1
    80003cd6:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003cd8:	00024517          	auipc	a0,0x24
    80003cdc:	0f050513          	addi	a0,a0,240 # 80027dc8 <itable>
    80003ce0:	ffffd097          	auipc	ra,0xffffd
    80003ce4:	f96080e7          	jalr	-106(ra) # 80000c76 <release>
      return ip;
    80003ce8:	8926                	mv	s2,s1
    80003cea:	a03d                	j	80003d18 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003cec:	f7f9                	bnez	a5,80003cba <iget+0x3c>
    80003cee:	8926                	mv	s2,s1
    80003cf0:	b7e9                	j	80003cba <iget+0x3c>
  if(empty == 0)
    80003cf2:	02090c63          	beqz	s2,80003d2a <iget+0xac>
  ip->dev = dev;
    80003cf6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003cfa:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003cfe:	4785                	li	a5,1
    80003d00:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003d04:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003d08:	00024517          	auipc	a0,0x24
    80003d0c:	0c050513          	addi	a0,a0,192 # 80027dc8 <itable>
    80003d10:	ffffd097          	auipc	ra,0xffffd
    80003d14:	f66080e7          	jalr	-154(ra) # 80000c76 <release>
}
    80003d18:	854a                	mv	a0,s2
    80003d1a:	70a2                	ld	ra,40(sp)
    80003d1c:	7402                	ld	s0,32(sp)
    80003d1e:	64e2                	ld	s1,24(sp)
    80003d20:	6942                	ld	s2,16(sp)
    80003d22:	69a2                	ld	s3,8(sp)
    80003d24:	6a02                	ld	s4,0(sp)
    80003d26:	6145                	addi	sp,sp,48
    80003d28:	8082                	ret
    panic("iget: no inodes");
    80003d2a:	00006517          	auipc	a0,0x6
    80003d2e:	c9650513          	addi	a0,a0,-874 # 800099c0 <syscalls+0x130>
    80003d32:	ffffc097          	auipc	ra,0xffffc
    80003d36:	7f8080e7          	jalr	2040(ra) # 8000052a <panic>

0000000080003d3a <fsinit>:
fsinit(int dev) {
    80003d3a:	7179                	addi	sp,sp,-48
    80003d3c:	f406                	sd	ra,40(sp)
    80003d3e:	f022                	sd	s0,32(sp)
    80003d40:	ec26                	sd	s1,24(sp)
    80003d42:	e84a                	sd	s2,16(sp)
    80003d44:	e44e                	sd	s3,8(sp)
    80003d46:	1800                	addi	s0,sp,48
    80003d48:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003d4a:	4585                	li	a1,1
    80003d4c:	00000097          	auipc	ra,0x0
    80003d50:	a62080e7          	jalr	-1438(ra) # 800037ae <bread>
    80003d54:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003d56:	00024997          	auipc	s3,0x24
    80003d5a:	05298993          	addi	s3,s3,82 # 80027da8 <sb>
    80003d5e:	02000613          	li	a2,32
    80003d62:	05850593          	addi	a1,a0,88
    80003d66:	854e                	mv	a0,s3
    80003d68:	ffffd097          	auipc	ra,0xffffd
    80003d6c:	fb2080e7          	jalr	-78(ra) # 80000d1a <memmove>
  brelse(bp);
    80003d70:	8526                	mv	a0,s1
    80003d72:	00000097          	auipc	ra,0x0
    80003d76:	b6c080e7          	jalr	-1172(ra) # 800038de <brelse>
  if(sb.magic != FSMAGIC)
    80003d7a:	0009a703          	lw	a4,0(s3)
    80003d7e:	102037b7          	lui	a5,0x10203
    80003d82:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003d86:	02f71263          	bne	a4,a5,80003daa <fsinit+0x70>
  initlog(dev, &sb);
    80003d8a:	00024597          	auipc	a1,0x24
    80003d8e:	01e58593          	addi	a1,a1,30 # 80027da8 <sb>
    80003d92:	854a                	mv	a0,s2
    80003d94:	00001097          	auipc	ra,0x1
    80003d98:	e60080e7          	jalr	-416(ra) # 80004bf4 <initlog>
}
    80003d9c:	70a2                	ld	ra,40(sp)
    80003d9e:	7402                	ld	s0,32(sp)
    80003da0:	64e2                	ld	s1,24(sp)
    80003da2:	6942                	ld	s2,16(sp)
    80003da4:	69a2                	ld	s3,8(sp)
    80003da6:	6145                	addi	sp,sp,48
    80003da8:	8082                	ret
    panic("invalid file system");
    80003daa:	00006517          	auipc	a0,0x6
    80003dae:	c2650513          	addi	a0,a0,-986 # 800099d0 <syscalls+0x140>
    80003db2:	ffffc097          	auipc	ra,0xffffc
    80003db6:	778080e7          	jalr	1912(ra) # 8000052a <panic>

0000000080003dba <iinit>:
{
    80003dba:	7179                	addi	sp,sp,-48
    80003dbc:	f406                	sd	ra,40(sp)
    80003dbe:	f022                	sd	s0,32(sp)
    80003dc0:	ec26                	sd	s1,24(sp)
    80003dc2:	e84a                	sd	s2,16(sp)
    80003dc4:	e44e                	sd	s3,8(sp)
    80003dc6:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003dc8:	00006597          	auipc	a1,0x6
    80003dcc:	c2058593          	addi	a1,a1,-992 # 800099e8 <syscalls+0x158>
    80003dd0:	00024517          	auipc	a0,0x24
    80003dd4:	ff850513          	addi	a0,a0,-8 # 80027dc8 <itable>
    80003dd8:	ffffd097          	auipc	ra,0xffffd
    80003ddc:	d5a080e7          	jalr	-678(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003de0:	00024497          	auipc	s1,0x24
    80003de4:	01048493          	addi	s1,s1,16 # 80027df0 <itable+0x28>
    80003de8:	00026997          	auipc	s3,0x26
    80003dec:	a9898993          	addi	s3,s3,-1384 # 80029880 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003df0:	00006917          	auipc	s2,0x6
    80003df4:	c0090913          	addi	s2,s2,-1024 # 800099f0 <syscalls+0x160>
    80003df8:	85ca                	mv	a1,s2
    80003dfa:	8526                	mv	a0,s1
    80003dfc:	00001097          	auipc	ra,0x1
    80003e00:	15c080e7          	jalr	348(ra) # 80004f58 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003e04:	08848493          	addi	s1,s1,136
    80003e08:	ff3498e3          	bne	s1,s3,80003df8 <iinit+0x3e>
}
    80003e0c:	70a2                	ld	ra,40(sp)
    80003e0e:	7402                	ld	s0,32(sp)
    80003e10:	64e2                	ld	s1,24(sp)
    80003e12:	6942                	ld	s2,16(sp)
    80003e14:	69a2                	ld	s3,8(sp)
    80003e16:	6145                	addi	sp,sp,48
    80003e18:	8082                	ret

0000000080003e1a <ialloc>:
{
    80003e1a:	715d                	addi	sp,sp,-80
    80003e1c:	e486                	sd	ra,72(sp)
    80003e1e:	e0a2                	sd	s0,64(sp)
    80003e20:	fc26                	sd	s1,56(sp)
    80003e22:	f84a                	sd	s2,48(sp)
    80003e24:	f44e                	sd	s3,40(sp)
    80003e26:	f052                	sd	s4,32(sp)
    80003e28:	ec56                	sd	s5,24(sp)
    80003e2a:	e85a                	sd	s6,16(sp)
    80003e2c:	e45e                	sd	s7,8(sp)
    80003e2e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003e30:	00024717          	auipc	a4,0x24
    80003e34:	f8472703          	lw	a4,-124(a4) # 80027db4 <sb+0xc>
    80003e38:	4785                	li	a5,1
    80003e3a:	04e7fa63          	bgeu	a5,a4,80003e8e <ialloc+0x74>
    80003e3e:	8aaa                	mv	s5,a0
    80003e40:	8bae                	mv	s7,a1
    80003e42:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003e44:	00024a17          	auipc	s4,0x24
    80003e48:	f64a0a13          	addi	s4,s4,-156 # 80027da8 <sb>
    80003e4c:	00048b1b          	sext.w	s6,s1
    80003e50:	0044d793          	srli	a5,s1,0x4
    80003e54:	018a2583          	lw	a1,24(s4)
    80003e58:	9dbd                	addw	a1,a1,a5
    80003e5a:	8556                	mv	a0,s5
    80003e5c:	00000097          	auipc	ra,0x0
    80003e60:	952080e7          	jalr	-1710(ra) # 800037ae <bread>
    80003e64:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003e66:	05850993          	addi	s3,a0,88
    80003e6a:	00f4f793          	andi	a5,s1,15
    80003e6e:	079a                	slli	a5,a5,0x6
    80003e70:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003e72:	00099783          	lh	a5,0(s3)
    80003e76:	c785                	beqz	a5,80003e9e <ialloc+0x84>
    brelse(bp);
    80003e78:	00000097          	auipc	ra,0x0
    80003e7c:	a66080e7          	jalr	-1434(ra) # 800038de <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003e80:	0485                	addi	s1,s1,1
    80003e82:	00ca2703          	lw	a4,12(s4)
    80003e86:	0004879b          	sext.w	a5,s1
    80003e8a:	fce7e1e3          	bltu	a5,a4,80003e4c <ialloc+0x32>
  panic("ialloc: no inodes");
    80003e8e:	00006517          	auipc	a0,0x6
    80003e92:	b6a50513          	addi	a0,a0,-1174 # 800099f8 <syscalls+0x168>
    80003e96:	ffffc097          	auipc	ra,0xffffc
    80003e9a:	694080e7          	jalr	1684(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003e9e:	04000613          	li	a2,64
    80003ea2:	4581                	li	a1,0
    80003ea4:	854e                	mv	a0,s3
    80003ea6:	ffffd097          	auipc	ra,0xffffd
    80003eaa:	e18080e7          	jalr	-488(ra) # 80000cbe <memset>
      dip->type = type;
    80003eae:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003eb2:	854a                	mv	a0,s2
    80003eb4:	00001097          	auipc	ra,0x1
    80003eb8:	fbe080e7          	jalr	-66(ra) # 80004e72 <log_write>
      brelse(bp);
    80003ebc:	854a                	mv	a0,s2
    80003ebe:	00000097          	auipc	ra,0x0
    80003ec2:	a20080e7          	jalr	-1504(ra) # 800038de <brelse>
      return iget(dev, inum);
    80003ec6:	85da                	mv	a1,s6
    80003ec8:	8556                	mv	a0,s5
    80003eca:	00000097          	auipc	ra,0x0
    80003ece:	db4080e7          	jalr	-588(ra) # 80003c7e <iget>
}
    80003ed2:	60a6                	ld	ra,72(sp)
    80003ed4:	6406                	ld	s0,64(sp)
    80003ed6:	74e2                	ld	s1,56(sp)
    80003ed8:	7942                	ld	s2,48(sp)
    80003eda:	79a2                	ld	s3,40(sp)
    80003edc:	7a02                	ld	s4,32(sp)
    80003ede:	6ae2                	ld	s5,24(sp)
    80003ee0:	6b42                	ld	s6,16(sp)
    80003ee2:	6ba2                	ld	s7,8(sp)
    80003ee4:	6161                	addi	sp,sp,80
    80003ee6:	8082                	ret

0000000080003ee8 <iupdate>:
{
    80003ee8:	1101                	addi	sp,sp,-32
    80003eea:	ec06                	sd	ra,24(sp)
    80003eec:	e822                	sd	s0,16(sp)
    80003eee:	e426                	sd	s1,8(sp)
    80003ef0:	e04a                	sd	s2,0(sp)
    80003ef2:	1000                	addi	s0,sp,32
    80003ef4:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ef6:	415c                	lw	a5,4(a0)
    80003ef8:	0047d79b          	srliw	a5,a5,0x4
    80003efc:	00024597          	auipc	a1,0x24
    80003f00:	ec45a583          	lw	a1,-316(a1) # 80027dc0 <sb+0x18>
    80003f04:	9dbd                	addw	a1,a1,a5
    80003f06:	4108                	lw	a0,0(a0)
    80003f08:	00000097          	auipc	ra,0x0
    80003f0c:	8a6080e7          	jalr	-1882(ra) # 800037ae <bread>
    80003f10:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f12:	05850793          	addi	a5,a0,88
    80003f16:	40c8                	lw	a0,4(s1)
    80003f18:	893d                	andi	a0,a0,15
    80003f1a:	051a                	slli	a0,a0,0x6
    80003f1c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003f1e:	04449703          	lh	a4,68(s1)
    80003f22:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003f26:	04649703          	lh	a4,70(s1)
    80003f2a:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003f2e:	04849703          	lh	a4,72(s1)
    80003f32:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003f36:	04a49703          	lh	a4,74(s1)
    80003f3a:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003f3e:	44f8                	lw	a4,76(s1)
    80003f40:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003f42:	03400613          	li	a2,52
    80003f46:	05048593          	addi	a1,s1,80
    80003f4a:	0531                	addi	a0,a0,12
    80003f4c:	ffffd097          	auipc	ra,0xffffd
    80003f50:	dce080e7          	jalr	-562(ra) # 80000d1a <memmove>
  log_write(bp);
    80003f54:	854a                	mv	a0,s2
    80003f56:	00001097          	auipc	ra,0x1
    80003f5a:	f1c080e7          	jalr	-228(ra) # 80004e72 <log_write>
  brelse(bp);
    80003f5e:	854a                	mv	a0,s2
    80003f60:	00000097          	auipc	ra,0x0
    80003f64:	97e080e7          	jalr	-1666(ra) # 800038de <brelse>
}
    80003f68:	60e2                	ld	ra,24(sp)
    80003f6a:	6442                	ld	s0,16(sp)
    80003f6c:	64a2                	ld	s1,8(sp)
    80003f6e:	6902                	ld	s2,0(sp)
    80003f70:	6105                	addi	sp,sp,32
    80003f72:	8082                	ret

0000000080003f74 <idup>:
{
    80003f74:	1101                	addi	sp,sp,-32
    80003f76:	ec06                	sd	ra,24(sp)
    80003f78:	e822                	sd	s0,16(sp)
    80003f7a:	e426                	sd	s1,8(sp)
    80003f7c:	1000                	addi	s0,sp,32
    80003f7e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f80:	00024517          	auipc	a0,0x24
    80003f84:	e4850513          	addi	a0,a0,-440 # 80027dc8 <itable>
    80003f88:	ffffd097          	auipc	ra,0xffffd
    80003f8c:	c3a080e7          	jalr	-966(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003f90:	449c                	lw	a5,8(s1)
    80003f92:	2785                	addiw	a5,a5,1
    80003f94:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f96:	00024517          	auipc	a0,0x24
    80003f9a:	e3250513          	addi	a0,a0,-462 # 80027dc8 <itable>
    80003f9e:	ffffd097          	auipc	ra,0xffffd
    80003fa2:	cd8080e7          	jalr	-808(ra) # 80000c76 <release>
}
    80003fa6:	8526                	mv	a0,s1
    80003fa8:	60e2                	ld	ra,24(sp)
    80003faa:	6442                	ld	s0,16(sp)
    80003fac:	64a2                	ld	s1,8(sp)
    80003fae:	6105                	addi	sp,sp,32
    80003fb0:	8082                	ret

0000000080003fb2 <ilock>:
{
    80003fb2:	1101                	addi	sp,sp,-32
    80003fb4:	ec06                	sd	ra,24(sp)
    80003fb6:	e822                	sd	s0,16(sp)
    80003fb8:	e426                	sd	s1,8(sp)
    80003fba:	e04a                	sd	s2,0(sp)
    80003fbc:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003fbe:	c115                	beqz	a0,80003fe2 <ilock+0x30>
    80003fc0:	84aa                	mv	s1,a0
    80003fc2:	451c                	lw	a5,8(a0)
    80003fc4:	00f05f63          	blez	a5,80003fe2 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003fc8:	0541                	addi	a0,a0,16
    80003fca:	00001097          	auipc	ra,0x1
    80003fce:	fc8080e7          	jalr	-56(ra) # 80004f92 <acquiresleep>
  if(ip->valid == 0){
    80003fd2:	40bc                	lw	a5,64(s1)
    80003fd4:	cf99                	beqz	a5,80003ff2 <ilock+0x40>
}
    80003fd6:	60e2                	ld	ra,24(sp)
    80003fd8:	6442                	ld	s0,16(sp)
    80003fda:	64a2                	ld	s1,8(sp)
    80003fdc:	6902                	ld	s2,0(sp)
    80003fde:	6105                	addi	sp,sp,32
    80003fe0:	8082                	ret
    panic("ilock");
    80003fe2:	00006517          	auipc	a0,0x6
    80003fe6:	a2e50513          	addi	a0,a0,-1490 # 80009a10 <syscalls+0x180>
    80003fea:	ffffc097          	auipc	ra,0xffffc
    80003fee:	540080e7          	jalr	1344(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ff2:	40dc                	lw	a5,4(s1)
    80003ff4:	0047d79b          	srliw	a5,a5,0x4
    80003ff8:	00024597          	auipc	a1,0x24
    80003ffc:	dc85a583          	lw	a1,-568(a1) # 80027dc0 <sb+0x18>
    80004000:	9dbd                	addw	a1,a1,a5
    80004002:	4088                	lw	a0,0(s1)
    80004004:	fffff097          	auipc	ra,0xfffff
    80004008:	7aa080e7          	jalr	1962(ra) # 800037ae <bread>
    8000400c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000400e:	05850593          	addi	a1,a0,88
    80004012:	40dc                	lw	a5,4(s1)
    80004014:	8bbd                	andi	a5,a5,15
    80004016:	079a                	slli	a5,a5,0x6
    80004018:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000401a:	00059783          	lh	a5,0(a1)
    8000401e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004022:	00259783          	lh	a5,2(a1)
    80004026:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000402a:	00459783          	lh	a5,4(a1)
    8000402e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004032:	00659783          	lh	a5,6(a1)
    80004036:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000403a:	459c                	lw	a5,8(a1)
    8000403c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000403e:	03400613          	li	a2,52
    80004042:	05b1                	addi	a1,a1,12
    80004044:	05048513          	addi	a0,s1,80
    80004048:	ffffd097          	auipc	ra,0xffffd
    8000404c:	cd2080e7          	jalr	-814(ra) # 80000d1a <memmove>
    brelse(bp);
    80004050:	854a                	mv	a0,s2
    80004052:	00000097          	auipc	ra,0x0
    80004056:	88c080e7          	jalr	-1908(ra) # 800038de <brelse>
    ip->valid = 1;
    8000405a:	4785                	li	a5,1
    8000405c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000405e:	04449783          	lh	a5,68(s1)
    80004062:	fbb5                	bnez	a5,80003fd6 <ilock+0x24>
      panic("ilock: no type");
    80004064:	00006517          	auipc	a0,0x6
    80004068:	9b450513          	addi	a0,a0,-1612 # 80009a18 <syscalls+0x188>
    8000406c:	ffffc097          	auipc	ra,0xffffc
    80004070:	4be080e7          	jalr	1214(ra) # 8000052a <panic>

0000000080004074 <iunlock>:
{
    80004074:	1101                	addi	sp,sp,-32
    80004076:	ec06                	sd	ra,24(sp)
    80004078:	e822                	sd	s0,16(sp)
    8000407a:	e426                	sd	s1,8(sp)
    8000407c:	e04a                	sd	s2,0(sp)
    8000407e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004080:	c905                	beqz	a0,800040b0 <iunlock+0x3c>
    80004082:	84aa                	mv	s1,a0
    80004084:	01050913          	addi	s2,a0,16
    80004088:	854a                	mv	a0,s2
    8000408a:	00001097          	auipc	ra,0x1
    8000408e:	fa2080e7          	jalr	-94(ra) # 8000502c <holdingsleep>
    80004092:	cd19                	beqz	a0,800040b0 <iunlock+0x3c>
    80004094:	449c                	lw	a5,8(s1)
    80004096:	00f05d63          	blez	a5,800040b0 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000409a:	854a                	mv	a0,s2
    8000409c:	00001097          	auipc	ra,0x1
    800040a0:	f4c080e7          	jalr	-180(ra) # 80004fe8 <releasesleep>
}
    800040a4:	60e2                	ld	ra,24(sp)
    800040a6:	6442                	ld	s0,16(sp)
    800040a8:	64a2                	ld	s1,8(sp)
    800040aa:	6902                	ld	s2,0(sp)
    800040ac:	6105                	addi	sp,sp,32
    800040ae:	8082                	ret
    panic("iunlock");
    800040b0:	00006517          	auipc	a0,0x6
    800040b4:	97850513          	addi	a0,a0,-1672 # 80009a28 <syscalls+0x198>
    800040b8:	ffffc097          	auipc	ra,0xffffc
    800040bc:	472080e7          	jalr	1138(ra) # 8000052a <panic>

00000000800040c0 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800040c0:	7179                	addi	sp,sp,-48
    800040c2:	f406                	sd	ra,40(sp)
    800040c4:	f022                	sd	s0,32(sp)
    800040c6:	ec26                	sd	s1,24(sp)
    800040c8:	e84a                	sd	s2,16(sp)
    800040ca:	e44e                	sd	s3,8(sp)
    800040cc:	e052                	sd	s4,0(sp)
    800040ce:	1800                	addi	s0,sp,48
    800040d0:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800040d2:	05050493          	addi	s1,a0,80
    800040d6:	08050913          	addi	s2,a0,128
    800040da:	a021                	j	800040e2 <itrunc+0x22>
    800040dc:	0491                	addi	s1,s1,4
    800040de:	01248d63          	beq	s1,s2,800040f8 <itrunc+0x38>
    if(ip->addrs[i]){
    800040e2:	408c                	lw	a1,0(s1)
    800040e4:	dde5                	beqz	a1,800040dc <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800040e6:	0009a503          	lw	a0,0(s3)
    800040ea:	00000097          	auipc	ra,0x0
    800040ee:	90a080e7          	jalr	-1782(ra) # 800039f4 <bfree>
      ip->addrs[i] = 0;
    800040f2:	0004a023          	sw	zero,0(s1)
    800040f6:	b7dd                	j	800040dc <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800040f8:	0809a583          	lw	a1,128(s3)
    800040fc:	e185                	bnez	a1,8000411c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800040fe:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004102:	854e                	mv	a0,s3
    80004104:	00000097          	auipc	ra,0x0
    80004108:	de4080e7          	jalr	-540(ra) # 80003ee8 <iupdate>
}
    8000410c:	70a2                	ld	ra,40(sp)
    8000410e:	7402                	ld	s0,32(sp)
    80004110:	64e2                	ld	s1,24(sp)
    80004112:	6942                	ld	s2,16(sp)
    80004114:	69a2                	ld	s3,8(sp)
    80004116:	6a02                	ld	s4,0(sp)
    80004118:	6145                	addi	sp,sp,48
    8000411a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000411c:	0009a503          	lw	a0,0(s3)
    80004120:	fffff097          	auipc	ra,0xfffff
    80004124:	68e080e7          	jalr	1678(ra) # 800037ae <bread>
    80004128:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000412a:	05850493          	addi	s1,a0,88
    8000412e:	45850913          	addi	s2,a0,1112
    80004132:	a021                	j	8000413a <itrunc+0x7a>
    80004134:	0491                	addi	s1,s1,4
    80004136:	01248b63          	beq	s1,s2,8000414c <itrunc+0x8c>
      if(a[j])
    8000413a:	408c                	lw	a1,0(s1)
    8000413c:	dde5                	beqz	a1,80004134 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000413e:	0009a503          	lw	a0,0(s3)
    80004142:	00000097          	auipc	ra,0x0
    80004146:	8b2080e7          	jalr	-1870(ra) # 800039f4 <bfree>
    8000414a:	b7ed                	j	80004134 <itrunc+0x74>
    brelse(bp);
    8000414c:	8552                	mv	a0,s4
    8000414e:	fffff097          	auipc	ra,0xfffff
    80004152:	790080e7          	jalr	1936(ra) # 800038de <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004156:	0809a583          	lw	a1,128(s3)
    8000415a:	0009a503          	lw	a0,0(s3)
    8000415e:	00000097          	auipc	ra,0x0
    80004162:	896080e7          	jalr	-1898(ra) # 800039f4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004166:	0809a023          	sw	zero,128(s3)
    8000416a:	bf51                	j	800040fe <itrunc+0x3e>

000000008000416c <iput>:
{
    8000416c:	1101                	addi	sp,sp,-32
    8000416e:	ec06                	sd	ra,24(sp)
    80004170:	e822                	sd	s0,16(sp)
    80004172:	e426                	sd	s1,8(sp)
    80004174:	e04a                	sd	s2,0(sp)
    80004176:	1000                	addi	s0,sp,32
    80004178:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000417a:	00024517          	auipc	a0,0x24
    8000417e:	c4e50513          	addi	a0,a0,-946 # 80027dc8 <itable>
    80004182:	ffffd097          	auipc	ra,0xffffd
    80004186:	a40080e7          	jalr	-1472(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000418a:	4498                	lw	a4,8(s1)
    8000418c:	4785                	li	a5,1
    8000418e:	02f70363          	beq	a4,a5,800041b4 <iput+0x48>
  ip->ref--;
    80004192:	449c                	lw	a5,8(s1)
    80004194:	37fd                	addiw	a5,a5,-1
    80004196:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004198:	00024517          	auipc	a0,0x24
    8000419c:	c3050513          	addi	a0,a0,-976 # 80027dc8 <itable>
    800041a0:	ffffd097          	auipc	ra,0xffffd
    800041a4:	ad6080e7          	jalr	-1322(ra) # 80000c76 <release>
}
    800041a8:	60e2                	ld	ra,24(sp)
    800041aa:	6442                	ld	s0,16(sp)
    800041ac:	64a2                	ld	s1,8(sp)
    800041ae:	6902                	ld	s2,0(sp)
    800041b0:	6105                	addi	sp,sp,32
    800041b2:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800041b4:	40bc                	lw	a5,64(s1)
    800041b6:	dff1                	beqz	a5,80004192 <iput+0x26>
    800041b8:	04a49783          	lh	a5,74(s1)
    800041bc:	fbf9                	bnez	a5,80004192 <iput+0x26>
    acquiresleep(&ip->lock);
    800041be:	01048913          	addi	s2,s1,16
    800041c2:	854a                	mv	a0,s2
    800041c4:	00001097          	auipc	ra,0x1
    800041c8:	dce080e7          	jalr	-562(ra) # 80004f92 <acquiresleep>
    release(&itable.lock);
    800041cc:	00024517          	auipc	a0,0x24
    800041d0:	bfc50513          	addi	a0,a0,-1028 # 80027dc8 <itable>
    800041d4:	ffffd097          	auipc	ra,0xffffd
    800041d8:	aa2080e7          	jalr	-1374(ra) # 80000c76 <release>
    itrunc(ip);
    800041dc:	8526                	mv	a0,s1
    800041de:	00000097          	auipc	ra,0x0
    800041e2:	ee2080e7          	jalr	-286(ra) # 800040c0 <itrunc>
    ip->type = 0;
    800041e6:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800041ea:	8526                	mv	a0,s1
    800041ec:	00000097          	auipc	ra,0x0
    800041f0:	cfc080e7          	jalr	-772(ra) # 80003ee8 <iupdate>
    ip->valid = 0;
    800041f4:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800041f8:	854a                	mv	a0,s2
    800041fa:	00001097          	auipc	ra,0x1
    800041fe:	dee080e7          	jalr	-530(ra) # 80004fe8 <releasesleep>
    acquire(&itable.lock);
    80004202:	00024517          	auipc	a0,0x24
    80004206:	bc650513          	addi	a0,a0,-1082 # 80027dc8 <itable>
    8000420a:	ffffd097          	auipc	ra,0xffffd
    8000420e:	9b8080e7          	jalr	-1608(ra) # 80000bc2 <acquire>
    80004212:	b741                	j	80004192 <iput+0x26>

0000000080004214 <iunlockput>:
{
    80004214:	1101                	addi	sp,sp,-32
    80004216:	ec06                	sd	ra,24(sp)
    80004218:	e822                	sd	s0,16(sp)
    8000421a:	e426                	sd	s1,8(sp)
    8000421c:	1000                	addi	s0,sp,32
    8000421e:	84aa                	mv	s1,a0
  iunlock(ip);
    80004220:	00000097          	auipc	ra,0x0
    80004224:	e54080e7          	jalr	-428(ra) # 80004074 <iunlock>
  iput(ip);
    80004228:	8526                	mv	a0,s1
    8000422a:	00000097          	auipc	ra,0x0
    8000422e:	f42080e7          	jalr	-190(ra) # 8000416c <iput>
}
    80004232:	60e2                	ld	ra,24(sp)
    80004234:	6442                	ld	s0,16(sp)
    80004236:	64a2                	ld	s1,8(sp)
    80004238:	6105                	addi	sp,sp,32
    8000423a:	8082                	ret

000000008000423c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000423c:	1141                	addi	sp,sp,-16
    8000423e:	e422                	sd	s0,8(sp)
    80004240:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004242:	411c                	lw	a5,0(a0)
    80004244:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004246:	415c                	lw	a5,4(a0)
    80004248:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000424a:	04451783          	lh	a5,68(a0)
    8000424e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004252:	04a51783          	lh	a5,74(a0)
    80004256:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000425a:	04c56783          	lwu	a5,76(a0)
    8000425e:	e99c                	sd	a5,16(a1)
}
    80004260:	6422                	ld	s0,8(sp)
    80004262:	0141                	addi	sp,sp,16
    80004264:	8082                	ret

0000000080004266 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004266:	457c                	lw	a5,76(a0)
    80004268:	0ed7e963          	bltu	a5,a3,8000435a <readi+0xf4>
{
    8000426c:	7159                	addi	sp,sp,-112
    8000426e:	f486                	sd	ra,104(sp)
    80004270:	f0a2                	sd	s0,96(sp)
    80004272:	eca6                	sd	s1,88(sp)
    80004274:	e8ca                	sd	s2,80(sp)
    80004276:	e4ce                	sd	s3,72(sp)
    80004278:	e0d2                	sd	s4,64(sp)
    8000427a:	fc56                	sd	s5,56(sp)
    8000427c:	f85a                	sd	s6,48(sp)
    8000427e:	f45e                	sd	s7,40(sp)
    80004280:	f062                	sd	s8,32(sp)
    80004282:	ec66                	sd	s9,24(sp)
    80004284:	e86a                	sd	s10,16(sp)
    80004286:	e46e                	sd	s11,8(sp)
    80004288:	1880                	addi	s0,sp,112
    8000428a:	8baa                	mv	s7,a0
    8000428c:	8c2e                	mv	s8,a1
    8000428e:	8ab2                	mv	s5,a2
    80004290:	84b6                	mv	s1,a3
    80004292:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004294:	9f35                	addw	a4,a4,a3
    return 0;
    80004296:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004298:	0ad76063          	bltu	a4,a3,80004338 <readi+0xd2>
  if(off + n > ip->size)
    8000429c:	00e7f463          	bgeu	a5,a4,800042a4 <readi+0x3e>
    n = ip->size - off;
    800042a0:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800042a4:	0a0b0963          	beqz	s6,80004356 <readi+0xf0>
    800042a8:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800042aa:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800042ae:	5cfd                	li	s9,-1
    800042b0:	a82d                	j	800042ea <readi+0x84>
    800042b2:	020a1d93          	slli	s11,s4,0x20
    800042b6:	020ddd93          	srli	s11,s11,0x20
    800042ba:	05890793          	addi	a5,s2,88
    800042be:	86ee                	mv	a3,s11
    800042c0:	963e                	add	a2,a2,a5
    800042c2:	85d6                	mv	a1,s5
    800042c4:	8562                	mv	a0,s8
    800042c6:	fffff097          	auipc	ra,0xfffff
    800042ca:	af4080e7          	jalr	-1292(ra) # 80002dba <either_copyout>
    800042ce:	05950d63          	beq	a0,s9,80004328 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800042d2:	854a                	mv	a0,s2
    800042d4:	fffff097          	auipc	ra,0xfffff
    800042d8:	60a080e7          	jalr	1546(ra) # 800038de <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800042dc:	013a09bb          	addw	s3,s4,s3
    800042e0:	009a04bb          	addw	s1,s4,s1
    800042e4:	9aee                	add	s5,s5,s11
    800042e6:	0569f763          	bgeu	s3,s6,80004334 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800042ea:	000ba903          	lw	s2,0(s7)
    800042ee:	00a4d59b          	srliw	a1,s1,0xa
    800042f2:	855e                	mv	a0,s7
    800042f4:	00000097          	auipc	ra,0x0
    800042f8:	8ae080e7          	jalr	-1874(ra) # 80003ba2 <bmap>
    800042fc:	0005059b          	sext.w	a1,a0
    80004300:	854a                	mv	a0,s2
    80004302:	fffff097          	auipc	ra,0xfffff
    80004306:	4ac080e7          	jalr	1196(ra) # 800037ae <bread>
    8000430a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000430c:	3ff4f613          	andi	a2,s1,1023
    80004310:	40cd07bb          	subw	a5,s10,a2
    80004314:	413b073b          	subw	a4,s6,s3
    80004318:	8a3e                	mv	s4,a5
    8000431a:	2781                	sext.w	a5,a5
    8000431c:	0007069b          	sext.w	a3,a4
    80004320:	f8f6f9e3          	bgeu	a3,a5,800042b2 <readi+0x4c>
    80004324:	8a3a                	mv	s4,a4
    80004326:	b771                	j	800042b2 <readi+0x4c>
      brelse(bp);
    80004328:	854a                	mv	a0,s2
    8000432a:	fffff097          	auipc	ra,0xfffff
    8000432e:	5b4080e7          	jalr	1460(ra) # 800038de <brelse>
      tot = -1;
    80004332:	59fd                	li	s3,-1
  }
  return tot;
    80004334:	0009851b          	sext.w	a0,s3
}
    80004338:	70a6                	ld	ra,104(sp)
    8000433a:	7406                	ld	s0,96(sp)
    8000433c:	64e6                	ld	s1,88(sp)
    8000433e:	6946                	ld	s2,80(sp)
    80004340:	69a6                	ld	s3,72(sp)
    80004342:	6a06                	ld	s4,64(sp)
    80004344:	7ae2                	ld	s5,56(sp)
    80004346:	7b42                	ld	s6,48(sp)
    80004348:	7ba2                	ld	s7,40(sp)
    8000434a:	7c02                	ld	s8,32(sp)
    8000434c:	6ce2                	ld	s9,24(sp)
    8000434e:	6d42                	ld	s10,16(sp)
    80004350:	6da2                	ld	s11,8(sp)
    80004352:	6165                	addi	sp,sp,112
    80004354:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004356:	89da                	mv	s3,s6
    80004358:	bff1                	j	80004334 <readi+0xce>
    return 0;
    8000435a:	4501                	li	a0,0
}
    8000435c:	8082                	ret

000000008000435e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000435e:	457c                	lw	a5,76(a0)
    80004360:	10d7e863          	bltu	a5,a3,80004470 <writei+0x112>
{
    80004364:	7159                	addi	sp,sp,-112
    80004366:	f486                	sd	ra,104(sp)
    80004368:	f0a2                	sd	s0,96(sp)
    8000436a:	eca6                	sd	s1,88(sp)
    8000436c:	e8ca                	sd	s2,80(sp)
    8000436e:	e4ce                	sd	s3,72(sp)
    80004370:	e0d2                	sd	s4,64(sp)
    80004372:	fc56                	sd	s5,56(sp)
    80004374:	f85a                	sd	s6,48(sp)
    80004376:	f45e                	sd	s7,40(sp)
    80004378:	f062                	sd	s8,32(sp)
    8000437a:	ec66                	sd	s9,24(sp)
    8000437c:	e86a                	sd	s10,16(sp)
    8000437e:	e46e                	sd	s11,8(sp)
    80004380:	1880                	addi	s0,sp,112
    80004382:	8b2a                	mv	s6,a0
    80004384:	8c2e                	mv	s8,a1
    80004386:	8ab2                	mv	s5,a2
    80004388:	8936                	mv	s2,a3
    8000438a:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000438c:	00e687bb          	addw	a5,a3,a4
    80004390:	0ed7e263          	bltu	a5,a3,80004474 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004394:	00043737          	lui	a4,0x43
    80004398:	0ef76063          	bltu	a4,a5,80004478 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000439c:	0c0b8863          	beqz	s7,8000446c <writei+0x10e>
    800043a0:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800043a2:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800043a6:	5cfd                	li	s9,-1
    800043a8:	a091                	j	800043ec <writei+0x8e>
    800043aa:	02099d93          	slli	s11,s3,0x20
    800043ae:	020ddd93          	srli	s11,s11,0x20
    800043b2:	05848793          	addi	a5,s1,88
    800043b6:	86ee                	mv	a3,s11
    800043b8:	8656                	mv	a2,s5
    800043ba:	85e2                	mv	a1,s8
    800043bc:	953e                	add	a0,a0,a5
    800043be:	fffff097          	auipc	ra,0xfffff
    800043c2:	a52080e7          	jalr	-1454(ra) # 80002e10 <either_copyin>
    800043c6:	07950263          	beq	a0,s9,8000442a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800043ca:	8526                	mv	a0,s1
    800043cc:	00001097          	auipc	ra,0x1
    800043d0:	aa6080e7          	jalr	-1370(ra) # 80004e72 <log_write>
    brelse(bp);
    800043d4:	8526                	mv	a0,s1
    800043d6:	fffff097          	auipc	ra,0xfffff
    800043da:	508080e7          	jalr	1288(ra) # 800038de <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043de:	01498a3b          	addw	s4,s3,s4
    800043e2:	0129893b          	addw	s2,s3,s2
    800043e6:	9aee                	add	s5,s5,s11
    800043e8:	057a7663          	bgeu	s4,s7,80004434 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800043ec:	000b2483          	lw	s1,0(s6)
    800043f0:	00a9559b          	srliw	a1,s2,0xa
    800043f4:	855a                	mv	a0,s6
    800043f6:	fffff097          	auipc	ra,0xfffff
    800043fa:	7ac080e7          	jalr	1964(ra) # 80003ba2 <bmap>
    800043fe:	0005059b          	sext.w	a1,a0
    80004402:	8526                	mv	a0,s1
    80004404:	fffff097          	auipc	ra,0xfffff
    80004408:	3aa080e7          	jalr	938(ra) # 800037ae <bread>
    8000440c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000440e:	3ff97513          	andi	a0,s2,1023
    80004412:	40ad07bb          	subw	a5,s10,a0
    80004416:	414b873b          	subw	a4,s7,s4
    8000441a:	89be                	mv	s3,a5
    8000441c:	2781                	sext.w	a5,a5
    8000441e:	0007069b          	sext.w	a3,a4
    80004422:	f8f6f4e3          	bgeu	a3,a5,800043aa <writei+0x4c>
    80004426:	89ba                	mv	s3,a4
    80004428:	b749                	j	800043aa <writei+0x4c>
      brelse(bp);
    8000442a:	8526                	mv	a0,s1
    8000442c:	fffff097          	auipc	ra,0xfffff
    80004430:	4b2080e7          	jalr	1202(ra) # 800038de <brelse>
  }

  if(off > ip->size)
    80004434:	04cb2783          	lw	a5,76(s6)
    80004438:	0127f463          	bgeu	a5,s2,80004440 <writei+0xe2>
    ip->size = off;
    8000443c:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004440:	855a                	mv	a0,s6
    80004442:	00000097          	auipc	ra,0x0
    80004446:	aa6080e7          	jalr	-1370(ra) # 80003ee8 <iupdate>

  return tot;
    8000444a:	000a051b          	sext.w	a0,s4
}
    8000444e:	70a6                	ld	ra,104(sp)
    80004450:	7406                	ld	s0,96(sp)
    80004452:	64e6                	ld	s1,88(sp)
    80004454:	6946                	ld	s2,80(sp)
    80004456:	69a6                	ld	s3,72(sp)
    80004458:	6a06                	ld	s4,64(sp)
    8000445a:	7ae2                	ld	s5,56(sp)
    8000445c:	7b42                	ld	s6,48(sp)
    8000445e:	7ba2                	ld	s7,40(sp)
    80004460:	7c02                	ld	s8,32(sp)
    80004462:	6ce2                	ld	s9,24(sp)
    80004464:	6d42                	ld	s10,16(sp)
    80004466:	6da2                	ld	s11,8(sp)
    80004468:	6165                	addi	sp,sp,112
    8000446a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000446c:	8a5e                	mv	s4,s7
    8000446e:	bfc9                	j	80004440 <writei+0xe2>
    return -1;
    80004470:	557d                	li	a0,-1
}
    80004472:	8082                	ret
    return -1;
    80004474:	557d                	li	a0,-1
    80004476:	bfe1                	j	8000444e <writei+0xf0>
    return -1;
    80004478:	557d                	li	a0,-1
    8000447a:	bfd1                	j	8000444e <writei+0xf0>

000000008000447c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000447c:	1141                	addi	sp,sp,-16
    8000447e:	e406                	sd	ra,8(sp)
    80004480:	e022                	sd	s0,0(sp)
    80004482:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004484:	4639                	li	a2,14
    80004486:	ffffd097          	auipc	ra,0xffffd
    8000448a:	910080e7          	jalr	-1776(ra) # 80000d96 <strncmp>
}
    8000448e:	60a2                	ld	ra,8(sp)
    80004490:	6402                	ld	s0,0(sp)
    80004492:	0141                	addi	sp,sp,16
    80004494:	8082                	ret

0000000080004496 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004496:	7139                	addi	sp,sp,-64
    80004498:	fc06                	sd	ra,56(sp)
    8000449a:	f822                	sd	s0,48(sp)
    8000449c:	f426                	sd	s1,40(sp)
    8000449e:	f04a                	sd	s2,32(sp)
    800044a0:	ec4e                	sd	s3,24(sp)
    800044a2:	e852                	sd	s4,16(sp)
    800044a4:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800044a6:	04451703          	lh	a4,68(a0)
    800044aa:	4785                	li	a5,1
    800044ac:	00f71a63          	bne	a4,a5,800044c0 <dirlookup+0x2a>
    800044b0:	892a                	mv	s2,a0
    800044b2:	89ae                	mv	s3,a1
    800044b4:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800044b6:	457c                	lw	a5,76(a0)
    800044b8:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800044ba:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044bc:	e79d                	bnez	a5,800044ea <dirlookup+0x54>
    800044be:	a8a5                	j	80004536 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800044c0:	00005517          	auipc	a0,0x5
    800044c4:	57050513          	addi	a0,a0,1392 # 80009a30 <syscalls+0x1a0>
    800044c8:	ffffc097          	auipc	ra,0xffffc
    800044cc:	062080e7          	jalr	98(ra) # 8000052a <panic>
      panic("dirlookup read");
    800044d0:	00005517          	auipc	a0,0x5
    800044d4:	57850513          	addi	a0,a0,1400 # 80009a48 <syscalls+0x1b8>
    800044d8:	ffffc097          	auipc	ra,0xffffc
    800044dc:	052080e7          	jalr	82(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044e0:	24c1                	addiw	s1,s1,16
    800044e2:	04c92783          	lw	a5,76(s2)
    800044e6:	04f4f763          	bgeu	s1,a5,80004534 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044ea:	4741                	li	a4,16
    800044ec:	86a6                	mv	a3,s1
    800044ee:	fc040613          	addi	a2,s0,-64
    800044f2:	4581                	li	a1,0
    800044f4:	854a                	mv	a0,s2
    800044f6:	00000097          	auipc	ra,0x0
    800044fa:	d70080e7          	jalr	-656(ra) # 80004266 <readi>
    800044fe:	47c1                	li	a5,16
    80004500:	fcf518e3          	bne	a0,a5,800044d0 <dirlookup+0x3a>
    if(de.inum == 0)
    80004504:	fc045783          	lhu	a5,-64(s0)
    80004508:	dfe1                	beqz	a5,800044e0 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000450a:	fc240593          	addi	a1,s0,-62
    8000450e:	854e                	mv	a0,s3
    80004510:	00000097          	auipc	ra,0x0
    80004514:	f6c080e7          	jalr	-148(ra) # 8000447c <namecmp>
    80004518:	f561                	bnez	a0,800044e0 <dirlookup+0x4a>
      if(poff)
    8000451a:	000a0463          	beqz	s4,80004522 <dirlookup+0x8c>
        *poff = off;
    8000451e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004522:	fc045583          	lhu	a1,-64(s0)
    80004526:	00092503          	lw	a0,0(s2)
    8000452a:	fffff097          	auipc	ra,0xfffff
    8000452e:	754080e7          	jalr	1876(ra) # 80003c7e <iget>
    80004532:	a011                	j	80004536 <dirlookup+0xa0>
  return 0;
    80004534:	4501                	li	a0,0
}
    80004536:	70e2                	ld	ra,56(sp)
    80004538:	7442                	ld	s0,48(sp)
    8000453a:	74a2                	ld	s1,40(sp)
    8000453c:	7902                	ld	s2,32(sp)
    8000453e:	69e2                	ld	s3,24(sp)
    80004540:	6a42                	ld	s4,16(sp)
    80004542:	6121                	addi	sp,sp,64
    80004544:	8082                	ret

0000000080004546 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004546:	711d                	addi	sp,sp,-96
    80004548:	ec86                	sd	ra,88(sp)
    8000454a:	e8a2                	sd	s0,80(sp)
    8000454c:	e4a6                	sd	s1,72(sp)
    8000454e:	e0ca                	sd	s2,64(sp)
    80004550:	fc4e                	sd	s3,56(sp)
    80004552:	f852                	sd	s4,48(sp)
    80004554:	f456                	sd	s5,40(sp)
    80004556:	f05a                	sd	s6,32(sp)
    80004558:	ec5e                	sd	s7,24(sp)
    8000455a:	e862                	sd	s8,16(sp)
    8000455c:	e466                	sd	s9,8(sp)
    8000455e:	1080                	addi	s0,sp,96
    80004560:	84aa                	mv	s1,a0
    80004562:	8aae                	mv	s5,a1
    80004564:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004566:	00054703          	lbu	a4,0(a0)
    8000456a:	02f00793          	li	a5,47
    8000456e:	02f70363          	beq	a4,a5,80004594 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004572:	ffffe097          	auipc	ra,0xffffe
    80004576:	c92080e7          	jalr	-878(ra) # 80002204 <myproc>
    8000457a:	15053503          	ld	a0,336(a0)
    8000457e:	00000097          	auipc	ra,0x0
    80004582:	9f6080e7          	jalr	-1546(ra) # 80003f74 <idup>
    80004586:	89aa                	mv	s3,a0
  while(*path == '/')
    80004588:	02f00913          	li	s2,47
  len = path - s;
    8000458c:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    8000458e:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004590:	4b85                	li	s7,1
    80004592:	a865                	j	8000464a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004594:	4585                	li	a1,1
    80004596:	4505                	li	a0,1
    80004598:	fffff097          	auipc	ra,0xfffff
    8000459c:	6e6080e7          	jalr	1766(ra) # 80003c7e <iget>
    800045a0:	89aa                	mv	s3,a0
    800045a2:	b7dd                	j	80004588 <namex+0x42>
      iunlockput(ip);
    800045a4:	854e                	mv	a0,s3
    800045a6:	00000097          	auipc	ra,0x0
    800045aa:	c6e080e7          	jalr	-914(ra) # 80004214 <iunlockput>
      return 0;
    800045ae:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800045b0:	854e                	mv	a0,s3
    800045b2:	60e6                	ld	ra,88(sp)
    800045b4:	6446                	ld	s0,80(sp)
    800045b6:	64a6                	ld	s1,72(sp)
    800045b8:	6906                	ld	s2,64(sp)
    800045ba:	79e2                	ld	s3,56(sp)
    800045bc:	7a42                	ld	s4,48(sp)
    800045be:	7aa2                	ld	s5,40(sp)
    800045c0:	7b02                	ld	s6,32(sp)
    800045c2:	6be2                	ld	s7,24(sp)
    800045c4:	6c42                	ld	s8,16(sp)
    800045c6:	6ca2                	ld	s9,8(sp)
    800045c8:	6125                	addi	sp,sp,96
    800045ca:	8082                	ret
      iunlock(ip);
    800045cc:	854e                	mv	a0,s3
    800045ce:	00000097          	auipc	ra,0x0
    800045d2:	aa6080e7          	jalr	-1370(ra) # 80004074 <iunlock>
      return ip;
    800045d6:	bfe9                	j	800045b0 <namex+0x6a>
      iunlockput(ip);
    800045d8:	854e                	mv	a0,s3
    800045da:	00000097          	auipc	ra,0x0
    800045de:	c3a080e7          	jalr	-966(ra) # 80004214 <iunlockput>
      return 0;
    800045e2:	89e6                	mv	s3,s9
    800045e4:	b7f1                	j	800045b0 <namex+0x6a>
  len = path - s;
    800045e6:	40b48633          	sub	a2,s1,a1
    800045ea:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800045ee:	099c5463          	bge	s8,s9,80004676 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800045f2:	4639                	li	a2,14
    800045f4:	8552                	mv	a0,s4
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	724080e7          	jalr	1828(ra) # 80000d1a <memmove>
  while(*path == '/')
    800045fe:	0004c783          	lbu	a5,0(s1)
    80004602:	01279763          	bne	a5,s2,80004610 <namex+0xca>
    path++;
    80004606:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004608:	0004c783          	lbu	a5,0(s1)
    8000460c:	ff278de3          	beq	a5,s2,80004606 <namex+0xc0>
    ilock(ip);
    80004610:	854e                	mv	a0,s3
    80004612:	00000097          	auipc	ra,0x0
    80004616:	9a0080e7          	jalr	-1632(ra) # 80003fb2 <ilock>
    if(ip->type != T_DIR){
    8000461a:	04499783          	lh	a5,68(s3)
    8000461e:	f97793e3          	bne	a5,s7,800045a4 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004622:	000a8563          	beqz	s5,8000462c <namex+0xe6>
    80004626:	0004c783          	lbu	a5,0(s1)
    8000462a:	d3cd                	beqz	a5,800045cc <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000462c:	865a                	mv	a2,s6
    8000462e:	85d2                	mv	a1,s4
    80004630:	854e                	mv	a0,s3
    80004632:	00000097          	auipc	ra,0x0
    80004636:	e64080e7          	jalr	-412(ra) # 80004496 <dirlookup>
    8000463a:	8caa                	mv	s9,a0
    8000463c:	dd51                	beqz	a0,800045d8 <namex+0x92>
    iunlockput(ip);
    8000463e:	854e                	mv	a0,s3
    80004640:	00000097          	auipc	ra,0x0
    80004644:	bd4080e7          	jalr	-1068(ra) # 80004214 <iunlockput>
    ip = next;
    80004648:	89e6                	mv	s3,s9
  while(*path == '/')
    8000464a:	0004c783          	lbu	a5,0(s1)
    8000464e:	05279763          	bne	a5,s2,8000469c <namex+0x156>
    path++;
    80004652:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004654:	0004c783          	lbu	a5,0(s1)
    80004658:	ff278de3          	beq	a5,s2,80004652 <namex+0x10c>
  if(*path == 0)
    8000465c:	c79d                	beqz	a5,8000468a <namex+0x144>
    path++;
    8000465e:	85a6                	mv	a1,s1
  len = path - s;
    80004660:	8cda                	mv	s9,s6
    80004662:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004664:	01278963          	beq	a5,s2,80004676 <namex+0x130>
    80004668:	dfbd                	beqz	a5,800045e6 <namex+0xa0>
    path++;
    8000466a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000466c:	0004c783          	lbu	a5,0(s1)
    80004670:	ff279ce3          	bne	a5,s2,80004668 <namex+0x122>
    80004674:	bf8d                	j	800045e6 <namex+0xa0>
    memmove(name, s, len);
    80004676:	2601                	sext.w	a2,a2
    80004678:	8552                	mv	a0,s4
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	6a0080e7          	jalr	1696(ra) # 80000d1a <memmove>
    name[len] = 0;
    80004682:	9cd2                	add	s9,s9,s4
    80004684:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004688:	bf9d                	j	800045fe <namex+0xb8>
  if(nameiparent){
    8000468a:	f20a83e3          	beqz	s5,800045b0 <namex+0x6a>
    iput(ip);
    8000468e:	854e                	mv	a0,s3
    80004690:	00000097          	auipc	ra,0x0
    80004694:	adc080e7          	jalr	-1316(ra) # 8000416c <iput>
    return 0;
    80004698:	4981                	li	s3,0
    8000469a:	bf19                	j	800045b0 <namex+0x6a>
  if(*path == 0)
    8000469c:	d7fd                	beqz	a5,8000468a <namex+0x144>
  while(*path != '/' && *path != 0)
    8000469e:	0004c783          	lbu	a5,0(s1)
    800046a2:	85a6                	mv	a1,s1
    800046a4:	b7d1                	j	80004668 <namex+0x122>

00000000800046a6 <dirlink>:
{
    800046a6:	7139                	addi	sp,sp,-64
    800046a8:	fc06                	sd	ra,56(sp)
    800046aa:	f822                	sd	s0,48(sp)
    800046ac:	f426                	sd	s1,40(sp)
    800046ae:	f04a                	sd	s2,32(sp)
    800046b0:	ec4e                	sd	s3,24(sp)
    800046b2:	e852                	sd	s4,16(sp)
    800046b4:	0080                	addi	s0,sp,64
    800046b6:	892a                	mv	s2,a0
    800046b8:	8a2e                	mv	s4,a1
    800046ba:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800046bc:	4601                	li	a2,0
    800046be:	00000097          	auipc	ra,0x0
    800046c2:	dd8080e7          	jalr	-552(ra) # 80004496 <dirlookup>
    800046c6:	e93d                	bnez	a0,8000473c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046c8:	04c92483          	lw	s1,76(s2)
    800046cc:	c49d                	beqz	s1,800046fa <dirlink+0x54>
    800046ce:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046d0:	4741                	li	a4,16
    800046d2:	86a6                	mv	a3,s1
    800046d4:	fc040613          	addi	a2,s0,-64
    800046d8:	4581                	li	a1,0
    800046da:	854a                	mv	a0,s2
    800046dc:	00000097          	auipc	ra,0x0
    800046e0:	b8a080e7          	jalr	-1142(ra) # 80004266 <readi>
    800046e4:	47c1                	li	a5,16
    800046e6:	06f51163          	bne	a0,a5,80004748 <dirlink+0xa2>
    if(de.inum == 0)
    800046ea:	fc045783          	lhu	a5,-64(s0)
    800046ee:	c791                	beqz	a5,800046fa <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046f0:	24c1                	addiw	s1,s1,16
    800046f2:	04c92783          	lw	a5,76(s2)
    800046f6:	fcf4ede3          	bltu	s1,a5,800046d0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800046fa:	4639                	li	a2,14
    800046fc:	85d2                	mv	a1,s4
    800046fe:	fc240513          	addi	a0,s0,-62
    80004702:	ffffc097          	auipc	ra,0xffffc
    80004706:	6d0080e7          	jalr	1744(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    8000470a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000470e:	4741                	li	a4,16
    80004710:	86a6                	mv	a3,s1
    80004712:	fc040613          	addi	a2,s0,-64
    80004716:	4581                	li	a1,0
    80004718:	854a                	mv	a0,s2
    8000471a:	00000097          	auipc	ra,0x0
    8000471e:	c44080e7          	jalr	-956(ra) # 8000435e <writei>
    80004722:	872a                	mv	a4,a0
    80004724:	47c1                	li	a5,16
  return 0;
    80004726:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004728:	02f71863          	bne	a4,a5,80004758 <dirlink+0xb2>
}
    8000472c:	70e2                	ld	ra,56(sp)
    8000472e:	7442                	ld	s0,48(sp)
    80004730:	74a2                	ld	s1,40(sp)
    80004732:	7902                	ld	s2,32(sp)
    80004734:	69e2                	ld	s3,24(sp)
    80004736:	6a42                	ld	s4,16(sp)
    80004738:	6121                	addi	sp,sp,64
    8000473a:	8082                	ret
    iput(ip);
    8000473c:	00000097          	auipc	ra,0x0
    80004740:	a30080e7          	jalr	-1488(ra) # 8000416c <iput>
    return -1;
    80004744:	557d                	li	a0,-1
    80004746:	b7dd                	j	8000472c <dirlink+0x86>
      panic("dirlink read");
    80004748:	00005517          	auipc	a0,0x5
    8000474c:	31050513          	addi	a0,a0,784 # 80009a58 <syscalls+0x1c8>
    80004750:	ffffc097          	auipc	ra,0xffffc
    80004754:	dda080e7          	jalr	-550(ra) # 8000052a <panic>
    panic("dirlink");
    80004758:	00005517          	auipc	a0,0x5
    8000475c:	4d850513          	addi	a0,a0,1240 # 80009c30 <syscalls+0x3a0>
    80004760:	ffffc097          	auipc	ra,0xffffc
    80004764:	dca080e7          	jalr	-566(ra) # 8000052a <panic>

0000000080004768 <namei>:

struct inode*
namei(char *path)
{
    80004768:	1101                	addi	sp,sp,-32
    8000476a:	ec06                	sd	ra,24(sp)
    8000476c:	e822                	sd	s0,16(sp)
    8000476e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004770:	fe040613          	addi	a2,s0,-32
    80004774:	4581                	li	a1,0
    80004776:	00000097          	auipc	ra,0x0
    8000477a:	dd0080e7          	jalr	-560(ra) # 80004546 <namex>
}
    8000477e:	60e2                	ld	ra,24(sp)
    80004780:	6442                	ld	s0,16(sp)
    80004782:	6105                	addi	sp,sp,32
    80004784:	8082                	ret

0000000080004786 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004786:	1141                	addi	sp,sp,-16
    80004788:	e406                	sd	ra,8(sp)
    8000478a:	e022                	sd	s0,0(sp)
    8000478c:	0800                	addi	s0,sp,16
    8000478e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004790:	4585                	li	a1,1
    80004792:	00000097          	auipc	ra,0x0
    80004796:	db4080e7          	jalr	-588(ra) # 80004546 <namex>
}
    8000479a:	60a2                	ld	ra,8(sp)
    8000479c:	6402                	ld	s0,0(sp)
    8000479e:	0141                	addi	sp,sp,16
    800047a0:	8082                	ret

00000000800047a2 <itoa>:


#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
    800047a2:	1101                	addi	sp,sp,-32
    800047a4:	ec22                	sd	s0,24(sp)
    800047a6:	1000                	addi	s0,sp,32
    800047a8:	872a                	mv	a4,a0
    800047aa:	852e                	mv	a0,a1
    char const digit[] = "0123456789";
    800047ac:	00005797          	auipc	a5,0x5
    800047b0:	2bc78793          	addi	a5,a5,700 # 80009a68 <syscalls+0x1d8>
    800047b4:	6394                	ld	a3,0(a5)
    800047b6:	fed43023          	sd	a3,-32(s0)
    800047ba:	0087d683          	lhu	a3,8(a5)
    800047be:	fed41423          	sh	a3,-24(s0)
    800047c2:	00a7c783          	lbu	a5,10(a5)
    800047c6:	fef40523          	sb	a5,-22(s0)
    char* p = b;
    800047ca:	87ae                	mv	a5,a1
    if(i<0){
    800047cc:	02074b63          	bltz	a4,80004802 <itoa+0x60>
        *p++ = '-';
        i *= -1;
    }
    int shifter = i;
    800047d0:	86ba                	mv	a3,a4
    do{ //Move to where representation ends
        ++p;
        shifter = shifter/10;
    800047d2:	4629                	li	a2,10
        ++p;
    800047d4:	0785                	addi	a5,a5,1
        shifter = shifter/10;
    800047d6:	02c6c6bb          	divw	a3,a3,a2
    }while(shifter);
    800047da:	feed                	bnez	a3,800047d4 <itoa+0x32>
    *p = '\0';
    800047dc:	00078023          	sb	zero,0(a5)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
    800047e0:	4629                	li	a2,10
    800047e2:	17fd                	addi	a5,a5,-1
    800047e4:	02c766bb          	remw	a3,a4,a2
    800047e8:	ff040593          	addi	a1,s0,-16
    800047ec:	96ae                	add	a3,a3,a1
    800047ee:	ff06c683          	lbu	a3,-16(a3)
    800047f2:	00d78023          	sb	a3,0(a5)
        i = i/10;
    800047f6:	02c7473b          	divw	a4,a4,a2
    }while(i);
    800047fa:	f765                	bnez	a4,800047e2 <itoa+0x40>
    return b;
}
    800047fc:	6462                	ld	s0,24(sp)
    800047fe:	6105                	addi	sp,sp,32
    80004800:	8082                	ret
        *p++ = '-';
    80004802:	00158793          	addi	a5,a1,1
    80004806:	02d00693          	li	a3,45
    8000480a:	00d58023          	sb	a3,0(a1)
        i *= -1;
    8000480e:	40e0073b          	negw	a4,a4
    80004812:	bf7d                	j	800047d0 <itoa+0x2e>

0000000080004814 <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
    80004814:	711d                	addi	sp,sp,-96
    80004816:	ec86                	sd	ra,88(sp)
    80004818:	e8a2                	sd	s0,80(sp)
    8000481a:	e4a6                	sd	s1,72(sp)
    8000481c:	e0ca                	sd	s2,64(sp)
    8000481e:	1080                	addi	s0,sp,96
    80004820:	84aa                	mv	s1,a0
  //path of proccess
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    80004822:	4619                	li	a2,6
    80004824:	00005597          	auipc	a1,0x5
    80004828:	25458593          	addi	a1,a1,596 # 80009a78 <syscalls+0x1e8>
    8000482c:	fd040513          	addi	a0,s0,-48
    80004830:	ffffc097          	auipc	ra,0xffffc
    80004834:	4ea080e7          	jalr	1258(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    80004838:	fd640593          	addi	a1,s0,-42
    8000483c:	5888                	lw	a0,48(s1)
    8000483e:	00000097          	auipc	ra,0x0
    80004842:	f64080e7          	jalr	-156(ra) # 800047a2 <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if(0 == p->swapFile)
    80004846:	1684b503          	ld	a0,360(s1)
    8000484a:	16050763          	beqz	a0,800049b8 <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    8000484e:	00001097          	auipc	ra,0x1
    80004852:	918080e7          	jalr	-1768(ra) # 80005166 <fileclose>

  begin_op();
    80004856:	00000097          	auipc	ra,0x0
    8000485a:	444080e7          	jalr	1092(ra) # 80004c9a <begin_op>
  if((dp = nameiparent(path, name)) == 0)
    8000485e:	fb040593          	addi	a1,s0,-80
    80004862:	fd040513          	addi	a0,s0,-48
    80004866:	00000097          	auipc	ra,0x0
    8000486a:	f20080e7          	jalr	-224(ra) # 80004786 <nameiparent>
    8000486e:	892a                	mv	s2,a0
    80004870:	cd69                	beqz	a0,8000494a <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    80004872:	fffff097          	auipc	ra,0xfffff
    80004876:	740080e7          	jalr	1856(ra) # 80003fb2 <ilock>

    // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000487a:	00005597          	auipc	a1,0x5
    8000487e:	20658593          	addi	a1,a1,518 # 80009a80 <syscalls+0x1f0>
    80004882:	fb040513          	addi	a0,s0,-80
    80004886:	00000097          	auipc	ra,0x0
    8000488a:	bf6080e7          	jalr	-1034(ra) # 8000447c <namecmp>
    8000488e:	c57d                	beqz	a0,8000497c <removeSwapFile+0x168>
    80004890:	00005597          	auipc	a1,0x5
    80004894:	1f858593          	addi	a1,a1,504 # 80009a88 <syscalls+0x1f8>
    80004898:	fb040513          	addi	a0,s0,-80
    8000489c:	00000097          	auipc	ra,0x0
    800048a0:	be0080e7          	jalr	-1056(ra) # 8000447c <namecmp>
    800048a4:	cd61                	beqz	a0,8000497c <removeSwapFile+0x168>
     goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    800048a6:	fac40613          	addi	a2,s0,-84
    800048aa:	fb040593          	addi	a1,s0,-80
    800048ae:	854a                	mv	a0,s2
    800048b0:	00000097          	auipc	ra,0x0
    800048b4:	be6080e7          	jalr	-1050(ra) # 80004496 <dirlookup>
    800048b8:	84aa                	mv	s1,a0
    800048ba:	c169                	beqz	a0,8000497c <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    800048bc:	fffff097          	auipc	ra,0xfffff
    800048c0:	6f6080e7          	jalr	1782(ra) # 80003fb2 <ilock>

  if(ip->nlink < 1)
    800048c4:	04a49783          	lh	a5,74(s1)
    800048c8:	08f05763          	blez	a5,80004956 <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    800048cc:	04449703          	lh	a4,68(s1)
    800048d0:	4785                	li	a5,1
    800048d2:	08f70a63          	beq	a4,a5,80004966 <removeSwapFile+0x152>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    800048d6:	4641                	li	a2,16
    800048d8:	4581                	li	a1,0
    800048da:	fc040513          	addi	a0,s0,-64
    800048de:	ffffc097          	auipc	ra,0xffffc
    800048e2:	3e0080e7          	jalr	992(ra) # 80000cbe <memset>
  if(writei(dp,0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800048e6:	4741                	li	a4,16
    800048e8:	fac42683          	lw	a3,-84(s0)
    800048ec:	fc040613          	addi	a2,s0,-64
    800048f0:	4581                	li	a1,0
    800048f2:	854a                	mv	a0,s2
    800048f4:	00000097          	auipc	ra,0x0
    800048f8:	a6a080e7          	jalr	-1430(ra) # 8000435e <writei>
    800048fc:	47c1                	li	a5,16
    800048fe:	08f51a63          	bne	a0,a5,80004992 <removeSwapFile+0x17e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80004902:	04449703          	lh	a4,68(s1)
    80004906:	4785                	li	a5,1
    80004908:	08f70d63          	beq	a4,a5,800049a2 <removeSwapFile+0x18e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    8000490c:	854a                	mv	a0,s2
    8000490e:	00000097          	auipc	ra,0x0
    80004912:	906080e7          	jalr	-1786(ra) # 80004214 <iunlockput>

  ip->nlink--;
    80004916:	04a4d783          	lhu	a5,74(s1)
    8000491a:	37fd                	addiw	a5,a5,-1
    8000491c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004920:	8526                	mv	a0,s1
    80004922:	fffff097          	auipc	ra,0xfffff
    80004926:	5c6080e7          	jalr	1478(ra) # 80003ee8 <iupdate>
  iunlockput(ip);
    8000492a:	8526                	mv	a0,s1
    8000492c:	00000097          	auipc	ra,0x0
    80004930:	8e8080e7          	jalr	-1816(ra) # 80004214 <iunlockput>

  end_op();
    80004934:	00000097          	auipc	ra,0x0
    80004938:	3e6080e7          	jalr	998(ra) # 80004d1a <end_op>

  return 0;
    8000493c:	4501                	li	a0,0
  bad:
    iunlockput(dp);
    end_op();
    return -1;

}
    8000493e:	60e6                	ld	ra,88(sp)
    80004940:	6446                	ld	s0,80(sp)
    80004942:	64a6                	ld	s1,72(sp)
    80004944:	6906                	ld	s2,64(sp)
    80004946:	6125                	addi	sp,sp,96
    80004948:	8082                	ret
    end_op();
    8000494a:	00000097          	auipc	ra,0x0
    8000494e:	3d0080e7          	jalr	976(ra) # 80004d1a <end_op>
    return -1;
    80004952:	557d                	li	a0,-1
    80004954:	b7ed                	j	8000493e <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    80004956:	00005517          	auipc	a0,0x5
    8000495a:	13a50513          	addi	a0,a0,314 # 80009a90 <syscalls+0x200>
    8000495e:	ffffc097          	auipc	ra,0xffffc
    80004962:	bcc080e7          	jalr	-1076(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004966:	8526                	mv	a0,s1
    80004968:	00001097          	auipc	ra,0x1
    8000496c:	7da080e7          	jalr	2010(ra) # 80006142 <isdirempty>
    80004970:	f13d                	bnez	a0,800048d6 <removeSwapFile+0xc2>
    iunlockput(ip);
    80004972:	8526                	mv	a0,s1
    80004974:	00000097          	auipc	ra,0x0
    80004978:	8a0080e7          	jalr	-1888(ra) # 80004214 <iunlockput>
    iunlockput(dp);
    8000497c:	854a                	mv	a0,s2
    8000497e:	00000097          	auipc	ra,0x0
    80004982:	896080e7          	jalr	-1898(ra) # 80004214 <iunlockput>
    end_op();
    80004986:	00000097          	auipc	ra,0x0
    8000498a:	394080e7          	jalr	916(ra) # 80004d1a <end_op>
    return -1;
    8000498e:	557d                	li	a0,-1
    80004990:	b77d                	j	8000493e <removeSwapFile+0x12a>
    panic("unlink: writei");
    80004992:	00005517          	auipc	a0,0x5
    80004996:	11650513          	addi	a0,a0,278 # 80009aa8 <syscalls+0x218>
    8000499a:	ffffc097          	auipc	ra,0xffffc
    8000499e:	b90080e7          	jalr	-1136(ra) # 8000052a <panic>
    dp->nlink--;
    800049a2:	04a95783          	lhu	a5,74(s2)
    800049a6:	37fd                	addiw	a5,a5,-1
    800049a8:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800049ac:	854a                	mv	a0,s2
    800049ae:	fffff097          	auipc	ra,0xfffff
    800049b2:	53a080e7          	jalr	1338(ra) # 80003ee8 <iupdate>
    800049b6:	bf99                	j	8000490c <removeSwapFile+0xf8>
    return -1;
    800049b8:	557d                	li	a0,-1
    800049ba:	b751                	j	8000493e <removeSwapFile+0x12a>

00000000800049bc <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
    800049bc:	7179                	addi	sp,sp,-48
    800049be:	f406                	sd	ra,40(sp)
    800049c0:	f022                	sd	s0,32(sp)
    800049c2:	ec26                	sd	s1,24(sp)
    800049c4:	e84a                	sd	s2,16(sp)
    800049c6:	1800                	addi	s0,sp,48
    800049c8:	84aa                	mv	s1,a0

  char path[DIGITS];
  memmove(path,"/.swap", 6);
    800049ca:	4619                	li	a2,6
    800049cc:	00005597          	auipc	a1,0x5
    800049d0:	0ac58593          	addi	a1,a1,172 # 80009a78 <syscalls+0x1e8>
    800049d4:	fd040513          	addi	a0,s0,-48
    800049d8:	ffffc097          	auipc	ra,0xffffc
    800049dc:	342080e7          	jalr	834(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    800049e0:	fd640593          	addi	a1,s0,-42
    800049e4:	5888                	lw	a0,48(s1)
    800049e6:	00000097          	auipc	ra,0x0
    800049ea:	dbc080e7          	jalr	-580(ra) # 800047a2 <itoa>

  begin_op();
    800049ee:	00000097          	auipc	ra,0x0
    800049f2:	2ac080e7          	jalr	684(ra) # 80004c9a <begin_op>
  
  struct inode * in = create(path, T_FILE, 0, 0);
    800049f6:	4681                	li	a3,0
    800049f8:	4601                	li	a2,0
    800049fa:	4589                	li	a1,2
    800049fc:	fd040513          	addi	a0,s0,-48
    80004a00:	00002097          	auipc	ra,0x2
    80004a04:	936080e7          	jalr	-1738(ra) # 80006336 <create>
    80004a08:	892a                	mv	s2,a0
  iunlock(in);
    80004a0a:	fffff097          	auipc	ra,0xfffff
    80004a0e:	66a080e7          	jalr	1642(ra) # 80004074 <iunlock>
  p->swapFile = filealloc();
    80004a12:	00000097          	auipc	ra,0x0
    80004a16:	698080e7          	jalr	1688(ra) # 800050aa <filealloc>
    80004a1a:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    80004a1e:	cd1d                	beqz	a0,80004a5c <createSwapFile+0xa0>
    panic("no slot for files on /store");

  p->swapFile->ip = in;
    80004a20:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    80004a24:	1684b703          	ld	a4,360(s1)
    80004a28:	4789                	li	a5,2
    80004a2a:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    80004a2c:	1684b703          	ld	a4,360(s1)
    80004a30:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    80004a34:	1684b703          	ld	a4,360(s1)
    80004a38:	4685                	li	a3,1
    80004a3a:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    80004a3e:	1684b703          	ld	a4,360(s1)
    80004a42:	00f704a3          	sb	a5,9(a4)
    end_op();
    80004a46:	00000097          	auipc	ra,0x0
    80004a4a:	2d4080e7          	jalr	724(ra) # 80004d1a <end_op>

    return 0;
}
    80004a4e:	4501                	li	a0,0
    80004a50:	70a2                	ld	ra,40(sp)
    80004a52:	7402                	ld	s0,32(sp)
    80004a54:	64e2                	ld	s1,24(sp)
    80004a56:	6942                	ld	s2,16(sp)
    80004a58:	6145                	addi	sp,sp,48
    80004a5a:	8082                	ret
    panic("no slot for files on /store");
    80004a5c:	00005517          	auipc	a0,0x5
    80004a60:	05c50513          	addi	a0,a0,92 # 80009ab8 <syscalls+0x228>
    80004a64:	ffffc097          	auipc	ra,0xffffc
    80004a68:	ac6080e7          	jalr	-1338(ra) # 8000052a <panic>

0000000080004a6c <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004a6c:	1141                	addi	sp,sp,-16
    80004a6e:	e406                	sd	ra,8(sp)
    80004a70:	e022                	sd	s0,0(sp)
    80004a72:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004a74:	16853783          	ld	a5,360(a0)
    80004a78:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    80004a7a:	8636                	mv	a2,a3
    80004a7c:	16853503          	ld	a0,360(a0)
    80004a80:	00001097          	auipc	ra,0x1
    80004a84:	ad8080e7          	jalr	-1320(ra) # 80005558 <kfilewrite>
}
    80004a88:	60a2                	ld	ra,8(sp)
    80004a8a:	6402                	ld	s0,0(sp)
    80004a8c:	0141                	addi	sp,sp,16
    80004a8e:	8082                	ret

0000000080004a90 <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004a90:	1141                	addi	sp,sp,-16
    80004a92:	e406                	sd	ra,8(sp)
    80004a94:	e022                	sd	s0,0(sp)
    80004a96:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004a98:	16853783          	ld	a5,360(a0)
    80004a9c:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer,  size);
    80004a9e:	8636                	mv	a2,a3
    80004aa0:	16853503          	ld	a0,360(a0)
    80004aa4:	00001097          	auipc	ra,0x1
    80004aa8:	9f2080e7          	jalr	-1550(ra) # 80005496 <kfileread>
    80004aac:	60a2                	ld	ra,8(sp)
    80004aae:	6402                	ld	s0,0(sp)
    80004ab0:	0141                	addi	sp,sp,16
    80004ab2:	8082                	ret

0000000080004ab4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004ab4:	1101                	addi	sp,sp,-32
    80004ab6:	ec06                	sd	ra,24(sp)
    80004ab8:	e822                	sd	s0,16(sp)
    80004aba:	e426                	sd	s1,8(sp)
    80004abc:	e04a                	sd	s2,0(sp)
    80004abe:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004ac0:	00025917          	auipc	s2,0x25
    80004ac4:	db090913          	addi	s2,s2,-592 # 80029870 <log>
    80004ac8:	01892583          	lw	a1,24(s2)
    80004acc:	02892503          	lw	a0,40(s2)
    80004ad0:	fffff097          	auipc	ra,0xfffff
    80004ad4:	cde080e7          	jalr	-802(ra) # 800037ae <bread>
    80004ad8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004ada:	02c92683          	lw	a3,44(s2)
    80004ade:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004ae0:	02d05863          	blez	a3,80004b10 <write_head+0x5c>
    80004ae4:	00025797          	auipc	a5,0x25
    80004ae8:	dbc78793          	addi	a5,a5,-580 # 800298a0 <log+0x30>
    80004aec:	05c50713          	addi	a4,a0,92
    80004af0:	36fd                	addiw	a3,a3,-1
    80004af2:	02069613          	slli	a2,a3,0x20
    80004af6:	01e65693          	srli	a3,a2,0x1e
    80004afa:	00025617          	auipc	a2,0x25
    80004afe:	daa60613          	addi	a2,a2,-598 # 800298a4 <log+0x34>
    80004b02:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004b04:	4390                	lw	a2,0(a5)
    80004b06:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004b08:	0791                	addi	a5,a5,4
    80004b0a:	0711                	addi	a4,a4,4
    80004b0c:	fed79ce3          	bne	a5,a3,80004b04 <write_head+0x50>
  }
  bwrite(buf);
    80004b10:	8526                	mv	a0,s1
    80004b12:	fffff097          	auipc	ra,0xfffff
    80004b16:	d8e080e7          	jalr	-626(ra) # 800038a0 <bwrite>
  brelse(buf);
    80004b1a:	8526                	mv	a0,s1
    80004b1c:	fffff097          	auipc	ra,0xfffff
    80004b20:	dc2080e7          	jalr	-574(ra) # 800038de <brelse>
}
    80004b24:	60e2                	ld	ra,24(sp)
    80004b26:	6442                	ld	s0,16(sp)
    80004b28:	64a2                	ld	s1,8(sp)
    80004b2a:	6902                	ld	s2,0(sp)
    80004b2c:	6105                	addi	sp,sp,32
    80004b2e:	8082                	ret

0000000080004b30 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b30:	00025797          	auipc	a5,0x25
    80004b34:	d6c7a783          	lw	a5,-660(a5) # 8002989c <log+0x2c>
    80004b38:	0af05d63          	blez	a5,80004bf2 <install_trans+0xc2>
{
    80004b3c:	7139                	addi	sp,sp,-64
    80004b3e:	fc06                	sd	ra,56(sp)
    80004b40:	f822                	sd	s0,48(sp)
    80004b42:	f426                	sd	s1,40(sp)
    80004b44:	f04a                	sd	s2,32(sp)
    80004b46:	ec4e                	sd	s3,24(sp)
    80004b48:	e852                	sd	s4,16(sp)
    80004b4a:	e456                	sd	s5,8(sp)
    80004b4c:	e05a                	sd	s6,0(sp)
    80004b4e:	0080                	addi	s0,sp,64
    80004b50:	8b2a                	mv	s6,a0
    80004b52:	00025a97          	auipc	s5,0x25
    80004b56:	d4ea8a93          	addi	s5,s5,-690 # 800298a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b5a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b5c:	00025997          	auipc	s3,0x25
    80004b60:	d1498993          	addi	s3,s3,-748 # 80029870 <log>
    80004b64:	a00d                	j	80004b86 <install_trans+0x56>
    brelse(lbuf);
    80004b66:	854a                	mv	a0,s2
    80004b68:	fffff097          	auipc	ra,0xfffff
    80004b6c:	d76080e7          	jalr	-650(ra) # 800038de <brelse>
    brelse(dbuf);
    80004b70:	8526                	mv	a0,s1
    80004b72:	fffff097          	auipc	ra,0xfffff
    80004b76:	d6c080e7          	jalr	-660(ra) # 800038de <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b7a:	2a05                	addiw	s4,s4,1
    80004b7c:	0a91                	addi	s5,s5,4
    80004b7e:	02c9a783          	lw	a5,44(s3)
    80004b82:	04fa5e63          	bge	s4,a5,80004bde <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b86:	0189a583          	lw	a1,24(s3)
    80004b8a:	014585bb          	addw	a1,a1,s4
    80004b8e:	2585                	addiw	a1,a1,1
    80004b90:	0289a503          	lw	a0,40(s3)
    80004b94:	fffff097          	auipc	ra,0xfffff
    80004b98:	c1a080e7          	jalr	-998(ra) # 800037ae <bread>
    80004b9c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004b9e:	000aa583          	lw	a1,0(s5)
    80004ba2:	0289a503          	lw	a0,40(s3)
    80004ba6:	fffff097          	auipc	ra,0xfffff
    80004baa:	c08080e7          	jalr	-1016(ra) # 800037ae <bread>
    80004bae:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004bb0:	40000613          	li	a2,1024
    80004bb4:	05890593          	addi	a1,s2,88
    80004bb8:	05850513          	addi	a0,a0,88
    80004bbc:	ffffc097          	auipc	ra,0xffffc
    80004bc0:	15e080e7          	jalr	350(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004bc4:	8526                	mv	a0,s1
    80004bc6:	fffff097          	auipc	ra,0xfffff
    80004bca:	cda080e7          	jalr	-806(ra) # 800038a0 <bwrite>
    if(recovering == 0)
    80004bce:	f80b1ce3          	bnez	s6,80004b66 <install_trans+0x36>
      bunpin(dbuf);
    80004bd2:	8526                	mv	a0,s1
    80004bd4:	fffff097          	auipc	ra,0xfffff
    80004bd8:	de4080e7          	jalr	-540(ra) # 800039b8 <bunpin>
    80004bdc:	b769                	j	80004b66 <install_trans+0x36>
}
    80004bde:	70e2                	ld	ra,56(sp)
    80004be0:	7442                	ld	s0,48(sp)
    80004be2:	74a2                	ld	s1,40(sp)
    80004be4:	7902                	ld	s2,32(sp)
    80004be6:	69e2                	ld	s3,24(sp)
    80004be8:	6a42                	ld	s4,16(sp)
    80004bea:	6aa2                	ld	s5,8(sp)
    80004bec:	6b02                	ld	s6,0(sp)
    80004bee:	6121                	addi	sp,sp,64
    80004bf0:	8082                	ret
    80004bf2:	8082                	ret

0000000080004bf4 <initlog>:
{
    80004bf4:	7179                	addi	sp,sp,-48
    80004bf6:	f406                	sd	ra,40(sp)
    80004bf8:	f022                	sd	s0,32(sp)
    80004bfa:	ec26                	sd	s1,24(sp)
    80004bfc:	e84a                	sd	s2,16(sp)
    80004bfe:	e44e                	sd	s3,8(sp)
    80004c00:	1800                	addi	s0,sp,48
    80004c02:	892a                	mv	s2,a0
    80004c04:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004c06:	00025497          	auipc	s1,0x25
    80004c0a:	c6a48493          	addi	s1,s1,-918 # 80029870 <log>
    80004c0e:	00005597          	auipc	a1,0x5
    80004c12:	eca58593          	addi	a1,a1,-310 # 80009ad8 <syscalls+0x248>
    80004c16:	8526                	mv	a0,s1
    80004c18:	ffffc097          	auipc	ra,0xffffc
    80004c1c:	f1a080e7          	jalr	-230(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004c20:	0149a583          	lw	a1,20(s3)
    80004c24:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004c26:	0109a783          	lw	a5,16(s3)
    80004c2a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004c2c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004c30:	854a                	mv	a0,s2
    80004c32:	fffff097          	auipc	ra,0xfffff
    80004c36:	b7c080e7          	jalr	-1156(ra) # 800037ae <bread>
  log.lh.n = lh->n;
    80004c3a:	4d34                	lw	a3,88(a0)
    80004c3c:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004c3e:	02d05663          	blez	a3,80004c6a <initlog+0x76>
    80004c42:	05c50793          	addi	a5,a0,92
    80004c46:	00025717          	auipc	a4,0x25
    80004c4a:	c5a70713          	addi	a4,a4,-934 # 800298a0 <log+0x30>
    80004c4e:	36fd                	addiw	a3,a3,-1
    80004c50:	02069613          	slli	a2,a3,0x20
    80004c54:	01e65693          	srli	a3,a2,0x1e
    80004c58:	06050613          	addi	a2,a0,96
    80004c5c:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004c5e:	4390                	lw	a2,0(a5)
    80004c60:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004c62:	0791                	addi	a5,a5,4
    80004c64:	0711                	addi	a4,a4,4
    80004c66:	fed79ce3          	bne	a5,a3,80004c5e <initlog+0x6a>
  brelse(buf);
    80004c6a:	fffff097          	auipc	ra,0xfffff
    80004c6e:	c74080e7          	jalr	-908(ra) # 800038de <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004c72:	4505                	li	a0,1
    80004c74:	00000097          	auipc	ra,0x0
    80004c78:	ebc080e7          	jalr	-324(ra) # 80004b30 <install_trans>
  log.lh.n = 0;
    80004c7c:	00025797          	auipc	a5,0x25
    80004c80:	c207a023          	sw	zero,-992(a5) # 8002989c <log+0x2c>
  write_head(); // clear the log
    80004c84:	00000097          	auipc	ra,0x0
    80004c88:	e30080e7          	jalr	-464(ra) # 80004ab4 <write_head>
}
    80004c8c:	70a2                	ld	ra,40(sp)
    80004c8e:	7402                	ld	s0,32(sp)
    80004c90:	64e2                	ld	s1,24(sp)
    80004c92:	6942                	ld	s2,16(sp)
    80004c94:	69a2                	ld	s3,8(sp)
    80004c96:	6145                	addi	sp,sp,48
    80004c98:	8082                	ret

0000000080004c9a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004c9a:	1101                	addi	sp,sp,-32
    80004c9c:	ec06                	sd	ra,24(sp)
    80004c9e:	e822                	sd	s0,16(sp)
    80004ca0:	e426                	sd	s1,8(sp)
    80004ca2:	e04a                	sd	s2,0(sp)
    80004ca4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004ca6:	00025517          	auipc	a0,0x25
    80004caa:	bca50513          	addi	a0,a0,-1078 # 80029870 <log>
    80004cae:	ffffc097          	auipc	ra,0xffffc
    80004cb2:	f14080e7          	jalr	-236(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004cb6:	00025497          	auipc	s1,0x25
    80004cba:	bba48493          	addi	s1,s1,-1094 # 80029870 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004cbe:	4979                	li	s2,30
    80004cc0:	a039                	j	80004cce <begin_op+0x34>
      sleep(&log, &log.lock);
    80004cc2:	85a6                	mv	a1,s1
    80004cc4:	8526                	mv	a0,s1
    80004cc6:	ffffe097          	auipc	ra,0xffffe
    80004cca:	d3a080e7          	jalr	-710(ra) # 80002a00 <sleep>
    if(log.committing){
    80004cce:	50dc                	lw	a5,36(s1)
    80004cd0:	fbed                	bnez	a5,80004cc2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004cd2:	509c                	lw	a5,32(s1)
    80004cd4:	0017871b          	addiw	a4,a5,1
    80004cd8:	0007069b          	sext.w	a3,a4
    80004cdc:	0027179b          	slliw	a5,a4,0x2
    80004ce0:	9fb9                	addw	a5,a5,a4
    80004ce2:	0017979b          	slliw	a5,a5,0x1
    80004ce6:	54d8                	lw	a4,44(s1)
    80004ce8:	9fb9                	addw	a5,a5,a4
    80004cea:	00f95963          	bge	s2,a5,80004cfc <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004cee:	85a6                	mv	a1,s1
    80004cf0:	8526                	mv	a0,s1
    80004cf2:	ffffe097          	auipc	ra,0xffffe
    80004cf6:	d0e080e7          	jalr	-754(ra) # 80002a00 <sleep>
    80004cfa:	bfd1                	j	80004cce <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004cfc:	00025517          	auipc	a0,0x25
    80004d00:	b7450513          	addi	a0,a0,-1164 # 80029870 <log>
    80004d04:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004d06:	ffffc097          	auipc	ra,0xffffc
    80004d0a:	f70080e7          	jalr	-144(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004d0e:	60e2                	ld	ra,24(sp)
    80004d10:	6442                	ld	s0,16(sp)
    80004d12:	64a2                	ld	s1,8(sp)
    80004d14:	6902                	ld	s2,0(sp)
    80004d16:	6105                	addi	sp,sp,32
    80004d18:	8082                	ret

0000000080004d1a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004d1a:	7139                	addi	sp,sp,-64
    80004d1c:	fc06                	sd	ra,56(sp)
    80004d1e:	f822                	sd	s0,48(sp)
    80004d20:	f426                	sd	s1,40(sp)
    80004d22:	f04a                	sd	s2,32(sp)
    80004d24:	ec4e                	sd	s3,24(sp)
    80004d26:	e852                	sd	s4,16(sp)
    80004d28:	e456                	sd	s5,8(sp)
    80004d2a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004d2c:	00025497          	auipc	s1,0x25
    80004d30:	b4448493          	addi	s1,s1,-1212 # 80029870 <log>
    80004d34:	8526                	mv	a0,s1
    80004d36:	ffffc097          	auipc	ra,0xffffc
    80004d3a:	e8c080e7          	jalr	-372(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004d3e:	509c                	lw	a5,32(s1)
    80004d40:	37fd                	addiw	a5,a5,-1
    80004d42:	0007891b          	sext.w	s2,a5
    80004d46:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004d48:	50dc                	lw	a5,36(s1)
    80004d4a:	e7b9                	bnez	a5,80004d98 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004d4c:	04091e63          	bnez	s2,80004da8 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004d50:	00025497          	auipc	s1,0x25
    80004d54:	b2048493          	addi	s1,s1,-1248 # 80029870 <log>
    80004d58:	4785                	li	a5,1
    80004d5a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004d5c:	8526                	mv	a0,s1
    80004d5e:	ffffc097          	auipc	ra,0xffffc
    80004d62:	f18080e7          	jalr	-232(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004d66:	54dc                	lw	a5,44(s1)
    80004d68:	06f04763          	bgtz	a5,80004dd6 <end_op+0xbc>
    acquire(&log.lock);
    80004d6c:	00025497          	auipc	s1,0x25
    80004d70:	b0448493          	addi	s1,s1,-1276 # 80029870 <log>
    80004d74:	8526                	mv	a0,s1
    80004d76:	ffffc097          	auipc	ra,0xffffc
    80004d7a:	e4c080e7          	jalr	-436(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004d7e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004d82:	8526                	mv	a0,s1
    80004d84:	ffffe097          	auipc	ra,0xffffe
    80004d88:	e08080e7          	jalr	-504(ra) # 80002b8c <wakeup>
    release(&log.lock);
    80004d8c:	8526                	mv	a0,s1
    80004d8e:	ffffc097          	auipc	ra,0xffffc
    80004d92:	ee8080e7          	jalr	-280(ra) # 80000c76 <release>
}
    80004d96:	a03d                	j	80004dc4 <end_op+0xaa>
    panic("log.committing");
    80004d98:	00005517          	auipc	a0,0x5
    80004d9c:	d4850513          	addi	a0,a0,-696 # 80009ae0 <syscalls+0x250>
    80004da0:	ffffb097          	auipc	ra,0xffffb
    80004da4:	78a080e7          	jalr	1930(ra) # 8000052a <panic>
    wakeup(&log);
    80004da8:	00025497          	auipc	s1,0x25
    80004dac:	ac848493          	addi	s1,s1,-1336 # 80029870 <log>
    80004db0:	8526                	mv	a0,s1
    80004db2:	ffffe097          	auipc	ra,0xffffe
    80004db6:	dda080e7          	jalr	-550(ra) # 80002b8c <wakeup>
  release(&log.lock);
    80004dba:	8526                	mv	a0,s1
    80004dbc:	ffffc097          	auipc	ra,0xffffc
    80004dc0:	eba080e7          	jalr	-326(ra) # 80000c76 <release>
}
    80004dc4:	70e2                	ld	ra,56(sp)
    80004dc6:	7442                	ld	s0,48(sp)
    80004dc8:	74a2                	ld	s1,40(sp)
    80004dca:	7902                	ld	s2,32(sp)
    80004dcc:	69e2                	ld	s3,24(sp)
    80004dce:	6a42                	ld	s4,16(sp)
    80004dd0:	6aa2                	ld	s5,8(sp)
    80004dd2:	6121                	addi	sp,sp,64
    80004dd4:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004dd6:	00025a97          	auipc	s5,0x25
    80004dda:	acaa8a93          	addi	s5,s5,-1334 # 800298a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004dde:	00025a17          	auipc	s4,0x25
    80004de2:	a92a0a13          	addi	s4,s4,-1390 # 80029870 <log>
    80004de6:	018a2583          	lw	a1,24(s4)
    80004dea:	012585bb          	addw	a1,a1,s2
    80004dee:	2585                	addiw	a1,a1,1
    80004df0:	028a2503          	lw	a0,40(s4)
    80004df4:	fffff097          	auipc	ra,0xfffff
    80004df8:	9ba080e7          	jalr	-1606(ra) # 800037ae <bread>
    80004dfc:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004dfe:	000aa583          	lw	a1,0(s5)
    80004e02:	028a2503          	lw	a0,40(s4)
    80004e06:	fffff097          	auipc	ra,0xfffff
    80004e0a:	9a8080e7          	jalr	-1624(ra) # 800037ae <bread>
    80004e0e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004e10:	40000613          	li	a2,1024
    80004e14:	05850593          	addi	a1,a0,88
    80004e18:	05848513          	addi	a0,s1,88
    80004e1c:	ffffc097          	auipc	ra,0xffffc
    80004e20:	efe080e7          	jalr	-258(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004e24:	8526                	mv	a0,s1
    80004e26:	fffff097          	auipc	ra,0xfffff
    80004e2a:	a7a080e7          	jalr	-1414(ra) # 800038a0 <bwrite>
    brelse(from);
    80004e2e:	854e                	mv	a0,s3
    80004e30:	fffff097          	auipc	ra,0xfffff
    80004e34:	aae080e7          	jalr	-1362(ra) # 800038de <brelse>
    brelse(to);
    80004e38:	8526                	mv	a0,s1
    80004e3a:	fffff097          	auipc	ra,0xfffff
    80004e3e:	aa4080e7          	jalr	-1372(ra) # 800038de <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e42:	2905                	addiw	s2,s2,1
    80004e44:	0a91                	addi	s5,s5,4
    80004e46:	02ca2783          	lw	a5,44(s4)
    80004e4a:	f8f94ee3          	blt	s2,a5,80004de6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004e4e:	00000097          	auipc	ra,0x0
    80004e52:	c66080e7          	jalr	-922(ra) # 80004ab4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004e56:	4501                	li	a0,0
    80004e58:	00000097          	auipc	ra,0x0
    80004e5c:	cd8080e7          	jalr	-808(ra) # 80004b30 <install_trans>
    log.lh.n = 0;
    80004e60:	00025797          	auipc	a5,0x25
    80004e64:	a207ae23          	sw	zero,-1476(a5) # 8002989c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004e68:	00000097          	auipc	ra,0x0
    80004e6c:	c4c080e7          	jalr	-948(ra) # 80004ab4 <write_head>
    80004e70:	bdf5                	j	80004d6c <end_op+0x52>

0000000080004e72 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004e72:	1101                	addi	sp,sp,-32
    80004e74:	ec06                	sd	ra,24(sp)
    80004e76:	e822                	sd	s0,16(sp)
    80004e78:	e426                	sd	s1,8(sp)
    80004e7a:	e04a                	sd	s2,0(sp)
    80004e7c:	1000                	addi	s0,sp,32
    80004e7e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004e80:	00025917          	auipc	s2,0x25
    80004e84:	9f090913          	addi	s2,s2,-1552 # 80029870 <log>
    80004e88:	854a                	mv	a0,s2
    80004e8a:	ffffc097          	auipc	ra,0xffffc
    80004e8e:	d38080e7          	jalr	-712(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004e92:	02c92603          	lw	a2,44(s2)
    80004e96:	47f5                	li	a5,29
    80004e98:	06c7c563          	blt	a5,a2,80004f02 <log_write+0x90>
    80004e9c:	00025797          	auipc	a5,0x25
    80004ea0:	9f07a783          	lw	a5,-1552(a5) # 8002988c <log+0x1c>
    80004ea4:	37fd                	addiw	a5,a5,-1
    80004ea6:	04f65e63          	bge	a2,a5,80004f02 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004eaa:	00025797          	auipc	a5,0x25
    80004eae:	9e67a783          	lw	a5,-1562(a5) # 80029890 <log+0x20>
    80004eb2:	06f05063          	blez	a5,80004f12 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004eb6:	4781                	li	a5,0
    80004eb8:	06c05563          	blez	a2,80004f22 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004ebc:	44cc                	lw	a1,12(s1)
    80004ebe:	00025717          	auipc	a4,0x25
    80004ec2:	9e270713          	addi	a4,a4,-1566 # 800298a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004ec6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004ec8:	4314                	lw	a3,0(a4)
    80004eca:	04b68c63          	beq	a3,a1,80004f22 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004ece:	2785                	addiw	a5,a5,1
    80004ed0:	0711                	addi	a4,a4,4
    80004ed2:	fef61be3          	bne	a2,a5,80004ec8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004ed6:	0621                	addi	a2,a2,8
    80004ed8:	060a                	slli	a2,a2,0x2
    80004eda:	00025797          	auipc	a5,0x25
    80004ede:	99678793          	addi	a5,a5,-1642 # 80029870 <log>
    80004ee2:	963e                	add	a2,a2,a5
    80004ee4:	44dc                	lw	a5,12(s1)
    80004ee6:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004ee8:	8526                	mv	a0,s1
    80004eea:	fffff097          	auipc	ra,0xfffff
    80004eee:	a92080e7          	jalr	-1390(ra) # 8000397c <bpin>
    log.lh.n++;
    80004ef2:	00025717          	auipc	a4,0x25
    80004ef6:	97e70713          	addi	a4,a4,-1666 # 80029870 <log>
    80004efa:	575c                	lw	a5,44(a4)
    80004efc:	2785                	addiw	a5,a5,1
    80004efe:	d75c                	sw	a5,44(a4)
    80004f00:	a835                	j	80004f3c <log_write+0xca>
    panic("too big a transaction");
    80004f02:	00005517          	auipc	a0,0x5
    80004f06:	bee50513          	addi	a0,a0,-1042 # 80009af0 <syscalls+0x260>
    80004f0a:	ffffb097          	auipc	ra,0xffffb
    80004f0e:	620080e7          	jalr	1568(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004f12:	00005517          	auipc	a0,0x5
    80004f16:	bf650513          	addi	a0,a0,-1034 # 80009b08 <syscalls+0x278>
    80004f1a:	ffffb097          	auipc	ra,0xffffb
    80004f1e:	610080e7          	jalr	1552(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004f22:	00878713          	addi	a4,a5,8
    80004f26:	00271693          	slli	a3,a4,0x2
    80004f2a:	00025717          	auipc	a4,0x25
    80004f2e:	94670713          	addi	a4,a4,-1722 # 80029870 <log>
    80004f32:	9736                	add	a4,a4,a3
    80004f34:	44d4                	lw	a3,12(s1)
    80004f36:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004f38:	faf608e3          	beq	a2,a5,80004ee8 <log_write+0x76>
  }
  release(&log.lock);
    80004f3c:	00025517          	auipc	a0,0x25
    80004f40:	93450513          	addi	a0,a0,-1740 # 80029870 <log>
    80004f44:	ffffc097          	auipc	ra,0xffffc
    80004f48:	d32080e7          	jalr	-718(ra) # 80000c76 <release>
}
    80004f4c:	60e2                	ld	ra,24(sp)
    80004f4e:	6442                	ld	s0,16(sp)
    80004f50:	64a2                	ld	s1,8(sp)
    80004f52:	6902                	ld	s2,0(sp)
    80004f54:	6105                	addi	sp,sp,32
    80004f56:	8082                	ret

0000000080004f58 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004f58:	1101                	addi	sp,sp,-32
    80004f5a:	ec06                	sd	ra,24(sp)
    80004f5c:	e822                	sd	s0,16(sp)
    80004f5e:	e426                	sd	s1,8(sp)
    80004f60:	e04a                	sd	s2,0(sp)
    80004f62:	1000                	addi	s0,sp,32
    80004f64:	84aa                	mv	s1,a0
    80004f66:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004f68:	00005597          	auipc	a1,0x5
    80004f6c:	bc058593          	addi	a1,a1,-1088 # 80009b28 <syscalls+0x298>
    80004f70:	0521                	addi	a0,a0,8
    80004f72:	ffffc097          	auipc	ra,0xffffc
    80004f76:	bc0080e7          	jalr	-1088(ra) # 80000b32 <initlock>
  lk->name = name;
    80004f7a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004f7e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004f82:	0204a423          	sw	zero,40(s1)
}
    80004f86:	60e2                	ld	ra,24(sp)
    80004f88:	6442                	ld	s0,16(sp)
    80004f8a:	64a2                	ld	s1,8(sp)
    80004f8c:	6902                	ld	s2,0(sp)
    80004f8e:	6105                	addi	sp,sp,32
    80004f90:	8082                	ret

0000000080004f92 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004f92:	1101                	addi	sp,sp,-32
    80004f94:	ec06                	sd	ra,24(sp)
    80004f96:	e822                	sd	s0,16(sp)
    80004f98:	e426                	sd	s1,8(sp)
    80004f9a:	e04a                	sd	s2,0(sp)
    80004f9c:	1000                	addi	s0,sp,32
    80004f9e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004fa0:	00850913          	addi	s2,a0,8
    80004fa4:	854a                	mv	a0,s2
    80004fa6:	ffffc097          	auipc	ra,0xffffc
    80004faa:	c1c080e7          	jalr	-996(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004fae:	409c                	lw	a5,0(s1)
    80004fb0:	cb89                	beqz	a5,80004fc2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004fb2:	85ca                	mv	a1,s2
    80004fb4:	8526                	mv	a0,s1
    80004fb6:	ffffe097          	auipc	ra,0xffffe
    80004fba:	a4a080e7          	jalr	-1462(ra) # 80002a00 <sleep>
  while (lk->locked) {
    80004fbe:	409c                	lw	a5,0(s1)
    80004fc0:	fbed                	bnez	a5,80004fb2 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004fc2:	4785                	li	a5,1
    80004fc4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004fc6:	ffffd097          	auipc	ra,0xffffd
    80004fca:	23e080e7          	jalr	574(ra) # 80002204 <myproc>
    80004fce:	591c                	lw	a5,48(a0)
    80004fd0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004fd2:	854a                	mv	a0,s2
    80004fd4:	ffffc097          	auipc	ra,0xffffc
    80004fd8:	ca2080e7          	jalr	-862(ra) # 80000c76 <release>
}
    80004fdc:	60e2                	ld	ra,24(sp)
    80004fde:	6442                	ld	s0,16(sp)
    80004fe0:	64a2                	ld	s1,8(sp)
    80004fe2:	6902                	ld	s2,0(sp)
    80004fe4:	6105                	addi	sp,sp,32
    80004fe6:	8082                	ret

0000000080004fe8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004fe8:	1101                	addi	sp,sp,-32
    80004fea:	ec06                	sd	ra,24(sp)
    80004fec:	e822                	sd	s0,16(sp)
    80004fee:	e426                	sd	s1,8(sp)
    80004ff0:	e04a                	sd	s2,0(sp)
    80004ff2:	1000                	addi	s0,sp,32
    80004ff4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ff6:	00850913          	addi	s2,a0,8
    80004ffa:	854a                	mv	a0,s2
    80004ffc:	ffffc097          	auipc	ra,0xffffc
    80005000:	bc6080e7          	jalr	-1082(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80005004:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005008:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000500c:	8526                	mv	a0,s1
    8000500e:	ffffe097          	auipc	ra,0xffffe
    80005012:	b7e080e7          	jalr	-1154(ra) # 80002b8c <wakeup>
  release(&lk->lk);
    80005016:	854a                	mv	a0,s2
    80005018:	ffffc097          	auipc	ra,0xffffc
    8000501c:	c5e080e7          	jalr	-930(ra) # 80000c76 <release>
}
    80005020:	60e2                	ld	ra,24(sp)
    80005022:	6442                	ld	s0,16(sp)
    80005024:	64a2                	ld	s1,8(sp)
    80005026:	6902                	ld	s2,0(sp)
    80005028:	6105                	addi	sp,sp,32
    8000502a:	8082                	ret

000000008000502c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000502c:	7179                	addi	sp,sp,-48
    8000502e:	f406                	sd	ra,40(sp)
    80005030:	f022                	sd	s0,32(sp)
    80005032:	ec26                	sd	s1,24(sp)
    80005034:	e84a                	sd	s2,16(sp)
    80005036:	e44e                	sd	s3,8(sp)
    80005038:	1800                	addi	s0,sp,48
    8000503a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000503c:	00850913          	addi	s2,a0,8
    80005040:	854a                	mv	a0,s2
    80005042:	ffffc097          	auipc	ra,0xffffc
    80005046:	b80080e7          	jalr	-1152(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000504a:	409c                	lw	a5,0(s1)
    8000504c:	ef99                	bnez	a5,8000506a <holdingsleep+0x3e>
    8000504e:	4481                	li	s1,0
  release(&lk->lk);
    80005050:	854a                	mv	a0,s2
    80005052:	ffffc097          	auipc	ra,0xffffc
    80005056:	c24080e7          	jalr	-988(ra) # 80000c76 <release>
  return r;
}
    8000505a:	8526                	mv	a0,s1
    8000505c:	70a2                	ld	ra,40(sp)
    8000505e:	7402                	ld	s0,32(sp)
    80005060:	64e2                	ld	s1,24(sp)
    80005062:	6942                	ld	s2,16(sp)
    80005064:	69a2                	ld	s3,8(sp)
    80005066:	6145                	addi	sp,sp,48
    80005068:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000506a:	0284a983          	lw	s3,40(s1)
    8000506e:	ffffd097          	auipc	ra,0xffffd
    80005072:	196080e7          	jalr	406(ra) # 80002204 <myproc>
    80005076:	5904                	lw	s1,48(a0)
    80005078:	413484b3          	sub	s1,s1,s3
    8000507c:	0014b493          	seqz	s1,s1
    80005080:	bfc1                	j	80005050 <holdingsleep+0x24>

0000000080005082 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80005082:	1141                	addi	sp,sp,-16
    80005084:	e406                	sd	ra,8(sp)
    80005086:	e022                	sd	s0,0(sp)
    80005088:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000508a:	00005597          	auipc	a1,0x5
    8000508e:	aae58593          	addi	a1,a1,-1362 # 80009b38 <syscalls+0x2a8>
    80005092:	00025517          	auipc	a0,0x25
    80005096:	92650513          	addi	a0,a0,-1754 # 800299b8 <ftable>
    8000509a:	ffffc097          	auipc	ra,0xffffc
    8000509e:	a98080e7          	jalr	-1384(ra) # 80000b32 <initlock>
}
    800050a2:	60a2                	ld	ra,8(sp)
    800050a4:	6402                	ld	s0,0(sp)
    800050a6:	0141                	addi	sp,sp,16
    800050a8:	8082                	ret

00000000800050aa <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800050aa:	1101                	addi	sp,sp,-32
    800050ac:	ec06                	sd	ra,24(sp)
    800050ae:	e822                	sd	s0,16(sp)
    800050b0:	e426                	sd	s1,8(sp)
    800050b2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800050b4:	00025517          	auipc	a0,0x25
    800050b8:	90450513          	addi	a0,a0,-1788 # 800299b8 <ftable>
    800050bc:	ffffc097          	auipc	ra,0xffffc
    800050c0:	b06080e7          	jalr	-1274(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800050c4:	00025497          	auipc	s1,0x25
    800050c8:	90c48493          	addi	s1,s1,-1780 # 800299d0 <ftable+0x18>
    800050cc:	00026717          	auipc	a4,0x26
    800050d0:	8a470713          	addi	a4,a4,-1884 # 8002a970 <ftable+0xfb8>
    if(f->ref == 0){
    800050d4:	40dc                	lw	a5,4(s1)
    800050d6:	cf99                	beqz	a5,800050f4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800050d8:	02848493          	addi	s1,s1,40
    800050dc:	fee49ce3          	bne	s1,a4,800050d4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800050e0:	00025517          	auipc	a0,0x25
    800050e4:	8d850513          	addi	a0,a0,-1832 # 800299b8 <ftable>
    800050e8:	ffffc097          	auipc	ra,0xffffc
    800050ec:	b8e080e7          	jalr	-1138(ra) # 80000c76 <release>
  return 0;
    800050f0:	4481                	li	s1,0
    800050f2:	a819                	j	80005108 <filealloc+0x5e>
      f->ref = 1;
    800050f4:	4785                	li	a5,1
    800050f6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800050f8:	00025517          	auipc	a0,0x25
    800050fc:	8c050513          	addi	a0,a0,-1856 # 800299b8 <ftable>
    80005100:	ffffc097          	auipc	ra,0xffffc
    80005104:	b76080e7          	jalr	-1162(ra) # 80000c76 <release>
}
    80005108:	8526                	mv	a0,s1
    8000510a:	60e2                	ld	ra,24(sp)
    8000510c:	6442                	ld	s0,16(sp)
    8000510e:	64a2                	ld	s1,8(sp)
    80005110:	6105                	addi	sp,sp,32
    80005112:	8082                	ret

0000000080005114 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005114:	1101                	addi	sp,sp,-32
    80005116:	ec06                	sd	ra,24(sp)
    80005118:	e822                	sd	s0,16(sp)
    8000511a:	e426                	sd	s1,8(sp)
    8000511c:	1000                	addi	s0,sp,32
    8000511e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80005120:	00025517          	auipc	a0,0x25
    80005124:	89850513          	addi	a0,a0,-1896 # 800299b8 <ftable>
    80005128:	ffffc097          	auipc	ra,0xffffc
    8000512c:	a9a080e7          	jalr	-1382(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80005130:	40dc                	lw	a5,4(s1)
    80005132:	02f05263          	blez	a5,80005156 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005136:	2785                	addiw	a5,a5,1
    80005138:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000513a:	00025517          	auipc	a0,0x25
    8000513e:	87e50513          	addi	a0,a0,-1922 # 800299b8 <ftable>
    80005142:	ffffc097          	auipc	ra,0xffffc
    80005146:	b34080e7          	jalr	-1228(ra) # 80000c76 <release>
  return f;
}
    8000514a:	8526                	mv	a0,s1
    8000514c:	60e2                	ld	ra,24(sp)
    8000514e:	6442                	ld	s0,16(sp)
    80005150:	64a2                	ld	s1,8(sp)
    80005152:	6105                	addi	sp,sp,32
    80005154:	8082                	ret
    panic("filedup");
    80005156:	00005517          	auipc	a0,0x5
    8000515a:	9ea50513          	addi	a0,a0,-1558 # 80009b40 <syscalls+0x2b0>
    8000515e:	ffffb097          	auipc	ra,0xffffb
    80005162:	3cc080e7          	jalr	972(ra) # 8000052a <panic>

0000000080005166 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005166:	7139                	addi	sp,sp,-64
    80005168:	fc06                	sd	ra,56(sp)
    8000516a:	f822                	sd	s0,48(sp)
    8000516c:	f426                	sd	s1,40(sp)
    8000516e:	f04a                	sd	s2,32(sp)
    80005170:	ec4e                	sd	s3,24(sp)
    80005172:	e852                	sd	s4,16(sp)
    80005174:	e456                	sd	s5,8(sp)
    80005176:	0080                	addi	s0,sp,64
    80005178:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000517a:	00025517          	auipc	a0,0x25
    8000517e:	83e50513          	addi	a0,a0,-1986 # 800299b8 <ftable>
    80005182:	ffffc097          	auipc	ra,0xffffc
    80005186:	a40080e7          	jalr	-1472(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    8000518a:	40dc                	lw	a5,4(s1)
    8000518c:	06f05163          	blez	a5,800051ee <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80005190:	37fd                	addiw	a5,a5,-1
    80005192:	0007871b          	sext.w	a4,a5
    80005196:	c0dc                	sw	a5,4(s1)
    80005198:	06e04363          	bgtz	a4,800051fe <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000519c:	0004a903          	lw	s2,0(s1)
    800051a0:	0094ca83          	lbu	s5,9(s1)
    800051a4:	0104ba03          	ld	s4,16(s1)
    800051a8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800051ac:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800051b0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800051b4:	00025517          	auipc	a0,0x25
    800051b8:	80450513          	addi	a0,a0,-2044 # 800299b8 <ftable>
    800051bc:	ffffc097          	auipc	ra,0xffffc
    800051c0:	aba080e7          	jalr	-1350(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    800051c4:	4785                	li	a5,1
    800051c6:	04f90d63          	beq	s2,a5,80005220 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800051ca:	3979                	addiw	s2,s2,-2
    800051cc:	4785                	li	a5,1
    800051ce:	0527e063          	bltu	a5,s2,8000520e <fileclose+0xa8>
    begin_op();
    800051d2:	00000097          	auipc	ra,0x0
    800051d6:	ac8080e7          	jalr	-1336(ra) # 80004c9a <begin_op>
    iput(ff.ip);
    800051da:	854e                	mv	a0,s3
    800051dc:	fffff097          	auipc	ra,0xfffff
    800051e0:	f90080e7          	jalr	-112(ra) # 8000416c <iput>
    end_op();
    800051e4:	00000097          	auipc	ra,0x0
    800051e8:	b36080e7          	jalr	-1226(ra) # 80004d1a <end_op>
    800051ec:	a00d                	j	8000520e <fileclose+0xa8>
    panic("fileclose");
    800051ee:	00005517          	auipc	a0,0x5
    800051f2:	95a50513          	addi	a0,a0,-1702 # 80009b48 <syscalls+0x2b8>
    800051f6:	ffffb097          	auipc	ra,0xffffb
    800051fa:	334080e7          	jalr	820(ra) # 8000052a <panic>
    release(&ftable.lock);
    800051fe:	00024517          	auipc	a0,0x24
    80005202:	7ba50513          	addi	a0,a0,1978 # 800299b8 <ftable>
    80005206:	ffffc097          	auipc	ra,0xffffc
    8000520a:	a70080e7          	jalr	-1424(ra) # 80000c76 <release>
  }
}
    8000520e:	70e2                	ld	ra,56(sp)
    80005210:	7442                	ld	s0,48(sp)
    80005212:	74a2                	ld	s1,40(sp)
    80005214:	7902                	ld	s2,32(sp)
    80005216:	69e2                	ld	s3,24(sp)
    80005218:	6a42                	ld	s4,16(sp)
    8000521a:	6aa2                	ld	s5,8(sp)
    8000521c:	6121                	addi	sp,sp,64
    8000521e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005220:	85d6                	mv	a1,s5
    80005222:	8552                	mv	a0,s4
    80005224:	00000097          	auipc	ra,0x0
    80005228:	542080e7          	jalr	1346(ra) # 80005766 <pipeclose>
    8000522c:	b7cd                	j	8000520e <fileclose+0xa8>

000000008000522e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000522e:	715d                	addi	sp,sp,-80
    80005230:	e486                	sd	ra,72(sp)
    80005232:	e0a2                	sd	s0,64(sp)
    80005234:	fc26                	sd	s1,56(sp)
    80005236:	f84a                	sd	s2,48(sp)
    80005238:	f44e                	sd	s3,40(sp)
    8000523a:	0880                	addi	s0,sp,80
    8000523c:	84aa                	mv	s1,a0
    8000523e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005240:	ffffd097          	auipc	ra,0xffffd
    80005244:	fc4080e7          	jalr	-60(ra) # 80002204 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005248:	409c                	lw	a5,0(s1)
    8000524a:	37f9                	addiw	a5,a5,-2
    8000524c:	4705                	li	a4,1
    8000524e:	04f76763          	bltu	a4,a5,8000529c <filestat+0x6e>
    80005252:	892a                	mv	s2,a0
    ilock(f->ip);
    80005254:	6c88                	ld	a0,24(s1)
    80005256:	fffff097          	auipc	ra,0xfffff
    8000525a:	d5c080e7          	jalr	-676(ra) # 80003fb2 <ilock>
    stati(f->ip, &st);
    8000525e:	fb840593          	addi	a1,s0,-72
    80005262:	6c88                	ld	a0,24(s1)
    80005264:	fffff097          	auipc	ra,0xfffff
    80005268:	fd8080e7          	jalr	-40(ra) # 8000423c <stati>
    iunlock(f->ip);
    8000526c:	6c88                	ld	a0,24(s1)
    8000526e:	fffff097          	auipc	ra,0xfffff
    80005272:	e06080e7          	jalr	-506(ra) # 80004074 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005276:	46e1                	li	a3,24
    80005278:	fb840613          	addi	a2,s0,-72
    8000527c:	85ce                	mv	a1,s3
    8000527e:	05093503          	ld	a0,80(s2)
    80005282:	ffffd097          	auipc	ra,0xffffd
    80005286:	c42080e7          	jalr	-958(ra) # 80001ec4 <copyout>
    8000528a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000528e:	60a6                	ld	ra,72(sp)
    80005290:	6406                	ld	s0,64(sp)
    80005292:	74e2                	ld	s1,56(sp)
    80005294:	7942                	ld	s2,48(sp)
    80005296:	79a2                	ld	s3,40(sp)
    80005298:	6161                	addi	sp,sp,80
    8000529a:	8082                	ret
  return -1;
    8000529c:	557d                	li	a0,-1
    8000529e:	bfc5                	j	8000528e <filestat+0x60>

00000000800052a0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800052a0:	7179                	addi	sp,sp,-48
    800052a2:	f406                	sd	ra,40(sp)
    800052a4:	f022                	sd	s0,32(sp)
    800052a6:	ec26                	sd	s1,24(sp)
    800052a8:	e84a                	sd	s2,16(sp)
    800052aa:	e44e                	sd	s3,8(sp)
    800052ac:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800052ae:	00854783          	lbu	a5,8(a0)
    800052b2:	c3d5                	beqz	a5,80005356 <fileread+0xb6>
    800052b4:	84aa                	mv	s1,a0
    800052b6:	89ae                	mv	s3,a1
    800052b8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800052ba:	411c                	lw	a5,0(a0)
    800052bc:	4705                	li	a4,1
    800052be:	04e78963          	beq	a5,a4,80005310 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800052c2:	470d                	li	a4,3
    800052c4:	04e78d63          	beq	a5,a4,8000531e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800052c8:	4709                	li	a4,2
    800052ca:	06e79e63          	bne	a5,a4,80005346 <fileread+0xa6>
    ilock(f->ip);
    800052ce:	6d08                	ld	a0,24(a0)
    800052d0:	fffff097          	auipc	ra,0xfffff
    800052d4:	ce2080e7          	jalr	-798(ra) # 80003fb2 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800052d8:	874a                	mv	a4,s2
    800052da:	5094                	lw	a3,32(s1)
    800052dc:	864e                	mv	a2,s3
    800052de:	4585                	li	a1,1
    800052e0:	6c88                	ld	a0,24(s1)
    800052e2:	fffff097          	auipc	ra,0xfffff
    800052e6:	f84080e7          	jalr	-124(ra) # 80004266 <readi>
    800052ea:	892a                	mv	s2,a0
    800052ec:	00a05563          	blez	a0,800052f6 <fileread+0x56>
      f->off += r;
    800052f0:	509c                	lw	a5,32(s1)
    800052f2:	9fa9                	addw	a5,a5,a0
    800052f4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800052f6:	6c88                	ld	a0,24(s1)
    800052f8:	fffff097          	auipc	ra,0xfffff
    800052fc:	d7c080e7          	jalr	-644(ra) # 80004074 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005300:	854a                	mv	a0,s2
    80005302:	70a2                	ld	ra,40(sp)
    80005304:	7402                	ld	s0,32(sp)
    80005306:	64e2                	ld	s1,24(sp)
    80005308:	6942                	ld	s2,16(sp)
    8000530a:	69a2                	ld	s3,8(sp)
    8000530c:	6145                	addi	sp,sp,48
    8000530e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005310:	6908                	ld	a0,16(a0)
    80005312:	00000097          	auipc	ra,0x0
    80005316:	5b6080e7          	jalr	1462(ra) # 800058c8 <piperead>
    8000531a:	892a                	mv	s2,a0
    8000531c:	b7d5                	j	80005300 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000531e:	02451783          	lh	a5,36(a0)
    80005322:	03079693          	slli	a3,a5,0x30
    80005326:	92c1                	srli	a3,a3,0x30
    80005328:	4725                	li	a4,9
    8000532a:	02d76863          	bltu	a4,a3,8000535a <fileread+0xba>
    8000532e:	0792                	slli	a5,a5,0x4
    80005330:	00024717          	auipc	a4,0x24
    80005334:	5e870713          	addi	a4,a4,1512 # 80029918 <devsw>
    80005338:	97ba                	add	a5,a5,a4
    8000533a:	639c                	ld	a5,0(a5)
    8000533c:	c38d                	beqz	a5,8000535e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000533e:	4505                	li	a0,1
    80005340:	9782                	jalr	a5
    80005342:	892a                	mv	s2,a0
    80005344:	bf75                	j	80005300 <fileread+0x60>
    panic("fileread");
    80005346:	00005517          	auipc	a0,0x5
    8000534a:	81250513          	addi	a0,a0,-2030 # 80009b58 <syscalls+0x2c8>
    8000534e:	ffffb097          	auipc	ra,0xffffb
    80005352:	1dc080e7          	jalr	476(ra) # 8000052a <panic>
    return -1;
    80005356:	597d                	li	s2,-1
    80005358:	b765                	j	80005300 <fileread+0x60>
      return -1;
    8000535a:	597d                	li	s2,-1
    8000535c:	b755                	j	80005300 <fileread+0x60>
    8000535e:	597d                	li	s2,-1
    80005360:	b745                	j	80005300 <fileread+0x60>

0000000080005362 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005362:	715d                	addi	sp,sp,-80
    80005364:	e486                	sd	ra,72(sp)
    80005366:	e0a2                	sd	s0,64(sp)
    80005368:	fc26                	sd	s1,56(sp)
    8000536a:	f84a                	sd	s2,48(sp)
    8000536c:	f44e                	sd	s3,40(sp)
    8000536e:	f052                	sd	s4,32(sp)
    80005370:	ec56                	sd	s5,24(sp)
    80005372:	e85a                	sd	s6,16(sp)
    80005374:	e45e                	sd	s7,8(sp)
    80005376:	e062                	sd	s8,0(sp)
    80005378:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000537a:	00954783          	lbu	a5,9(a0)
    8000537e:	10078663          	beqz	a5,8000548a <filewrite+0x128>
    80005382:	892a                	mv	s2,a0
    80005384:	8aae                	mv	s5,a1
    80005386:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005388:	411c                	lw	a5,0(a0)
    8000538a:	4705                	li	a4,1
    8000538c:	02e78263          	beq	a5,a4,800053b0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005390:	470d                	li	a4,3
    80005392:	02e78663          	beq	a5,a4,800053be <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005396:	4709                	li	a4,2
    80005398:	0ee79163          	bne	a5,a4,8000547a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000539c:	0ac05d63          	blez	a2,80005456 <filewrite+0xf4>
    int i = 0;
    800053a0:	4981                	li	s3,0
    800053a2:	6b05                	lui	s6,0x1
    800053a4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800053a8:	6b85                	lui	s7,0x1
    800053aa:	c00b8b9b          	addiw	s7,s7,-1024
    800053ae:	a861                	j	80005446 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800053b0:	6908                	ld	a0,16(a0)
    800053b2:	00000097          	auipc	ra,0x0
    800053b6:	424080e7          	jalr	1060(ra) # 800057d6 <pipewrite>
    800053ba:	8a2a                	mv	s4,a0
    800053bc:	a045                	j	8000545c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800053be:	02451783          	lh	a5,36(a0)
    800053c2:	03079693          	slli	a3,a5,0x30
    800053c6:	92c1                	srli	a3,a3,0x30
    800053c8:	4725                	li	a4,9
    800053ca:	0cd76263          	bltu	a4,a3,8000548e <filewrite+0x12c>
    800053ce:	0792                	slli	a5,a5,0x4
    800053d0:	00024717          	auipc	a4,0x24
    800053d4:	54870713          	addi	a4,a4,1352 # 80029918 <devsw>
    800053d8:	97ba                	add	a5,a5,a4
    800053da:	679c                	ld	a5,8(a5)
    800053dc:	cbdd                	beqz	a5,80005492 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800053de:	4505                	li	a0,1
    800053e0:	9782                	jalr	a5
    800053e2:	8a2a                	mv	s4,a0
    800053e4:	a8a5                	j	8000545c <filewrite+0xfa>
    800053e6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800053ea:	00000097          	auipc	ra,0x0
    800053ee:	8b0080e7          	jalr	-1872(ra) # 80004c9a <begin_op>
      ilock(f->ip);
    800053f2:	01893503          	ld	a0,24(s2)
    800053f6:	fffff097          	auipc	ra,0xfffff
    800053fa:	bbc080e7          	jalr	-1092(ra) # 80003fb2 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800053fe:	8762                	mv	a4,s8
    80005400:	02092683          	lw	a3,32(s2)
    80005404:	01598633          	add	a2,s3,s5
    80005408:	4585                	li	a1,1
    8000540a:	01893503          	ld	a0,24(s2)
    8000540e:	fffff097          	auipc	ra,0xfffff
    80005412:	f50080e7          	jalr	-176(ra) # 8000435e <writei>
    80005416:	84aa                	mv	s1,a0
    80005418:	00a05763          	blez	a0,80005426 <filewrite+0xc4>
        f->off += r;
    8000541c:	02092783          	lw	a5,32(s2)
    80005420:	9fa9                	addw	a5,a5,a0
    80005422:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005426:	01893503          	ld	a0,24(s2)
    8000542a:	fffff097          	auipc	ra,0xfffff
    8000542e:	c4a080e7          	jalr	-950(ra) # 80004074 <iunlock>
      end_op();
    80005432:	00000097          	auipc	ra,0x0
    80005436:	8e8080e7          	jalr	-1816(ra) # 80004d1a <end_op>

      if(r != n1){
    8000543a:	009c1f63          	bne	s8,s1,80005458 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000543e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005442:	0149db63          	bge	s3,s4,80005458 <filewrite+0xf6>
      int n1 = n - i;
    80005446:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000544a:	84be                	mv	s1,a5
    8000544c:	2781                	sext.w	a5,a5
    8000544e:	f8fb5ce3          	bge	s6,a5,800053e6 <filewrite+0x84>
    80005452:	84de                	mv	s1,s7
    80005454:	bf49                	j	800053e6 <filewrite+0x84>
    int i = 0;
    80005456:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005458:	013a1f63          	bne	s4,s3,80005476 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000545c:	8552                	mv	a0,s4
    8000545e:	60a6                	ld	ra,72(sp)
    80005460:	6406                	ld	s0,64(sp)
    80005462:	74e2                	ld	s1,56(sp)
    80005464:	7942                	ld	s2,48(sp)
    80005466:	79a2                	ld	s3,40(sp)
    80005468:	7a02                	ld	s4,32(sp)
    8000546a:	6ae2                	ld	s5,24(sp)
    8000546c:	6b42                	ld	s6,16(sp)
    8000546e:	6ba2                	ld	s7,8(sp)
    80005470:	6c02                	ld	s8,0(sp)
    80005472:	6161                	addi	sp,sp,80
    80005474:	8082                	ret
    ret = (i == n ? n : -1);
    80005476:	5a7d                	li	s4,-1
    80005478:	b7d5                	j	8000545c <filewrite+0xfa>
    panic("filewrite");
    8000547a:	00004517          	auipc	a0,0x4
    8000547e:	6ee50513          	addi	a0,a0,1774 # 80009b68 <syscalls+0x2d8>
    80005482:	ffffb097          	auipc	ra,0xffffb
    80005486:	0a8080e7          	jalr	168(ra) # 8000052a <panic>
    return -1;
    8000548a:	5a7d                	li	s4,-1
    8000548c:	bfc1                	j	8000545c <filewrite+0xfa>
      return -1;
    8000548e:	5a7d                	li	s4,-1
    80005490:	b7f1                	j	8000545c <filewrite+0xfa>
    80005492:	5a7d                	li	s4,-1
    80005494:	b7e1                	j	8000545c <filewrite+0xfa>

0000000080005496 <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    80005496:	7179                	addi	sp,sp,-48
    80005498:	f406                	sd	ra,40(sp)
    8000549a:	f022                	sd	s0,32(sp)
    8000549c:	ec26                	sd	s1,24(sp)
    8000549e:	e84a                	sd	s2,16(sp)
    800054a0:	e44e                	sd	s3,8(sp)
    800054a2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800054a4:	00854783          	lbu	a5,8(a0)
    800054a8:	c3d5                	beqz	a5,8000554c <kfileread+0xb6>
    800054aa:	84aa                	mv	s1,a0
    800054ac:	89ae                	mv	s3,a1
    800054ae:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800054b0:	411c                	lw	a5,0(a0)
    800054b2:	4705                	li	a4,1
    800054b4:	04e78963          	beq	a5,a4,80005506 <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800054b8:	470d                	li	a4,3
    800054ba:	04e78d63          	beq	a5,a4,80005514 <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800054be:	4709                	li	a4,2
    800054c0:	06e79e63          	bne	a5,a4,8000553c <kfileread+0xa6>
    ilock(f->ip);
    800054c4:	6d08                	ld	a0,24(a0)
    800054c6:	fffff097          	auipc	ra,0xfffff
    800054ca:	aec080e7          	jalr	-1300(ra) # 80003fb2 <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    800054ce:	874a                	mv	a4,s2
    800054d0:	5094                	lw	a3,32(s1)
    800054d2:	864e                	mv	a2,s3
    800054d4:	4581                	li	a1,0
    800054d6:	6c88                	ld	a0,24(s1)
    800054d8:	fffff097          	auipc	ra,0xfffff
    800054dc:	d8e080e7          	jalr	-626(ra) # 80004266 <readi>
    800054e0:	892a                	mv	s2,a0
    800054e2:	00a05563          	blez	a0,800054ec <kfileread+0x56>
      f->off += r;
    800054e6:	509c                	lw	a5,32(s1)
    800054e8:	9fa9                	addw	a5,a5,a0
    800054ea:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800054ec:	6c88                	ld	a0,24(s1)
    800054ee:	fffff097          	auipc	ra,0xfffff
    800054f2:	b86080e7          	jalr	-1146(ra) # 80004074 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800054f6:	854a                	mv	a0,s2
    800054f8:	70a2                	ld	ra,40(sp)
    800054fa:	7402                	ld	s0,32(sp)
    800054fc:	64e2                	ld	s1,24(sp)
    800054fe:	6942                	ld	s2,16(sp)
    80005500:	69a2                	ld	s3,8(sp)
    80005502:	6145                	addi	sp,sp,48
    80005504:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005506:	6908                	ld	a0,16(a0)
    80005508:	00000097          	auipc	ra,0x0
    8000550c:	3c0080e7          	jalr	960(ra) # 800058c8 <piperead>
    80005510:	892a                	mv	s2,a0
    80005512:	b7d5                	j	800054f6 <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005514:	02451783          	lh	a5,36(a0)
    80005518:	03079693          	slli	a3,a5,0x30
    8000551c:	92c1                	srli	a3,a3,0x30
    8000551e:	4725                	li	a4,9
    80005520:	02d76863          	bltu	a4,a3,80005550 <kfileread+0xba>
    80005524:	0792                	slli	a5,a5,0x4
    80005526:	00024717          	auipc	a4,0x24
    8000552a:	3f270713          	addi	a4,a4,1010 # 80029918 <devsw>
    8000552e:	97ba                	add	a5,a5,a4
    80005530:	639c                	ld	a5,0(a5)
    80005532:	c38d                	beqz	a5,80005554 <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005534:	4505                	li	a0,1
    80005536:	9782                	jalr	a5
    80005538:	892a                	mv	s2,a0
    8000553a:	bf75                	j	800054f6 <kfileread+0x60>
    panic("fileread");
    8000553c:	00004517          	auipc	a0,0x4
    80005540:	61c50513          	addi	a0,a0,1564 # 80009b58 <syscalls+0x2c8>
    80005544:	ffffb097          	auipc	ra,0xffffb
    80005548:	fe6080e7          	jalr	-26(ra) # 8000052a <panic>
    return -1;
    8000554c:	597d                	li	s2,-1
    8000554e:	b765                	j	800054f6 <kfileread+0x60>
      return -1;
    80005550:	597d                	li	s2,-1
    80005552:	b755                	j	800054f6 <kfileread+0x60>
    80005554:	597d                	li	s2,-1
    80005556:	b745                	j	800054f6 <kfileread+0x60>

0000000080005558 <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    80005558:	715d                	addi	sp,sp,-80
    8000555a:	e486                	sd	ra,72(sp)
    8000555c:	e0a2                	sd	s0,64(sp)
    8000555e:	fc26                	sd	s1,56(sp)
    80005560:	f84a                	sd	s2,48(sp)
    80005562:	f44e                	sd	s3,40(sp)
    80005564:	f052                	sd	s4,32(sp)
    80005566:	ec56                	sd	s5,24(sp)
    80005568:	e85a                	sd	s6,16(sp)
    8000556a:	e45e                	sd	s7,8(sp)
    8000556c:	e062                	sd	s8,0(sp)
    8000556e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005570:	00954783          	lbu	a5,9(a0)
    80005574:	10078663          	beqz	a5,80005680 <kfilewrite+0x128>
    80005578:	892a                	mv	s2,a0
    8000557a:	8aae                	mv	s5,a1
    8000557c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000557e:	411c                	lw	a5,0(a0)
    80005580:	4705                	li	a4,1
    80005582:	02e78263          	beq	a5,a4,800055a6 <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){ 
    80005586:	470d                	li	a4,3
    80005588:	02e78663          	beq	a5,a4,800055b4 <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000558c:	4709                	li	a4,2
    8000558e:	0ee79163          	bne	a5,a4,80005670 <kfilewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005592:	0ac05d63          	blez	a2,8000564c <kfilewrite+0xf4>
    int i = 0;
    80005596:	4981                	li	s3,0
    80005598:	6b05                	lui	s6,0x1
    8000559a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000559e:	6b85                	lui	s7,0x1
    800055a0:	c00b8b9b          	addiw	s7,s7,-1024
    800055a4:	a861                	j	8000563c <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800055a6:	6908                	ld	a0,16(a0)
    800055a8:	00000097          	auipc	ra,0x0
    800055ac:	22e080e7          	jalr	558(ra) # 800057d6 <pipewrite>
    800055b0:	8a2a                	mv	s4,a0
    800055b2:	a045                	j	80005652 <kfilewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800055b4:	02451783          	lh	a5,36(a0)
    800055b8:	03079693          	slli	a3,a5,0x30
    800055bc:	92c1                	srli	a3,a3,0x30
    800055be:	4725                	li	a4,9
    800055c0:	0cd76263          	bltu	a4,a3,80005684 <kfilewrite+0x12c>
    800055c4:	0792                	slli	a5,a5,0x4
    800055c6:	00024717          	auipc	a4,0x24
    800055ca:	35270713          	addi	a4,a4,850 # 80029918 <devsw>
    800055ce:	97ba                	add	a5,a5,a4
    800055d0:	679c                	ld	a5,8(a5)
    800055d2:	cbdd                	beqz	a5,80005688 <kfilewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800055d4:	4505                	li	a0,1
    800055d6:	9782                	jalr	a5
    800055d8:	8a2a                	mv	s4,a0
    800055da:	a8a5                	j	80005652 <kfilewrite+0xfa>
    800055dc:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800055e0:	fffff097          	auipc	ra,0xfffff
    800055e4:	6ba080e7          	jalr	1722(ra) # 80004c9a <begin_op>
      ilock(f->ip);
    800055e8:	01893503          	ld	a0,24(s2)
    800055ec:	fffff097          	auipc	ra,0xfffff
    800055f0:	9c6080e7          	jalr	-1594(ra) # 80003fb2 <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    800055f4:	8762                	mv	a4,s8
    800055f6:	02092683          	lw	a3,32(s2)
    800055fa:	01598633          	add	a2,s3,s5
    800055fe:	4581                	li	a1,0
    80005600:	01893503          	ld	a0,24(s2)
    80005604:	fffff097          	auipc	ra,0xfffff
    80005608:	d5a080e7          	jalr	-678(ra) # 8000435e <writei>
    8000560c:	84aa                	mv	s1,a0
    8000560e:	00a05763          	blez	a0,8000561c <kfilewrite+0xc4>
        f->off += r;
    80005612:	02092783          	lw	a5,32(s2)
    80005616:	9fa9                	addw	a5,a5,a0
    80005618:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000561c:	01893503          	ld	a0,24(s2)
    80005620:	fffff097          	auipc	ra,0xfffff
    80005624:	a54080e7          	jalr	-1452(ra) # 80004074 <iunlock>
      end_op();
    80005628:	fffff097          	auipc	ra,0xfffff
    8000562c:	6f2080e7          	jalr	1778(ra) # 80004d1a <end_op>

      if(r != n1){
    80005630:	009c1f63          	bne	s8,s1,8000564e <kfilewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005634:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005638:	0149db63          	bge	s3,s4,8000564e <kfilewrite+0xf6>
      int n1 = n - i;
    8000563c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005640:	84be                	mv	s1,a5
    80005642:	2781                	sext.w	a5,a5
    80005644:	f8fb5ce3          	bge	s6,a5,800055dc <kfilewrite+0x84>
    80005648:	84de                	mv	s1,s7
    8000564a:	bf49                	j	800055dc <kfilewrite+0x84>
    int i = 0;
    8000564c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000564e:	013a1f63          	bne	s4,s3,8000566c <kfilewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
    80005652:	8552                	mv	a0,s4
    80005654:	60a6                	ld	ra,72(sp)
    80005656:	6406                	ld	s0,64(sp)
    80005658:	74e2                	ld	s1,56(sp)
    8000565a:	7942                	ld	s2,48(sp)
    8000565c:	79a2                	ld	s3,40(sp)
    8000565e:	7a02                	ld	s4,32(sp)
    80005660:	6ae2                	ld	s5,24(sp)
    80005662:	6b42                	ld	s6,16(sp)
    80005664:	6ba2                	ld	s7,8(sp)
    80005666:	6c02                	ld	s8,0(sp)
    80005668:	6161                	addi	sp,sp,80
    8000566a:	8082                	ret
    ret = (i == n ? n : -1);
    8000566c:	5a7d                	li	s4,-1
    8000566e:	b7d5                	j	80005652 <kfilewrite+0xfa>
    panic("filewrite");
    80005670:	00004517          	auipc	a0,0x4
    80005674:	4f850513          	addi	a0,a0,1272 # 80009b68 <syscalls+0x2d8>
    80005678:	ffffb097          	auipc	ra,0xffffb
    8000567c:	eb2080e7          	jalr	-334(ra) # 8000052a <panic>
    return -1;
    80005680:	5a7d                	li	s4,-1
    80005682:	bfc1                	j	80005652 <kfilewrite+0xfa>
      return -1;
    80005684:	5a7d                	li	s4,-1
    80005686:	b7f1                	j	80005652 <kfilewrite+0xfa>
    80005688:	5a7d                	li	s4,-1
    8000568a:	b7e1                	j	80005652 <kfilewrite+0xfa>

000000008000568c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000568c:	7179                	addi	sp,sp,-48
    8000568e:	f406                	sd	ra,40(sp)
    80005690:	f022                	sd	s0,32(sp)
    80005692:	ec26                	sd	s1,24(sp)
    80005694:	e84a                	sd	s2,16(sp)
    80005696:	e44e                	sd	s3,8(sp)
    80005698:	e052                	sd	s4,0(sp)
    8000569a:	1800                	addi	s0,sp,48
    8000569c:	84aa                	mv	s1,a0
    8000569e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800056a0:	0005b023          	sd	zero,0(a1)
    800056a4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800056a8:	00000097          	auipc	ra,0x0
    800056ac:	a02080e7          	jalr	-1534(ra) # 800050aa <filealloc>
    800056b0:	e088                	sd	a0,0(s1)
    800056b2:	c551                	beqz	a0,8000573e <pipealloc+0xb2>
    800056b4:	00000097          	auipc	ra,0x0
    800056b8:	9f6080e7          	jalr	-1546(ra) # 800050aa <filealloc>
    800056bc:	00aa3023          	sd	a0,0(s4)
    800056c0:	c92d                	beqz	a0,80005732 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800056c2:	ffffb097          	auipc	ra,0xffffb
    800056c6:	410080e7          	jalr	1040(ra) # 80000ad2 <kalloc>
    800056ca:	892a                	mv	s2,a0
    800056cc:	c125                	beqz	a0,8000572c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800056ce:	4985                	li	s3,1
    800056d0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800056d4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800056d8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800056dc:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800056e0:	00004597          	auipc	a1,0x4
    800056e4:	49858593          	addi	a1,a1,1176 # 80009b78 <syscalls+0x2e8>
    800056e8:	ffffb097          	auipc	ra,0xffffb
    800056ec:	44a080e7          	jalr	1098(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    800056f0:	609c                	ld	a5,0(s1)
    800056f2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800056f6:	609c                	ld	a5,0(s1)
    800056f8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800056fc:	609c                	ld	a5,0(s1)
    800056fe:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005702:	609c                	ld	a5,0(s1)
    80005704:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005708:	000a3783          	ld	a5,0(s4)
    8000570c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005710:	000a3783          	ld	a5,0(s4)
    80005714:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005718:	000a3783          	ld	a5,0(s4)
    8000571c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005720:	000a3783          	ld	a5,0(s4)
    80005724:	0127b823          	sd	s2,16(a5)
  return 0;
    80005728:	4501                	li	a0,0
    8000572a:	a025                	j	80005752 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000572c:	6088                	ld	a0,0(s1)
    8000572e:	e501                	bnez	a0,80005736 <pipealloc+0xaa>
    80005730:	a039                	j	8000573e <pipealloc+0xb2>
    80005732:	6088                	ld	a0,0(s1)
    80005734:	c51d                	beqz	a0,80005762 <pipealloc+0xd6>
    fileclose(*f0);
    80005736:	00000097          	auipc	ra,0x0
    8000573a:	a30080e7          	jalr	-1488(ra) # 80005166 <fileclose>
  if(*f1)
    8000573e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005742:	557d                	li	a0,-1
  if(*f1)
    80005744:	c799                	beqz	a5,80005752 <pipealloc+0xc6>
    fileclose(*f1);
    80005746:	853e                	mv	a0,a5
    80005748:	00000097          	auipc	ra,0x0
    8000574c:	a1e080e7          	jalr	-1506(ra) # 80005166 <fileclose>
  return -1;
    80005750:	557d                	li	a0,-1
}
    80005752:	70a2                	ld	ra,40(sp)
    80005754:	7402                	ld	s0,32(sp)
    80005756:	64e2                	ld	s1,24(sp)
    80005758:	6942                	ld	s2,16(sp)
    8000575a:	69a2                	ld	s3,8(sp)
    8000575c:	6a02                	ld	s4,0(sp)
    8000575e:	6145                	addi	sp,sp,48
    80005760:	8082                	ret
  return -1;
    80005762:	557d                	li	a0,-1
    80005764:	b7fd                	j	80005752 <pipealloc+0xc6>

0000000080005766 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005766:	1101                	addi	sp,sp,-32
    80005768:	ec06                	sd	ra,24(sp)
    8000576a:	e822                	sd	s0,16(sp)
    8000576c:	e426                	sd	s1,8(sp)
    8000576e:	e04a                	sd	s2,0(sp)
    80005770:	1000                	addi	s0,sp,32
    80005772:	84aa                	mv	s1,a0
    80005774:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005776:	ffffb097          	auipc	ra,0xffffb
    8000577a:	44c080e7          	jalr	1100(ra) # 80000bc2 <acquire>
  if(writable){
    8000577e:	02090d63          	beqz	s2,800057b8 <pipeclose+0x52>
    pi->writeopen = 0;
    80005782:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005786:	21848513          	addi	a0,s1,536
    8000578a:	ffffd097          	auipc	ra,0xffffd
    8000578e:	402080e7          	jalr	1026(ra) # 80002b8c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005792:	2204b783          	ld	a5,544(s1)
    80005796:	eb95                	bnez	a5,800057ca <pipeclose+0x64>
    release(&pi->lock);
    80005798:	8526                	mv	a0,s1
    8000579a:	ffffb097          	auipc	ra,0xffffb
    8000579e:	4dc080e7          	jalr	1244(ra) # 80000c76 <release>
    kfree((char*)pi);
    800057a2:	8526                	mv	a0,s1
    800057a4:	ffffb097          	auipc	ra,0xffffb
    800057a8:	232080e7          	jalr	562(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    800057ac:	60e2                	ld	ra,24(sp)
    800057ae:	6442                	ld	s0,16(sp)
    800057b0:	64a2                	ld	s1,8(sp)
    800057b2:	6902                	ld	s2,0(sp)
    800057b4:	6105                	addi	sp,sp,32
    800057b6:	8082                	ret
    pi->readopen = 0;
    800057b8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800057bc:	21c48513          	addi	a0,s1,540
    800057c0:	ffffd097          	auipc	ra,0xffffd
    800057c4:	3cc080e7          	jalr	972(ra) # 80002b8c <wakeup>
    800057c8:	b7e9                	j	80005792 <pipeclose+0x2c>
    release(&pi->lock);
    800057ca:	8526                	mv	a0,s1
    800057cc:	ffffb097          	auipc	ra,0xffffb
    800057d0:	4aa080e7          	jalr	1194(ra) # 80000c76 <release>
}
    800057d4:	bfe1                	j	800057ac <pipeclose+0x46>

00000000800057d6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800057d6:	711d                	addi	sp,sp,-96
    800057d8:	ec86                	sd	ra,88(sp)
    800057da:	e8a2                	sd	s0,80(sp)
    800057dc:	e4a6                	sd	s1,72(sp)
    800057de:	e0ca                	sd	s2,64(sp)
    800057e0:	fc4e                	sd	s3,56(sp)
    800057e2:	f852                	sd	s4,48(sp)
    800057e4:	f456                	sd	s5,40(sp)
    800057e6:	f05a                	sd	s6,32(sp)
    800057e8:	ec5e                	sd	s7,24(sp)
    800057ea:	e862                	sd	s8,16(sp)
    800057ec:	1080                	addi	s0,sp,96
    800057ee:	84aa                	mv	s1,a0
    800057f0:	8aae                	mv	s5,a1
    800057f2:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800057f4:	ffffd097          	auipc	ra,0xffffd
    800057f8:	a10080e7          	jalr	-1520(ra) # 80002204 <myproc>
    800057fc:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800057fe:	8526                	mv	a0,s1
    80005800:	ffffb097          	auipc	ra,0xffffb
    80005804:	3c2080e7          	jalr	962(ra) # 80000bc2 <acquire>
  while(i < n){
    80005808:	0b405363          	blez	s4,800058ae <pipewrite+0xd8>
  int i = 0;
    8000580c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000580e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005810:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005814:	21c48b93          	addi	s7,s1,540
    80005818:	a089                	j	8000585a <pipewrite+0x84>
      release(&pi->lock);
    8000581a:	8526                	mv	a0,s1
    8000581c:	ffffb097          	auipc	ra,0xffffb
    80005820:	45a080e7          	jalr	1114(ra) # 80000c76 <release>
      return -1;
    80005824:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005826:	854a                	mv	a0,s2
    80005828:	60e6                	ld	ra,88(sp)
    8000582a:	6446                	ld	s0,80(sp)
    8000582c:	64a6                	ld	s1,72(sp)
    8000582e:	6906                	ld	s2,64(sp)
    80005830:	79e2                	ld	s3,56(sp)
    80005832:	7a42                	ld	s4,48(sp)
    80005834:	7aa2                	ld	s5,40(sp)
    80005836:	7b02                	ld	s6,32(sp)
    80005838:	6be2                	ld	s7,24(sp)
    8000583a:	6c42                	ld	s8,16(sp)
    8000583c:	6125                	addi	sp,sp,96
    8000583e:	8082                	ret
      wakeup(&pi->nread);
    80005840:	8562                	mv	a0,s8
    80005842:	ffffd097          	auipc	ra,0xffffd
    80005846:	34a080e7          	jalr	842(ra) # 80002b8c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000584a:	85a6                	mv	a1,s1
    8000584c:	855e                	mv	a0,s7
    8000584e:	ffffd097          	auipc	ra,0xffffd
    80005852:	1b2080e7          	jalr	434(ra) # 80002a00 <sleep>
  while(i < n){
    80005856:	05495d63          	bge	s2,s4,800058b0 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    8000585a:	2204a783          	lw	a5,544(s1)
    8000585e:	dfd5                	beqz	a5,8000581a <pipewrite+0x44>
    80005860:	0289a783          	lw	a5,40(s3)
    80005864:	fbdd                	bnez	a5,8000581a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005866:	2184a783          	lw	a5,536(s1)
    8000586a:	21c4a703          	lw	a4,540(s1)
    8000586e:	2007879b          	addiw	a5,a5,512
    80005872:	fcf707e3          	beq	a4,a5,80005840 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005876:	4685                	li	a3,1
    80005878:	01590633          	add	a2,s2,s5
    8000587c:	faf40593          	addi	a1,s0,-81
    80005880:	0509b503          	ld	a0,80(s3)
    80005884:	ffffc097          	auipc	ra,0xffffc
    80005888:	6cc080e7          	jalr	1740(ra) # 80001f50 <copyin>
    8000588c:	03650263          	beq	a0,s6,800058b0 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005890:	21c4a783          	lw	a5,540(s1)
    80005894:	0017871b          	addiw	a4,a5,1
    80005898:	20e4ae23          	sw	a4,540(s1)
    8000589c:	1ff7f793          	andi	a5,a5,511
    800058a0:	97a6                	add	a5,a5,s1
    800058a2:	faf44703          	lbu	a4,-81(s0)
    800058a6:	00e78c23          	sb	a4,24(a5)
      i++;
    800058aa:	2905                	addiw	s2,s2,1
    800058ac:	b76d                	j	80005856 <pipewrite+0x80>
  int i = 0;
    800058ae:	4901                	li	s2,0
  wakeup(&pi->nread);
    800058b0:	21848513          	addi	a0,s1,536
    800058b4:	ffffd097          	auipc	ra,0xffffd
    800058b8:	2d8080e7          	jalr	728(ra) # 80002b8c <wakeup>
  release(&pi->lock);
    800058bc:	8526                	mv	a0,s1
    800058be:	ffffb097          	auipc	ra,0xffffb
    800058c2:	3b8080e7          	jalr	952(ra) # 80000c76 <release>
  return i;
    800058c6:	b785                	j	80005826 <pipewrite+0x50>

00000000800058c8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800058c8:	715d                	addi	sp,sp,-80
    800058ca:	e486                	sd	ra,72(sp)
    800058cc:	e0a2                	sd	s0,64(sp)
    800058ce:	fc26                	sd	s1,56(sp)
    800058d0:	f84a                	sd	s2,48(sp)
    800058d2:	f44e                	sd	s3,40(sp)
    800058d4:	f052                	sd	s4,32(sp)
    800058d6:	ec56                	sd	s5,24(sp)
    800058d8:	e85a                	sd	s6,16(sp)
    800058da:	0880                	addi	s0,sp,80
    800058dc:	84aa                	mv	s1,a0
    800058de:	892e                	mv	s2,a1
    800058e0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800058e2:	ffffd097          	auipc	ra,0xffffd
    800058e6:	922080e7          	jalr	-1758(ra) # 80002204 <myproc>
    800058ea:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800058ec:	8526                	mv	a0,s1
    800058ee:	ffffb097          	auipc	ra,0xffffb
    800058f2:	2d4080e7          	jalr	724(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800058f6:	2184a703          	lw	a4,536(s1)
    800058fa:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800058fe:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005902:	02f71463          	bne	a4,a5,8000592a <piperead+0x62>
    80005906:	2244a783          	lw	a5,548(s1)
    8000590a:	c385                	beqz	a5,8000592a <piperead+0x62>
    if(pr->killed){
    8000590c:	028a2783          	lw	a5,40(s4)
    80005910:	ebc1                	bnez	a5,800059a0 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005912:	85a6                	mv	a1,s1
    80005914:	854e                	mv	a0,s3
    80005916:	ffffd097          	auipc	ra,0xffffd
    8000591a:	0ea080e7          	jalr	234(ra) # 80002a00 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000591e:	2184a703          	lw	a4,536(s1)
    80005922:	21c4a783          	lw	a5,540(s1)
    80005926:	fef700e3          	beq	a4,a5,80005906 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000592a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000592c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000592e:	05505363          	blez	s5,80005974 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80005932:	2184a783          	lw	a5,536(s1)
    80005936:	21c4a703          	lw	a4,540(s1)
    8000593a:	02f70d63          	beq	a4,a5,80005974 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000593e:	0017871b          	addiw	a4,a5,1
    80005942:	20e4ac23          	sw	a4,536(s1)
    80005946:	1ff7f793          	andi	a5,a5,511
    8000594a:	97a6                	add	a5,a5,s1
    8000594c:	0187c783          	lbu	a5,24(a5)
    80005950:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005954:	4685                	li	a3,1
    80005956:	fbf40613          	addi	a2,s0,-65
    8000595a:	85ca                	mv	a1,s2
    8000595c:	050a3503          	ld	a0,80(s4)
    80005960:	ffffc097          	auipc	ra,0xffffc
    80005964:	564080e7          	jalr	1380(ra) # 80001ec4 <copyout>
    80005968:	01650663          	beq	a0,s6,80005974 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000596c:	2985                	addiw	s3,s3,1
    8000596e:	0905                	addi	s2,s2,1
    80005970:	fd3a91e3          	bne	s5,s3,80005932 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005974:	21c48513          	addi	a0,s1,540
    80005978:	ffffd097          	auipc	ra,0xffffd
    8000597c:	214080e7          	jalr	532(ra) # 80002b8c <wakeup>
  release(&pi->lock);
    80005980:	8526                	mv	a0,s1
    80005982:	ffffb097          	auipc	ra,0xffffb
    80005986:	2f4080e7          	jalr	756(ra) # 80000c76 <release>
  return i;
}
    8000598a:	854e                	mv	a0,s3
    8000598c:	60a6                	ld	ra,72(sp)
    8000598e:	6406                	ld	s0,64(sp)
    80005990:	74e2                	ld	s1,56(sp)
    80005992:	7942                	ld	s2,48(sp)
    80005994:	79a2                	ld	s3,40(sp)
    80005996:	7a02                	ld	s4,32(sp)
    80005998:	6ae2                	ld	s5,24(sp)
    8000599a:	6b42                	ld	s6,16(sp)
    8000599c:	6161                	addi	sp,sp,80
    8000599e:	8082                	ret
      release(&pi->lock);
    800059a0:	8526                	mv	a0,s1
    800059a2:	ffffb097          	auipc	ra,0xffffb
    800059a6:	2d4080e7          	jalr	724(ra) # 80000c76 <release>
      return -1;
    800059aa:	59fd                	li	s3,-1
    800059ac:	bff9                	j	8000598a <piperead+0xc2>

00000000800059ae <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800059ae:	de010113          	addi	sp,sp,-544
    800059b2:	20113c23          	sd	ra,536(sp)
    800059b6:	20813823          	sd	s0,528(sp)
    800059ba:	20913423          	sd	s1,520(sp)
    800059be:	21213023          	sd	s2,512(sp)
    800059c2:	ffce                	sd	s3,504(sp)
    800059c4:	fbd2                	sd	s4,496(sp)
    800059c6:	f7d6                	sd	s5,488(sp)
    800059c8:	f3da                	sd	s6,480(sp)
    800059ca:	efde                	sd	s7,472(sp)
    800059cc:	ebe2                	sd	s8,464(sp)
    800059ce:	e7e6                	sd	s9,456(sp)
    800059d0:	e3ea                	sd	s10,448(sp)
    800059d2:	ff6e                	sd	s11,440(sp)
    800059d4:	1400                	addi	s0,sp,544
    800059d6:	dea43c23          	sd	a0,-520(s0)
    800059da:	deb43423          	sd	a1,-536(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800059de:	ffffd097          	auipc	ra,0xffffd
    800059e2:	826080e7          	jalr	-2010(ra) # 80002204 <myproc>
    800059e6:	84aa                	mv	s1,a0

  for(int i = 0; i< 16; i++){
    800059e8:	17450793          	addi	a5,a0,372
    800059ec:	23450713          	addi	a4,a0,564
    p->swapped_pages.pages[i].is_used = 0;
    800059f0:	0c07a423          	sw	zero,200(a5)
    p->ram_pages.pages[i].is_used = 0; 
    800059f4:	0007a023          	sw	zero,0(a5)
  for(int i = 0; i< 16; i++){
    800059f8:	07b1                	addi	a5,a5,12
    800059fa:	fee79be3          	bne	a5,a4,800059f0 <exec+0x42>
  }

  begin_op();
    800059fe:	fffff097          	auipc	ra,0xfffff
    80005a02:	29c080e7          	jalr	668(ra) # 80004c9a <begin_op>

  if((ip = namei(path)) == 0){
    80005a06:	df843503          	ld	a0,-520(s0)
    80005a0a:	fffff097          	auipc	ra,0xfffff
    80005a0e:	d5e080e7          	jalr	-674(ra) # 80004768 <namei>
    80005a12:	8aaa                	mv	s5,a0
    80005a14:	c935                	beqz	a0,80005a88 <exec+0xda>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a16:	ffffe097          	auipc	ra,0xffffe
    80005a1a:	59c080e7          	jalr	1436(ra) # 80003fb2 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005a1e:	04000713          	li	a4,64
    80005a22:	4681                	li	a3,0
    80005a24:	e4840613          	addi	a2,s0,-440
    80005a28:	4581                	li	a1,0
    80005a2a:	8556                	mv	a0,s5
    80005a2c:	fffff097          	auipc	ra,0xfffff
    80005a30:	83a080e7          	jalr	-1990(ra) # 80004266 <readi>
    80005a34:	04000793          	li	a5,64
    80005a38:	00f51a63          	bne	a0,a5,80005a4c <exec+0x9e>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005a3c:	e4842703          	lw	a4,-440(s0)
    80005a40:	464c47b7          	lui	a5,0x464c4
    80005a44:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005a48:	04f70663          	beq	a4,a5,80005a94 <exec+0xe6>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005a4c:	8556                	mv	a0,s5
    80005a4e:	ffffe097          	auipc	ra,0xffffe
    80005a52:	7c6080e7          	jalr	1990(ra) # 80004214 <iunlockput>
    end_op();
    80005a56:	fffff097          	auipc	ra,0xfffff
    80005a5a:	2c4080e7          	jalr	708(ra) # 80004d1a <end_op>
  }
  return -1;
    80005a5e:	557d                	li	a0,-1
}
    80005a60:	21813083          	ld	ra,536(sp)
    80005a64:	21013403          	ld	s0,528(sp)
    80005a68:	20813483          	ld	s1,520(sp)
    80005a6c:	20013903          	ld	s2,512(sp)
    80005a70:	79fe                	ld	s3,504(sp)
    80005a72:	7a5e                	ld	s4,496(sp)
    80005a74:	7abe                	ld	s5,488(sp)
    80005a76:	7b1e                	ld	s6,480(sp)
    80005a78:	6bfe                	ld	s7,472(sp)
    80005a7a:	6c5e                	ld	s8,464(sp)
    80005a7c:	6cbe                	ld	s9,456(sp)
    80005a7e:	6d1e                	ld	s10,448(sp)
    80005a80:	7dfa                	ld	s11,440(sp)
    80005a82:	22010113          	addi	sp,sp,544
    80005a86:	8082                	ret
    end_op();
    80005a88:	fffff097          	auipc	ra,0xfffff
    80005a8c:	292080e7          	jalr	658(ra) # 80004d1a <end_op>
    return -1;
    80005a90:	557d                	li	a0,-1
    80005a92:	b7f9                	j	80005a60 <exec+0xb2>
  if((pagetable = proc_pagetable(p)) == 0)
    80005a94:	8526                	mv	a0,s1
    80005a96:	ffffd097          	auipc	ra,0xffffd
    80005a9a:	840080e7          	jalr	-1984(ra) # 800022d6 <proc_pagetable>
    80005a9e:	8b2a                	mv	s6,a0
    80005aa0:	d555                	beqz	a0,80005a4c <exec+0x9e>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005aa2:	e6842783          	lw	a5,-408(s0)
    80005aa6:	e8045703          	lhu	a4,-384(s0)
    80005aaa:	c735                	beqz	a4,80005b16 <exec+0x168>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005aac:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005aae:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005ab2:	6a05                	lui	s4,0x1
    80005ab4:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005ab8:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80005abc:	6d85                	lui	s11,0x1
    80005abe:	7d7d                	lui	s10,0xfffff
    80005ac0:	a4a1                	j	80005d08 <exec+0x35a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005ac2:	00004517          	auipc	a0,0x4
    80005ac6:	0e650513          	addi	a0,a0,230 # 80009ba8 <syscalls+0x318>
    80005aca:	ffffb097          	auipc	ra,0xffffb
    80005ace:	a60080e7          	jalr	-1440(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005ad2:	874e                	mv	a4,s3
    80005ad4:	009c86bb          	addw	a3,s9,s1
    80005ad8:	4581                	li	a1,0
    80005ada:	8556                	mv	a0,s5
    80005adc:	ffffe097          	auipc	ra,0xffffe
    80005ae0:	78a080e7          	jalr	1930(ra) # 80004266 <readi>
    80005ae4:	2501                	sext.w	a0,a0
    80005ae6:	1ca99163          	bne	s3,a0,80005ca8 <exec+0x2fa>
  for(i = 0; i < sz; i += PGSIZE){
    80005aea:	009d84bb          	addw	s1,s11,s1
    80005aee:	012d093b          	addw	s2,s10,s2
    80005af2:	1f74fb63          	bgeu	s1,s7,80005ce8 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    80005af6:	02049593          	slli	a1,s1,0x20
    80005afa:	9181                	srli	a1,a1,0x20
    80005afc:	95e2                	add	a1,a1,s8
    80005afe:	855a                	mv	a0,s6
    80005b00:	ffffb097          	auipc	ra,0xffffb
    80005b04:	54c080e7          	jalr	1356(ra) # 8000104c <walkaddr>
    80005b08:	862a                	mv	a2,a0
    if(pa == 0)
    80005b0a:	dd45                	beqz	a0,80005ac2 <exec+0x114>
      n = PGSIZE;
    80005b0c:	89d2                	mv	s3,s4
    if(sz - i < PGSIZE)
    80005b0e:	fd4972e3          	bgeu	s2,s4,80005ad2 <exec+0x124>
      n = sz - i;
    80005b12:	89ca                	mv	s3,s2
    80005b14:	bf7d                	j	80005ad2 <exec+0x124>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005b16:	4481                	li	s1,0
  iunlockput(ip);
    80005b18:	8556                	mv	a0,s5
    80005b1a:	ffffe097          	auipc	ra,0xffffe
    80005b1e:	6fa080e7          	jalr	1786(ra) # 80004214 <iunlockput>
  end_op();
    80005b22:	fffff097          	auipc	ra,0xfffff
    80005b26:	1f8080e7          	jalr	504(ra) # 80004d1a <end_op>
  p = myproc();
    80005b2a:	ffffc097          	auipc	ra,0xffffc
    80005b2e:	6da080e7          	jalr	1754(ra) # 80002204 <myproc>
    80005b32:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005b34:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005b38:	6785                	lui	a5,0x1
    80005b3a:	17fd                	addi	a5,a5,-1
    80005b3c:	94be                	add	s1,s1,a5
    80005b3e:	77fd                	lui	a5,0xfffff
    80005b40:	8fe5                	and	a5,a5,s1
    80005b42:	84be                	mv	s1,a5
    80005b44:	def43823          	sd	a5,-528(s0)
  printf("Call uvmalloc from exec, line 72"); 
    80005b48:	00004517          	auipc	a0,0x4
    80005b4c:	08050513          	addi	a0,a0,128 # 80009bc8 <syscalls+0x338>
    80005b50:	ffffb097          	auipc	ra,0xffffb
    80005b54:	a24080e7          	jalr	-1500(ra) # 80000574 <printf>
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005b58:	6609                	lui	a2,0x2
    80005b5a:	9626                	add	a2,a2,s1
    80005b5c:	85a6                	mv	a1,s1
    80005b5e:	855a                	mv	a0,s6
    80005b60:	ffffc097          	auipc	ra,0xffffc
    80005b64:	f8c080e7          	jalr	-116(ra) # 80001aec <uvmalloc>
    80005b68:	8c2a                	mv	s8,a0
  ip = 0;
    80005b6a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005b6c:	12050e63          	beqz	a0,80005ca8 <exec+0x2fa>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005b70:	75f9                	lui	a1,0xffffe
    80005b72:	95aa                	add	a1,a1,a0
    80005b74:	855a                	mv	a0,s6
    80005b76:	ffffc097          	auipc	ra,0xffffc
    80005b7a:	31c080e7          	jalr	796(ra) # 80001e92 <uvmclear>
  stackbase = sp - PGSIZE;
    80005b7e:	7afd                	lui	s5,0xfffff
    80005b80:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005b82:	de843783          	ld	a5,-536(s0)
    80005b86:	6388                	ld	a0,0(a5)
    80005b88:	c925                	beqz	a0,80005bf8 <exec+0x24a>
    80005b8a:	e8840993          	addi	s3,s0,-376
    80005b8e:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005b92:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005b94:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005b96:	ffffb097          	auipc	ra,0xffffb
    80005b9a:	2ac080e7          	jalr	684(ra) # 80000e42 <strlen>
    80005b9e:	0015079b          	addiw	a5,a0,1
    80005ba2:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005ba6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005baa:	13596363          	bltu	s2,s5,80005cd0 <exec+0x322>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005bae:	de843d83          	ld	s11,-536(s0)
    80005bb2:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005bb6:	8552                	mv	a0,s4
    80005bb8:	ffffb097          	auipc	ra,0xffffb
    80005bbc:	28a080e7          	jalr	650(ra) # 80000e42 <strlen>
    80005bc0:	0015069b          	addiw	a3,a0,1
    80005bc4:	8652                	mv	a2,s4
    80005bc6:	85ca                	mv	a1,s2
    80005bc8:	855a                	mv	a0,s6
    80005bca:	ffffc097          	auipc	ra,0xffffc
    80005bce:	2fa080e7          	jalr	762(ra) # 80001ec4 <copyout>
    80005bd2:	10054363          	bltz	a0,80005cd8 <exec+0x32a>
    ustack[argc] = sp;
    80005bd6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005bda:	0485                	addi	s1,s1,1
    80005bdc:	008d8793          	addi	a5,s11,8
    80005be0:	def43423          	sd	a5,-536(s0)
    80005be4:	008db503          	ld	a0,8(s11)
    80005be8:	c911                	beqz	a0,80005bfc <exec+0x24e>
    if(argc >= MAXARG)
    80005bea:	09a1                	addi	s3,s3,8
    80005bec:	fb3c95e3          	bne	s9,s3,80005b96 <exec+0x1e8>
  sz = sz1;;
    80005bf0:	df843823          	sd	s8,-528(s0)
  ip = 0;
    80005bf4:	4a81                	li	s5,0
    80005bf6:	a84d                	j	80005ca8 <exec+0x2fa>
  sp = sz;
    80005bf8:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005bfa:	4481                	li	s1,0
  ustack[argc] = 0;
    80005bfc:	00349793          	slli	a5,s1,0x3
    80005c00:	f9040713          	addi	a4,s0,-112
    80005c04:	97ba                	add	a5,a5,a4
    80005c06:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd0ef8>
  sp -= (argc+1) * sizeof(uint64);
    80005c0a:	00148693          	addi	a3,s1,1
    80005c0e:	068e                	slli	a3,a3,0x3
    80005c10:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005c14:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005c18:	01597663          	bgeu	s2,s5,80005c24 <exec+0x276>
  sz = sz1;;
    80005c1c:	df843823          	sd	s8,-528(s0)
  ip = 0;
    80005c20:	4a81                	li	s5,0
    80005c22:	a059                	j	80005ca8 <exec+0x2fa>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005c24:	e8840613          	addi	a2,s0,-376
    80005c28:	85ca                	mv	a1,s2
    80005c2a:	855a                	mv	a0,s6
    80005c2c:	ffffc097          	auipc	ra,0xffffc
    80005c30:	298080e7          	jalr	664(ra) # 80001ec4 <copyout>
    80005c34:	0a054663          	bltz	a0,80005ce0 <exec+0x332>
  p->trapframe->a1 = sp;
    80005c38:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005c3c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005c40:	df843783          	ld	a5,-520(s0)
    80005c44:	0007c703          	lbu	a4,0(a5)
    80005c48:	cf11                	beqz	a4,80005c64 <exec+0x2b6>
    80005c4a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005c4c:	02f00693          	li	a3,47
    80005c50:	a029                	j	80005c5a <exec+0x2ac>
  for(last=s=path; *s; s++)
    80005c52:	0785                	addi	a5,a5,1
    80005c54:	fff7c703          	lbu	a4,-1(a5)
    80005c58:	c711                	beqz	a4,80005c64 <exec+0x2b6>
    if(*s == '/')
    80005c5a:	fed71ce3          	bne	a4,a3,80005c52 <exec+0x2a4>
      last = s+1;
    80005c5e:	def43c23          	sd	a5,-520(s0)
    80005c62:	bfc5                	j	80005c52 <exec+0x2a4>
  safestrcpy(p->name, last, sizeof(p->name));
    80005c64:	4641                	li	a2,16
    80005c66:	df843583          	ld	a1,-520(s0)
    80005c6a:	158b8513          	addi	a0,s7,344
    80005c6e:	ffffb097          	auipc	ra,0xffffb
    80005c72:	1a2080e7          	jalr	418(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80005c76:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005c7a:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005c7e:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005c82:	058bb783          	ld	a5,88(s7)
    80005c86:	e6043703          	ld	a4,-416(s0)
    80005c8a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005c8c:	058bb783          	ld	a5,88(s7)
    80005c90:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005c94:	85ea                	mv	a1,s10
    80005c96:	ffffc097          	auipc	ra,0xffffc
    80005c9a:	6dc080e7          	jalr	1756(ra) # 80002372 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005c9e:	0004851b          	sext.w	a0,s1
    80005ca2:	bb7d                	j	80005a60 <exec+0xb2>
    80005ca4:	de943823          	sd	s1,-528(s0)
    proc_freepagetable(pagetable, sz);
    80005ca8:	df043583          	ld	a1,-528(s0)
    80005cac:	855a                	mv	a0,s6
    80005cae:	ffffc097          	auipc	ra,0xffffc
    80005cb2:	6c4080e7          	jalr	1732(ra) # 80002372 <proc_freepagetable>
  if(ip){
    80005cb6:	d80a9be3          	bnez	s5,80005a4c <exec+0x9e>
  return -1;
    80005cba:	557d                	li	a0,-1
    80005cbc:	b355                	j	80005a60 <exec+0xb2>
    80005cbe:	de943823          	sd	s1,-528(s0)
    80005cc2:	b7dd                	j	80005ca8 <exec+0x2fa>
    80005cc4:	de943823          	sd	s1,-528(s0)
    80005cc8:	b7c5                	j	80005ca8 <exec+0x2fa>
    80005cca:	de943823          	sd	s1,-528(s0)
    80005cce:	bfe9                	j	80005ca8 <exec+0x2fa>
  sz = sz1;;
    80005cd0:	df843823          	sd	s8,-528(s0)
  ip = 0;
    80005cd4:	4a81                	li	s5,0
    80005cd6:	bfc9                	j	80005ca8 <exec+0x2fa>
  sz = sz1;;
    80005cd8:	df843823          	sd	s8,-528(s0)
  ip = 0;
    80005cdc:	4a81                	li	s5,0
    80005cde:	b7e9                	j	80005ca8 <exec+0x2fa>
  sz = sz1;;
    80005ce0:	df843823          	sd	s8,-528(s0)
  ip = 0;
    80005ce4:	4a81                	li	s5,0
    80005ce6:	b7c9                	j	80005ca8 <exec+0x2fa>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005ce8:	df043483          	ld	s1,-528(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005cec:	e0843783          	ld	a5,-504(s0)
    80005cf0:	0017869b          	addiw	a3,a5,1
    80005cf4:	e0d43423          	sd	a3,-504(s0)
    80005cf8:	e0043783          	ld	a5,-512(s0)
    80005cfc:	0387879b          	addiw	a5,a5,56
    80005d00:	e8045703          	lhu	a4,-384(s0)
    80005d04:	e0e6dae3          	bge	a3,a4,80005b18 <exec+0x16a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005d08:	2781                	sext.w	a5,a5
    80005d0a:	e0f43023          	sd	a5,-512(s0)
    80005d0e:	03800713          	li	a4,56
    80005d12:	86be                	mv	a3,a5
    80005d14:	e1040613          	addi	a2,s0,-496
    80005d18:	4581                	li	a1,0
    80005d1a:	8556                	mv	a0,s5
    80005d1c:	ffffe097          	auipc	ra,0xffffe
    80005d20:	54a080e7          	jalr	1354(ra) # 80004266 <readi>
    80005d24:	03800793          	li	a5,56
    80005d28:	f6f51ee3          	bne	a0,a5,80005ca4 <exec+0x2f6>
    if(ph.type != ELF_PROG_LOAD)
    80005d2c:	e1042783          	lw	a5,-496(s0)
    80005d30:	4705                	li	a4,1
    80005d32:	fae79de3          	bne	a5,a4,80005cec <exec+0x33e>
    if(ph.memsz < ph.filesz)
    80005d36:	e3843783          	ld	a5,-456(s0)
    80005d3a:	e3043703          	ld	a4,-464(s0)
    80005d3e:	f8e7e0e3          	bltu	a5,a4,80005cbe <exec+0x310>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005d42:	e2043703          	ld	a4,-480(s0)
    80005d46:	97ba                	add	a5,a5,a4
    80005d48:	f6e7eee3          	bltu	a5,a4,80005cc4 <exec+0x316>
    printf("Call uvmalloc from exec, line 52"); 
    80005d4c:	00004517          	auipc	a0,0x4
    80005d50:	e3450513          	addi	a0,a0,-460 # 80009b80 <syscalls+0x2f0>
    80005d54:	ffffb097          	auipc	ra,0xffffb
    80005d58:	820080e7          	jalr	-2016(ra) # 80000574 <printf>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005d5c:	e2043603          	ld	a2,-480(s0)
    80005d60:	e3843783          	ld	a5,-456(s0)
    80005d64:	963e                	add	a2,a2,a5
    80005d66:	85a6                	mv	a1,s1
    80005d68:	855a                	mv	a0,s6
    80005d6a:	ffffc097          	auipc	ra,0xffffc
    80005d6e:	d82080e7          	jalr	-638(ra) # 80001aec <uvmalloc>
    80005d72:	dea43823          	sd	a0,-528(s0)
    80005d76:	d931                	beqz	a0,80005cca <exec+0x31c>
    if(ph.vaddr % PGSIZE != 0)
    80005d78:	e2043c03          	ld	s8,-480(s0)
    80005d7c:	de043783          	ld	a5,-544(s0)
    80005d80:	00fc77b3          	and	a5,s8,a5
    80005d84:	f395                	bnez	a5,80005ca8 <exec+0x2fa>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005d86:	e1842c83          	lw	s9,-488(s0)
    80005d8a:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005d8e:	f40b8de3          	beqz	s7,80005ce8 <exec+0x33a>
    80005d92:	895e                	mv	s2,s7
    80005d94:	4481                	li	s1,0
    80005d96:	b385                	j	80005af6 <exec+0x148>

0000000080005d98 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005d98:	7179                	addi	sp,sp,-48
    80005d9a:	f406                	sd	ra,40(sp)
    80005d9c:	f022                	sd	s0,32(sp)
    80005d9e:	ec26                	sd	s1,24(sp)
    80005da0:	e84a                	sd	s2,16(sp)
    80005da2:	1800                	addi	s0,sp,48
    80005da4:	892e                	mv	s2,a1
    80005da6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005da8:	fdc40593          	addi	a1,s0,-36
    80005dac:	ffffd097          	auipc	ra,0xffffd
    80005db0:	694080e7          	jalr	1684(ra) # 80003440 <argint>
    80005db4:	04054063          	bltz	a0,80005df4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005db8:	fdc42703          	lw	a4,-36(s0)
    80005dbc:	47bd                	li	a5,15
    80005dbe:	02e7ed63          	bltu	a5,a4,80005df8 <argfd+0x60>
    80005dc2:	ffffc097          	auipc	ra,0xffffc
    80005dc6:	442080e7          	jalr	1090(ra) # 80002204 <myproc>
    80005dca:	fdc42703          	lw	a4,-36(s0)
    80005dce:	01a70793          	addi	a5,a4,26
    80005dd2:	078e                	slli	a5,a5,0x3
    80005dd4:	953e                	add	a0,a0,a5
    80005dd6:	611c                	ld	a5,0(a0)
    80005dd8:	c395                	beqz	a5,80005dfc <argfd+0x64>
    return -1;
  if(pfd)
    80005dda:	00090463          	beqz	s2,80005de2 <argfd+0x4a>
    *pfd = fd;
    80005dde:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005de2:	4501                	li	a0,0
  if(pf)
    80005de4:	c091                	beqz	s1,80005de8 <argfd+0x50>
    *pf = f;
    80005de6:	e09c                	sd	a5,0(s1)
}
    80005de8:	70a2                	ld	ra,40(sp)
    80005dea:	7402                	ld	s0,32(sp)
    80005dec:	64e2                	ld	s1,24(sp)
    80005dee:	6942                	ld	s2,16(sp)
    80005df0:	6145                	addi	sp,sp,48
    80005df2:	8082                	ret
    return -1;
    80005df4:	557d                	li	a0,-1
    80005df6:	bfcd                	j	80005de8 <argfd+0x50>
    return -1;
    80005df8:	557d                	li	a0,-1
    80005dfa:	b7fd                	j	80005de8 <argfd+0x50>
    80005dfc:	557d                	li	a0,-1
    80005dfe:	b7ed                	j	80005de8 <argfd+0x50>

0000000080005e00 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005e00:	1101                	addi	sp,sp,-32
    80005e02:	ec06                	sd	ra,24(sp)
    80005e04:	e822                	sd	s0,16(sp)
    80005e06:	e426                	sd	s1,8(sp)
    80005e08:	1000                	addi	s0,sp,32
    80005e0a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005e0c:	ffffc097          	auipc	ra,0xffffc
    80005e10:	3f8080e7          	jalr	1016(ra) # 80002204 <myproc>
    80005e14:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005e16:	0d050793          	addi	a5,a0,208
    80005e1a:	4501                	li	a0,0
    80005e1c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005e1e:	6398                	ld	a4,0(a5)
    80005e20:	cb19                	beqz	a4,80005e36 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005e22:	2505                	addiw	a0,a0,1
    80005e24:	07a1                	addi	a5,a5,8
    80005e26:	fed51ce3          	bne	a0,a3,80005e1e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005e2a:	557d                	li	a0,-1
}
    80005e2c:	60e2                	ld	ra,24(sp)
    80005e2e:	6442                	ld	s0,16(sp)
    80005e30:	64a2                	ld	s1,8(sp)
    80005e32:	6105                	addi	sp,sp,32
    80005e34:	8082                	ret
      p->ofile[fd] = f;
    80005e36:	01a50793          	addi	a5,a0,26
    80005e3a:	078e                	slli	a5,a5,0x3
    80005e3c:	963e                	add	a2,a2,a5
    80005e3e:	e204                	sd	s1,0(a2)
      return fd;
    80005e40:	b7f5                	j	80005e2c <fdalloc+0x2c>

0000000080005e42 <sys_dup>:

uint64
sys_dup(void)
{
    80005e42:	7179                	addi	sp,sp,-48
    80005e44:	f406                	sd	ra,40(sp)
    80005e46:	f022                	sd	s0,32(sp)
    80005e48:	ec26                	sd	s1,24(sp)
    80005e4a:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    80005e4c:	fd840613          	addi	a2,s0,-40
    80005e50:	4581                	li	a1,0
    80005e52:	4501                	li	a0,0
    80005e54:	00000097          	auipc	ra,0x0
    80005e58:	f44080e7          	jalr	-188(ra) # 80005d98 <argfd>
    return -1;
    80005e5c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005e5e:	02054363          	bltz	a0,80005e84 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005e62:	fd843503          	ld	a0,-40(s0)
    80005e66:	00000097          	auipc	ra,0x0
    80005e6a:	f9a080e7          	jalr	-102(ra) # 80005e00 <fdalloc>
    80005e6e:	84aa                	mv	s1,a0
    return -1;
    80005e70:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005e72:	00054963          	bltz	a0,80005e84 <sys_dup+0x42>
  filedup(f);
    80005e76:	fd843503          	ld	a0,-40(s0)
    80005e7a:	fffff097          	auipc	ra,0xfffff
    80005e7e:	29a080e7          	jalr	666(ra) # 80005114 <filedup>
  return fd;
    80005e82:	87a6                	mv	a5,s1
}
    80005e84:	853e                	mv	a0,a5
    80005e86:	70a2                	ld	ra,40(sp)
    80005e88:	7402                	ld	s0,32(sp)
    80005e8a:	64e2                	ld	s1,24(sp)
    80005e8c:	6145                	addi	sp,sp,48
    80005e8e:	8082                	ret

0000000080005e90 <sys_read>:

uint64
sys_read(void)
{
    80005e90:	7179                	addi	sp,sp,-48
    80005e92:	f406                	sd	ra,40(sp)
    80005e94:	f022                	sd	s0,32(sp)
    80005e96:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e98:	fe840613          	addi	a2,s0,-24
    80005e9c:	4581                	li	a1,0
    80005e9e:	4501                	li	a0,0
    80005ea0:	00000097          	auipc	ra,0x0
    80005ea4:	ef8080e7          	jalr	-264(ra) # 80005d98 <argfd>
    return -1;
    80005ea8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005eaa:	04054163          	bltz	a0,80005eec <sys_read+0x5c>
    80005eae:	fe440593          	addi	a1,s0,-28
    80005eb2:	4509                	li	a0,2
    80005eb4:	ffffd097          	auipc	ra,0xffffd
    80005eb8:	58c080e7          	jalr	1420(ra) # 80003440 <argint>
    return -1;
    80005ebc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ebe:	02054763          	bltz	a0,80005eec <sys_read+0x5c>
    80005ec2:	fd840593          	addi	a1,s0,-40
    80005ec6:	4505                	li	a0,1
    80005ec8:	ffffd097          	auipc	ra,0xffffd
    80005ecc:	59a080e7          	jalr	1434(ra) # 80003462 <argaddr>
    return -1;
    80005ed0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ed2:	00054d63          	bltz	a0,80005eec <sys_read+0x5c>
  return fileread(f, p, n);
    80005ed6:	fe442603          	lw	a2,-28(s0)
    80005eda:	fd843583          	ld	a1,-40(s0)
    80005ede:	fe843503          	ld	a0,-24(s0)
    80005ee2:	fffff097          	auipc	ra,0xfffff
    80005ee6:	3be080e7          	jalr	958(ra) # 800052a0 <fileread>
    80005eea:	87aa                	mv	a5,a0
}
    80005eec:	853e                	mv	a0,a5
    80005eee:	70a2                	ld	ra,40(sp)
    80005ef0:	7402                	ld	s0,32(sp)
    80005ef2:	6145                	addi	sp,sp,48
    80005ef4:	8082                	ret

0000000080005ef6 <sys_write>:

uint64
sys_write(void)
{
    80005ef6:	7179                	addi	sp,sp,-48
    80005ef8:	f406                	sd	ra,40(sp)
    80005efa:	f022                	sd	s0,32(sp)
    80005efc:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005efe:	fe840613          	addi	a2,s0,-24
    80005f02:	4581                	li	a1,0
    80005f04:	4501                	li	a0,0
    80005f06:	00000097          	auipc	ra,0x0
    80005f0a:	e92080e7          	jalr	-366(ra) # 80005d98 <argfd>
    return -1;
    80005f0e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f10:	04054163          	bltz	a0,80005f52 <sys_write+0x5c>
    80005f14:	fe440593          	addi	a1,s0,-28
    80005f18:	4509                	li	a0,2
    80005f1a:	ffffd097          	auipc	ra,0xffffd
    80005f1e:	526080e7          	jalr	1318(ra) # 80003440 <argint>
    return -1;
    80005f22:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f24:	02054763          	bltz	a0,80005f52 <sys_write+0x5c>
    80005f28:	fd840593          	addi	a1,s0,-40
    80005f2c:	4505                	li	a0,1
    80005f2e:	ffffd097          	auipc	ra,0xffffd
    80005f32:	534080e7          	jalr	1332(ra) # 80003462 <argaddr>
    return -1;
    80005f36:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f38:	00054d63          	bltz	a0,80005f52 <sys_write+0x5c>

  return filewrite(f, p, n);
    80005f3c:	fe442603          	lw	a2,-28(s0)
    80005f40:	fd843583          	ld	a1,-40(s0)
    80005f44:	fe843503          	ld	a0,-24(s0)
    80005f48:	fffff097          	auipc	ra,0xfffff
    80005f4c:	41a080e7          	jalr	1050(ra) # 80005362 <filewrite>
    80005f50:	87aa                	mv	a5,a0
}
    80005f52:	853e                	mv	a0,a5
    80005f54:	70a2                	ld	ra,40(sp)
    80005f56:	7402                	ld	s0,32(sp)
    80005f58:	6145                	addi	sp,sp,48
    80005f5a:	8082                	ret

0000000080005f5c <sys_close>:

uint64
sys_close(void)
{
    80005f5c:	1101                	addi	sp,sp,-32
    80005f5e:	ec06                	sd	ra,24(sp)
    80005f60:	e822                	sd	s0,16(sp)
    80005f62:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    80005f64:	fe040613          	addi	a2,s0,-32
    80005f68:	fec40593          	addi	a1,s0,-20
    80005f6c:	4501                	li	a0,0
    80005f6e:	00000097          	auipc	ra,0x0
    80005f72:	e2a080e7          	jalr	-470(ra) # 80005d98 <argfd>
    return -1;
    80005f76:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005f78:	02054463          	bltz	a0,80005fa0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005f7c:	ffffc097          	auipc	ra,0xffffc
    80005f80:	288080e7          	jalr	648(ra) # 80002204 <myproc>
    80005f84:	fec42783          	lw	a5,-20(s0)
    80005f88:	07e9                	addi	a5,a5,26
    80005f8a:	078e                	slli	a5,a5,0x3
    80005f8c:	97aa                	add	a5,a5,a0
    80005f8e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005f92:	fe043503          	ld	a0,-32(s0)
    80005f96:	fffff097          	auipc	ra,0xfffff
    80005f9a:	1d0080e7          	jalr	464(ra) # 80005166 <fileclose>
  return 0;
    80005f9e:	4781                	li	a5,0
}
    80005fa0:	853e                	mv	a0,a5
    80005fa2:	60e2                	ld	ra,24(sp)
    80005fa4:	6442                	ld	s0,16(sp)
    80005fa6:	6105                	addi	sp,sp,32
    80005fa8:	8082                	ret

0000000080005faa <sys_fstat>:

uint64
sys_fstat(void)
{
    80005faa:	1101                	addi	sp,sp,-32
    80005fac:	ec06                	sd	ra,24(sp)
    80005fae:	e822                	sd	s0,16(sp)
    80005fb0:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005fb2:	fe840613          	addi	a2,s0,-24
    80005fb6:	4581                	li	a1,0
    80005fb8:	4501                	li	a0,0
    80005fba:	00000097          	auipc	ra,0x0
    80005fbe:	dde080e7          	jalr	-546(ra) # 80005d98 <argfd>
    return -1;
    80005fc2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005fc4:	02054563          	bltz	a0,80005fee <sys_fstat+0x44>
    80005fc8:	fe040593          	addi	a1,s0,-32
    80005fcc:	4505                	li	a0,1
    80005fce:	ffffd097          	auipc	ra,0xffffd
    80005fd2:	494080e7          	jalr	1172(ra) # 80003462 <argaddr>
    return -1;
    80005fd6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005fd8:	00054b63          	bltz	a0,80005fee <sys_fstat+0x44>
  return filestat(f, st);
    80005fdc:	fe043583          	ld	a1,-32(s0)
    80005fe0:	fe843503          	ld	a0,-24(s0)
    80005fe4:	fffff097          	auipc	ra,0xfffff
    80005fe8:	24a080e7          	jalr	586(ra) # 8000522e <filestat>
    80005fec:	87aa                	mv	a5,a0
}
    80005fee:	853e                	mv	a0,a5
    80005ff0:	60e2                	ld	ra,24(sp)
    80005ff2:	6442                	ld	s0,16(sp)
    80005ff4:	6105                	addi	sp,sp,32
    80005ff6:	8082                	ret

0000000080005ff8 <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    80005ff8:	7169                	addi	sp,sp,-304
    80005ffa:	f606                	sd	ra,296(sp)
    80005ffc:	f222                	sd	s0,288(sp)
    80005ffe:	ee26                	sd	s1,280(sp)
    80006000:	ea4a                	sd	s2,272(sp)
    80006002:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006004:	08000613          	li	a2,128
    80006008:	ed040593          	addi	a1,s0,-304
    8000600c:	4501                	li	a0,0
    8000600e:	ffffd097          	auipc	ra,0xffffd
    80006012:	476080e7          	jalr	1142(ra) # 80003484 <argstr>
    return -1;
    80006016:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006018:	10054e63          	bltz	a0,80006134 <sys_link+0x13c>
    8000601c:	08000613          	li	a2,128
    80006020:	f5040593          	addi	a1,s0,-176
    80006024:	4505                	li	a0,1
    80006026:	ffffd097          	auipc	ra,0xffffd
    8000602a:	45e080e7          	jalr	1118(ra) # 80003484 <argstr>
    return -1;
    8000602e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006030:	10054263          	bltz	a0,80006134 <sys_link+0x13c>

  begin_op();
    80006034:	fffff097          	auipc	ra,0xfffff
    80006038:	c66080e7          	jalr	-922(ra) # 80004c9a <begin_op>
  if((ip = namei(old)) == 0){
    8000603c:	ed040513          	addi	a0,s0,-304
    80006040:	ffffe097          	auipc	ra,0xffffe
    80006044:	728080e7          	jalr	1832(ra) # 80004768 <namei>
    80006048:	84aa                	mv	s1,a0
    8000604a:	c551                	beqz	a0,800060d6 <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    8000604c:	ffffe097          	auipc	ra,0xffffe
    80006050:	f66080e7          	jalr	-154(ra) # 80003fb2 <ilock>
  if(ip->type == T_DIR){
    80006054:	04449703          	lh	a4,68(s1)
    80006058:	4785                	li	a5,1
    8000605a:	08f70463          	beq	a4,a5,800060e2 <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    8000605e:	04a4d783          	lhu	a5,74(s1)
    80006062:	2785                	addiw	a5,a5,1
    80006064:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006068:	8526                	mv	a0,s1
    8000606a:	ffffe097          	auipc	ra,0xffffe
    8000606e:	e7e080e7          	jalr	-386(ra) # 80003ee8 <iupdate>
  iunlock(ip);
    80006072:	8526                	mv	a0,s1
    80006074:	ffffe097          	auipc	ra,0xffffe
    80006078:	000080e7          	jalr	ra # 80004074 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    8000607c:	fd040593          	addi	a1,s0,-48
    80006080:	f5040513          	addi	a0,s0,-176
    80006084:	ffffe097          	auipc	ra,0xffffe
    80006088:	702080e7          	jalr	1794(ra) # 80004786 <nameiparent>
    8000608c:	892a                	mv	s2,a0
    8000608e:	c935                	beqz	a0,80006102 <sys_link+0x10a>
    goto bad;
  ilock(dp);
    80006090:	ffffe097          	auipc	ra,0xffffe
    80006094:	f22080e7          	jalr	-222(ra) # 80003fb2 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80006098:	00092703          	lw	a4,0(s2)
    8000609c:	409c                	lw	a5,0(s1)
    8000609e:	04f71d63          	bne	a4,a5,800060f8 <sys_link+0x100>
    800060a2:	40d0                	lw	a2,4(s1)
    800060a4:	fd040593          	addi	a1,s0,-48
    800060a8:	854a                	mv	a0,s2
    800060aa:	ffffe097          	auipc	ra,0xffffe
    800060ae:	5fc080e7          	jalr	1532(ra) # 800046a6 <dirlink>
    800060b2:	04054363          	bltz	a0,800060f8 <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    800060b6:	854a                	mv	a0,s2
    800060b8:	ffffe097          	auipc	ra,0xffffe
    800060bc:	15c080e7          	jalr	348(ra) # 80004214 <iunlockput>
  iput(ip);
    800060c0:	8526                	mv	a0,s1
    800060c2:	ffffe097          	auipc	ra,0xffffe
    800060c6:	0aa080e7          	jalr	170(ra) # 8000416c <iput>

  end_op();
    800060ca:	fffff097          	auipc	ra,0xfffff
    800060ce:	c50080e7          	jalr	-944(ra) # 80004d1a <end_op>

  return 0;
    800060d2:	4781                	li	a5,0
    800060d4:	a085                	j	80006134 <sys_link+0x13c>
    end_op();
    800060d6:	fffff097          	auipc	ra,0xfffff
    800060da:	c44080e7          	jalr	-956(ra) # 80004d1a <end_op>
    return -1;
    800060de:	57fd                	li	a5,-1
    800060e0:	a891                	j	80006134 <sys_link+0x13c>
    iunlockput(ip);
    800060e2:	8526                	mv	a0,s1
    800060e4:	ffffe097          	auipc	ra,0xffffe
    800060e8:	130080e7          	jalr	304(ra) # 80004214 <iunlockput>
    end_op();
    800060ec:	fffff097          	auipc	ra,0xfffff
    800060f0:	c2e080e7          	jalr	-978(ra) # 80004d1a <end_op>
    return -1;
    800060f4:	57fd                	li	a5,-1
    800060f6:	a83d                	j	80006134 <sys_link+0x13c>
    iunlockput(dp);
    800060f8:	854a                	mv	a0,s2
    800060fa:	ffffe097          	auipc	ra,0xffffe
    800060fe:	11a080e7          	jalr	282(ra) # 80004214 <iunlockput>

bad:
  ilock(ip);
    80006102:	8526                	mv	a0,s1
    80006104:	ffffe097          	auipc	ra,0xffffe
    80006108:	eae080e7          	jalr	-338(ra) # 80003fb2 <ilock>
  ip->nlink--;
    8000610c:	04a4d783          	lhu	a5,74(s1)
    80006110:	37fd                	addiw	a5,a5,-1
    80006112:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006116:	8526                	mv	a0,s1
    80006118:	ffffe097          	auipc	ra,0xffffe
    8000611c:	dd0080e7          	jalr	-560(ra) # 80003ee8 <iupdate>
  iunlockput(ip);
    80006120:	8526                	mv	a0,s1
    80006122:	ffffe097          	auipc	ra,0xffffe
    80006126:	0f2080e7          	jalr	242(ra) # 80004214 <iunlockput>
  end_op();
    8000612a:	fffff097          	auipc	ra,0xfffff
    8000612e:	bf0080e7          	jalr	-1040(ra) # 80004d1a <end_op>
  return -1;
    80006132:	57fd                	li	a5,-1
}
    80006134:	853e                	mv	a0,a5
    80006136:	70b2                	ld	ra,296(sp)
    80006138:	7412                	ld	s0,288(sp)
    8000613a:	64f2                	ld	s1,280(sp)
    8000613c:	6952                	ld	s2,272(sp)
    8000613e:	6155                	addi	sp,sp,304
    80006140:	8082                	ret

0000000080006142 <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006142:	4578                	lw	a4,76(a0)
    80006144:	02000793          	li	a5,32
    80006148:	04e7fa63          	bgeu	a5,a4,8000619c <isdirempty+0x5a>
{
    8000614c:	7179                	addi	sp,sp,-48
    8000614e:	f406                	sd	ra,40(sp)
    80006150:	f022                	sd	s0,32(sp)
    80006152:	ec26                	sd	s1,24(sp)
    80006154:	e84a                	sd	s2,16(sp)
    80006156:	1800                	addi	s0,sp,48
    80006158:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000615a:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000615e:	4741                	li	a4,16
    80006160:	86a6                	mv	a3,s1
    80006162:	fd040613          	addi	a2,s0,-48
    80006166:	4581                	li	a1,0
    80006168:	854a                	mv	a0,s2
    8000616a:	ffffe097          	auipc	ra,0xffffe
    8000616e:	0fc080e7          	jalr	252(ra) # 80004266 <readi>
    80006172:	47c1                	li	a5,16
    80006174:	00f51c63          	bne	a0,a5,8000618c <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    80006178:	fd045783          	lhu	a5,-48(s0)
    8000617c:	e395                	bnez	a5,800061a0 <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000617e:	24c1                	addiw	s1,s1,16
    80006180:	04c92783          	lw	a5,76(s2)
    80006184:	fcf4ede3          	bltu	s1,a5,8000615e <isdirempty+0x1c>
      return 0;
  }
  return 1;
    80006188:	4505                	li	a0,1
    8000618a:	a821                	j	800061a2 <isdirempty+0x60>
      panic("isdirempty: readi");
    8000618c:	00004517          	auipc	a0,0x4
    80006190:	a6450513          	addi	a0,a0,-1436 # 80009bf0 <syscalls+0x360>
    80006194:	ffffa097          	auipc	ra,0xffffa
    80006198:	396080e7          	jalr	918(ra) # 8000052a <panic>
  return 1;
    8000619c:	4505                	li	a0,1
}
    8000619e:	8082                	ret
      return 0;
    800061a0:	4501                	li	a0,0
}
    800061a2:	70a2                	ld	ra,40(sp)
    800061a4:	7402                	ld	s0,32(sp)
    800061a6:	64e2                	ld	s1,24(sp)
    800061a8:	6942                	ld	s2,16(sp)
    800061aa:	6145                	addi	sp,sp,48
    800061ac:	8082                	ret

00000000800061ae <sys_unlink>:

uint64
sys_unlink(void)
{
    800061ae:	7155                	addi	sp,sp,-208
    800061b0:	e586                	sd	ra,200(sp)
    800061b2:	e1a2                	sd	s0,192(sp)
    800061b4:	fd26                	sd	s1,184(sp)
    800061b6:	f94a                	sd	s2,176(sp)
    800061b8:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    800061ba:	08000613          	li	a2,128
    800061be:	f4040593          	addi	a1,s0,-192
    800061c2:	4501                	li	a0,0
    800061c4:	ffffd097          	auipc	ra,0xffffd
    800061c8:	2c0080e7          	jalr	704(ra) # 80003484 <argstr>
    800061cc:	16054363          	bltz	a0,80006332 <sys_unlink+0x184>
    return -1;

  begin_op();
    800061d0:	fffff097          	auipc	ra,0xfffff
    800061d4:	aca080e7          	jalr	-1334(ra) # 80004c9a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800061d8:	fc040593          	addi	a1,s0,-64
    800061dc:	f4040513          	addi	a0,s0,-192
    800061e0:	ffffe097          	auipc	ra,0xffffe
    800061e4:	5a6080e7          	jalr	1446(ra) # 80004786 <nameiparent>
    800061e8:	84aa                	mv	s1,a0
    800061ea:	c961                	beqz	a0,800062ba <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    800061ec:	ffffe097          	auipc	ra,0xffffe
    800061f0:	dc6080e7          	jalr	-570(ra) # 80003fb2 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800061f4:	00004597          	auipc	a1,0x4
    800061f8:	88c58593          	addi	a1,a1,-1908 # 80009a80 <syscalls+0x1f0>
    800061fc:	fc040513          	addi	a0,s0,-64
    80006200:	ffffe097          	auipc	ra,0xffffe
    80006204:	27c080e7          	jalr	636(ra) # 8000447c <namecmp>
    80006208:	c175                	beqz	a0,800062ec <sys_unlink+0x13e>
    8000620a:	00004597          	auipc	a1,0x4
    8000620e:	87e58593          	addi	a1,a1,-1922 # 80009a88 <syscalls+0x1f8>
    80006212:	fc040513          	addi	a0,s0,-64
    80006216:	ffffe097          	auipc	ra,0xffffe
    8000621a:	266080e7          	jalr	614(ra) # 8000447c <namecmp>
    8000621e:	c579                	beqz	a0,800062ec <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80006220:	f3c40613          	addi	a2,s0,-196
    80006224:	fc040593          	addi	a1,s0,-64
    80006228:	8526                	mv	a0,s1
    8000622a:	ffffe097          	auipc	ra,0xffffe
    8000622e:	26c080e7          	jalr	620(ra) # 80004496 <dirlookup>
    80006232:	892a                	mv	s2,a0
    80006234:	cd45                	beqz	a0,800062ec <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    80006236:	ffffe097          	auipc	ra,0xffffe
    8000623a:	d7c080e7          	jalr	-644(ra) # 80003fb2 <ilock>

  if(ip->nlink < 1)
    8000623e:	04a91783          	lh	a5,74(s2)
    80006242:	08f05263          	blez	a5,800062c6 <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006246:	04491703          	lh	a4,68(s2)
    8000624a:	4785                	li	a5,1
    8000624c:	08f70563          	beq	a4,a5,800062d6 <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80006250:	4641                	li	a2,16
    80006252:	4581                	li	a1,0
    80006254:	fd040513          	addi	a0,s0,-48
    80006258:	ffffb097          	auipc	ra,0xffffb
    8000625c:	a66080e7          	jalr	-1434(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006260:	4741                	li	a4,16
    80006262:	f3c42683          	lw	a3,-196(s0)
    80006266:	fd040613          	addi	a2,s0,-48
    8000626a:	4581                	li	a1,0
    8000626c:	8526                	mv	a0,s1
    8000626e:	ffffe097          	auipc	ra,0xffffe
    80006272:	0f0080e7          	jalr	240(ra) # 8000435e <writei>
    80006276:	47c1                	li	a5,16
    80006278:	08f51a63          	bne	a0,a5,8000630c <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    8000627c:	04491703          	lh	a4,68(s2)
    80006280:	4785                	li	a5,1
    80006282:	08f70d63          	beq	a4,a5,8000631c <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80006286:	8526                	mv	a0,s1
    80006288:	ffffe097          	auipc	ra,0xffffe
    8000628c:	f8c080e7          	jalr	-116(ra) # 80004214 <iunlockput>

  ip->nlink--;
    80006290:	04a95783          	lhu	a5,74(s2)
    80006294:	37fd                	addiw	a5,a5,-1
    80006296:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000629a:	854a                	mv	a0,s2
    8000629c:	ffffe097          	auipc	ra,0xffffe
    800062a0:	c4c080e7          	jalr	-948(ra) # 80003ee8 <iupdate>
  iunlockput(ip);
    800062a4:	854a                	mv	a0,s2
    800062a6:	ffffe097          	auipc	ra,0xffffe
    800062aa:	f6e080e7          	jalr	-146(ra) # 80004214 <iunlockput>

  end_op();
    800062ae:	fffff097          	auipc	ra,0xfffff
    800062b2:	a6c080e7          	jalr	-1428(ra) # 80004d1a <end_op>

  return 0;
    800062b6:	4501                	li	a0,0
    800062b8:	a0a1                	j	80006300 <sys_unlink+0x152>
    end_op();
    800062ba:	fffff097          	auipc	ra,0xfffff
    800062be:	a60080e7          	jalr	-1440(ra) # 80004d1a <end_op>
    return -1;
    800062c2:	557d                	li	a0,-1
    800062c4:	a835                	j	80006300 <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    800062c6:	00003517          	auipc	a0,0x3
    800062ca:	7ca50513          	addi	a0,a0,1994 # 80009a90 <syscalls+0x200>
    800062ce:	ffffa097          	auipc	ra,0xffffa
    800062d2:	25c080e7          	jalr	604(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800062d6:	854a                	mv	a0,s2
    800062d8:	00000097          	auipc	ra,0x0
    800062dc:	e6a080e7          	jalr	-406(ra) # 80006142 <isdirempty>
    800062e0:	f925                	bnez	a0,80006250 <sys_unlink+0xa2>
    iunlockput(ip);
    800062e2:	854a                	mv	a0,s2
    800062e4:	ffffe097          	auipc	ra,0xffffe
    800062e8:	f30080e7          	jalr	-208(ra) # 80004214 <iunlockput>

bad:
  iunlockput(dp);
    800062ec:	8526                	mv	a0,s1
    800062ee:	ffffe097          	auipc	ra,0xffffe
    800062f2:	f26080e7          	jalr	-218(ra) # 80004214 <iunlockput>
  end_op();
    800062f6:	fffff097          	auipc	ra,0xfffff
    800062fa:	a24080e7          	jalr	-1500(ra) # 80004d1a <end_op>
  return -1;
    800062fe:	557d                	li	a0,-1
}
    80006300:	60ae                	ld	ra,200(sp)
    80006302:	640e                	ld	s0,192(sp)
    80006304:	74ea                	ld	s1,184(sp)
    80006306:	794a                	ld	s2,176(sp)
    80006308:	6169                	addi	sp,sp,208
    8000630a:	8082                	ret
    panic("unlink: writei");
    8000630c:	00003517          	auipc	a0,0x3
    80006310:	79c50513          	addi	a0,a0,1948 # 80009aa8 <syscalls+0x218>
    80006314:	ffffa097          	auipc	ra,0xffffa
    80006318:	216080e7          	jalr	534(ra) # 8000052a <panic>
    dp->nlink--;
    8000631c:	04a4d783          	lhu	a5,74(s1)
    80006320:	37fd                	addiw	a5,a5,-1
    80006322:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006326:	8526                	mv	a0,s1
    80006328:	ffffe097          	auipc	ra,0xffffe
    8000632c:	bc0080e7          	jalr	-1088(ra) # 80003ee8 <iupdate>
    80006330:	bf99                	j	80006286 <sys_unlink+0xd8>
    return -1;
    80006332:	557d                	li	a0,-1
    80006334:	b7f1                	j	80006300 <sys_unlink+0x152>

0000000080006336 <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    80006336:	715d                	addi	sp,sp,-80
    80006338:	e486                	sd	ra,72(sp)
    8000633a:	e0a2                	sd	s0,64(sp)
    8000633c:	fc26                	sd	s1,56(sp)
    8000633e:	f84a                	sd	s2,48(sp)
    80006340:	f44e                	sd	s3,40(sp)
    80006342:	f052                	sd	s4,32(sp)
    80006344:	ec56                	sd	s5,24(sp)
    80006346:	0880                	addi	s0,sp,80
    80006348:	89ae                	mv	s3,a1
    8000634a:	8ab2                	mv	s5,a2
    8000634c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000634e:	fb040593          	addi	a1,s0,-80
    80006352:	ffffe097          	auipc	ra,0xffffe
    80006356:	434080e7          	jalr	1076(ra) # 80004786 <nameiparent>
    8000635a:	892a                	mv	s2,a0
    8000635c:	12050e63          	beqz	a0,80006498 <create+0x162>
    return 0;

  ilock(dp);
    80006360:	ffffe097          	auipc	ra,0xffffe
    80006364:	c52080e7          	jalr	-942(ra) # 80003fb2 <ilock>
  
  if((ip = dirlookup(dp, name, 0)) != 0){
    80006368:	4601                	li	a2,0
    8000636a:	fb040593          	addi	a1,s0,-80
    8000636e:	854a                	mv	a0,s2
    80006370:	ffffe097          	auipc	ra,0xffffe
    80006374:	126080e7          	jalr	294(ra) # 80004496 <dirlookup>
    80006378:	84aa                	mv	s1,a0
    8000637a:	c921                	beqz	a0,800063ca <create+0x94>
    iunlockput(dp);
    8000637c:	854a                	mv	a0,s2
    8000637e:	ffffe097          	auipc	ra,0xffffe
    80006382:	e96080e7          	jalr	-362(ra) # 80004214 <iunlockput>
    ilock(ip);
    80006386:	8526                	mv	a0,s1
    80006388:	ffffe097          	auipc	ra,0xffffe
    8000638c:	c2a080e7          	jalr	-982(ra) # 80003fb2 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80006390:	2981                	sext.w	s3,s3
    80006392:	4789                	li	a5,2
    80006394:	02f99463          	bne	s3,a5,800063bc <create+0x86>
    80006398:	0444d783          	lhu	a5,68(s1)
    8000639c:	37f9                	addiw	a5,a5,-2
    8000639e:	17c2                	slli	a5,a5,0x30
    800063a0:	93c1                	srli	a5,a5,0x30
    800063a2:	4705                	li	a4,1
    800063a4:	00f76c63          	bltu	a4,a5,800063bc <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800063a8:	8526                	mv	a0,s1
    800063aa:	60a6                	ld	ra,72(sp)
    800063ac:	6406                	ld	s0,64(sp)
    800063ae:	74e2                	ld	s1,56(sp)
    800063b0:	7942                	ld	s2,48(sp)
    800063b2:	79a2                	ld	s3,40(sp)
    800063b4:	7a02                	ld	s4,32(sp)
    800063b6:	6ae2                	ld	s5,24(sp)
    800063b8:	6161                	addi	sp,sp,80
    800063ba:	8082                	ret
    iunlockput(ip);
    800063bc:	8526                	mv	a0,s1
    800063be:	ffffe097          	auipc	ra,0xffffe
    800063c2:	e56080e7          	jalr	-426(ra) # 80004214 <iunlockput>
    return 0;
    800063c6:	4481                	li	s1,0
    800063c8:	b7c5                	j	800063a8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800063ca:	85ce                	mv	a1,s3
    800063cc:	00092503          	lw	a0,0(s2)
    800063d0:	ffffe097          	auipc	ra,0xffffe
    800063d4:	a4a080e7          	jalr	-1462(ra) # 80003e1a <ialloc>
    800063d8:	84aa                	mv	s1,a0
    800063da:	c521                	beqz	a0,80006422 <create+0xec>
  ilock(ip);
    800063dc:	ffffe097          	auipc	ra,0xffffe
    800063e0:	bd6080e7          	jalr	-1066(ra) # 80003fb2 <ilock>
  ip->major = major;
    800063e4:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800063e8:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800063ec:	4a05                	li	s4,1
    800063ee:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800063f2:	8526                	mv	a0,s1
    800063f4:	ffffe097          	auipc	ra,0xffffe
    800063f8:	af4080e7          	jalr	-1292(ra) # 80003ee8 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800063fc:	2981                	sext.w	s3,s3
    800063fe:	03498a63          	beq	s3,s4,80006432 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80006402:	40d0                	lw	a2,4(s1)
    80006404:	fb040593          	addi	a1,s0,-80
    80006408:	854a                	mv	a0,s2
    8000640a:	ffffe097          	auipc	ra,0xffffe
    8000640e:	29c080e7          	jalr	668(ra) # 800046a6 <dirlink>
    80006412:	06054b63          	bltz	a0,80006488 <create+0x152>
  iunlockput(dp);
    80006416:	854a                	mv	a0,s2
    80006418:	ffffe097          	auipc	ra,0xffffe
    8000641c:	dfc080e7          	jalr	-516(ra) # 80004214 <iunlockput>
  return ip;
    80006420:	b761                	j	800063a8 <create+0x72>
    panic("create: ialloc");
    80006422:	00003517          	auipc	a0,0x3
    80006426:	7e650513          	addi	a0,a0,2022 # 80009c08 <syscalls+0x378>
    8000642a:	ffffa097          	auipc	ra,0xffffa
    8000642e:	100080e7          	jalr	256(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80006432:	04a95783          	lhu	a5,74(s2)
    80006436:	2785                	addiw	a5,a5,1
    80006438:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000643c:	854a                	mv	a0,s2
    8000643e:	ffffe097          	auipc	ra,0xffffe
    80006442:	aaa080e7          	jalr	-1366(ra) # 80003ee8 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80006446:	40d0                	lw	a2,4(s1)
    80006448:	00003597          	auipc	a1,0x3
    8000644c:	63858593          	addi	a1,a1,1592 # 80009a80 <syscalls+0x1f0>
    80006450:	8526                	mv	a0,s1
    80006452:	ffffe097          	auipc	ra,0xffffe
    80006456:	254080e7          	jalr	596(ra) # 800046a6 <dirlink>
    8000645a:	00054f63          	bltz	a0,80006478 <create+0x142>
    8000645e:	00492603          	lw	a2,4(s2)
    80006462:	00003597          	auipc	a1,0x3
    80006466:	62658593          	addi	a1,a1,1574 # 80009a88 <syscalls+0x1f8>
    8000646a:	8526                	mv	a0,s1
    8000646c:	ffffe097          	auipc	ra,0xffffe
    80006470:	23a080e7          	jalr	570(ra) # 800046a6 <dirlink>
    80006474:	f80557e3          	bgez	a0,80006402 <create+0xcc>
      panic("create dots");
    80006478:	00003517          	auipc	a0,0x3
    8000647c:	7a050513          	addi	a0,a0,1952 # 80009c18 <syscalls+0x388>
    80006480:	ffffa097          	auipc	ra,0xffffa
    80006484:	0aa080e7          	jalr	170(ra) # 8000052a <panic>
    panic("create: dirlink");
    80006488:	00003517          	auipc	a0,0x3
    8000648c:	7a050513          	addi	a0,a0,1952 # 80009c28 <syscalls+0x398>
    80006490:	ffffa097          	auipc	ra,0xffffa
    80006494:	09a080e7          	jalr	154(ra) # 8000052a <panic>
    return 0;
    80006498:	84aa                	mv	s1,a0
    8000649a:	b739                	j	800063a8 <create+0x72>

000000008000649c <sys_open>:

uint64
sys_open(void)
{
    8000649c:	7131                	addi	sp,sp,-192
    8000649e:	fd06                	sd	ra,184(sp)
    800064a0:	f922                	sd	s0,176(sp)
    800064a2:	f526                	sd	s1,168(sp)
    800064a4:	f14a                	sd	s2,160(sp)
    800064a6:	ed4e                	sd	s3,152(sp)
    800064a8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800064aa:	08000613          	li	a2,128
    800064ae:	f5040593          	addi	a1,s0,-176
    800064b2:	4501                	li	a0,0
    800064b4:	ffffd097          	auipc	ra,0xffffd
    800064b8:	fd0080e7          	jalr	-48(ra) # 80003484 <argstr>
    return -1;
    800064bc:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800064be:	0c054163          	bltz	a0,80006580 <sys_open+0xe4>
    800064c2:	f4c40593          	addi	a1,s0,-180
    800064c6:	4505                	li	a0,1
    800064c8:	ffffd097          	auipc	ra,0xffffd
    800064cc:	f78080e7          	jalr	-136(ra) # 80003440 <argint>
    800064d0:	0a054863          	bltz	a0,80006580 <sys_open+0xe4>

  begin_op();
    800064d4:	ffffe097          	auipc	ra,0xffffe
    800064d8:	7c6080e7          	jalr	1990(ra) # 80004c9a <begin_op>

  if(omode & O_CREATE){
    800064dc:	f4c42783          	lw	a5,-180(s0)
    800064e0:	2007f793          	andi	a5,a5,512
    800064e4:	cbdd                	beqz	a5,8000659a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800064e6:	4681                	li	a3,0
    800064e8:	4601                	li	a2,0
    800064ea:	4589                	li	a1,2
    800064ec:	f5040513          	addi	a0,s0,-176
    800064f0:	00000097          	auipc	ra,0x0
    800064f4:	e46080e7          	jalr	-442(ra) # 80006336 <create>
    800064f8:	892a                	mv	s2,a0
    if(ip == 0){
    800064fa:	c959                	beqz	a0,80006590 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800064fc:	04491703          	lh	a4,68(s2)
    80006500:	478d                	li	a5,3
    80006502:	00f71763          	bne	a4,a5,80006510 <sys_open+0x74>
    80006506:	04695703          	lhu	a4,70(s2)
    8000650a:	47a5                	li	a5,9
    8000650c:	0ce7ec63          	bltu	a5,a4,800065e4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006510:	fffff097          	auipc	ra,0xfffff
    80006514:	b9a080e7          	jalr	-1126(ra) # 800050aa <filealloc>
    80006518:	89aa                	mv	s3,a0
    8000651a:	10050263          	beqz	a0,8000661e <sys_open+0x182>
    8000651e:	00000097          	auipc	ra,0x0
    80006522:	8e2080e7          	jalr	-1822(ra) # 80005e00 <fdalloc>
    80006526:	84aa                	mv	s1,a0
    80006528:	0e054663          	bltz	a0,80006614 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000652c:	04491703          	lh	a4,68(s2)
    80006530:	478d                	li	a5,3
    80006532:	0cf70463          	beq	a4,a5,800065fa <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006536:	4789                	li	a5,2
    80006538:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000653c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006540:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006544:	f4c42783          	lw	a5,-180(s0)
    80006548:	0017c713          	xori	a4,a5,1
    8000654c:	8b05                	andi	a4,a4,1
    8000654e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006552:	0037f713          	andi	a4,a5,3
    80006556:	00e03733          	snez	a4,a4
    8000655a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000655e:	4007f793          	andi	a5,a5,1024
    80006562:	c791                	beqz	a5,8000656e <sys_open+0xd2>
    80006564:	04491703          	lh	a4,68(s2)
    80006568:	4789                	li	a5,2
    8000656a:	08f70f63          	beq	a4,a5,80006608 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000656e:	854a                	mv	a0,s2
    80006570:	ffffe097          	auipc	ra,0xffffe
    80006574:	b04080e7          	jalr	-1276(ra) # 80004074 <iunlock>
  end_op();
    80006578:	ffffe097          	auipc	ra,0xffffe
    8000657c:	7a2080e7          	jalr	1954(ra) # 80004d1a <end_op>

  return fd;
}
    80006580:	8526                	mv	a0,s1
    80006582:	70ea                	ld	ra,184(sp)
    80006584:	744a                	ld	s0,176(sp)
    80006586:	74aa                	ld	s1,168(sp)
    80006588:	790a                	ld	s2,160(sp)
    8000658a:	69ea                	ld	s3,152(sp)
    8000658c:	6129                	addi	sp,sp,192
    8000658e:	8082                	ret
      end_op();
    80006590:	ffffe097          	auipc	ra,0xffffe
    80006594:	78a080e7          	jalr	1930(ra) # 80004d1a <end_op>
      return -1;
    80006598:	b7e5                	j	80006580 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000659a:	f5040513          	addi	a0,s0,-176
    8000659e:	ffffe097          	auipc	ra,0xffffe
    800065a2:	1ca080e7          	jalr	458(ra) # 80004768 <namei>
    800065a6:	892a                	mv	s2,a0
    800065a8:	c905                	beqz	a0,800065d8 <sys_open+0x13c>
    ilock(ip);
    800065aa:	ffffe097          	auipc	ra,0xffffe
    800065ae:	a08080e7          	jalr	-1528(ra) # 80003fb2 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800065b2:	04491703          	lh	a4,68(s2)
    800065b6:	4785                	li	a5,1
    800065b8:	f4f712e3          	bne	a4,a5,800064fc <sys_open+0x60>
    800065bc:	f4c42783          	lw	a5,-180(s0)
    800065c0:	dba1                	beqz	a5,80006510 <sys_open+0x74>
      iunlockput(ip);
    800065c2:	854a                	mv	a0,s2
    800065c4:	ffffe097          	auipc	ra,0xffffe
    800065c8:	c50080e7          	jalr	-944(ra) # 80004214 <iunlockput>
      end_op();
    800065cc:	ffffe097          	auipc	ra,0xffffe
    800065d0:	74e080e7          	jalr	1870(ra) # 80004d1a <end_op>
      return -1;
    800065d4:	54fd                	li	s1,-1
    800065d6:	b76d                	j	80006580 <sys_open+0xe4>
      end_op();
    800065d8:	ffffe097          	auipc	ra,0xffffe
    800065dc:	742080e7          	jalr	1858(ra) # 80004d1a <end_op>
      return -1;
    800065e0:	54fd                	li	s1,-1
    800065e2:	bf79                	j	80006580 <sys_open+0xe4>
    iunlockput(ip);
    800065e4:	854a                	mv	a0,s2
    800065e6:	ffffe097          	auipc	ra,0xffffe
    800065ea:	c2e080e7          	jalr	-978(ra) # 80004214 <iunlockput>
    end_op();
    800065ee:	ffffe097          	auipc	ra,0xffffe
    800065f2:	72c080e7          	jalr	1836(ra) # 80004d1a <end_op>
    return -1;
    800065f6:	54fd                	li	s1,-1
    800065f8:	b761                	j	80006580 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800065fa:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800065fe:	04691783          	lh	a5,70(s2)
    80006602:	02f99223          	sh	a5,36(s3)
    80006606:	bf2d                	j	80006540 <sys_open+0xa4>
    itrunc(ip);
    80006608:	854a                	mv	a0,s2
    8000660a:	ffffe097          	auipc	ra,0xffffe
    8000660e:	ab6080e7          	jalr	-1354(ra) # 800040c0 <itrunc>
    80006612:	bfb1                	j	8000656e <sys_open+0xd2>
      fileclose(f);
    80006614:	854e                	mv	a0,s3
    80006616:	fffff097          	auipc	ra,0xfffff
    8000661a:	b50080e7          	jalr	-1200(ra) # 80005166 <fileclose>
    iunlockput(ip);
    8000661e:	854a                	mv	a0,s2
    80006620:	ffffe097          	auipc	ra,0xffffe
    80006624:	bf4080e7          	jalr	-1036(ra) # 80004214 <iunlockput>
    end_op();
    80006628:	ffffe097          	auipc	ra,0xffffe
    8000662c:	6f2080e7          	jalr	1778(ra) # 80004d1a <end_op>
    return -1;
    80006630:	54fd                	li	s1,-1
    80006632:	b7b9                	j	80006580 <sys_open+0xe4>

0000000080006634 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006634:	7175                	addi	sp,sp,-144
    80006636:	e506                	sd	ra,136(sp)
    80006638:	e122                	sd	s0,128(sp)
    8000663a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000663c:	ffffe097          	auipc	ra,0xffffe
    80006640:	65e080e7          	jalr	1630(ra) # 80004c9a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006644:	08000613          	li	a2,128
    80006648:	f7040593          	addi	a1,s0,-144
    8000664c:	4501                	li	a0,0
    8000664e:	ffffd097          	auipc	ra,0xffffd
    80006652:	e36080e7          	jalr	-458(ra) # 80003484 <argstr>
    80006656:	02054963          	bltz	a0,80006688 <sys_mkdir+0x54>
    8000665a:	4681                	li	a3,0
    8000665c:	4601                	li	a2,0
    8000665e:	4585                	li	a1,1
    80006660:	f7040513          	addi	a0,s0,-144
    80006664:	00000097          	auipc	ra,0x0
    80006668:	cd2080e7          	jalr	-814(ra) # 80006336 <create>
    8000666c:	cd11                	beqz	a0,80006688 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000666e:	ffffe097          	auipc	ra,0xffffe
    80006672:	ba6080e7          	jalr	-1114(ra) # 80004214 <iunlockput>
  end_op();
    80006676:	ffffe097          	auipc	ra,0xffffe
    8000667a:	6a4080e7          	jalr	1700(ra) # 80004d1a <end_op>
  return 0;
    8000667e:	4501                	li	a0,0
}
    80006680:	60aa                	ld	ra,136(sp)
    80006682:	640a                	ld	s0,128(sp)
    80006684:	6149                	addi	sp,sp,144
    80006686:	8082                	ret
    end_op();
    80006688:	ffffe097          	auipc	ra,0xffffe
    8000668c:	692080e7          	jalr	1682(ra) # 80004d1a <end_op>
    return -1;
    80006690:	557d                	li	a0,-1
    80006692:	b7fd                	j	80006680 <sys_mkdir+0x4c>

0000000080006694 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006694:	7135                	addi	sp,sp,-160
    80006696:	ed06                	sd	ra,152(sp)
    80006698:	e922                	sd	s0,144(sp)
    8000669a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000669c:	ffffe097          	auipc	ra,0xffffe
    800066a0:	5fe080e7          	jalr	1534(ra) # 80004c9a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800066a4:	08000613          	li	a2,128
    800066a8:	f7040593          	addi	a1,s0,-144
    800066ac:	4501                	li	a0,0
    800066ae:	ffffd097          	auipc	ra,0xffffd
    800066b2:	dd6080e7          	jalr	-554(ra) # 80003484 <argstr>
    800066b6:	04054a63          	bltz	a0,8000670a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800066ba:	f6c40593          	addi	a1,s0,-148
    800066be:	4505                	li	a0,1
    800066c0:	ffffd097          	auipc	ra,0xffffd
    800066c4:	d80080e7          	jalr	-640(ra) # 80003440 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800066c8:	04054163          	bltz	a0,8000670a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800066cc:	f6840593          	addi	a1,s0,-152
    800066d0:	4509                	li	a0,2
    800066d2:	ffffd097          	auipc	ra,0xffffd
    800066d6:	d6e080e7          	jalr	-658(ra) # 80003440 <argint>
     argint(1, &major) < 0 ||
    800066da:	02054863          	bltz	a0,8000670a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800066de:	f6841683          	lh	a3,-152(s0)
    800066e2:	f6c41603          	lh	a2,-148(s0)
    800066e6:	458d                	li	a1,3
    800066e8:	f7040513          	addi	a0,s0,-144
    800066ec:	00000097          	auipc	ra,0x0
    800066f0:	c4a080e7          	jalr	-950(ra) # 80006336 <create>
     argint(2, &minor) < 0 ||
    800066f4:	c919                	beqz	a0,8000670a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800066f6:	ffffe097          	auipc	ra,0xffffe
    800066fa:	b1e080e7          	jalr	-1250(ra) # 80004214 <iunlockput>
  end_op();
    800066fe:	ffffe097          	auipc	ra,0xffffe
    80006702:	61c080e7          	jalr	1564(ra) # 80004d1a <end_op>
  return 0;
    80006706:	4501                	li	a0,0
    80006708:	a031                	j	80006714 <sys_mknod+0x80>
    end_op();
    8000670a:	ffffe097          	auipc	ra,0xffffe
    8000670e:	610080e7          	jalr	1552(ra) # 80004d1a <end_op>
    return -1;
    80006712:	557d                	li	a0,-1
}
    80006714:	60ea                	ld	ra,152(sp)
    80006716:	644a                	ld	s0,144(sp)
    80006718:	610d                	addi	sp,sp,160
    8000671a:	8082                	ret

000000008000671c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000671c:	7135                	addi	sp,sp,-160
    8000671e:	ed06                	sd	ra,152(sp)
    80006720:	e922                	sd	s0,144(sp)
    80006722:	e526                	sd	s1,136(sp)
    80006724:	e14a                	sd	s2,128(sp)
    80006726:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006728:	ffffc097          	auipc	ra,0xffffc
    8000672c:	adc080e7          	jalr	-1316(ra) # 80002204 <myproc>
    80006730:	892a                	mv	s2,a0
  
  begin_op();
    80006732:	ffffe097          	auipc	ra,0xffffe
    80006736:	568080e7          	jalr	1384(ra) # 80004c9a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000673a:	08000613          	li	a2,128
    8000673e:	f6040593          	addi	a1,s0,-160
    80006742:	4501                	li	a0,0
    80006744:	ffffd097          	auipc	ra,0xffffd
    80006748:	d40080e7          	jalr	-704(ra) # 80003484 <argstr>
    8000674c:	04054b63          	bltz	a0,800067a2 <sys_chdir+0x86>
    80006750:	f6040513          	addi	a0,s0,-160
    80006754:	ffffe097          	auipc	ra,0xffffe
    80006758:	014080e7          	jalr	20(ra) # 80004768 <namei>
    8000675c:	84aa                	mv	s1,a0
    8000675e:	c131                	beqz	a0,800067a2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006760:	ffffe097          	auipc	ra,0xffffe
    80006764:	852080e7          	jalr	-1966(ra) # 80003fb2 <ilock>
  if(ip->type != T_DIR){
    80006768:	04449703          	lh	a4,68(s1)
    8000676c:	4785                	li	a5,1
    8000676e:	04f71063          	bne	a4,a5,800067ae <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006772:	8526                	mv	a0,s1
    80006774:	ffffe097          	auipc	ra,0xffffe
    80006778:	900080e7          	jalr	-1792(ra) # 80004074 <iunlock>
  iput(p->cwd);
    8000677c:	15093503          	ld	a0,336(s2)
    80006780:	ffffe097          	auipc	ra,0xffffe
    80006784:	9ec080e7          	jalr	-1556(ra) # 8000416c <iput>
  end_op();
    80006788:	ffffe097          	auipc	ra,0xffffe
    8000678c:	592080e7          	jalr	1426(ra) # 80004d1a <end_op>
  p->cwd = ip;
    80006790:	14993823          	sd	s1,336(s2)
  return 0;
    80006794:	4501                	li	a0,0
}
    80006796:	60ea                	ld	ra,152(sp)
    80006798:	644a                	ld	s0,144(sp)
    8000679a:	64aa                	ld	s1,136(sp)
    8000679c:	690a                	ld	s2,128(sp)
    8000679e:	610d                	addi	sp,sp,160
    800067a0:	8082                	ret
    end_op();
    800067a2:	ffffe097          	auipc	ra,0xffffe
    800067a6:	578080e7          	jalr	1400(ra) # 80004d1a <end_op>
    return -1;
    800067aa:	557d                	li	a0,-1
    800067ac:	b7ed                	j	80006796 <sys_chdir+0x7a>
    iunlockput(ip);
    800067ae:	8526                	mv	a0,s1
    800067b0:	ffffe097          	auipc	ra,0xffffe
    800067b4:	a64080e7          	jalr	-1436(ra) # 80004214 <iunlockput>
    end_op();
    800067b8:	ffffe097          	auipc	ra,0xffffe
    800067bc:	562080e7          	jalr	1378(ra) # 80004d1a <end_op>
    return -1;
    800067c0:	557d                	li	a0,-1
    800067c2:	bfd1                	j	80006796 <sys_chdir+0x7a>

00000000800067c4 <sys_exec>:

uint64
sys_exec(void)
{
    800067c4:	7145                	addi	sp,sp,-464
    800067c6:	e786                	sd	ra,456(sp)
    800067c8:	e3a2                	sd	s0,448(sp)
    800067ca:	ff26                	sd	s1,440(sp)
    800067cc:	fb4a                	sd	s2,432(sp)
    800067ce:	f74e                	sd	s3,424(sp)
    800067d0:	f352                	sd	s4,416(sp)
    800067d2:	ef56                	sd	s5,408(sp)
    800067d4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800067d6:	08000613          	li	a2,128
    800067da:	f4040593          	addi	a1,s0,-192
    800067de:	4501                	li	a0,0
    800067e0:	ffffd097          	auipc	ra,0xffffd
    800067e4:	ca4080e7          	jalr	-860(ra) # 80003484 <argstr>
    return -1;
    800067e8:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800067ea:	0c054a63          	bltz	a0,800068be <sys_exec+0xfa>
    800067ee:	e3840593          	addi	a1,s0,-456
    800067f2:	4505                	li	a0,1
    800067f4:	ffffd097          	auipc	ra,0xffffd
    800067f8:	c6e080e7          	jalr	-914(ra) # 80003462 <argaddr>
    800067fc:	0c054163          	bltz	a0,800068be <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006800:	10000613          	li	a2,256
    80006804:	4581                	li	a1,0
    80006806:	e4040513          	addi	a0,s0,-448
    8000680a:	ffffa097          	auipc	ra,0xffffa
    8000680e:	4b4080e7          	jalr	1204(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006812:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006816:	89a6                	mv	s3,s1
    80006818:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000681a:	02000a13          	li	s4,32
    8000681e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006822:	00391793          	slli	a5,s2,0x3
    80006826:	e3040593          	addi	a1,s0,-464
    8000682a:	e3843503          	ld	a0,-456(s0)
    8000682e:	953e                	add	a0,a0,a5
    80006830:	ffffd097          	auipc	ra,0xffffd
    80006834:	b76080e7          	jalr	-1162(ra) # 800033a6 <fetchaddr>
    80006838:	02054a63          	bltz	a0,8000686c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000683c:	e3043783          	ld	a5,-464(s0)
    80006840:	c3b9                	beqz	a5,80006886 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006842:	ffffa097          	auipc	ra,0xffffa
    80006846:	290080e7          	jalr	656(ra) # 80000ad2 <kalloc>
    8000684a:	85aa                	mv	a1,a0
    8000684c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006850:	cd11                	beqz	a0,8000686c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006852:	6605                	lui	a2,0x1
    80006854:	e3043503          	ld	a0,-464(s0)
    80006858:	ffffd097          	auipc	ra,0xffffd
    8000685c:	ba0080e7          	jalr	-1120(ra) # 800033f8 <fetchstr>
    80006860:	00054663          	bltz	a0,8000686c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006864:	0905                	addi	s2,s2,1
    80006866:	09a1                	addi	s3,s3,8
    80006868:	fb491be3          	bne	s2,s4,8000681e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000686c:	10048913          	addi	s2,s1,256
    80006870:	6088                	ld	a0,0(s1)
    80006872:	c529                	beqz	a0,800068bc <sys_exec+0xf8>
    kfree(argv[i]);
    80006874:	ffffa097          	auipc	ra,0xffffa
    80006878:	162080e7          	jalr	354(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000687c:	04a1                	addi	s1,s1,8
    8000687e:	ff2499e3          	bne	s1,s2,80006870 <sys_exec+0xac>
  return -1;
    80006882:	597d                	li	s2,-1
    80006884:	a82d                	j	800068be <sys_exec+0xfa>
      argv[i] = 0;
    80006886:	0a8e                	slli	s5,s5,0x3
    80006888:	fc040793          	addi	a5,s0,-64
    8000688c:	9abe                	add	s5,s5,a5
    8000688e:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd0e80>
  int ret = exec(path, argv);
    80006892:	e4040593          	addi	a1,s0,-448
    80006896:	f4040513          	addi	a0,s0,-192
    8000689a:	fffff097          	auipc	ra,0xfffff
    8000689e:	114080e7          	jalr	276(ra) # 800059ae <exec>
    800068a2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800068a4:	10048993          	addi	s3,s1,256
    800068a8:	6088                	ld	a0,0(s1)
    800068aa:	c911                	beqz	a0,800068be <sys_exec+0xfa>
    kfree(argv[i]);
    800068ac:	ffffa097          	auipc	ra,0xffffa
    800068b0:	12a080e7          	jalr	298(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800068b4:	04a1                	addi	s1,s1,8
    800068b6:	ff3499e3          	bne	s1,s3,800068a8 <sys_exec+0xe4>
    800068ba:	a011                	j	800068be <sys_exec+0xfa>
  return -1;
    800068bc:	597d                	li	s2,-1
}
    800068be:	854a                	mv	a0,s2
    800068c0:	60be                	ld	ra,456(sp)
    800068c2:	641e                	ld	s0,448(sp)
    800068c4:	74fa                	ld	s1,440(sp)
    800068c6:	795a                	ld	s2,432(sp)
    800068c8:	79ba                	ld	s3,424(sp)
    800068ca:	7a1a                	ld	s4,416(sp)
    800068cc:	6afa                	ld	s5,408(sp)
    800068ce:	6179                	addi	sp,sp,464
    800068d0:	8082                	ret

00000000800068d2 <sys_pipe>:

uint64
sys_pipe(void)
{
    800068d2:	7139                	addi	sp,sp,-64
    800068d4:	fc06                	sd	ra,56(sp)
    800068d6:	f822                	sd	s0,48(sp)
    800068d8:	f426                	sd	s1,40(sp)
    800068da:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800068dc:	ffffc097          	auipc	ra,0xffffc
    800068e0:	928080e7          	jalr	-1752(ra) # 80002204 <myproc>
    800068e4:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800068e6:	fd840593          	addi	a1,s0,-40
    800068ea:	4501                	li	a0,0
    800068ec:	ffffd097          	auipc	ra,0xffffd
    800068f0:	b76080e7          	jalr	-1162(ra) # 80003462 <argaddr>
    return -1;
    800068f4:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800068f6:	0e054063          	bltz	a0,800069d6 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800068fa:	fc840593          	addi	a1,s0,-56
    800068fe:	fd040513          	addi	a0,s0,-48
    80006902:	fffff097          	auipc	ra,0xfffff
    80006906:	d8a080e7          	jalr	-630(ra) # 8000568c <pipealloc>
    return -1;
    8000690a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000690c:	0c054563          	bltz	a0,800069d6 <sys_pipe+0x104>
  fd0 = -1;
    80006910:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006914:	fd043503          	ld	a0,-48(s0)
    80006918:	fffff097          	auipc	ra,0xfffff
    8000691c:	4e8080e7          	jalr	1256(ra) # 80005e00 <fdalloc>
    80006920:	fca42223          	sw	a0,-60(s0)
    80006924:	08054c63          	bltz	a0,800069bc <sys_pipe+0xea>
    80006928:	fc843503          	ld	a0,-56(s0)
    8000692c:	fffff097          	auipc	ra,0xfffff
    80006930:	4d4080e7          	jalr	1236(ra) # 80005e00 <fdalloc>
    80006934:	fca42023          	sw	a0,-64(s0)
    80006938:	06054863          	bltz	a0,800069a8 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000693c:	4691                	li	a3,4
    8000693e:	fc440613          	addi	a2,s0,-60
    80006942:	fd843583          	ld	a1,-40(s0)
    80006946:	68a8                	ld	a0,80(s1)
    80006948:	ffffb097          	auipc	ra,0xffffb
    8000694c:	57c080e7          	jalr	1404(ra) # 80001ec4 <copyout>
    80006950:	02054063          	bltz	a0,80006970 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006954:	4691                	li	a3,4
    80006956:	fc040613          	addi	a2,s0,-64
    8000695a:	fd843583          	ld	a1,-40(s0)
    8000695e:	0591                	addi	a1,a1,4
    80006960:	68a8                	ld	a0,80(s1)
    80006962:	ffffb097          	auipc	ra,0xffffb
    80006966:	562080e7          	jalr	1378(ra) # 80001ec4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000696a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000696c:	06055563          	bgez	a0,800069d6 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006970:	fc442783          	lw	a5,-60(s0)
    80006974:	07e9                	addi	a5,a5,26
    80006976:	078e                	slli	a5,a5,0x3
    80006978:	97a6                	add	a5,a5,s1
    8000697a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000697e:	fc042503          	lw	a0,-64(s0)
    80006982:	0569                	addi	a0,a0,26
    80006984:	050e                	slli	a0,a0,0x3
    80006986:	9526                	add	a0,a0,s1
    80006988:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000698c:	fd043503          	ld	a0,-48(s0)
    80006990:	ffffe097          	auipc	ra,0xffffe
    80006994:	7d6080e7          	jalr	2006(ra) # 80005166 <fileclose>
    fileclose(wf);
    80006998:	fc843503          	ld	a0,-56(s0)
    8000699c:	ffffe097          	auipc	ra,0xffffe
    800069a0:	7ca080e7          	jalr	1994(ra) # 80005166 <fileclose>
    return -1;
    800069a4:	57fd                	li	a5,-1
    800069a6:	a805                	j	800069d6 <sys_pipe+0x104>
    if(fd0 >= 0)
    800069a8:	fc442783          	lw	a5,-60(s0)
    800069ac:	0007c863          	bltz	a5,800069bc <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800069b0:	01a78513          	addi	a0,a5,26
    800069b4:	050e                	slli	a0,a0,0x3
    800069b6:	9526                	add	a0,a0,s1
    800069b8:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800069bc:	fd043503          	ld	a0,-48(s0)
    800069c0:	ffffe097          	auipc	ra,0xffffe
    800069c4:	7a6080e7          	jalr	1958(ra) # 80005166 <fileclose>
    fileclose(wf);
    800069c8:	fc843503          	ld	a0,-56(s0)
    800069cc:	ffffe097          	auipc	ra,0xffffe
    800069d0:	79a080e7          	jalr	1946(ra) # 80005166 <fileclose>
    return -1;
    800069d4:	57fd                	li	a5,-1
}
    800069d6:	853e                	mv	a0,a5
    800069d8:	70e2                	ld	ra,56(sp)
    800069da:	7442                	ld	s0,48(sp)
    800069dc:	74a2                	ld	s1,40(sp)
    800069de:	6121                	addi	sp,sp,64
    800069e0:	8082                	ret
	...

00000000800069f0 <kernelvec>:
    800069f0:	7111                	addi	sp,sp,-256
    800069f2:	e006                	sd	ra,0(sp)
    800069f4:	e40a                	sd	sp,8(sp)
    800069f6:	e80e                	sd	gp,16(sp)
    800069f8:	ec12                	sd	tp,24(sp)
    800069fa:	f016                	sd	t0,32(sp)
    800069fc:	f41a                	sd	t1,40(sp)
    800069fe:	f81e                	sd	t2,48(sp)
    80006a00:	fc22                	sd	s0,56(sp)
    80006a02:	e0a6                	sd	s1,64(sp)
    80006a04:	e4aa                	sd	a0,72(sp)
    80006a06:	e8ae                	sd	a1,80(sp)
    80006a08:	ecb2                	sd	a2,88(sp)
    80006a0a:	f0b6                	sd	a3,96(sp)
    80006a0c:	f4ba                	sd	a4,104(sp)
    80006a0e:	f8be                	sd	a5,112(sp)
    80006a10:	fcc2                	sd	a6,120(sp)
    80006a12:	e146                	sd	a7,128(sp)
    80006a14:	e54a                	sd	s2,136(sp)
    80006a16:	e94e                	sd	s3,144(sp)
    80006a18:	ed52                	sd	s4,152(sp)
    80006a1a:	f156                	sd	s5,160(sp)
    80006a1c:	f55a                	sd	s6,168(sp)
    80006a1e:	f95e                	sd	s7,176(sp)
    80006a20:	fd62                	sd	s8,184(sp)
    80006a22:	e1e6                	sd	s9,192(sp)
    80006a24:	e5ea                	sd	s10,200(sp)
    80006a26:	e9ee                	sd	s11,208(sp)
    80006a28:	edf2                	sd	t3,216(sp)
    80006a2a:	f1f6                	sd	t4,224(sp)
    80006a2c:	f5fa                	sd	t5,232(sp)
    80006a2e:	f9fe                	sd	t6,240(sp)
    80006a30:	843fc0ef          	jal	ra,80003272 <kerneltrap>
    80006a34:	6082                	ld	ra,0(sp)
    80006a36:	6122                	ld	sp,8(sp)
    80006a38:	61c2                	ld	gp,16(sp)
    80006a3a:	7282                	ld	t0,32(sp)
    80006a3c:	7322                	ld	t1,40(sp)
    80006a3e:	73c2                	ld	t2,48(sp)
    80006a40:	7462                	ld	s0,56(sp)
    80006a42:	6486                	ld	s1,64(sp)
    80006a44:	6526                	ld	a0,72(sp)
    80006a46:	65c6                	ld	a1,80(sp)
    80006a48:	6666                	ld	a2,88(sp)
    80006a4a:	7686                	ld	a3,96(sp)
    80006a4c:	7726                	ld	a4,104(sp)
    80006a4e:	77c6                	ld	a5,112(sp)
    80006a50:	7866                	ld	a6,120(sp)
    80006a52:	688a                	ld	a7,128(sp)
    80006a54:	692a                	ld	s2,136(sp)
    80006a56:	69ca                	ld	s3,144(sp)
    80006a58:	6a6a                	ld	s4,152(sp)
    80006a5a:	7a8a                	ld	s5,160(sp)
    80006a5c:	7b2a                	ld	s6,168(sp)
    80006a5e:	7bca                	ld	s7,176(sp)
    80006a60:	7c6a                	ld	s8,184(sp)
    80006a62:	6c8e                	ld	s9,192(sp)
    80006a64:	6d2e                	ld	s10,200(sp)
    80006a66:	6dce                	ld	s11,208(sp)
    80006a68:	6e6e                	ld	t3,216(sp)
    80006a6a:	7e8e                	ld	t4,224(sp)
    80006a6c:	7f2e                	ld	t5,232(sp)
    80006a6e:	7fce                	ld	t6,240(sp)
    80006a70:	6111                	addi	sp,sp,256
    80006a72:	10200073          	sret
    80006a76:	00000013          	nop
    80006a7a:	00000013          	nop
    80006a7e:	0001                	nop

0000000080006a80 <timervec>:
    80006a80:	34051573          	csrrw	a0,mscratch,a0
    80006a84:	e10c                	sd	a1,0(a0)
    80006a86:	e510                	sd	a2,8(a0)
    80006a88:	e914                	sd	a3,16(a0)
    80006a8a:	6d0c                	ld	a1,24(a0)
    80006a8c:	7110                	ld	a2,32(a0)
    80006a8e:	6194                	ld	a3,0(a1)
    80006a90:	96b2                	add	a3,a3,a2
    80006a92:	e194                	sd	a3,0(a1)
    80006a94:	4589                	li	a1,2
    80006a96:	14459073          	csrw	sip,a1
    80006a9a:	6914                	ld	a3,16(a0)
    80006a9c:	6510                	ld	a2,8(a0)
    80006a9e:	610c                	ld	a1,0(a0)
    80006aa0:	34051573          	csrrw	a0,mscratch,a0
    80006aa4:	30200073          	mret
	...

0000000080006aaa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80006aaa:	1141                	addi	sp,sp,-16
    80006aac:	e422                	sd	s0,8(sp)
    80006aae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006ab0:	0c0007b7          	lui	a5,0xc000
    80006ab4:	4705                	li	a4,1
    80006ab6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006ab8:	c3d8                	sw	a4,4(a5)
}
    80006aba:	6422                	ld	s0,8(sp)
    80006abc:	0141                	addi	sp,sp,16
    80006abe:	8082                	ret

0000000080006ac0 <plicinithart>:

void
plicinithart(void)
{
    80006ac0:	1141                	addi	sp,sp,-16
    80006ac2:	e406                	sd	ra,8(sp)
    80006ac4:	e022                	sd	s0,0(sp)
    80006ac6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006ac8:	ffffb097          	auipc	ra,0xffffb
    80006acc:	710080e7          	jalr	1808(ra) # 800021d8 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006ad0:	0085171b          	slliw	a4,a0,0x8
    80006ad4:	0c0027b7          	lui	a5,0xc002
    80006ad8:	97ba                	add	a5,a5,a4
    80006ada:	40200713          	li	a4,1026
    80006ade:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006ae2:	00d5151b          	slliw	a0,a0,0xd
    80006ae6:	0c2017b7          	lui	a5,0xc201
    80006aea:	953e                	add	a0,a0,a5
    80006aec:	00052023          	sw	zero,0(a0)
}
    80006af0:	60a2                	ld	ra,8(sp)
    80006af2:	6402                	ld	s0,0(sp)
    80006af4:	0141                	addi	sp,sp,16
    80006af6:	8082                	ret

0000000080006af8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006af8:	1141                	addi	sp,sp,-16
    80006afa:	e406                	sd	ra,8(sp)
    80006afc:	e022                	sd	s0,0(sp)
    80006afe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006b00:	ffffb097          	auipc	ra,0xffffb
    80006b04:	6d8080e7          	jalr	1752(ra) # 800021d8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006b08:	00d5179b          	slliw	a5,a0,0xd
    80006b0c:	0c201537          	lui	a0,0xc201
    80006b10:	953e                	add	a0,a0,a5
  return irq;
}
    80006b12:	4148                	lw	a0,4(a0)
    80006b14:	60a2                	ld	ra,8(sp)
    80006b16:	6402                	ld	s0,0(sp)
    80006b18:	0141                	addi	sp,sp,16
    80006b1a:	8082                	ret

0000000080006b1c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80006b1c:	1101                	addi	sp,sp,-32
    80006b1e:	ec06                	sd	ra,24(sp)
    80006b20:	e822                	sd	s0,16(sp)
    80006b22:	e426                	sd	s1,8(sp)
    80006b24:	1000                	addi	s0,sp,32
    80006b26:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006b28:	ffffb097          	auipc	ra,0xffffb
    80006b2c:	6b0080e7          	jalr	1712(ra) # 800021d8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006b30:	00d5151b          	slliw	a0,a0,0xd
    80006b34:	0c2017b7          	lui	a5,0xc201
    80006b38:	97aa                	add	a5,a5,a0
    80006b3a:	c3c4                	sw	s1,4(a5)
}
    80006b3c:	60e2                	ld	ra,24(sp)
    80006b3e:	6442                	ld	s0,16(sp)
    80006b40:	64a2                	ld	s1,8(sp)
    80006b42:	6105                	addi	sp,sp,32
    80006b44:	8082                	ret

0000000080006b46 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006b46:	1141                	addi	sp,sp,-16
    80006b48:	e406                	sd	ra,8(sp)
    80006b4a:	e022                	sd	s0,0(sp)
    80006b4c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80006b4e:	479d                	li	a5,7
    80006b50:	06a7c963          	blt	a5,a0,80006bc2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006b54:	00024797          	auipc	a5,0x24
    80006b58:	4ac78793          	addi	a5,a5,1196 # 8002b000 <disk>
    80006b5c:	00a78733          	add	a4,a5,a0
    80006b60:	6789                	lui	a5,0x2
    80006b62:	97ba                	add	a5,a5,a4
    80006b64:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006b68:	e7ad                	bnez	a5,80006bd2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006b6a:	00451793          	slli	a5,a0,0x4
    80006b6e:	00026717          	auipc	a4,0x26
    80006b72:	49270713          	addi	a4,a4,1170 # 8002d000 <disk+0x2000>
    80006b76:	6314                	ld	a3,0(a4)
    80006b78:	96be                	add	a3,a3,a5
    80006b7a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006b7e:	6314                	ld	a3,0(a4)
    80006b80:	96be                	add	a3,a3,a5
    80006b82:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006b86:	6314                	ld	a3,0(a4)
    80006b88:	96be                	add	a3,a3,a5
    80006b8a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80006b8e:	6318                	ld	a4,0(a4)
    80006b90:	97ba                	add	a5,a5,a4
    80006b92:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006b96:	00024797          	auipc	a5,0x24
    80006b9a:	46a78793          	addi	a5,a5,1130 # 8002b000 <disk>
    80006b9e:	97aa                	add	a5,a5,a0
    80006ba0:	6509                	lui	a0,0x2
    80006ba2:	953e                	add	a0,a0,a5
    80006ba4:	4785                	li	a5,1
    80006ba6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006baa:	00026517          	auipc	a0,0x26
    80006bae:	46e50513          	addi	a0,a0,1134 # 8002d018 <disk+0x2018>
    80006bb2:	ffffc097          	auipc	ra,0xffffc
    80006bb6:	fda080e7          	jalr	-38(ra) # 80002b8c <wakeup>
}
    80006bba:	60a2                	ld	ra,8(sp)
    80006bbc:	6402                	ld	s0,0(sp)
    80006bbe:	0141                	addi	sp,sp,16
    80006bc0:	8082                	ret
    panic("free_desc 1");
    80006bc2:	00003517          	auipc	a0,0x3
    80006bc6:	07650513          	addi	a0,a0,118 # 80009c38 <syscalls+0x3a8>
    80006bca:	ffffa097          	auipc	ra,0xffffa
    80006bce:	960080e7          	jalr	-1696(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006bd2:	00003517          	auipc	a0,0x3
    80006bd6:	07650513          	addi	a0,a0,118 # 80009c48 <syscalls+0x3b8>
    80006bda:	ffffa097          	auipc	ra,0xffffa
    80006bde:	950080e7          	jalr	-1712(ra) # 8000052a <panic>

0000000080006be2 <virtio_disk_init>:
{
    80006be2:	1101                	addi	sp,sp,-32
    80006be4:	ec06                	sd	ra,24(sp)
    80006be6:	e822                	sd	s0,16(sp)
    80006be8:	e426                	sd	s1,8(sp)
    80006bea:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006bec:	00003597          	auipc	a1,0x3
    80006bf0:	06c58593          	addi	a1,a1,108 # 80009c58 <syscalls+0x3c8>
    80006bf4:	00026517          	auipc	a0,0x26
    80006bf8:	53450513          	addi	a0,a0,1332 # 8002d128 <disk+0x2128>
    80006bfc:	ffffa097          	auipc	ra,0xffffa
    80006c00:	f36080e7          	jalr	-202(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006c04:	100017b7          	lui	a5,0x10001
    80006c08:	4398                	lw	a4,0(a5)
    80006c0a:	2701                	sext.w	a4,a4
    80006c0c:	747277b7          	lui	a5,0x74727
    80006c10:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006c14:	0ef71163          	bne	a4,a5,80006cf6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006c18:	100017b7          	lui	a5,0x10001
    80006c1c:	43dc                	lw	a5,4(a5)
    80006c1e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006c20:	4705                	li	a4,1
    80006c22:	0ce79a63          	bne	a5,a4,80006cf6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006c26:	100017b7          	lui	a5,0x10001
    80006c2a:	479c                	lw	a5,8(a5)
    80006c2c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006c2e:	4709                	li	a4,2
    80006c30:	0ce79363          	bne	a5,a4,80006cf6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006c34:	100017b7          	lui	a5,0x10001
    80006c38:	47d8                	lw	a4,12(a5)
    80006c3a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006c3c:	554d47b7          	lui	a5,0x554d4
    80006c40:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006c44:	0af71963          	bne	a4,a5,80006cf6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006c48:	100017b7          	lui	a5,0x10001
    80006c4c:	4705                	li	a4,1
    80006c4e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006c50:	470d                	li	a4,3
    80006c52:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006c54:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006c56:	c7ffe737          	lui	a4,0xc7ffe
    80006c5a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd075f>
    80006c5e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006c60:	2701                	sext.w	a4,a4
    80006c62:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006c64:	472d                	li	a4,11
    80006c66:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006c68:	473d                	li	a4,15
    80006c6a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006c6c:	6705                	lui	a4,0x1
    80006c6e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006c70:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006c74:	5bdc                	lw	a5,52(a5)
    80006c76:	2781                	sext.w	a5,a5
  if(max == 0)
    80006c78:	c7d9                	beqz	a5,80006d06 <virtio_disk_init+0x124>
  if(max < NUM)
    80006c7a:	471d                	li	a4,7
    80006c7c:	08f77d63          	bgeu	a4,a5,80006d16 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006c80:	100014b7          	lui	s1,0x10001
    80006c84:	47a1                	li	a5,8
    80006c86:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006c88:	6609                	lui	a2,0x2
    80006c8a:	4581                	li	a1,0
    80006c8c:	00024517          	auipc	a0,0x24
    80006c90:	37450513          	addi	a0,a0,884 # 8002b000 <disk>
    80006c94:	ffffa097          	auipc	ra,0xffffa
    80006c98:	02a080e7          	jalr	42(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006c9c:	00024717          	auipc	a4,0x24
    80006ca0:	36470713          	addi	a4,a4,868 # 8002b000 <disk>
    80006ca4:	00c75793          	srli	a5,a4,0xc
    80006ca8:	2781                	sext.w	a5,a5
    80006caa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006cac:	00026797          	auipc	a5,0x26
    80006cb0:	35478793          	addi	a5,a5,852 # 8002d000 <disk+0x2000>
    80006cb4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006cb6:	00024717          	auipc	a4,0x24
    80006cba:	3ca70713          	addi	a4,a4,970 # 8002b080 <disk+0x80>
    80006cbe:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006cc0:	00025717          	auipc	a4,0x25
    80006cc4:	34070713          	addi	a4,a4,832 # 8002c000 <disk+0x1000>
    80006cc8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006cca:	4705                	li	a4,1
    80006ccc:	00e78c23          	sb	a4,24(a5)
    80006cd0:	00e78ca3          	sb	a4,25(a5)
    80006cd4:	00e78d23          	sb	a4,26(a5)
    80006cd8:	00e78da3          	sb	a4,27(a5)
    80006cdc:	00e78e23          	sb	a4,28(a5)
    80006ce0:	00e78ea3          	sb	a4,29(a5)
    80006ce4:	00e78f23          	sb	a4,30(a5)
    80006ce8:	00e78fa3          	sb	a4,31(a5)
}
    80006cec:	60e2                	ld	ra,24(sp)
    80006cee:	6442                	ld	s0,16(sp)
    80006cf0:	64a2                	ld	s1,8(sp)
    80006cf2:	6105                	addi	sp,sp,32
    80006cf4:	8082                	ret
    panic("could not find virtio disk");
    80006cf6:	00003517          	auipc	a0,0x3
    80006cfa:	f7250513          	addi	a0,a0,-142 # 80009c68 <syscalls+0x3d8>
    80006cfe:	ffffa097          	auipc	ra,0xffffa
    80006d02:	82c080e7          	jalr	-2004(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006d06:	00003517          	auipc	a0,0x3
    80006d0a:	f8250513          	addi	a0,a0,-126 # 80009c88 <syscalls+0x3f8>
    80006d0e:	ffffa097          	auipc	ra,0xffffa
    80006d12:	81c080e7          	jalr	-2020(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006d16:	00003517          	auipc	a0,0x3
    80006d1a:	f9250513          	addi	a0,a0,-110 # 80009ca8 <syscalls+0x418>
    80006d1e:	ffffa097          	auipc	ra,0xffffa
    80006d22:	80c080e7          	jalr	-2036(ra) # 8000052a <panic>

0000000080006d26 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006d26:	7119                	addi	sp,sp,-128
    80006d28:	fc86                	sd	ra,120(sp)
    80006d2a:	f8a2                	sd	s0,112(sp)
    80006d2c:	f4a6                	sd	s1,104(sp)
    80006d2e:	f0ca                	sd	s2,96(sp)
    80006d30:	ecce                	sd	s3,88(sp)
    80006d32:	e8d2                	sd	s4,80(sp)
    80006d34:	e4d6                	sd	s5,72(sp)
    80006d36:	e0da                	sd	s6,64(sp)
    80006d38:	fc5e                	sd	s7,56(sp)
    80006d3a:	f862                	sd	s8,48(sp)
    80006d3c:	f466                	sd	s9,40(sp)
    80006d3e:	f06a                	sd	s10,32(sp)
    80006d40:	ec6e                	sd	s11,24(sp)
    80006d42:	0100                	addi	s0,sp,128
    80006d44:	8aaa                	mv	s5,a0
    80006d46:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006d48:	00c52c83          	lw	s9,12(a0)
    80006d4c:	001c9c9b          	slliw	s9,s9,0x1
    80006d50:	1c82                	slli	s9,s9,0x20
    80006d52:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006d56:	00026517          	auipc	a0,0x26
    80006d5a:	3d250513          	addi	a0,a0,978 # 8002d128 <disk+0x2128>
    80006d5e:	ffffa097          	auipc	ra,0xffffa
    80006d62:	e64080e7          	jalr	-412(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006d66:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006d68:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006d6a:	00024c17          	auipc	s8,0x24
    80006d6e:	296c0c13          	addi	s8,s8,662 # 8002b000 <disk>
    80006d72:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006d74:	4b0d                	li	s6,3
    80006d76:	a0ad                	j	80006de0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006d78:	00fc0733          	add	a4,s8,a5
    80006d7c:	975e                	add	a4,a4,s7
    80006d7e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006d82:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006d84:	0207c563          	bltz	a5,80006dae <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006d88:	2905                	addiw	s2,s2,1
    80006d8a:	0611                	addi	a2,a2,4
    80006d8c:	19690d63          	beq	s2,s6,80006f26 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006d90:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006d92:	00026717          	auipc	a4,0x26
    80006d96:	28670713          	addi	a4,a4,646 # 8002d018 <disk+0x2018>
    80006d9a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006d9c:	00074683          	lbu	a3,0(a4)
    80006da0:	fee1                	bnez	a3,80006d78 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006da2:	2785                	addiw	a5,a5,1
    80006da4:	0705                	addi	a4,a4,1
    80006da6:	fe979be3          	bne	a5,s1,80006d9c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006daa:	57fd                	li	a5,-1
    80006dac:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006dae:	01205d63          	blez	s2,80006dc8 <virtio_disk_rw+0xa2>
    80006db2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006db4:	000a2503          	lw	a0,0(s4)
    80006db8:	00000097          	auipc	ra,0x0
    80006dbc:	d8e080e7          	jalr	-626(ra) # 80006b46 <free_desc>
      for(int j = 0; j < i; j++)
    80006dc0:	2d85                	addiw	s11,s11,1
    80006dc2:	0a11                	addi	s4,s4,4
    80006dc4:	ffb918e3          	bne	s2,s11,80006db4 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006dc8:	00026597          	auipc	a1,0x26
    80006dcc:	36058593          	addi	a1,a1,864 # 8002d128 <disk+0x2128>
    80006dd0:	00026517          	auipc	a0,0x26
    80006dd4:	24850513          	addi	a0,a0,584 # 8002d018 <disk+0x2018>
    80006dd8:	ffffc097          	auipc	ra,0xffffc
    80006ddc:	c28080e7          	jalr	-984(ra) # 80002a00 <sleep>
  for(int i = 0; i < 3; i++){
    80006de0:	f8040a13          	addi	s4,s0,-128
{
    80006de4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006de6:	894e                	mv	s2,s3
    80006de8:	b765                	j	80006d90 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006dea:	00026697          	auipc	a3,0x26
    80006dee:	2166b683          	ld	a3,534(a3) # 8002d000 <disk+0x2000>
    80006df2:	96ba                	add	a3,a3,a4
    80006df4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006df8:	00024817          	auipc	a6,0x24
    80006dfc:	20880813          	addi	a6,a6,520 # 8002b000 <disk>
    80006e00:	00026697          	auipc	a3,0x26
    80006e04:	20068693          	addi	a3,a3,512 # 8002d000 <disk+0x2000>
    80006e08:	6290                	ld	a2,0(a3)
    80006e0a:	963a                	add	a2,a2,a4
    80006e0c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006e10:	0015e593          	ori	a1,a1,1
    80006e14:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006e18:	f8842603          	lw	a2,-120(s0)
    80006e1c:	628c                	ld	a1,0(a3)
    80006e1e:	972e                	add	a4,a4,a1
    80006e20:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006e24:	20050593          	addi	a1,a0,512
    80006e28:	0592                	slli	a1,a1,0x4
    80006e2a:	95c2                	add	a1,a1,a6
    80006e2c:	577d                	li	a4,-1
    80006e2e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006e32:	00461713          	slli	a4,a2,0x4
    80006e36:	6290                	ld	a2,0(a3)
    80006e38:	963a                	add	a2,a2,a4
    80006e3a:	03078793          	addi	a5,a5,48
    80006e3e:	97c2                	add	a5,a5,a6
    80006e40:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006e42:	629c                	ld	a5,0(a3)
    80006e44:	97ba                	add	a5,a5,a4
    80006e46:	4605                	li	a2,1
    80006e48:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006e4a:	629c                	ld	a5,0(a3)
    80006e4c:	97ba                	add	a5,a5,a4
    80006e4e:	4809                	li	a6,2
    80006e50:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006e54:	629c                	ld	a5,0(a3)
    80006e56:	973e                	add	a4,a4,a5
    80006e58:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006e5c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006e60:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006e64:	6698                	ld	a4,8(a3)
    80006e66:	00275783          	lhu	a5,2(a4)
    80006e6a:	8b9d                	andi	a5,a5,7
    80006e6c:	0786                	slli	a5,a5,0x1
    80006e6e:	97ba                	add	a5,a5,a4
    80006e70:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006e74:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006e78:	6698                	ld	a4,8(a3)
    80006e7a:	00275783          	lhu	a5,2(a4)
    80006e7e:	2785                	addiw	a5,a5,1
    80006e80:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006e84:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006e88:	100017b7          	lui	a5,0x10001
    80006e8c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006e90:	004aa783          	lw	a5,4(s5)
    80006e94:	02c79163          	bne	a5,a2,80006eb6 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006e98:	00026917          	auipc	s2,0x26
    80006e9c:	29090913          	addi	s2,s2,656 # 8002d128 <disk+0x2128>
  while(b->disk == 1) {
    80006ea0:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006ea2:	85ca                	mv	a1,s2
    80006ea4:	8556                	mv	a0,s5
    80006ea6:	ffffc097          	auipc	ra,0xffffc
    80006eaa:	b5a080e7          	jalr	-1190(ra) # 80002a00 <sleep>
  while(b->disk == 1) {
    80006eae:	004aa783          	lw	a5,4(s5)
    80006eb2:	fe9788e3          	beq	a5,s1,80006ea2 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006eb6:	f8042903          	lw	s2,-128(s0)
    80006eba:	20090793          	addi	a5,s2,512
    80006ebe:	00479713          	slli	a4,a5,0x4
    80006ec2:	00024797          	auipc	a5,0x24
    80006ec6:	13e78793          	addi	a5,a5,318 # 8002b000 <disk>
    80006eca:	97ba                	add	a5,a5,a4
    80006ecc:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006ed0:	00026997          	auipc	s3,0x26
    80006ed4:	13098993          	addi	s3,s3,304 # 8002d000 <disk+0x2000>
    80006ed8:	00491713          	slli	a4,s2,0x4
    80006edc:	0009b783          	ld	a5,0(s3)
    80006ee0:	97ba                	add	a5,a5,a4
    80006ee2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006ee6:	854a                	mv	a0,s2
    80006ee8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006eec:	00000097          	auipc	ra,0x0
    80006ef0:	c5a080e7          	jalr	-934(ra) # 80006b46 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006ef4:	8885                	andi	s1,s1,1
    80006ef6:	f0ed                	bnez	s1,80006ed8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006ef8:	00026517          	auipc	a0,0x26
    80006efc:	23050513          	addi	a0,a0,560 # 8002d128 <disk+0x2128>
    80006f00:	ffffa097          	auipc	ra,0xffffa
    80006f04:	d76080e7          	jalr	-650(ra) # 80000c76 <release>
}
    80006f08:	70e6                	ld	ra,120(sp)
    80006f0a:	7446                	ld	s0,112(sp)
    80006f0c:	74a6                	ld	s1,104(sp)
    80006f0e:	7906                	ld	s2,96(sp)
    80006f10:	69e6                	ld	s3,88(sp)
    80006f12:	6a46                	ld	s4,80(sp)
    80006f14:	6aa6                	ld	s5,72(sp)
    80006f16:	6b06                	ld	s6,64(sp)
    80006f18:	7be2                	ld	s7,56(sp)
    80006f1a:	7c42                	ld	s8,48(sp)
    80006f1c:	7ca2                	ld	s9,40(sp)
    80006f1e:	7d02                	ld	s10,32(sp)
    80006f20:	6de2                	ld	s11,24(sp)
    80006f22:	6109                	addi	sp,sp,128
    80006f24:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006f26:	f8042503          	lw	a0,-128(s0)
    80006f2a:	20050793          	addi	a5,a0,512
    80006f2e:	0792                	slli	a5,a5,0x4
  if(write)
    80006f30:	00024817          	auipc	a6,0x24
    80006f34:	0d080813          	addi	a6,a6,208 # 8002b000 <disk>
    80006f38:	00f80733          	add	a4,a6,a5
    80006f3c:	01a036b3          	snez	a3,s10
    80006f40:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006f44:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006f48:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006f4c:	7679                	lui	a2,0xffffe
    80006f4e:	963e                	add	a2,a2,a5
    80006f50:	00026697          	auipc	a3,0x26
    80006f54:	0b068693          	addi	a3,a3,176 # 8002d000 <disk+0x2000>
    80006f58:	6298                	ld	a4,0(a3)
    80006f5a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006f5c:	0a878593          	addi	a1,a5,168
    80006f60:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006f62:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006f64:	6298                	ld	a4,0(a3)
    80006f66:	9732                	add	a4,a4,a2
    80006f68:	45c1                	li	a1,16
    80006f6a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006f6c:	6298                	ld	a4,0(a3)
    80006f6e:	9732                	add	a4,a4,a2
    80006f70:	4585                	li	a1,1
    80006f72:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006f76:	f8442703          	lw	a4,-124(s0)
    80006f7a:	628c                	ld	a1,0(a3)
    80006f7c:	962e                	add	a2,a2,a1
    80006f7e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd000e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006f82:	0712                	slli	a4,a4,0x4
    80006f84:	6290                	ld	a2,0(a3)
    80006f86:	963a                	add	a2,a2,a4
    80006f88:	058a8593          	addi	a1,s5,88
    80006f8c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006f8e:	6294                	ld	a3,0(a3)
    80006f90:	96ba                	add	a3,a3,a4
    80006f92:	40000613          	li	a2,1024
    80006f96:	c690                	sw	a2,8(a3)
  if(write)
    80006f98:	e40d19e3          	bnez	s10,80006dea <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006f9c:	00026697          	auipc	a3,0x26
    80006fa0:	0646b683          	ld	a3,100(a3) # 8002d000 <disk+0x2000>
    80006fa4:	96ba                	add	a3,a3,a4
    80006fa6:	4609                	li	a2,2
    80006fa8:	00c69623          	sh	a2,12(a3)
    80006fac:	b5b1                	j	80006df8 <virtio_disk_rw+0xd2>

0000000080006fae <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006fae:	1101                	addi	sp,sp,-32
    80006fb0:	ec06                	sd	ra,24(sp)
    80006fb2:	e822                	sd	s0,16(sp)
    80006fb4:	e426                	sd	s1,8(sp)
    80006fb6:	e04a                	sd	s2,0(sp)
    80006fb8:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006fba:	00026517          	auipc	a0,0x26
    80006fbe:	16e50513          	addi	a0,a0,366 # 8002d128 <disk+0x2128>
    80006fc2:	ffffa097          	auipc	ra,0xffffa
    80006fc6:	c00080e7          	jalr	-1024(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006fca:	10001737          	lui	a4,0x10001
    80006fce:	533c                	lw	a5,96(a4)
    80006fd0:	8b8d                	andi	a5,a5,3
    80006fd2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006fd4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006fd8:	00026797          	auipc	a5,0x26
    80006fdc:	02878793          	addi	a5,a5,40 # 8002d000 <disk+0x2000>
    80006fe0:	6b94                	ld	a3,16(a5)
    80006fe2:	0207d703          	lhu	a4,32(a5)
    80006fe6:	0026d783          	lhu	a5,2(a3)
    80006fea:	06f70163          	beq	a4,a5,8000704c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006fee:	00024917          	auipc	s2,0x24
    80006ff2:	01290913          	addi	s2,s2,18 # 8002b000 <disk>
    80006ff6:	00026497          	auipc	s1,0x26
    80006ffa:	00a48493          	addi	s1,s1,10 # 8002d000 <disk+0x2000>
    __sync_synchronize();
    80006ffe:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80007002:	6898                	ld	a4,16(s1)
    80007004:	0204d783          	lhu	a5,32(s1)
    80007008:	8b9d                	andi	a5,a5,7
    8000700a:	078e                	slli	a5,a5,0x3
    8000700c:	97ba                	add	a5,a5,a4
    8000700e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80007010:	20078713          	addi	a4,a5,512
    80007014:	0712                	slli	a4,a4,0x4
    80007016:	974a                	add	a4,a4,s2
    80007018:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000701c:	e731                	bnez	a4,80007068 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000701e:	20078793          	addi	a5,a5,512
    80007022:	0792                	slli	a5,a5,0x4
    80007024:	97ca                	add	a5,a5,s2
    80007026:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80007028:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000702c:	ffffc097          	auipc	ra,0xffffc
    80007030:	b60080e7          	jalr	-1184(ra) # 80002b8c <wakeup>

    disk.used_idx += 1;
    80007034:	0204d783          	lhu	a5,32(s1)
    80007038:	2785                	addiw	a5,a5,1
    8000703a:	17c2                	slli	a5,a5,0x30
    8000703c:	93c1                	srli	a5,a5,0x30
    8000703e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80007042:	6898                	ld	a4,16(s1)
    80007044:	00275703          	lhu	a4,2(a4)
    80007048:	faf71be3          	bne	a4,a5,80006ffe <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000704c:	00026517          	auipc	a0,0x26
    80007050:	0dc50513          	addi	a0,a0,220 # 8002d128 <disk+0x2128>
    80007054:	ffffa097          	auipc	ra,0xffffa
    80007058:	c22080e7          	jalr	-990(ra) # 80000c76 <release>
}
    8000705c:	60e2                	ld	ra,24(sp)
    8000705e:	6442                	ld	s0,16(sp)
    80007060:	64a2                	ld	s1,8(sp)
    80007062:	6902                	ld	s2,0(sp)
    80007064:	6105                	addi	sp,sp,32
    80007066:	8082                	ret
      panic("virtio_disk_intr status");
    80007068:	00003517          	auipc	a0,0x3
    8000706c:	c6050513          	addi	a0,a0,-928 # 80009cc8 <syscalls+0x438>
    80007070:	ffff9097          	auipc	ra,0xffff9
    80007074:	4ba080e7          	jalr	1210(ra) # 8000052a <panic>
	...

0000000080008000 <_trampoline>:
    80008000:	14051573          	csrrw	a0,sscratch,a0
    80008004:	02153423          	sd	ra,40(a0)
    80008008:	02253823          	sd	sp,48(a0)
    8000800c:	02353c23          	sd	gp,56(a0)
    80008010:	04453023          	sd	tp,64(a0)
    80008014:	04553423          	sd	t0,72(a0)
    80008018:	04653823          	sd	t1,80(a0)
    8000801c:	04753c23          	sd	t2,88(a0)
    80008020:	f120                	sd	s0,96(a0)
    80008022:	f524                	sd	s1,104(a0)
    80008024:	fd2c                	sd	a1,120(a0)
    80008026:	e150                	sd	a2,128(a0)
    80008028:	e554                	sd	a3,136(a0)
    8000802a:	e958                	sd	a4,144(a0)
    8000802c:	ed5c                	sd	a5,152(a0)
    8000802e:	0b053023          	sd	a6,160(a0)
    80008032:	0b153423          	sd	a7,168(a0)
    80008036:	0b253823          	sd	s2,176(a0)
    8000803a:	0b353c23          	sd	s3,184(a0)
    8000803e:	0d453023          	sd	s4,192(a0)
    80008042:	0d553423          	sd	s5,200(a0)
    80008046:	0d653823          	sd	s6,208(a0)
    8000804a:	0d753c23          	sd	s7,216(a0)
    8000804e:	0f853023          	sd	s8,224(a0)
    80008052:	0f953423          	sd	s9,232(a0)
    80008056:	0fa53823          	sd	s10,240(a0)
    8000805a:	0fb53c23          	sd	s11,248(a0)
    8000805e:	11c53023          	sd	t3,256(a0)
    80008062:	11d53423          	sd	t4,264(a0)
    80008066:	11e53823          	sd	t5,272(a0)
    8000806a:	11f53c23          	sd	t6,280(a0)
    8000806e:	140022f3          	csrr	t0,sscratch
    80008072:	06553823          	sd	t0,112(a0)
    80008076:	00853103          	ld	sp,8(a0)
    8000807a:	02053203          	ld	tp,32(a0)
    8000807e:	01053283          	ld	t0,16(a0)
    80008082:	00053303          	ld	t1,0(a0)
    80008086:	18031073          	csrw	satp,t1
    8000808a:	12000073          	sfence.vma
    8000808e:	8282                	jr	t0

0000000080008090 <userret>:
    80008090:	18059073          	csrw	satp,a1
    80008094:	12000073          	sfence.vma
    80008098:	07053283          	ld	t0,112(a0)
    8000809c:	14029073          	csrw	sscratch,t0
    800080a0:	02853083          	ld	ra,40(a0)
    800080a4:	03053103          	ld	sp,48(a0)
    800080a8:	03853183          	ld	gp,56(a0)
    800080ac:	04053203          	ld	tp,64(a0)
    800080b0:	04853283          	ld	t0,72(a0)
    800080b4:	05053303          	ld	t1,80(a0)
    800080b8:	05853383          	ld	t2,88(a0)
    800080bc:	7120                	ld	s0,96(a0)
    800080be:	7524                	ld	s1,104(a0)
    800080c0:	7d2c                	ld	a1,120(a0)
    800080c2:	6150                	ld	a2,128(a0)
    800080c4:	6554                	ld	a3,136(a0)
    800080c6:	6958                	ld	a4,144(a0)
    800080c8:	6d5c                	ld	a5,152(a0)
    800080ca:	0a053803          	ld	a6,160(a0)
    800080ce:	0a853883          	ld	a7,168(a0)
    800080d2:	0b053903          	ld	s2,176(a0)
    800080d6:	0b853983          	ld	s3,184(a0)
    800080da:	0c053a03          	ld	s4,192(a0)
    800080de:	0c853a83          	ld	s5,200(a0)
    800080e2:	0d053b03          	ld	s6,208(a0)
    800080e6:	0d853b83          	ld	s7,216(a0)
    800080ea:	0e053c03          	ld	s8,224(a0)
    800080ee:	0e853c83          	ld	s9,232(a0)
    800080f2:	0f053d03          	ld	s10,240(a0)
    800080f6:	0f853d83          	ld	s11,248(a0)
    800080fa:	10053e03          	ld	t3,256(a0)
    800080fe:	10853e83          	ld	t4,264(a0)
    80008102:	11053f03          	ld	t5,272(a0)
    80008106:	11853f83          	ld	t6,280(a0)
    8000810a:	14051573          	csrrw	a0,sscratch,a0
    8000810e:	10200073          	sret
	...
