
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
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
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
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
    80000064:	00006797          	auipc	a5,0x6
    80000068:	2dc78793          	addi	a5,a5,732 # 80006340 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd37ff>
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
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	60a080e7          	jalr	1546(ra) # 80002728 <either_copyin>
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
    8000017c:	00011517          	auipc	a0,0x11
    80000180:	00450513          	addi	a0,a0,4 # 80011180 <cons>
    80000184:	00001097          	auipc	ra,0x1
    80000188:	a3e080e7          	jalr	-1474(ra) # 80000bc2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018c:	00011497          	auipc	s1,0x11
    80000190:	ff448493          	addi	s1,s1,-12 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000194:	00011917          	auipc	s2,0x11
    80000198:	08490913          	addi	s2,s2,132 # 80011218 <cons+0x98>
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
    800001b6:	9ca080e7          	jalr	-1590(ra) # 80001b7c <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	16c080e7          	jalr	364(ra) # 8000232e <sleep>
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
    800001fe:	00002097          	auipc	ra,0x2
    80000202:	4d4080e7          	jalr	1236(ra) # 800026d2 <either_copyout>
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
    80000212:	00011517          	auipc	a0,0x11
    80000216:	f6e50513          	addi	a0,a0,-146 # 80011180 <cons>
    8000021a:	00001097          	auipc	ra,0x1
    8000021e:	a5c080e7          	jalr	-1444(ra) # 80000c76 <release>

  return target - n;
    80000222:	413b053b          	subw	a0,s6,s3
    80000226:	a811                	j	8000023a <consoleread+0xe4>
        release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	f5850513          	addi	a0,a0,-168 # 80011180 <cons>
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
    8000025e:	00011717          	auipc	a4,0x11
    80000262:	faf72d23          	sw	a5,-70(a4) # 80011218 <cons+0x98>
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
    800002b8:	00011517          	auipc	a0,0x11
    800002bc:	ec850513          	addi	a0,a0,-312 # 80011180 <cons>
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
    800002de:	00002097          	auipc	ra,0x2
    800002e2:	4a0080e7          	jalr	1184(ra) # 8000277e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002e6:	00011517          	auipc	a0,0x11
    800002ea:	e9a50513          	addi	a0,a0,-358 # 80011180 <cons>
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
    8000030a:	00011717          	auipc	a4,0x11
    8000030e:	e7670713          	addi	a4,a4,-394 # 80011180 <cons>
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
    80000334:	00011797          	auipc	a5,0x11
    80000338:	e4c78793          	addi	a5,a5,-436 # 80011180 <cons>
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
    80000362:	00011797          	auipc	a5,0x11
    80000366:	eb67a783          	lw	a5,-330(a5) # 80011218 <cons+0x98>
    8000036a:	0807879b          	addiw	a5,a5,128
    8000036e:	f6f61ce3          	bne	a2,a5,800002e6 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000372:	863e                	mv	a2,a5
    80000374:	a07d                	j	80000422 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000376:	00011717          	auipc	a4,0x11
    8000037a:	e0a70713          	addi	a4,a4,-502 # 80011180 <cons>
    8000037e:	0a072783          	lw	a5,160(a4)
    80000382:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000386:	00011497          	auipc	s1,0x11
    8000038a:	dfa48493          	addi	s1,s1,-518 # 80011180 <cons>
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
    800003c2:	00011717          	auipc	a4,0x11
    800003c6:	dbe70713          	addi	a4,a4,-578 # 80011180 <cons>
    800003ca:	0a072783          	lw	a5,160(a4)
    800003ce:	09c72703          	lw	a4,156(a4)
    800003d2:	f0f70ae3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003d6:	37fd                	addiw	a5,a5,-1
    800003d8:	00011717          	auipc	a4,0x11
    800003dc:	e4f72423          	sw	a5,-440(a4) # 80011220 <cons+0xa0>
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
    800003fe:	00011797          	auipc	a5,0x11
    80000402:	d8278793          	addi	a5,a5,-638 # 80011180 <cons>
    80000406:	0a07a703          	lw	a4,160(a5)
    8000040a:	0017069b          	addiw	a3,a4,1
    8000040e:	0006861b          	sext.w	a2,a3
    80000412:	0ad7a023          	sw	a3,160(a5)
    80000416:	07f77713          	andi	a4,a4,127
    8000041a:	97ba                	add	a5,a5,a4
    8000041c:	4729                	li	a4,10
    8000041e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000422:	00011797          	auipc	a5,0x11
    80000426:	dec7ad23          	sw	a2,-518(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000042a:	00011517          	auipc	a0,0x11
    8000042e:	dee50513          	addi	a0,a0,-530 # 80011218 <cons+0x98>
    80000432:	00002097          	auipc	ra,0x2
    80000436:	088080e7          	jalr	136(ra) # 800024ba <wakeup>
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
    80000444:	00008597          	auipc	a1,0x8
    80000448:	bcc58593          	addi	a1,a1,-1076 # 80008010 <etext+0x10>
    8000044c:	00011517          	auipc	a0,0x11
    80000450:	d3450513          	addi	a0,a0,-716 # 80011180 <cons>
    80000454:	00000097          	auipc	ra,0x0
    80000458:	6de080e7          	jalr	1758(ra) # 80000b32 <initlock>

  uartinit();
    8000045c:	00000097          	auipc	ra,0x0
    80000460:	32a080e7          	jalr	810(ra) # 80000786 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000464:	00026797          	auipc	a5,0x26
    80000468:	4b478793          	addi	a5,a5,1204 # 80026918 <devsw>
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
    800004a6:	00008617          	auipc	a2,0x8
    800004aa:	b9a60613          	addi	a2,a2,-1126 # 80008040 <digits>
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
    80000536:	00011797          	auipc	a5,0x11
    8000053a:	d007a523          	sw	zero,-758(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000053e:	00008517          	auipc	a0,0x8
    80000542:	ada50513          	addi	a0,a0,-1318 # 80008018 <etext+0x18>
    80000546:	00000097          	auipc	ra,0x0
    8000054a:	02e080e7          	jalr	46(ra) # 80000574 <printf>
  printf(s);
    8000054e:	8526                	mv	a0,s1
    80000550:	00000097          	auipc	ra,0x0
    80000554:	024080e7          	jalr	36(ra) # 80000574 <printf>
  printf("\n");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	b7050513          	addi	a0,a0,-1168 # 800080c8 <digits+0x88>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	014080e7          	jalr	20(ra) # 80000574 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000568:	4785                	li	a5,1
    8000056a:	00009717          	auipc	a4,0x9
    8000056e:	a8f72b23          	sw	a5,-1386(a4) # 80009000 <panicked>
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
    800005a6:	00011d97          	auipc	s11,0x11
    800005aa:	c9adad83          	lw	s11,-870(s11) # 80011240 <pr+0x18>
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
    800005d2:	00008b17          	auipc	s6,0x8
    800005d6:	a6eb0b13          	addi	s6,s6,-1426 # 80008040 <digits>
    switch(c){
    800005da:	07300c93          	li	s9,115
    800005de:	06400c13          	li	s8,100
    800005e2:	a82d                	j	8000061c <printf+0xa8>
    acquire(&pr.lock);
    800005e4:	00011517          	auipc	a0,0x11
    800005e8:	c4450513          	addi	a0,a0,-956 # 80011228 <pr>
    800005ec:	00000097          	auipc	ra,0x0
    800005f0:	5d6080e7          	jalr	1494(ra) # 80000bc2 <acquire>
    800005f4:	bf7d                	j	800005b2 <printf+0x3e>
    panic("null fmt");
    800005f6:	00008517          	auipc	a0,0x8
    800005fa:	a3250513          	addi	a0,a0,-1486 # 80008028 <etext+0x28>
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
    800006f0:	00008497          	auipc	s1,0x8
    800006f4:	93048493          	addi	s1,s1,-1744 # 80008020 <etext+0x20>
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
    80000742:	00011517          	auipc	a0,0x11
    80000746:	ae650513          	addi	a0,a0,-1306 # 80011228 <pr>
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
    8000075e:	00011497          	auipc	s1,0x11
    80000762:	aca48493          	addi	s1,s1,-1334 # 80011228 <pr>
    80000766:	00008597          	auipc	a1,0x8
    8000076a:	8d258593          	addi	a1,a1,-1838 # 80008038 <etext+0x38>
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
    800007b6:	00008597          	auipc	a1,0x8
    800007ba:	8a258593          	addi	a1,a1,-1886 # 80008058 <digits+0x18>
    800007be:	00011517          	auipc	a0,0x11
    800007c2:	a8a50513          	addi	a0,a0,-1398 # 80011248 <uart_tx_lock>
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
    800007ea:	00009797          	auipc	a5,0x9
    800007ee:	8167a783          	lw	a5,-2026(a5) # 80009000 <panicked>
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
    80000822:	00008797          	auipc	a5,0x8
    80000826:	7e67b783          	ld	a5,2022(a5) # 80009008 <uart_tx_r>
    8000082a:	00008717          	auipc	a4,0x8
    8000082e:	7e673703          	ld	a4,2022(a4) # 80009010 <uart_tx_w>
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
    8000084c:	00011a17          	auipc	s4,0x11
    80000850:	9fca0a13          	addi	s4,s4,-1540 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000854:	00008497          	auipc	s1,0x8
    80000858:	7b448493          	addi	s1,s1,1972 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000085c:	00008997          	auipc	s3,0x8
    80000860:	7b498993          	addi	s3,s3,1972 # 80009010 <uart_tx_w>
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
    80000882:	c3c080e7          	jalr	-964(ra) # 800024ba <wakeup>
    
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
    800008ba:	00011517          	auipc	a0,0x11
    800008be:	98e50513          	addi	a0,a0,-1650 # 80011248 <uart_tx_lock>
    800008c2:	00000097          	auipc	ra,0x0
    800008c6:	300080e7          	jalr	768(ra) # 80000bc2 <acquire>
  if(panicked){
    800008ca:	00008797          	auipc	a5,0x8
    800008ce:	7367a783          	lw	a5,1846(a5) # 80009000 <panicked>
    800008d2:	c391                	beqz	a5,800008d6 <uartputc+0x2e>
    for(;;)
    800008d4:	a001                	j	800008d4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008d6:	00008717          	auipc	a4,0x8
    800008da:	73a73703          	ld	a4,1850(a4) # 80009010 <uart_tx_w>
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	72a7b783          	ld	a5,1834(a5) # 80009008 <uart_tx_r>
    800008e6:	02078793          	addi	a5,a5,32
    800008ea:	02e79b63          	bne	a5,a4,80000920 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008ee:	00011997          	auipc	s3,0x11
    800008f2:	95a98993          	addi	s3,s3,-1702 # 80011248 <uart_tx_lock>
    800008f6:	00008497          	auipc	s1,0x8
    800008fa:	71248493          	addi	s1,s1,1810 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fe:	00008917          	auipc	s2,0x8
    80000902:	71290913          	addi	s2,s2,1810 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000906:	85ce                	mv	a1,s3
    80000908:	8526                	mv	a0,s1
    8000090a:	00002097          	auipc	ra,0x2
    8000090e:	a24080e7          	jalr	-1500(ra) # 8000232e <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00093703          	ld	a4,0(s2)
    80000916:	609c                	ld	a5,0(s1)
    80000918:	02078793          	addi	a5,a5,32
    8000091c:	fee785e3          	beq	a5,a4,80000906 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000920:	00011497          	auipc	s1,0x11
    80000924:	92848493          	addi	s1,s1,-1752 # 80011248 <uart_tx_lock>
    80000928:	01f77793          	andi	a5,a4,31
    8000092c:	97a6                	add	a5,a5,s1
    8000092e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000932:	0705                	addi	a4,a4,1
    80000934:	00008797          	auipc	a5,0x8
    80000938:	6ce7be23          	sd	a4,1756(a5) # 80009010 <uart_tx_w>
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
    800009a8:	00011497          	auipc	s1,0x11
    800009ac:	8a048493          	addi	s1,s1,-1888 # 80011248 <uart_tx_lock>
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
    800009ea:	0002a797          	auipc	a5,0x2a
    800009ee:	61678793          	addi	a5,a5,1558 # 8002b000 <end>
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
    80000a0a:	00011917          	auipc	s2,0x11
    80000a0e:	87690913          	addi	s2,s2,-1930 # 80011280 <kmem>
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
    80000a3c:	00007517          	auipc	a0,0x7
    80000a40:	62450513          	addi	a0,a0,1572 # 80008060 <digits+0x20>
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
    80000a9e:	00007597          	auipc	a1,0x7
    80000aa2:	5ca58593          	addi	a1,a1,1482 # 80008068 <digits+0x28>
    80000aa6:	00010517          	auipc	a0,0x10
    80000aaa:	7da50513          	addi	a0,a0,2010 # 80011280 <kmem>
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	084080e7          	jalr	132(ra) # 80000b32 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ab6:	45c5                	li	a1,17
    80000ab8:	05ee                	slli	a1,a1,0x1b
    80000aba:	0002a517          	auipc	a0,0x2a
    80000abe:	54650513          	addi	a0,a0,1350 # 8002b000 <end>
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
    80000adc:	00010497          	auipc	s1,0x10
    80000ae0:	7a448493          	addi	s1,s1,1956 # 80011280 <kmem>
    80000ae4:	8526                	mv	a0,s1
    80000ae6:	00000097          	auipc	ra,0x0
    80000aea:	0dc080e7          	jalr	220(ra) # 80000bc2 <acquire>
  r = kmem.freelist;
    80000aee:	6c84                	ld	s1,24(s1)
  if(r)
    80000af0:	c885                	beqz	s1,80000b20 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000af2:	609c                	ld	a5,0(s1)
    80000af4:	00010517          	auipc	a0,0x10
    80000af8:	78c50513          	addi	a0,a0,1932 # 80011280 <kmem>
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
    80000b20:	00010517          	auipc	a0,0x10
    80000b24:	76050513          	addi	a0,a0,1888 # 80011280 <kmem>
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
    80000b60:	004080e7          	jalr	4(ra) # 80001b60 <mycpu>
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
    80000b92:	fd2080e7          	jalr	-46(ra) # 80001b60 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	fc6080e7          	jalr	-58(ra) # 80001b60 <mycpu>
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
    80000bb6:	fae080e7          	jalr	-82(ra) # 80001b60 <mycpu>
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
    80000bf6:	f6e080e7          	jalr	-146(ra) # 80001b60 <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire");
    80000c06:	00007517          	auipc	a0,0x7
    80000c0a:	46a50513          	addi	a0,a0,1130 # 80008070 <digits+0x30>
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
    80000c22:	f42080e7          	jalr	-190(ra) # 80001b60 <mycpu>
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
    80000c56:	00007517          	auipc	a0,0x7
    80000c5a:	42250513          	addi	a0,a0,1058 # 80008078 <digits+0x38>
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	8cc080e7          	jalr	-1844(ra) # 8000052a <panic>
    panic("pop_off");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	42a50513          	addi	a0,a0,1066 # 80008090 <digits+0x50>
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
    80000cae:	00007517          	auipc	a0,0x7
    80000cb2:	3ea50513          	addi	a0,a0,1002 # 80008098 <digits+0x58>
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
    80000e78:	cdc080e7          	jalr	-804(ra) # 80001b50 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e7c:	00008717          	auipc	a4,0x8
    80000e80:	19c70713          	addi	a4,a4,412 # 80009018 <started>
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
    80000e94:	cc0080e7          	jalr	-832(ra) # 80001b50 <cpuid>
    80000e98:	85aa                	mv	a1,a0
    80000e9a:	00007517          	auipc	a0,0x7
    80000e9e:	21e50513          	addi	a0,a0,542 # 800080b8 <digits+0x78>
    80000ea2:	fffff097          	auipc	ra,0xfffff
    80000ea6:	6d2080e7          	jalr	1746(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000eaa:	00000097          	auipc	ra,0x0
    80000eae:	0d8080e7          	jalr	216(ra) # 80000f82 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb2:	00002097          	auipc	ra,0x2
    80000eb6:	a0e080e7          	jalr	-1522(ra) # 800028c0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	4c6080e7          	jalr	1222(ra) # 80006380 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	2ba080e7          	jalr	698(ra) # 8000217c <scheduler>
    consoleinit();
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	572080e7          	jalr	1394(ra) # 8000043c <consoleinit>
    printfinit();
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	882080e7          	jalr	-1918(ra) # 80000754 <printfinit>
    printf("\n");
    80000eda:	00007517          	auipc	a0,0x7
    80000ede:	1ee50513          	addi	a0,a0,494 # 800080c8 <digits+0x88>
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	692080e7          	jalr	1682(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000eea:	00007517          	auipc	a0,0x7
    80000eee:	1b650513          	addi	a0,a0,438 # 800080a0 <digits+0x60>
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	682080e7          	jalr	1666(ra) # 80000574 <printf>
    printf("\n");
    80000efa:	00007517          	auipc	a0,0x7
    80000efe:	1ce50513          	addi	a0,a0,462 # 800080c8 <digits+0x88>
    80000f02:	fffff097          	auipc	ra,0xfffff
    80000f06:	672080e7          	jalr	1650(ra) # 80000574 <printf>
    kinit();         // physical page allocator
    80000f0a:	00000097          	auipc	ra,0x0
    80000f0e:	b8c080e7          	jalr	-1140(ra) # 80000a96 <kinit>
    kvminit();       // create kernel page table
    80000f12:	00000097          	auipc	ra,0x0
    80000f16:	310080e7          	jalr	784(ra) # 80001222 <kvminit>
    kvminithart();   // turn on paging
    80000f1a:	00000097          	auipc	ra,0x0
    80000f1e:	068080e7          	jalr	104(ra) # 80000f82 <kvminithart>
    procinit();      // process table
    80000f22:	00001097          	auipc	ra,0x1
    80000f26:	b7e080e7          	jalr	-1154(ra) # 80001aa0 <procinit>
    trapinit();      // trap vectors
    80000f2a:	00002097          	auipc	ra,0x2
    80000f2e:	96e080e7          	jalr	-1682(ra) # 80002898 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	98e080e7          	jalr	-1650(ra) # 800028c0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	430080e7          	jalr	1072(ra) # 8000636a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	43e080e7          	jalr	1086(ra) # 80006380 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	0e6080e7          	jalr	230(ra) # 80003030 <binit>
    iinit();         // inode cache
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	778080e7          	jalr	1912(ra) # 800036ca <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	a38080e7          	jalr	-1480(ra) # 80004992 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	540080e7          	jalr	1344(ra) # 800064a2 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	f28080e7          	jalr	-216(ra) # 80001e92 <userinit>
    __sync_synchronize();
    80000f72:	0ff0000f          	fence
    started = 1;
    80000f76:	4785                	li	a5,1
    80000f78:	00008717          	auipc	a4,0x8
    80000f7c:	0af72023          	sw	a5,160(a4) # 80009018 <started>
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
    80000f88:	00008797          	auipc	a5,0x8
    80000f8c:	0987b783          	ld	a5,152(a5) # 80009020 <kernel_pagetable>
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
    80000fcc:	00007517          	auipc	a0,0x7
    80000fd0:	10450513          	addi	a0,a0,260 # 800080d0 <digits+0x90>
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
    800010a2:	0880                	addi	s0,sp,80
    800010a4:	8aaa                	mv	s5,a0
    800010a6:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010a8:	777d                	lui	a4,0xfffff
    800010aa:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010ae:	167d                	addi	a2,a2,-1
    800010b0:	00b609b3          	add	s3,a2,a1
    800010b4:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010b8:	893e                	mv	s2,a5
    800010ba:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010be:	6b85                	lui	s7,0x1
    800010c0:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010c4:	4605                	li	a2,1
    800010c6:	85ca                	mv	a1,s2
    800010c8:	8556                	mv	a0,s5
    800010ca:	00000097          	auipc	ra,0x0
    800010ce:	edc080e7          	jalr	-292(ra) # 80000fa6 <walk>
    800010d2:	c51d                	beqz	a0,80001100 <mappages+0x72>
    if(*pte & PTE_V)
    800010d4:	611c                	ld	a5,0(a0)
    800010d6:	8b85                	andi	a5,a5,1
    800010d8:	ef81                	bnez	a5,800010f0 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010da:	80b1                	srli	s1,s1,0xc
    800010dc:	04aa                	slli	s1,s1,0xa
    800010de:	0164e4b3          	or	s1,s1,s6
    800010e2:	0014e493          	ori	s1,s1,1
    800010e6:	e104                	sd	s1,0(a0)
    if(a == last)
    800010e8:	03390863          	beq	s2,s3,80001118 <mappages+0x8a>
    a += PGSIZE;
    800010ec:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010ee:	bfc9                	j	800010c0 <mappages+0x32>
      panic("remap");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	432080e7          	jalr	1074(ra) # 8000052a <panic>
      return -1;
    80001100:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001102:	60a6                	ld	ra,72(sp)
    80001104:	6406                	ld	s0,64(sp)
    80001106:	74e2                	ld	s1,56(sp)
    80001108:	7942                	ld	s2,48(sp)
    8000110a:	79a2                	ld	s3,40(sp)
    8000110c:	7a02                	ld	s4,32(sp)
    8000110e:	6ae2                	ld	s5,24(sp)
    80001110:	6b42                	ld	s6,16(sp)
    80001112:	6ba2                	ld	s7,8(sp)
    80001114:	6161                	addi	sp,sp,80
    80001116:	8082                	ret
  return 0;
    80001118:	4501                	li	a0,0
    8000111a:	b7e5                	j	80001102 <mappages+0x74>

000000008000111c <kvmmap>:
{
    8000111c:	1141                	addi	sp,sp,-16
    8000111e:	e406                	sd	ra,8(sp)
    80001120:	e022                	sd	s0,0(sp)
    80001122:	0800                	addi	s0,sp,16
    80001124:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001126:	86b2                	mv	a3,a2
    80001128:	863e                	mv	a2,a5
    8000112a:	00000097          	auipc	ra,0x0
    8000112e:	f64080e7          	jalr	-156(ra) # 8000108e <mappages>
    80001132:	e509                	bnez	a0,8000113c <kvmmap+0x20>
}
    80001134:	60a2                	ld	ra,8(sp)
    80001136:	6402                	ld	s0,0(sp)
    80001138:	0141                	addi	sp,sp,16
    8000113a:	8082                	ret
    panic("kvmmap");
    8000113c:	00007517          	auipc	a0,0x7
    80001140:	fa450513          	addi	a0,a0,-92 # 800080e0 <digits+0xa0>
    80001144:	fffff097          	auipc	ra,0xfffff
    80001148:	3e6080e7          	jalr	998(ra) # 8000052a <panic>

000000008000114c <kvmmake>:
{
    8000114c:	1101                	addi	sp,sp,-32
    8000114e:	ec06                	sd	ra,24(sp)
    80001150:	e822                	sd	s0,16(sp)
    80001152:	e426                	sd	s1,8(sp)
    80001154:	e04a                	sd	s2,0(sp)
    80001156:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001158:	00000097          	auipc	ra,0x0
    8000115c:	97a080e7          	jalr	-1670(ra) # 80000ad2 <kalloc>
    80001160:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001162:	6605                	lui	a2,0x1
    80001164:	4581                	li	a1,0
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	b58080e7          	jalr	-1192(ra) # 80000cbe <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000116e:	4719                	li	a4,6
    80001170:	6685                	lui	a3,0x1
    80001172:	10000637          	lui	a2,0x10000
    80001176:	100005b7          	lui	a1,0x10000
    8000117a:	8526                	mv	a0,s1
    8000117c:	00000097          	auipc	ra,0x0
    80001180:	fa0080e7          	jalr	-96(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001184:	4719                	li	a4,6
    80001186:	6685                	lui	a3,0x1
    80001188:	10001637          	lui	a2,0x10001
    8000118c:	100015b7          	lui	a1,0x10001
    80001190:	8526                	mv	a0,s1
    80001192:	00000097          	auipc	ra,0x0
    80001196:	f8a080e7          	jalr	-118(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000119a:	4719                	li	a4,6
    8000119c:	004006b7          	lui	a3,0x400
    800011a0:	0c000637          	lui	a2,0xc000
    800011a4:	0c0005b7          	lui	a1,0xc000
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f72080e7          	jalr	-142(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011b2:	00007917          	auipc	s2,0x7
    800011b6:	e4e90913          	addi	s2,s2,-434 # 80008000 <etext>
    800011ba:	4729                	li	a4,10
    800011bc:	80007697          	auipc	a3,0x80007
    800011c0:	e4468693          	addi	a3,a3,-444 # 8000 <_entry-0x7fff8000>
    800011c4:	4605                	li	a2,1
    800011c6:	067e                	slli	a2,a2,0x1f
    800011c8:	85b2                	mv	a1,a2
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f50080e7          	jalr	-176(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011d4:	4719                	li	a4,6
    800011d6:	46c5                	li	a3,17
    800011d8:	06ee                	slli	a3,a3,0x1b
    800011da:	412686b3          	sub	a3,a3,s2
    800011de:	864a                	mv	a2,s2
    800011e0:	85ca                	mv	a1,s2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f38080e7          	jalr	-200(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800011ec:	4729                	li	a4,10
    800011ee:	6685                	lui	a3,0x1
    800011f0:	00006617          	auipc	a2,0x6
    800011f4:	e1060613          	addi	a2,a2,-496 # 80007000 <_trampoline>
    800011f8:	040005b7          	lui	a1,0x4000
    800011fc:	15fd                	addi	a1,a1,-1
    800011fe:	05b2                	slli	a1,a1,0xc
    80001200:	8526                	mv	a0,s1
    80001202:	00000097          	auipc	ra,0x0
    80001206:	f1a080e7          	jalr	-230(ra) # 8000111c <kvmmap>
  proc_mapstacks(kpgtbl);
    8000120a:	8526                	mv	a0,s1
    8000120c:	00000097          	auipc	ra,0x0
    80001210:	7fe080e7          	jalr	2046(ra) # 80001a0a <proc_mapstacks>
}
    80001214:	8526                	mv	a0,s1
    80001216:	60e2                	ld	ra,24(sp)
    80001218:	6442                	ld	s0,16(sp)
    8000121a:	64a2                	ld	s1,8(sp)
    8000121c:	6902                	ld	s2,0(sp)
    8000121e:	6105                	addi	sp,sp,32
    80001220:	8082                	ret

0000000080001222 <kvminit>:
{
    80001222:	1141                	addi	sp,sp,-16
    80001224:	e406                	sd	ra,8(sp)
    80001226:	e022                	sd	s0,0(sp)
    80001228:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000122a:	00000097          	auipc	ra,0x0
    8000122e:	f22080e7          	jalr	-222(ra) # 8000114c <kvmmake>
    80001232:	00008797          	auipc	a5,0x8
    80001236:	dea7b723          	sd	a0,-530(a5) # 80009020 <kernel_pagetable>
}
    8000123a:	60a2                	ld	ra,8(sp)
    8000123c:	6402                	ld	s0,0(sp)
    8000123e:	0141                	addi	sp,sp,16
    80001240:	8082                	ret

0000000080001242 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001242:	715d                	addi	sp,sp,-80
    80001244:	e486                	sd	ra,72(sp)
    80001246:	e0a2                	sd	s0,64(sp)
    80001248:	fc26                	sd	s1,56(sp)
    8000124a:	f84a                	sd	s2,48(sp)
    8000124c:	f44e                	sd	s3,40(sp)
    8000124e:	f052                	sd	s4,32(sp)
    80001250:	ec56                	sd	s5,24(sp)
    80001252:	e85a                	sd	s6,16(sp)
    80001254:	e45e                	sd	s7,8(sp)
    80001256:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001258:	03459793          	slli	a5,a1,0x34
    8000125c:	e795                	bnez	a5,80001288 <uvmunmap+0x46>
    8000125e:	8a2a                	mv	s4,a0
    80001260:	892e                	mv	s2,a1
    80001262:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001264:	0632                	slli	a2,a2,0xc
    80001266:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000126a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000126c:	6b05                	lui	s6,0x1
    8000126e:	0735e263          	bltu	a1,s3,800012d2 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001272:	60a6                	ld	ra,72(sp)
    80001274:	6406                	ld	s0,64(sp)
    80001276:	74e2                	ld	s1,56(sp)
    80001278:	7942                	ld	s2,48(sp)
    8000127a:	79a2                	ld	s3,40(sp)
    8000127c:	7a02                	ld	s4,32(sp)
    8000127e:	6ae2                	ld	s5,24(sp)
    80001280:	6b42                	ld	s6,16(sp)
    80001282:	6ba2                	ld	s7,8(sp)
    80001284:	6161                	addi	sp,sp,80
    80001286:	8082                	ret
    panic("uvmunmap: not aligned");
    80001288:	00007517          	auipc	a0,0x7
    8000128c:	e6050513          	addi	a0,a0,-416 # 800080e8 <digits+0xa8>
    80001290:	fffff097          	auipc	ra,0xfffff
    80001294:	29a080e7          	jalr	666(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    80001298:	00007517          	auipc	a0,0x7
    8000129c:	e6850513          	addi	a0,a0,-408 # 80008100 <digits+0xc0>
    800012a0:	fffff097          	auipc	ra,0xfffff
    800012a4:	28a080e7          	jalr	650(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012a8:	00007517          	auipc	a0,0x7
    800012ac:	e6850513          	addi	a0,a0,-408 # 80008110 <digits+0xd0>
    800012b0:	fffff097          	auipc	ra,0xfffff
    800012b4:	27a080e7          	jalr	634(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012b8:	00007517          	auipc	a0,0x7
    800012bc:	e7050513          	addi	a0,a0,-400 # 80008128 <digits+0xe8>
    800012c0:	fffff097          	auipc	ra,0xfffff
    800012c4:	26a080e7          	jalr	618(ra) # 8000052a <panic>
    *pte = 0;
    800012c8:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012cc:	995a                	add	s2,s2,s6
    800012ce:	fb3972e3          	bgeu	s2,s3,80001272 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012d2:	4601                	li	a2,0
    800012d4:	85ca                	mv	a1,s2
    800012d6:	8552                	mv	a0,s4
    800012d8:	00000097          	auipc	ra,0x0
    800012dc:	cce080e7          	jalr	-818(ra) # 80000fa6 <walk>
    800012e0:	84aa                	mv	s1,a0
    800012e2:	d95d                	beqz	a0,80001298 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012e4:	6108                	ld	a0,0(a0)
    800012e6:	00157793          	andi	a5,a0,1
    800012ea:	dfdd                	beqz	a5,800012a8 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800012ec:	3ff57793          	andi	a5,a0,1023
    800012f0:	fd7784e3          	beq	a5,s7,800012b8 <uvmunmap+0x76>
    if(do_free){
    800012f4:	fc0a8ae3          	beqz	s5,800012c8 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800012f8:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fa:	0532                	slli	a0,a0,0xc
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	6da080e7          	jalr	1754(ra) # 800009d6 <kfree>
    80001304:	b7d1                	j	800012c8 <uvmunmap+0x86>

0000000080001306 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001306:	1101                	addi	sp,sp,-32
    80001308:	ec06                	sd	ra,24(sp)
    8000130a:	e822                	sd	s0,16(sp)
    8000130c:	e426                	sd	s1,8(sp)
    8000130e:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001310:	fffff097          	auipc	ra,0xfffff
    80001314:	7c2080e7          	jalr	1986(ra) # 80000ad2 <kalloc>
    80001318:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000131a:	c519                	beqz	a0,80001328 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000131c:	6605                	lui	a2,0x1
    8000131e:	4581                	li	a1,0
    80001320:	00000097          	auipc	ra,0x0
    80001324:	99e080e7          	jalr	-1634(ra) # 80000cbe <memset>
  return pagetable;
}
    80001328:	8526                	mv	a0,s1
    8000132a:	60e2                	ld	ra,24(sp)
    8000132c:	6442                	ld	s0,16(sp)
    8000132e:	64a2                	ld	s1,8(sp)
    80001330:	6105                	addi	sp,sp,32
    80001332:	8082                	ret

0000000080001334 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001334:	7179                	addi	sp,sp,-48
    80001336:	f406                	sd	ra,40(sp)
    80001338:	f022                	sd	s0,32(sp)
    8000133a:	ec26                	sd	s1,24(sp)
    8000133c:	e84a                	sd	s2,16(sp)
    8000133e:	e44e                	sd	s3,8(sp)
    80001340:	e052                	sd	s4,0(sp)
    80001342:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001344:	6785                	lui	a5,0x1
    80001346:	04f67863          	bgeu	a2,a5,80001396 <uvminit+0x62>
    8000134a:	8a2a                	mv	s4,a0
    8000134c:	89ae                	mv	s3,a1
    8000134e:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001350:	fffff097          	auipc	ra,0xfffff
    80001354:	782080e7          	jalr	1922(ra) # 80000ad2 <kalloc>
    80001358:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	960080e7          	jalr	-1696(ra) # 80000cbe <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001366:	4779                	li	a4,30
    80001368:	86ca                	mv	a3,s2
    8000136a:	6605                	lui	a2,0x1
    8000136c:	4581                	li	a1,0
    8000136e:	8552                	mv	a0,s4
    80001370:	00000097          	auipc	ra,0x0
    80001374:	d1e080e7          	jalr	-738(ra) # 8000108e <mappages>
  memmove(mem, src, sz);
    80001378:	8626                	mv	a2,s1
    8000137a:	85ce                	mv	a1,s3
    8000137c:	854a                	mv	a0,s2
    8000137e:	00000097          	auipc	ra,0x0
    80001382:	99c080e7          	jalr	-1636(ra) # 80000d1a <memmove>
}
    80001386:	70a2                	ld	ra,40(sp)
    80001388:	7402                	ld	s0,32(sp)
    8000138a:	64e2                	ld	s1,24(sp)
    8000138c:	6942                	ld	s2,16(sp)
    8000138e:	69a2                	ld	s3,8(sp)
    80001390:	6a02                	ld	s4,0(sp)
    80001392:	6145                	addi	sp,sp,48
    80001394:	8082                	ret
    panic("inituvm: more than a page");
    80001396:	00007517          	auipc	a0,0x7
    8000139a:	daa50513          	addi	a0,a0,-598 # 80008140 <digits+0x100>
    8000139e:	fffff097          	auipc	ra,0xfffff
    800013a2:	18c080e7          	jalr	396(ra) # 8000052a <panic>

00000000800013a6 <find_occupied_page_in_ram>:
// +    myproc()->psyc_pages_fifo.counter--;
// +    return page_to_swap_vaddr;
// +}

uint64
find_occupied_page_in_ram(void){
    800013a6:	1141                	addi	sp,sp,-16
    800013a8:	e406                	sd	ra,8(sp)
    800013aa:	e022                	sd	s0,0(sp)
    800013ac:	0800                	addi	s0,sp,16
  uint occupied_index=0;
  struct proc *p =  myproc();
    800013ae:	00000097          	auipc	ra,0x0
    800013b2:	7ce080e7          	jalr	1998(ra) # 80001b7c <myproc>
  while(occupied_index<16){
    800013b6:	17050513          	addi	a0,a0,368
  uint occupied_index=0;
    800013ba:	4781                	li	a5,0
    //finidng occupied page in swap file memory
    if(p->ram_pages.pages[occupied_index].virtual_address != -1)
    800013bc:	56fd                	li	a3,-1
  while(occupied_index<16){
    800013be:	4641                	li	a2,16
    if(p->ram_pages.pages[occupied_index].virtual_address != -1)
    800013c0:	4118                	lw	a4,0(a0)
    800013c2:	00d71e63          	bne	a4,a3,800013de <find_occupied_page_in_ram+0x38>
      return occupied_index;
    else
      occupied_index++;
    800013c6:	2785                	addiw	a5,a5,1
  while(occupied_index<16){
    800013c8:	0521                	addi	a0,a0,8
    800013ca:	fec79be3          	bne	a5,a2,800013c0 <find_occupied_page_in_ram+0x1a>
  }
  if(occupied_index > 15){
    //proc has a MAX_PSYC_PAGES pages
    panic("ram memory: somthing's wrong");
    800013ce:	00007517          	auipc	a0,0x7
    800013d2:	d9250513          	addi	a0,a0,-622 # 80008160 <digits+0x120>
    800013d6:	fffff097          	auipc	ra,0xfffff
    800013da:	154080e7          	jalr	340(ra) # 8000052a <panic>
      return occupied_index;
    800013de:	02079513          	slli	a0,a5,0x20
    800013e2:	9101                	srli	a0,a0,0x20
  }
  return -1;
}
    800013e4:	60a2                	ld	ra,8(sp)
    800013e6:	6402                	ld	s0,0(sp)
    800013e8:	0141                	addi	sp,sp,16
    800013ea:	8082                	ret

00000000800013ec <find_free_page_in_swapped>:

uint64
find_free_page_in_swapped(void){
    800013ec:	1141                	addi	sp,sp,-16
    800013ee:	e406                	sd	ra,8(sp)
    800013f0:	e022                	sd	s0,0(sp)
    800013f2:	0800                	addi	s0,sp,16
  uint sp_index=0;
  struct proc *p =  myproc();
    800013f4:	00000097          	auipc	ra,0x0
    800013f8:	788080e7          	jalr	1928(ra) # 80001b7c <myproc>
  while(sp_index<16){
    800013fc:	1f850513          	addi	a0,a0,504
  uint sp_index=0;
    80001400:	4781                	li	a5,0
    //finidng occupied page in swap file memory
    if(p->swapped_pages.pages[sp_index].virtual_address == -1)
    80001402:	56fd                	li	a3,-1
  while(sp_index<16){
    80001404:	4641                	li	a2,16
    if(p->swapped_pages.pages[sp_index].virtual_address == -1)
    80001406:	4118                	lw	a4,0(a0)
    80001408:	00d70b63          	beq	a4,a3,8000141e <find_free_page_in_swapped+0x32>
      return sp_index;
    else
      sp_index++;
    8000140c:	2785                	addiw	a5,a5,1
  while(sp_index<16){
    8000140e:	0521                	addi	a0,a0,8
    80001410:	fec79be3          	bne	a5,a2,80001406 <find_free_page_in_swapped+0x1a>
  }

  //proc has a MAX_PSYC_PAGES pages
  return -1;
    80001414:	557d                	li	a0,-1
}
    80001416:	60a2                	ld	ra,8(sp)
    80001418:	6402                	ld	s0,0(sp)
    8000141a:	0141                	addi	sp,sp,16
    8000141c:	8082                	ret
      return sp_index;
    8000141e:	02079513          	slli	a0,a5,0x20
    80001422:	9101                	srli	a0,a0,0x20
    80001424:	bfcd                	j	80001416 <find_free_page_in_swapped+0x2a>

0000000080001426 <swap>:

uint64
swap (void){
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
  struct proc *p=myproc();
    80001438:	00000097          	auipc	ra,0x0
    8000143c:	744080e7          	jalr	1860(ra) # 80001b7c <myproc>
    80001440:	892a                	mv	s2,a0
  uint occupied_index= find_occupied_page_in_ram();
    80001442:	00000097          	auipc	ra,0x0
    80001446:	f64080e7          	jalr	-156(ra) # 800013a6 <find_occupied_page_in_ram>
    8000144a:	84aa                	mv	s1,a0
  uint sp_index= find_free_page_in_swapped();
    8000144c:	00000097          	auipc	ra,0x0
    80001450:	fa0080e7          	jalr	-96(ra) # 800013ec <find_free_page_in_swapped>
    80001454:	0005099b          	sext.w	s3,a0
  // if sp_index==-1 then there are MAX_PSYC_PAGES 
  uint64 mm_va = p->ram_pages.pages[occupied_index].virtual_address;
    80001458:	02049793          	slli	a5,s1,0x20
    8000145c:	01d7d493          	srli	s1,a5,0x1d
    80001460:	94ca                	add	s1,s1,s2
    80001462:	1704aa83          	lw	s5,368(s1)
    80001466:	020a9a13          	slli	s4,s5,0x20
    8000146a:	020a5a13          	srli	s4,s4,0x20
  
  writeToSwapFile(p, (char*)mm_va, sp_index*PGSIZE, PGSIZE);
    8000146e:	6685                	lui	a3,0x1
    80001470:	00c5161b          	slliw	a2,a0,0xc
    80001474:	85d2                	mv	a1,s4
    80001476:	854a                	mv	a0,s2
    80001478:	00003097          	auipc	ra,0x3
    8000147c:	f04080e7          	jalr	-252(ra) # 8000437c <writeToSwapFile>
  p->swapped_pages.pages[sp_index].virtual_address=mm_va;
    80001480:	02099793          	slli	a5,s3,0x20
    80001484:	01d7d993          	srli	s3,a5,0x1d
    80001488:	99ca                	add	s3,s3,s2
    8000148a:	1f59ac23          	sw	s5,504(s3) # 11f8 <_entry-0x7fffee08>
  p->ram_pages.pages[occupied_index].virtual_address=-1; //this index is no more occupied
    8000148e:	57fd                	li	a5,-1
    80001490:	16f4a823          	sw	a5,368(s1)
  
  uint64 physical_address= walkaddr(p->pagetable, mm_va); //exchange virtual address to physical address
    80001494:	85d2                	mv	a1,s4
    80001496:	05093503          	ld	a0,80(s2)
    8000149a:	00000097          	auipc	ra,0x0
    8000149e:	bb2080e7          	jalr	-1102(ra) # 8000104c <walkaddr>
    800014a2:	84aa                	mv	s1,a0
  // kfree(*physical_address); //Free the page of physical memory
  // update pte flags
  pte_t *pte;
  uint64 a = PGROUNDDOWN(mm_va);
  
  if((pte = walk(p->pagetable, a, 1)) == 0)
    800014a4:	4605                	li	a2,1
    800014a6:	75fd                	lui	a1,0xfffff
    800014a8:	00ba75b3          	and	a1,s4,a1
    800014ac:	05093503          	ld	a0,80(s2)
    800014b0:	00000097          	auipc	ra,0x0
    800014b4:	af6080e7          	jalr	-1290(ra) # 80000fa6 <walk>
    800014b8:	c10d                	beqz	a0,800014da <swap+0xb4>
      return -1;
  *pte= PA2PTE(physical_address);
    800014ba:	00c4d793          	srli	a5,s1,0xc
    800014be:	07aa                	slli	a5,a5,0xa
  *pte |= PTE_PG; //page is on disc
    800014c0:	2007e793          	ori	a5,a5,512
    800014c4:	e11c                	sd	a5,0(a0)
  *pte &= ~PTE_V; //page is not valid
  // lcr3(V2P(myproc()->pgdir)); //TODO check: maybe needed for TLB maintainess

  return physical_address; //this physical addres is available now
}
    800014c6:	8526                	mv	a0,s1
    800014c8:	70e2                	ld	ra,56(sp)
    800014ca:	7442                	ld	s0,48(sp)
    800014cc:	74a2                	ld	s1,40(sp)
    800014ce:	7902                	ld	s2,32(sp)
    800014d0:	69e2                	ld	s3,24(sp)
    800014d2:	6a42                	ld	s4,16(sp)
    800014d4:	6aa2                	ld	s5,8(sp)
    800014d6:	6121                	addi	sp,sp,64
    800014d8:	8082                	ret
      return -1;
    800014da:	54fd                	li	s1,-1
    800014dc:	b7ed                	j	800014c6 <swap+0xa0>

00000000800014de <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014de:	1101                	addi	sp,sp,-32
    800014e0:	ec06                	sd	ra,24(sp)
    800014e2:	e822                	sd	s0,16(sp)
    800014e4:	e426                	sd	s1,8(sp)
    800014e6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014e8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014ea:	00b67d63          	bgeu	a2,a1,80001504 <uvmdealloc+0x26>
    800014ee:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014f0:	6785                	lui	a5,0x1
    800014f2:	17fd                	addi	a5,a5,-1
    800014f4:	00f60733          	add	a4,a2,a5
    800014f8:	767d                	lui	a2,0xfffff
    800014fa:	8f71                	and	a4,a4,a2
    800014fc:	97ae                	add	a5,a5,a1
    800014fe:	8ff1                	and	a5,a5,a2
    80001500:	00f76863          	bltu	a4,a5,80001510 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001504:	8526                	mv	a0,s1
    80001506:	60e2                	ld	ra,24(sp)
    80001508:	6442                	ld	s0,16(sp)
    8000150a:	64a2                	ld	s1,8(sp)
    8000150c:	6105                	addi	sp,sp,32
    8000150e:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001510:	8f99                	sub	a5,a5,a4
    80001512:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001514:	4685                	li	a3,1
    80001516:	0007861b          	sext.w	a2,a5
    8000151a:	85ba                	mv	a1,a4
    8000151c:	00000097          	auipc	ra,0x0
    80001520:	d26080e7          	jalr	-730(ra) # 80001242 <uvmunmap>
    80001524:	b7c5                	j	80001504 <uvmdealloc+0x26>

0000000080001526 <init_free_ram_page>:
init_free_ram_page(pagetable_t pagetable, uint64 va, uint64 pa, int index){
    80001526:	7139                	addi	sp,sp,-64
    80001528:	fc06                	sd	ra,56(sp)
    8000152a:	f822                	sd	s0,48(sp)
    8000152c:	f426                	sd	s1,40(sp)
    8000152e:	f04a                	sd	s2,32(sp)
    80001530:	ec4e                	sd	s3,24(sp)
    80001532:	e852                	sd	s4,16(sp)
    80001534:	e456                	sd	s5,8(sp)
    80001536:	0080                	addi	s0,sp,64
    80001538:	8aaa                	mv	s5,a0
    8000153a:	89ae                	mv	s3,a1
    8000153c:	8a32                	mv	s4,a2
    8000153e:	84b6                	mv	s1,a3
  struct proc *p=myproc();
    80001540:	00000097          	auipc	ra,0x0
    80001544:	63c080e7          	jalr	1596(ra) # 80001b7c <myproc>
    80001548:	892a                	mv	s2,a0
  if(mappages(pagetable, va, PGSIZE, pa, PTE_W|PTE_U) < 0){
    8000154a:	4751                	li	a4,20
    8000154c:	86d2                	mv	a3,s4
    8000154e:	6605                	lui	a2,0x1
    80001550:	85ce                	mv	a1,s3
    80001552:	8556                	mv	a0,s5
    80001554:	00000097          	auipc	ra,0x0
    80001558:	b3a080e7          	jalr	-1222(ra) # 8000108e <mappages>
    8000155c:	02054363          	bltz	a0,80001582 <init_free_ram_page+0x5c>
    p->ram_pages.pages[index].virtual_address = va;
    80001560:	02e48693          	addi	a3,s1,46
    80001564:	068e                	slli	a3,a3,0x3
    80001566:	00d90533          	add	a0,s2,a3
    8000156a:	01352023          	sw	s3,0(a0)
  return 0;
    8000156e:	4501                	li	a0,0
}
    80001570:	70e2                	ld	ra,56(sp)
    80001572:	7442                	ld	s0,48(sp)
    80001574:	74a2                	ld	s1,40(sp)
    80001576:	7902                	ld	s2,32(sp)
    80001578:	69e2                	ld	s3,24(sp)
    8000157a:	6a42                	ld	s4,16(sp)
    8000157c:	6aa2                	ld	s5,8(sp)
    8000157e:	6121                	addi	sp,sp,64
    80001580:	8082                	ret
      uvmdealloc(pagetable, PGSIZE, PGSIZE);
    80001582:	6605                	lui	a2,0x1
    80001584:	6585                	lui	a1,0x1
    80001586:	8556                	mv	a0,s5
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	f56080e7          	jalr	-170(ra) # 800014de <uvmdealloc>
      kfree((void*)pa); //Free the page of physical memory
    80001590:	8552                	mv	a0,s4
    80001592:	fffff097          	auipc	ra,0xfffff
    80001596:	444080e7          	jalr	1092(ra) # 800009d6 <kfree>
      return 1;
    8000159a:	4505                	li	a0,1
    8000159c:	bfd1                	j	80001570 <init_free_ram_page+0x4a>

000000008000159e <find_and_init_page>:
find_and_init_page(uint64 pa, uint64 va){
    8000159e:	1101                	addi	sp,sp,-32
    800015a0:	ec06                	sd	ra,24(sp)
    800015a2:	e822                	sd	s0,16(sp)
    800015a4:	e426                	sd	s1,8(sp)
    800015a6:	e04a                	sd	s2,0(sp)
    800015a8:	1000                	addi	s0,sp,32
    800015aa:	892a                	mv	s2,a0
    800015ac:	84ae                	mv	s1,a1
  struct proc *p =  myproc();
    800015ae:	00000097          	auipc	ra,0x0
    800015b2:	5ce080e7          	jalr	1486(ra) # 80001b7c <myproc>
  while(index<MAX_PSYC_PAGES){
    800015b6:	17050793          	addi	a5,a0,368
  int index =0;
    800015ba:	4681                	li	a3,0
    if(p->ram_pages.pages[index].virtual_address==-1){
    800015bc:	587d                	li	a6,-1
  while(index<MAX_PSYC_PAGES){
    800015be:	48c1                	li	a7,16
    if(p->ram_pages.pages[index].virtual_address==-1){
    800015c0:	4398                	lw	a4,0(a5)
    800015c2:	01070d63          	beq	a4,a6,800015dc <find_and_init_page+0x3e>
    index++;
    800015c6:	2685                	addiw	a3,a3,1
  while(index<MAX_PSYC_PAGES){
    800015c8:	07a1                	addi	a5,a5,8
    800015ca:	ff169be3          	bne	a3,a7,800015c0 <find_and_init_page+0x22>
  return -1;
    800015ce:	557d                	li	a0,-1
}
    800015d0:	60e2                	ld	ra,24(sp)
    800015d2:	6442                	ld	s0,16(sp)
    800015d4:	64a2                	ld	s1,8(sp)
    800015d6:	6902                	ld	s2,0(sp)
    800015d8:	6105                	addi	sp,sp,32
    800015da:	8082                	ret
      return init_free_ram_page(p->pagetable, va, pa, index);
    800015dc:	864a                	mv	a2,s2
    800015de:	85a6                	mv	a1,s1
    800015e0:	6928                	ld	a0,80(a0)
    800015e2:	00000097          	auipc	ra,0x0
    800015e6:	f44080e7          	jalr	-188(ra) # 80001526 <init_free_ram_page>
    800015ea:	b7dd                	j	800015d0 <find_and_init_page+0x32>

00000000800015ec <uvmalloc>:
  if(newsz < oldsz)
    800015ec:	0ab66163          	bltu	a2,a1,8000168e <uvmalloc+0xa2>
{
    800015f0:	7139                	addi	sp,sp,-64
    800015f2:	fc06                	sd	ra,56(sp)
    800015f4:	f822                	sd	s0,48(sp)
    800015f6:	f426                	sd	s1,40(sp)
    800015f8:	f04a                	sd	s2,32(sp)
    800015fa:	ec4e                	sd	s3,24(sp)
    800015fc:	e852                	sd	s4,16(sp)
    800015fe:	e456                	sd	s5,8(sp)
    80001600:	0080                	addi	s0,sp,64
    80001602:	8aaa                	mv	s5,a0
    80001604:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001606:	6985                	lui	s3,0x1
    80001608:	19fd                	addi	s3,s3,-1
    8000160a:	95ce                	add	a1,a1,s3
    8000160c:	79fd                	lui	s3,0xfffff
    8000160e:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001612:	08c9f063          	bgeu	s3,a2,80001692 <uvmalloc+0xa6>
    80001616:	894e                	mv	s2,s3
    mem = kalloc();
    80001618:	fffff097          	auipc	ra,0xfffff
    8000161c:	4ba080e7          	jalr	1210(ra) # 80000ad2 <kalloc>
    80001620:	84aa                	mv	s1,a0
    if(mem == 0){
    80001622:	c51d                	beqz	a0,80001650 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001624:	6605                	lui	a2,0x1
    80001626:	4581                	li	a1,0
    80001628:	fffff097          	auipc	ra,0xfffff
    8000162c:	696080e7          	jalr	1686(ra) # 80000cbe <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001630:	4779                	li	a4,30
    80001632:	86a6                	mv	a3,s1
    80001634:	6605                	lui	a2,0x1
    80001636:	85ca                	mv	a1,s2
    80001638:	8556                	mv	a0,s5
    8000163a:	00000097          	auipc	ra,0x0
    8000163e:	a54080e7          	jalr	-1452(ra) # 8000108e <mappages>
    80001642:	e905                	bnez	a0,80001672 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001644:	6785                	lui	a5,0x1
    80001646:	993e                	add	s2,s2,a5
    80001648:	fd4968e3          	bltu	s2,s4,80001618 <uvmalloc+0x2c>
  return newsz;
    8000164c:	8552                	mv	a0,s4
    8000164e:	a809                	j	80001660 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001650:	864e                	mv	a2,s3
    80001652:	85ca                	mv	a1,s2
    80001654:	8556                	mv	a0,s5
    80001656:	00000097          	auipc	ra,0x0
    8000165a:	e88080e7          	jalr	-376(ra) # 800014de <uvmdealloc>
      return 0;
    8000165e:	4501                	li	a0,0
}
    80001660:	70e2                	ld	ra,56(sp)
    80001662:	7442                	ld	s0,48(sp)
    80001664:	74a2                	ld	s1,40(sp)
    80001666:	7902                	ld	s2,32(sp)
    80001668:	69e2                	ld	s3,24(sp)
    8000166a:	6a42                	ld	s4,16(sp)
    8000166c:	6aa2                	ld	s5,8(sp)
    8000166e:	6121                	addi	sp,sp,64
    80001670:	8082                	ret
      kfree(mem);
    80001672:	8526                	mv	a0,s1
    80001674:	fffff097          	auipc	ra,0xfffff
    80001678:	362080e7          	jalr	866(ra) # 800009d6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000167c:	864e                	mv	a2,s3
    8000167e:	85ca                	mv	a1,s2
    80001680:	8556                	mv	a0,s5
    80001682:	00000097          	auipc	ra,0x0
    80001686:	e5c080e7          	jalr	-420(ra) # 800014de <uvmdealloc>
      return 0;
    8000168a:	4501                	li	a0,0
    8000168c:	bfd1                	j	80001660 <uvmalloc+0x74>
    return oldsz;
    8000168e:	852e                	mv	a0,a1
}
    80001690:	8082                	ret
  return newsz;
    80001692:	8532                	mv	a0,a2
    80001694:	b7f1                	j	80001660 <uvmalloc+0x74>

0000000080001696 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001696:	7179                	addi	sp,sp,-48
    80001698:	f406                	sd	ra,40(sp)
    8000169a:	f022                	sd	s0,32(sp)
    8000169c:	ec26                	sd	s1,24(sp)
    8000169e:	e84a                	sd	s2,16(sp)
    800016a0:	e44e                	sd	s3,8(sp)
    800016a2:	e052                	sd	s4,0(sp)
    800016a4:	1800                	addi	s0,sp,48
    800016a6:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800016a8:	84aa                	mv	s1,a0
    800016aa:	6905                	lui	s2,0x1
    800016ac:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016ae:	4985                	li	s3,1
    800016b0:	a821                	j	800016c8 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800016b2:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800016b4:	0532                	slli	a0,a0,0xc
    800016b6:	00000097          	auipc	ra,0x0
    800016ba:	fe0080e7          	jalr	-32(ra) # 80001696 <freewalk>
      pagetable[i] = 0;
    800016be:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800016c2:	04a1                	addi	s1,s1,8
    800016c4:	03248163          	beq	s1,s2,800016e6 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800016c8:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016ca:	00f57793          	andi	a5,a0,15
    800016ce:	ff3782e3          	beq	a5,s3,800016b2 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800016d2:	8905                	andi	a0,a0,1
    800016d4:	d57d                	beqz	a0,800016c2 <freewalk+0x2c>
      panic("freewalk: leaf");
    800016d6:	00007517          	auipc	a0,0x7
    800016da:	aaa50513          	addi	a0,a0,-1366 # 80008180 <digits+0x140>
    800016de:	fffff097          	auipc	ra,0xfffff
    800016e2:	e4c080e7          	jalr	-436(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    800016e6:	8552                	mv	a0,s4
    800016e8:	fffff097          	auipc	ra,0xfffff
    800016ec:	2ee080e7          	jalr	750(ra) # 800009d6 <kfree>
}
    800016f0:	70a2                	ld	ra,40(sp)
    800016f2:	7402                	ld	s0,32(sp)
    800016f4:	64e2                	ld	s1,24(sp)
    800016f6:	6942                	ld	s2,16(sp)
    800016f8:	69a2                	ld	s3,8(sp)
    800016fa:	6a02                	ld	s4,0(sp)
    800016fc:	6145                	addi	sp,sp,48
    800016fe:	8082                	ret

0000000080001700 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001700:	1101                	addi	sp,sp,-32
    80001702:	ec06                	sd	ra,24(sp)
    80001704:	e822                	sd	s0,16(sp)
    80001706:	e426                	sd	s1,8(sp)
    80001708:	1000                	addi	s0,sp,32
    8000170a:	84aa                	mv	s1,a0
  if(sz > 0)
    8000170c:	e999                	bnez	a1,80001722 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000170e:	8526                	mv	a0,s1
    80001710:	00000097          	auipc	ra,0x0
    80001714:	f86080e7          	jalr	-122(ra) # 80001696 <freewalk>
}
    80001718:	60e2                	ld	ra,24(sp)
    8000171a:	6442                	ld	s0,16(sp)
    8000171c:	64a2                	ld	s1,8(sp)
    8000171e:	6105                	addi	sp,sp,32
    80001720:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001722:	6605                	lui	a2,0x1
    80001724:	167d                	addi	a2,a2,-1
    80001726:	962e                	add	a2,a2,a1
    80001728:	4685                	li	a3,1
    8000172a:	8231                	srli	a2,a2,0xc
    8000172c:	4581                	li	a1,0
    8000172e:	00000097          	auipc	ra,0x0
    80001732:	b14080e7          	jalr	-1260(ra) # 80001242 <uvmunmap>
    80001736:	bfe1                	j	8000170e <uvmfree+0xe>

0000000080001738 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001738:	c679                	beqz	a2,80001806 <uvmcopy+0xce>
{
    8000173a:	715d                	addi	sp,sp,-80
    8000173c:	e486                	sd	ra,72(sp)
    8000173e:	e0a2                	sd	s0,64(sp)
    80001740:	fc26                	sd	s1,56(sp)
    80001742:	f84a                	sd	s2,48(sp)
    80001744:	f44e                	sd	s3,40(sp)
    80001746:	f052                	sd	s4,32(sp)
    80001748:	ec56                	sd	s5,24(sp)
    8000174a:	e85a                	sd	s6,16(sp)
    8000174c:	e45e                	sd	s7,8(sp)
    8000174e:	0880                	addi	s0,sp,80
    80001750:	8b2a                	mv	s6,a0
    80001752:	8aae                	mv	s5,a1
    80001754:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001756:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001758:	4601                	li	a2,0
    8000175a:	85ce                	mv	a1,s3
    8000175c:	855a                	mv	a0,s6
    8000175e:	00000097          	auipc	ra,0x0
    80001762:	848080e7          	jalr	-1976(ra) # 80000fa6 <walk>
    80001766:	c531                	beqz	a0,800017b2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001768:	6118                	ld	a4,0(a0)
    8000176a:	00177793          	andi	a5,a4,1
    8000176e:	cbb1                	beqz	a5,800017c2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001770:	00a75593          	srli	a1,a4,0xa
    80001774:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001778:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000177c:	fffff097          	auipc	ra,0xfffff
    80001780:	356080e7          	jalr	854(ra) # 80000ad2 <kalloc>
    80001784:	892a                	mv	s2,a0
    80001786:	c939                	beqz	a0,800017dc <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001788:	6605                	lui	a2,0x1
    8000178a:	85de                	mv	a1,s7
    8000178c:	fffff097          	auipc	ra,0xfffff
    80001790:	58e080e7          	jalr	1422(ra) # 80000d1a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001794:	8726                	mv	a4,s1
    80001796:	86ca                	mv	a3,s2
    80001798:	6605                	lui	a2,0x1
    8000179a:	85ce                	mv	a1,s3
    8000179c:	8556                	mv	a0,s5
    8000179e:	00000097          	auipc	ra,0x0
    800017a2:	8f0080e7          	jalr	-1808(ra) # 8000108e <mappages>
    800017a6:	e515                	bnez	a0,800017d2 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800017a8:	6785                	lui	a5,0x1
    800017aa:	99be                	add	s3,s3,a5
    800017ac:	fb49e6e3          	bltu	s3,s4,80001758 <uvmcopy+0x20>
    800017b0:	a081                	j	800017f0 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800017b2:	00007517          	auipc	a0,0x7
    800017b6:	9de50513          	addi	a0,a0,-1570 # 80008190 <digits+0x150>
    800017ba:	fffff097          	auipc	ra,0xfffff
    800017be:	d70080e7          	jalr	-656(ra) # 8000052a <panic>
      panic("uvmcopy: page not present");
    800017c2:	00007517          	auipc	a0,0x7
    800017c6:	9ee50513          	addi	a0,a0,-1554 # 800081b0 <digits+0x170>
    800017ca:	fffff097          	auipc	ra,0xfffff
    800017ce:	d60080e7          	jalr	-672(ra) # 8000052a <panic>
      kfree(mem);
    800017d2:	854a                	mv	a0,s2
    800017d4:	fffff097          	auipc	ra,0xfffff
    800017d8:	202080e7          	jalr	514(ra) # 800009d6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800017dc:	4685                	li	a3,1
    800017de:	00c9d613          	srli	a2,s3,0xc
    800017e2:	4581                	li	a1,0
    800017e4:	8556                	mv	a0,s5
    800017e6:	00000097          	auipc	ra,0x0
    800017ea:	a5c080e7          	jalr	-1444(ra) # 80001242 <uvmunmap>
  return -1;
    800017ee:	557d                	li	a0,-1
}
    800017f0:	60a6                	ld	ra,72(sp)
    800017f2:	6406                	ld	s0,64(sp)
    800017f4:	74e2                	ld	s1,56(sp)
    800017f6:	7942                	ld	s2,48(sp)
    800017f8:	79a2                	ld	s3,40(sp)
    800017fa:	7a02                	ld	s4,32(sp)
    800017fc:	6ae2                	ld	s5,24(sp)
    800017fe:	6b42                	ld	s6,16(sp)
    80001800:	6ba2                	ld	s7,8(sp)
    80001802:	6161                	addi	sp,sp,80
    80001804:	8082                	ret
  return 0;
    80001806:	4501                	li	a0,0
}
    80001808:	8082                	ret

000000008000180a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000180a:	1141                	addi	sp,sp,-16
    8000180c:	e406                	sd	ra,8(sp)
    8000180e:	e022                	sd	s0,0(sp)
    80001810:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001812:	4601                	li	a2,0
    80001814:	fffff097          	auipc	ra,0xfffff
    80001818:	792080e7          	jalr	1938(ra) # 80000fa6 <walk>
  if(pte == 0)
    8000181c:	c901                	beqz	a0,8000182c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000181e:	611c                	ld	a5,0(a0)
    80001820:	9bbd                	andi	a5,a5,-17
    80001822:	e11c                	sd	a5,0(a0)
}
    80001824:	60a2                	ld	ra,8(sp)
    80001826:	6402                	ld	s0,0(sp)
    80001828:	0141                	addi	sp,sp,16
    8000182a:	8082                	ret
    panic("uvmclear");
    8000182c:	00007517          	auipc	a0,0x7
    80001830:	9a450513          	addi	a0,a0,-1628 # 800081d0 <digits+0x190>
    80001834:	fffff097          	auipc	ra,0xfffff
    80001838:	cf6080e7          	jalr	-778(ra) # 8000052a <panic>

000000008000183c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000183c:	c6bd                	beqz	a3,800018aa <copyout+0x6e>
{
    8000183e:	715d                	addi	sp,sp,-80
    80001840:	e486                	sd	ra,72(sp)
    80001842:	e0a2                	sd	s0,64(sp)
    80001844:	fc26                	sd	s1,56(sp)
    80001846:	f84a                	sd	s2,48(sp)
    80001848:	f44e                	sd	s3,40(sp)
    8000184a:	f052                	sd	s4,32(sp)
    8000184c:	ec56                	sd	s5,24(sp)
    8000184e:	e85a                	sd	s6,16(sp)
    80001850:	e45e                	sd	s7,8(sp)
    80001852:	e062                	sd	s8,0(sp)
    80001854:	0880                	addi	s0,sp,80
    80001856:	8b2a                	mv	s6,a0
    80001858:	8c2e                	mv	s8,a1
    8000185a:	8a32                	mv	s4,a2
    8000185c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000185e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001860:	6a85                	lui	s5,0x1
    80001862:	a015                	j	80001886 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001864:	9562                	add	a0,a0,s8
    80001866:	0004861b          	sext.w	a2,s1
    8000186a:	85d2                	mv	a1,s4
    8000186c:	41250533          	sub	a0,a0,s2
    80001870:	fffff097          	auipc	ra,0xfffff
    80001874:	4aa080e7          	jalr	1194(ra) # 80000d1a <memmove>

    len -= n;
    80001878:	409989b3          	sub	s3,s3,s1
    src += n;
    8000187c:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000187e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001882:	02098263          	beqz	s3,800018a6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001886:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000188a:	85ca                	mv	a1,s2
    8000188c:	855a                	mv	a0,s6
    8000188e:	fffff097          	auipc	ra,0xfffff
    80001892:	7be080e7          	jalr	1982(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    80001896:	cd01                	beqz	a0,800018ae <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001898:	418904b3          	sub	s1,s2,s8
    8000189c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000189e:	fc99f3e3          	bgeu	s3,s1,80001864 <copyout+0x28>
    800018a2:	84ce                	mv	s1,s3
    800018a4:	b7c1                	j	80001864 <copyout+0x28>
  }
  return 0;
    800018a6:	4501                	li	a0,0
    800018a8:	a021                	j	800018b0 <copyout+0x74>
    800018aa:	4501                	li	a0,0
}
    800018ac:	8082                	ret
      return -1;
    800018ae:	557d                	li	a0,-1
}
    800018b0:	60a6                	ld	ra,72(sp)
    800018b2:	6406                	ld	s0,64(sp)
    800018b4:	74e2                	ld	s1,56(sp)
    800018b6:	7942                	ld	s2,48(sp)
    800018b8:	79a2                	ld	s3,40(sp)
    800018ba:	7a02                	ld	s4,32(sp)
    800018bc:	6ae2                	ld	s5,24(sp)
    800018be:	6b42                	ld	s6,16(sp)
    800018c0:	6ba2                	ld	s7,8(sp)
    800018c2:	6c02                	ld	s8,0(sp)
    800018c4:	6161                	addi	sp,sp,80
    800018c6:	8082                	ret

00000000800018c8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800018c8:	caa5                	beqz	a3,80001938 <copyin+0x70>
{
    800018ca:	715d                	addi	sp,sp,-80
    800018cc:	e486                	sd	ra,72(sp)
    800018ce:	e0a2                	sd	s0,64(sp)
    800018d0:	fc26                	sd	s1,56(sp)
    800018d2:	f84a                	sd	s2,48(sp)
    800018d4:	f44e                	sd	s3,40(sp)
    800018d6:	f052                	sd	s4,32(sp)
    800018d8:	ec56                	sd	s5,24(sp)
    800018da:	e85a                	sd	s6,16(sp)
    800018dc:	e45e                	sd	s7,8(sp)
    800018de:	e062                	sd	s8,0(sp)
    800018e0:	0880                	addi	s0,sp,80
    800018e2:	8b2a                	mv	s6,a0
    800018e4:	8a2e                	mv	s4,a1
    800018e6:	8c32                	mv	s8,a2
    800018e8:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800018ea:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018ec:	6a85                	lui	s5,0x1
    800018ee:	a01d                	j	80001914 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800018f0:	018505b3          	add	a1,a0,s8
    800018f4:	0004861b          	sext.w	a2,s1
    800018f8:	412585b3          	sub	a1,a1,s2
    800018fc:	8552                	mv	a0,s4
    800018fe:	fffff097          	auipc	ra,0xfffff
    80001902:	41c080e7          	jalr	1052(ra) # 80000d1a <memmove>

    len -= n;
    80001906:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000190a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000190c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001910:	02098263          	beqz	s3,80001934 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001914:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001918:	85ca                	mv	a1,s2
    8000191a:	855a                	mv	a0,s6
    8000191c:	fffff097          	auipc	ra,0xfffff
    80001920:	730080e7          	jalr	1840(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    80001924:	cd01                	beqz	a0,8000193c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001926:	418904b3          	sub	s1,s2,s8
    8000192a:	94d6                	add	s1,s1,s5
    if(n > len)
    8000192c:	fc99f2e3          	bgeu	s3,s1,800018f0 <copyin+0x28>
    80001930:	84ce                	mv	s1,s3
    80001932:	bf7d                	j	800018f0 <copyin+0x28>
  }
  return 0;
    80001934:	4501                	li	a0,0
    80001936:	a021                	j	8000193e <copyin+0x76>
    80001938:	4501                	li	a0,0
}
    8000193a:	8082                	ret
      return -1;
    8000193c:	557d                	li	a0,-1
}
    8000193e:	60a6                	ld	ra,72(sp)
    80001940:	6406                	ld	s0,64(sp)
    80001942:	74e2                	ld	s1,56(sp)
    80001944:	7942                	ld	s2,48(sp)
    80001946:	79a2                	ld	s3,40(sp)
    80001948:	7a02                	ld	s4,32(sp)
    8000194a:	6ae2                	ld	s5,24(sp)
    8000194c:	6b42                	ld	s6,16(sp)
    8000194e:	6ba2                	ld	s7,8(sp)
    80001950:	6c02                	ld	s8,0(sp)
    80001952:	6161                	addi	sp,sp,80
    80001954:	8082                	ret

0000000080001956 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001956:	c6c5                	beqz	a3,800019fe <copyinstr+0xa8>
{
    80001958:	715d                	addi	sp,sp,-80
    8000195a:	e486                	sd	ra,72(sp)
    8000195c:	e0a2                	sd	s0,64(sp)
    8000195e:	fc26                	sd	s1,56(sp)
    80001960:	f84a                	sd	s2,48(sp)
    80001962:	f44e                	sd	s3,40(sp)
    80001964:	f052                	sd	s4,32(sp)
    80001966:	ec56                	sd	s5,24(sp)
    80001968:	e85a                	sd	s6,16(sp)
    8000196a:	e45e                	sd	s7,8(sp)
    8000196c:	0880                	addi	s0,sp,80
    8000196e:	8a2a                	mv	s4,a0
    80001970:	8b2e                	mv	s6,a1
    80001972:	8bb2                	mv	s7,a2
    80001974:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001976:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001978:	6985                	lui	s3,0x1
    8000197a:	a035                	j	800019a6 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000197c:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001980:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001982:	0017b793          	seqz	a5,a5
    80001986:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000198a:	60a6                	ld	ra,72(sp)
    8000198c:	6406                	ld	s0,64(sp)
    8000198e:	74e2                	ld	s1,56(sp)
    80001990:	7942                	ld	s2,48(sp)
    80001992:	79a2                	ld	s3,40(sp)
    80001994:	7a02                	ld	s4,32(sp)
    80001996:	6ae2                	ld	s5,24(sp)
    80001998:	6b42                	ld	s6,16(sp)
    8000199a:	6ba2                	ld	s7,8(sp)
    8000199c:	6161                	addi	sp,sp,80
    8000199e:	8082                	ret
    srcva = va0 + PGSIZE;
    800019a0:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800019a4:	c8a9                	beqz	s1,800019f6 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800019a6:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800019aa:	85ca                	mv	a1,s2
    800019ac:	8552                	mv	a0,s4
    800019ae:	fffff097          	auipc	ra,0xfffff
    800019b2:	69e080e7          	jalr	1694(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    800019b6:	c131                	beqz	a0,800019fa <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800019b8:	41790833          	sub	a6,s2,s7
    800019bc:	984e                	add	a6,a6,s3
    if(n > max)
    800019be:	0104f363          	bgeu	s1,a6,800019c4 <copyinstr+0x6e>
    800019c2:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800019c4:	955e                	add	a0,a0,s7
    800019c6:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800019ca:	fc080be3          	beqz	a6,800019a0 <copyinstr+0x4a>
    800019ce:	985a                	add	a6,a6,s6
    800019d0:	87da                	mv	a5,s6
      if(*p == '\0'){
    800019d2:	41650633          	sub	a2,a0,s6
    800019d6:	14fd                	addi	s1,s1,-1
    800019d8:	9b26                	add	s6,s6,s1
    800019da:	00f60733          	add	a4,a2,a5
    800019de:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd4000>
    800019e2:	df49                	beqz	a4,8000197c <copyinstr+0x26>
        *dst = *p;
    800019e4:	00e78023          	sb	a4,0(a5)
      --max;
    800019e8:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800019ec:	0785                	addi	a5,a5,1
    while(n > 0){
    800019ee:	ff0796e3          	bne	a5,a6,800019da <copyinstr+0x84>
      dst++;
    800019f2:	8b42                	mv	s6,a6
    800019f4:	b775                	j	800019a0 <copyinstr+0x4a>
    800019f6:	4781                	li	a5,0
    800019f8:	b769                	j	80001982 <copyinstr+0x2c>
      return -1;
    800019fa:	557d                	li	a0,-1
    800019fc:	b779                	j	8000198a <copyinstr+0x34>
  int got_null = 0;
    800019fe:	4781                	li	a5,0
  if(got_null){
    80001a00:	0017b793          	seqz	a5,a5
    80001a04:	40f00533          	neg	a0,a5
}
    80001a08:	8082                	ret

0000000080001a0a <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001a0a:	7139                	addi	sp,sp,-64
    80001a0c:	fc06                	sd	ra,56(sp)
    80001a0e:	f822                	sd	s0,48(sp)
    80001a10:	f426                	sd	s1,40(sp)
    80001a12:	f04a                	sd	s2,32(sp)
    80001a14:	ec4e                	sd	s3,24(sp)
    80001a16:	e852                	sd	s4,16(sp)
    80001a18:	e456                	sd	s5,8(sp)
    80001a1a:	e05a                	sd	s6,0(sp)
    80001a1c:	0080                	addi	s0,sp,64
    80001a1e:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a20:	00011497          	auipc	s1,0x11
    80001a24:	cb048493          	addi	s1,s1,-848 # 800126d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001a28:	8b26                	mv	s6,s1
    80001a2a:	00006a97          	auipc	s5,0x6
    80001a2e:	5d6a8a93          	addi	s5,s5,1494 # 80008000 <etext>
    80001a32:	04000937          	lui	s2,0x4000
    80001a36:	197d                	addi	s2,s2,-1
    80001a38:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a3a:	0001ba17          	auipc	s4,0x1b
    80001a3e:	c96a0a13          	addi	s4,s4,-874 # 8001c6d0 <tickslock>
    char *pa = kalloc();
    80001a42:	fffff097          	auipc	ra,0xfffff
    80001a46:	090080e7          	jalr	144(ra) # 80000ad2 <kalloc>
    80001a4a:	862a                	mv	a2,a0
    if(pa == 0)
    80001a4c:	c131                	beqz	a0,80001a90 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001a4e:	416485b3          	sub	a1,s1,s6
    80001a52:	859d                	srai	a1,a1,0x7
    80001a54:	000ab783          	ld	a5,0(s5)
    80001a58:	02f585b3          	mul	a1,a1,a5
    80001a5c:	2585                	addiw	a1,a1,1
    80001a5e:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a62:	4719                	li	a4,6
    80001a64:	6685                	lui	a3,0x1
    80001a66:	40b905b3          	sub	a1,s2,a1
    80001a6a:	854e                	mv	a0,s3
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	6b0080e7          	jalr	1712(ra) # 8000111c <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a74:	28048493          	addi	s1,s1,640
    80001a78:	fd4495e3          	bne	s1,s4,80001a42 <proc_mapstacks+0x38>
  }
}
    80001a7c:	70e2                	ld	ra,56(sp)
    80001a7e:	7442                	ld	s0,48(sp)
    80001a80:	74a2                	ld	s1,40(sp)
    80001a82:	7902                	ld	s2,32(sp)
    80001a84:	69e2                	ld	s3,24(sp)
    80001a86:	6a42                	ld	s4,16(sp)
    80001a88:	6aa2                	ld	s5,8(sp)
    80001a8a:	6b02                	ld	s6,0(sp)
    80001a8c:	6121                	addi	sp,sp,64
    80001a8e:	8082                	ret
      panic("kalloc");
    80001a90:	00006517          	auipc	a0,0x6
    80001a94:	75050513          	addi	a0,a0,1872 # 800081e0 <digits+0x1a0>
    80001a98:	fffff097          	auipc	ra,0xfffff
    80001a9c:	a92080e7          	jalr	-1390(ra) # 8000052a <panic>

0000000080001aa0 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001aa0:	7139                	addi	sp,sp,-64
    80001aa2:	fc06                	sd	ra,56(sp)
    80001aa4:	f822                	sd	s0,48(sp)
    80001aa6:	f426                	sd	s1,40(sp)
    80001aa8:	f04a                	sd	s2,32(sp)
    80001aaa:	ec4e                	sd	s3,24(sp)
    80001aac:	e852                	sd	s4,16(sp)
    80001aae:	e456                	sd	s5,8(sp)
    80001ab0:	e05a                	sd	s6,0(sp)
    80001ab2:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001ab4:	00006597          	auipc	a1,0x6
    80001ab8:	73458593          	addi	a1,a1,1844 # 800081e8 <digits+0x1a8>
    80001abc:	0000f517          	auipc	a0,0xf
    80001ac0:	7e450513          	addi	a0,a0,2020 # 800112a0 <pid_lock>
    80001ac4:	fffff097          	auipc	ra,0xfffff
    80001ac8:	06e080e7          	jalr	110(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001acc:	00006597          	auipc	a1,0x6
    80001ad0:	72458593          	addi	a1,a1,1828 # 800081f0 <digits+0x1b0>
    80001ad4:	0000f517          	auipc	a0,0xf
    80001ad8:	7e450513          	addi	a0,a0,2020 # 800112b8 <wait_lock>
    80001adc:	fffff097          	auipc	ra,0xfffff
    80001ae0:	056080e7          	jalr	86(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ae4:	00011497          	auipc	s1,0x11
    80001ae8:	bec48493          	addi	s1,s1,-1044 # 800126d0 <proc>
      initlock(&p->lock, "proc");
    80001aec:	00006b17          	auipc	s6,0x6
    80001af0:	714b0b13          	addi	s6,s6,1812 # 80008200 <digits+0x1c0>
      p->kstack = KSTACK((int) (p - proc));
    80001af4:	8aa6                	mv	s5,s1
    80001af6:	00006a17          	auipc	s4,0x6
    80001afa:	50aa0a13          	addi	s4,s4,1290 # 80008000 <etext>
    80001afe:	04000937          	lui	s2,0x4000
    80001b02:	197d                	addi	s2,s2,-1
    80001b04:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b06:	0001b997          	auipc	s3,0x1b
    80001b0a:	bca98993          	addi	s3,s3,-1078 # 8001c6d0 <tickslock>
      initlock(&p->lock, "proc");
    80001b0e:	85da                	mv	a1,s6
    80001b10:	8526                	mv	a0,s1
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	020080e7          	jalr	32(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001b1a:	415487b3          	sub	a5,s1,s5
    80001b1e:	879d                	srai	a5,a5,0x7
    80001b20:	000a3703          	ld	a4,0(s4)
    80001b24:	02e787b3          	mul	a5,a5,a4
    80001b28:	2785                	addiw	a5,a5,1
    80001b2a:	00d7979b          	slliw	a5,a5,0xd
    80001b2e:	40f907b3          	sub	a5,s2,a5
    80001b32:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b34:	28048493          	addi	s1,s1,640
    80001b38:	fd349be3          	bne	s1,s3,80001b0e <procinit+0x6e>
  }
}
    80001b3c:	70e2                	ld	ra,56(sp)
    80001b3e:	7442                	ld	s0,48(sp)
    80001b40:	74a2                	ld	s1,40(sp)
    80001b42:	7902                	ld	s2,32(sp)
    80001b44:	69e2                	ld	s3,24(sp)
    80001b46:	6a42                	ld	s4,16(sp)
    80001b48:	6aa2                	ld	s5,8(sp)
    80001b4a:	6b02                	ld	s6,0(sp)
    80001b4c:	6121                	addi	sp,sp,64
    80001b4e:	8082                	ret

0000000080001b50 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001b50:	1141                	addi	sp,sp,-16
    80001b52:	e422                	sd	s0,8(sp)
    80001b54:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b56:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b58:	2501                	sext.w	a0,a0
    80001b5a:	6422                	ld	s0,8(sp)
    80001b5c:	0141                	addi	sp,sp,16
    80001b5e:	8082                	ret

0000000080001b60 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001b60:	1141                	addi	sp,sp,-16
    80001b62:	e422                	sd	s0,8(sp)
    80001b64:	0800                	addi	s0,sp,16
    80001b66:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b68:	2781                	sext.w	a5,a5
    80001b6a:	079e                	slli	a5,a5,0x7
  return c;
}
    80001b6c:	0000f517          	auipc	a0,0xf
    80001b70:	76450513          	addi	a0,a0,1892 # 800112d0 <cpus>
    80001b74:	953e                	add	a0,a0,a5
    80001b76:	6422                	ld	s0,8(sp)
    80001b78:	0141                	addi	sp,sp,16
    80001b7a:	8082                	ret

0000000080001b7c <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001b7c:	1101                	addi	sp,sp,-32
    80001b7e:	ec06                	sd	ra,24(sp)
    80001b80:	e822                	sd	s0,16(sp)
    80001b82:	e426                	sd	s1,8(sp)
    80001b84:	1000                	addi	s0,sp,32
  push_off();
    80001b86:	fffff097          	auipc	ra,0xfffff
    80001b8a:	ff0080e7          	jalr	-16(ra) # 80000b76 <push_off>
    80001b8e:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b90:	2781                	sext.w	a5,a5
    80001b92:	079e                	slli	a5,a5,0x7
    80001b94:	0000f717          	auipc	a4,0xf
    80001b98:	70c70713          	addi	a4,a4,1804 # 800112a0 <pid_lock>
    80001b9c:	97ba                	add	a5,a5,a4
    80001b9e:	7b84                	ld	s1,48(a5)
  pop_off();
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	076080e7          	jalr	118(ra) # 80000c16 <pop_off>
  return p;
}
    80001ba8:	8526                	mv	a0,s1
    80001baa:	60e2                	ld	ra,24(sp)
    80001bac:	6442                	ld	s0,16(sp)
    80001bae:	64a2                	ld	s1,8(sp)
    80001bb0:	6105                	addi	sp,sp,32
    80001bb2:	8082                	ret

0000000080001bb4 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001bb4:	1141                	addi	sp,sp,-16
    80001bb6:	e406                	sd	ra,8(sp)
    80001bb8:	e022                	sd	s0,0(sp)
    80001bba:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001bbc:	00000097          	auipc	ra,0x0
    80001bc0:	fc0080e7          	jalr	-64(ra) # 80001b7c <myproc>
    80001bc4:	fffff097          	auipc	ra,0xfffff
    80001bc8:	0b2080e7          	jalr	178(ra) # 80000c76 <release>

  if (first) {
    80001bcc:	00007797          	auipc	a5,0x7
    80001bd0:	c847a783          	lw	a5,-892(a5) # 80008850 <first.1>
    80001bd4:	eb89                	bnez	a5,80001be6 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001bd6:	00001097          	auipc	ra,0x1
    80001bda:	d02080e7          	jalr	-766(ra) # 800028d8 <usertrapret>
}
    80001bde:	60a2                	ld	ra,8(sp)
    80001be0:	6402                	ld	s0,0(sp)
    80001be2:	0141                	addi	sp,sp,16
    80001be4:	8082                	ret
    first = 0;
    80001be6:	00007797          	auipc	a5,0x7
    80001bea:	c607a523          	sw	zero,-918(a5) # 80008850 <first.1>
    fsinit(ROOTDEV);
    80001bee:	4505                	li	a0,1
    80001bf0:	00002097          	auipc	ra,0x2
    80001bf4:	a5a080e7          	jalr	-1446(ra) # 8000364a <fsinit>
    80001bf8:	bff9                	j	80001bd6 <forkret+0x22>

0000000080001bfa <allocpid>:
allocpid() {
    80001bfa:	1101                	addi	sp,sp,-32
    80001bfc:	ec06                	sd	ra,24(sp)
    80001bfe:	e822                	sd	s0,16(sp)
    80001c00:	e426                	sd	s1,8(sp)
    80001c02:	e04a                	sd	s2,0(sp)
    80001c04:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c06:	0000f917          	auipc	s2,0xf
    80001c0a:	69a90913          	addi	s2,s2,1690 # 800112a0 <pid_lock>
    80001c0e:	854a                	mv	a0,s2
    80001c10:	fffff097          	auipc	ra,0xfffff
    80001c14:	fb2080e7          	jalr	-78(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001c18:	00007797          	auipc	a5,0x7
    80001c1c:	c3c78793          	addi	a5,a5,-964 # 80008854 <nextpid>
    80001c20:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c22:	0014871b          	addiw	a4,s1,1
    80001c26:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c28:	854a                	mv	a0,s2
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	04c080e7          	jalr	76(ra) # 80000c76 <release>
}
    80001c32:	8526                	mv	a0,s1
    80001c34:	60e2                	ld	ra,24(sp)
    80001c36:	6442                	ld	s0,16(sp)
    80001c38:	64a2                	ld	s1,8(sp)
    80001c3a:	6902                	ld	s2,0(sp)
    80001c3c:	6105                	addi	sp,sp,32
    80001c3e:	8082                	ret

0000000080001c40 <proc_pagetable>:
{
    80001c40:	1101                	addi	sp,sp,-32
    80001c42:	ec06                	sd	ra,24(sp)
    80001c44:	e822                	sd	s0,16(sp)
    80001c46:	e426                	sd	s1,8(sp)
    80001c48:	e04a                	sd	s2,0(sp)
    80001c4a:	1000                	addi	s0,sp,32
    80001c4c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c4e:	fffff097          	auipc	ra,0xfffff
    80001c52:	6b8080e7          	jalr	1720(ra) # 80001306 <uvmcreate>
    80001c56:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c58:	c121                	beqz	a0,80001c98 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c5a:	4729                	li	a4,10
    80001c5c:	00005697          	auipc	a3,0x5
    80001c60:	3a468693          	addi	a3,a3,932 # 80007000 <_trampoline>
    80001c64:	6605                	lui	a2,0x1
    80001c66:	040005b7          	lui	a1,0x4000
    80001c6a:	15fd                	addi	a1,a1,-1
    80001c6c:	05b2                	slli	a1,a1,0xc
    80001c6e:	fffff097          	auipc	ra,0xfffff
    80001c72:	420080e7          	jalr	1056(ra) # 8000108e <mappages>
    80001c76:	02054863          	bltz	a0,80001ca6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c7a:	4719                	li	a4,6
    80001c7c:	05893683          	ld	a3,88(s2)
    80001c80:	6605                	lui	a2,0x1
    80001c82:	020005b7          	lui	a1,0x2000
    80001c86:	15fd                	addi	a1,a1,-1
    80001c88:	05b6                	slli	a1,a1,0xd
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	402080e7          	jalr	1026(ra) # 8000108e <mappages>
    80001c94:	02054163          	bltz	a0,80001cb6 <proc_pagetable+0x76>
}
    80001c98:	8526                	mv	a0,s1
    80001c9a:	60e2                	ld	ra,24(sp)
    80001c9c:	6442                	ld	s0,16(sp)
    80001c9e:	64a2                	ld	s1,8(sp)
    80001ca0:	6902                	ld	s2,0(sp)
    80001ca2:	6105                	addi	sp,sp,32
    80001ca4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ca6:	4581                	li	a1,0
    80001ca8:	8526                	mv	a0,s1
    80001caa:	00000097          	auipc	ra,0x0
    80001cae:	a56080e7          	jalr	-1450(ra) # 80001700 <uvmfree>
    return 0;
    80001cb2:	4481                	li	s1,0
    80001cb4:	b7d5                	j	80001c98 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cb6:	4681                	li	a3,0
    80001cb8:	4605                	li	a2,1
    80001cba:	040005b7          	lui	a1,0x4000
    80001cbe:	15fd                	addi	a1,a1,-1
    80001cc0:	05b2                	slli	a1,a1,0xc
    80001cc2:	8526                	mv	a0,s1
    80001cc4:	fffff097          	auipc	ra,0xfffff
    80001cc8:	57e080e7          	jalr	1406(ra) # 80001242 <uvmunmap>
    uvmfree(pagetable, 0);
    80001ccc:	4581                	li	a1,0
    80001cce:	8526                	mv	a0,s1
    80001cd0:	00000097          	auipc	ra,0x0
    80001cd4:	a30080e7          	jalr	-1488(ra) # 80001700 <uvmfree>
    return 0;
    80001cd8:	4481                	li	s1,0
    80001cda:	bf7d                	j	80001c98 <proc_pagetable+0x58>

0000000080001cdc <proc_freepagetable>:
{
    80001cdc:	1101                	addi	sp,sp,-32
    80001cde:	ec06                	sd	ra,24(sp)
    80001ce0:	e822                	sd	s0,16(sp)
    80001ce2:	e426                	sd	s1,8(sp)
    80001ce4:	e04a                	sd	s2,0(sp)
    80001ce6:	1000                	addi	s0,sp,32
    80001ce8:	84aa                	mv	s1,a0
    80001cea:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cec:	4681                	li	a3,0
    80001cee:	4605                	li	a2,1
    80001cf0:	040005b7          	lui	a1,0x4000
    80001cf4:	15fd                	addi	a1,a1,-1
    80001cf6:	05b2                	slli	a1,a1,0xc
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	54a080e7          	jalr	1354(ra) # 80001242 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d00:	4681                	li	a3,0
    80001d02:	4605                	li	a2,1
    80001d04:	020005b7          	lui	a1,0x2000
    80001d08:	15fd                	addi	a1,a1,-1
    80001d0a:	05b6                	slli	a1,a1,0xd
    80001d0c:	8526                	mv	a0,s1
    80001d0e:	fffff097          	auipc	ra,0xfffff
    80001d12:	534080e7          	jalr	1332(ra) # 80001242 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d16:	85ca                	mv	a1,s2
    80001d18:	8526                	mv	a0,s1
    80001d1a:	00000097          	auipc	ra,0x0
    80001d1e:	9e6080e7          	jalr	-1562(ra) # 80001700 <uvmfree>
}
    80001d22:	60e2                	ld	ra,24(sp)
    80001d24:	6442                	ld	s0,16(sp)
    80001d26:	64a2                	ld	s1,8(sp)
    80001d28:	6902                	ld	s2,0(sp)
    80001d2a:	6105                	addi	sp,sp,32
    80001d2c:	8082                	ret

0000000080001d2e <freeproc>:
{
    80001d2e:	1101                	addi	sp,sp,-32
    80001d30:	ec06                	sd	ra,24(sp)
    80001d32:	e822                	sd	s0,16(sp)
    80001d34:	e426                	sd	s1,8(sp)
    80001d36:	1000                	addi	s0,sp,32
    80001d38:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d3a:	6d28                	ld	a0,88(a0)
    80001d3c:	c509                	beqz	a0,80001d46 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	c98080e7          	jalr	-872(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001d46:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001d4a:	68a8                	ld	a0,80(s1)
    80001d4c:	c511                	beqz	a0,80001d58 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d4e:	64ac                	ld	a1,72(s1)
    80001d50:	00000097          	auipc	ra,0x0
    80001d54:	f8c080e7          	jalr	-116(ra) # 80001cdc <proc_freepagetable>
  p->pagetable = 0;
    80001d58:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d5c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d60:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d64:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d68:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d6c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d70:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d74:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d78:	0004ac23          	sw	zero,24(s1)
}
    80001d7c:	60e2                	ld	ra,24(sp)
    80001d7e:	6442                	ld	s0,16(sp)
    80001d80:	64a2                	ld	s1,8(sp)
    80001d82:	6105                	addi	sp,sp,32
    80001d84:	8082                	ret

0000000080001d86 <allocproc>:
{
    80001d86:	7179                	addi	sp,sp,-48
    80001d88:	f406                	sd	ra,40(sp)
    80001d8a:	f022                	sd	s0,32(sp)
    80001d8c:	ec26                	sd	s1,24(sp)
    80001d8e:	e84a                	sd	s2,16(sp)
    80001d90:	e44e                	sd	s3,8(sp)
    80001d92:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d94:	00011497          	auipc	s1,0x11
    80001d98:	93c48493          	addi	s1,s1,-1732 # 800126d0 <proc>
    80001d9c:	0001b997          	auipc	s3,0x1b
    80001da0:	93498993          	addi	s3,s3,-1740 # 8001c6d0 <tickslock>
    acquire(&p->lock);
    80001da4:	8526                	mv	a0,s1
    80001da6:	fffff097          	auipc	ra,0xfffff
    80001daa:	e1c080e7          	jalr	-484(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001dae:	4c9c                	lw	a5,24(s1)
    80001db0:	cf81                	beqz	a5,80001dc8 <allocproc+0x42>
      release(&p->lock);
    80001db2:	8526                	mv	a0,s1
    80001db4:	fffff097          	auipc	ra,0xfffff
    80001db8:	ec2080e7          	jalr	-318(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001dbc:	28048493          	addi	s1,s1,640
    80001dc0:	ff3492e3          	bne	s1,s3,80001da4 <allocproc+0x1e>
  return 0;
    80001dc4:	4481                	li	s1,0
    80001dc6:	a8a1                	j	80001e1e <allocproc+0x98>
  p->pid = allocpid();
    80001dc8:	00000097          	auipc	ra,0x0
    80001dcc:	e32080e7          	jalr	-462(ra) # 80001bfa <allocpid>
    80001dd0:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001dd2:	4785                	li	a5,1
    80001dd4:	cc9c                	sw	a5,24(s1)
  if (p->pid>=3){
    80001dd6:	4789                	li	a5,2
    80001dd8:	04a7cb63          	blt	a5,a0,80001e2e <allocproc+0xa8>
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001ddc:	fffff097          	auipc	ra,0xfffff
    80001de0:	cf6080e7          	jalr	-778(ra) # 80000ad2 <kalloc>
    80001de4:	892a                	mv	s2,a0
    80001de6:	eca8                	sd	a0,88(s1)
    80001de8:	cd2d                	beqz	a0,80001e62 <allocproc+0xdc>
  p->pagetable = proc_pagetable(p);
    80001dea:	8526                	mv	a0,s1
    80001dec:	00000097          	auipc	ra,0x0
    80001df0:	e54080e7          	jalr	-428(ra) # 80001c40 <proc_pagetable>
    80001df4:	892a                	mv	s2,a0
    80001df6:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001df8:	c149                	beqz	a0,80001e7a <allocproc+0xf4>
  memset(&p->context, 0, sizeof(p->context));
    80001dfa:	07000613          	li	a2,112
    80001dfe:	4581                	li	a1,0
    80001e00:	06048513          	addi	a0,s1,96
    80001e04:	fffff097          	auipc	ra,0xfffff
    80001e08:	eba080e7          	jalr	-326(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001e0c:	00000797          	auipc	a5,0x0
    80001e10:	da878793          	addi	a5,a5,-600 # 80001bb4 <forkret>
    80001e14:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e16:	60bc                	ld	a5,64(s1)
    80001e18:	6705                	lui	a4,0x1
    80001e1a:	97ba                	add	a5,a5,a4
    80001e1c:	f4bc                	sd	a5,104(s1)
}
    80001e1e:	8526                	mv	a0,s1
    80001e20:	70a2                	ld	ra,40(sp)
    80001e22:	7402                	ld	s0,32(sp)
    80001e24:	64e2                	ld	s1,24(sp)
    80001e26:	6942                	ld	s2,16(sp)
    80001e28:	69a2                	ld	s3,8(sp)
    80001e2a:	6145                	addi	sp,sp,48
    80001e2c:	8082                	ret
    createSwapFile(p);
    80001e2e:	8526                	mv	a0,s1
    80001e30:	00002097          	auipc	ra,0x2
    80001e34:	49c080e7          	jalr	1180(ra) # 800042cc <createSwapFile>
    p->swapped_pages.page_counter=0;
    80001e38:	2604ac23          	sw	zero,632(s1)
    p->ram_pages.page_counter=0;
    80001e3c:	1e04aa23          	sw	zero,500(s1)
    p->ram_pages.first_page_in=0; 
    80001e40:	1e04a823          	sw	zero,496(s1)
    for (int i=0 ; i<MAX_PSYC_PAGES ; i++){
    80001e44:	17048793          	addi	a5,s1,368
    80001e48:	1f048913          	addi	s2,s1,496
      p->swapped_pages.pages[i].virtual_address = -1;
    80001e4c:	577d                	li	a4,-1
    80001e4e:	08e7a423          	sw	a4,136(a5)
      p->swapped_pages.pages[i].file_offset = -1;
    80001e52:	08e7a623          	sw	a4,140(a5)
      p->ram_pages.pages[i].virtual_address = -1;
    80001e56:	c398                	sw	a4,0(a5)
      p->ram_pages.pages[i].access_counter = -1;
    80001e58:	c3d8                	sw	a4,4(a5)
    for (int i=0 ; i<MAX_PSYC_PAGES ; i++){
    80001e5a:	07a1                	addi	a5,a5,8
    80001e5c:	ff2799e3          	bne	a5,s2,80001e4e <allocproc+0xc8>
    80001e60:	bfb5                	j	80001ddc <allocproc+0x56>
    freeproc(p);
    80001e62:	8526                	mv	a0,s1
    80001e64:	00000097          	auipc	ra,0x0
    80001e68:	eca080e7          	jalr	-310(ra) # 80001d2e <freeproc>
    release(&p->lock);
    80001e6c:	8526                	mv	a0,s1
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	e08080e7          	jalr	-504(ra) # 80000c76 <release>
    return 0;
    80001e76:	84ca                	mv	s1,s2
    80001e78:	b75d                	j	80001e1e <allocproc+0x98>
    freeproc(p);
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	00000097          	auipc	ra,0x0
    80001e80:	eb2080e7          	jalr	-334(ra) # 80001d2e <freeproc>
    release(&p->lock);
    80001e84:	8526                	mv	a0,s1
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	df0080e7          	jalr	-528(ra) # 80000c76 <release>
    return 0;
    80001e8e:	84ca                	mv	s1,s2
    80001e90:	b779                	j	80001e1e <allocproc+0x98>

0000000080001e92 <userinit>:
{
    80001e92:	1101                	addi	sp,sp,-32
    80001e94:	ec06                	sd	ra,24(sp)
    80001e96:	e822                	sd	s0,16(sp)
    80001e98:	e426                	sd	s1,8(sp)
    80001e9a:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e9c:	00000097          	auipc	ra,0x0
    80001ea0:	eea080e7          	jalr	-278(ra) # 80001d86 <allocproc>
    80001ea4:	84aa                	mv	s1,a0
  initproc = p;
    80001ea6:	00007797          	auipc	a5,0x7
    80001eaa:	18a7b123          	sd	a0,386(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001eae:	03400613          	li	a2,52
    80001eb2:	00007597          	auipc	a1,0x7
    80001eb6:	9ae58593          	addi	a1,a1,-1618 # 80008860 <initcode>
    80001eba:	6928                	ld	a0,80(a0)
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	478080e7          	jalr	1144(ra) # 80001334 <uvminit>
  p->sz = PGSIZE;
    80001ec4:	6785                	lui	a5,0x1
    80001ec6:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ec8:	6cb8                	ld	a4,88(s1)
    80001eca:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ece:	6cb8                	ld	a4,88(s1)
    80001ed0:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ed2:	4641                	li	a2,16
    80001ed4:	00006597          	auipc	a1,0x6
    80001ed8:	33458593          	addi	a1,a1,820 # 80008208 <digits+0x1c8>
    80001edc:	15848513          	addi	a0,s1,344
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	f30080e7          	jalr	-208(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001ee8:	00006517          	auipc	a0,0x6
    80001eec:	33050513          	addi	a0,a0,816 # 80008218 <digits+0x1d8>
    80001ef0:	00002097          	auipc	ra,0x2
    80001ef4:	188080e7          	jalr	392(ra) # 80004078 <namei>
    80001ef8:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001efc:	478d                	li	a5,3
    80001efe:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f00:	8526                	mv	a0,s1
    80001f02:	fffff097          	auipc	ra,0xfffff
    80001f06:	d74080e7          	jalr	-652(ra) # 80000c76 <release>
}
    80001f0a:	60e2                	ld	ra,24(sp)
    80001f0c:	6442                	ld	s0,16(sp)
    80001f0e:	64a2                	ld	s1,8(sp)
    80001f10:	6105                	addi	sp,sp,32
    80001f12:	8082                	ret

0000000080001f14 <growproc>:
{
    80001f14:	1101                	addi	sp,sp,-32
    80001f16:	ec06                	sd	ra,24(sp)
    80001f18:	e822                	sd	s0,16(sp)
    80001f1a:	e426                	sd	s1,8(sp)
    80001f1c:	e04a                	sd	s2,0(sp)
    80001f1e:	1000                	addi	s0,sp,32
    80001f20:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001f22:	00000097          	auipc	ra,0x0
    80001f26:	c5a080e7          	jalr	-934(ra) # 80001b7c <myproc>
    80001f2a:	892a                	mv	s2,a0
  sz = p->sz;
    80001f2c:	652c                	ld	a1,72(a0)
    80001f2e:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001f32:	00904f63          	bgtz	s1,80001f50 <growproc+0x3c>
  } else if(n < 0){
    80001f36:	0204cc63          	bltz	s1,80001f6e <growproc+0x5a>
  p->sz = sz;
    80001f3a:	1602                	slli	a2,a2,0x20
    80001f3c:	9201                	srli	a2,a2,0x20
    80001f3e:	04c93423          	sd	a2,72(s2)
  return 0;
    80001f42:	4501                	li	a0,0
}
    80001f44:	60e2                	ld	ra,24(sp)
    80001f46:	6442                	ld	s0,16(sp)
    80001f48:	64a2                	ld	s1,8(sp)
    80001f4a:	6902                	ld	s2,0(sp)
    80001f4c:	6105                	addi	sp,sp,32
    80001f4e:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001f50:	9e25                	addw	a2,a2,s1
    80001f52:	1602                	slli	a2,a2,0x20
    80001f54:	9201                	srli	a2,a2,0x20
    80001f56:	1582                	slli	a1,a1,0x20
    80001f58:	9181                	srli	a1,a1,0x20
    80001f5a:	6928                	ld	a0,80(a0)
    80001f5c:	fffff097          	auipc	ra,0xfffff
    80001f60:	690080e7          	jalr	1680(ra) # 800015ec <uvmalloc>
    80001f64:	0005061b          	sext.w	a2,a0
    80001f68:	fa69                	bnez	a2,80001f3a <growproc+0x26>
      return -1;
    80001f6a:	557d                	li	a0,-1
    80001f6c:	bfe1                	j	80001f44 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f6e:	9e25                	addw	a2,a2,s1
    80001f70:	1602                	slli	a2,a2,0x20
    80001f72:	9201                	srli	a2,a2,0x20
    80001f74:	1582                	slli	a1,a1,0x20
    80001f76:	9181                	srli	a1,a1,0x20
    80001f78:	6928                	ld	a0,80(a0)
    80001f7a:	fffff097          	auipc	ra,0xfffff
    80001f7e:	564080e7          	jalr	1380(ra) # 800014de <uvmdealloc>
    80001f82:	0005061b          	sext.w	a2,a0
    80001f86:	bf55                	j	80001f3a <growproc+0x26>

0000000080001f88 <fork>:
{
    80001f88:	7119                	addi	sp,sp,-128
    80001f8a:	fc86                	sd	ra,120(sp)
    80001f8c:	f8a2                	sd	s0,112(sp)
    80001f8e:	f4a6                	sd	s1,104(sp)
    80001f90:	f0ca                	sd	s2,96(sp)
    80001f92:	ecce                	sd	s3,88(sp)
    80001f94:	e8d2                	sd	s4,80(sp)
    80001f96:	e4d6                	sd	s5,72(sp)
    80001f98:	e0da                	sd	s6,64(sp)
    80001f9a:	fc5e                	sd	s7,56(sp)
    80001f9c:	f862                	sd	s8,48(sp)
    80001f9e:	f466                	sd	s9,40(sp)
    80001fa0:	f06a                	sd	s10,32(sp)
    80001fa2:	ec6e                	sd	s11,24(sp)
    80001fa4:	0100                	addi	s0,sp,128
  struct proc *p = myproc();
    80001fa6:	00000097          	auipc	ra,0x0
    80001faa:	bd6080e7          	jalr	-1066(ra) # 80001b7c <myproc>
    80001fae:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001fb0:	00000097          	auipc	ra,0x0
    80001fb4:	dd6080e7          	jalr	-554(ra) # 80001d86 <allocproc>
    80001fb8:	1a050e63          	beqz	a0,80002174 <fork+0x1ec>
    80001fbc:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001fbe:	048ab603          	ld	a2,72(s5)
    80001fc2:	692c                	ld	a1,80(a0)
    80001fc4:	050ab503          	ld	a0,80(s5)
    80001fc8:	fffff097          	auipc	ra,0xfffff
    80001fcc:	770080e7          	jalr	1904(ra) # 80001738 <uvmcopy>
    80001fd0:	04054863          	bltz	a0,80002020 <fork+0x98>
  np->sz = p->sz;
    80001fd4:	048ab783          	ld	a5,72(s5)
    80001fd8:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001fdc:	058ab683          	ld	a3,88(s5)
    80001fe0:	87b6                	mv	a5,a3
    80001fe2:	058a3703          	ld	a4,88(s4)
    80001fe6:	12068693          	addi	a3,a3,288
    80001fea:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001fee:	6788                	ld	a0,8(a5)
    80001ff0:	6b8c                	ld	a1,16(a5)
    80001ff2:	6f90                	ld	a2,24(a5)
    80001ff4:	01073023          	sd	a6,0(a4)
    80001ff8:	e708                	sd	a0,8(a4)
    80001ffa:	eb0c                	sd	a1,16(a4)
    80001ffc:	ef10                	sd	a2,24(a4)
    80001ffe:	02078793          	addi	a5,a5,32
    80002002:	02070713          	addi	a4,a4,32
    80002006:	fed792e3          	bne	a5,a3,80001fea <fork+0x62>
  np->trapframe->a0 = 0;
    8000200a:	058a3783          	ld	a5,88(s4)
    8000200e:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80002012:	0d0a8493          	addi	s1,s5,208
    80002016:	0d0a0913          	addi	s2,s4,208
    8000201a:	150a8993          	addi	s3,s5,336
    8000201e:	a01d                	j	80002044 <fork+0xbc>
    freeproc(np);
    80002020:	8552                	mv	a0,s4
    80002022:	00000097          	auipc	ra,0x0
    80002026:	d0c080e7          	jalr	-756(ra) # 80001d2e <freeproc>
    release(&np->lock);
    8000202a:	8552                	mv	a0,s4
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	c4a080e7          	jalr	-950(ra) # 80000c76 <release>
    return -1;
    80002034:	57fd                	li	a5,-1
    80002036:	f8f43423          	sd	a5,-120(s0)
    8000203a:	aa21                	j	80002152 <fork+0x1ca>
  for(i = 0; i < NOFILE; i++)
    8000203c:	04a1                	addi	s1,s1,8
    8000203e:	0921                	addi	s2,s2,8
    80002040:	01348b63          	beq	s1,s3,80002056 <fork+0xce>
    if(p->ofile[i])
    80002044:	6088                	ld	a0,0(s1)
    80002046:	d97d                	beqz	a0,8000203c <fork+0xb4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002048:	00003097          	auipc	ra,0x3
    8000204c:	9dc080e7          	jalr	-1572(ra) # 80004a24 <filedup>
    80002050:	00a93023          	sd	a0,0(s2)
    80002054:	b7e5                	j	8000203c <fork+0xb4>
  np->cwd = idup(p->cwd);
    80002056:	150ab503          	ld	a0,336(s5)
    8000205a:	00002097          	auipc	ra,0x2
    8000205e:	82a080e7          	jalr	-2006(ra) # 80003884 <idup>
    80002062:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002066:	4641                	li	a2,16
    80002068:	158a8593          	addi	a1,s5,344
    8000206c:	158a0513          	addi	a0,s4,344
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	da0080e7          	jalr	-608(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80002078:	030a2783          	lw	a5,48(s4)
    8000207c:	f8f43423          	sd	a5,-120(s0)
  if(p->pid > 2) {
    80002080:	030aa703          	lw	a4,48(s5)
    80002084:	4789                	li	a5,2
    80002086:	08e7d463          	bge	a5,a4,8000210e <fork+0x186>
    np->swapped_pages.page_counter=p->swapped_pages.page_counter;
    8000208a:	278aa783          	lw	a5,632(s5)
    8000208e:	26fa2c23          	sw	a5,632(s4)
    np->ram_pages.page_counter=p->ram_pages.page_counter;
    80002092:	1f4aa783          	lw	a5,500(s5)
    80002096:	1efa2a23          	sw	a5,500(s4)
    np->ram_pages.first_page_in=p->ram_pages.page_counter; 
    8000209a:	1efa2823          	sw	a5,496(s4)
    for (int i=0 ; i<MAX_PSYC_PAGES ; i++){
    8000209e:	170a8913          	addi	s2,s5,368
    800020a2:	170a0493          	addi	s1,s4,368
    800020a6:	1f0a0d13          	addi	s10,s4,496
    np->ram_pages.first_page_in=p->ram_pages.page_counter; 
    800020aa:	4981                	li	s3,0
      if (np->ram_pages.pages[i].virtual_address!= -1){
    800020ac:	5cfd                	li	s9,-1
        readFromSwapFile(p, buffer, i*PGSIZE, (PGSIZE));
    800020ae:	0000fd97          	auipc	s11,0xf
    800020b2:	622d8d93          	addi	s11,s11,1570 # 800116d0 <buffer>
    for (int i=0 ; i<MAX_PSYC_PAGES ; i++){
    800020b6:	6c05                	lui	s8,0x1
    800020b8:	a819                	j	800020ce <fork+0x146>
      np->ram_pages.pages[i].access_counter = p->ram_pages.pages[i].access_counter;
    800020ba:	004ba783          	lw	a5,4(s7) # fffffffffffff004 <end+0xffffffff7ffd4004>
    800020be:	00fb2223          	sw	a5,4(s6)
    for (int i=0 ; i<MAX_PSYC_PAGES ; i++){
    800020c2:	0921                	addi	s2,s2,8
    800020c4:	04a1                	addi	s1,s1,8
    800020c6:	013c09bb          	addw	s3,s8,s3
    800020ca:	05a48263          	beq	s1,s10,8000210e <fork+0x186>
      np->swapped_pages.pages[i].virtual_address = p->swapped_pages.pages[i].virtual_address;
    800020ce:	8bca                	mv	s7,s2
    800020d0:	08892783          	lw	a5,136(s2)
    800020d4:	8b26                	mv	s6,s1
    800020d6:	08f4a423          	sw	a5,136(s1)
      np->swapped_pages.pages[i].file_offset = p->swapped_pages.pages[i].file_offset;
    800020da:	08c92783          	lw	a5,140(s2)
    800020de:	08f4a623          	sw	a5,140(s1)
      np->ram_pages.pages[i].virtual_address = p->ram_pages.pages[i].virtual_address;
    800020e2:	00092783          	lw	a5,0(s2)
    800020e6:	c09c                	sw	a5,0(s1)
      if (np->ram_pages.pages[i].virtual_address!= -1){
    800020e8:	fd9789e3          	beq	a5,s9,800020ba <fork+0x132>
        readFromSwapFile(p, buffer, i*PGSIZE, (PGSIZE));
    800020ec:	6685                	lui	a3,0x1
    800020ee:	864e                	mv	a2,s3
    800020f0:	85ee                	mv	a1,s11
    800020f2:	8556                	mv	a0,s5
    800020f4:	00002097          	auipc	ra,0x2
    800020f8:	2ac080e7          	jalr	684(ra) # 800043a0 <readFromSwapFile>
        writeToSwapFile(np, buffer, i*PGSIZE, (PGSIZE));
    800020fc:	6685                	lui	a3,0x1
    800020fe:	864e                	mv	a2,s3
    80002100:	85ee                	mv	a1,s11
    80002102:	8552                	mv	a0,s4
    80002104:	00002097          	auipc	ra,0x2
    80002108:	278080e7          	jalr	632(ra) # 8000437c <writeToSwapFile>
    8000210c:	b77d                	j	800020ba <fork+0x132>
  release(&np->lock);
    8000210e:	8552                	mv	a0,s4
    80002110:	fffff097          	auipc	ra,0xfffff
    80002114:	b66080e7          	jalr	-1178(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80002118:	0000f497          	auipc	s1,0xf
    8000211c:	1a048493          	addi	s1,s1,416 # 800112b8 <wait_lock>
    80002120:	8526                	mv	a0,s1
    80002122:	fffff097          	auipc	ra,0xfffff
    80002126:	aa0080e7          	jalr	-1376(ra) # 80000bc2 <acquire>
  np->parent = p;
    8000212a:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    8000212e:	8526                	mv	a0,s1
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	b46080e7          	jalr	-1210(ra) # 80000c76 <release>
  acquire(&np->lock);
    80002138:	8552                	mv	a0,s4
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	a88080e7          	jalr	-1400(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80002142:	478d                	li	a5,3
    80002144:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80002148:	8552                	mv	a0,s4
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	b2c080e7          	jalr	-1236(ra) # 80000c76 <release>
}
    80002152:	f8843503          	ld	a0,-120(s0)
    80002156:	70e6                	ld	ra,120(sp)
    80002158:	7446                	ld	s0,112(sp)
    8000215a:	74a6                	ld	s1,104(sp)
    8000215c:	7906                	ld	s2,96(sp)
    8000215e:	69e6                	ld	s3,88(sp)
    80002160:	6a46                	ld	s4,80(sp)
    80002162:	6aa6                	ld	s5,72(sp)
    80002164:	6b06                	ld	s6,64(sp)
    80002166:	7be2                	ld	s7,56(sp)
    80002168:	7c42                	ld	s8,48(sp)
    8000216a:	7ca2                	ld	s9,40(sp)
    8000216c:	7d02                	ld	s10,32(sp)
    8000216e:	6de2                	ld	s11,24(sp)
    80002170:	6109                	addi	sp,sp,128
    80002172:	8082                	ret
    return -1;
    80002174:	57fd                	li	a5,-1
    80002176:	f8f43423          	sd	a5,-120(s0)
    8000217a:	bfe1                	j	80002152 <fork+0x1ca>

000000008000217c <scheduler>:
{
    8000217c:	7139                	addi	sp,sp,-64
    8000217e:	fc06                	sd	ra,56(sp)
    80002180:	f822                	sd	s0,48(sp)
    80002182:	f426                	sd	s1,40(sp)
    80002184:	f04a                	sd	s2,32(sp)
    80002186:	ec4e                	sd	s3,24(sp)
    80002188:	e852                	sd	s4,16(sp)
    8000218a:	e456                	sd	s5,8(sp)
    8000218c:	e05a                	sd	s6,0(sp)
    8000218e:	0080                	addi	s0,sp,64
    80002190:	8792                	mv	a5,tp
  int id = r_tp();
    80002192:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002194:	00779a93          	slli	s5,a5,0x7
    80002198:	0000f717          	auipc	a4,0xf
    8000219c:	10870713          	addi	a4,a4,264 # 800112a0 <pid_lock>
    800021a0:	9756                	add	a4,a4,s5
    800021a2:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    800021a6:	0000f717          	auipc	a4,0xf
    800021aa:	13270713          	addi	a4,a4,306 # 800112d8 <cpus+0x8>
    800021ae:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    800021b0:	498d                	li	s3,3
        p->state = RUNNING;
    800021b2:	4b11                	li	s6,4
        c->proc = p;
    800021b4:	079e                	slli	a5,a5,0x7
    800021b6:	0000fa17          	auipc	s4,0xf
    800021ba:	0eaa0a13          	addi	s4,s4,234 # 800112a0 <pid_lock>
    800021be:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800021c0:	0001a917          	auipc	s2,0x1a
    800021c4:	51090913          	addi	s2,s2,1296 # 8001c6d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021c8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021cc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021d0:	10079073          	csrw	sstatus,a5
    800021d4:	00010497          	auipc	s1,0x10
    800021d8:	4fc48493          	addi	s1,s1,1276 # 800126d0 <proc>
    800021dc:	a811                	j	800021f0 <scheduler+0x74>
      release(&p->lock);
    800021de:	8526                	mv	a0,s1
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	a96080e7          	jalr	-1386(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800021e8:	28048493          	addi	s1,s1,640
    800021ec:	fd248ee3          	beq	s1,s2,800021c8 <scheduler+0x4c>
      acquire(&p->lock);
    800021f0:	8526                	mv	a0,s1
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	9d0080e7          	jalr	-1584(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    800021fa:	4c9c                	lw	a5,24(s1)
    800021fc:	ff3791e3          	bne	a5,s3,800021de <scheduler+0x62>
        p->state = RUNNING;
    80002200:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002204:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002208:	06048593          	addi	a1,s1,96
    8000220c:	8556                	mv	a0,s5
    8000220e:	00000097          	auipc	ra,0x0
    80002212:	620080e7          	jalr	1568(ra) # 8000282e <swtch>
        c->proc = 0;
    80002216:	020a3823          	sd	zero,48(s4)
    8000221a:	b7d1                	j	800021de <scheduler+0x62>

000000008000221c <sched>:
{
    8000221c:	7179                	addi	sp,sp,-48
    8000221e:	f406                	sd	ra,40(sp)
    80002220:	f022                	sd	s0,32(sp)
    80002222:	ec26                	sd	s1,24(sp)
    80002224:	e84a                	sd	s2,16(sp)
    80002226:	e44e                	sd	s3,8(sp)
    80002228:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000222a:	00000097          	auipc	ra,0x0
    8000222e:	952080e7          	jalr	-1710(ra) # 80001b7c <myproc>
    80002232:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002234:	fffff097          	auipc	ra,0xfffff
    80002238:	914080e7          	jalr	-1772(ra) # 80000b48 <holding>
    8000223c:	c93d                	beqz	a0,800022b2 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000223e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002240:	2781                	sext.w	a5,a5
    80002242:	079e                	slli	a5,a5,0x7
    80002244:	0000f717          	auipc	a4,0xf
    80002248:	05c70713          	addi	a4,a4,92 # 800112a0 <pid_lock>
    8000224c:	97ba                	add	a5,a5,a4
    8000224e:	0a87a703          	lw	a4,168(a5)
    80002252:	4785                	li	a5,1
    80002254:	06f71763          	bne	a4,a5,800022c2 <sched+0xa6>
  if(p->state == RUNNING)
    80002258:	4c98                	lw	a4,24(s1)
    8000225a:	4791                	li	a5,4
    8000225c:	06f70b63          	beq	a4,a5,800022d2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002260:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002264:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002266:	efb5                	bnez	a5,800022e2 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002268:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000226a:	0000f917          	auipc	s2,0xf
    8000226e:	03690913          	addi	s2,s2,54 # 800112a0 <pid_lock>
    80002272:	2781                	sext.w	a5,a5
    80002274:	079e                	slli	a5,a5,0x7
    80002276:	97ca                	add	a5,a5,s2
    80002278:	0ac7a983          	lw	s3,172(a5)
    8000227c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000227e:	2781                	sext.w	a5,a5
    80002280:	079e                	slli	a5,a5,0x7
    80002282:	0000f597          	auipc	a1,0xf
    80002286:	05658593          	addi	a1,a1,86 # 800112d8 <cpus+0x8>
    8000228a:	95be                	add	a1,a1,a5
    8000228c:	06048513          	addi	a0,s1,96
    80002290:	00000097          	auipc	ra,0x0
    80002294:	59e080e7          	jalr	1438(ra) # 8000282e <swtch>
    80002298:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000229a:	2781                	sext.w	a5,a5
    8000229c:	079e                	slli	a5,a5,0x7
    8000229e:	97ca                	add	a5,a5,s2
    800022a0:	0b37a623          	sw	s3,172(a5)
}
    800022a4:	70a2                	ld	ra,40(sp)
    800022a6:	7402                	ld	s0,32(sp)
    800022a8:	64e2                	ld	s1,24(sp)
    800022aa:	6942                	ld	s2,16(sp)
    800022ac:	69a2                	ld	s3,8(sp)
    800022ae:	6145                	addi	sp,sp,48
    800022b0:	8082                	ret
    panic("sched p->lock");
    800022b2:	00006517          	auipc	a0,0x6
    800022b6:	f6e50513          	addi	a0,a0,-146 # 80008220 <digits+0x1e0>
    800022ba:	ffffe097          	auipc	ra,0xffffe
    800022be:	270080e7          	jalr	624(ra) # 8000052a <panic>
    panic("sched locks");
    800022c2:	00006517          	auipc	a0,0x6
    800022c6:	f6e50513          	addi	a0,a0,-146 # 80008230 <digits+0x1f0>
    800022ca:	ffffe097          	auipc	ra,0xffffe
    800022ce:	260080e7          	jalr	608(ra) # 8000052a <panic>
    panic("sched running");
    800022d2:	00006517          	auipc	a0,0x6
    800022d6:	f6e50513          	addi	a0,a0,-146 # 80008240 <digits+0x200>
    800022da:	ffffe097          	auipc	ra,0xffffe
    800022de:	250080e7          	jalr	592(ra) # 8000052a <panic>
    panic("sched interruptible");
    800022e2:	00006517          	auipc	a0,0x6
    800022e6:	f6e50513          	addi	a0,a0,-146 # 80008250 <digits+0x210>
    800022ea:	ffffe097          	auipc	ra,0xffffe
    800022ee:	240080e7          	jalr	576(ra) # 8000052a <panic>

00000000800022f2 <yield>:
{
    800022f2:	1101                	addi	sp,sp,-32
    800022f4:	ec06                	sd	ra,24(sp)
    800022f6:	e822                	sd	s0,16(sp)
    800022f8:	e426                	sd	s1,8(sp)
    800022fa:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022fc:	00000097          	auipc	ra,0x0
    80002300:	880080e7          	jalr	-1920(ra) # 80001b7c <myproc>
    80002304:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002306:	fffff097          	auipc	ra,0xfffff
    8000230a:	8bc080e7          	jalr	-1860(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    8000230e:	478d                	li	a5,3
    80002310:	cc9c                	sw	a5,24(s1)
  sched();
    80002312:	00000097          	auipc	ra,0x0
    80002316:	f0a080e7          	jalr	-246(ra) # 8000221c <sched>
  release(&p->lock);
    8000231a:	8526                	mv	a0,s1
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	95a080e7          	jalr	-1702(ra) # 80000c76 <release>
}
    80002324:	60e2                	ld	ra,24(sp)
    80002326:	6442                	ld	s0,16(sp)
    80002328:	64a2                	ld	s1,8(sp)
    8000232a:	6105                	addi	sp,sp,32
    8000232c:	8082                	ret

000000008000232e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000232e:	7179                	addi	sp,sp,-48
    80002330:	f406                	sd	ra,40(sp)
    80002332:	f022                	sd	s0,32(sp)
    80002334:	ec26                	sd	s1,24(sp)
    80002336:	e84a                	sd	s2,16(sp)
    80002338:	e44e                	sd	s3,8(sp)
    8000233a:	1800                	addi	s0,sp,48
    8000233c:	89aa                	mv	s3,a0
    8000233e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002340:	00000097          	auipc	ra,0x0
    80002344:	83c080e7          	jalr	-1988(ra) # 80001b7c <myproc>
    80002348:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	878080e7          	jalr	-1928(ra) # 80000bc2 <acquire>
  release(lk);
    80002352:	854a                	mv	a0,s2
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	922080e7          	jalr	-1758(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    8000235c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002360:	4789                	li	a5,2
    80002362:	cc9c                	sw	a5,24(s1)

  sched();
    80002364:	00000097          	auipc	ra,0x0
    80002368:	eb8080e7          	jalr	-328(ra) # 8000221c <sched>

  // Tidy up.
  p->chan = 0;
    8000236c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002370:	8526                	mv	a0,s1
    80002372:	fffff097          	auipc	ra,0xfffff
    80002376:	904080e7          	jalr	-1788(ra) # 80000c76 <release>
  acquire(lk);
    8000237a:	854a                	mv	a0,s2
    8000237c:	fffff097          	auipc	ra,0xfffff
    80002380:	846080e7          	jalr	-1978(ra) # 80000bc2 <acquire>
}
    80002384:	70a2                	ld	ra,40(sp)
    80002386:	7402                	ld	s0,32(sp)
    80002388:	64e2                	ld	s1,24(sp)
    8000238a:	6942                	ld	s2,16(sp)
    8000238c:	69a2                	ld	s3,8(sp)
    8000238e:	6145                	addi	sp,sp,48
    80002390:	8082                	ret

0000000080002392 <wait>:
{
    80002392:	715d                	addi	sp,sp,-80
    80002394:	e486                	sd	ra,72(sp)
    80002396:	e0a2                	sd	s0,64(sp)
    80002398:	fc26                	sd	s1,56(sp)
    8000239a:	f84a                	sd	s2,48(sp)
    8000239c:	f44e                	sd	s3,40(sp)
    8000239e:	f052                	sd	s4,32(sp)
    800023a0:	ec56                	sd	s5,24(sp)
    800023a2:	e85a                	sd	s6,16(sp)
    800023a4:	e45e                	sd	s7,8(sp)
    800023a6:	e062                	sd	s8,0(sp)
    800023a8:	0880                	addi	s0,sp,80
    800023aa:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	7d0080e7          	jalr	2000(ra) # 80001b7c <myproc>
    800023b4:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023b6:	0000f517          	auipc	a0,0xf
    800023ba:	f0250513          	addi	a0,a0,-254 # 800112b8 <wait_lock>
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	804080e7          	jalr	-2044(ra) # 80000bc2 <acquire>
    havekids = 0;
    800023c6:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800023c8:	4a15                	li	s4,5
        havekids = 1;
    800023ca:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800023cc:	0001a997          	auipc	s3,0x1a
    800023d0:	30498993          	addi	s3,s3,772 # 8001c6d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023d4:	0000fc17          	auipc	s8,0xf
    800023d8:	ee4c0c13          	addi	s8,s8,-284 # 800112b8 <wait_lock>
    havekids = 0;
    800023dc:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800023de:	00010497          	auipc	s1,0x10
    800023e2:	2f248493          	addi	s1,s1,754 # 800126d0 <proc>
    800023e6:	a0bd                	j	80002454 <wait+0xc2>
          pid = np->pid;
    800023e8:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800023ec:	000b0e63          	beqz	s6,80002408 <wait+0x76>
    800023f0:	4691                	li	a3,4
    800023f2:	02c48613          	addi	a2,s1,44
    800023f6:	85da                	mv	a1,s6
    800023f8:	05093503          	ld	a0,80(s2)
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	440080e7          	jalr	1088(ra) # 8000183c <copyout>
    80002404:	02054563          	bltz	a0,8000242e <wait+0x9c>
          freeproc(np);
    80002408:	8526                	mv	a0,s1
    8000240a:	00000097          	auipc	ra,0x0
    8000240e:	924080e7          	jalr	-1756(ra) # 80001d2e <freeproc>
          release(&np->lock);
    80002412:	8526                	mv	a0,s1
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	862080e7          	jalr	-1950(ra) # 80000c76 <release>
          release(&wait_lock);
    8000241c:	0000f517          	auipc	a0,0xf
    80002420:	e9c50513          	addi	a0,a0,-356 # 800112b8 <wait_lock>
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	852080e7          	jalr	-1966(ra) # 80000c76 <release>
          return pid;
    8000242c:	a09d                	j	80002492 <wait+0x100>
            release(&np->lock);
    8000242e:	8526                	mv	a0,s1
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	846080e7          	jalr	-1978(ra) # 80000c76 <release>
            release(&wait_lock);
    80002438:	0000f517          	auipc	a0,0xf
    8000243c:	e8050513          	addi	a0,a0,-384 # 800112b8 <wait_lock>
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	836080e7          	jalr	-1994(ra) # 80000c76 <release>
            return -1;
    80002448:	59fd                	li	s3,-1
    8000244a:	a0a1                	j	80002492 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000244c:	28048493          	addi	s1,s1,640
    80002450:	03348463          	beq	s1,s3,80002478 <wait+0xe6>
      if(np->parent == p){
    80002454:	7c9c                	ld	a5,56(s1)
    80002456:	ff279be3          	bne	a5,s2,8000244c <wait+0xba>
        acquire(&np->lock);
    8000245a:	8526                	mv	a0,s1
    8000245c:	ffffe097          	auipc	ra,0xffffe
    80002460:	766080e7          	jalr	1894(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    80002464:	4c9c                	lw	a5,24(s1)
    80002466:	f94781e3          	beq	a5,s4,800023e8 <wait+0x56>
        release(&np->lock);
    8000246a:	8526                	mv	a0,s1
    8000246c:	fffff097          	auipc	ra,0xfffff
    80002470:	80a080e7          	jalr	-2038(ra) # 80000c76 <release>
        havekids = 1;
    80002474:	8756                	mv	a4,s5
    80002476:	bfd9                	j	8000244c <wait+0xba>
    if(!havekids || p->killed){
    80002478:	c701                	beqz	a4,80002480 <wait+0xee>
    8000247a:	02892783          	lw	a5,40(s2)
    8000247e:	c79d                	beqz	a5,800024ac <wait+0x11a>
      release(&wait_lock);
    80002480:	0000f517          	auipc	a0,0xf
    80002484:	e3850513          	addi	a0,a0,-456 # 800112b8 <wait_lock>
    80002488:	ffffe097          	auipc	ra,0xffffe
    8000248c:	7ee080e7          	jalr	2030(ra) # 80000c76 <release>
      return -1;
    80002490:	59fd                	li	s3,-1
}
    80002492:	854e                	mv	a0,s3
    80002494:	60a6                	ld	ra,72(sp)
    80002496:	6406                	ld	s0,64(sp)
    80002498:	74e2                	ld	s1,56(sp)
    8000249a:	7942                	ld	s2,48(sp)
    8000249c:	79a2                	ld	s3,40(sp)
    8000249e:	7a02                	ld	s4,32(sp)
    800024a0:	6ae2                	ld	s5,24(sp)
    800024a2:	6b42                	ld	s6,16(sp)
    800024a4:	6ba2                	ld	s7,8(sp)
    800024a6:	6c02                	ld	s8,0(sp)
    800024a8:	6161                	addi	sp,sp,80
    800024aa:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024ac:	85e2                	mv	a1,s8
    800024ae:	854a                	mv	a0,s2
    800024b0:	00000097          	auipc	ra,0x0
    800024b4:	e7e080e7          	jalr	-386(ra) # 8000232e <sleep>
    havekids = 0;
    800024b8:	b715                	j	800023dc <wait+0x4a>

00000000800024ba <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800024ba:	7139                	addi	sp,sp,-64
    800024bc:	fc06                	sd	ra,56(sp)
    800024be:	f822                	sd	s0,48(sp)
    800024c0:	f426                	sd	s1,40(sp)
    800024c2:	f04a                	sd	s2,32(sp)
    800024c4:	ec4e                	sd	s3,24(sp)
    800024c6:	e852                	sd	s4,16(sp)
    800024c8:	e456                	sd	s5,8(sp)
    800024ca:	0080                	addi	s0,sp,64
    800024cc:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800024ce:	00010497          	auipc	s1,0x10
    800024d2:	20248493          	addi	s1,s1,514 # 800126d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800024d6:	4989                	li	s3,2
        p->state = RUNNABLE;
    800024d8:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800024da:	0001a917          	auipc	s2,0x1a
    800024de:	1f690913          	addi	s2,s2,502 # 8001c6d0 <tickslock>
    800024e2:	a811                	j	800024f6 <wakeup+0x3c>
      }
      release(&p->lock);
    800024e4:	8526                	mv	a0,s1
    800024e6:	ffffe097          	auipc	ra,0xffffe
    800024ea:	790080e7          	jalr	1936(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024ee:	28048493          	addi	s1,s1,640
    800024f2:	03248663          	beq	s1,s2,8000251e <wakeup+0x64>
    if(p != myproc()){
    800024f6:	fffff097          	auipc	ra,0xfffff
    800024fa:	686080e7          	jalr	1670(ra) # 80001b7c <myproc>
    800024fe:	fea488e3          	beq	s1,a0,800024ee <wakeup+0x34>
      acquire(&p->lock);
    80002502:	8526                	mv	a0,s1
    80002504:	ffffe097          	auipc	ra,0xffffe
    80002508:	6be080e7          	jalr	1726(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000250c:	4c9c                	lw	a5,24(s1)
    8000250e:	fd379be3          	bne	a5,s3,800024e4 <wakeup+0x2a>
    80002512:	709c                	ld	a5,32(s1)
    80002514:	fd4798e3          	bne	a5,s4,800024e4 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002518:	0154ac23          	sw	s5,24(s1)
    8000251c:	b7e1                	j	800024e4 <wakeup+0x2a>
    }
  }
}
    8000251e:	70e2                	ld	ra,56(sp)
    80002520:	7442                	ld	s0,48(sp)
    80002522:	74a2                	ld	s1,40(sp)
    80002524:	7902                	ld	s2,32(sp)
    80002526:	69e2                	ld	s3,24(sp)
    80002528:	6a42                	ld	s4,16(sp)
    8000252a:	6aa2                	ld	s5,8(sp)
    8000252c:	6121                	addi	sp,sp,64
    8000252e:	8082                	ret

0000000080002530 <reparent>:
{
    80002530:	7179                	addi	sp,sp,-48
    80002532:	f406                	sd	ra,40(sp)
    80002534:	f022                	sd	s0,32(sp)
    80002536:	ec26                	sd	s1,24(sp)
    80002538:	e84a                	sd	s2,16(sp)
    8000253a:	e44e                	sd	s3,8(sp)
    8000253c:	e052                	sd	s4,0(sp)
    8000253e:	1800                	addi	s0,sp,48
    80002540:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002542:	00010497          	auipc	s1,0x10
    80002546:	18e48493          	addi	s1,s1,398 # 800126d0 <proc>
      pp->parent = initproc;
    8000254a:	00007a17          	auipc	s4,0x7
    8000254e:	adea0a13          	addi	s4,s4,-1314 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002552:	0001a997          	auipc	s3,0x1a
    80002556:	17e98993          	addi	s3,s3,382 # 8001c6d0 <tickslock>
    8000255a:	a029                	j	80002564 <reparent+0x34>
    8000255c:	28048493          	addi	s1,s1,640
    80002560:	01348d63          	beq	s1,s3,8000257a <reparent+0x4a>
    if(pp->parent == p){
    80002564:	7c9c                	ld	a5,56(s1)
    80002566:	ff279be3          	bne	a5,s2,8000255c <reparent+0x2c>
      pp->parent = initproc;
    8000256a:	000a3503          	ld	a0,0(s4)
    8000256e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002570:	00000097          	auipc	ra,0x0
    80002574:	f4a080e7          	jalr	-182(ra) # 800024ba <wakeup>
    80002578:	b7d5                	j	8000255c <reparent+0x2c>
}
    8000257a:	70a2                	ld	ra,40(sp)
    8000257c:	7402                	ld	s0,32(sp)
    8000257e:	64e2                	ld	s1,24(sp)
    80002580:	6942                	ld	s2,16(sp)
    80002582:	69a2                	ld	s3,8(sp)
    80002584:	6a02                	ld	s4,0(sp)
    80002586:	6145                	addi	sp,sp,48
    80002588:	8082                	ret

000000008000258a <exit>:
{
    8000258a:	7179                	addi	sp,sp,-48
    8000258c:	f406                	sd	ra,40(sp)
    8000258e:	f022                	sd	s0,32(sp)
    80002590:	ec26                	sd	s1,24(sp)
    80002592:	e84a                	sd	s2,16(sp)
    80002594:	e44e                	sd	s3,8(sp)
    80002596:	e052                	sd	s4,0(sp)
    80002598:	1800                	addi	s0,sp,48
    8000259a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000259c:	fffff097          	auipc	ra,0xfffff
    800025a0:	5e0080e7          	jalr	1504(ra) # 80001b7c <myproc>
    800025a4:	89aa                	mv	s3,a0
  if(p == initproc)
    800025a6:	00007797          	auipc	a5,0x7
    800025aa:	a827b783          	ld	a5,-1406(a5) # 80009028 <initproc>
    800025ae:	0d050493          	addi	s1,a0,208
    800025b2:	15050913          	addi	s2,a0,336
    800025b6:	02a79363          	bne	a5,a0,800025dc <exit+0x52>
    panic("init exiting");
    800025ba:	00006517          	auipc	a0,0x6
    800025be:	cae50513          	addi	a0,a0,-850 # 80008268 <digits+0x228>
    800025c2:	ffffe097          	auipc	ra,0xffffe
    800025c6:	f68080e7          	jalr	-152(ra) # 8000052a <panic>
      fileclose(f);
    800025ca:	00002097          	auipc	ra,0x2
    800025ce:	4ac080e7          	jalr	1196(ra) # 80004a76 <fileclose>
      p->ofile[fd] = 0;
    800025d2:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800025d6:	04a1                	addi	s1,s1,8
    800025d8:	01248563          	beq	s1,s2,800025e2 <exit+0x58>
    if(p->ofile[fd]){
    800025dc:	6088                	ld	a0,0(s1)
    800025de:	f575                	bnez	a0,800025ca <exit+0x40>
    800025e0:	bfdd                	j	800025d6 <exit+0x4c>
  begin_op();
    800025e2:	00002097          	auipc	ra,0x2
    800025e6:	fc8080e7          	jalr	-56(ra) # 800045aa <begin_op>
  iput(p->cwd);
    800025ea:	1509b503          	ld	a0,336(s3)
    800025ee:	00001097          	auipc	ra,0x1
    800025f2:	48e080e7          	jalr	1166(ra) # 80003a7c <iput>
  end_op();
    800025f6:	00002097          	auipc	ra,0x2
    800025fa:	034080e7          	jalr	52(ra) # 8000462a <end_op>
  p->cwd = 0;
    800025fe:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002602:	0000f497          	auipc	s1,0xf
    80002606:	cb648493          	addi	s1,s1,-842 # 800112b8 <wait_lock>
    8000260a:	8526                	mv	a0,s1
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	5b6080e7          	jalr	1462(ra) # 80000bc2 <acquire>
  reparent(p);
    80002614:	854e                	mv	a0,s3
    80002616:	00000097          	auipc	ra,0x0
    8000261a:	f1a080e7          	jalr	-230(ra) # 80002530 <reparent>
  wakeup(p->parent);
    8000261e:	0389b503          	ld	a0,56(s3)
    80002622:	00000097          	auipc	ra,0x0
    80002626:	e98080e7          	jalr	-360(ra) # 800024ba <wakeup>
  acquire(&p->lock);
    8000262a:	854e                	mv	a0,s3
    8000262c:	ffffe097          	auipc	ra,0xffffe
    80002630:	596080e7          	jalr	1430(ra) # 80000bc2 <acquire>
  p->xstate = status;
    80002634:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002638:	4795                	li	a5,5
    8000263a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000263e:	8526                	mv	a0,s1
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	636080e7          	jalr	1590(ra) # 80000c76 <release>
  sched();
    80002648:	00000097          	auipc	ra,0x0
    8000264c:	bd4080e7          	jalr	-1068(ra) # 8000221c <sched>
  panic("zombie exit");
    80002650:	00006517          	auipc	a0,0x6
    80002654:	c2850513          	addi	a0,a0,-984 # 80008278 <digits+0x238>
    80002658:	ffffe097          	auipc	ra,0xffffe
    8000265c:	ed2080e7          	jalr	-302(ra) # 8000052a <panic>

0000000080002660 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002660:	7179                	addi	sp,sp,-48
    80002662:	f406                	sd	ra,40(sp)
    80002664:	f022                	sd	s0,32(sp)
    80002666:	ec26                	sd	s1,24(sp)
    80002668:	e84a                	sd	s2,16(sp)
    8000266a:	e44e                	sd	s3,8(sp)
    8000266c:	1800                	addi	s0,sp,48
    8000266e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002670:	00010497          	auipc	s1,0x10
    80002674:	06048493          	addi	s1,s1,96 # 800126d0 <proc>
    80002678:	0001a997          	auipc	s3,0x1a
    8000267c:	05898993          	addi	s3,s3,88 # 8001c6d0 <tickslock>
    acquire(&p->lock);
    80002680:	8526                	mv	a0,s1
    80002682:	ffffe097          	auipc	ra,0xffffe
    80002686:	540080e7          	jalr	1344(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    8000268a:	589c                	lw	a5,48(s1)
    8000268c:	01278d63          	beq	a5,s2,800026a6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002690:	8526                	mv	a0,s1
    80002692:	ffffe097          	auipc	ra,0xffffe
    80002696:	5e4080e7          	jalr	1508(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000269a:	28048493          	addi	s1,s1,640
    8000269e:	ff3491e3          	bne	s1,s3,80002680 <kill+0x20>
  }
  return -1;
    800026a2:	557d                	li	a0,-1
    800026a4:	a829                	j	800026be <kill+0x5e>
      p->killed = 1;
    800026a6:	4785                	li	a5,1
    800026a8:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800026aa:	4c98                	lw	a4,24(s1)
    800026ac:	4789                	li	a5,2
    800026ae:	00f70f63          	beq	a4,a5,800026cc <kill+0x6c>
      release(&p->lock);
    800026b2:	8526                	mv	a0,s1
    800026b4:	ffffe097          	auipc	ra,0xffffe
    800026b8:	5c2080e7          	jalr	1474(ra) # 80000c76 <release>
      return 0;
    800026bc:	4501                	li	a0,0
}
    800026be:	70a2                	ld	ra,40(sp)
    800026c0:	7402                	ld	s0,32(sp)
    800026c2:	64e2                	ld	s1,24(sp)
    800026c4:	6942                	ld	s2,16(sp)
    800026c6:	69a2                	ld	s3,8(sp)
    800026c8:	6145                	addi	sp,sp,48
    800026ca:	8082                	ret
        p->state = RUNNABLE;
    800026cc:	478d                	li	a5,3
    800026ce:	cc9c                	sw	a5,24(s1)
    800026d0:	b7cd                	j	800026b2 <kill+0x52>

00000000800026d2 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026d2:	7179                	addi	sp,sp,-48
    800026d4:	f406                	sd	ra,40(sp)
    800026d6:	f022                	sd	s0,32(sp)
    800026d8:	ec26                	sd	s1,24(sp)
    800026da:	e84a                	sd	s2,16(sp)
    800026dc:	e44e                	sd	s3,8(sp)
    800026de:	e052                	sd	s4,0(sp)
    800026e0:	1800                	addi	s0,sp,48
    800026e2:	84aa                	mv	s1,a0
    800026e4:	892e                	mv	s2,a1
    800026e6:	89b2                	mv	s3,a2
    800026e8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026ea:	fffff097          	auipc	ra,0xfffff
    800026ee:	492080e7          	jalr	1170(ra) # 80001b7c <myproc>
  if(user_dst){
    800026f2:	c08d                	beqz	s1,80002714 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800026f4:	86d2                	mv	a3,s4
    800026f6:	864e                	mv	a2,s3
    800026f8:	85ca                	mv	a1,s2
    800026fa:	6928                	ld	a0,80(a0)
    800026fc:	fffff097          	auipc	ra,0xfffff
    80002700:	140080e7          	jalr	320(ra) # 8000183c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002704:	70a2                	ld	ra,40(sp)
    80002706:	7402                	ld	s0,32(sp)
    80002708:	64e2                	ld	s1,24(sp)
    8000270a:	6942                	ld	s2,16(sp)
    8000270c:	69a2                	ld	s3,8(sp)
    8000270e:	6a02                	ld	s4,0(sp)
    80002710:	6145                	addi	sp,sp,48
    80002712:	8082                	ret
    memmove((char *)dst, src, len);
    80002714:	000a061b          	sext.w	a2,s4
    80002718:	85ce                	mv	a1,s3
    8000271a:	854a                	mv	a0,s2
    8000271c:	ffffe097          	auipc	ra,0xffffe
    80002720:	5fe080e7          	jalr	1534(ra) # 80000d1a <memmove>
    return 0;
    80002724:	8526                	mv	a0,s1
    80002726:	bff9                	j	80002704 <either_copyout+0x32>

0000000080002728 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002728:	7179                	addi	sp,sp,-48
    8000272a:	f406                	sd	ra,40(sp)
    8000272c:	f022                	sd	s0,32(sp)
    8000272e:	ec26                	sd	s1,24(sp)
    80002730:	e84a                	sd	s2,16(sp)
    80002732:	e44e                	sd	s3,8(sp)
    80002734:	e052                	sd	s4,0(sp)
    80002736:	1800                	addi	s0,sp,48
    80002738:	892a                	mv	s2,a0
    8000273a:	84ae                	mv	s1,a1
    8000273c:	89b2                	mv	s3,a2
    8000273e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002740:	fffff097          	auipc	ra,0xfffff
    80002744:	43c080e7          	jalr	1084(ra) # 80001b7c <myproc>
  if(user_src){
    80002748:	c08d                	beqz	s1,8000276a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000274a:	86d2                	mv	a3,s4
    8000274c:	864e                	mv	a2,s3
    8000274e:	85ca                	mv	a1,s2
    80002750:	6928                	ld	a0,80(a0)
    80002752:	fffff097          	auipc	ra,0xfffff
    80002756:	176080e7          	jalr	374(ra) # 800018c8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000275a:	70a2                	ld	ra,40(sp)
    8000275c:	7402                	ld	s0,32(sp)
    8000275e:	64e2                	ld	s1,24(sp)
    80002760:	6942                	ld	s2,16(sp)
    80002762:	69a2                	ld	s3,8(sp)
    80002764:	6a02                	ld	s4,0(sp)
    80002766:	6145                	addi	sp,sp,48
    80002768:	8082                	ret
    memmove(dst, (char*)src, len);
    8000276a:	000a061b          	sext.w	a2,s4
    8000276e:	85ce                	mv	a1,s3
    80002770:	854a                	mv	a0,s2
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	5a8080e7          	jalr	1448(ra) # 80000d1a <memmove>
    return 0;
    8000277a:	8526                	mv	a0,s1
    8000277c:	bff9                	j	8000275a <either_copyin+0x32>

000000008000277e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000277e:	715d                	addi	sp,sp,-80
    80002780:	e486                	sd	ra,72(sp)
    80002782:	e0a2                	sd	s0,64(sp)
    80002784:	fc26                	sd	s1,56(sp)
    80002786:	f84a                	sd	s2,48(sp)
    80002788:	f44e                	sd	s3,40(sp)
    8000278a:	f052                	sd	s4,32(sp)
    8000278c:	ec56                	sd	s5,24(sp)
    8000278e:	e85a                	sd	s6,16(sp)
    80002790:	e45e                	sd	s7,8(sp)
    80002792:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002794:	00006517          	auipc	a0,0x6
    80002798:	93450513          	addi	a0,a0,-1740 # 800080c8 <digits+0x88>
    8000279c:	ffffe097          	auipc	ra,0xffffe
    800027a0:	dd8080e7          	jalr	-552(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027a4:	00010497          	auipc	s1,0x10
    800027a8:	08448493          	addi	s1,s1,132 # 80012828 <proc+0x158>
    800027ac:	0001a917          	auipc	s2,0x1a
    800027b0:	07c90913          	addi	s2,s2,124 # 8001c828 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027b4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800027b6:	00006997          	auipc	s3,0x6
    800027ba:	ad298993          	addi	s3,s3,-1326 # 80008288 <digits+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    800027be:	00006a97          	auipc	s5,0x6
    800027c2:	ad2a8a93          	addi	s5,s5,-1326 # 80008290 <digits+0x250>
    printf("\n");
    800027c6:	00006a17          	auipc	s4,0x6
    800027ca:	902a0a13          	addi	s4,s4,-1790 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027ce:	00006b97          	auipc	s7,0x6
    800027d2:	afab8b93          	addi	s7,s7,-1286 # 800082c8 <states.0>
    800027d6:	a00d                	j	800027f8 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800027d8:	ed86a583          	lw	a1,-296(a3) # ed8 <_entry-0x7ffff128>
    800027dc:	8556                	mv	a0,s5
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	d96080e7          	jalr	-618(ra) # 80000574 <printf>
    printf("\n");
    800027e6:	8552                	mv	a0,s4
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	d8c080e7          	jalr	-628(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027f0:	28048493          	addi	s1,s1,640
    800027f4:	03248263          	beq	s1,s2,80002818 <procdump+0x9a>
    if(p->state == UNUSED)
    800027f8:	86a6                	mv	a3,s1
    800027fa:	ec04a783          	lw	a5,-320(s1)
    800027fe:	dbed                	beqz	a5,800027f0 <procdump+0x72>
      state = "???";
    80002800:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002802:	fcfb6be3          	bltu	s6,a5,800027d8 <procdump+0x5a>
    80002806:	02079713          	slli	a4,a5,0x20
    8000280a:	01d75793          	srli	a5,a4,0x1d
    8000280e:	97de                	add	a5,a5,s7
    80002810:	6390                	ld	a2,0(a5)
    80002812:	f279                	bnez	a2,800027d8 <procdump+0x5a>
      state = "???";
    80002814:	864e                	mv	a2,s3
    80002816:	b7c9                	j	800027d8 <procdump+0x5a>
  }
}
    80002818:	60a6                	ld	ra,72(sp)
    8000281a:	6406                	ld	s0,64(sp)
    8000281c:	74e2                	ld	s1,56(sp)
    8000281e:	7942                	ld	s2,48(sp)
    80002820:	79a2                	ld	s3,40(sp)
    80002822:	7a02                	ld	s4,32(sp)
    80002824:	6ae2                	ld	s5,24(sp)
    80002826:	6b42                	ld	s6,16(sp)
    80002828:	6ba2                	ld	s7,8(sp)
    8000282a:	6161                	addi	sp,sp,80
    8000282c:	8082                	ret

000000008000282e <swtch>:
    8000282e:	00153023          	sd	ra,0(a0)
    80002832:	00253423          	sd	sp,8(a0)
    80002836:	e900                	sd	s0,16(a0)
    80002838:	ed04                	sd	s1,24(a0)
    8000283a:	03253023          	sd	s2,32(a0)
    8000283e:	03353423          	sd	s3,40(a0)
    80002842:	03453823          	sd	s4,48(a0)
    80002846:	03553c23          	sd	s5,56(a0)
    8000284a:	05653023          	sd	s6,64(a0)
    8000284e:	05753423          	sd	s7,72(a0)
    80002852:	05853823          	sd	s8,80(a0)
    80002856:	05953c23          	sd	s9,88(a0)
    8000285a:	07a53023          	sd	s10,96(a0)
    8000285e:	07b53423          	sd	s11,104(a0)
    80002862:	0005b083          	ld	ra,0(a1)
    80002866:	0085b103          	ld	sp,8(a1)
    8000286a:	6980                	ld	s0,16(a1)
    8000286c:	6d84                	ld	s1,24(a1)
    8000286e:	0205b903          	ld	s2,32(a1)
    80002872:	0285b983          	ld	s3,40(a1)
    80002876:	0305ba03          	ld	s4,48(a1)
    8000287a:	0385ba83          	ld	s5,56(a1)
    8000287e:	0405bb03          	ld	s6,64(a1)
    80002882:	0485bb83          	ld	s7,72(a1)
    80002886:	0505bc03          	ld	s8,80(a1)
    8000288a:	0585bc83          	ld	s9,88(a1)
    8000288e:	0605bd03          	ld	s10,96(a1)
    80002892:	0685bd83          	ld	s11,104(a1)
    80002896:	8082                	ret

0000000080002898 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002898:	1141                	addi	sp,sp,-16
    8000289a:	e406                	sd	ra,8(sp)
    8000289c:	e022                	sd	s0,0(sp)
    8000289e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800028a0:	00006597          	auipc	a1,0x6
    800028a4:	a5858593          	addi	a1,a1,-1448 # 800082f8 <states.0+0x30>
    800028a8:	0001a517          	auipc	a0,0x1a
    800028ac:	e2850513          	addi	a0,a0,-472 # 8001c6d0 <tickslock>
    800028b0:	ffffe097          	auipc	ra,0xffffe
    800028b4:	282080e7          	jalr	642(ra) # 80000b32 <initlock>
}
    800028b8:	60a2                	ld	ra,8(sp)
    800028ba:	6402                	ld	s0,0(sp)
    800028bc:	0141                	addi	sp,sp,16
    800028be:	8082                	ret

00000000800028c0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800028c0:	1141                	addi	sp,sp,-16
    800028c2:	e422                	sd	s0,8(sp)
    800028c4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028c6:	00004797          	auipc	a5,0x4
    800028ca:	9ea78793          	addi	a5,a5,-1558 # 800062b0 <kernelvec>
    800028ce:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028d2:	6422                	ld	s0,8(sp)
    800028d4:	0141                	addi	sp,sp,16
    800028d6:	8082                	ret

00000000800028d8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800028d8:	1141                	addi	sp,sp,-16
    800028da:	e406                	sd	ra,8(sp)
    800028dc:	e022                	sd	s0,0(sp)
    800028de:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028e0:	fffff097          	auipc	ra,0xfffff
    800028e4:	29c080e7          	jalr	668(ra) # 80001b7c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028ec:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ee:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800028f2:	00004617          	auipc	a2,0x4
    800028f6:	70e60613          	addi	a2,a2,1806 # 80007000 <_trampoline>
    800028fa:	00004697          	auipc	a3,0x4
    800028fe:	70668693          	addi	a3,a3,1798 # 80007000 <_trampoline>
    80002902:	8e91                	sub	a3,a3,a2
    80002904:	040007b7          	lui	a5,0x4000
    80002908:	17fd                	addi	a5,a5,-1
    8000290a:	07b2                	slli	a5,a5,0xc
    8000290c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000290e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002912:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002914:	180026f3          	csrr	a3,satp
    80002918:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000291a:	6d38                	ld	a4,88(a0)
    8000291c:	6134                	ld	a3,64(a0)
    8000291e:	6585                	lui	a1,0x1
    80002920:	96ae                	add	a3,a3,a1
    80002922:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002924:	6d38                	ld	a4,88(a0)
    80002926:	00000697          	auipc	a3,0x0
    8000292a:	13868693          	addi	a3,a3,312 # 80002a5e <usertrap>
    8000292e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002930:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002932:	8692                	mv	a3,tp
    80002934:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002936:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000293a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000293e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002942:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002946:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002948:	6f18                	ld	a4,24(a4)
    8000294a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000294e:	692c                	ld	a1,80(a0)
    80002950:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002952:	00004717          	auipc	a4,0x4
    80002956:	73e70713          	addi	a4,a4,1854 # 80007090 <userret>
    8000295a:	8f11                	sub	a4,a4,a2
    8000295c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000295e:	577d                	li	a4,-1
    80002960:	177e                	slli	a4,a4,0x3f
    80002962:	8dd9                	or	a1,a1,a4
    80002964:	02000537          	lui	a0,0x2000
    80002968:	157d                	addi	a0,a0,-1
    8000296a:	0536                	slli	a0,a0,0xd
    8000296c:	9782                	jalr	a5
}
    8000296e:	60a2                	ld	ra,8(sp)
    80002970:	6402                	ld	s0,0(sp)
    80002972:	0141                	addi	sp,sp,16
    80002974:	8082                	ret

0000000080002976 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002976:	1101                	addi	sp,sp,-32
    80002978:	ec06                	sd	ra,24(sp)
    8000297a:	e822                	sd	s0,16(sp)
    8000297c:	e426                	sd	s1,8(sp)
    8000297e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002980:	0001a497          	auipc	s1,0x1a
    80002984:	d5048493          	addi	s1,s1,-688 # 8001c6d0 <tickslock>
    80002988:	8526                	mv	a0,s1
    8000298a:	ffffe097          	auipc	ra,0xffffe
    8000298e:	238080e7          	jalr	568(ra) # 80000bc2 <acquire>
  ticks++;
    80002992:	00006517          	auipc	a0,0x6
    80002996:	69e50513          	addi	a0,a0,1694 # 80009030 <ticks>
    8000299a:	411c                	lw	a5,0(a0)
    8000299c:	2785                	addiw	a5,a5,1
    8000299e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800029a0:	00000097          	auipc	ra,0x0
    800029a4:	b1a080e7          	jalr	-1254(ra) # 800024ba <wakeup>
  release(&tickslock);
    800029a8:	8526                	mv	a0,s1
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	2cc080e7          	jalr	716(ra) # 80000c76 <release>
}
    800029b2:	60e2                	ld	ra,24(sp)
    800029b4:	6442                	ld	s0,16(sp)
    800029b6:	64a2                	ld	s1,8(sp)
    800029b8:	6105                	addi	sp,sp,32
    800029ba:	8082                	ret

00000000800029bc <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800029bc:	1101                	addi	sp,sp,-32
    800029be:	ec06                	sd	ra,24(sp)
    800029c0:	e822                	sd	s0,16(sp)
    800029c2:	e426                	sd	s1,8(sp)
    800029c4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029c6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800029ca:	00074d63          	bltz	a4,800029e4 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800029ce:	57fd                	li	a5,-1
    800029d0:	17fe                	slli	a5,a5,0x3f
    800029d2:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800029d4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800029d6:	06f70363          	beq	a4,a5,80002a3c <devintr+0x80>
  }
}
    800029da:	60e2                	ld	ra,24(sp)
    800029dc:	6442                	ld	s0,16(sp)
    800029de:	64a2                	ld	s1,8(sp)
    800029e0:	6105                	addi	sp,sp,32
    800029e2:	8082                	ret
     (scause & 0xff) == 9){
    800029e4:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800029e8:	46a5                	li	a3,9
    800029ea:	fed792e3          	bne	a5,a3,800029ce <devintr+0x12>
    int irq = plic_claim();
    800029ee:	00004097          	auipc	ra,0x4
    800029f2:	9ca080e7          	jalr	-1590(ra) # 800063b8 <plic_claim>
    800029f6:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029f8:	47a9                	li	a5,10
    800029fa:	02f50763          	beq	a0,a5,80002a28 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800029fe:	4785                	li	a5,1
    80002a00:	02f50963          	beq	a0,a5,80002a32 <devintr+0x76>
    return 1;
    80002a04:	4505                	li	a0,1
    } else if(irq){
    80002a06:	d8f1                	beqz	s1,800029da <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a08:	85a6                	mv	a1,s1
    80002a0a:	00006517          	auipc	a0,0x6
    80002a0e:	8f650513          	addi	a0,a0,-1802 # 80008300 <states.0+0x38>
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	b62080e7          	jalr	-1182(ra) # 80000574 <printf>
      plic_complete(irq);
    80002a1a:	8526                	mv	a0,s1
    80002a1c:	00004097          	auipc	ra,0x4
    80002a20:	9c0080e7          	jalr	-1600(ra) # 800063dc <plic_complete>
    return 1;
    80002a24:	4505                	li	a0,1
    80002a26:	bf55                	j	800029da <devintr+0x1e>
      uartintr();
    80002a28:	ffffe097          	auipc	ra,0xffffe
    80002a2c:	f5e080e7          	jalr	-162(ra) # 80000986 <uartintr>
    80002a30:	b7ed                	j	80002a1a <devintr+0x5e>
      virtio_disk_intr();
    80002a32:	00004097          	auipc	ra,0x4
    80002a36:	e3c080e7          	jalr	-452(ra) # 8000686e <virtio_disk_intr>
    80002a3a:	b7c5                	j	80002a1a <devintr+0x5e>
    if(cpuid() == 0){
    80002a3c:	fffff097          	auipc	ra,0xfffff
    80002a40:	114080e7          	jalr	276(ra) # 80001b50 <cpuid>
    80002a44:	c901                	beqz	a0,80002a54 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a46:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a4a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a4c:	14479073          	csrw	sip,a5
    return 2;
    80002a50:	4509                	li	a0,2
    80002a52:	b761                	j	800029da <devintr+0x1e>
      clockintr();
    80002a54:	00000097          	auipc	ra,0x0
    80002a58:	f22080e7          	jalr	-222(ra) # 80002976 <clockintr>
    80002a5c:	b7ed                	j	80002a46 <devintr+0x8a>

0000000080002a5e <usertrap>:
{
    80002a5e:	1101                	addi	sp,sp,-32
    80002a60:	ec06                	sd	ra,24(sp)
    80002a62:	e822                	sd	s0,16(sp)
    80002a64:	e426                	sd	s1,8(sp)
    80002a66:	e04a                	sd	s2,0(sp)
    80002a68:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a6a:	14302973          	csrr	s2,stval
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a6e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a72:	1007f793          	andi	a5,a5,256
    80002a76:	ebbd                	bnez	a5,80002aec <usertrap+0x8e>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a78:	00004797          	auipc	a5,0x4
    80002a7c:	83878793          	addi	a5,a5,-1992 # 800062b0 <kernelvec>
    80002a80:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a84:	fffff097          	auipc	ra,0xfffff
    80002a88:	0f8080e7          	jalr	248(ra) # 80001b7c <myproc>
    80002a8c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a8e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a90:	14102773          	csrr	a4,sepc
    80002a94:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a96:	14202773          	csrr	a4,scause
  if(r_scause() == 13 || r_scause() == 15){
    80002a9a:	47b5                	li	a5,13
    80002a9c:	06f70063          	beq	a4,a5,80002afc <usertrap+0x9e>
    80002aa0:	14202773          	csrr	a4,scause
    80002aa4:	47bd                	li	a5,15
    80002aa6:	04f70b63          	beq	a4,a5,80002afc <usertrap+0x9e>
    80002aaa:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002aae:	47a1                	li	a5,8
    80002ab0:	06f71863          	bne	a4,a5,80002b20 <usertrap+0xc2>
    if(p->killed)
    80002ab4:	549c                	lw	a5,40(s1)
    80002ab6:	efb9                	bnez	a5,80002b14 <usertrap+0xb6>
    p->trapframe->epc += 4;
    80002ab8:	6cb8                	ld	a4,88(s1)
    80002aba:	6f1c                	ld	a5,24(a4)
    80002abc:	0791                	addi	a5,a5,4
    80002abe:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ac0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ac4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ac8:	10079073          	csrw	sstatus,a5
    syscall();
    80002acc:	00000097          	auipc	ra,0x0
    80002ad0:	2f8080e7          	jalr	760(ra) # 80002dc4 <syscall>
  if(p->killed)
    80002ad4:	549c                	lw	a5,40(s1)
    80002ad6:	e7c5                	bnez	a5,80002b7e <usertrap+0x120>
  usertrapret();
    80002ad8:	00000097          	auipc	ra,0x0
    80002adc:	e00080e7          	jalr	-512(ra) # 800028d8 <usertrapret>
}
    80002ae0:	60e2                	ld	ra,24(sp)
    80002ae2:	6442                	ld	s0,16(sp)
    80002ae4:	64a2                	ld	s1,8(sp)
    80002ae6:	6902                	ld	s2,0(sp)
    80002ae8:	6105                	addi	sp,sp,32
    80002aea:	8082                	ret
  panic("usertrap: not from user mode");
    80002aec:	00006517          	auipc	a0,0x6
    80002af0:	83450513          	addi	a0,a0,-1996 # 80008320 <states.0+0x58>
    80002af4:	ffffe097          	auipc	ra,0xffffe
    80002af8:	a36080e7          	jalr	-1482(ra) # 8000052a <panic>
    uint64 pa = swap();
    80002afc:	fffff097          	auipc	ra,0xfffff
    80002b00:	92a080e7          	jalr	-1750(ra) # 80001426 <swap>
    find_and_init_page(pa, align_va);
    80002b04:	75fd                	lui	a1,0xfffff
    80002b06:	00b975b3          	and	a1,s2,a1
    80002b0a:	fffff097          	auipc	ra,0xfffff
    80002b0e:	a94080e7          	jalr	-1388(ra) # 8000159e <find_and_init_page>
    80002b12:	bf61                	j	80002aaa <usertrap+0x4c>
      exit(-1);
    80002b14:	557d                	li	a0,-1
    80002b16:	00000097          	auipc	ra,0x0
    80002b1a:	a74080e7          	jalr	-1420(ra) # 8000258a <exit>
    80002b1e:	bf69                	j	80002ab8 <usertrap+0x5a>
  } else if((which_dev = devintr()) != 0){
    80002b20:	00000097          	auipc	ra,0x0
    80002b24:	e9c080e7          	jalr	-356(ra) # 800029bc <devintr>
    80002b28:	892a                	mv	s2,a0
    80002b2a:	c501                	beqz	a0,80002b32 <usertrap+0xd4>
  if(p->killed)
    80002b2c:	549c                	lw	a5,40(s1)
    80002b2e:	c3a1                	beqz	a5,80002b6e <usertrap+0x110>
    80002b30:	a815                	j	80002b64 <usertrap+0x106>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b32:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b36:	5890                	lw	a2,48(s1)
    80002b38:	00006517          	auipc	a0,0x6
    80002b3c:	80850513          	addi	a0,a0,-2040 # 80008340 <states.0+0x78>
    80002b40:	ffffe097          	auipc	ra,0xffffe
    80002b44:	a34080e7          	jalr	-1484(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b48:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b4c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b50:	00006517          	auipc	a0,0x6
    80002b54:	82050513          	addi	a0,a0,-2016 # 80008370 <states.0+0xa8>
    80002b58:	ffffe097          	auipc	ra,0xffffe
    80002b5c:	a1c080e7          	jalr	-1508(ra) # 80000574 <printf>
    p->killed = 1;
    80002b60:	4785                	li	a5,1
    80002b62:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002b64:	557d                	li	a0,-1
    80002b66:	00000097          	auipc	ra,0x0
    80002b6a:	a24080e7          	jalr	-1500(ra) # 8000258a <exit>
  if(which_dev == 2)
    80002b6e:	4789                	li	a5,2
    80002b70:	f6f914e3          	bne	s2,a5,80002ad8 <usertrap+0x7a>
    yield();
    80002b74:	fffff097          	auipc	ra,0xfffff
    80002b78:	77e080e7          	jalr	1918(ra) # 800022f2 <yield>
    80002b7c:	bfb1                	j	80002ad8 <usertrap+0x7a>
  int which_dev = 0;
    80002b7e:	4901                	li	s2,0
    80002b80:	b7d5                	j	80002b64 <usertrap+0x106>

0000000080002b82 <kerneltrap>:
{
    80002b82:	7179                	addi	sp,sp,-48
    80002b84:	f406                	sd	ra,40(sp)
    80002b86:	f022                	sd	s0,32(sp)
    80002b88:	ec26                	sd	s1,24(sp)
    80002b8a:	e84a                	sd	s2,16(sp)
    80002b8c:	e44e                	sd	s3,8(sp)
    80002b8e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b90:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b94:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b98:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b9c:	1004f793          	andi	a5,s1,256
    80002ba0:	cb85                	beqz	a5,80002bd0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ba2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ba6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002ba8:	ef85                	bnez	a5,80002be0 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002baa:	00000097          	auipc	ra,0x0
    80002bae:	e12080e7          	jalr	-494(ra) # 800029bc <devintr>
    80002bb2:	cd1d                	beqz	a0,80002bf0 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bb4:	4789                	li	a5,2
    80002bb6:	06f50a63          	beq	a0,a5,80002c2a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bba:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bbe:	10049073          	csrw	sstatus,s1
}
    80002bc2:	70a2                	ld	ra,40(sp)
    80002bc4:	7402                	ld	s0,32(sp)
    80002bc6:	64e2                	ld	s1,24(sp)
    80002bc8:	6942                	ld	s2,16(sp)
    80002bca:	69a2                	ld	s3,8(sp)
    80002bcc:	6145                	addi	sp,sp,48
    80002bce:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002bd0:	00005517          	auipc	a0,0x5
    80002bd4:	7c050513          	addi	a0,a0,1984 # 80008390 <states.0+0xc8>
    80002bd8:	ffffe097          	auipc	ra,0xffffe
    80002bdc:	952080e7          	jalr	-1710(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002be0:	00005517          	auipc	a0,0x5
    80002be4:	7d850513          	addi	a0,a0,2008 # 800083b8 <states.0+0xf0>
    80002be8:	ffffe097          	auipc	ra,0xffffe
    80002bec:	942080e7          	jalr	-1726(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002bf0:	85ce                	mv	a1,s3
    80002bf2:	00005517          	auipc	a0,0x5
    80002bf6:	7e650513          	addi	a0,a0,2022 # 800083d8 <states.0+0x110>
    80002bfa:	ffffe097          	auipc	ra,0xffffe
    80002bfe:	97a080e7          	jalr	-1670(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c02:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c06:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c0a:	00005517          	auipc	a0,0x5
    80002c0e:	7de50513          	addi	a0,a0,2014 # 800083e8 <states.0+0x120>
    80002c12:	ffffe097          	auipc	ra,0xffffe
    80002c16:	962080e7          	jalr	-1694(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002c1a:	00005517          	auipc	a0,0x5
    80002c1e:	7e650513          	addi	a0,a0,2022 # 80008400 <states.0+0x138>
    80002c22:	ffffe097          	auipc	ra,0xffffe
    80002c26:	908080e7          	jalr	-1784(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c2a:	fffff097          	auipc	ra,0xfffff
    80002c2e:	f52080e7          	jalr	-174(ra) # 80001b7c <myproc>
    80002c32:	d541                	beqz	a0,80002bba <kerneltrap+0x38>
    80002c34:	fffff097          	auipc	ra,0xfffff
    80002c38:	f48080e7          	jalr	-184(ra) # 80001b7c <myproc>
    80002c3c:	4d18                	lw	a4,24(a0)
    80002c3e:	4791                	li	a5,4
    80002c40:	f6f71de3          	bne	a4,a5,80002bba <kerneltrap+0x38>
    yield();
    80002c44:	fffff097          	auipc	ra,0xfffff
    80002c48:	6ae080e7          	jalr	1710(ra) # 800022f2 <yield>
    80002c4c:	b7bd                	j	80002bba <kerneltrap+0x38>

0000000080002c4e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c4e:	1101                	addi	sp,sp,-32
    80002c50:	ec06                	sd	ra,24(sp)
    80002c52:	e822                	sd	s0,16(sp)
    80002c54:	e426                	sd	s1,8(sp)
    80002c56:	1000                	addi	s0,sp,32
    80002c58:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c5a:	fffff097          	auipc	ra,0xfffff
    80002c5e:	f22080e7          	jalr	-222(ra) # 80001b7c <myproc>
  switch (n) {
    80002c62:	4795                	li	a5,5
    80002c64:	0497e163          	bltu	a5,s1,80002ca6 <argraw+0x58>
    80002c68:	048a                	slli	s1,s1,0x2
    80002c6a:	00005717          	auipc	a4,0x5
    80002c6e:	7ce70713          	addi	a4,a4,1998 # 80008438 <states.0+0x170>
    80002c72:	94ba                	add	s1,s1,a4
    80002c74:	409c                	lw	a5,0(s1)
    80002c76:	97ba                	add	a5,a5,a4
    80002c78:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c7a:	6d3c                	ld	a5,88(a0)
    80002c7c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c7e:	60e2                	ld	ra,24(sp)
    80002c80:	6442                	ld	s0,16(sp)
    80002c82:	64a2                	ld	s1,8(sp)
    80002c84:	6105                	addi	sp,sp,32
    80002c86:	8082                	ret
    return p->trapframe->a1;
    80002c88:	6d3c                	ld	a5,88(a0)
    80002c8a:	7fa8                	ld	a0,120(a5)
    80002c8c:	bfcd                	j	80002c7e <argraw+0x30>
    return p->trapframe->a2;
    80002c8e:	6d3c                	ld	a5,88(a0)
    80002c90:	63c8                	ld	a0,128(a5)
    80002c92:	b7f5                	j	80002c7e <argraw+0x30>
    return p->trapframe->a3;
    80002c94:	6d3c                	ld	a5,88(a0)
    80002c96:	67c8                	ld	a0,136(a5)
    80002c98:	b7dd                	j	80002c7e <argraw+0x30>
    return p->trapframe->a4;
    80002c9a:	6d3c                	ld	a5,88(a0)
    80002c9c:	6bc8                	ld	a0,144(a5)
    80002c9e:	b7c5                	j	80002c7e <argraw+0x30>
    return p->trapframe->a5;
    80002ca0:	6d3c                	ld	a5,88(a0)
    80002ca2:	6fc8                	ld	a0,152(a5)
    80002ca4:	bfe9                	j	80002c7e <argraw+0x30>
  panic("argraw");
    80002ca6:	00005517          	auipc	a0,0x5
    80002caa:	76a50513          	addi	a0,a0,1898 # 80008410 <states.0+0x148>
    80002cae:	ffffe097          	auipc	ra,0xffffe
    80002cb2:	87c080e7          	jalr	-1924(ra) # 8000052a <panic>

0000000080002cb6 <fetchaddr>:
{
    80002cb6:	1101                	addi	sp,sp,-32
    80002cb8:	ec06                	sd	ra,24(sp)
    80002cba:	e822                	sd	s0,16(sp)
    80002cbc:	e426                	sd	s1,8(sp)
    80002cbe:	e04a                	sd	s2,0(sp)
    80002cc0:	1000                	addi	s0,sp,32
    80002cc2:	84aa                	mv	s1,a0
    80002cc4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002cc6:	fffff097          	auipc	ra,0xfffff
    80002cca:	eb6080e7          	jalr	-330(ra) # 80001b7c <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002cce:	653c                	ld	a5,72(a0)
    80002cd0:	02f4f863          	bgeu	s1,a5,80002d00 <fetchaddr+0x4a>
    80002cd4:	00848713          	addi	a4,s1,8
    80002cd8:	02e7e663          	bltu	a5,a4,80002d04 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002cdc:	46a1                	li	a3,8
    80002cde:	8626                	mv	a2,s1
    80002ce0:	85ca                	mv	a1,s2
    80002ce2:	6928                	ld	a0,80(a0)
    80002ce4:	fffff097          	auipc	ra,0xfffff
    80002ce8:	be4080e7          	jalr	-1052(ra) # 800018c8 <copyin>
    80002cec:	00a03533          	snez	a0,a0
    80002cf0:	40a00533          	neg	a0,a0
}
    80002cf4:	60e2                	ld	ra,24(sp)
    80002cf6:	6442                	ld	s0,16(sp)
    80002cf8:	64a2                	ld	s1,8(sp)
    80002cfa:	6902                	ld	s2,0(sp)
    80002cfc:	6105                	addi	sp,sp,32
    80002cfe:	8082                	ret
    return -1;
    80002d00:	557d                	li	a0,-1
    80002d02:	bfcd                	j	80002cf4 <fetchaddr+0x3e>
    80002d04:	557d                	li	a0,-1
    80002d06:	b7fd                	j	80002cf4 <fetchaddr+0x3e>

0000000080002d08 <fetchstr>:
{
    80002d08:	7179                	addi	sp,sp,-48
    80002d0a:	f406                	sd	ra,40(sp)
    80002d0c:	f022                	sd	s0,32(sp)
    80002d0e:	ec26                	sd	s1,24(sp)
    80002d10:	e84a                	sd	s2,16(sp)
    80002d12:	e44e                	sd	s3,8(sp)
    80002d14:	1800                	addi	s0,sp,48
    80002d16:	892a                	mv	s2,a0
    80002d18:	84ae                	mv	s1,a1
    80002d1a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d1c:	fffff097          	auipc	ra,0xfffff
    80002d20:	e60080e7          	jalr	-416(ra) # 80001b7c <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d24:	86ce                	mv	a3,s3
    80002d26:	864a                	mv	a2,s2
    80002d28:	85a6                	mv	a1,s1
    80002d2a:	6928                	ld	a0,80(a0)
    80002d2c:	fffff097          	auipc	ra,0xfffff
    80002d30:	c2a080e7          	jalr	-982(ra) # 80001956 <copyinstr>
  if(err < 0)
    80002d34:	00054763          	bltz	a0,80002d42 <fetchstr+0x3a>
  return strlen(buf);
    80002d38:	8526                	mv	a0,s1
    80002d3a:	ffffe097          	auipc	ra,0xffffe
    80002d3e:	108080e7          	jalr	264(ra) # 80000e42 <strlen>
}
    80002d42:	70a2                	ld	ra,40(sp)
    80002d44:	7402                	ld	s0,32(sp)
    80002d46:	64e2                	ld	s1,24(sp)
    80002d48:	6942                	ld	s2,16(sp)
    80002d4a:	69a2                	ld	s3,8(sp)
    80002d4c:	6145                	addi	sp,sp,48
    80002d4e:	8082                	ret

0000000080002d50 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d50:	1101                	addi	sp,sp,-32
    80002d52:	ec06                	sd	ra,24(sp)
    80002d54:	e822                	sd	s0,16(sp)
    80002d56:	e426                	sd	s1,8(sp)
    80002d58:	1000                	addi	s0,sp,32
    80002d5a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d5c:	00000097          	auipc	ra,0x0
    80002d60:	ef2080e7          	jalr	-270(ra) # 80002c4e <argraw>
    80002d64:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d66:	4501                	li	a0,0
    80002d68:	60e2                	ld	ra,24(sp)
    80002d6a:	6442                	ld	s0,16(sp)
    80002d6c:	64a2                	ld	s1,8(sp)
    80002d6e:	6105                	addi	sp,sp,32
    80002d70:	8082                	ret

0000000080002d72 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002d72:	1101                	addi	sp,sp,-32
    80002d74:	ec06                	sd	ra,24(sp)
    80002d76:	e822                	sd	s0,16(sp)
    80002d78:	e426                	sd	s1,8(sp)
    80002d7a:	1000                	addi	s0,sp,32
    80002d7c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d7e:	00000097          	auipc	ra,0x0
    80002d82:	ed0080e7          	jalr	-304(ra) # 80002c4e <argraw>
    80002d86:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d88:	4501                	li	a0,0
    80002d8a:	60e2                	ld	ra,24(sp)
    80002d8c:	6442                	ld	s0,16(sp)
    80002d8e:	64a2                	ld	s1,8(sp)
    80002d90:	6105                	addi	sp,sp,32
    80002d92:	8082                	ret

0000000080002d94 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d94:	1101                	addi	sp,sp,-32
    80002d96:	ec06                	sd	ra,24(sp)
    80002d98:	e822                	sd	s0,16(sp)
    80002d9a:	e426                	sd	s1,8(sp)
    80002d9c:	e04a                	sd	s2,0(sp)
    80002d9e:	1000                	addi	s0,sp,32
    80002da0:	84ae                	mv	s1,a1
    80002da2:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002da4:	00000097          	auipc	ra,0x0
    80002da8:	eaa080e7          	jalr	-342(ra) # 80002c4e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002dac:	864a                	mv	a2,s2
    80002dae:	85a6                	mv	a1,s1
    80002db0:	00000097          	auipc	ra,0x0
    80002db4:	f58080e7          	jalr	-168(ra) # 80002d08 <fetchstr>
}
    80002db8:	60e2                	ld	ra,24(sp)
    80002dba:	6442                	ld	s0,16(sp)
    80002dbc:	64a2                	ld	s1,8(sp)
    80002dbe:	6902                	ld	s2,0(sp)
    80002dc0:	6105                	addi	sp,sp,32
    80002dc2:	8082                	ret

0000000080002dc4 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002dc4:	1101                	addi	sp,sp,-32
    80002dc6:	ec06                	sd	ra,24(sp)
    80002dc8:	e822                	sd	s0,16(sp)
    80002dca:	e426                	sd	s1,8(sp)
    80002dcc:	e04a                	sd	s2,0(sp)
    80002dce:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002dd0:	fffff097          	auipc	ra,0xfffff
    80002dd4:	dac080e7          	jalr	-596(ra) # 80001b7c <myproc>
    80002dd8:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002dda:	05853903          	ld	s2,88(a0)
    80002dde:	0a893783          	ld	a5,168(s2)
    80002de2:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002de6:	37fd                	addiw	a5,a5,-1
    80002de8:	4751                	li	a4,20
    80002dea:	00f76f63          	bltu	a4,a5,80002e08 <syscall+0x44>
    80002dee:	00369713          	slli	a4,a3,0x3
    80002df2:	00005797          	auipc	a5,0x5
    80002df6:	65e78793          	addi	a5,a5,1630 # 80008450 <syscalls>
    80002dfa:	97ba                	add	a5,a5,a4
    80002dfc:	639c                	ld	a5,0(a5)
    80002dfe:	c789                	beqz	a5,80002e08 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e00:	9782                	jalr	a5
    80002e02:	06a93823          	sd	a0,112(s2)
    80002e06:	a839                	j	80002e24 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e08:	15848613          	addi	a2,s1,344
    80002e0c:	588c                	lw	a1,48(s1)
    80002e0e:	00005517          	auipc	a0,0x5
    80002e12:	60a50513          	addi	a0,a0,1546 # 80008418 <states.0+0x150>
    80002e16:	ffffd097          	auipc	ra,0xffffd
    80002e1a:	75e080e7          	jalr	1886(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e1e:	6cbc                	ld	a5,88(s1)
    80002e20:	577d                	li	a4,-1
    80002e22:	fbb8                	sd	a4,112(a5)
  }
}
    80002e24:	60e2                	ld	ra,24(sp)
    80002e26:	6442                	ld	s0,16(sp)
    80002e28:	64a2                	ld	s1,8(sp)
    80002e2a:	6902                	ld	s2,0(sp)
    80002e2c:	6105                	addi	sp,sp,32
    80002e2e:	8082                	ret

0000000080002e30 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e30:	1101                	addi	sp,sp,-32
    80002e32:	ec06                	sd	ra,24(sp)
    80002e34:	e822                	sd	s0,16(sp)
    80002e36:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e38:	fec40593          	addi	a1,s0,-20
    80002e3c:	4501                	li	a0,0
    80002e3e:	00000097          	auipc	ra,0x0
    80002e42:	f12080e7          	jalr	-238(ra) # 80002d50 <argint>
    return -1;
    80002e46:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e48:	00054963          	bltz	a0,80002e5a <sys_exit+0x2a>
  exit(n);
    80002e4c:	fec42503          	lw	a0,-20(s0)
    80002e50:	fffff097          	auipc	ra,0xfffff
    80002e54:	73a080e7          	jalr	1850(ra) # 8000258a <exit>
  return 0;  // not reached
    80002e58:	4781                	li	a5,0
}
    80002e5a:	853e                	mv	a0,a5
    80002e5c:	60e2                	ld	ra,24(sp)
    80002e5e:	6442                	ld	s0,16(sp)
    80002e60:	6105                	addi	sp,sp,32
    80002e62:	8082                	ret

0000000080002e64 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e64:	1141                	addi	sp,sp,-16
    80002e66:	e406                	sd	ra,8(sp)
    80002e68:	e022                	sd	s0,0(sp)
    80002e6a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e6c:	fffff097          	auipc	ra,0xfffff
    80002e70:	d10080e7          	jalr	-752(ra) # 80001b7c <myproc>
}
    80002e74:	5908                	lw	a0,48(a0)
    80002e76:	60a2                	ld	ra,8(sp)
    80002e78:	6402                	ld	s0,0(sp)
    80002e7a:	0141                	addi	sp,sp,16
    80002e7c:	8082                	ret

0000000080002e7e <sys_fork>:

uint64
sys_fork(void)
{
    80002e7e:	1141                	addi	sp,sp,-16
    80002e80:	e406                	sd	ra,8(sp)
    80002e82:	e022                	sd	s0,0(sp)
    80002e84:	0800                	addi	s0,sp,16
  return fork();
    80002e86:	fffff097          	auipc	ra,0xfffff
    80002e8a:	102080e7          	jalr	258(ra) # 80001f88 <fork>
}
    80002e8e:	60a2                	ld	ra,8(sp)
    80002e90:	6402                	ld	s0,0(sp)
    80002e92:	0141                	addi	sp,sp,16
    80002e94:	8082                	ret

0000000080002e96 <sys_wait>:

uint64
sys_wait(void)
{
    80002e96:	1101                	addi	sp,sp,-32
    80002e98:	ec06                	sd	ra,24(sp)
    80002e9a:	e822                	sd	s0,16(sp)
    80002e9c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e9e:	fe840593          	addi	a1,s0,-24
    80002ea2:	4501                	li	a0,0
    80002ea4:	00000097          	auipc	ra,0x0
    80002ea8:	ece080e7          	jalr	-306(ra) # 80002d72 <argaddr>
    80002eac:	87aa                	mv	a5,a0
    return -1;
    80002eae:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002eb0:	0007c863          	bltz	a5,80002ec0 <sys_wait+0x2a>
  return wait(p);
    80002eb4:	fe843503          	ld	a0,-24(s0)
    80002eb8:	fffff097          	auipc	ra,0xfffff
    80002ebc:	4da080e7          	jalr	1242(ra) # 80002392 <wait>
}
    80002ec0:	60e2                	ld	ra,24(sp)
    80002ec2:	6442                	ld	s0,16(sp)
    80002ec4:	6105                	addi	sp,sp,32
    80002ec6:	8082                	ret

0000000080002ec8 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ec8:	7179                	addi	sp,sp,-48
    80002eca:	f406                	sd	ra,40(sp)
    80002ecc:	f022                	sd	s0,32(sp)
    80002ece:	ec26                	sd	s1,24(sp)
    80002ed0:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002ed2:	fdc40593          	addi	a1,s0,-36
    80002ed6:	4501                	li	a0,0
    80002ed8:	00000097          	auipc	ra,0x0
    80002edc:	e78080e7          	jalr	-392(ra) # 80002d50 <argint>
    return -1;
    80002ee0:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002ee2:	00054f63          	bltz	a0,80002f00 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002ee6:	fffff097          	auipc	ra,0xfffff
    80002eea:	c96080e7          	jalr	-874(ra) # 80001b7c <myproc>
    80002eee:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002ef0:	fdc42503          	lw	a0,-36(s0)
    80002ef4:	fffff097          	auipc	ra,0xfffff
    80002ef8:	020080e7          	jalr	32(ra) # 80001f14 <growproc>
    80002efc:	00054863          	bltz	a0,80002f0c <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002f00:	8526                	mv	a0,s1
    80002f02:	70a2                	ld	ra,40(sp)
    80002f04:	7402                	ld	s0,32(sp)
    80002f06:	64e2                	ld	s1,24(sp)
    80002f08:	6145                	addi	sp,sp,48
    80002f0a:	8082                	ret
    return -1;
    80002f0c:	54fd                	li	s1,-1
    80002f0e:	bfcd                	j	80002f00 <sys_sbrk+0x38>

0000000080002f10 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f10:	7139                	addi	sp,sp,-64
    80002f12:	fc06                	sd	ra,56(sp)
    80002f14:	f822                	sd	s0,48(sp)
    80002f16:	f426                	sd	s1,40(sp)
    80002f18:	f04a                	sd	s2,32(sp)
    80002f1a:	ec4e                	sd	s3,24(sp)
    80002f1c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f1e:	fcc40593          	addi	a1,s0,-52
    80002f22:	4501                	li	a0,0
    80002f24:	00000097          	auipc	ra,0x0
    80002f28:	e2c080e7          	jalr	-468(ra) # 80002d50 <argint>
    return -1;
    80002f2c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f2e:	06054563          	bltz	a0,80002f98 <sys_sleep+0x88>
  acquire(&tickslock);
    80002f32:	00019517          	auipc	a0,0x19
    80002f36:	79e50513          	addi	a0,a0,1950 # 8001c6d0 <tickslock>
    80002f3a:	ffffe097          	auipc	ra,0xffffe
    80002f3e:	c88080e7          	jalr	-888(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80002f42:	00006917          	auipc	s2,0x6
    80002f46:	0ee92903          	lw	s2,238(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002f4a:	fcc42783          	lw	a5,-52(s0)
    80002f4e:	cf85                	beqz	a5,80002f86 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f50:	00019997          	auipc	s3,0x19
    80002f54:	78098993          	addi	s3,s3,1920 # 8001c6d0 <tickslock>
    80002f58:	00006497          	auipc	s1,0x6
    80002f5c:	0d848493          	addi	s1,s1,216 # 80009030 <ticks>
    if(myproc()->killed){
    80002f60:	fffff097          	auipc	ra,0xfffff
    80002f64:	c1c080e7          	jalr	-996(ra) # 80001b7c <myproc>
    80002f68:	551c                	lw	a5,40(a0)
    80002f6a:	ef9d                	bnez	a5,80002fa8 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f6c:	85ce                	mv	a1,s3
    80002f6e:	8526                	mv	a0,s1
    80002f70:	fffff097          	auipc	ra,0xfffff
    80002f74:	3be080e7          	jalr	958(ra) # 8000232e <sleep>
  while(ticks - ticks0 < n){
    80002f78:	409c                	lw	a5,0(s1)
    80002f7a:	412787bb          	subw	a5,a5,s2
    80002f7e:	fcc42703          	lw	a4,-52(s0)
    80002f82:	fce7efe3          	bltu	a5,a4,80002f60 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f86:	00019517          	auipc	a0,0x19
    80002f8a:	74a50513          	addi	a0,a0,1866 # 8001c6d0 <tickslock>
    80002f8e:	ffffe097          	auipc	ra,0xffffe
    80002f92:	ce8080e7          	jalr	-792(ra) # 80000c76 <release>
  return 0;
    80002f96:	4781                	li	a5,0
}
    80002f98:	853e                	mv	a0,a5
    80002f9a:	70e2                	ld	ra,56(sp)
    80002f9c:	7442                	ld	s0,48(sp)
    80002f9e:	74a2                	ld	s1,40(sp)
    80002fa0:	7902                	ld	s2,32(sp)
    80002fa2:	69e2                	ld	s3,24(sp)
    80002fa4:	6121                	addi	sp,sp,64
    80002fa6:	8082                	ret
      release(&tickslock);
    80002fa8:	00019517          	auipc	a0,0x19
    80002fac:	72850513          	addi	a0,a0,1832 # 8001c6d0 <tickslock>
    80002fb0:	ffffe097          	auipc	ra,0xffffe
    80002fb4:	cc6080e7          	jalr	-826(ra) # 80000c76 <release>
      return -1;
    80002fb8:	57fd                	li	a5,-1
    80002fba:	bff9                	j	80002f98 <sys_sleep+0x88>

0000000080002fbc <sys_kill>:

uint64
sys_kill(void)
{
    80002fbc:	1101                	addi	sp,sp,-32
    80002fbe:	ec06                	sd	ra,24(sp)
    80002fc0:	e822                	sd	s0,16(sp)
    80002fc2:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002fc4:	fec40593          	addi	a1,s0,-20
    80002fc8:	4501                	li	a0,0
    80002fca:	00000097          	auipc	ra,0x0
    80002fce:	d86080e7          	jalr	-634(ra) # 80002d50 <argint>
    80002fd2:	87aa                	mv	a5,a0
    return -1;
    80002fd4:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002fd6:	0007c863          	bltz	a5,80002fe6 <sys_kill+0x2a>
  return kill(pid);
    80002fda:	fec42503          	lw	a0,-20(s0)
    80002fde:	fffff097          	auipc	ra,0xfffff
    80002fe2:	682080e7          	jalr	1666(ra) # 80002660 <kill>
}
    80002fe6:	60e2                	ld	ra,24(sp)
    80002fe8:	6442                	ld	s0,16(sp)
    80002fea:	6105                	addi	sp,sp,32
    80002fec:	8082                	ret

0000000080002fee <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fee:	1101                	addi	sp,sp,-32
    80002ff0:	ec06                	sd	ra,24(sp)
    80002ff2:	e822                	sd	s0,16(sp)
    80002ff4:	e426                	sd	s1,8(sp)
    80002ff6:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ff8:	00019517          	auipc	a0,0x19
    80002ffc:	6d850513          	addi	a0,a0,1752 # 8001c6d0 <tickslock>
    80003000:	ffffe097          	auipc	ra,0xffffe
    80003004:	bc2080e7          	jalr	-1086(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80003008:	00006497          	auipc	s1,0x6
    8000300c:	0284a483          	lw	s1,40(s1) # 80009030 <ticks>
  release(&tickslock);
    80003010:	00019517          	auipc	a0,0x19
    80003014:	6c050513          	addi	a0,a0,1728 # 8001c6d0 <tickslock>
    80003018:	ffffe097          	auipc	ra,0xffffe
    8000301c:	c5e080e7          	jalr	-930(ra) # 80000c76 <release>
  return xticks;
}
    80003020:	02049513          	slli	a0,s1,0x20
    80003024:	9101                	srli	a0,a0,0x20
    80003026:	60e2                	ld	ra,24(sp)
    80003028:	6442                	ld	s0,16(sp)
    8000302a:	64a2                	ld	s1,8(sp)
    8000302c:	6105                	addi	sp,sp,32
    8000302e:	8082                	ret

0000000080003030 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003030:	7179                	addi	sp,sp,-48
    80003032:	f406                	sd	ra,40(sp)
    80003034:	f022                	sd	s0,32(sp)
    80003036:	ec26                	sd	s1,24(sp)
    80003038:	e84a                	sd	s2,16(sp)
    8000303a:	e44e                	sd	s3,8(sp)
    8000303c:	e052                	sd	s4,0(sp)
    8000303e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003040:	00005597          	auipc	a1,0x5
    80003044:	4c058593          	addi	a1,a1,1216 # 80008500 <syscalls+0xb0>
    80003048:	00019517          	auipc	a0,0x19
    8000304c:	6a050513          	addi	a0,a0,1696 # 8001c6e8 <bcache>
    80003050:	ffffe097          	auipc	ra,0xffffe
    80003054:	ae2080e7          	jalr	-1310(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003058:	00021797          	auipc	a5,0x21
    8000305c:	69078793          	addi	a5,a5,1680 # 800246e8 <bcache+0x8000>
    80003060:	00022717          	auipc	a4,0x22
    80003064:	8f070713          	addi	a4,a4,-1808 # 80024950 <bcache+0x8268>
    80003068:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000306c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003070:	00019497          	auipc	s1,0x19
    80003074:	69048493          	addi	s1,s1,1680 # 8001c700 <bcache+0x18>
    b->next = bcache.head.next;
    80003078:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000307a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000307c:	00005a17          	auipc	s4,0x5
    80003080:	48ca0a13          	addi	s4,s4,1164 # 80008508 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003084:	2b893783          	ld	a5,696(s2)
    80003088:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000308a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000308e:	85d2                	mv	a1,s4
    80003090:	01048513          	addi	a0,s1,16
    80003094:	00001097          	auipc	ra,0x1
    80003098:	7d4080e7          	jalr	2004(ra) # 80004868 <initsleeplock>
    bcache.head.next->prev = b;
    8000309c:	2b893783          	ld	a5,696(s2)
    800030a0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030a2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030a6:	45848493          	addi	s1,s1,1112
    800030aa:	fd349de3          	bne	s1,s3,80003084 <binit+0x54>
  }
}
    800030ae:	70a2                	ld	ra,40(sp)
    800030b0:	7402                	ld	s0,32(sp)
    800030b2:	64e2                	ld	s1,24(sp)
    800030b4:	6942                	ld	s2,16(sp)
    800030b6:	69a2                	ld	s3,8(sp)
    800030b8:	6a02                	ld	s4,0(sp)
    800030ba:	6145                	addi	sp,sp,48
    800030bc:	8082                	ret

00000000800030be <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030be:	7179                	addi	sp,sp,-48
    800030c0:	f406                	sd	ra,40(sp)
    800030c2:	f022                	sd	s0,32(sp)
    800030c4:	ec26                	sd	s1,24(sp)
    800030c6:	e84a                	sd	s2,16(sp)
    800030c8:	e44e                	sd	s3,8(sp)
    800030ca:	1800                	addi	s0,sp,48
    800030cc:	892a                	mv	s2,a0
    800030ce:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800030d0:	00019517          	auipc	a0,0x19
    800030d4:	61850513          	addi	a0,a0,1560 # 8001c6e8 <bcache>
    800030d8:	ffffe097          	auipc	ra,0xffffe
    800030dc:	aea080e7          	jalr	-1302(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030e0:	00022497          	auipc	s1,0x22
    800030e4:	8c04b483          	ld	s1,-1856(s1) # 800249a0 <bcache+0x82b8>
    800030e8:	00022797          	auipc	a5,0x22
    800030ec:	86878793          	addi	a5,a5,-1944 # 80024950 <bcache+0x8268>
    800030f0:	02f48f63          	beq	s1,a5,8000312e <bread+0x70>
    800030f4:	873e                	mv	a4,a5
    800030f6:	a021                	j	800030fe <bread+0x40>
    800030f8:	68a4                	ld	s1,80(s1)
    800030fa:	02e48a63          	beq	s1,a4,8000312e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030fe:	449c                	lw	a5,8(s1)
    80003100:	ff279ce3          	bne	a5,s2,800030f8 <bread+0x3a>
    80003104:	44dc                	lw	a5,12(s1)
    80003106:	ff3799e3          	bne	a5,s3,800030f8 <bread+0x3a>
      b->refcnt++;
    8000310a:	40bc                	lw	a5,64(s1)
    8000310c:	2785                	addiw	a5,a5,1
    8000310e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003110:	00019517          	auipc	a0,0x19
    80003114:	5d850513          	addi	a0,a0,1496 # 8001c6e8 <bcache>
    80003118:	ffffe097          	auipc	ra,0xffffe
    8000311c:	b5e080e7          	jalr	-1186(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003120:	01048513          	addi	a0,s1,16
    80003124:	00001097          	auipc	ra,0x1
    80003128:	77e080e7          	jalr	1918(ra) # 800048a2 <acquiresleep>
      return b;
    8000312c:	a8b9                	j	8000318a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000312e:	00022497          	auipc	s1,0x22
    80003132:	86a4b483          	ld	s1,-1942(s1) # 80024998 <bcache+0x82b0>
    80003136:	00022797          	auipc	a5,0x22
    8000313a:	81a78793          	addi	a5,a5,-2022 # 80024950 <bcache+0x8268>
    8000313e:	00f48863          	beq	s1,a5,8000314e <bread+0x90>
    80003142:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003144:	40bc                	lw	a5,64(s1)
    80003146:	cf81                	beqz	a5,8000315e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003148:	64a4                	ld	s1,72(s1)
    8000314a:	fee49de3          	bne	s1,a4,80003144 <bread+0x86>
  panic("bget: no buffers");
    8000314e:	00005517          	auipc	a0,0x5
    80003152:	3c250513          	addi	a0,a0,962 # 80008510 <syscalls+0xc0>
    80003156:	ffffd097          	auipc	ra,0xffffd
    8000315a:	3d4080e7          	jalr	980(ra) # 8000052a <panic>
      b->dev = dev;
    8000315e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003162:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003166:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000316a:	4785                	li	a5,1
    8000316c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000316e:	00019517          	auipc	a0,0x19
    80003172:	57a50513          	addi	a0,a0,1402 # 8001c6e8 <bcache>
    80003176:	ffffe097          	auipc	ra,0xffffe
    8000317a:	b00080e7          	jalr	-1280(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    8000317e:	01048513          	addi	a0,s1,16
    80003182:	00001097          	auipc	ra,0x1
    80003186:	720080e7          	jalr	1824(ra) # 800048a2 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000318a:	409c                	lw	a5,0(s1)
    8000318c:	cb89                	beqz	a5,8000319e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000318e:	8526                	mv	a0,s1
    80003190:	70a2                	ld	ra,40(sp)
    80003192:	7402                	ld	s0,32(sp)
    80003194:	64e2                	ld	s1,24(sp)
    80003196:	6942                	ld	s2,16(sp)
    80003198:	69a2                	ld	s3,8(sp)
    8000319a:	6145                	addi	sp,sp,48
    8000319c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000319e:	4581                	li	a1,0
    800031a0:	8526                	mv	a0,s1
    800031a2:	00003097          	auipc	ra,0x3
    800031a6:	444080e7          	jalr	1092(ra) # 800065e6 <virtio_disk_rw>
    b->valid = 1;
    800031aa:	4785                	li	a5,1
    800031ac:	c09c                	sw	a5,0(s1)
  return b;
    800031ae:	b7c5                	j	8000318e <bread+0xd0>

00000000800031b0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031b0:	1101                	addi	sp,sp,-32
    800031b2:	ec06                	sd	ra,24(sp)
    800031b4:	e822                	sd	s0,16(sp)
    800031b6:	e426                	sd	s1,8(sp)
    800031b8:	1000                	addi	s0,sp,32
    800031ba:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031bc:	0541                	addi	a0,a0,16
    800031be:	00001097          	auipc	ra,0x1
    800031c2:	77e080e7          	jalr	1918(ra) # 8000493c <holdingsleep>
    800031c6:	cd01                	beqz	a0,800031de <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031c8:	4585                	li	a1,1
    800031ca:	8526                	mv	a0,s1
    800031cc:	00003097          	auipc	ra,0x3
    800031d0:	41a080e7          	jalr	1050(ra) # 800065e6 <virtio_disk_rw>
}
    800031d4:	60e2                	ld	ra,24(sp)
    800031d6:	6442                	ld	s0,16(sp)
    800031d8:	64a2                	ld	s1,8(sp)
    800031da:	6105                	addi	sp,sp,32
    800031dc:	8082                	ret
    panic("bwrite");
    800031de:	00005517          	auipc	a0,0x5
    800031e2:	34a50513          	addi	a0,a0,842 # 80008528 <syscalls+0xd8>
    800031e6:	ffffd097          	auipc	ra,0xffffd
    800031ea:	344080e7          	jalr	836(ra) # 8000052a <panic>

00000000800031ee <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031ee:	1101                	addi	sp,sp,-32
    800031f0:	ec06                	sd	ra,24(sp)
    800031f2:	e822                	sd	s0,16(sp)
    800031f4:	e426                	sd	s1,8(sp)
    800031f6:	e04a                	sd	s2,0(sp)
    800031f8:	1000                	addi	s0,sp,32
    800031fa:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031fc:	01050913          	addi	s2,a0,16
    80003200:	854a                	mv	a0,s2
    80003202:	00001097          	auipc	ra,0x1
    80003206:	73a080e7          	jalr	1850(ra) # 8000493c <holdingsleep>
    8000320a:	c92d                	beqz	a0,8000327c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000320c:	854a                	mv	a0,s2
    8000320e:	00001097          	auipc	ra,0x1
    80003212:	6ea080e7          	jalr	1770(ra) # 800048f8 <releasesleep>

  acquire(&bcache.lock);
    80003216:	00019517          	auipc	a0,0x19
    8000321a:	4d250513          	addi	a0,a0,1234 # 8001c6e8 <bcache>
    8000321e:	ffffe097          	auipc	ra,0xffffe
    80003222:	9a4080e7          	jalr	-1628(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003226:	40bc                	lw	a5,64(s1)
    80003228:	37fd                	addiw	a5,a5,-1
    8000322a:	0007871b          	sext.w	a4,a5
    8000322e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003230:	eb05                	bnez	a4,80003260 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003232:	68bc                	ld	a5,80(s1)
    80003234:	64b8                	ld	a4,72(s1)
    80003236:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003238:	64bc                	ld	a5,72(s1)
    8000323a:	68b8                	ld	a4,80(s1)
    8000323c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000323e:	00021797          	auipc	a5,0x21
    80003242:	4aa78793          	addi	a5,a5,1194 # 800246e8 <bcache+0x8000>
    80003246:	2b87b703          	ld	a4,696(a5)
    8000324a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000324c:	00021717          	auipc	a4,0x21
    80003250:	70470713          	addi	a4,a4,1796 # 80024950 <bcache+0x8268>
    80003254:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003256:	2b87b703          	ld	a4,696(a5)
    8000325a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000325c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003260:	00019517          	auipc	a0,0x19
    80003264:	48850513          	addi	a0,a0,1160 # 8001c6e8 <bcache>
    80003268:	ffffe097          	auipc	ra,0xffffe
    8000326c:	a0e080e7          	jalr	-1522(ra) # 80000c76 <release>
}
    80003270:	60e2                	ld	ra,24(sp)
    80003272:	6442                	ld	s0,16(sp)
    80003274:	64a2                	ld	s1,8(sp)
    80003276:	6902                	ld	s2,0(sp)
    80003278:	6105                	addi	sp,sp,32
    8000327a:	8082                	ret
    panic("brelse");
    8000327c:	00005517          	auipc	a0,0x5
    80003280:	2b450513          	addi	a0,a0,692 # 80008530 <syscalls+0xe0>
    80003284:	ffffd097          	auipc	ra,0xffffd
    80003288:	2a6080e7          	jalr	678(ra) # 8000052a <panic>

000000008000328c <bpin>:

void
bpin(struct buf *b) {
    8000328c:	1101                	addi	sp,sp,-32
    8000328e:	ec06                	sd	ra,24(sp)
    80003290:	e822                	sd	s0,16(sp)
    80003292:	e426                	sd	s1,8(sp)
    80003294:	1000                	addi	s0,sp,32
    80003296:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003298:	00019517          	auipc	a0,0x19
    8000329c:	45050513          	addi	a0,a0,1104 # 8001c6e8 <bcache>
    800032a0:	ffffe097          	auipc	ra,0xffffe
    800032a4:	922080e7          	jalr	-1758(ra) # 80000bc2 <acquire>
  b->refcnt++;
    800032a8:	40bc                	lw	a5,64(s1)
    800032aa:	2785                	addiw	a5,a5,1
    800032ac:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032ae:	00019517          	auipc	a0,0x19
    800032b2:	43a50513          	addi	a0,a0,1082 # 8001c6e8 <bcache>
    800032b6:	ffffe097          	auipc	ra,0xffffe
    800032ba:	9c0080e7          	jalr	-1600(ra) # 80000c76 <release>
}
    800032be:	60e2                	ld	ra,24(sp)
    800032c0:	6442                	ld	s0,16(sp)
    800032c2:	64a2                	ld	s1,8(sp)
    800032c4:	6105                	addi	sp,sp,32
    800032c6:	8082                	ret

00000000800032c8 <bunpin>:

void
bunpin(struct buf *b) {
    800032c8:	1101                	addi	sp,sp,-32
    800032ca:	ec06                	sd	ra,24(sp)
    800032cc:	e822                	sd	s0,16(sp)
    800032ce:	e426                	sd	s1,8(sp)
    800032d0:	1000                	addi	s0,sp,32
    800032d2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032d4:	00019517          	auipc	a0,0x19
    800032d8:	41450513          	addi	a0,a0,1044 # 8001c6e8 <bcache>
    800032dc:	ffffe097          	auipc	ra,0xffffe
    800032e0:	8e6080e7          	jalr	-1818(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800032e4:	40bc                	lw	a5,64(s1)
    800032e6:	37fd                	addiw	a5,a5,-1
    800032e8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032ea:	00019517          	auipc	a0,0x19
    800032ee:	3fe50513          	addi	a0,a0,1022 # 8001c6e8 <bcache>
    800032f2:	ffffe097          	auipc	ra,0xffffe
    800032f6:	984080e7          	jalr	-1660(ra) # 80000c76 <release>
}
    800032fa:	60e2                	ld	ra,24(sp)
    800032fc:	6442                	ld	s0,16(sp)
    800032fe:	64a2                	ld	s1,8(sp)
    80003300:	6105                	addi	sp,sp,32
    80003302:	8082                	ret

0000000080003304 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003304:	1101                	addi	sp,sp,-32
    80003306:	ec06                	sd	ra,24(sp)
    80003308:	e822                	sd	s0,16(sp)
    8000330a:	e426                	sd	s1,8(sp)
    8000330c:	e04a                	sd	s2,0(sp)
    8000330e:	1000                	addi	s0,sp,32
    80003310:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003312:	00d5d59b          	srliw	a1,a1,0xd
    80003316:	00022797          	auipc	a5,0x22
    8000331a:	aae7a783          	lw	a5,-1362(a5) # 80024dc4 <sb+0x1c>
    8000331e:	9dbd                	addw	a1,a1,a5
    80003320:	00000097          	auipc	ra,0x0
    80003324:	d9e080e7          	jalr	-610(ra) # 800030be <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003328:	0074f713          	andi	a4,s1,7
    8000332c:	4785                	li	a5,1
    8000332e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003332:	14ce                	slli	s1,s1,0x33
    80003334:	90d9                	srli	s1,s1,0x36
    80003336:	00950733          	add	a4,a0,s1
    8000333a:	05874703          	lbu	a4,88(a4)
    8000333e:	00e7f6b3          	and	a3,a5,a4
    80003342:	c69d                	beqz	a3,80003370 <bfree+0x6c>
    80003344:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003346:	94aa                	add	s1,s1,a0
    80003348:	fff7c793          	not	a5,a5
    8000334c:	8ff9                	and	a5,a5,a4
    8000334e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003352:	00001097          	auipc	ra,0x1
    80003356:	430080e7          	jalr	1072(ra) # 80004782 <log_write>
  brelse(bp);
    8000335a:	854a                	mv	a0,s2
    8000335c:	00000097          	auipc	ra,0x0
    80003360:	e92080e7          	jalr	-366(ra) # 800031ee <brelse>
}
    80003364:	60e2                	ld	ra,24(sp)
    80003366:	6442                	ld	s0,16(sp)
    80003368:	64a2                	ld	s1,8(sp)
    8000336a:	6902                	ld	s2,0(sp)
    8000336c:	6105                	addi	sp,sp,32
    8000336e:	8082                	ret
    panic("freeing free block");
    80003370:	00005517          	auipc	a0,0x5
    80003374:	1c850513          	addi	a0,a0,456 # 80008538 <syscalls+0xe8>
    80003378:	ffffd097          	auipc	ra,0xffffd
    8000337c:	1b2080e7          	jalr	434(ra) # 8000052a <panic>

0000000080003380 <balloc>:
{
    80003380:	711d                	addi	sp,sp,-96
    80003382:	ec86                	sd	ra,88(sp)
    80003384:	e8a2                	sd	s0,80(sp)
    80003386:	e4a6                	sd	s1,72(sp)
    80003388:	e0ca                	sd	s2,64(sp)
    8000338a:	fc4e                	sd	s3,56(sp)
    8000338c:	f852                	sd	s4,48(sp)
    8000338e:	f456                	sd	s5,40(sp)
    80003390:	f05a                	sd	s6,32(sp)
    80003392:	ec5e                	sd	s7,24(sp)
    80003394:	e862                	sd	s8,16(sp)
    80003396:	e466                	sd	s9,8(sp)
    80003398:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000339a:	00022797          	auipc	a5,0x22
    8000339e:	a127a783          	lw	a5,-1518(a5) # 80024dac <sb+0x4>
    800033a2:	cbd1                	beqz	a5,80003436 <balloc+0xb6>
    800033a4:	8baa                	mv	s7,a0
    800033a6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033a8:	00022b17          	auipc	s6,0x22
    800033ac:	a00b0b13          	addi	s6,s6,-1536 # 80024da8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033b0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033b2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033b4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033b6:	6c89                	lui	s9,0x2
    800033b8:	a831                	j	800033d4 <balloc+0x54>
    brelse(bp);
    800033ba:	854a                	mv	a0,s2
    800033bc:	00000097          	auipc	ra,0x0
    800033c0:	e32080e7          	jalr	-462(ra) # 800031ee <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033c4:	015c87bb          	addw	a5,s9,s5
    800033c8:	00078a9b          	sext.w	s5,a5
    800033cc:	004b2703          	lw	a4,4(s6)
    800033d0:	06eaf363          	bgeu	s5,a4,80003436 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800033d4:	41fad79b          	sraiw	a5,s5,0x1f
    800033d8:	0137d79b          	srliw	a5,a5,0x13
    800033dc:	015787bb          	addw	a5,a5,s5
    800033e0:	40d7d79b          	sraiw	a5,a5,0xd
    800033e4:	01cb2583          	lw	a1,28(s6)
    800033e8:	9dbd                	addw	a1,a1,a5
    800033ea:	855e                	mv	a0,s7
    800033ec:	00000097          	auipc	ra,0x0
    800033f0:	cd2080e7          	jalr	-814(ra) # 800030be <bread>
    800033f4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033f6:	004b2503          	lw	a0,4(s6)
    800033fa:	000a849b          	sext.w	s1,s5
    800033fe:	8662                	mv	a2,s8
    80003400:	faa4fde3          	bgeu	s1,a0,800033ba <balloc+0x3a>
      m = 1 << (bi % 8);
    80003404:	41f6579b          	sraiw	a5,a2,0x1f
    80003408:	01d7d69b          	srliw	a3,a5,0x1d
    8000340c:	00c6873b          	addw	a4,a3,a2
    80003410:	00777793          	andi	a5,a4,7
    80003414:	9f95                	subw	a5,a5,a3
    80003416:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000341a:	4037571b          	sraiw	a4,a4,0x3
    8000341e:	00e906b3          	add	a3,s2,a4
    80003422:	0586c683          	lbu	a3,88(a3)
    80003426:	00d7f5b3          	and	a1,a5,a3
    8000342a:	cd91                	beqz	a1,80003446 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000342c:	2605                	addiw	a2,a2,1
    8000342e:	2485                	addiw	s1,s1,1
    80003430:	fd4618e3          	bne	a2,s4,80003400 <balloc+0x80>
    80003434:	b759                	j	800033ba <balloc+0x3a>
  panic("balloc: out of blocks");
    80003436:	00005517          	auipc	a0,0x5
    8000343a:	11a50513          	addi	a0,a0,282 # 80008550 <syscalls+0x100>
    8000343e:	ffffd097          	auipc	ra,0xffffd
    80003442:	0ec080e7          	jalr	236(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003446:	974a                	add	a4,a4,s2
    80003448:	8fd5                	or	a5,a5,a3
    8000344a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000344e:	854a                	mv	a0,s2
    80003450:	00001097          	auipc	ra,0x1
    80003454:	332080e7          	jalr	818(ra) # 80004782 <log_write>
        brelse(bp);
    80003458:	854a                	mv	a0,s2
    8000345a:	00000097          	auipc	ra,0x0
    8000345e:	d94080e7          	jalr	-620(ra) # 800031ee <brelse>
  bp = bread(dev, bno);
    80003462:	85a6                	mv	a1,s1
    80003464:	855e                	mv	a0,s7
    80003466:	00000097          	auipc	ra,0x0
    8000346a:	c58080e7          	jalr	-936(ra) # 800030be <bread>
    8000346e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003470:	40000613          	li	a2,1024
    80003474:	4581                	li	a1,0
    80003476:	05850513          	addi	a0,a0,88
    8000347a:	ffffe097          	auipc	ra,0xffffe
    8000347e:	844080e7          	jalr	-1980(ra) # 80000cbe <memset>
  log_write(bp);
    80003482:	854a                	mv	a0,s2
    80003484:	00001097          	auipc	ra,0x1
    80003488:	2fe080e7          	jalr	766(ra) # 80004782 <log_write>
  brelse(bp);
    8000348c:	854a                	mv	a0,s2
    8000348e:	00000097          	auipc	ra,0x0
    80003492:	d60080e7          	jalr	-672(ra) # 800031ee <brelse>
}
    80003496:	8526                	mv	a0,s1
    80003498:	60e6                	ld	ra,88(sp)
    8000349a:	6446                	ld	s0,80(sp)
    8000349c:	64a6                	ld	s1,72(sp)
    8000349e:	6906                	ld	s2,64(sp)
    800034a0:	79e2                	ld	s3,56(sp)
    800034a2:	7a42                	ld	s4,48(sp)
    800034a4:	7aa2                	ld	s5,40(sp)
    800034a6:	7b02                	ld	s6,32(sp)
    800034a8:	6be2                	ld	s7,24(sp)
    800034aa:	6c42                	ld	s8,16(sp)
    800034ac:	6ca2                	ld	s9,8(sp)
    800034ae:	6125                	addi	sp,sp,96
    800034b0:	8082                	ret

00000000800034b2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034b2:	7179                	addi	sp,sp,-48
    800034b4:	f406                	sd	ra,40(sp)
    800034b6:	f022                	sd	s0,32(sp)
    800034b8:	ec26                	sd	s1,24(sp)
    800034ba:	e84a                	sd	s2,16(sp)
    800034bc:	e44e                	sd	s3,8(sp)
    800034be:	e052                	sd	s4,0(sp)
    800034c0:	1800                	addi	s0,sp,48
    800034c2:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034c4:	47ad                	li	a5,11
    800034c6:	04b7fe63          	bgeu	a5,a1,80003522 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034ca:	ff45849b          	addiw	s1,a1,-12
    800034ce:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034d2:	0ff00793          	li	a5,255
    800034d6:	0ae7e463          	bltu	a5,a4,8000357e <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034da:	08052583          	lw	a1,128(a0)
    800034de:	c5b5                	beqz	a1,8000354a <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800034e0:	00092503          	lw	a0,0(s2)
    800034e4:	00000097          	auipc	ra,0x0
    800034e8:	bda080e7          	jalr	-1062(ra) # 800030be <bread>
    800034ec:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034ee:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034f2:	02049713          	slli	a4,s1,0x20
    800034f6:	01e75593          	srli	a1,a4,0x1e
    800034fa:	00b784b3          	add	s1,a5,a1
    800034fe:	0004a983          	lw	s3,0(s1)
    80003502:	04098e63          	beqz	s3,8000355e <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003506:	8552                	mv	a0,s4
    80003508:	00000097          	auipc	ra,0x0
    8000350c:	ce6080e7          	jalr	-794(ra) # 800031ee <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003510:	854e                	mv	a0,s3
    80003512:	70a2                	ld	ra,40(sp)
    80003514:	7402                	ld	s0,32(sp)
    80003516:	64e2                	ld	s1,24(sp)
    80003518:	6942                	ld	s2,16(sp)
    8000351a:	69a2                	ld	s3,8(sp)
    8000351c:	6a02                	ld	s4,0(sp)
    8000351e:	6145                	addi	sp,sp,48
    80003520:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003522:	02059793          	slli	a5,a1,0x20
    80003526:	01e7d593          	srli	a1,a5,0x1e
    8000352a:	00b504b3          	add	s1,a0,a1
    8000352e:	0504a983          	lw	s3,80(s1)
    80003532:	fc099fe3          	bnez	s3,80003510 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003536:	4108                	lw	a0,0(a0)
    80003538:	00000097          	auipc	ra,0x0
    8000353c:	e48080e7          	jalr	-440(ra) # 80003380 <balloc>
    80003540:	0005099b          	sext.w	s3,a0
    80003544:	0534a823          	sw	s3,80(s1)
    80003548:	b7e1                	j	80003510 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000354a:	4108                	lw	a0,0(a0)
    8000354c:	00000097          	auipc	ra,0x0
    80003550:	e34080e7          	jalr	-460(ra) # 80003380 <balloc>
    80003554:	0005059b          	sext.w	a1,a0
    80003558:	08b92023          	sw	a1,128(s2)
    8000355c:	b751                	j	800034e0 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000355e:	00092503          	lw	a0,0(s2)
    80003562:	00000097          	auipc	ra,0x0
    80003566:	e1e080e7          	jalr	-482(ra) # 80003380 <balloc>
    8000356a:	0005099b          	sext.w	s3,a0
    8000356e:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003572:	8552                	mv	a0,s4
    80003574:	00001097          	auipc	ra,0x1
    80003578:	20e080e7          	jalr	526(ra) # 80004782 <log_write>
    8000357c:	b769                	j	80003506 <bmap+0x54>
  panic("bmap: out of range");
    8000357e:	00005517          	auipc	a0,0x5
    80003582:	fea50513          	addi	a0,a0,-22 # 80008568 <syscalls+0x118>
    80003586:	ffffd097          	auipc	ra,0xffffd
    8000358a:	fa4080e7          	jalr	-92(ra) # 8000052a <panic>

000000008000358e <iget>:
{
    8000358e:	7179                	addi	sp,sp,-48
    80003590:	f406                	sd	ra,40(sp)
    80003592:	f022                	sd	s0,32(sp)
    80003594:	ec26                	sd	s1,24(sp)
    80003596:	e84a                	sd	s2,16(sp)
    80003598:	e44e                	sd	s3,8(sp)
    8000359a:	e052                	sd	s4,0(sp)
    8000359c:	1800                	addi	s0,sp,48
    8000359e:	89aa                	mv	s3,a0
    800035a0:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800035a2:	00022517          	auipc	a0,0x22
    800035a6:	82650513          	addi	a0,a0,-2010 # 80024dc8 <itable>
    800035aa:	ffffd097          	auipc	ra,0xffffd
    800035ae:	618080e7          	jalr	1560(ra) # 80000bc2 <acquire>
  empty = 0;
    800035b2:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035b4:	00022497          	auipc	s1,0x22
    800035b8:	82c48493          	addi	s1,s1,-2004 # 80024de0 <itable+0x18>
    800035bc:	00023697          	auipc	a3,0x23
    800035c0:	2b468693          	addi	a3,a3,692 # 80026870 <log>
    800035c4:	a039                	j	800035d2 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035c6:	02090b63          	beqz	s2,800035fc <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035ca:	08848493          	addi	s1,s1,136
    800035ce:	02d48a63          	beq	s1,a3,80003602 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035d2:	449c                	lw	a5,8(s1)
    800035d4:	fef059e3          	blez	a5,800035c6 <iget+0x38>
    800035d8:	4098                	lw	a4,0(s1)
    800035da:	ff3716e3          	bne	a4,s3,800035c6 <iget+0x38>
    800035de:	40d8                	lw	a4,4(s1)
    800035e0:	ff4713e3          	bne	a4,s4,800035c6 <iget+0x38>
      ip->ref++;
    800035e4:	2785                	addiw	a5,a5,1
    800035e6:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035e8:	00021517          	auipc	a0,0x21
    800035ec:	7e050513          	addi	a0,a0,2016 # 80024dc8 <itable>
    800035f0:	ffffd097          	auipc	ra,0xffffd
    800035f4:	686080e7          	jalr	1670(ra) # 80000c76 <release>
      return ip;
    800035f8:	8926                	mv	s2,s1
    800035fa:	a03d                	j	80003628 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035fc:	f7f9                	bnez	a5,800035ca <iget+0x3c>
    800035fe:	8926                	mv	s2,s1
    80003600:	b7e9                	j	800035ca <iget+0x3c>
  if(empty == 0)
    80003602:	02090c63          	beqz	s2,8000363a <iget+0xac>
  ip->dev = dev;
    80003606:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000360a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000360e:	4785                	li	a5,1
    80003610:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003614:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003618:	00021517          	auipc	a0,0x21
    8000361c:	7b050513          	addi	a0,a0,1968 # 80024dc8 <itable>
    80003620:	ffffd097          	auipc	ra,0xffffd
    80003624:	656080e7          	jalr	1622(ra) # 80000c76 <release>
}
    80003628:	854a                	mv	a0,s2
    8000362a:	70a2                	ld	ra,40(sp)
    8000362c:	7402                	ld	s0,32(sp)
    8000362e:	64e2                	ld	s1,24(sp)
    80003630:	6942                	ld	s2,16(sp)
    80003632:	69a2                	ld	s3,8(sp)
    80003634:	6a02                	ld	s4,0(sp)
    80003636:	6145                	addi	sp,sp,48
    80003638:	8082                	ret
    panic("iget: no inodes");
    8000363a:	00005517          	auipc	a0,0x5
    8000363e:	f4650513          	addi	a0,a0,-186 # 80008580 <syscalls+0x130>
    80003642:	ffffd097          	auipc	ra,0xffffd
    80003646:	ee8080e7          	jalr	-280(ra) # 8000052a <panic>

000000008000364a <fsinit>:
fsinit(int dev) {
    8000364a:	7179                	addi	sp,sp,-48
    8000364c:	f406                	sd	ra,40(sp)
    8000364e:	f022                	sd	s0,32(sp)
    80003650:	ec26                	sd	s1,24(sp)
    80003652:	e84a                	sd	s2,16(sp)
    80003654:	e44e                	sd	s3,8(sp)
    80003656:	1800                	addi	s0,sp,48
    80003658:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000365a:	4585                	li	a1,1
    8000365c:	00000097          	auipc	ra,0x0
    80003660:	a62080e7          	jalr	-1438(ra) # 800030be <bread>
    80003664:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003666:	00021997          	auipc	s3,0x21
    8000366a:	74298993          	addi	s3,s3,1858 # 80024da8 <sb>
    8000366e:	02000613          	li	a2,32
    80003672:	05850593          	addi	a1,a0,88
    80003676:	854e                	mv	a0,s3
    80003678:	ffffd097          	auipc	ra,0xffffd
    8000367c:	6a2080e7          	jalr	1698(ra) # 80000d1a <memmove>
  brelse(bp);
    80003680:	8526                	mv	a0,s1
    80003682:	00000097          	auipc	ra,0x0
    80003686:	b6c080e7          	jalr	-1172(ra) # 800031ee <brelse>
  if(sb.magic != FSMAGIC)
    8000368a:	0009a703          	lw	a4,0(s3)
    8000368e:	102037b7          	lui	a5,0x10203
    80003692:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003696:	02f71263          	bne	a4,a5,800036ba <fsinit+0x70>
  initlog(dev, &sb);
    8000369a:	00021597          	auipc	a1,0x21
    8000369e:	70e58593          	addi	a1,a1,1806 # 80024da8 <sb>
    800036a2:	854a                	mv	a0,s2
    800036a4:	00001097          	auipc	ra,0x1
    800036a8:	e60080e7          	jalr	-416(ra) # 80004504 <initlog>
}
    800036ac:	70a2                	ld	ra,40(sp)
    800036ae:	7402                	ld	s0,32(sp)
    800036b0:	64e2                	ld	s1,24(sp)
    800036b2:	6942                	ld	s2,16(sp)
    800036b4:	69a2                	ld	s3,8(sp)
    800036b6:	6145                	addi	sp,sp,48
    800036b8:	8082                	ret
    panic("invalid file system");
    800036ba:	00005517          	auipc	a0,0x5
    800036be:	ed650513          	addi	a0,a0,-298 # 80008590 <syscalls+0x140>
    800036c2:	ffffd097          	auipc	ra,0xffffd
    800036c6:	e68080e7          	jalr	-408(ra) # 8000052a <panic>

00000000800036ca <iinit>:
{
    800036ca:	7179                	addi	sp,sp,-48
    800036cc:	f406                	sd	ra,40(sp)
    800036ce:	f022                	sd	s0,32(sp)
    800036d0:	ec26                	sd	s1,24(sp)
    800036d2:	e84a                	sd	s2,16(sp)
    800036d4:	e44e                	sd	s3,8(sp)
    800036d6:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036d8:	00005597          	auipc	a1,0x5
    800036dc:	ed058593          	addi	a1,a1,-304 # 800085a8 <syscalls+0x158>
    800036e0:	00021517          	auipc	a0,0x21
    800036e4:	6e850513          	addi	a0,a0,1768 # 80024dc8 <itable>
    800036e8:	ffffd097          	auipc	ra,0xffffd
    800036ec:	44a080e7          	jalr	1098(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    800036f0:	00021497          	auipc	s1,0x21
    800036f4:	70048493          	addi	s1,s1,1792 # 80024df0 <itable+0x28>
    800036f8:	00023997          	auipc	s3,0x23
    800036fc:	18898993          	addi	s3,s3,392 # 80026880 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003700:	00005917          	auipc	s2,0x5
    80003704:	eb090913          	addi	s2,s2,-336 # 800085b0 <syscalls+0x160>
    80003708:	85ca                	mv	a1,s2
    8000370a:	8526                	mv	a0,s1
    8000370c:	00001097          	auipc	ra,0x1
    80003710:	15c080e7          	jalr	348(ra) # 80004868 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003714:	08848493          	addi	s1,s1,136
    80003718:	ff3498e3          	bne	s1,s3,80003708 <iinit+0x3e>
}
    8000371c:	70a2                	ld	ra,40(sp)
    8000371e:	7402                	ld	s0,32(sp)
    80003720:	64e2                	ld	s1,24(sp)
    80003722:	6942                	ld	s2,16(sp)
    80003724:	69a2                	ld	s3,8(sp)
    80003726:	6145                	addi	sp,sp,48
    80003728:	8082                	ret

000000008000372a <ialloc>:
{
    8000372a:	715d                	addi	sp,sp,-80
    8000372c:	e486                	sd	ra,72(sp)
    8000372e:	e0a2                	sd	s0,64(sp)
    80003730:	fc26                	sd	s1,56(sp)
    80003732:	f84a                	sd	s2,48(sp)
    80003734:	f44e                	sd	s3,40(sp)
    80003736:	f052                	sd	s4,32(sp)
    80003738:	ec56                	sd	s5,24(sp)
    8000373a:	e85a                	sd	s6,16(sp)
    8000373c:	e45e                	sd	s7,8(sp)
    8000373e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003740:	00021717          	auipc	a4,0x21
    80003744:	67472703          	lw	a4,1652(a4) # 80024db4 <sb+0xc>
    80003748:	4785                	li	a5,1
    8000374a:	04e7fa63          	bgeu	a5,a4,8000379e <ialloc+0x74>
    8000374e:	8aaa                	mv	s5,a0
    80003750:	8bae                	mv	s7,a1
    80003752:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003754:	00021a17          	auipc	s4,0x21
    80003758:	654a0a13          	addi	s4,s4,1620 # 80024da8 <sb>
    8000375c:	00048b1b          	sext.w	s6,s1
    80003760:	0044d793          	srli	a5,s1,0x4
    80003764:	018a2583          	lw	a1,24(s4)
    80003768:	9dbd                	addw	a1,a1,a5
    8000376a:	8556                	mv	a0,s5
    8000376c:	00000097          	auipc	ra,0x0
    80003770:	952080e7          	jalr	-1710(ra) # 800030be <bread>
    80003774:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003776:	05850993          	addi	s3,a0,88
    8000377a:	00f4f793          	andi	a5,s1,15
    8000377e:	079a                	slli	a5,a5,0x6
    80003780:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003782:	00099783          	lh	a5,0(s3)
    80003786:	c785                	beqz	a5,800037ae <ialloc+0x84>
    brelse(bp);
    80003788:	00000097          	auipc	ra,0x0
    8000378c:	a66080e7          	jalr	-1434(ra) # 800031ee <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003790:	0485                	addi	s1,s1,1
    80003792:	00ca2703          	lw	a4,12(s4)
    80003796:	0004879b          	sext.w	a5,s1
    8000379a:	fce7e1e3          	bltu	a5,a4,8000375c <ialloc+0x32>
  panic("ialloc: no inodes");
    8000379e:	00005517          	auipc	a0,0x5
    800037a2:	e1a50513          	addi	a0,a0,-486 # 800085b8 <syscalls+0x168>
    800037a6:	ffffd097          	auipc	ra,0xffffd
    800037aa:	d84080e7          	jalr	-636(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    800037ae:	04000613          	li	a2,64
    800037b2:	4581                	li	a1,0
    800037b4:	854e                	mv	a0,s3
    800037b6:	ffffd097          	auipc	ra,0xffffd
    800037ba:	508080e7          	jalr	1288(ra) # 80000cbe <memset>
      dip->type = type;
    800037be:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037c2:	854a                	mv	a0,s2
    800037c4:	00001097          	auipc	ra,0x1
    800037c8:	fbe080e7          	jalr	-66(ra) # 80004782 <log_write>
      brelse(bp);
    800037cc:	854a                	mv	a0,s2
    800037ce:	00000097          	auipc	ra,0x0
    800037d2:	a20080e7          	jalr	-1504(ra) # 800031ee <brelse>
      return iget(dev, inum);
    800037d6:	85da                	mv	a1,s6
    800037d8:	8556                	mv	a0,s5
    800037da:	00000097          	auipc	ra,0x0
    800037de:	db4080e7          	jalr	-588(ra) # 8000358e <iget>
}
    800037e2:	60a6                	ld	ra,72(sp)
    800037e4:	6406                	ld	s0,64(sp)
    800037e6:	74e2                	ld	s1,56(sp)
    800037e8:	7942                	ld	s2,48(sp)
    800037ea:	79a2                	ld	s3,40(sp)
    800037ec:	7a02                	ld	s4,32(sp)
    800037ee:	6ae2                	ld	s5,24(sp)
    800037f0:	6b42                	ld	s6,16(sp)
    800037f2:	6ba2                	ld	s7,8(sp)
    800037f4:	6161                	addi	sp,sp,80
    800037f6:	8082                	ret

00000000800037f8 <iupdate>:
{
    800037f8:	1101                	addi	sp,sp,-32
    800037fa:	ec06                	sd	ra,24(sp)
    800037fc:	e822                	sd	s0,16(sp)
    800037fe:	e426                	sd	s1,8(sp)
    80003800:	e04a                	sd	s2,0(sp)
    80003802:	1000                	addi	s0,sp,32
    80003804:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003806:	415c                	lw	a5,4(a0)
    80003808:	0047d79b          	srliw	a5,a5,0x4
    8000380c:	00021597          	auipc	a1,0x21
    80003810:	5b45a583          	lw	a1,1460(a1) # 80024dc0 <sb+0x18>
    80003814:	9dbd                	addw	a1,a1,a5
    80003816:	4108                	lw	a0,0(a0)
    80003818:	00000097          	auipc	ra,0x0
    8000381c:	8a6080e7          	jalr	-1882(ra) # 800030be <bread>
    80003820:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003822:	05850793          	addi	a5,a0,88
    80003826:	40c8                	lw	a0,4(s1)
    80003828:	893d                	andi	a0,a0,15
    8000382a:	051a                	slli	a0,a0,0x6
    8000382c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000382e:	04449703          	lh	a4,68(s1)
    80003832:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003836:	04649703          	lh	a4,70(s1)
    8000383a:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000383e:	04849703          	lh	a4,72(s1)
    80003842:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003846:	04a49703          	lh	a4,74(s1)
    8000384a:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000384e:	44f8                	lw	a4,76(s1)
    80003850:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003852:	03400613          	li	a2,52
    80003856:	05048593          	addi	a1,s1,80
    8000385a:	0531                	addi	a0,a0,12
    8000385c:	ffffd097          	auipc	ra,0xffffd
    80003860:	4be080e7          	jalr	1214(ra) # 80000d1a <memmove>
  log_write(bp);
    80003864:	854a                	mv	a0,s2
    80003866:	00001097          	auipc	ra,0x1
    8000386a:	f1c080e7          	jalr	-228(ra) # 80004782 <log_write>
  brelse(bp);
    8000386e:	854a                	mv	a0,s2
    80003870:	00000097          	auipc	ra,0x0
    80003874:	97e080e7          	jalr	-1666(ra) # 800031ee <brelse>
}
    80003878:	60e2                	ld	ra,24(sp)
    8000387a:	6442                	ld	s0,16(sp)
    8000387c:	64a2                	ld	s1,8(sp)
    8000387e:	6902                	ld	s2,0(sp)
    80003880:	6105                	addi	sp,sp,32
    80003882:	8082                	ret

0000000080003884 <idup>:
{
    80003884:	1101                	addi	sp,sp,-32
    80003886:	ec06                	sd	ra,24(sp)
    80003888:	e822                	sd	s0,16(sp)
    8000388a:	e426                	sd	s1,8(sp)
    8000388c:	1000                	addi	s0,sp,32
    8000388e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003890:	00021517          	auipc	a0,0x21
    80003894:	53850513          	addi	a0,a0,1336 # 80024dc8 <itable>
    80003898:	ffffd097          	auipc	ra,0xffffd
    8000389c:	32a080e7          	jalr	810(ra) # 80000bc2 <acquire>
  ip->ref++;
    800038a0:	449c                	lw	a5,8(s1)
    800038a2:	2785                	addiw	a5,a5,1
    800038a4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038a6:	00021517          	auipc	a0,0x21
    800038aa:	52250513          	addi	a0,a0,1314 # 80024dc8 <itable>
    800038ae:	ffffd097          	auipc	ra,0xffffd
    800038b2:	3c8080e7          	jalr	968(ra) # 80000c76 <release>
}
    800038b6:	8526                	mv	a0,s1
    800038b8:	60e2                	ld	ra,24(sp)
    800038ba:	6442                	ld	s0,16(sp)
    800038bc:	64a2                	ld	s1,8(sp)
    800038be:	6105                	addi	sp,sp,32
    800038c0:	8082                	ret

00000000800038c2 <ilock>:
{
    800038c2:	1101                	addi	sp,sp,-32
    800038c4:	ec06                	sd	ra,24(sp)
    800038c6:	e822                	sd	s0,16(sp)
    800038c8:	e426                	sd	s1,8(sp)
    800038ca:	e04a                	sd	s2,0(sp)
    800038cc:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038ce:	c115                	beqz	a0,800038f2 <ilock+0x30>
    800038d0:	84aa                	mv	s1,a0
    800038d2:	451c                	lw	a5,8(a0)
    800038d4:	00f05f63          	blez	a5,800038f2 <ilock+0x30>
  acquiresleep(&ip->lock);
    800038d8:	0541                	addi	a0,a0,16
    800038da:	00001097          	auipc	ra,0x1
    800038de:	fc8080e7          	jalr	-56(ra) # 800048a2 <acquiresleep>
  if(ip->valid == 0){
    800038e2:	40bc                	lw	a5,64(s1)
    800038e4:	cf99                	beqz	a5,80003902 <ilock+0x40>
}
    800038e6:	60e2                	ld	ra,24(sp)
    800038e8:	6442                	ld	s0,16(sp)
    800038ea:	64a2                	ld	s1,8(sp)
    800038ec:	6902                	ld	s2,0(sp)
    800038ee:	6105                	addi	sp,sp,32
    800038f0:	8082                	ret
    panic("ilock");
    800038f2:	00005517          	auipc	a0,0x5
    800038f6:	cde50513          	addi	a0,a0,-802 # 800085d0 <syscalls+0x180>
    800038fa:	ffffd097          	auipc	ra,0xffffd
    800038fe:	c30080e7          	jalr	-976(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003902:	40dc                	lw	a5,4(s1)
    80003904:	0047d79b          	srliw	a5,a5,0x4
    80003908:	00021597          	auipc	a1,0x21
    8000390c:	4b85a583          	lw	a1,1208(a1) # 80024dc0 <sb+0x18>
    80003910:	9dbd                	addw	a1,a1,a5
    80003912:	4088                	lw	a0,0(s1)
    80003914:	fffff097          	auipc	ra,0xfffff
    80003918:	7aa080e7          	jalr	1962(ra) # 800030be <bread>
    8000391c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000391e:	05850593          	addi	a1,a0,88
    80003922:	40dc                	lw	a5,4(s1)
    80003924:	8bbd                	andi	a5,a5,15
    80003926:	079a                	slli	a5,a5,0x6
    80003928:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000392a:	00059783          	lh	a5,0(a1)
    8000392e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003932:	00259783          	lh	a5,2(a1)
    80003936:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000393a:	00459783          	lh	a5,4(a1)
    8000393e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003942:	00659783          	lh	a5,6(a1)
    80003946:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000394a:	459c                	lw	a5,8(a1)
    8000394c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000394e:	03400613          	li	a2,52
    80003952:	05b1                	addi	a1,a1,12
    80003954:	05048513          	addi	a0,s1,80
    80003958:	ffffd097          	auipc	ra,0xffffd
    8000395c:	3c2080e7          	jalr	962(ra) # 80000d1a <memmove>
    brelse(bp);
    80003960:	854a                	mv	a0,s2
    80003962:	00000097          	auipc	ra,0x0
    80003966:	88c080e7          	jalr	-1908(ra) # 800031ee <brelse>
    ip->valid = 1;
    8000396a:	4785                	li	a5,1
    8000396c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000396e:	04449783          	lh	a5,68(s1)
    80003972:	fbb5                	bnez	a5,800038e6 <ilock+0x24>
      panic("ilock: no type");
    80003974:	00005517          	auipc	a0,0x5
    80003978:	c6450513          	addi	a0,a0,-924 # 800085d8 <syscalls+0x188>
    8000397c:	ffffd097          	auipc	ra,0xffffd
    80003980:	bae080e7          	jalr	-1106(ra) # 8000052a <panic>

0000000080003984 <iunlock>:
{
    80003984:	1101                	addi	sp,sp,-32
    80003986:	ec06                	sd	ra,24(sp)
    80003988:	e822                	sd	s0,16(sp)
    8000398a:	e426                	sd	s1,8(sp)
    8000398c:	e04a                	sd	s2,0(sp)
    8000398e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003990:	c905                	beqz	a0,800039c0 <iunlock+0x3c>
    80003992:	84aa                	mv	s1,a0
    80003994:	01050913          	addi	s2,a0,16
    80003998:	854a                	mv	a0,s2
    8000399a:	00001097          	auipc	ra,0x1
    8000399e:	fa2080e7          	jalr	-94(ra) # 8000493c <holdingsleep>
    800039a2:	cd19                	beqz	a0,800039c0 <iunlock+0x3c>
    800039a4:	449c                	lw	a5,8(s1)
    800039a6:	00f05d63          	blez	a5,800039c0 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039aa:	854a                	mv	a0,s2
    800039ac:	00001097          	auipc	ra,0x1
    800039b0:	f4c080e7          	jalr	-180(ra) # 800048f8 <releasesleep>
}
    800039b4:	60e2                	ld	ra,24(sp)
    800039b6:	6442                	ld	s0,16(sp)
    800039b8:	64a2                	ld	s1,8(sp)
    800039ba:	6902                	ld	s2,0(sp)
    800039bc:	6105                	addi	sp,sp,32
    800039be:	8082                	ret
    panic("iunlock");
    800039c0:	00005517          	auipc	a0,0x5
    800039c4:	c2850513          	addi	a0,a0,-984 # 800085e8 <syscalls+0x198>
    800039c8:	ffffd097          	auipc	ra,0xffffd
    800039cc:	b62080e7          	jalr	-1182(ra) # 8000052a <panic>

00000000800039d0 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039d0:	7179                	addi	sp,sp,-48
    800039d2:	f406                	sd	ra,40(sp)
    800039d4:	f022                	sd	s0,32(sp)
    800039d6:	ec26                	sd	s1,24(sp)
    800039d8:	e84a                	sd	s2,16(sp)
    800039da:	e44e                	sd	s3,8(sp)
    800039dc:	e052                	sd	s4,0(sp)
    800039de:	1800                	addi	s0,sp,48
    800039e0:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039e2:	05050493          	addi	s1,a0,80
    800039e6:	08050913          	addi	s2,a0,128
    800039ea:	a021                	j	800039f2 <itrunc+0x22>
    800039ec:	0491                	addi	s1,s1,4
    800039ee:	01248d63          	beq	s1,s2,80003a08 <itrunc+0x38>
    if(ip->addrs[i]){
    800039f2:	408c                	lw	a1,0(s1)
    800039f4:	dde5                	beqz	a1,800039ec <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039f6:	0009a503          	lw	a0,0(s3)
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	90a080e7          	jalr	-1782(ra) # 80003304 <bfree>
      ip->addrs[i] = 0;
    80003a02:	0004a023          	sw	zero,0(s1)
    80003a06:	b7dd                	j	800039ec <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a08:	0809a583          	lw	a1,128(s3)
    80003a0c:	e185                	bnez	a1,80003a2c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a0e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a12:	854e                	mv	a0,s3
    80003a14:	00000097          	auipc	ra,0x0
    80003a18:	de4080e7          	jalr	-540(ra) # 800037f8 <iupdate>
}
    80003a1c:	70a2                	ld	ra,40(sp)
    80003a1e:	7402                	ld	s0,32(sp)
    80003a20:	64e2                	ld	s1,24(sp)
    80003a22:	6942                	ld	s2,16(sp)
    80003a24:	69a2                	ld	s3,8(sp)
    80003a26:	6a02                	ld	s4,0(sp)
    80003a28:	6145                	addi	sp,sp,48
    80003a2a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a2c:	0009a503          	lw	a0,0(s3)
    80003a30:	fffff097          	auipc	ra,0xfffff
    80003a34:	68e080e7          	jalr	1678(ra) # 800030be <bread>
    80003a38:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a3a:	05850493          	addi	s1,a0,88
    80003a3e:	45850913          	addi	s2,a0,1112
    80003a42:	a021                	j	80003a4a <itrunc+0x7a>
    80003a44:	0491                	addi	s1,s1,4
    80003a46:	01248b63          	beq	s1,s2,80003a5c <itrunc+0x8c>
      if(a[j])
    80003a4a:	408c                	lw	a1,0(s1)
    80003a4c:	dde5                	beqz	a1,80003a44 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a4e:	0009a503          	lw	a0,0(s3)
    80003a52:	00000097          	auipc	ra,0x0
    80003a56:	8b2080e7          	jalr	-1870(ra) # 80003304 <bfree>
    80003a5a:	b7ed                	j	80003a44 <itrunc+0x74>
    brelse(bp);
    80003a5c:	8552                	mv	a0,s4
    80003a5e:	fffff097          	auipc	ra,0xfffff
    80003a62:	790080e7          	jalr	1936(ra) # 800031ee <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a66:	0809a583          	lw	a1,128(s3)
    80003a6a:	0009a503          	lw	a0,0(s3)
    80003a6e:	00000097          	auipc	ra,0x0
    80003a72:	896080e7          	jalr	-1898(ra) # 80003304 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a76:	0809a023          	sw	zero,128(s3)
    80003a7a:	bf51                	j	80003a0e <itrunc+0x3e>

0000000080003a7c <iput>:
{
    80003a7c:	1101                	addi	sp,sp,-32
    80003a7e:	ec06                	sd	ra,24(sp)
    80003a80:	e822                	sd	s0,16(sp)
    80003a82:	e426                	sd	s1,8(sp)
    80003a84:	e04a                	sd	s2,0(sp)
    80003a86:	1000                	addi	s0,sp,32
    80003a88:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a8a:	00021517          	auipc	a0,0x21
    80003a8e:	33e50513          	addi	a0,a0,830 # 80024dc8 <itable>
    80003a92:	ffffd097          	auipc	ra,0xffffd
    80003a96:	130080e7          	jalr	304(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a9a:	4498                	lw	a4,8(s1)
    80003a9c:	4785                	li	a5,1
    80003a9e:	02f70363          	beq	a4,a5,80003ac4 <iput+0x48>
  ip->ref--;
    80003aa2:	449c                	lw	a5,8(s1)
    80003aa4:	37fd                	addiw	a5,a5,-1
    80003aa6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003aa8:	00021517          	auipc	a0,0x21
    80003aac:	32050513          	addi	a0,a0,800 # 80024dc8 <itable>
    80003ab0:	ffffd097          	auipc	ra,0xffffd
    80003ab4:	1c6080e7          	jalr	454(ra) # 80000c76 <release>
}
    80003ab8:	60e2                	ld	ra,24(sp)
    80003aba:	6442                	ld	s0,16(sp)
    80003abc:	64a2                	ld	s1,8(sp)
    80003abe:	6902                	ld	s2,0(sp)
    80003ac0:	6105                	addi	sp,sp,32
    80003ac2:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ac4:	40bc                	lw	a5,64(s1)
    80003ac6:	dff1                	beqz	a5,80003aa2 <iput+0x26>
    80003ac8:	04a49783          	lh	a5,74(s1)
    80003acc:	fbf9                	bnez	a5,80003aa2 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ace:	01048913          	addi	s2,s1,16
    80003ad2:	854a                	mv	a0,s2
    80003ad4:	00001097          	auipc	ra,0x1
    80003ad8:	dce080e7          	jalr	-562(ra) # 800048a2 <acquiresleep>
    release(&itable.lock);
    80003adc:	00021517          	auipc	a0,0x21
    80003ae0:	2ec50513          	addi	a0,a0,748 # 80024dc8 <itable>
    80003ae4:	ffffd097          	auipc	ra,0xffffd
    80003ae8:	192080e7          	jalr	402(ra) # 80000c76 <release>
    itrunc(ip);
    80003aec:	8526                	mv	a0,s1
    80003aee:	00000097          	auipc	ra,0x0
    80003af2:	ee2080e7          	jalr	-286(ra) # 800039d0 <itrunc>
    ip->type = 0;
    80003af6:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003afa:	8526                	mv	a0,s1
    80003afc:	00000097          	auipc	ra,0x0
    80003b00:	cfc080e7          	jalr	-772(ra) # 800037f8 <iupdate>
    ip->valid = 0;
    80003b04:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b08:	854a                	mv	a0,s2
    80003b0a:	00001097          	auipc	ra,0x1
    80003b0e:	dee080e7          	jalr	-530(ra) # 800048f8 <releasesleep>
    acquire(&itable.lock);
    80003b12:	00021517          	auipc	a0,0x21
    80003b16:	2b650513          	addi	a0,a0,694 # 80024dc8 <itable>
    80003b1a:	ffffd097          	auipc	ra,0xffffd
    80003b1e:	0a8080e7          	jalr	168(ra) # 80000bc2 <acquire>
    80003b22:	b741                	j	80003aa2 <iput+0x26>

0000000080003b24 <iunlockput>:
{
    80003b24:	1101                	addi	sp,sp,-32
    80003b26:	ec06                	sd	ra,24(sp)
    80003b28:	e822                	sd	s0,16(sp)
    80003b2a:	e426                	sd	s1,8(sp)
    80003b2c:	1000                	addi	s0,sp,32
    80003b2e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b30:	00000097          	auipc	ra,0x0
    80003b34:	e54080e7          	jalr	-428(ra) # 80003984 <iunlock>
  iput(ip);
    80003b38:	8526                	mv	a0,s1
    80003b3a:	00000097          	auipc	ra,0x0
    80003b3e:	f42080e7          	jalr	-190(ra) # 80003a7c <iput>
}
    80003b42:	60e2                	ld	ra,24(sp)
    80003b44:	6442                	ld	s0,16(sp)
    80003b46:	64a2                	ld	s1,8(sp)
    80003b48:	6105                	addi	sp,sp,32
    80003b4a:	8082                	ret

0000000080003b4c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b4c:	1141                	addi	sp,sp,-16
    80003b4e:	e422                	sd	s0,8(sp)
    80003b50:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b52:	411c                	lw	a5,0(a0)
    80003b54:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b56:	415c                	lw	a5,4(a0)
    80003b58:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b5a:	04451783          	lh	a5,68(a0)
    80003b5e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b62:	04a51783          	lh	a5,74(a0)
    80003b66:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b6a:	04c56783          	lwu	a5,76(a0)
    80003b6e:	e99c                	sd	a5,16(a1)
}
    80003b70:	6422                	ld	s0,8(sp)
    80003b72:	0141                	addi	sp,sp,16
    80003b74:	8082                	ret

0000000080003b76 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b76:	457c                	lw	a5,76(a0)
    80003b78:	0ed7e963          	bltu	a5,a3,80003c6a <readi+0xf4>
{
    80003b7c:	7159                	addi	sp,sp,-112
    80003b7e:	f486                	sd	ra,104(sp)
    80003b80:	f0a2                	sd	s0,96(sp)
    80003b82:	eca6                	sd	s1,88(sp)
    80003b84:	e8ca                	sd	s2,80(sp)
    80003b86:	e4ce                	sd	s3,72(sp)
    80003b88:	e0d2                	sd	s4,64(sp)
    80003b8a:	fc56                	sd	s5,56(sp)
    80003b8c:	f85a                	sd	s6,48(sp)
    80003b8e:	f45e                	sd	s7,40(sp)
    80003b90:	f062                	sd	s8,32(sp)
    80003b92:	ec66                	sd	s9,24(sp)
    80003b94:	e86a                	sd	s10,16(sp)
    80003b96:	e46e                	sd	s11,8(sp)
    80003b98:	1880                	addi	s0,sp,112
    80003b9a:	8baa                	mv	s7,a0
    80003b9c:	8c2e                	mv	s8,a1
    80003b9e:	8ab2                	mv	s5,a2
    80003ba0:	84b6                	mv	s1,a3
    80003ba2:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ba4:	9f35                	addw	a4,a4,a3
    return 0;
    80003ba6:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ba8:	0ad76063          	bltu	a4,a3,80003c48 <readi+0xd2>
  if(off + n > ip->size)
    80003bac:	00e7f463          	bgeu	a5,a4,80003bb4 <readi+0x3e>
    n = ip->size - off;
    80003bb0:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bb4:	0a0b0963          	beqz	s6,80003c66 <readi+0xf0>
    80003bb8:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bba:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bbe:	5cfd                	li	s9,-1
    80003bc0:	a82d                	j	80003bfa <readi+0x84>
    80003bc2:	020a1d93          	slli	s11,s4,0x20
    80003bc6:	020ddd93          	srli	s11,s11,0x20
    80003bca:	05890793          	addi	a5,s2,88
    80003bce:	86ee                	mv	a3,s11
    80003bd0:	963e                	add	a2,a2,a5
    80003bd2:	85d6                	mv	a1,s5
    80003bd4:	8562                	mv	a0,s8
    80003bd6:	fffff097          	auipc	ra,0xfffff
    80003bda:	afc080e7          	jalr	-1284(ra) # 800026d2 <either_copyout>
    80003bde:	05950d63          	beq	a0,s9,80003c38 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003be2:	854a                	mv	a0,s2
    80003be4:	fffff097          	auipc	ra,0xfffff
    80003be8:	60a080e7          	jalr	1546(ra) # 800031ee <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bec:	013a09bb          	addw	s3,s4,s3
    80003bf0:	009a04bb          	addw	s1,s4,s1
    80003bf4:	9aee                	add	s5,s5,s11
    80003bf6:	0569f763          	bgeu	s3,s6,80003c44 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bfa:	000ba903          	lw	s2,0(s7)
    80003bfe:	00a4d59b          	srliw	a1,s1,0xa
    80003c02:	855e                	mv	a0,s7
    80003c04:	00000097          	auipc	ra,0x0
    80003c08:	8ae080e7          	jalr	-1874(ra) # 800034b2 <bmap>
    80003c0c:	0005059b          	sext.w	a1,a0
    80003c10:	854a                	mv	a0,s2
    80003c12:	fffff097          	auipc	ra,0xfffff
    80003c16:	4ac080e7          	jalr	1196(ra) # 800030be <bread>
    80003c1a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c1c:	3ff4f613          	andi	a2,s1,1023
    80003c20:	40cd07bb          	subw	a5,s10,a2
    80003c24:	413b073b          	subw	a4,s6,s3
    80003c28:	8a3e                	mv	s4,a5
    80003c2a:	2781                	sext.w	a5,a5
    80003c2c:	0007069b          	sext.w	a3,a4
    80003c30:	f8f6f9e3          	bgeu	a3,a5,80003bc2 <readi+0x4c>
    80003c34:	8a3a                	mv	s4,a4
    80003c36:	b771                	j	80003bc2 <readi+0x4c>
      brelse(bp);
    80003c38:	854a                	mv	a0,s2
    80003c3a:	fffff097          	auipc	ra,0xfffff
    80003c3e:	5b4080e7          	jalr	1460(ra) # 800031ee <brelse>
      tot = -1;
    80003c42:	59fd                	li	s3,-1
  }
  return tot;
    80003c44:	0009851b          	sext.w	a0,s3
}
    80003c48:	70a6                	ld	ra,104(sp)
    80003c4a:	7406                	ld	s0,96(sp)
    80003c4c:	64e6                	ld	s1,88(sp)
    80003c4e:	6946                	ld	s2,80(sp)
    80003c50:	69a6                	ld	s3,72(sp)
    80003c52:	6a06                	ld	s4,64(sp)
    80003c54:	7ae2                	ld	s5,56(sp)
    80003c56:	7b42                	ld	s6,48(sp)
    80003c58:	7ba2                	ld	s7,40(sp)
    80003c5a:	7c02                	ld	s8,32(sp)
    80003c5c:	6ce2                	ld	s9,24(sp)
    80003c5e:	6d42                	ld	s10,16(sp)
    80003c60:	6da2                	ld	s11,8(sp)
    80003c62:	6165                	addi	sp,sp,112
    80003c64:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c66:	89da                	mv	s3,s6
    80003c68:	bff1                	j	80003c44 <readi+0xce>
    return 0;
    80003c6a:	4501                	li	a0,0
}
    80003c6c:	8082                	ret

0000000080003c6e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c6e:	457c                	lw	a5,76(a0)
    80003c70:	10d7e863          	bltu	a5,a3,80003d80 <writei+0x112>
{
    80003c74:	7159                	addi	sp,sp,-112
    80003c76:	f486                	sd	ra,104(sp)
    80003c78:	f0a2                	sd	s0,96(sp)
    80003c7a:	eca6                	sd	s1,88(sp)
    80003c7c:	e8ca                	sd	s2,80(sp)
    80003c7e:	e4ce                	sd	s3,72(sp)
    80003c80:	e0d2                	sd	s4,64(sp)
    80003c82:	fc56                	sd	s5,56(sp)
    80003c84:	f85a                	sd	s6,48(sp)
    80003c86:	f45e                	sd	s7,40(sp)
    80003c88:	f062                	sd	s8,32(sp)
    80003c8a:	ec66                	sd	s9,24(sp)
    80003c8c:	e86a                	sd	s10,16(sp)
    80003c8e:	e46e                	sd	s11,8(sp)
    80003c90:	1880                	addi	s0,sp,112
    80003c92:	8b2a                	mv	s6,a0
    80003c94:	8c2e                	mv	s8,a1
    80003c96:	8ab2                	mv	s5,a2
    80003c98:	8936                	mv	s2,a3
    80003c9a:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c9c:	00e687bb          	addw	a5,a3,a4
    80003ca0:	0ed7e263          	bltu	a5,a3,80003d84 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ca4:	00043737          	lui	a4,0x43
    80003ca8:	0ef76063          	bltu	a4,a5,80003d88 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cac:	0c0b8863          	beqz	s7,80003d7c <writei+0x10e>
    80003cb0:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cb2:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cb6:	5cfd                	li	s9,-1
    80003cb8:	a091                	j	80003cfc <writei+0x8e>
    80003cba:	02099d93          	slli	s11,s3,0x20
    80003cbe:	020ddd93          	srli	s11,s11,0x20
    80003cc2:	05848793          	addi	a5,s1,88
    80003cc6:	86ee                	mv	a3,s11
    80003cc8:	8656                	mv	a2,s5
    80003cca:	85e2                	mv	a1,s8
    80003ccc:	953e                	add	a0,a0,a5
    80003cce:	fffff097          	auipc	ra,0xfffff
    80003cd2:	a5a080e7          	jalr	-1446(ra) # 80002728 <either_copyin>
    80003cd6:	07950263          	beq	a0,s9,80003d3a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003cda:	8526                	mv	a0,s1
    80003cdc:	00001097          	auipc	ra,0x1
    80003ce0:	aa6080e7          	jalr	-1370(ra) # 80004782 <log_write>
    brelse(bp);
    80003ce4:	8526                	mv	a0,s1
    80003ce6:	fffff097          	auipc	ra,0xfffff
    80003cea:	508080e7          	jalr	1288(ra) # 800031ee <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cee:	01498a3b          	addw	s4,s3,s4
    80003cf2:	0129893b          	addw	s2,s3,s2
    80003cf6:	9aee                	add	s5,s5,s11
    80003cf8:	057a7663          	bgeu	s4,s7,80003d44 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cfc:	000b2483          	lw	s1,0(s6)
    80003d00:	00a9559b          	srliw	a1,s2,0xa
    80003d04:	855a                	mv	a0,s6
    80003d06:	fffff097          	auipc	ra,0xfffff
    80003d0a:	7ac080e7          	jalr	1964(ra) # 800034b2 <bmap>
    80003d0e:	0005059b          	sext.w	a1,a0
    80003d12:	8526                	mv	a0,s1
    80003d14:	fffff097          	auipc	ra,0xfffff
    80003d18:	3aa080e7          	jalr	938(ra) # 800030be <bread>
    80003d1c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d1e:	3ff97513          	andi	a0,s2,1023
    80003d22:	40ad07bb          	subw	a5,s10,a0
    80003d26:	414b873b          	subw	a4,s7,s4
    80003d2a:	89be                	mv	s3,a5
    80003d2c:	2781                	sext.w	a5,a5
    80003d2e:	0007069b          	sext.w	a3,a4
    80003d32:	f8f6f4e3          	bgeu	a3,a5,80003cba <writei+0x4c>
    80003d36:	89ba                	mv	s3,a4
    80003d38:	b749                	j	80003cba <writei+0x4c>
      brelse(bp);
    80003d3a:	8526                	mv	a0,s1
    80003d3c:	fffff097          	auipc	ra,0xfffff
    80003d40:	4b2080e7          	jalr	1202(ra) # 800031ee <brelse>
  }

  if(off > ip->size)
    80003d44:	04cb2783          	lw	a5,76(s6)
    80003d48:	0127f463          	bgeu	a5,s2,80003d50 <writei+0xe2>
    ip->size = off;
    80003d4c:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d50:	855a                	mv	a0,s6
    80003d52:	00000097          	auipc	ra,0x0
    80003d56:	aa6080e7          	jalr	-1370(ra) # 800037f8 <iupdate>

  return tot;
    80003d5a:	000a051b          	sext.w	a0,s4
}
    80003d5e:	70a6                	ld	ra,104(sp)
    80003d60:	7406                	ld	s0,96(sp)
    80003d62:	64e6                	ld	s1,88(sp)
    80003d64:	6946                	ld	s2,80(sp)
    80003d66:	69a6                	ld	s3,72(sp)
    80003d68:	6a06                	ld	s4,64(sp)
    80003d6a:	7ae2                	ld	s5,56(sp)
    80003d6c:	7b42                	ld	s6,48(sp)
    80003d6e:	7ba2                	ld	s7,40(sp)
    80003d70:	7c02                	ld	s8,32(sp)
    80003d72:	6ce2                	ld	s9,24(sp)
    80003d74:	6d42                	ld	s10,16(sp)
    80003d76:	6da2                	ld	s11,8(sp)
    80003d78:	6165                	addi	sp,sp,112
    80003d7a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d7c:	8a5e                	mv	s4,s7
    80003d7e:	bfc9                	j	80003d50 <writei+0xe2>
    return -1;
    80003d80:	557d                	li	a0,-1
}
    80003d82:	8082                	ret
    return -1;
    80003d84:	557d                	li	a0,-1
    80003d86:	bfe1                	j	80003d5e <writei+0xf0>
    return -1;
    80003d88:	557d                	li	a0,-1
    80003d8a:	bfd1                	j	80003d5e <writei+0xf0>

0000000080003d8c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d8c:	1141                	addi	sp,sp,-16
    80003d8e:	e406                	sd	ra,8(sp)
    80003d90:	e022                	sd	s0,0(sp)
    80003d92:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d94:	4639                	li	a2,14
    80003d96:	ffffd097          	auipc	ra,0xffffd
    80003d9a:	000080e7          	jalr	ra # 80000d96 <strncmp>
}
    80003d9e:	60a2                	ld	ra,8(sp)
    80003da0:	6402                	ld	s0,0(sp)
    80003da2:	0141                	addi	sp,sp,16
    80003da4:	8082                	ret

0000000080003da6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003da6:	7139                	addi	sp,sp,-64
    80003da8:	fc06                	sd	ra,56(sp)
    80003daa:	f822                	sd	s0,48(sp)
    80003dac:	f426                	sd	s1,40(sp)
    80003dae:	f04a                	sd	s2,32(sp)
    80003db0:	ec4e                	sd	s3,24(sp)
    80003db2:	e852                	sd	s4,16(sp)
    80003db4:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003db6:	04451703          	lh	a4,68(a0)
    80003dba:	4785                	li	a5,1
    80003dbc:	00f71a63          	bne	a4,a5,80003dd0 <dirlookup+0x2a>
    80003dc0:	892a                	mv	s2,a0
    80003dc2:	89ae                	mv	s3,a1
    80003dc4:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dc6:	457c                	lw	a5,76(a0)
    80003dc8:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003dca:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dcc:	e79d                	bnez	a5,80003dfa <dirlookup+0x54>
    80003dce:	a8a5                	j	80003e46 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003dd0:	00005517          	auipc	a0,0x5
    80003dd4:	82050513          	addi	a0,a0,-2016 # 800085f0 <syscalls+0x1a0>
    80003dd8:	ffffc097          	auipc	ra,0xffffc
    80003ddc:	752080e7          	jalr	1874(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003de0:	00005517          	auipc	a0,0x5
    80003de4:	82850513          	addi	a0,a0,-2008 # 80008608 <syscalls+0x1b8>
    80003de8:	ffffc097          	auipc	ra,0xffffc
    80003dec:	742080e7          	jalr	1858(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003df0:	24c1                	addiw	s1,s1,16
    80003df2:	04c92783          	lw	a5,76(s2)
    80003df6:	04f4f763          	bgeu	s1,a5,80003e44 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dfa:	4741                	li	a4,16
    80003dfc:	86a6                	mv	a3,s1
    80003dfe:	fc040613          	addi	a2,s0,-64
    80003e02:	4581                	li	a1,0
    80003e04:	854a                	mv	a0,s2
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	d70080e7          	jalr	-656(ra) # 80003b76 <readi>
    80003e0e:	47c1                	li	a5,16
    80003e10:	fcf518e3          	bne	a0,a5,80003de0 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e14:	fc045783          	lhu	a5,-64(s0)
    80003e18:	dfe1                	beqz	a5,80003df0 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e1a:	fc240593          	addi	a1,s0,-62
    80003e1e:	854e                	mv	a0,s3
    80003e20:	00000097          	auipc	ra,0x0
    80003e24:	f6c080e7          	jalr	-148(ra) # 80003d8c <namecmp>
    80003e28:	f561                	bnez	a0,80003df0 <dirlookup+0x4a>
      if(poff)
    80003e2a:	000a0463          	beqz	s4,80003e32 <dirlookup+0x8c>
        *poff = off;
    80003e2e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e32:	fc045583          	lhu	a1,-64(s0)
    80003e36:	00092503          	lw	a0,0(s2)
    80003e3a:	fffff097          	auipc	ra,0xfffff
    80003e3e:	754080e7          	jalr	1876(ra) # 8000358e <iget>
    80003e42:	a011                	j	80003e46 <dirlookup+0xa0>
  return 0;
    80003e44:	4501                	li	a0,0
}
    80003e46:	70e2                	ld	ra,56(sp)
    80003e48:	7442                	ld	s0,48(sp)
    80003e4a:	74a2                	ld	s1,40(sp)
    80003e4c:	7902                	ld	s2,32(sp)
    80003e4e:	69e2                	ld	s3,24(sp)
    80003e50:	6a42                	ld	s4,16(sp)
    80003e52:	6121                	addi	sp,sp,64
    80003e54:	8082                	ret

0000000080003e56 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e56:	711d                	addi	sp,sp,-96
    80003e58:	ec86                	sd	ra,88(sp)
    80003e5a:	e8a2                	sd	s0,80(sp)
    80003e5c:	e4a6                	sd	s1,72(sp)
    80003e5e:	e0ca                	sd	s2,64(sp)
    80003e60:	fc4e                	sd	s3,56(sp)
    80003e62:	f852                	sd	s4,48(sp)
    80003e64:	f456                	sd	s5,40(sp)
    80003e66:	f05a                	sd	s6,32(sp)
    80003e68:	ec5e                	sd	s7,24(sp)
    80003e6a:	e862                	sd	s8,16(sp)
    80003e6c:	e466                	sd	s9,8(sp)
    80003e6e:	1080                	addi	s0,sp,96
    80003e70:	84aa                	mv	s1,a0
    80003e72:	8aae                	mv	s5,a1
    80003e74:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e76:	00054703          	lbu	a4,0(a0)
    80003e7a:	02f00793          	li	a5,47
    80003e7e:	02f70363          	beq	a4,a5,80003ea4 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e82:	ffffe097          	auipc	ra,0xffffe
    80003e86:	cfa080e7          	jalr	-774(ra) # 80001b7c <myproc>
    80003e8a:	15053503          	ld	a0,336(a0)
    80003e8e:	00000097          	auipc	ra,0x0
    80003e92:	9f6080e7          	jalr	-1546(ra) # 80003884 <idup>
    80003e96:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e98:	02f00913          	li	s2,47
  len = path - s;
    80003e9c:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003e9e:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ea0:	4b85                	li	s7,1
    80003ea2:	a865                	j	80003f5a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ea4:	4585                	li	a1,1
    80003ea6:	4505                	li	a0,1
    80003ea8:	fffff097          	auipc	ra,0xfffff
    80003eac:	6e6080e7          	jalr	1766(ra) # 8000358e <iget>
    80003eb0:	89aa                	mv	s3,a0
    80003eb2:	b7dd                	j	80003e98 <namex+0x42>
      iunlockput(ip);
    80003eb4:	854e                	mv	a0,s3
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	c6e080e7          	jalr	-914(ra) # 80003b24 <iunlockput>
      return 0;
    80003ebe:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ec0:	854e                	mv	a0,s3
    80003ec2:	60e6                	ld	ra,88(sp)
    80003ec4:	6446                	ld	s0,80(sp)
    80003ec6:	64a6                	ld	s1,72(sp)
    80003ec8:	6906                	ld	s2,64(sp)
    80003eca:	79e2                	ld	s3,56(sp)
    80003ecc:	7a42                	ld	s4,48(sp)
    80003ece:	7aa2                	ld	s5,40(sp)
    80003ed0:	7b02                	ld	s6,32(sp)
    80003ed2:	6be2                	ld	s7,24(sp)
    80003ed4:	6c42                	ld	s8,16(sp)
    80003ed6:	6ca2                	ld	s9,8(sp)
    80003ed8:	6125                	addi	sp,sp,96
    80003eda:	8082                	ret
      iunlock(ip);
    80003edc:	854e                	mv	a0,s3
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	aa6080e7          	jalr	-1370(ra) # 80003984 <iunlock>
      return ip;
    80003ee6:	bfe9                	j	80003ec0 <namex+0x6a>
      iunlockput(ip);
    80003ee8:	854e                	mv	a0,s3
    80003eea:	00000097          	auipc	ra,0x0
    80003eee:	c3a080e7          	jalr	-966(ra) # 80003b24 <iunlockput>
      return 0;
    80003ef2:	89e6                	mv	s3,s9
    80003ef4:	b7f1                	j	80003ec0 <namex+0x6a>
  len = path - s;
    80003ef6:	40b48633          	sub	a2,s1,a1
    80003efa:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003efe:	099c5463          	bge	s8,s9,80003f86 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f02:	4639                	li	a2,14
    80003f04:	8552                	mv	a0,s4
    80003f06:	ffffd097          	auipc	ra,0xffffd
    80003f0a:	e14080e7          	jalr	-492(ra) # 80000d1a <memmove>
  while(*path == '/')
    80003f0e:	0004c783          	lbu	a5,0(s1)
    80003f12:	01279763          	bne	a5,s2,80003f20 <namex+0xca>
    path++;
    80003f16:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f18:	0004c783          	lbu	a5,0(s1)
    80003f1c:	ff278de3          	beq	a5,s2,80003f16 <namex+0xc0>
    ilock(ip);
    80003f20:	854e                	mv	a0,s3
    80003f22:	00000097          	auipc	ra,0x0
    80003f26:	9a0080e7          	jalr	-1632(ra) # 800038c2 <ilock>
    if(ip->type != T_DIR){
    80003f2a:	04499783          	lh	a5,68(s3)
    80003f2e:	f97793e3          	bne	a5,s7,80003eb4 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f32:	000a8563          	beqz	s5,80003f3c <namex+0xe6>
    80003f36:	0004c783          	lbu	a5,0(s1)
    80003f3a:	d3cd                	beqz	a5,80003edc <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f3c:	865a                	mv	a2,s6
    80003f3e:	85d2                	mv	a1,s4
    80003f40:	854e                	mv	a0,s3
    80003f42:	00000097          	auipc	ra,0x0
    80003f46:	e64080e7          	jalr	-412(ra) # 80003da6 <dirlookup>
    80003f4a:	8caa                	mv	s9,a0
    80003f4c:	dd51                	beqz	a0,80003ee8 <namex+0x92>
    iunlockput(ip);
    80003f4e:	854e                	mv	a0,s3
    80003f50:	00000097          	auipc	ra,0x0
    80003f54:	bd4080e7          	jalr	-1068(ra) # 80003b24 <iunlockput>
    ip = next;
    80003f58:	89e6                	mv	s3,s9
  while(*path == '/')
    80003f5a:	0004c783          	lbu	a5,0(s1)
    80003f5e:	05279763          	bne	a5,s2,80003fac <namex+0x156>
    path++;
    80003f62:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f64:	0004c783          	lbu	a5,0(s1)
    80003f68:	ff278de3          	beq	a5,s2,80003f62 <namex+0x10c>
  if(*path == 0)
    80003f6c:	c79d                	beqz	a5,80003f9a <namex+0x144>
    path++;
    80003f6e:	85a6                	mv	a1,s1
  len = path - s;
    80003f70:	8cda                	mv	s9,s6
    80003f72:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003f74:	01278963          	beq	a5,s2,80003f86 <namex+0x130>
    80003f78:	dfbd                	beqz	a5,80003ef6 <namex+0xa0>
    path++;
    80003f7a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f7c:	0004c783          	lbu	a5,0(s1)
    80003f80:	ff279ce3          	bne	a5,s2,80003f78 <namex+0x122>
    80003f84:	bf8d                	j	80003ef6 <namex+0xa0>
    memmove(name, s, len);
    80003f86:	2601                	sext.w	a2,a2
    80003f88:	8552                	mv	a0,s4
    80003f8a:	ffffd097          	auipc	ra,0xffffd
    80003f8e:	d90080e7          	jalr	-624(ra) # 80000d1a <memmove>
    name[len] = 0;
    80003f92:	9cd2                	add	s9,s9,s4
    80003f94:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003f98:	bf9d                	j	80003f0e <namex+0xb8>
  if(nameiparent){
    80003f9a:	f20a83e3          	beqz	s5,80003ec0 <namex+0x6a>
    iput(ip);
    80003f9e:	854e                	mv	a0,s3
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	adc080e7          	jalr	-1316(ra) # 80003a7c <iput>
    return 0;
    80003fa8:	4981                	li	s3,0
    80003faa:	bf19                	j	80003ec0 <namex+0x6a>
  if(*path == 0)
    80003fac:	d7fd                	beqz	a5,80003f9a <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fae:	0004c783          	lbu	a5,0(s1)
    80003fb2:	85a6                	mv	a1,s1
    80003fb4:	b7d1                	j	80003f78 <namex+0x122>

0000000080003fb6 <dirlink>:
{
    80003fb6:	7139                	addi	sp,sp,-64
    80003fb8:	fc06                	sd	ra,56(sp)
    80003fba:	f822                	sd	s0,48(sp)
    80003fbc:	f426                	sd	s1,40(sp)
    80003fbe:	f04a                	sd	s2,32(sp)
    80003fc0:	ec4e                	sd	s3,24(sp)
    80003fc2:	e852                	sd	s4,16(sp)
    80003fc4:	0080                	addi	s0,sp,64
    80003fc6:	892a                	mv	s2,a0
    80003fc8:	8a2e                	mv	s4,a1
    80003fca:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fcc:	4601                	li	a2,0
    80003fce:	00000097          	auipc	ra,0x0
    80003fd2:	dd8080e7          	jalr	-552(ra) # 80003da6 <dirlookup>
    80003fd6:	e93d                	bnez	a0,8000404c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fd8:	04c92483          	lw	s1,76(s2)
    80003fdc:	c49d                	beqz	s1,8000400a <dirlink+0x54>
    80003fde:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fe0:	4741                	li	a4,16
    80003fe2:	86a6                	mv	a3,s1
    80003fe4:	fc040613          	addi	a2,s0,-64
    80003fe8:	4581                	li	a1,0
    80003fea:	854a                	mv	a0,s2
    80003fec:	00000097          	auipc	ra,0x0
    80003ff0:	b8a080e7          	jalr	-1142(ra) # 80003b76 <readi>
    80003ff4:	47c1                	li	a5,16
    80003ff6:	06f51163          	bne	a0,a5,80004058 <dirlink+0xa2>
    if(de.inum == 0)
    80003ffa:	fc045783          	lhu	a5,-64(s0)
    80003ffe:	c791                	beqz	a5,8000400a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004000:	24c1                	addiw	s1,s1,16
    80004002:	04c92783          	lw	a5,76(s2)
    80004006:	fcf4ede3          	bltu	s1,a5,80003fe0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000400a:	4639                	li	a2,14
    8000400c:	85d2                	mv	a1,s4
    8000400e:	fc240513          	addi	a0,s0,-62
    80004012:	ffffd097          	auipc	ra,0xffffd
    80004016:	dc0080e7          	jalr	-576(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    8000401a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000401e:	4741                	li	a4,16
    80004020:	86a6                	mv	a3,s1
    80004022:	fc040613          	addi	a2,s0,-64
    80004026:	4581                	li	a1,0
    80004028:	854a                	mv	a0,s2
    8000402a:	00000097          	auipc	ra,0x0
    8000402e:	c44080e7          	jalr	-956(ra) # 80003c6e <writei>
    80004032:	872a                	mv	a4,a0
    80004034:	47c1                	li	a5,16
  return 0;
    80004036:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004038:	02f71863          	bne	a4,a5,80004068 <dirlink+0xb2>
}
    8000403c:	70e2                	ld	ra,56(sp)
    8000403e:	7442                	ld	s0,48(sp)
    80004040:	74a2                	ld	s1,40(sp)
    80004042:	7902                	ld	s2,32(sp)
    80004044:	69e2                	ld	s3,24(sp)
    80004046:	6a42                	ld	s4,16(sp)
    80004048:	6121                	addi	sp,sp,64
    8000404a:	8082                	ret
    iput(ip);
    8000404c:	00000097          	auipc	ra,0x0
    80004050:	a30080e7          	jalr	-1488(ra) # 80003a7c <iput>
    return -1;
    80004054:	557d                	li	a0,-1
    80004056:	b7dd                	j	8000403c <dirlink+0x86>
      panic("dirlink read");
    80004058:	00004517          	auipc	a0,0x4
    8000405c:	5c050513          	addi	a0,a0,1472 # 80008618 <syscalls+0x1c8>
    80004060:	ffffc097          	auipc	ra,0xffffc
    80004064:	4ca080e7          	jalr	1226(ra) # 8000052a <panic>
    panic("dirlink");
    80004068:	00004517          	auipc	a0,0x4
    8000406c:	73850513          	addi	a0,a0,1848 # 800087a0 <syscalls+0x350>
    80004070:	ffffc097          	auipc	ra,0xffffc
    80004074:	4ba080e7          	jalr	1210(ra) # 8000052a <panic>

0000000080004078 <namei>:

struct inode*
namei(char *path)
{
    80004078:	1101                	addi	sp,sp,-32
    8000407a:	ec06                	sd	ra,24(sp)
    8000407c:	e822                	sd	s0,16(sp)
    8000407e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004080:	fe040613          	addi	a2,s0,-32
    80004084:	4581                	li	a1,0
    80004086:	00000097          	auipc	ra,0x0
    8000408a:	dd0080e7          	jalr	-560(ra) # 80003e56 <namex>
}
    8000408e:	60e2                	ld	ra,24(sp)
    80004090:	6442                	ld	s0,16(sp)
    80004092:	6105                	addi	sp,sp,32
    80004094:	8082                	ret

0000000080004096 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004096:	1141                	addi	sp,sp,-16
    80004098:	e406                	sd	ra,8(sp)
    8000409a:	e022                	sd	s0,0(sp)
    8000409c:	0800                	addi	s0,sp,16
    8000409e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040a0:	4585                	li	a1,1
    800040a2:	00000097          	auipc	ra,0x0
    800040a6:	db4080e7          	jalr	-588(ra) # 80003e56 <namex>
}
    800040aa:	60a2                	ld	ra,8(sp)
    800040ac:	6402                	ld	s0,0(sp)
    800040ae:	0141                	addi	sp,sp,16
    800040b0:	8082                	ret

00000000800040b2 <itoa>:


#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
    800040b2:	1101                	addi	sp,sp,-32
    800040b4:	ec22                	sd	s0,24(sp)
    800040b6:	1000                	addi	s0,sp,32
    800040b8:	872a                	mv	a4,a0
    800040ba:	852e                	mv	a0,a1
    char const digit[] = "0123456789";
    800040bc:	00004797          	auipc	a5,0x4
    800040c0:	56c78793          	addi	a5,a5,1388 # 80008628 <syscalls+0x1d8>
    800040c4:	6394                	ld	a3,0(a5)
    800040c6:	fed43023          	sd	a3,-32(s0)
    800040ca:	0087d683          	lhu	a3,8(a5)
    800040ce:	fed41423          	sh	a3,-24(s0)
    800040d2:	00a7c783          	lbu	a5,10(a5)
    800040d6:	fef40523          	sb	a5,-22(s0)
    char* p = b;
    800040da:	87ae                	mv	a5,a1
    if(i<0){
    800040dc:	02074b63          	bltz	a4,80004112 <itoa+0x60>
        *p++ = '-';
        i *= -1;
    }
    int shifter = i;
    800040e0:	86ba                	mv	a3,a4
    do{ //Move to where representation ends
        ++p;
        shifter = shifter/10;
    800040e2:	4629                	li	a2,10
        ++p;
    800040e4:	0785                	addi	a5,a5,1
        shifter = shifter/10;
    800040e6:	02c6c6bb          	divw	a3,a3,a2
    }while(shifter);
    800040ea:	feed                	bnez	a3,800040e4 <itoa+0x32>
    *p = '\0';
    800040ec:	00078023          	sb	zero,0(a5)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
    800040f0:	4629                	li	a2,10
    800040f2:	17fd                	addi	a5,a5,-1
    800040f4:	02c766bb          	remw	a3,a4,a2
    800040f8:	ff040593          	addi	a1,s0,-16
    800040fc:	96ae                	add	a3,a3,a1
    800040fe:	ff06c683          	lbu	a3,-16(a3)
    80004102:	00d78023          	sb	a3,0(a5)
        i = i/10;
    80004106:	02c7473b          	divw	a4,a4,a2
    }while(i);
    8000410a:	f765                	bnez	a4,800040f2 <itoa+0x40>
    return b;
}
    8000410c:	6462                	ld	s0,24(sp)
    8000410e:	6105                	addi	sp,sp,32
    80004110:	8082                	ret
        *p++ = '-';
    80004112:	00158793          	addi	a5,a1,1
    80004116:	02d00693          	li	a3,45
    8000411a:	00d58023          	sb	a3,0(a1)
        i *= -1;
    8000411e:	40e0073b          	negw	a4,a4
    80004122:	bf7d                	j	800040e0 <itoa+0x2e>

0000000080004124 <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
    80004124:	711d                	addi	sp,sp,-96
    80004126:	ec86                	sd	ra,88(sp)
    80004128:	e8a2                	sd	s0,80(sp)
    8000412a:	e4a6                	sd	s1,72(sp)
    8000412c:	e0ca                	sd	s2,64(sp)
    8000412e:	1080                	addi	s0,sp,96
    80004130:	84aa                	mv	s1,a0
  //path of proccess
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    80004132:	4619                	li	a2,6
    80004134:	00004597          	auipc	a1,0x4
    80004138:	50458593          	addi	a1,a1,1284 # 80008638 <syscalls+0x1e8>
    8000413c:	fd040513          	addi	a0,s0,-48
    80004140:	ffffd097          	auipc	ra,0xffffd
    80004144:	bda080e7          	jalr	-1062(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    80004148:	fd640593          	addi	a1,s0,-42
    8000414c:	5888                	lw	a0,48(s1)
    8000414e:	00000097          	auipc	ra,0x0
    80004152:	f64080e7          	jalr	-156(ra) # 800040b2 <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if(0 == p->swapFile)
    80004156:	1684b503          	ld	a0,360(s1)
    8000415a:	16050763          	beqz	a0,800042c8 <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    8000415e:	00001097          	auipc	ra,0x1
    80004162:	918080e7          	jalr	-1768(ra) # 80004a76 <fileclose>

  begin_op();
    80004166:	00000097          	auipc	ra,0x0
    8000416a:	444080e7          	jalr	1092(ra) # 800045aa <begin_op>
  if((dp = nameiparent(path, name)) == 0)
    8000416e:	fb040593          	addi	a1,s0,-80
    80004172:	fd040513          	addi	a0,s0,-48
    80004176:	00000097          	auipc	ra,0x0
    8000417a:	f20080e7          	jalr	-224(ra) # 80004096 <nameiparent>
    8000417e:	892a                	mv	s2,a0
    80004180:	cd69                	beqz	a0,8000425a <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    80004182:	fffff097          	auipc	ra,0xfffff
    80004186:	740080e7          	jalr	1856(ra) # 800038c2 <ilock>

    // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000418a:	00004597          	auipc	a1,0x4
    8000418e:	4b658593          	addi	a1,a1,1206 # 80008640 <syscalls+0x1f0>
    80004192:	fb040513          	addi	a0,s0,-80
    80004196:	00000097          	auipc	ra,0x0
    8000419a:	bf6080e7          	jalr	-1034(ra) # 80003d8c <namecmp>
    8000419e:	c57d                	beqz	a0,8000428c <removeSwapFile+0x168>
    800041a0:	00004597          	auipc	a1,0x4
    800041a4:	4a858593          	addi	a1,a1,1192 # 80008648 <syscalls+0x1f8>
    800041a8:	fb040513          	addi	a0,s0,-80
    800041ac:	00000097          	auipc	ra,0x0
    800041b0:	be0080e7          	jalr	-1056(ra) # 80003d8c <namecmp>
    800041b4:	cd61                	beqz	a0,8000428c <removeSwapFile+0x168>
     goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    800041b6:	fac40613          	addi	a2,s0,-84
    800041ba:	fb040593          	addi	a1,s0,-80
    800041be:	854a                	mv	a0,s2
    800041c0:	00000097          	auipc	ra,0x0
    800041c4:	be6080e7          	jalr	-1050(ra) # 80003da6 <dirlookup>
    800041c8:	84aa                	mv	s1,a0
    800041ca:	c169                	beqz	a0,8000428c <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    800041cc:	fffff097          	auipc	ra,0xfffff
    800041d0:	6f6080e7          	jalr	1782(ra) # 800038c2 <ilock>

  if(ip->nlink < 1)
    800041d4:	04a49783          	lh	a5,74(s1)
    800041d8:	08f05763          	blez	a5,80004266 <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    800041dc:	04449703          	lh	a4,68(s1)
    800041e0:	4785                	li	a5,1
    800041e2:	08f70a63          	beq	a4,a5,80004276 <removeSwapFile+0x152>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    800041e6:	4641                	li	a2,16
    800041e8:	4581                	li	a1,0
    800041ea:	fc040513          	addi	a0,s0,-64
    800041ee:	ffffd097          	auipc	ra,0xffffd
    800041f2:	ad0080e7          	jalr	-1328(ra) # 80000cbe <memset>
  if(writei(dp,0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041f6:	4741                	li	a4,16
    800041f8:	fac42683          	lw	a3,-84(s0)
    800041fc:	fc040613          	addi	a2,s0,-64
    80004200:	4581                	li	a1,0
    80004202:	854a                	mv	a0,s2
    80004204:	00000097          	auipc	ra,0x0
    80004208:	a6a080e7          	jalr	-1430(ra) # 80003c6e <writei>
    8000420c:	47c1                	li	a5,16
    8000420e:	08f51a63          	bne	a0,a5,800042a2 <removeSwapFile+0x17e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80004212:	04449703          	lh	a4,68(s1)
    80004216:	4785                	li	a5,1
    80004218:	08f70d63          	beq	a4,a5,800042b2 <removeSwapFile+0x18e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    8000421c:	854a                	mv	a0,s2
    8000421e:	00000097          	auipc	ra,0x0
    80004222:	906080e7          	jalr	-1786(ra) # 80003b24 <iunlockput>

  ip->nlink--;
    80004226:	04a4d783          	lhu	a5,74(s1)
    8000422a:	37fd                	addiw	a5,a5,-1
    8000422c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004230:	8526                	mv	a0,s1
    80004232:	fffff097          	auipc	ra,0xfffff
    80004236:	5c6080e7          	jalr	1478(ra) # 800037f8 <iupdate>
  iunlockput(ip);
    8000423a:	8526                	mv	a0,s1
    8000423c:	00000097          	auipc	ra,0x0
    80004240:	8e8080e7          	jalr	-1816(ra) # 80003b24 <iunlockput>

  end_op();
    80004244:	00000097          	auipc	ra,0x0
    80004248:	3e6080e7          	jalr	998(ra) # 8000462a <end_op>

  return 0;
    8000424c:	4501                	li	a0,0
  bad:
    iunlockput(dp);
    end_op();
    return -1;

}
    8000424e:	60e6                	ld	ra,88(sp)
    80004250:	6446                	ld	s0,80(sp)
    80004252:	64a6                	ld	s1,72(sp)
    80004254:	6906                	ld	s2,64(sp)
    80004256:	6125                	addi	sp,sp,96
    80004258:	8082                	ret
    end_op();
    8000425a:	00000097          	auipc	ra,0x0
    8000425e:	3d0080e7          	jalr	976(ra) # 8000462a <end_op>
    return -1;
    80004262:	557d                	li	a0,-1
    80004264:	b7ed                	j	8000424e <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    80004266:	00004517          	auipc	a0,0x4
    8000426a:	3ea50513          	addi	a0,a0,1002 # 80008650 <syscalls+0x200>
    8000426e:	ffffc097          	auipc	ra,0xffffc
    80004272:	2bc080e7          	jalr	700(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004276:	8526                	mv	a0,s1
    80004278:	00001097          	auipc	ra,0x1
    8000427c:	798080e7          	jalr	1944(ra) # 80005a10 <isdirempty>
    80004280:	f13d                	bnez	a0,800041e6 <removeSwapFile+0xc2>
    iunlockput(ip);
    80004282:	8526                	mv	a0,s1
    80004284:	00000097          	auipc	ra,0x0
    80004288:	8a0080e7          	jalr	-1888(ra) # 80003b24 <iunlockput>
    iunlockput(dp);
    8000428c:	854a                	mv	a0,s2
    8000428e:	00000097          	auipc	ra,0x0
    80004292:	896080e7          	jalr	-1898(ra) # 80003b24 <iunlockput>
    end_op();
    80004296:	00000097          	auipc	ra,0x0
    8000429a:	394080e7          	jalr	916(ra) # 8000462a <end_op>
    return -1;
    8000429e:	557d                	li	a0,-1
    800042a0:	b77d                	j	8000424e <removeSwapFile+0x12a>
    panic("unlink: writei");
    800042a2:	00004517          	auipc	a0,0x4
    800042a6:	3c650513          	addi	a0,a0,966 # 80008668 <syscalls+0x218>
    800042aa:	ffffc097          	auipc	ra,0xffffc
    800042ae:	280080e7          	jalr	640(ra) # 8000052a <panic>
    dp->nlink--;
    800042b2:	04a95783          	lhu	a5,74(s2)
    800042b6:	37fd                	addiw	a5,a5,-1
    800042b8:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800042bc:	854a                	mv	a0,s2
    800042be:	fffff097          	auipc	ra,0xfffff
    800042c2:	53a080e7          	jalr	1338(ra) # 800037f8 <iupdate>
    800042c6:	bf99                	j	8000421c <removeSwapFile+0xf8>
    return -1;
    800042c8:	557d                	li	a0,-1
    800042ca:	b751                	j	8000424e <removeSwapFile+0x12a>

00000000800042cc <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
    800042cc:	7179                	addi	sp,sp,-48
    800042ce:	f406                	sd	ra,40(sp)
    800042d0:	f022                	sd	s0,32(sp)
    800042d2:	ec26                	sd	s1,24(sp)
    800042d4:	e84a                	sd	s2,16(sp)
    800042d6:	1800                	addi	s0,sp,48
    800042d8:	84aa                	mv	s1,a0

  char path[DIGITS];
  memmove(path,"/.swap", 6);
    800042da:	4619                	li	a2,6
    800042dc:	00004597          	auipc	a1,0x4
    800042e0:	35c58593          	addi	a1,a1,860 # 80008638 <syscalls+0x1e8>
    800042e4:	fd040513          	addi	a0,s0,-48
    800042e8:	ffffd097          	auipc	ra,0xffffd
    800042ec:	a32080e7          	jalr	-1486(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    800042f0:	fd640593          	addi	a1,s0,-42
    800042f4:	5888                	lw	a0,48(s1)
    800042f6:	00000097          	auipc	ra,0x0
    800042fa:	dbc080e7          	jalr	-580(ra) # 800040b2 <itoa>

  begin_op();
    800042fe:	00000097          	auipc	ra,0x0
    80004302:	2ac080e7          	jalr	684(ra) # 800045aa <begin_op>
  
  struct inode * in = create(path, T_FILE, 0, 0);
    80004306:	4681                	li	a3,0
    80004308:	4601                	li	a2,0
    8000430a:	4589                	li	a1,2
    8000430c:	fd040513          	addi	a0,s0,-48
    80004310:	00002097          	auipc	ra,0x2
    80004314:	8f4080e7          	jalr	-1804(ra) # 80005c04 <create>
    80004318:	892a                	mv	s2,a0
  iunlock(in);
    8000431a:	fffff097          	auipc	ra,0xfffff
    8000431e:	66a080e7          	jalr	1642(ra) # 80003984 <iunlock>
  p->swapFile = filealloc();
    80004322:	00000097          	auipc	ra,0x0
    80004326:	698080e7          	jalr	1688(ra) # 800049ba <filealloc>
    8000432a:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    8000432e:	cd1d                	beqz	a0,8000436c <createSwapFile+0xa0>
    panic("no slot for files on /store");

  p->swapFile->ip = in;
    80004330:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    80004334:	1684b703          	ld	a4,360(s1)
    80004338:	4789                	li	a5,2
    8000433a:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    8000433c:	1684b703          	ld	a4,360(s1)
    80004340:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    80004344:	1684b703          	ld	a4,360(s1)
    80004348:	4685                	li	a3,1
    8000434a:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    8000434e:	1684b703          	ld	a4,360(s1)
    80004352:	00f704a3          	sb	a5,9(a4)
    end_op();
    80004356:	00000097          	auipc	ra,0x0
    8000435a:	2d4080e7          	jalr	724(ra) # 8000462a <end_op>

    return 0;
}
    8000435e:	4501                	li	a0,0
    80004360:	70a2                	ld	ra,40(sp)
    80004362:	7402                	ld	s0,32(sp)
    80004364:	64e2                	ld	s1,24(sp)
    80004366:	6942                	ld	s2,16(sp)
    80004368:	6145                	addi	sp,sp,48
    8000436a:	8082                	ret
    panic("no slot for files on /store");
    8000436c:	00004517          	auipc	a0,0x4
    80004370:	30c50513          	addi	a0,a0,780 # 80008678 <syscalls+0x228>
    80004374:	ffffc097          	auipc	ra,0xffffc
    80004378:	1b6080e7          	jalr	438(ra) # 8000052a <panic>

000000008000437c <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    8000437c:	1141                	addi	sp,sp,-16
    8000437e:	e406                	sd	ra,8(sp)
    80004380:	e022                	sd	s0,0(sp)
    80004382:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004384:	16853783          	ld	a5,360(a0)
    80004388:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    8000438a:	8636                	mv	a2,a3
    8000438c:	16853503          	ld	a0,360(a0)
    80004390:	00001097          	auipc	ra,0x1
    80004394:	ad8080e7          	jalr	-1320(ra) # 80004e68 <kfilewrite>
}
    80004398:	60a2                	ld	ra,8(sp)
    8000439a:	6402                	ld	s0,0(sp)
    8000439c:	0141                	addi	sp,sp,16
    8000439e:	8082                	ret

00000000800043a0 <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    800043a0:	1141                	addi	sp,sp,-16
    800043a2:	e406                	sd	ra,8(sp)
    800043a4:	e022                	sd	s0,0(sp)
    800043a6:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    800043a8:	16853783          	ld	a5,360(a0)
    800043ac:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer,  size);
    800043ae:	8636                	mv	a2,a3
    800043b0:	16853503          	ld	a0,360(a0)
    800043b4:	00001097          	auipc	ra,0x1
    800043b8:	9f2080e7          	jalr	-1550(ra) # 80004da6 <kfileread>
    800043bc:	60a2                	ld	ra,8(sp)
    800043be:	6402                	ld	s0,0(sp)
    800043c0:	0141                	addi	sp,sp,16
    800043c2:	8082                	ret

00000000800043c4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800043c4:	1101                	addi	sp,sp,-32
    800043c6:	ec06                	sd	ra,24(sp)
    800043c8:	e822                	sd	s0,16(sp)
    800043ca:	e426                	sd	s1,8(sp)
    800043cc:	e04a                	sd	s2,0(sp)
    800043ce:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800043d0:	00022917          	auipc	s2,0x22
    800043d4:	4a090913          	addi	s2,s2,1184 # 80026870 <log>
    800043d8:	01892583          	lw	a1,24(s2)
    800043dc:	02892503          	lw	a0,40(s2)
    800043e0:	fffff097          	auipc	ra,0xfffff
    800043e4:	cde080e7          	jalr	-802(ra) # 800030be <bread>
    800043e8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800043ea:	02c92683          	lw	a3,44(s2)
    800043ee:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800043f0:	02d05863          	blez	a3,80004420 <write_head+0x5c>
    800043f4:	00022797          	auipc	a5,0x22
    800043f8:	4ac78793          	addi	a5,a5,1196 # 800268a0 <log+0x30>
    800043fc:	05c50713          	addi	a4,a0,92
    80004400:	36fd                	addiw	a3,a3,-1
    80004402:	02069613          	slli	a2,a3,0x20
    80004406:	01e65693          	srli	a3,a2,0x1e
    8000440a:	00022617          	auipc	a2,0x22
    8000440e:	49a60613          	addi	a2,a2,1178 # 800268a4 <log+0x34>
    80004412:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004414:	4390                	lw	a2,0(a5)
    80004416:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004418:	0791                	addi	a5,a5,4
    8000441a:	0711                	addi	a4,a4,4
    8000441c:	fed79ce3          	bne	a5,a3,80004414 <write_head+0x50>
  }
  bwrite(buf);
    80004420:	8526                	mv	a0,s1
    80004422:	fffff097          	auipc	ra,0xfffff
    80004426:	d8e080e7          	jalr	-626(ra) # 800031b0 <bwrite>
  brelse(buf);
    8000442a:	8526                	mv	a0,s1
    8000442c:	fffff097          	auipc	ra,0xfffff
    80004430:	dc2080e7          	jalr	-574(ra) # 800031ee <brelse>
}
    80004434:	60e2                	ld	ra,24(sp)
    80004436:	6442                	ld	s0,16(sp)
    80004438:	64a2                	ld	s1,8(sp)
    8000443a:	6902                	ld	s2,0(sp)
    8000443c:	6105                	addi	sp,sp,32
    8000443e:	8082                	ret

0000000080004440 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004440:	00022797          	auipc	a5,0x22
    80004444:	45c7a783          	lw	a5,1116(a5) # 8002689c <log+0x2c>
    80004448:	0af05d63          	blez	a5,80004502 <install_trans+0xc2>
{
    8000444c:	7139                	addi	sp,sp,-64
    8000444e:	fc06                	sd	ra,56(sp)
    80004450:	f822                	sd	s0,48(sp)
    80004452:	f426                	sd	s1,40(sp)
    80004454:	f04a                	sd	s2,32(sp)
    80004456:	ec4e                	sd	s3,24(sp)
    80004458:	e852                	sd	s4,16(sp)
    8000445a:	e456                	sd	s5,8(sp)
    8000445c:	e05a                	sd	s6,0(sp)
    8000445e:	0080                	addi	s0,sp,64
    80004460:	8b2a                	mv	s6,a0
    80004462:	00022a97          	auipc	s5,0x22
    80004466:	43ea8a93          	addi	s5,s5,1086 # 800268a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000446a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000446c:	00022997          	auipc	s3,0x22
    80004470:	40498993          	addi	s3,s3,1028 # 80026870 <log>
    80004474:	a00d                	j	80004496 <install_trans+0x56>
    brelse(lbuf);
    80004476:	854a                	mv	a0,s2
    80004478:	fffff097          	auipc	ra,0xfffff
    8000447c:	d76080e7          	jalr	-650(ra) # 800031ee <brelse>
    brelse(dbuf);
    80004480:	8526                	mv	a0,s1
    80004482:	fffff097          	auipc	ra,0xfffff
    80004486:	d6c080e7          	jalr	-660(ra) # 800031ee <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000448a:	2a05                	addiw	s4,s4,1
    8000448c:	0a91                	addi	s5,s5,4
    8000448e:	02c9a783          	lw	a5,44(s3)
    80004492:	04fa5e63          	bge	s4,a5,800044ee <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004496:	0189a583          	lw	a1,24(s3)
    8000449a:	014585bb          	addw	a1,a1,s4
    8000449e:	2585                	addiw	a1,a1,1
    800044a0:	0289a503          	lw	a0,40(s3)
    800044a4:	fffff097          	auipc	ra,0xfffff
    800044a8:	c1a080e7          	jalr	-998(ra) # 800030be <bread>
    800044ac:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800044ae:	000aa583          	lw	a1,0(s5)
    800044b2:	0289a503          	lw	a0,40(s3)
    800044b6:	fffff097          	auipc	ra,0xfffff
    800044ba:	c08080e7          	jalr	-1016(ra) # 800030be <bread>
    800044be:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800044c0:	40000613          	li	a2,1024
    800044c4:	05890593          	addi	a1,s2,88
    800044c8:	05850513          	addi	a0,a0,88
    800044cc:	ffffd097          	auipc	ra,0xffffd
    800044d0:	84e080e7          	jalr	-1970(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    800044d4:	8526                	mv	a0,s1
    800044d6:	fffff097          	auipc	ra,0xfffff
    800044da:	cda080e7          	jalr	-806(ra) # 800031b0 <bwrite>
    if(recovering == 0)
    800044de:	f80b1ce3          	bnez	s6,80004476 <install_trans+0x36>
      bunpin(dbuf);
    800044e2:	8526                	mv	a0,s1
    800044e4:	fffff097          	auipc	ra,0xfffff
    800044e8:	de4080e7          	jalr	-540(ra) # 800032c8 <bunpin>
    800044ec:	b769                	j	80004476 <install_trans+0x36>
}
    800044ee:	70e2                	ld	ra,56(sp)
    800044f0:	7442                	ld	s0,48(sp)
    800044f2:	74a2                	ld	s1,40(sp)
    800044f4:	7902                	ld	s2,32(sp)
    800044f6:	69e2                	ld	s3,24(sp)
    800044f8:	6a42                	ld	s4,16(sp)
    800044fa:	6aa2                	ld	s5,8(sp)
    800044fc:	6b02                	ld	s6,0(sp)
    800044fe:	6121                	addi	sp,sp,64
    80004500:	8082                	ret
    80004502:	8082                	ret

0000000080004504 <initlog>:
{
    80004504:	7179                	addi	sp,sp,-48
    80004506:	f406                	sd	ra,40(sp)
    80004508:	f022                	sd	s0,32(sp)
    8000450a:	ec26                	sd	s1,24(sp)
    8000450c:	e84a                	sd	s2,16(sp)
    8000450e:	e44e                	sd	s3,8(sp)
    80004510:	1800                	addi	s0,sp,48
    80004512:	892a                	mv	s2,a0
    80004514:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004516:	00022497          	auipc	s1,0x22
    8000451a:	35a48493          	addi	s1,s1,858 # 80026870 <log>
    8000451e:	00004597          	auipc	a1,0x4
    80004522:	17a58593          	addi	a1,a1,378 # 80008698 <syscalls+0x248>
    80004526:	8526                	mv	a0,s1
    80004528:	ffffc097          	auipc	ra,0xffffc
    8000452c:	60a080e7          	jalr	1546(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004530:	0149a583          	lw	a1,20(s3)
    80004534:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004536:	0109a783          	lw	a5,16(s3)
    8000453a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000453c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004540:	854a                	mv	a0,s2
    80004542:	fffff097          	auipc	ra,0xfffff
    80004546:	b7c080e7          	jalr	-1156(ra) # 800030be <bread>
  log.lh.n = lh->n;
    8000454a:	4d34                	lw	a3,88(a0)
    8000454c:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000454e:	02d05663          	blez	a3,8000457a <initlog+0x76>
    80004552:	05c50793          	addi	a5,a0,92
    80004556:	00022717          	auipc	a4,0x22
    8000455a:	34a70713          	addi	a4,a4,842 # 800268a0 <log+0x30>
    8000455e:	36fd                	addiw	a3,a3,-1
    80004560:	02069613          	slli	a2,a3,0x20
    80004564:	01e65693          	srli	a3,a2,0x1e
    80004568:	06050613          	addi	a2,a0,96
    8000456c:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000456e:	4390                	lw	a2,0(a5)
    80004570:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004572:	0791                	addi	a5,a5,4
    80004574:	0711                	addi	a4,a4,4
    80004576:	fed79ce3          	bne	a5,a3,8000456e <initlog+0x6a>
  brelse(buf);
    8000457a:	fffff097          	auipc	ra,0xfffff
    8000457e:	c74080e7          	jalr	-908(ra) # 800031ee <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004582:	4505                	li	a0,1
    80004584:	00000097          	auipc	ra,0x0
    80004588:	ebc080e7          	jalr	-324(ra) # 80004440 <install_trans>
  log.lh.n = 0;
    8000458c:	00022797          	auipc	a5,0x22
    80004590:	3007a823          	sw	zero,784(a5) # 8002689c <log+0x2c>
  write_head(); // clear the log
    80004594:	00000097          	auipc	ra,0x0
    80004598:	e30080e7          	jalr	-464(ra) # 800043c4 <write_head>
}
    8000459c:	70a2                	ld	ra,40(sp)
    8000459e:	7402                	ld	s0,32(sp)
    800045a0:	64e2                	ld	s1,24(sp)
    800045a2:	6942                	ld	s2,16(sp)
    800045a4:	69a2                	ld	s3,8(sp)
    800045a6:	6145                	addi	sp,sp,48
    800045a8:	8082                	ret

00000000800045aa <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800045aa:	1101                	addi	sp,sp,-32
    800045ac:	ec06                	sd	ra,24(sp)
    800045ae:	e822                	sd	s0,16(sp)
    800045b0:	e426                	sd	s1,8(sp)
    800045b2:	e04a                	sd	s2,0(sp)
    800045b4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800045b6:	00022517          	auipc	a0,0x22
    800045ba:	2ba50513          	addi	a0,a0,698 # 80026870 <log>
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	604080e7          	jalr	1540(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    800045c6:	00022497          	auipc	s1,0x22
    800045ca:	2aa48493          	addi	s1,s1,682 # 80026870 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045ce:	4979                	li	s2,30
    800045d0:	a039                	j	800045de <begin_op+0x34>
      sleep(&log, &log.lock);
    800045d2:	85a6                	mv	a1,s1
    800045d4:	8526                	mv	a0,s1
    800045d6:	ffffe097          	auipc	ra,0xffffe
    800045da:	d58080e7          	jalr	-680(ra) # 8000232e <sleep>
    if(log.committing){
    800045de:	50dc                	lw	a5,36(s1)
    800045e0:	fbed                	bnez	a5,800045d2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045e2:	509c                	lw	a5,32(s1)
    800045e4:	0017871b          	addiw	a4,a5,1
    800045e8:	0007069b          	sext.w	a3,a4
    800045ec:	0027179b          	slliw	a5,a4,0x2
    800045f0:	9fb9                	addw	a5,a5,a4
    800045f2:	0017979b          	slliw	a5,a5,0x1
    800045f6:	54d8                	lw	a4,44(s1)
    800045f8:	9fb9                	addw	a5,a5,a4
    800045fa:	00f95963          	bge	s2,a5,8000460c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800045fe:	85a6                	mv	a1,s1
    80004600:	8526                	mv	a0,s1
    80004602:	ffffe097          	auipc	ra,0xffffe
    80004606:	d2c080e7          	jalr	-724(ra) # 8000232e <sleep>
    8000460a:	bfd1                	j	800045de <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000460c:	00022517          	auipc	a0,0x22
    80004610:	26450513          	addi	a0,a0,612 # 80026870 <log>
    80004614:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004616:	ffffc097          	auipc	ra,0xffffc
    8000461a:	660080e7          	jalr	1632(ra) # 80000c76 <release>
      break;
    }
  }
}
    8000461e:	60e2                	ld	ra,24(sp)
    80004620:	6442                	ld	s0,16(sp)
    80004622:	64a2                	ld	s1,8(sp)
    80004624:	6902                	ld	s2,0(sp)
    80004626:	6105                	addi	sp,sp,32
    80004628:	8082                	ret

000000008000462a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000462a:	7139                	addi	sp,sp,-64
    8000462c:	fc06                	sd	ra,56(sp)
    8000462e:	f822                	sd	s0,48(sp)
    80004630:	f426                	sd	s1,40(sp)
    80004632:	f04a                	sd	s2,32(sp)
    80004634:	ec4e                	sd	s3,24(sp)
    80004636:	e852                	sd	s4,16(sp)
    80004638:	e456                	sd	s5,8(sp)
    8000463a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000463c:	00022497          	auipc	s1,0x22
    80004640:	23448493          	addi	s1,s1,564 # 80026870 <log>
    80004644:	8526                	mv	a0,s1
    80004646:	ffffc097          	auipc	ra,0xffffc
    8000464a:	57c080e7          	jalr	1404(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    8000464e:	509c                	lw	a5,32(s1)
    80004650:	37fd                	addiw	a5,a5,-1
    80004652:	0007891b          	sext.w	s2,a5
    80004656:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004658:	50dc                	lw	a5,36(s1)
    8000465a:	e7b9                	bnez	a5,800046a8 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000465c:	04091e63          	bnez	s2,800046b8 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004660:	00022497          	auipc	s1,0x22
    80004664:	21048493          	addi	s1,s1,528 # 80026870 <log>
    80004668:	4785                	li	a5,1
    8000466a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000466c:	8526                	mv	a0,s1
    8000466e:	ffffc097          	auipc	ra,0xffffc
    80004672:	608080e7          	jalr	1544(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004676:	54dc                	lw	a5,44(s1)
    80004678:	06f04763          	bgtz	a5,800046e6 <end_op+0xbc>
    acquire(&log.lock);
    8000467c:	00022497          	auipc	s1,0x22
    80004680:	1f448493          	addi	s1,s1,500 # 80026870 <log>
    80004684:	8526                	mv	a0,s1
    80004686:	ffffc097          	auipc	ra,0xffffc
    8000468a:	53c080e7          	jalr	1340(ra) # 80000bc2 <acquire>
    log.committing = 0;
    8000468e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004692:	8526                	mv	a0,s1
    80004694:	ffffe097          	auipc	ra,0xffffe
    80004698:	e26080e7          	jalr	-474(ra) # 800024ba <wakeup>
    release(&log.lock);
    8000469c:	8526                	mv	a0,s1
    8000469e:	ffffc097          	auipc	ra,0xffffc
    800046a2:	5d8080e7          	jalr	1496(ra) # 80000c76 <release>
}
    800046a6:	a03d                	j	800046d4 <end_op+0xaa>
    panic("log.committing");
    800046a8:	00004517          	auipc	a0,0x4
    800046ac:	ff850513          	addi	a0,a0,-8 # 800086a0 <syscalls+0x250>
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	e7a080e7          	jalr	-390(ra) # 8000052a <panic>
    wakeup(&log);
    800046b8:	00022497          	auipc	s1,0x22
    800046bc:	1b848493          	addi	s1,s1,440 # 80026870 <log>
    800046c0:	8526                	mv	a0,s1
    800046c2:	ffffe097          	auipc	ra,0xffffe
    800046c6:	df8080e7          	jalr	-520(ra) # 800024ba <wakeup>
  release(&log.lock);
    800046ca:	8526                	mv	a0,s1
    800046cc:	ffffc097          	auipc	ra,0xffffc
    800046d0:	5aa080e7          	jalr	1450(ra) # 80000c76 <release>
}
    800046d4:	70e2                	ld	ra,56(sp)
    800046d6:	7442                	ld	s0,48(sp)
    800046d8:	74a2                	ld	s1,40(sp)
    800046da:	7902                	ld	s2,32(sp)
    800046dc:	69e2                	ld	s3,24(sp)
    800046de:	6a42                	ld	s4,16(sp)
    800046e0:	6aa2                	ld	s5,8(sp)
    800046e2:	6121                	addi	sp,sp,64
    800046e4:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800046e6:	00022a97          	auipc	s5,0x22
    800046ea:	1baa8a93          	addi	s5,s5,442 # 800268a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800046ee:	00022a17          	auipc	s4,0x22
    800046f2:	182a0a13          	addi	s4,s4,386 # 80026870 <log>
    800046f6:	018a2583          	lw	a1,24(s4)
    800046fa:	012585bb          	addw	a1,a1,s2
    800046fe:	2585                	addiw	a1,a1,1
    80004700:	028a2503          	lw	a0,40(s4)
    80004704:	fffff097          	auipc	ra,0xfffff
    80004708:	9ba080e7          	jalr	-1606(ra) # 800030be <bread>
    8000470c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000470e:	000aa583          	lw	a1,0(s5)
    80004712:	028a2503          	lw	a0,40(s4)
    80004716:	fffff097          	auipc	ra,0xfffff
    8000471a:	9a8080e7          	jalr	-1624(ra) # 800030be <bread>
    8000471e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004720:	40000613          	li	a2,1024
    80004724:	05850593          	addi	a1,a0,88
    80004728:	05848513          	addi	a0,s1,88
    8000472c:	ffffc097          	auipc	ra,0xffffc
    80004730:	5ee080e7          	jalr	1518(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004734:	8526                	mv	a0,s1
    80004736:	fffff097          	auipc	ra,0xfffff
    8000473a:	a7a080e7          	jalr	-1414(ra) # 800031b0 <bwrite>
    brelse(from);
    8000473e:	854e                	mv	a0,s3
    80004740:	fffff097          	auipc	ra,0xfffff
    80004744:	aae080e7          	jalr	-1362(ra) # 800031ee <brelse>
    brelse(to);
    80004748:	8526                	mv	a0,s1
    8000474a:	fffff097          	auipc	ra,0xfffff
    8000474e:	aa4080e7          	jalr	-1372(ra) # 800031ee <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004752:	2905                	addiw	s2,s2,1
    80004754:	0a91                	addi	s5,s5,4
    80004756:	02ca2783          	lw	a5,44(s4)
    8000475a:	f8f94ee3          	blt	s2,a5,800046f6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000475e:	00000097          	auipc	ra,0x0
    80004762:	c66080e7          	jalr	-922(ra) # 800043c4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004766:	4501                	li	a0,0
    80004768:	00000097          	auipc	ra,0x0
    8000476c:	cd8080e7          	jalr	-808(ra) # 80004440 <install_trans>
    log.lh.n = 0;
    80004770:	00022797          	auipc	a5,0x22
    80004774:	1207a623          	sw	zero,300(a5) # 8002689c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004778:	00000097          	auipc	ra,0x0
    8000477c:	c4c080e7          	jalr	-948(ra) # 800043c4 <write_head>
    80004780:	bdf5                	j	8000467c <end_op+0x52>

0000000080004782 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004782:	1101                	addi	sp,sp,-32
    80004784:	ec06                	sd	ra,24(sp)
    80004786:	e822                	sd	s0,16(sp)
    80004788:	e426                	sd	s1,8(sp)
    8000478a:	e04a                	sd	s2,0(sp)
    8000478c:	1000                	addi	s0,sp,32
    8000478e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004790:	00022917          	auipc	s2,0x22
    80004794:	0e090913          	addi	s2,s2,224 # 80026870 <log>
    80004798:	854a                	mv	a0,s2
    8000479a:	ffffc097          	auipc	ra,0xffffc
    8000479e:	428080e7          	jalr	1064(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800047a2:	02c92603          	lw	a2,44(s2)
    800047a6:	47f5                	li	a5,29
    800047a8:	06c7c563          	blt	a5,a2,80004812 <log_write+0x90>
    800047ac:	00022797          	auipc	a5,0x22
    800047b0:	0e07a783          	lw	a5,224(a5) # 8002688c <log+0x1c>
    800047b4:	37fd                	addiw	a5,a5,-1
    800047b6:	04f65e63          	bge	a2,a5,80004812 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800047ba:	00022797          	auipc	a5,0x22
    800047be:	0d67a783          	lw	a5,214(a5) # 80026890 <log+0x20>
    800047c2:	06f05063          	blez	a5,80004822 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800047c6:	4781                	li	a5,0
    800047c8:	06c05563          	blez	a2,80004832 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800047cc:	44cc                	lw	a1,12(s1)
    800047ce:	00022717          	auipc	a4,0x22
    800047d2:	0d270713          	addi	a4,a4,210 # 800268a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800047d6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800047d8:	4314                	lw	a3,0(a4)
    800047da:	04b68c63          	beq	a3,a1,80004832 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800047de:	2785                	addiw	a5,a5,1
    800047e0:	0711                	addi	a4,a4,4
    800047e2:	fef61be3          	bne	a2,a5,800047d8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800047e6:	0621                	addi	a2,a2,8
    800047e8:	060a                	slli	a2,a2,0x2
    800047ea:	00022797          	auipc	a5,0x22
    800047ee:	08678793          	addi	a5,a5,134 # 80026870 <log>
    800047f2:	963e                	add	a2,a2,a5
    800047f4:	44dc                	lw	a5,12(s1)
    800047f6:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800047f8:	8526                	mv	a0,s1
    800047fa:	fffff097          	auipc	ra,0xfffff
    800047fe:	a92080e7          	jalr	-1390(ra) # 8000328c <bpin>
    log.lh.n++;
    80004802:	00022717          	auipc	a4,0x22
    80004806:	06e70713          	addi	a4,a4,110 # 80026870 <log>
    8000480a:	575c                	lw	a5,44(a4)
    8000480c:	2785                	addiw	a5,a5,1
    8000480e:	d75c                	sw	a5,44(a4)
    80004810:	a835                	j	8000484c <log_write+0xca>
    panic("too big a transaction");
    80004812:	00004517          	auipc	a0,0x4
    80004816:	e9e50513          	addi	a0,a0,-354 # 800086b0 <syscalls+0x260>
    8000481a:	ffffc097          	auipc	ra,0xffffc
    8000481e:	d10080e7          	jalr	-752(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004822:	00004517          	auipc	a0,0x4
    80004826:	ea650513          	addi	a0,a0,-346 # 800086c8 <syscalls+0x278>
    8000482a:	ffffc097          	auipc	ra,0xffffc
    8000482e:	d00080e7          	jalr	-768(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004832:	00878713          	addi	a4,a5,8
    80004836:	00271693          	slli	a3,a4,0x2
    8000483a:	00022717          	auipc	a4,0x22
    8000483e:	03670713          	addi	a4,a4,54 # 80026870 <log>
    80004842:	9736                	add	a4,a4,a3
    80004844:	44d4                	lw	a3,12(s1)
    80004846:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004848:	faf608e3          	beq	a2,a5,800047f8 <log_write+0x76>
  }
  release(&log.lock);
    8000484c:	00022517          	auipc	a0,0x22
    80004850:	02450513          	addi	a0,a0,36 # 80026870 <log>
    80004854:	ffffc097          	auipc	ra,0xffffc
    80004858:	422080e7          	jalr	1058(ra) # 80000c76 <release>
}
    8000485c:	60e2                	ld	ra,24(sp)
    8000485e:	6442                	ld	s0,16(sp)
    80004860:	64a2                	ld	s1,8(sp)
    80004862:	6902                	ld	s2,0(sp)
    80004864:	6105                	addi	sp,sp,32
    80004866:	8082                	ret

0000000080004868 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004868:	1101                	addi	sp,sp,-32
    8000486a:	ec06                	sd	ra,24(sp)
    8000486c:	e822                	sd	s0,16(sp)
    8000486e:	e426                	sd	s1,8(sp)
    80004870:	e04a                	sd	s2,0(sp)
    80004872:	1000                	addi	s0,sp,32
    80004874:	84aa                	mv	s1,a0
    80004876:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004878:	00004597          	auipc	a1,0x4
    8000487c:	e7058593          	addi	a1,a1,-400 # 800086e8 <syscalls+0x298>
    80004880:	0521                	addi	a0,a0,8
    80004882:	ffffc097          	auipc	ra,0xffffc
    80004886:	2b0080e7          	jalr	688(ra) # 80000b32 <initlock>
  lk->name = name;
    8000488a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000488e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004892:	0204a423          	sw	zero,40(s1)
}
    80004896:	60e2                	ld	ra,24(sp)
    80004898:	6442                	ld	s0,16(sp)
    8000489a:	64a2                	ld	s1,8(sp)
    8000489c:	6902                	ld	s2,0(sp)
    8000489e:	6105                	addi	sp,sp,32
    800048a0:	8082                	ret

00000000800048a2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800048a2:	1101                	addi	sp,sp,-32
    800048a4:	ec06                	sd	ra,24(sp)
    800048a6:	e822                	sd	s0,16(sp)
    800048a8:	e426                	sd	s1,8(sp)
    800048aa:	e04a                	sd	s2,0(sp)
    800048ac:	1000                	addi	s0,sp,32
    800048ae:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048b0:	00850913          	addi	s2,a0,8
    800048b4:	854a                	mv	a0,s2
    800048b6:	ffffc097          	auipc	ra,0xffffc
    800048ba:	30c080e7          	jalr	780(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    800048be:	409c                	lw	a5,0(s1)
    800048c0:	cb89                	beqz	a5,800048d2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800048c2:	85ca                	mv	a1,s2
    800048c4:	8526                	mv	a0,s1
    800048c6:	ffffe097          	auipc	ra,0xffffe
    800048ca:	a68080e7          	jalr	-1432(ra) # 8000232e <sleep>
  while (lk->locked) {
    800048ce:	409c                	lw	a5,0(s1)
    800048d0:	fbed                	bnez	a5,800048c2 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800048d2:	4785                	li	a5,1
    800048d4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800048d6:	ffffd097          	auipc	ra,0xffffd
    800048da:	2a6080e7          	jalr	678(ra) # 80001b7c <myproc>
    800048de:	591c                	lw	a5,48(a0)
    800048e0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800048e2:	854a                	mv	a0,s2
    800048e4:	ffffc097          	auipc	ra,0xffffc
    800048e8:	392080e7          	jalr	914(ra) # 80000c76 <release>
}
    800048ec:	60e2                	ld	ra,24(sp)
    800048ee:	6442                	ld	s0,16(sp)
    800048f0:	64a2                	ld	s1,8(sp)
    800048f2:	6902                	ld	s2,0(sp)
    800048f4:	6105                	addi	sp,sp,32
    800048f6:	8082                	ret

00000000800048f8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800048f8:	1101                	addi	sp,sp,-32
    800048fa:	ec06                	sd	ra,24(sp)
    800048fc:	e822                	sd	s0,16(sp)
    800048fe:	e426                	sd	s1,8(sp)
    80004900:	e04a                	sd	s2,0(sp)
    80004902:	1000                	addi	s0,sp,32
    80004904:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004906:	00850913          	addi	s2,a0,8
    8000490a:	854a                	mv	a0,s2
    8000490c:	ffffc097          	auipc	ra,0xffffc
    80004910:	2b6080e7          	jalr	694(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004914:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004918:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000491c:	8526                	mv	a0,s1
    8000491e:	ffffe097          	auipc	ra,0xffffe
    80004922:	b9c080e7          	jalr	-1124(ra) # 800024ba <wakeup>
  release(&lk->lk);
    80004926:	854a                	mv	a0,s2
    80004928:	ffffc097          	auipc	ra,0xffffc
    8000492c:	34e080e7          	jalr	846(ra) # 80000c76 <release>
}
    80004930:	60e2                	ld	ra,24(sp)
    80004932:	6442                	ld	s0,16(sp)
    80004934:	64a2                	ld	s1,8(sp)
    80004936:	6902                	ld	s2,0(sp)
    80004938:	6105                	addi	sp,sp,32
    8000493a:	8082                	ret

000000008000493c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000493c:	7179                	addi	sp,sp,-48
    8000493e:	f406                	sd	ra,40(sp)
    80004940:	f022                	sd	s0,32(sp)
    80004942:	ec26                	sd	s1,24(sp)
    80004944:	e84a                	sd	s2,16(sp)
    80004946:	e44e                	sd	s3,8(sp)
    80004948:	1800                	addi	s0,sp,48
    8000494a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000494c:	00850913          	addi	s2,a0,8
    80004950:	854a                	mv	a0,s2
    80004952:	ffffc097          	auipc	ra,0xffffc
    80004956:	270080e7          	jalr	624(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000495a:	409c                	lw	a5,0(s1)
    8000495c:	ef99                	bnez	a5,8000497a <holdingsleep+0x3e>
    8000495e:	4481                	li	s1,0
  release(&lk->lk);
    80004960:	854a                	mv	a0,s2
    80004962:	ffffc097          	auipc	ra,0xffffc
    80004966:	314080e7          	jalr	788(ra) # 80000c76 <release>
  return r;
}
    8000496a:	8526                	mv	a0,s1
    8000496c:	70a2                	ld	ra,40(sp)
    8000496e:	7402                	ld	s0,32(sp)
    80004970:	64e2                	ld	s1,24(sp)
    80004972:	6942                	ld	s2,16(sp)
    80004974:	69a2                	ld	s3,8(sp)
    80004976:	6145                	addi	sp,sp,48
    80004978:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000497a:	0284a983          	lw	s3,40(s1)
    8000497e:	ffffd097          	auipc	ra,0xffffd
    80004982:	1fe080e7          	jalr	510(ra) # 80001b7c <myproc>
    80004986:	5904                	lw	s1,48(a0)
    80004988:	413484b3          	sub	s1,s1,s3
    8000498c:	0014b493          	seqz	s1,s1
    80004990:	bfc1                	j	80004960 <holdingsleep+0x24>

0000000080004992 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004992:	1141                	addi	sp,sp,-16
    80004994:	e406                	sd	ra,8(sp)
    80004996:	e022                	sd	s0,0(sp)
    80004998:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000499a:	00004597          	auipc	a1,0x4
    8000499e:	d5e58593          	addi	a1,a1,-674 # 800086f8 <syscalls+0x2a8>
    800049a2:	00022517          	auipc	a0,0x22
    800049a6:	01650513          	addi	a0,a0,22 # 800269b8 <ftable>
    800049aa:	ffffc097          	auipc	ra,0xffffc
    800049ae:	188080e7          	jalr	392(ra) # 80000b32 <initlock>
}
    800049b2:	60a2                	ld	ra,8(sp)
    800049b4:	6402                	ld	s0,0(sp)
    800049b6:	0141                	addi	sp,sp,16
    800049b8:	8082                	ret

00000000800049ba <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800049ba:	1101                	addi	sp,sp,-32
    800049bc:	ec06                	sd	ra,24(sp)
    800049be:	e822                	sd	s0,16(sp)
    800049c0:	e426                	sd	s1,8(sp)
    800049c2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800049c4:	00022517          	auipc	a0,0x22
    800049c8:	ff450513          	addi	a0,a0,-12 # 800269b8 <ftable>
    800049cc:	ffffc097          	auipc	ra,0xffffc
    800049d0:	1f6080e7          	jalr	502(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049d4:	00022497          	auipc	s1,0x22
    800049d8:	ffc48493          	addi	s1,s1,-4 # 800269d0 <ftable+0x18>
    800049dc:	00023717          	auipc	a4,0x23
    800049e0:	f9470713          	addi	a4,a4,-108 # 80027970 <ftable+0xfb8>
    if(f->ref == 0){
    800049e4:	40dc                	lw	a5,4(s1)
    800049e6:	cf99                	beqz	a5,80004a04 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049e8:	02848493          	addi	s1,s1,40
    800049ec:	fee49ce3          	bne	s1,a4,800049e4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800049f0:	00022517          	auipc	a0,0x22
    800049f4:	fc850513          	addi	a0,a0,-56 # 800269b8 <ftable>
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	27e080e7          	jalr	638(ra) # 80000c76 <release>
  return 0;
    80004a00:	4481                	li	s1,0
    80004a02:	a819                	j	80004a18 <filealloc+0x5e>
      f->ref = 1;
    80004a04:	4785                	li	a5,1
    80004a06:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a08:	00022517          	auipc	a0,0x22
    80004a0c:	fb050513          	addi	a0,a0,-80 # 800269b8 <ftable>
    80004a10:	ffffc097          	auipc	ra,0xffffc
    80004a14:	266080e7          	jalr	614(ra) # 80000c76 <release>
}
    80004a18:	8526                	mv	a0,s1
    80004a1a:	60e2                	ld	ra,24(sp)
    80004a1c:	6442                	ld	s0,16(sp)
    80004a1e:	64a2                	ld	s1,8(sp)
    80004a20:	6105                	addi	sp,sp,32
    80004a22:	8082                	ret

0000000080004a24 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a24:	1101                	addi	sp,sp,-32
    80004a26:	ec06                	sd	ra,24(sp)
    80004a28:	e822                	sd	s0,16(sp)
    80004a2a:	e426                	sd	s1,8(sp)
    80004a2c:	1000                	addi	s0,sp,32
    80004a2e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a30:	00022517          	auipc	a0,0x22
    80004a34:	f8850513          	addi	a0,a0,-120 # 800269b8 <ftable>
    80004a38:	ffffc097          	auipc	ra,0xffffc
    80004a3c:	18a080e7          	jalr	394(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004a40:	40dc                	lw	a5,4(s1)
    80004a42:	02f05263          	blez	a5,80004a66 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a46:	2785                	addiw	a5,a5,1
    80004a48:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a4a:	00022517          	auipc	a0,0x22
    80004a4e:	f6e50513          	addi	a0,a0,-146 # 800269b8 <ftable>
    80004a52:	ffffc097          	auipc	ra,0xffffc
    80004a56:	224080e7          	jalr	548(ra) # 80000c76 <release>
  return f;
}
    80004a5a:	8526                	mv	a0,s1
    80004a5c:	60e2                	ld	ra,24(sp)
    80004a5e:	6442                	ld	s0,16(sp)
    80004a60:	64a2                	ld	s1,8(sp)
    80004a62:	6105                	addi	sp,sp,32
    80004a64:	8082                	ret
    panic("filedup");
    80004a66:	00004517          	auipc	a0,0x4
    80004a6a:	c9a50513          	addi	a0,a0,-870 # 80008700 <syscalls+0x2b0>
    80004a6e:	ffffc097          	auipc	ra,0xffffc
    80004a72:	abc080e7          	jalr	-1348(ra) # 8000052a <panic>

0000000080004a76 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a76:	7139                	addi	sp,sp,-64
    80004a78:	fc06                	sd	ra,56(sp)
    80004a7a:	f822                	sd	s0,48(sp)
    80004a7c:	f426                	sd	s1,40(sp)
    80004a7e:	f04a                	sd	s2,32(sp)
    80004a80:	ec4e                	sd	s3,24(sp)
    80004a82:	e852                	sd	s4,16(sp)
    80004a84:	e456                	sd	s5,8(sp)
    80004a86:	0080                	addi	s0,sp,64
    80004a88:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a8a:	00022517          	auipc	a0,0x22
    80004a8e:	f2e50513          	addi	a0,a0,-210 # 800269b8 <ftable>
    80004a92:	ffffc097          	auipc	ra,0xffffc
    80004a96:	130080e7          	jalr	304(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004a9a:	40dc                	lw	a5,4(s1)
    80004a9c:	06f05163          	blez	a5,80004afe <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004aa0:	37fd                	addiw	a5,a5,-1
    80004aa2:	0007871b          	sext.w	a4,a5
    80004aa6:	c0dc                	sw	a5,4(s1)
    80004aa8:	06e04363          	bgtz	a4,80004b0e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004aac:	0004a903          	lw	s2,0(s1)
    80004ab0:	0094ca83          	lbu	s5,9(s1)
    80004ab4:	0104ba03          	ld	s4,16(s1)
    80004ab8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004abc:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004ac0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004ac4:	00022517          	auipc	a0,0x22
    80004ac8:	ef450513          	addi	a0,a0,-268 # 800269b8 <ftable>
    80004acc:	ffffc097          	auipc	ra,0xffffc
    80004ad0:	1aa080e7          	jalr	426(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80004ad4:	4785                	li	a5,1
    80004ad6:	04f90d63          	beq	s2,a5,80004b30 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004ada:	3979                	addiw	s2,s2,-2
    80004adc:	4785                	li	a5,1
    80004ade:	0527e063          	bltu	a5,s2,80004b1e <fileclose+0xa8>
    begin_op();
    80004ae2:	00000097          	auipc	ra,0x0
    80004ae6:	ac8080e7          	jalr	-1336(ra) # 800045aa <begin_op>
    iput(ff.ip);
    80004aea:	854e                	mv	a0,s3
    80004aec:	fffff097          	auipc	ra,0xfffff
    80004af0:	f90080e7          	jalr	-112(ra) # 80003a7c <iput>
    end_op();
    80004af4:	00000097          	auipc	ra,0x0
    80004af8:	b36080e7          	jalr	-1226(ra) # 8000462a <end_op>
    80004afc:	a00d                	j	80004b1e <fileclose+0xa8>
    panic("fileclose");
    80004afe:	00004517          	auipc	a0,0x4
    80004b02:	c0a50513          	addi	a0,a0,-1014 # 80008708 <syscalls+0x2b8>
    80004b06:	ffffc097          	auipc	ra,0xffffc
    80004b0a:	a24080e7          	jalr	-1500(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004b0e:	00022517          	auipc	a0,0x22
    80004b12:	eaa50513          	addi	a0,a0,-342 # 800269b8 <ftable>
    80004b16:	ffffc097          	auipc	ra,0xffffc
    80004b1a:	160080e7          	jalr	352(ra) # 80000c76 <release>
  }
}
    80004b1e:	70e2                	ld	ra,56(sp)
    80004b20:	7442                	ld	s0,48(sp)
    80004b22:	74a2                	ld	s1,40(sp)
    80004b24:	7902                	ld	s2,32(sp)
    80004b26:	69e2                	ld	s3,24(sp)
    80004b28:	6a42                	ld	s4,16(sp)
    80004b2a:	6aa2                	ld	s5,8(sp)
    80004b2c:	6121                	addi	sp,sp,64
    80004b2e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b30:	85d6                	mv	a1,s5
    80004b32:	8552                	mv	a0,s4
    80004b34:	00000097          	auipc	ra,0x0
    80004b38:	542080e7          	jalr	1346(ra) # 80005076 <pipeclose>
    80004b3c:	b7cd                	j	80004b1e <fileclose+0xa8>

0000000080004b3e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b3e:	715d                	addi	sp,sp,-80
    80004b40:	e486                	sd	ra,72(sp)
    80004b42:	e0a2                	sd	s0,64(sp)
    80004b44:	fc26                	sd	s1,56(sp)
    80004b46:	f84a                	sd	s2,48(sp)
    80004b48:	f44e                	sd	s3,40(sp)
    80004b4a:	0880                	addi	s0,sp,80
    80004b4c:	84aa                	mv	s1,a0
    80004b4e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b50:	ffffd097          	auipc	ra,0xffffd
    80004b54:	02c080e7          	jalr	44(ra) # 80001b7c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b58:	409c                	lw	a5,0(s1)
    80004b5a:	37f9                	addiw	a5,a5,-2
    80004b5c:	4705                	li	a4,1
    80004b5e:	04f76763          	bltu	a4,a5,80004bac <filestat+0x6e>
    80004b62:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b64:	6c88                	ld	a0,24(s1)
    80004b66:	fffff097          	auipc	ra,0xfffff
    80004b6a:	d5c080e7          	jalr	-676(ra) # 800038c2 <ilock>
    stati(f->ip, &st);
    80004b6e:	fb840593          	addi	a1,s0,-72
    80004b72:	6c88                	ld	a0,24(s1)
    80004b74:	fffff097          	auipc	ra,0xfffff
    80004b78:	fd8080e7          	jalr	-40(ra) # 80003b4c <stati>
    iunlock(f->ip);
    80004b7c:	6c88                	ld	a0,24(s1)
    80004b7e:	fffff097          	auipc	ra,0xfffff
    80004b82:	e06080e7          	jalr	-506(ra) # 80003984 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b86:	46e1                	li	a3,24
    80004b88:	fb840613          	addi	a2,s0,-72
    80004b8c:	85ce                	mv	a1,s3
    80004b8e:	05093503          	ld	a0,80(s2)
    80004b92:	ffffd097          	auipc	ra,0xffffd
    80004b96:	caa080e7          	jalr	-854(ra) # 8000183c <copyout>
    80004b9a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b9e:	60a6                	ld	ra,72(sp)
    80004ba0:	6406                	ld	s0,64(sp)
    80004ba2:	74e2                	ld	s1,56(sp)
    80004ba4:	7942                	ld	s2,48(sp)
    80004ba6:	79a2                	ld	s3,40(sp)
    80004ba8:	6161                	addi	sp,sp,80
    80004baa:	8082                	ret
  return -1;
    80004bac:	557d                	li	a0,-1
    80004bae:	bfc5                	j	80004b9e <filestat+0x60>

0000000080004bb0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004bb0:	7179                	addi	sp,sp,-48
    80004bb2:	f406                	sd	ra,40(sp)
    80004bb4:	f022                	sd	s0,32(sp)
    80004bb6:	ec26                	sd	s1,24(sp)
    80004bb8:	e84a                	sd	s2,16(sp)
    80004bba:	e44e                	sd	s3,8(sp)
    80004bbc:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004bbe:	00854783          	lbu	a5,8(a0)
    80004bc2:	c3d5                	beqz	a5,80004c66 <fileread+0xb6>
    80004bc4:	84aa                	mv	s1,a0
    80004bc6:	89ae                	mv	s3,a1
    80004bc8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bca:	411c                	lw	a5,0(a0)
    80004bcc:	4705                	li	a4,1
    80004bce:	04e78963          	beq	a5,a4,80004c20 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bd2:	470d                	li	a4,3
    80004bd4:	04e78d63          	beq	a5,a4,80004c2e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004bd8:	4709                	li	a4,2
    80004bda:	06e79e63          	bne	a5,a4,80004c56 <fileread+0xa6>
    ilock(f->ip);
    80004bde:	6d08                	ld	a0,24(a0)
    80004be0:	fffff097          	auipc	ra,0xfffff
    80004be4:	ce2080e7          	jalr	-798(ra) # 800038c2 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004be8:	874a                	mv	a4,s2
    80004bea:	5094                	lw	a3,32(s1)
    80004bec:	864e                	mv	a2,s3
    80004bee:	4585                	li	a1,1
    80004bf0:	6c88                	ld	a0,24(s1)
    80004bf2:	fffff097          	auipc	ra,0xfffff
    80004bf6:	f84080e7          	jalr	-124(ra) # 80003b76 <readi>
    80004bfa:	892a                	mv	s2,a0
    80004bfc:	00a05563          	blez	a0,80004c06 <fileread+0x56>
      f->off += r;
    80004c00:	509c                	lw	a5,32(s1)
    80004c02:	9fa9                	addw	a5,a5,a0
    80004c04:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c06:	6c88                	ld	a0,24(s1)
    80004c08:	fffff097          	auipc	ra,0xfffff
    80004c0c:	d7c080e7          	jalr	-644(ra) # 80003984 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c10:	854a                	mv	a0,s2
    80004c12:	70a2                	ld	ra,40(sp)
    80004c14:	7402                	ld	s0,32(sp)
    80004c16:	64e2                	ld	s1,24(sp)
    80004c18:	6942                	ld	s2,16(sp)
    80004c1a:	69a2                	ld	s3,8(sp)
    80004c1c:	6145                	addi	sp,sp,48
    80004c1e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c20:	6908                	ld	a0,16(a0)
    80004c22:	00000097          	auipc	ra,0x0
    80004c26:	5b6080e7          	jalr	1462(ra) # 800051d8 <piperead>
    80004c2a:	892a                	mv	s2,a0
    80004c2c:	b7d5                	j	80004c10 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c2e:	02451783          	lh	a5,36(a0)
    80004c32:	03079693          	slli	a3,a5,0x30
    80004c36:	92c1                	srli	a3,a3,0x30
    80004c38:	4725                	li	a4,9
    80004c3a:	02d76863          	bltu	a4,a3,80004c6a <fileread+0xba>
    80004c3e:	0792                	slli	a5,a5,0x4
    80004c40:	00022717          	auipc	a4,0x22
    80004c44:	cd870713          	addi	a4,a4,-808 # 80026918 <devsw>
    80004c48:	97ba                	add	a5,a5,a4
    80004c4a:	639c                	ld	a5,0(a5)
    80004c4c:	c38d                	beqz	a5,80004c6e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c4e:	4505                	li	a0,1
    80004c50:	9782                	jalr	a5
    80004c52:	892a                	mv	s2,a0
    80004c54:	bf75                	j	80004c10 <fileread+0x60>
    panic("fileread");
    80004c56:	00004517          	auipc	a0,0x4
    80004c5a:	ac250513          	addi	a0,a0,-1342 # 80008718 <syscalls+0x2c8>
    80004c5e:	ffffc097          	auipc	ra,0xffffc
    80004c62:	8cc080e7          	jalr	-1844(ra) # 8000052a <panic>
    return -1;
    80004c66:	597d                	li	s2,-1
    80004c68:	b765                	j	80004c10 <fileread+0x60>
      return -1;
    80004c6a:	597d                	li	s2,-1
    80004c6c:	b755                	j	80004c10 <fileread+0x60>
    80004c6e:	597d                	li	s2,-1
    80004c70:	b745                	j	80004c10 <fileread+0x60>

0000000080004c72 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c72:	715d                	addi	sp,sp,-80
    80004c74:	e486                	sd	ra,72(sp)
    80004c76:	e0a2                	sd	s0,64(sp)
    80004c78:	fc26                	sd	s1,56(sp)
    80004c7a:	f84a                	sd	s2,48(sp)
    80004c7c:	f44e                	sd	s3,40(sp)
    80004c7e:	f052                	sd	s4,32(sp)
    80004c80:	ec56                	sd	s5,24(sp)
    80004c82:	e85a                	sd	s6,16(sp)
    80004c84:	e45e                	sd	s7,8(sp)
    80004c86:	e062                	sd	s8,0(sp)
    80004c88:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004c8a:	00954783          	lbu	a5,9(a0)
    80004c8e:	10078663          	beqz	a5,80004d9a <filewrite+0x128>
    80004c92:	892a                	mv	s2,a0
    80004c94:	8aae                	mv	s5,a1
    80004c96:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c98:	411c                	lw	a5,0(a0)
    80004c9a:	4705                	li	a4,1
    80004c9c:	02e78263          	beq	a5,a4,80004cc0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ca0:	470d                	li	a4,3
    80004ca2:	02e78663          	beq	a5,a4,80004cce <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ca6:	4709                	li	a4,2
    80004ca8:	0ee79163          	bne	a5,a4,80004d8a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004cac:	0ac05d63          	blez	a2,80004d66 <filewrite+0xf4>
    int i = 0;
    80004cb0:	4981                	li	s3,0
    80004cb2:	6b05                	lui	s6,0x1
    80004cb4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004cb8:	6b85                	lui	s7,0x1
    80004cba:	c00b8b9b          	addiw	s7,s7,-1024
    80004cbe:	a861                	j	80004d56 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004cc0:	6908                	ld	a0,16(a0)
    80004cc2:	00000097          	auipc	ra,0x0
    80004cc6:	424080e7          	jalr	1060(ra) # 800050e6 <pipewrite>
    80004cca:	8a2a                	mv	s4,a0
    80004ccc:	a045                	j	80004d6c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004cce:	02451783          	lh	a5,36(a0)
    80004cd2:	03079693          	slli	a3,a5,0x30
    80004cd6:	92c1                	srli	a3,a3,0x30
    80004cd8:	4725                	li	a4,9
    80004cda:	0cd76263          	bltu	a4,a3,80004d9e <filewrite+0x12c>
    80004cde:	0792                	slli	a5,a5,0x4
    80004ce0:	00022717          	auipc	a4,0x22
    80004ce4:	c3870713          	addi	a4,a4,-968 # 80026918 <devsw>
    80004ce8:	97ba                	add	a5,a5,a4
    80004cea:	679c                	ld	a5,8(a5)
    80004cec:	cbdd                	beqz	a5,80004da2 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004cee:	4505                	li	a0,1
    80004cf0:	9782                	jalr	a5
    80004cf2:	8a2a                	mv	s4,a0
    80004cf4:	a8a5                	j	80004d6c <filewrite+0xfa>
    80004cf6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004cfa:	00000097          	auipc	ra,0x0
    80004cfe:	8b0080e7          	jalr	-1872(ra) # 800045aa <begin_op>
      ilock(f->ip);
    80004d02:	01893503          	ld	a0,24(s2)
    80004d06:	fffff097          	auipc	ra,0xfffff
    80004d0a:	bbc080e7          	jalr	-1092(ra) # 800038c2 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d0e:	8762                	mv	a4,s8
    80004d10:	02092683          	lw	a3,32(s2)
    80004d14:	01598633          	add	a2,s3,s5
    80004d18:	4585                	li	a1,1
    80004d1a:	01893503          	ld	a0,24(s2)
    80004d1e:	fffff097          	auipc	ra,0xfffff
    80004d22:	f50080e7          	jalr	-176(ra) # 80003c6e <writei>
    80004d26:	84aa                	mv	s1,a0
    80004d28:	00a05763          	blez	a0,80004d36 <filewrite+0xc4>
        f->off += r;
    80004d2c:	02092783          	lw	a5,32(s2)
    80004d30:	9fa9                	addw	a5,a5,a0
    80004d32:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d36:	01893503          	ld	a0,24(s2)
    80004d3a:	fffff097          	auipc	ra,0xfffff
    80004d3e:	c4a080e7          	jalr	-950(ra) # 80003984 <iunlock>
      end_op();
    80004d42:	00000097          	auipc	ra,0x0
    80004d46:	8e8080e7          	jalr	-1816(ra) # 8000462a <end_op>

      if(r != n1){
    80004d4a:	009c1f63          	bne	s8,s1,80004d68 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d4e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d52:	0149db63          	bge	s3,s4,80004d68 <filewrite+0xf6>
      int n1 = n - i;
    80004d56:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004d5a:	84be                	mv	s1,a5
    80004d5c:	2781                	sext.w	a5,a5
    80004d5e:	f8fb5ce3          	bge	s6,a5,80004cf6 <filewrite+0x84>
    80004d62:	84de                	mv	s1,s7
    80004d64:	bf49                	j	80004cf6 <filewrite+0x84>
    int i = 0;
    80004d66:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d68:	013a1f63          	bne	s4,s3,80004d86 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d6c:	8552                	mv	a0,s4
    80004d6e:	60a6                	ld	ra,72(sp)
    80004d70:	6406                	ld	s0,64(sp)
    80004d72:	74e2                	ld	s1,56(sp)
    80004d74:	7942                	ld	s2,48(sp)
    80004d76:	79a2                	ld	s3,40(sp)
    80004d78:	7a02                	ld	s4,32(sp)
    80004d7a:	6ae2                	ld	s5,24(sp)
    80004d7c:	6b42                	ld	s6,16(sp)
    80004d7e:	6ba2                	ld	s7,8(sp)
    80004d80:	6c02                	ld	s8,0(sp)
    80004d82:	6161                	addi	sp,sp,80
    80004d84:	8082                	ret
    ret = (i == n ? n : -1);
    80004d86:	5a7d                	li	s4,-1
    80004d88:	b7d5                	j	80004d6c <filewrite+0xfa>
    panic("filewrite");
    80004d8a:	00004517          	auipc	a0,0x4
    80004d8e:	99e50513          	addi	a0,a0,-1634 # 80008728 <syscalls+0x2d8>
    80004d92:	ffffb097          	auipc	ra,0xffffb
    80004d96:	798080e7          	jalr	1944(ra) # 8000052a <panic>
    return -1;
    80004d9a:	5a7d                	li	s4,-1
    80004d9c:	bfc1                	j	80004d6c <filewrite+0xfa>
      return -1;
    80004d9e:	5a7d                	li	s4,-1
    80004da0:	b7f1                	j	80004d6c <filewrite+0xfa>
    80004da2:	5a7d                	li	s4,-1
    80004da4:	b7e1                	j	80004d6c <filewrite+0xfa>

0000000080004da6 <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    80004da6:	7179                	addi	sp,sp,-48
    80004da8:	f406                	sd	ra,40(sp)
    80004daa:	f022                	sd	s0,32(sp)
    80004dac:	ec26                	sd	s1,24(sp)
    80004dae:	e84a                	sd	s2,16(sp)
    80004db0:	e44e                	sd	s3,8(sp)
    80004db2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004db4:	00854783          	lbu	a5,8(a0)
    80004db8:	c3d5                	beqz	a5,80004e5c <kfileread+0xb6>
    80004dba:	84aa                	mv	s1,a0
    80004dbc:	89ae                	mv	s3,a1
    80004dbe:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dc0:	411c                	lw	a5,0(a0)
    80004dc2:	4705                	li	a4,1
    80004dc4:	04e78963          	beq	a5,a4,80004e16 <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004dc8:	470d                	li	a4,3
    80004dca:	04e78d63          	beq	a5,a4,80004e24 <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004dce:	4709                	li	a4,2
    80004dd0:	06e79e63          	bne	a5,a4,80004e4c <kfileread+0xa6>
    ilock(f->ip);
    80004dd4:	6d08                	ld	a0,24(a0)
    80004dd6:	fffff097          	auipc	ra,0xfffff
    80004dda:	aec080e7          	jalr	-1300(ra) # 800038c2 <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    80004dde:	874a                	mv	a4,s2
    80004de0:	5094                	lw	a3,32(s1)
    80004de2:	864e                	mv	a2,s3
    80004de4:	4581                	li	a1,0
    80004de6:	6c88                	ld	a0,24(s1)
    80004de8:	fffff097          	auipc	ra,0xfffff
    80004dec:	d8e080e7          	jalr	-626(ra) # 80003b76 <readi>
    80004df0:	892a                	mv	s2,a0
    80004df2:	00a05563          	blez	a0,80004dfc <kfileread+0x56>
      f->off += r;
    80004df6:	509c                	lw	a5,32(s1)
    80004df8:	9fa9                	addw	a5,a5,a0
    80004dfa:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004dfc:	6c88                	ld	a0,24(s1)
    80004dfe:	fffff097          	auipc	ra,0xfffff
    80004e02:	b86080e7          	jalr	-1146(ra) # 80003984 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e06:	854a                	mv	a0,s2
    80004e08:	70a2                	ld	ra,40(sp)
    80004e0a:	7402                	ld	s0,32(sp)
    80004e0c:	64e2                	ld	s1,24(sp)
    80004e0e:	6942                	ld	s2,16(sp)
    80004e10:	69a2                	ld	s3,8(sp)
    80004e12:	6145                	addi	sp,sp,48
    80004e14:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e16:	6908                	ld	a0,16(a0)
    80004e18:	00000097          	auipc	ra,0x0
    80004e1c:	3c0080e7          	jalr	960(ra) # 800051d8 <piperead>
    80004e20:	892a                	mv	s2,a0
    80004e22:	b7d5                	j	80004e06 <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e24:	02451783          	lh	a5,36(a0)
    80004e28:	03079693          	slli	a3,a5,0x30
    80004e2c:	92c1                	srli	a3,a3,0x30
    80004e2e:	4725                	li	a4,9
    80004e30:	02d76863          	bltu	a4,a3,80004e60 <kfileread+0xba>
    80004e34:	0792                	slli	a5,a5,0x4
    80004e36:	00022717          	auipc	a4,0x22
    80004e3a:	ae270713          	addi	a4,a4,-1310 # 80026918 <devsw>
    80004e3e:	97ba                	add	a5,a5,a4
    80004e40:	639c                	ld	a5,0(a5)
    80004e42:	c38d                	beqz	a5,80004e64 <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e44:	4505                	li	a0,1
    80004e46:	9782                	jalr	a5
    80004e48:	892a                	mv	s2,a0
    80004e4a:	bf75                	j	80004e06 <kfileread+0x60>
    panic("fileread");
    80004e4c:	00004517          	auipc	a0,0x4
    80004e50:	8cc50513          	addi	a0,a0,-1844 # 80008718 <syscalls+0x2c8>
    80004e54:	ffffb097          	auipc	ra,0xffffb
    80004e58:	6d6080e7          	jalr	1750(ra) # 8000052a <panic>
    return -1;
    80004e5c:	597d                	li	s2,-1
    80004e5e:	b765                	j	80004e06 <kfileread+0x60>
      return -1;
    80004e60:	597d                	li	s2,-1
    80004e62:	b755                	j	80004e06 <kfileread+0x60>
    80004e64:	597d                	li	s2,-1
    80004e66:	b745                	j	80004e06 <kfileread+0x60>

0000000080004e68 <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    80004e68:	715d                	addi	sp,sp,-80
    80004e6a:	e486                	sd	ra,72(sp)
    80004e6c:	e0a2                	sd	s0,64(sp)
    80004e6e:	fc26                	sd	s1,56(sp)
    80004e70:	f84a                	sd	s2,48(sp)
    80004e72:	f44e                	sd	s3,40(sp)
    80004e74:	f052                	sd	s4,32(sp)
    80004e76:	ec56                	sd	s5,24(sp)
    80004e78:	e85a                	sd	s6,16(sp)
    80004e7a:	e45e                	sd	s7,8(sp)
    80004e7c:	e062                	sd	s8,0(sp)
    80004e7e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004e80:	00954783          	lbu	a5,9(a0)
    80004e84:	10078663          	beqz	a5,80004f90 <kfilewrite+0x128>
    80004e88:	892a                	mv	s2,a0
    80004e8a:	8aae                	mv	s5,a1
    80004e8c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e8e:	411c                	lw	a5,0(a0)
    80004e90:	4705                	li	a4,1
    80004e92:	02e78263          	beq	a5,a4,80004eb6 <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e96:	470d                	li	a4,3
    80004e98:	02e78663          	beq	a5,a4,80004ec4 <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e9c:	4709                	li	a4,2
    80004e9e:	0ee79163          	bne	a5,a4,80004f80 <kfilewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ea2:	0ac05d63          	blez	a2,80004f5c <kfilewrite+0xf4>
    int i = 0;
    80004ea6:	4981                	li	s3,0
    80004ea8:	6b05                	lui	s6,0x1
    80004eaa:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004eae:	6b85                	lui	s7,0x1
    80004eb0:	c00b8b9b          	addiw	s7,s7,-1024
    80004eb4:	a861                	j	80004f4c <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004eb6:	6908                	ld	a0,16(a0)
    80004eb8:	00000097          	auipc	ra,0x0
    80004ebc:	22e080e7          	jalr	558(ra) # 800050e6 <pipewrite>
    80004ec0:	8a2a                	mv	s4,a0
    80004ec2:	a045                	j	80004f62 <kfilewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004ec4:	02451783          	lh	a5,36(a0)
    80004ec8:	03079693          	slli	a3,a5,0x30
    80004ecc:	92c1                	srli	a3,a3,0x30
    80004ece:	4725                	li	a4,9
    80004ed0:	0cd76263          	bltu	a4,a3,80004f94 <kfilewrite+0x12c>
    80004ed4:	0792                	slli	a5,a5,0x4
    80004ed6:	00022717          	auipc	a4,0x22
    80004eda:	a4270713          	addi	a4,a4,-1470 # 80026918 <devsw>
    80004ede:	97ba                	add	a5,a5,a4
    80004ee0:	679c                	ld	a5,8(a5)
    80004ee2:	cbdd                	beqz	a5,80004f98 <kfilewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004ee4:	4505                	li	a0,1
    80004ee6:	9782                	jalr	a5
    80004ee8:	8a2a                	mv	s4,a0
    80004eea:	a8a5                	j	80004f62 <kfilewrite+0xfa>
    80004eec:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ef0:	fffff097          	auipc	ra,0xfffff
    80004ef4:	6ba080e7          	jalr	1722(ra) # 800045aa <begin_op>
      ilock(f->ip);
    80004ef8:	01893503          	ld	a0,24(s2)
    80004efc:	fffff097          	auipc	ra,0xfffff
    80004f00:	9c6080e7          	jalr	-1594(ra) # 800038c2 <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    80004f04:	8762                	mv	a4,s8
    80004f06:	02092683          	lw	a3,32(s2)
    80004f0a:	01598633          	add	a2,s3,s5
    80004f0e:	4581                	li	a1,0
    80004f10:	01893503          	ld	a0,24(s2)
    80004f14:	fffff097          	auipc	ra,0xfffff
    80004f18:	d5a080e7          	jalr	-678(ra) # 80003c6e <writei>
    80004f1c:	84aa                	mv	s1,a0
    80004f1e:	00a05763          	blez	a0,80004f2c <kfilewrite+0xc4>
        f->off += r;
    80004f22:	02092783          	lw	a5,32(s2)
    80004f26:	9fa9                	addw	a5,a5,a0
    80004f28:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f2c:	01893503          	ld	a0,24(s2)
    80004f30:	fffff097          	auipc	ra,0xfffff
    80004f34:	a54080e7          	jalr	-1452(ra) # 80003984 <iunlock>
      end_op();
    80004f38:	fffff097          	auipc	ra,0xfffff
    80004f3c:	6f2080e7          	jalr	1778(ra) # 8000462a <end_op>

      if(r != n1){
    80004f40:	009c1f63          	bne	s8,s1,80004f5e <kfilewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004f44:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f48:	0149db63          	bge	s3,s4,80004f5e <kfilewrite+0xf6>
      int n1 = n - i;
    80004f4c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004f50:	84be                	mv	s1,a5
    80004f52:	2781                	sext.w	a5,a5
    80004f54:	f8fb5ce3          	bge	s6,a5,80004eec <kfilewrite+0x84>
    80004f58:	84de                	mv	s1,s7
    80004f5a:	bf49                	j	80004eec <kfilewrite+0x84>
    int i = 0;
    80004f5c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004f5e:	013a1f63          	bne	s4,s3,80004f7c <kfilewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
    80004f62:	8552                	mv	a0,s4
    80004f64:	60a6                	ld	ra,72(sp)
    80004f66:	6406                	ld	s0,64(sp)
    80004f68:	74e2                	ld	s1,56(sp)
    80004f6a:	7942                	ld	s2,48(sp)
    80004f6c:	79a2                	ld	s3,40(sp)
    80004f6e:	7a02                	ld	s4,32(sp)
    80004f70:	6ae2                	ld	s5,24(sp)
    80004f72:	6b42                	ld	s6,16(sp)
    80004f74:	6ba2                	ld	s7,8(sp)
    80004f76:	6c02                	ld	s8,0(sp)
    80004f78:	6161                	addi	sp,sp,80
    80004f7a:	8082                	ret
    ret = (i == n ? n : -1);
    80004f7c:	5a7d                	li	s4,-1
    80004f7e:	b7d5                	j	80004f62 <kfilewrite+0xfa>
    panic("filewrite");
    80004f80:	00003517          	auipc	a0,0x3
    80004f84:	7a850513          	addi	a0,a0,1960 # 80008728 <syscalls+0x2d8>
    80004f88:	ffffb097          	auipc	ra,0xffffb
    80004f8c:	5a2080e7          	jalr	1442(ra) # 8000052a <panic>
    return -1;
    80004f90:	5a7d                	li	s4,-1
    80004f92:	bfc1                	j	80004f62 <kfilewrite+0xfa>
      return -1;
    80004f94:	5a7d                	li	s4,-1
    80004f96:	b7f1                	j	80004f62 <kfilewrite+0xfa>
    80004f98:	5a7d                	li	s4,-1
    80004f9a:	b7e1                	j	80004f62 <kfilewrite+0xfa>

0000000080004f9c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004f9c:	7179                	addi	sp,sp,-48
    80004f9e:	f406                	sd	ra,40(sp)
    80004fa0:	f022                	sd	s0,32(sp)
    80004fa2:	ec26                	sd	s1,24(sp)
    80004fa4:	e84a                	sd	s2,16(sp)
    80004fa6:	e44e                	sd	s3,8(sp)
    80004fa8:	e052                	sd	s4,0(sp)
    80004faa:	1800                	addi	s0,sp,48
    80004fac:	84aa                	mv	s1,a0
    80004fae:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004fb0:	0005b023          	sd	zero,0(a1)
    80004fb4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004fb8:	00000097          	auipc	ra,0x0
    80004fbc:	a02080e7          	jalr	-1534(ra) # 800049ba <filealloc>
    80004fc0:	e088                	sd	a0,0(s1)
    80004fc2:	c551                	beqz	a0,8000504e <pipealloc+0xb2>
    80004fc4:	00000097          	auipc	ra,0x0
    80004fc8:	9f6080e7          	jalr	-1546(ra) # 800049ba <filealloc>
    80004fcc:	00aa3023          	sd	a0,0(s4)
    80004fd0:	c92d                	beqz	a0,80005042 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004fd2:	ffffc097          	auipc	ra,0xffffc
    80004fd6:	b00080e7          	jalr	-1280(ra) # 80000ad2 <kalloc>
    80004fda:	892a                	mv	s2,a0
    80004fdc:	c125                	beqz	a0,8000503c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004fde:	4985                	li	s3,1
    80004fe0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004fe4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004fe8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004fec:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ff0:	00003597          	auipc	a1,0x3
    80004ff4:	74858593          	addi	a1,a1,1864 # 80008738 <syscalls+0x2e8>
    80004ff8:	ffffc097          	auipc	ra,0xffffc
    80004ffc:	b3a080e7          	jalr	-1222(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80005000:	609c                	ld	a5,0(s1)
    80005002:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005006:	609c                	ld	a5,0(s1)
    80005008:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000500c:	609c                	ld	a5,0(s1)
    8000500e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005012:	609c                	ld	a5,0(s1)
    80005014:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005018:	000a3783          	ld	a5,0(s4)
    8000501c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005020:	000a3783          	ld	a5,0(s4)
    80005024:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005028:	000a3783          	ld	a5,0(s4)
    8000502c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005030:	000a3783          	ld	a5,0(s4)
    80005034:	0127b823          	sd	s2,16(a5)
  return 0;
    80005038:	4501                	li	a0,0
    8000503a:	a025                	j	80005062 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000503c:	6088                	ld	a0,0(s1)
    8000503e:	e501                	bnez	a0,80005046 <pipealloc+0xaa>
    80005040:	a039                	j	8000504e <pipealloc+0xb2>
    80005042:	6088                	ld	a0,0(s1)
    80005044:	c51d                	beqz	a0,80005072 <pipealloc+0xd6>
    fileclose(*f0);
    80005046:	00000097          	auipc	ra,0x0
    8000504a:	a30080e7          	jalr	-1488(ra) # 80004a76 <fileclose>
  if(*f1)
    8000504e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005052:	557d                	li	a0,-1
  if(*f1)
    80005054:	c799                	beqz	a5,80005062 <pipealloc+0xc6>
    fileclose(*f1);
    80005056:	853e                	mv	a0,a5
    80005058:	00000097          	auipc	ra,0x0
    8000505c:	a1e080e7          	jalr	-1506(ra) # 80004a76 <fileclose>
  return -1;
    80005060:	557d                	li	a0,-1
}
    80005062:	70a2                	ld	ra,40(sp)
    80005064:	7402                	ld	s0,32(sp)
    80005066:	64e2                	ld	s1,24(sp)
    80005068:	6942                	ld	s2,16(sp)
    8000506a:	69a2                	ld	s3,8(sp)
    8000506c:	6a02                	ld	s4,0(sp)
    8000506e:	6145                	addi	sp,sp,48
    80005070:	8082                	ret
  return -1;
    80005072:	557d                	li	a0,-1
    80005074:	b7fd                	j	80005062 <pipealloc+0xc6>

0000000080005076 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005076:	1101                	addi	sp,sp,-32
    80005078:	ec06                	sd	ra,24(sp)
    8000507a:	e822                	sd	s0,16(sp)
    8000507c:	e426                	sd	s1,8(sp)
    8000507e:	e04a                	sd	s2,0(sp)
    80005080:	1000                	addi	s0,sp,32
    80005082:	84aa                	mv	s1,a0
    80005084:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005086:	ffffc097          	auipc	ra,0xffffc
    8000508a:	b3c080e7          	jalr	-1220(ra) # 80000bc2 <acquire>
  if(writable){
    8000508e:	02090d63          	beqz	s2,800050c8 <pipeclose+0x52>
    pi->writeopen = 0;
    80005092:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005096:	21848513          	addi	a0,s1,536
    8000509a:	ffffd097          	auipc	ra,0xffffd
    8000509e:	420080e7          	jalr	1056(ra) # 800024ba <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800050a2:	2204b783          	ld	a5,544(s1)
    800050a6:	eb95                	bnez	a5,800050da <pipeclose+0x64>
    release(&pi->lock);
    800050a8:	8526                	mv	a0,s1
    800050aa:	ffffc097          	auipc	ra,0xffffc
    800050ae:	bcc080e7          	jalr	-1076(ra) # 80000c76 <release>
    kfree((char*)pi);
    800050b2:	8526                	mv	a0,s1
    800050b4:	ffffc097          	auipc	ra,0xffffc
    800050b8:	922080e7          	jalr	-1758(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    800050bc:	60e2                	ld	ra,24(sp)
    800050be:	6442                	ld	s0,16(sp)
    800050c0:	64a2                	ld	s1,8(sp)
    800050c2:	6902                	ld	s2,0(sp)
    800050c4:	6105                	addi	sp,sp,32
    800050c6:	8082                	ret
    pi->readopen = 0;
    800050c8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800050cc:	21c48513          	addi	a0,s1,540
    800050d0:	ffffd097          	auipc	ra,0xffffd
    800050d4:	3ea080e7          	jalr	1002(ra) # 800024ba <wakeup>
    800050d8:	b7e9                	j	800050a2 <pipeclose+0x2c>
    release(&pi->lock);
    800050da:	8526                	mv	a0,s1
    800050dc:	ffffc097          	auipc	ra,0xffffc
    800050e0:	b9a080e7          	jalr	-1126(ra) # 80000c76 <release>
}
    800050e4:	bfe1                	j	800050bc <pipeclose+0x46>

00000000800050e6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800050e6:	711d                	addi	sp,sp,-96
    800050e8:	ec86                	sd	ra,88(sp)
    800050ea:	e8a2                	sd	s0,80(sp)
    800050ec:	e4a6                	sd	s1,72(sp)
    800050ee:	e0ca                	sd	s2,64(sp)
    800050f0:	fc4e                	sd	s3,56(sp)
    800050f2:	f852                	sd	s4,48(sp)
    800050f4:	f456                	sd	s5,40(sp)
    800050f6:	f05a                	sd	s6,32(sp)
    800050f8:	ec5e                	sd	s7,24(sp)
    800050fa:	e862                	sd	s8,16(sp)
    800050fc:	1080                	addi	s0,sp,96
    800050fe:	84aa                	mv	s1,a0
    80005100:	8aae                	mv	s5,a1
    80005102:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005104:	ffffd097          	auipc	ra,0xffffd
    80005108:	a78080e7          	jalr	-1416(ra) # 80001b7c <myproc>
    8000510c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000510e:	8526                	mv	a0,s1
    80005110:	ffffc097          	auipc	ra,0xffffc
    80005114:	ab2080e7          	jalr	-1358(ra) # 80000bc2 <acquire>
  while(i < n){
    80005118:	0b405363          	blez	s4,800051be <pipewrite+0xd8>
  int i = 0;
    8000511c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000511e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005120:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005124:	21c48b93          	addi	s7,s1,540
    80005128:	a089                	j	8000516a <pipewrite+0x84>
      release(&pi->lock);
    8000512a:	8526                	mv	a0,s1
    8000512c:	ffffc097          	auipc	ra,0xffffc
    80005130:	b4a080e7          	jalr	-1206(ra) # 80000c76 <release>
      return -1;
    80005134:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005136:	854a                	mv	a0,s2
    80005138:	60e6                	ld	ra,88(sp)
    8000513a:	6446                	ld	s0,80(sp)
    8000513c:	64a6                	ld	s1,72(sp)
    8000513e:	6906                	ld	s2,64(sp)
    80005140:	79e2                	ld	s3,56(sp)
    80005142:	7a42                	ld	s4,48(sp)
    80005144:	7aa2                	ld	s5,40(sp)
    80005146:	7b02                	ld	s6,32(sp)
    80005148:	6be2                	ld	s7,24(sp)
    8000514a:	6c42                	ld	s8,16(sp)
    8000514c:	6125                	addi	sp,sp,96
    8000514e:	8082                	ret
      wakeup(&pi->nread);
    80005150:	8562                	mv	a0,s8
    80005152:	ffffd097          	auipc	ra,0xffffd
    80005156:	368080e7          	jalr	872(ra) # 800024ba <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000515a:	85a6                	mv	a1,s1
    8000515c:	855e                	mv	a0,s7
    8000515e:	ffffd097          	auipc	ra,0xffffd
    80005162:	1d0080e7          	jalr	464(ra) # 8000232e <sleep>
  while(i < n){
    80005166:	05495d63          	bge	s2,s4,800051c0 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    8000516a:	2204a783          	lw	a5,544(s1)
    8000516e:	dfd5                	beqz	a5,8000512a <pipewrite+0x44>
    80005170:	0289a783          	lw	a5,40(s3)
    80005174:	fbdd                	bnez	a5,8000512a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005176:	2184a783          	lw	a5,536(s1)
    8000517a:	21c4a703          	lw	a4,540(s1)
    8000517e:	2007879b          	addiw	a5,a5,512
    80005182:	fcf707e3          	beq	a4,a5,80005150 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005186:	4685                	li	a3,1
    80005188:	01590633          	add	a2,s2,s5
    8000518c:	faf40593          	addi	a1,s0,-81
    80005190:	0509b503          	ld	a0,80(s3)
    80005194:	ffffc097          	auipc	ra,0xffffc
    80005198:	734080e7          	jalr	1844(ra) # 800018c8 <copyin>
    8000519c:	03650263          	beq	a0,s6,800051c0 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800051a0:	21c4a783          	lw	a5,540(s1)
    800051a4:	0017871b          	addiw	a4,a5,1
    800051a8:	20e4ae23          	sw	a4,540(s1)
    800051ac:	1ff7f793          	andi	a5,a5,511
    800051b0:	97a6                	add	a5,a5,s1
    800051b2:	faf44703          	lbu	a4,-81(s0)
    800051b6:	00e78c23          	sb	a4,24(a5)
      i++;
    800051ba:	2905                	addiw	s2,s2,1
    800051bc:	b76d                	j	80005166 <pipewrite+0x80>
  int i = 0;
    800051be:	4901                	li	s2,0
  wakeup(&pi->nread);
    800051c0:	21848513          	addi	a0,s1,536
    800051c4:	ffffd097          	auipc	ra,0xffffd
    800051c8:	2f6080e7          	jalr	758(ra) # 800024ba <wakeup>
  release(&pi->lock);
    800051cc:	8526                	mv	a0,s1
    800051ce:	ffffc097          	auipc	ra,0xffffc
    800051d2:	aa8080e7          	jalr	-1368(ra) # 80000c76 <release>
  return i;
    800051d6:	b785                	j	80005136 <pipewrite+0x50>

00000000800051d8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800051d8:	715d                	addi	sp,sp,-80
    800051da:	e486                	sd	ra,72(sp)
    800051dc:	e0a2                	sd	s0,64(sp)
    800051de:	fc26                	sd	s1,56(sp)
    800051e0:	f84a                	sd	s2,48(sp)
    800051e2:	f44e                	sd	s3,40(sp)
    800051e4:	f052                	sd	s4,32(sp)
    800051e6:	ec56                	sd	s5,24(sp)
    800051e8:	e85a                	sd	s6,16(sp)
    800051ea:	0880                	addi	s0,sp,80
    800051ec:	84aa                	mv	s1,a0
    800051ee:	892e                	mv	s2,a1
    800051f0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800051f2:	ffffd097          	auipc	ra,0xffffd
    800051f6:	98a080e7          	jalr	-1654(ra) # 80001b7c <myproc>
    800051fa:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800051fc:	8526                	mv	a0,s1
    800051fe:	ffffc097          	auipc	ra,0xffffc
    80005202:	9c4080e7          	jalr	-1596(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005206:	2184a703          	lw	a4,536(s1)
    8000520a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000520e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005212:	02f71463          	bne	a4,a5,8000523a <piperead+0x62>
    80005216:	2244a783          	lw	a5,548(s1)
    8000521a:	c385                	beqz	a5,8000523a <piperead+0x62>
    if(pr->killed){
    8000521c:	028a2783          	lw	a5,40(s4)
    80005220:	ebc1                	bnez	a5,800052b0 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005222:	85a6                	mv	a1,s1
    80005224:	854e                	mv	a0,s3
    80005226:	ffffd097          	auipc	ra,0xffffd
    8000522a:	108080e7          	jalr	264(ra) # 8000232e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000522e:	2184a703          	lw	a4,536(s1)
    80005232:	21c4a783          	lw	a5,540(s1)
    80005236:	fef700e3          	beq	a4,a5,80005216 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000523a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000523c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000523e:	05505363          	blez	s5,80005284 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80005242:	2184a783          	lw	a5,536(s1)
    80005246:	21c4a703          	lw	a4,540(s1)
    8000524a:	02f70d63          	beq	a4,a5,80005284 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000524e:	0017871b          	addiw	a4,a5,1
    80005252:	20e4ac23          	sw	a4,536(s1)
    80005256:	1ff7f793          	andi	a5,a5,511
    8000525a:	97a6                	add	a5,a5,s1
    8000525c:	0187c783          	lbu	a5,24(a5)
    80005260:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005264:	4685                	li	a3,1
    80005266:	fbf40613          	addi	a2,s0,-65
    8000526a:	85ca                	mv	a1,s2
    8000526c:	050a3503          	ld	a0,80(s4)
    80005270:	ffffc097          	auipc	ra,0xffffc
    80005274:	5cc080e7          	jalr	1484(ra) # 8000183c <copyout>
    80005278:	01650663          	beq	a0,s6,80005284 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000527c:	2985                	addiw	s3,s3,1
    8000527e:	0905                	addi	s2,s2,1
    80005280:	fd3a91e3          	bne	s5,s3,80005242 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005284:	21c48513          	addi	a0,s1,540
    80005288:	ffffd097          	auipc	ra,0xffffd
    8000528c:	232080e7          	jalr	562(ra) # 800024ba <wakeup>
  release(&pi->lock);
    80005290:	8526                	mv	a0,s1
    80005292:	ffffc097          	auipc	ra,0xffffc
    80005296:	9e4080e7          	jalr	-1564(ra) # 80000c76 <release>
  return i;
}
    8000529a:	854e                	mv	a0,s3
    8000529c:	60a6                	ld	ra,72(sp)
    8000529e:	6406                	ld	s0,64(sp)
    800052a0:	74e2                	ld	s1,56(sp)
    800052a2:	7942                	ld	s2,48(sp)
    800052a4:	79a2                	ld	s3,40(sp)
    800052a6:	7a02                	ld	s4,32(sp)
    800052a8:	6ae2                	ld	s5,24(sp)
    800052aa:	6b42                	ld	s6,16(sp)
    800052ac:	6161                	addi	sp,sp,80
    800052ae:	8082                	ret
      release(&pi->lock);
    800052b0:	8526                	mv	a0,s1
    800052b2:	ffffc097          	auipc	ra,0xffffc
    800052b6:	9c4080e7          	jalr	-1596(ra) # 80000c76 <release>
      return -1;
    800052ba:	59fd                	li	s3,-1
    800052bc:	bff9                	j	8000529a <piperead+0xc2>

00000000800052be <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800052be:	de010113          	addi	sp,sp,-544
    800052c2:	20113c23          	sd	ra,536(sp)
    800052c6:	20813823          	sd	s0,528(sp)
    800052ca:	20913423          	sd	s1,520(sp)
    800052ce:	21213023          	sd	s2,512(sp)
    800052d2:	ffce                	sd	s3,504(sp)
    800052d4:	fbd2                	sd	s4,496(sp)
    800052d6:	f7d6                	sd	s5,488(sp)
    800052d8:	f3da                	sd	s6,480(sp)
    800052da:	efde                	sd	s7,472(sp)
    800052dc:	ebe2                	sd	s8,464(sp)
    800052de:	e7e6                	sd	s9,456(sp)
    800052e0:	e3ea                	sd	s10,448(sp)
    800052e2:	ff6e                	sd	s11,440(sp)
    800052e4:	1400                	addi	s0,sp,544
    800052e6:	892a                	mv	s2,a0
    800052e8:	dea43423          	sd	a0,-536(s0)
    800052ec:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800052f0:	ffffd097          	auipc	ra,0xffffd
    800052f4:	88c080e7          	jalr	-1908(ra) # 80001b7c <myproc>
    800052f8:	84aa                	mv	s1,a0

  begin_op();
    800052fa:	fffff097          	auipc	ra,0xfffff
    800052fe:	2b0080e7          	jalr	688(ra) # 800045aa <begin_op>

  if((ip = namei(path)) == 0){
    80005302:	854a                	mv	a0,s2
    80005304:	fffff097          	auipc	ra,0xfffff
    80005308:	d74080e7          	jalr	-652(ra) # 80004078 <namei>
    8000530c:	c93d                	beqz	a0,80005382 <exec+0xc4>
    8000530e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005310:	ffffe097          	auipc	ra,0xffffe
    80005314:	5b2080e7          	jalr	1458(ra) # 800038c2 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005318:	04000713          	li	a4,64
    8000531c:	4681                	li	a3,0
    8000531e:	e4840613          	addi	a2,s0,-440
    80005322:	4581                	li	a1,0
    80005324:	8556                	mv	a0,s5
    80005326:	fffff097          	auipc	ra,0xfffff
    8000532a:	850080e7          	jalr	-1968(ra) # 80003b76 <readi>
    8000532e:	04000793          	li	a5,64
    80005332:	00f51a63          	bne	a0,a5,80005346 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005336:	e4842703          	lw	a4,-440(s0)
    8000533a:	464c47b7          	lui	a5,0x464c4
    8000533e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005342:	04f70663          	beq	a4,a5,8000538e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005346:	8556                	mv	a0,s5
    80005348:	ffffe097          	auipc	ra,0xffffe
    8000534c:	7dc080e7          	jalr	2012(ra) # 80003b24 <iunlockput>
    end_op();
    80005350:	fffff097          	auipc	ra,0xfffff
    80005354:	2da080e7          	jalr	730(ra) # 8000462a <end_op>
  }
  return -1;
    80005358:	557d                	li	a0,-1
}
    8000535a:	21813083          	ld	ra,536(sp)
    8000535e:	21013403          	ld	s0,528(sp)
    80005362:	20813483          	ld	s1,520(sp)
    80005366:	20013903          	ld	s2,512(sp)
    8000536a:	79fe                	ld	s3,504(sp)
    8000536c:	7a5e                	ld	s4,496(sp)
    8000536e:	7abe                	ld	s5,488(sp)
    80005370:	7b1e                	ld	s6,480(sp)
    80005372:	6bfe                	ld	s7,472(sp)
    80005374:	6c5e                	ld	s8,464(sp)
    80005376:	6cbe                	ld	s9,456(sp)
    80005378:	6d1e                	ld	s10,448(sp)
    8000537a:	7dfa                	ld	s11,440(sp)
    8000537c:	22010113          	addi	sp,sp,544
    80005380:	8082                	ret
    end_op();
    80005382:	fffff097          	auipc	ra,0xfffff
    80005386:	2a8080e7          	jalr	680(ra) # 8000462a <end_op>
    return -1;
    8000538a:	557d                	li	a0,-1
    8000538c:	b7f9                	j	8000535a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000538e:	8526                	mv	a0,s1
    80005390:	ffffd097          	auipc	ra,0xffffd
    80005394:	8b0080e7          	jalr	-1872(ra) # 80001c40 <proc_pagetable>
    80005398:	8b2a                	mv	s6,a0
    8000539a:	d555                	beqz	a0,80005346 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000539c:	e6842783          	lw	a5,-408(s0)
    800053a0:	e8045703          	lhu	a4,-384(s0)
    800053a4:	c735                	beqz	a4,80005410 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800053a6:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053a8:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800053ac:	6a05                	lui	s4,0x1
    800053ae:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800053b2:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    800053b6:	6d85                	lui	s11,0x1
    800053b8:	7d7d                	lui	s10,0xfffff
    800053ba:	ac1d                	j	800055f0 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800053bc:	00003517          	auipc	a0,0x3
    800053c0:	38450513          	addi	a0,a0,900 # 80008740 <syscalls+0x2f0>
    800053c4:	ffffb097          	auipc	ra,0xffffb
    800053c8:	166080e7          	jalr	358(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800053cc:	874a                	mv	a4,s2
    800053ce:	009c86bb          	addw	a3,s9,s1
    800053d2:	4581                	li	a1,0
    800053d4:	8556                	mv	a0,s5
    800053d6:	ffffe097          	auipc	ra,0xffffe
    800053da:	7a0080e7          	jalr	1952(ra) # 80003b76 <readi>
    800053de:	2501                	sext.w	a0,a0
    800053e0:	1aa91863          	bne	s2,a0,80005590 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    800053e4:	009d84bb          	addw	s1,s11,s1
    800053e8:	013d09bb          	addw	s3,s10,s3
    800053ec:	1f74f263          	bgeu	s1,s7,800055d0 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    800053f0:	02049593          	slli	a1,s1,0x20
    800053f4:	9181                	srli	a1,a1,0x20
    800053f6:	95e2                	add	a1,a1,s8
    800053f8:	855a                	mv	a0,s6
    800053fa:	ffffc097          	auipc	ra,0xffffc
    800053fe:	c52080e7          	jalr	-942(ra) # 8000104c <walkaddr>
    80005402:	862a                	mv	a2,a0
    if(pa == 0)
    80005404:	dd45                	beqz	a0,800053bc <exec+0xfe>
      n = PGSIZE;
    80005406:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005408:	fd49f2e3          	bgeu	s3,s4,800053cc <exec+0x10e>
      n = sz - i;
    8000540c:	894e                	mv	s2,s3
    8000540e:	bf7d                	j	800053cc <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005410:	4481                	li	s1,0
  iunlockput(ip);
    80005412:	8556                	mv	a0,s5
    80005414:	ffffe097          	auipc	ra,0xffffe
    80005418:	710080e7          	jalr	1808(ra) # 80003b24 <iunlockput>
  end_op();
    8000541c:	fffff097          	auipc	ra,0xfffff
    80005420:	20e080e7          	jalr	526(ra) # 8000462a <end_op>
  p = myproc();
    80005424:	ffffc097          	auipc	ra,0xffffc
    80005428:	758080e7          	jalr	1880(ra) # 80001b7c <myproc>
    8000542c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000542e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005432:	6785                	lui	a5,0x1
    80005434:	17fd                	addi	a5,a5,-1
    80005436:	94be                	add	s1,s1,a5
    80005438:	77fd                	lui	a5,0xfffff
    8000543a:	8fe5                	and	a5,a5,s1
    8000543c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005440:	6609                	lui	a2,0x2
    80005442:	963e                	add	a2,a2,a5
    80005444:	85be                	mv	a1,a5
    80005446:	855a                	mv	a0,s6
    80005448:	ffffc097          	auipc	ra,0xffffc
    8000544c:	1a4080e7          	jalr	420(ra) # 800015ec <uvmalloc>
    80005450:	8c2a                	mv	s8,a0
  ip = 0;
    80005452:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005454:	12050e63          	beqz	a0,80005590 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005458:	75f9                	lui	a1,0xffffe
    8000545a:	95aa                	add	a1,a1,a0
    8000545c:	855a                	mv	a0,s6
    8000545e:	ffffc097          	auipc	ra,0xffffc
    80005462:	3ac080e7          	jalr	940(ra) # 8000180a <uvmclear>
  stackbase = sp - PGSIZE;
    80005466:	7afd                	lui	s5,0xfffff
    80005468:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000546a:	df043783          	ld	a5,-528(s0)
    8000546e:	6388                	ld	a0,0(a5)
    80005470:	c925                	beqz	a0,800054e0 <exec+0x222>
    80005472:	e8840993          	addi	s3,s0,-376
    80005476:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    8000547a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000547c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000547e:	ffffc097          	auipc	ra,0xffffc
    80005482:	9c4080e7          	jalr	-1596(ra) # 80000e42 <strlen>
    80005486:	0015079b          	addiw	a5,a0,1
    8000548a:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000548e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005492:	13596363          	bltu	s2,s5,800055b8 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005496:	df043d83          	ld	s11,-528(s0)
    8000549a:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000549e:	8552                	mv	a0,s4
    800054a0:	ffffc097          	auipc	ra,0xffffc
    800054a4:	9a2080e7          	jalr	-1630(ra) # 80000e42 <strlen>
    800054a8:	0015069b          	addiw	a3,a0,1
    800054ac:	8652                	mv	a2,s4
    800054ae:	85ca                	mv	a1,s2
    800054b0:	855a                	mv	a0,s6
    800054b2:	ffffc097          	auipc	ra,0xffffc
    800054b6:	38a080e7          	jalr	906(ra) # 8000183c <copyout>
    800054ba:	10054363          	bltz	a0,800055c0 <exec+0x302>
    ustack[argc] = sp;
    800054be:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800054c2:	0485                	addi	s1,s1,1
    800054c4:	008d8793          	addi	a5,s11,8
    800054c8:	def43823          	sd	a5,-528(s0)
    800054cc:	008db503          	ld	a0,8(s11)
    800054d0:	c911                	beqz	a0,800054e4 <exec+0x226>
    if(argc >= MAXARG)
    800054d2:	09a1                	addi	s3,s3,8
    800054d4:	fb3c95e3          	bne	s9,s3,8000547e <exec+0x1c0>
  sz = sz1;
    800054d8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054dc:	4a81                	li	s5,0
    800054de:	a84d                	j	80005590 <exec+0x2d2>
  sp = sz;
    800054e0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800054e2:	4481                	li	s1,0
  ustack[argc] = 0;
    800054e4:	00349793          	slli	a5,s1,0x3
    800054e8:	f9040713          	addi	a4,s0,-112
    800054ec:	97ba                	add	a5,a5,a4
    800054ee:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd3ef8>
  sp -= (argc+1) * sizeof(uint64);
    800054f2:	00148693          	addi	a3,s1,1
    800054f6:	068e                	slli	a3,a3,0x3
    800054f8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800054fc:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005500:	01597663          	bgeu	s2,s5,8000550c <exec+0x24e>
  sz = sz1;
    80005504:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005508:	4a81                	li	s5,0
    8000550a:	a059                	j	80005590 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000550c:	e8840613          	addi	a2,s0,-376
    80005510:	85ca                	mv	a1,s2
    80005512:	855a                	mv	a0,s6
    80005514:	ffffc097          	auipc	ra,0xffffc
    80005518:	328080e7          	jalr	808(ra) # 8000183c <copyout>
    8000551c:	0a054663          	bltz	a0,800055c8 <exec+0x30a>
  p->trapframe->a1 = sp;
    80005520:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005524:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005528:	de843783          	ld	a5,-536(s0)
    8000552c:	0007c703          	lbu	a4,0(a5)
    80005530:	cf11                	beqz	a4,8000554c <exec+0x28e>
    80005532:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005534:	02f00693          	li	a3,47
    80005538:	a039                	j	80005546 <exec+0x288>
      last = s+1;
    8000553a:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000553e:	0785                	addi	a5,a5,1
    80005540:	fff7c703          	lbu	a4,-1(a5)
    80005544:	c701                	beqz	a4,8000554c <exec+0x28e>
    if(*s == '/')
    80005546:	fed71ce3          	bne	a4,a3,8000553e <exec+0x280>
    8000554a:	bfc5                	j	8000553a <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    8000554c:	4641                	li	a2,16
    8000554e:	de843583          	ld	a1,-536(s0)
    80005552:	158b8513          	addi	a0,s7,344
    80005556:	ffffc097          	auipc	ra,0xffffc
    8000555a:	8ba080e7          	jalr	-1862(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    8000555e:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005562:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005566:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000556a:	058bb783          	ld	a5,88(s7)
    8000556e:	e6043703          	ld	a4,-416(s0)
    80005572:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005574:	058bb783          	ld	a5,88(s7)
    80005578:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000557c:	85ea                	mv	a1,s10
    8000557e:	ffffc097          	auipc	ra,0xffffc
    80005582:	75e080e7          	jalr	1886(ra) # 80001cdc <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005586:	0004851b          	sext.w	a0,s1
    8000558a:	bbc1                	j	8000535a <exec+0x9c>
    8000558c:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005590:	df843583          	ld	a1,-520(s0)
    80005594:	855a                	mv	a0,s6
    80005596:	ffffc097          	auipc	ra,0xffffc
    8000559a:	746080e7          	jalr	1862(ra) # 80001cdc <proc_freepagetable>
  if(ip){
    8000559e:	da0a94e3          	bnez	s5,80005346 <exec+0x88>
  return -1;
    800055a2:	557d                	li	a0,-1
    800055a4:	bb5d                	j	8000535a <exec+0x9c>
    800055a6:	de943c23          	sd	s1,-520(s0)
    800055aa:	b7dd                	j	80005590 <exec+0x2d2>
    800055ac:	de943c23          	sd	s1,-520(s0)
    800055b0:	b7c5                	j	80005590 <exec+0x2d2>
    800055b2:	de943c23          	sd	s1,-520(s0)
    800055b6:	bfe9                	j	80005590 <exec+0x2d2>
  sz = sz1;
    800055b8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055bc:	4a81                	li	s5,0
    800055be:	bfc9                	j	80005590 <exec+0x2d2>
  sz = sz1;
    800055c0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055c4:	4a81                	li	s5,0
    800055c6:	b7e9                	j	80005590 <exec+0x2d2>
  sz = sz1;
    800055c8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055cc:	4a81                	li	s5,0
    800055ce:	b7c9                	j	80005590 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800055d0:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055d4:	e0843783          	ld	a5,-504(s0)
    800055d8:	0017869b          	addiw	a3,a5,1
    800055dc:	e0d43423          	sd	a3,-504(s0)
    800055e0:	e0043783          	ld	a5,-512(s0)
    800055e4:	0387879b          	addiw	a5,a5,56
    800055e8:	e8045703          	lhu	a4,-384(s0)
    800055ec:	e2e6d3e3          	bge	a3,a4,80005412 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800055f0:	2781                	sext.w	a5,a5
    800055f2:	e0f43023          	sd	a5,-512(s0)
    800055f6:	03800713          	li	a4,56
    800055fa:	86be                	mv	a3,a5
    800055fc:	e1040613          	addi	a2,s0,-496
    80005600:	4581                	li	a1,0
    80005602:	8556                	mv	a0,s5
    80005604:	ffffe097          	auipc	ra,0xffffe
    80005608:	572080e7          	jalr	1394(ra) # 80003b76 <readi>
    8000560c:	03800793          	li	a5,56
    80005610:	f6f51ee3          	bne	a0,a5,8000558c <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005614:	e1042783          	lw	a5,-496(s0)
    80005618:	4705                	li	a4,1
    8000561a:	fae79de3          	bne	a5,a4,800055d4 <exec+0x316>
    if(ph.memsz < ph.filesz)
    8000561e:	e3843603          	ld	a2,-456(s0)
    80005622:	e3043783          	ld	a5,-464(s0)
    80005626:	f8f660e3          	bltu	a2,a5,800055a6 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000562a:	e2043783          	ld	a5,-480(s0)
    8000562e:	963e                	add	a2,a2,a5
    80005630:	f6f66ee3          	bltu	a2,a5,800055ac <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005634:	85a6                	mv	a1,s1
    80005636:	855a                	mv	a0,s6
    80005638:	ffffc097          	auipc	ra,0xffffc
    8000563c:	fb4080e7          	jalr	-76(ra) # 800015ec <uvmalloc>
    80005640:	dea43c23          	sd	a0,-520(s0)
    80005644:	d53d                	beqz	a0,800055b2 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005646:	e2043c03          	ld	s8,-480(s0)
    8000564a:	de043783          	ld	a5,-544(s0)
    8000564e:	00fc77b3          	and	a5,s8,a5
    80005652:	ff9d                	bnez	a5,80005590 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005654:	e1842c83          	lw	s9,-488(s0)
    80005658:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000565c:	f60b8ae3          	beqz	s7,800055d0 <exec+0x312>
    80005660:	89de                	mv	s3,s7
    80005662:	4481                	li	s1,0
    80005664:	b371                	j	800053f0 <exec+0x132>

0000000080005666 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005666:	7179                	addi	sp,sp,-48
    80005668:	f406                	sd	ra,40(sp)
    8000566a:	f022                	sd	s0,32(sp)
    8000566c:	ec26                	sd	s1,24(sp)
    8000566e:	e84a                	sd	s2,16(sp)
    80005670:	1800                	addi	s0,sp,48
    80005672:	892e                	mv	s2,a1
    80005674:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005676:	fdc40593          	addi	a1,s0,-36
    8000567a:	ffffd097          	auipc	ra,0xffffd
    8000567e:	6d6080e7          	jalr	1750(ra) # 80002d50 <argint>
    80005682:	04054063          	bltz	a0,800056c2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005686:	fdc42703          	lw	a4,-36(s0)
    8000568a:	47bd                	li	a5,15
    8000568c:	02e7ed63          	bltu	a5,a4,800056c6 <argfd+0x60>
    80005690:	ffffc097          	auipc	ra,0xffffc
    80005694:	4ec080e7          	jalr	1260(ra) # 80001b7c <myproc>
    80005698:	fdc42703          	lw	a4,-36(s0)
    8000569c:	01a70793          	addi	a5,a4,26
    800056a0:	078e                	slli	a5,a5,0x3
    800056a2:	953e                	add	a0,a0,a5
    800056a4:	611c                	ld	a5,0(a0)
    800056a6:	c395                	beqz	a5,800056ca <argfd+0x64>
    return -1;
  if(pfd)
    800056a8:	00090463          	beqz	s2,800056b0 <argfd+0x4a>
    *pfd = fd;
    800056ac:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800056b0:	4501                	li	a0,0
  if(pf)
    800056b2:	c091                	beqz	s1,800056b6 <argfd+0x50>
    *pf = f;
    800056b4:	e09c                	sd	a5,0(s1)
}
    800056b6:	70a2                	ld	ra,40(sp)
    800056b8:	7402                	ld	s0,32(sp)
    800056ba:	64e2                	ld	s1,24(sp)
    800056bc:	6942                	ld	s2,16(sp)
    800056be:	6145                	addi	sp,sp,48
    800056c0:	8082                	ret
    return -1;
    800056c2:	557d                	li	a0,-1
    800056c4:	bfcd                	j	800056b6 <argfd+0x50>
    return -1;
    800056c6:	557d                	li	a0,-1
    800056c8:	b7fd                	j	800056b6 <argfd+0x50>
    800056ca:	557d                	li	a0,-1
    800056cc:	b7ed                	j	800056b6 <argfd+0x50>

00000000800056ce <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800056ce:	1101                	addi	sp,sp,-32
    800056d0:	ec06                	sd	ra,24(sp)
    800056d2:	e822                	sd	s0,16(sp)
    800056d4:	e426                	sd	s1,8(sp)
    800056d6:	1000                	addi	s0,sp,32
    800056d8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800056da:	ffffc097          	auipc	ra,0xffffc
    800056de:	4a2080e7          	jalr	1186(ra) # 80001b7c <myproc>
    800056e2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800056e4:	0d050793          	addi	a5,a0,208
    800056e8:	4501                	li	a0,0
    800056ea:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800056ec:	6398                	ld	a4,0(a5)
    800056ee:	cb19                	beqz	a4,80005704 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800056f0:	2505                	addiw	a0,a0,1
    800056f2:	07a1                	addi	a5,a5,8
    800056f4:	fed51ce3          	bne	a0,a3,800056ec <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800056f8:	557d                	li	a0,-1
}
    800056fa:	60e2                	ld	ra,24(sp)
    800056fc:	6442                	ld	s0,16(sp)
    800056fe:	64a2                	ld	s1,8(sp)
    80005700:	6105                	addi	sp,sp,32
    80005702:	8082                	ret
      p->ofile[fd] = f;
    80005704:	01a50793          	addi	a5,a0,26
    80005708:	078e                	slli	a5,a5,0x3
    8000570a:	963e                	add	a2,a2,a5
    8000570c:	e204                	sd	s1,0(a2)
      return fd;
    8000570e:	b7f5                	j	800056fa <fdalloc+0x2c>

0000000080005710 <sys_dup>:

uint64
sys_dup(void)
{
    80005710:	7179                	addi	sp,sp,-48
    80005712:	f406                	sd	ra,40(sp)
    80005714:	f022                	sd	s0,32(sp)
    80005716:	ec26                	sd	s1,24(sp)
    80005718:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    8000571a:	fd840613          	addi	a2,s0,-40
    8000571e:	4581                	li	a1,0
    80005720:	4501                	li	a0,0
    80005722:	00000097          	auipc	ra,0x0
    80005726:	f44080e7          	jalr	-188(ra) # 80005666 <argfd>
    return -1;
    8000572a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000572c:	02054363          	bltz	a0,80005752 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005730:	fd843503          	ld	a0,-40(s0)
    80005734:	00000097          	auipc	ra,0x0
    80005738:	f9a080e7          	jalr	-102(ra) # 800056ce <fdalloc>
    8000573c:	84aa                	mv	s1,a0
    return -1;
    8000573e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005740:	00054963          	bltz	a0,80005752 <sys_dup+0x42>
  filedup(f);
    80005744:	fd843503          	ld	a0,-40(s0)
    80005748:	fffff097          	auipc	ra,0xfffff
    8000574c:	2dc080e7          	jalr	732(ra) # 80004a24 <filedup>
  return fd;
    80005750:	87a6                	mv	a5,s1
}
    80005752:	853e                	mv	a0,a5
    80005754:	70a2                	ld	ra,40(sp)
    80005756:	7402                	ld	s0,32(sp)
    80005758:	64e2                	ld	s1,24(sp)
    8000575a:	6145                	addi	sp,sp,48
    8000575c:	8082                	ret

000000008000575e <sys_read>:

uint64
sys_read(void)
{
    8000575e:	7179                	addi	sp,sp,-48
    80005760:	f406                	sd	ra,40(sp)
    80005762:	f022                	sd	s0,32(sp)
    80005764:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005766:	fe840613          	addi	a2,s0,-24
    8000576a:	4581                	li	a1,0
    8000576c:	4501                	li	a0,0
    8000576e:	00000097          	auipc	ra,0x0
    80005772:	ef8080e7          	jalr	-264(ra) # 80005666 <argfd>
    return -1;
    80005776:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005778:	04054163          	bltz	a0,800057ba <sys_read+0x5c>
    8000577c:	fe440593          	addi	a1,s0,-28
    80005780:	4509                	li	a0,2
    80005782:	ffffd097          	auipc	ra,0xffffd
    80005786:	5ce080e7          	jalr	1486(ra) # 80002d50 <argint>
    return -1;
    8000578a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000578c:	02054763          	bltz	a0,800057ba <sys_read+0x5c>
    80005790:	fd840593          	addi	a1,s0,-40
    80005794:	4505                	li	a0,1
    80005796:	ffffd097          	auipc	ra,0xffffd
    8000579a:	5dc080e7          	jalr	1500(ra) # 80002d72 <argaddr>
    return -1;
    8000579e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057a0:	00054d63          	bltz	a0,800057ba <sys_read+0x5c>
  return fileread(f, p, n);
    800057a4:	fe442603          	lw	a2,-28(s0)
    800057a8:	fd843583          	ld	a1,-40(s0)
    800057ac:	fe843503          	ld	a0,-24(s0)
    800057b0:	fffff097          	auipc	ra,0xfffff
    800057b4:	400080e7          	jalr	1024(ra) # 80004bb0 <fileread>
    800057b8:	87aa                	mv	a5,a0
}
    800057ba:	853e                	mv	a0,a5
    800057bc:	70a2                	ld	ra,40(sp)
    800057be:	7402                	ld	s0,32(sp)
    800057c0:	6145                	addi	sp,sp,48
    800057c2:	8082                	ret

00000000800057c4 <sys_write>:

uint64
sys_write(void)
{
    800057c4:	7179                	addi	sp,sp,-48
    800057c6:	f406                	sd	ra,40(sp)
    800057c8:	f022                	sd	s0,32(sp)
    800057ca:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057cc:	fe840613          	addi	a2,s0,-24
    800057d0:	4581                	li	a1,0
    800057d2:	4501                	li	a0,0
    800057d4:	00000097          	auipc	ra,0x0
    800057d8:	e92080e7          	jalr	-366(ra) # 80005666 <argfd>
    return -1;
    800057dc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057de:	04054163          	bltz	a0,80005820 <sys_write+0x5c>
    800057e2:	fe440593          	addi	a1,s0,-28
    800057e6:	4509                	li	a0,2
    800057e8:	ffffd097          	auipc	ra,0xffffd
    800057ec:	568080e7          	jalr	1384(ra) # 80002d50 <argint>
    return -1;
    800057f0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057f2:	02054763          	bltz	a0,80005820 <sys_write+0x5c>
    800057f6:	fd840593          	addi	a1,s0,-40
    800057fa:	4505                	li	a0,1
    800057fc:	ffffd097          	auipc	ra,0xffffd
    80005800:	576080e7          	jalr	1398(ra) # 80002d72 <argaddr>
    return -1;
    80005804:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005806:	00054d63          	bltz	a0,80005820 <sys_write+0x5c>

  return filewrite(f, p, n);
    8000580a:	fe442603          	lw	a2,-28(s0)
    8000580e:	fd843583          	ld	a1,-40(s0)
    80005812:	fe843503          	ld	a0,-24(s0)
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	45c080e7          	jalr	1116(ra) # 80004c72 <filewrite>
    8000581e:	87aa                	mv	a5,a0
}
    80005820:	853e                	mv	a0,a5
    80005822:	70a2                	ld	ra,40(sp)
    80005824:	7402                	ld	s0,32(sp)
    80005826:	6145                	addi	sp,sp,48
    80005828:	8082                	ret

000000008000582a <sys_close>:

uint64
sys_close(void)
{
    8000582a:	1101                	addi	sp,sp,-32
    8000582c:	ec06                	sd	ra,24(sp)
    8000582e:	e822                	sd	s0,16(sp)
    80005830:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    80005832:	fe040613          	addi	a2,s0,-32
    80005836:	fec40593          	addi	a1,s0,-20
    8000583a:	4501                	li	a0,0
    8000583c:	00000097          	auipc	ra,0x0
    80005840:	e2a080e7          	jalr	-470(ra) # 80005666 <argfd>
    return -1;
    80005844:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005846:	02054463          	bltz	a0,8000586e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000584a:	ffffc097          	auipc	ra,0xffffc
    8000584e:	332080e7          	jalr	818(ra) # 80001b7c <myproc>
    80005852:	fec42783          	lw	a5,-20(s0)
    80005856:	07e9                	addi	a5,a5,26
    80005858:	078e                	slli	a5,a5,0x3
    8000585a:	97aa                	add	a5,a5,a0
    8000585c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005860:	fe043503          	ld	a0,-32(s0)
    80005864:	fffff097          	auipc	ra,0xfffff
    80005868:	212080e7          	jalr	530(ra) # 80004a76 <fileclose>
  return 0;
    8000586c:	4781                	li	a5,0
}
    8000586e:	853e                	mv	a0,a5
    80005870:	60e2                	ld	ra,24(sp)
    80005872:	6442                	ld	s0,16(sp)
    80005874:	6105                	addi	sp,sp,32
    80005876:	8082                	ret

0000000080005878 <sys_fstat>:

uint64
sys_fstat(void)
{
    80005878:	1101                	addi	sp,sp,-32
    8000587a:	ec06                	sd	ra,24(sp)
    8000587c:	e822                	sd	s0,16(sp)
    8000587e:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005880:	fe840613          	addi	a2,s0,-24
    80005884:	4581                	li	a1,0
    80005886:	4501                	li	a0,0
    80005888:	00000097          	auipc	ra,0x0
    8000588c:	dde080e7          	jalr	-546(ra) # 80005666 <argfd>
    return -1;
    80005890:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005892:	02054563          	bltz	a0,800058bc <sys_fstat+0x44>
    80005896:	fe040593          	addi	a1,s0,-32
    8000589a:	4505                	li	a0,1
    8000589c:	ffffd097          	auipc	ra,0xffffd
    800058a0:	4d6080e7          	jalr	1238(ra) # 80002d72 <argaddr>
    return -1;
    800058a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058a6:	00054b63          	bltz	a0,800058bc <sys_fstat+0x44>
  return filestat(f, st);
    800058aa:	fe043583          	ld	a1,-32(s0)
    800058ae:	fe843503          	ld	a0,-24(s0)
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	28c080e7          	jalr	652(ra) # 80004b3e <filestat>
    800058ba:	87aa                	mv	a5,a0
}
    800058bc:	853e                	mv	a0,a5
    800058be:	60e2                	ld	ra,24(sp)
    800058c0:	6442                	ld	s0,16(sp)
    800058c2:	6105                	addi	sp,sp,32
    800058c4:	8082                	ret

00000000800058c6 <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    800058c6:	7169                	addi	sp,sp,-304
    800058c8:	f606                	sd	ra,296(sp)
    800058ca:	f222                	sd	s0,288(sp)
    800058cc:	ee26                	sd	s1,280(sp)
    800058ce:	ea4a                	sd	s2,272(sp)
    800058d0:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058d2:	08000613          	li	a2,128
    800058d6:	ed040593          	addi	a1,s0,-304
    800058da:	4501                	li	a0,0
    800058dc:	ffffd097          	auipc	ra,0xffffd
    800058e0:	4b8080e7          	jalr	1208(ra) # 80002d94 <argstr>
    return -1;
    800058e4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058e6:	10054e63          	bltz	a0,80005a02 <sys_link+0x13c>
    800058ea:	08000613          	li	a2,128
    800058ee:	f5040593          	addi	a1,s0,-176
    800058f2:	4505                	li	a0,1
    800058f4:	ffffd097          	auipc	ra,0xffffd
    800058f8:	4a0080e7          	jalr	1184(ra) # 80002d94 <argstr>
    return -1;
    800058fc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058fe:	10054263          	bltz	a0,80005a02 <sys_link+0x13c>

  begin_op();
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	ca8080e7          	jalr	-856(ra) # 800045aa <begin_op>
  if((ip = namei(old)) == 0){
    8000590a:	ed040513          	addi	a0,s0,-304
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	76a080e7          	jalr	1898(ra) # 80004078 <namei>
    80005916:	84aa                	mv	s1,a0
    80005918:	c551                	beqz	a0,800059a4 <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    8000591a:	ffffe097          	auipc	ra,0xffffe
    8000591e:	fa8080e7          	jalr	-88(ra) # 800038c2 <ilock>
  if(ip->type == T_DIR){
    80005922:	04449703          	lh	a4,68(s1)
    80005926:	4785                	li	a5,1
    80005928:	08f70463          	beq	a4,a5,800059b0 <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    8000592c:	04a4d783          	lhu	a5,74(s1)
    80005930:	2785                	addiw	a5,a5,1
    80005932:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005936:	8526                	mv	a0,s1
    80005938:	ffffe097          	auipc	ra,0xffffe
    8000593c:	ec0080e7          	jalr	-320(ra) # 800037f8 <iupdate>
  iunlock(ip);
    80005940:	8526                	mv	a0,s1
    80005942:	ffffe097          	auipc	ra,0xffffe
    80005946:	042080e7          	jalr	66(ra) # 80003984 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    8000594a:	fd040593          	addi	a1,s0,-48
    8000594e:	f5040513          	addi	a0,s0,-176
    80005952:	ffffe097          	auipc	ra,0xffffe
    80005956:	744080e7          	jalr	1860(ra) # 80004096 <nameiparent>
    8000595a:	892a                	mv	s2,a0
    8000595c:	c935                	beqz	a0,800059d0 <sys_link+0x10a>
    goto bad;
  ilock(dp);
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	f64080e7          	jalr	-156(ra) # 800038c2 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005966:	00092703          	lw	a4,0(s2)
    8000596a:	409c                	lw	a5,0(s1)
    8000596c:	04f71d63          	bne	a4,a5,800059c6 <sys_link+0x100>
    80005970:	40d0                	lw	a2,4(s1)
    80005972:	fd040593          	addi	a1,s0,-48
    80005976:	854a                	mv	a0,s2
    80005978:	ffffe097          	auipc	ra,0xffffe
    8000597c:	63e080e7          	jalr	1598(ra) # 80003fb6 <dirlink>
    80005980:	04054363          	bltz	a0,800059c6 <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    80005984:	854a                	mv	a0,s2
    80005986:	ffffe097          	auipc	ra,0xffffe
    8000598a:	19e080e7          	jalr	414(ra) # 80003b24 <iunlockput>
  iput(ip);
    8000598e:	8526                	mv	a0,s1
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	0ec080e7          	jalr	236(ra) # 80003a7c <iput>

  end_op();
    80005998:	fffff097          	auipc	ra,0xfffff
    8000599c:	c92080e7          	jalr	-878(ra) # 8000462a <end_op>

  return 0;
    800059a0:	4781                	li	a5,0
    800059a2:	a085                	j	80005a02 <sys_link+0x13c>
    end_op();
    800059a4:	fffff097          	auipc	ra,0xfffff
    800059a8:	c86080e7          	jalr	-890(ra) # 8000462a <end_op>
    return -1;
    800059ac:	57fd                	li	a5,-1
    800059ae:	a891                	j	80005a02 <sys_link+0x13c>
    iunlockput(ip);
    800059b0:	8526                	mv	a0,s1
    800059b2:	ffffe097          	auipc	ra,0xffffe
    800059b6:	172080e7          	jalr	370(ra) # 80003b24 <iunlockput>
    end_op();
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	c70080e7          	jalr	-912(ra) # 8000462a <end_op>
    return -1;
    800059c2:	57fd                	li	a5,-1
    800059c4:	a83d                	j	80005a02 <sys_link+0x13c>
    iunlockput(dp);
    800059c6:	854a                	mv	a0,s2
    800059c8:	ffffe097          	auipc	ra,0xffffe
    800059cc:	15c080e7          	jalr	348(ra) # 80003b24 <iunlockput>

bad:
  ilock(ip);
    800059d0:	8526                	mv	a0,s1
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	ef0080e7          	jalr	-272(ra) # 800038c2 <ilock>
  ip->nlink--;
    800059da:	04a4d783          	lhu	a5,74(s1)
    800059de:	37fd                	addiw	a5,a5,-1
    800059e0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059e4:	8526                	mv	a0,s1
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	e12080e7          	jalr	-494(ra) # 800037f8 <iupdate>
  iunlockput(ip);
    800059ee:	8526                	mv	a0,s1
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	134080e7          	jalr	308(ra) # 80003b24 <iunlockput>
  end_op();
    800059f8:	fffff097          	auipc	ra,0xfffff
    800059fc:	c32080e7          	jalr	-974(ra) # 8000462a <end_op>
  return -1;
    80005a00:	57fd                	li	a5,-1
}
    80005a02:	853e                	mv	a0,a5
    80005a04:	70b2                	ld	ra,296(sp)
    80005a06:	7412                	ld	s0,288(sp)
    80005a08:	64f2                	ld	s1,280(sp)
    80005a0a:	6952                	ld	s2,272(sp)
    80005a0c:	6155                	addi	sp,sp,304
    80005a0e:	8082                	ret

0000000080005a10 <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a10:	4578                	lw	a4,76(a0)
    80005a12:	02000793          	li	a5,32
    80005a16:	04e7fa63          	bgeu	a5,a4,80005a6a <isdirempty+0x5a>
{
    80005a1a:	7179                	addi	sp,sp,-48
    80005a1c:	f406                	sd	ra,40(sp)
    80005a1e:	f022                	sd	s0,32(sp)
    80005a20:	ec26                	sd	s1,24(sp)
    80005a22:	e84a                	sd	s2,16(sp)
    80005a24:	1800                	addi	s0,sp,48
    80005a26:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a28:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a2c:	4741                	li	a4,16
    80005a2e:	86a6                	mv	a3,s1
    80005a30:	fd040613          	addi	a2,s0,-48
    80005a34:	4581                	li	a1,0
    80005a36:	854a                	mv	a0,s2
    80005a38:	ffffe097          	auipc	ra,0xffffe
    80005a3c:	13e080e7          	jalr	318(ra) # 80003b76 <readi>
    80005a40:	47c1                	li	a5,16
    80005a42:	00f51c63          	bne	a0,a5,80005a5a <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    80005a46:	fd045783          	lhu	a5,-48(s0)
    80005a4a:	e395                	bnez	a5,80005a6e <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a4c:	24c1                	addiw	s1,s1,16
    80005a4e:	04c92783          	lw	a5,76(s2)
    80005a52:	fcf4ede3          	bltu	s1,a5,80005a2c <isdirempty+0x1c>
      return 0;
  }
  return 1;
    80005a56:	4505                	li	a0,1
    80005a58:	a821                	j	80005a70 <isdirempty+0x60>
      panic("isdirempty: readi");
    80005a5a:	00003517          	auipc	a0,0x3
    80005a5e:	d0650513          	addi	a0,a0,-762 # 80008760 <syscalls+0x310>
    80005a62:	ffffb097          	auipc	ra,0xffffb
    80005a66:	ac8080e7          	jalr	-1336(ra) # 8000052a <panic>
  return 1;
    80005a6a:	4505                	li	a0,1
}
    80005a6c:	8082                	ret
      return 0;
    80005a6e:	4501                	li	a0,0
}
    80005a70:	70a2                	ld	ra,40(sp)
    80005a72:	7402                	ld	s0,32(sp)
    80005a74:	64e2                	ld	s1,24(sp)
    80005a76:	6942                	ld	s2,16(sp)
    80005a78:	6145                	addi	sp,sp,48
    80005a7a:	8082                	ret

0000000080005a7c <sys_unlink>:

uint64
sys_unlink(void)
{
    80005a7c:	7155                	addi	sp,sp,-208
    80005a7e:	e586                	sd	ra,200(sp)
    80005a80:	e1a2                	sd	s0,192(sp)
    80005a82:	fd26                	sd	s1,184(sp)
    80005a84:	f94a                	sd	s2,176(sp)
    80005a86:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    80005a88:	08000613          	li	a2,128
    80005a8c:	f4040593          	addi	a1,s0,-192
    80005a90:	4501                	li	a0,0
    80005a92:	ffffd097          	auipc	ra,0xffffd
    80005a96:	302080e7          	jalr	770(ra) # 80002d94 <argstr>
    80005a9a:	16054363          	bltz	a0,80005c00 <sys_unlink+0x184>
    return -1;

  begin_op();
    80005a9e:	fffff097          	auipc	ra,0xfffff
    80005aa2:	b0c080e7          	jalr	-1268(ra) # 800045aa <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005aa6:	fc040593          	addi	a1,s0,-64
    80005aaa:	f4040513          	addi	a0,s0,-192
    80005aae:	ffffe097          	auipc	ra,0xffffe
    80005ab2:	5e8080e7          	jalr	1512(ra) # 80004096 <nameiparent>
    80005ab6:	84aa                	mv	s1,a0
    80005ab8:	c961                	beqz	a0,80005b88 <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    80005aba:	ffffe097          	auipc	ra,0xffffe
    80005abe:	e08080e7          	jalr	-504(ra) # 800038c2 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005ac2:	00003597          	auipc	a1,0x3
    80005ac6:	b7e58593          	addi	a1,a1,-1154 # 80008640 <syscalls+0x1f0>
    80005aca:	fc040513          	addi	a0,s0,-64
    80005ace:	ffffe097          	auipc	ra,0xffffe
    80005ad2:	2be080e7          	jalr	702(ra) # 80003d8c <namecmp>
    80005ad6:	c175                	beqz	a0,80005bba <sys_unlink+0x13e>
    80005ad8:	00003597          	auipc	a1,0x3
    80005adc:	b7058593          	addi	a1,a1,-1168 # 80008648 <syscalls+0x1f8>
    80005ae0:	fc040513          	addi	a0,s0,-64
    80005ae4:	ffffe097          	auipc	ra,0xffffe
    80005ae8:	2a8080e7          	jalr	680(ra) # 80003d8c <namecmp>
    80005aec:	c579                	beqz	a0,80005bba <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80005aee:	f3c40613          	addi	a2,s0,-196
    80005af2:	fc040593          	addi	a1,s0,-64
    80005af6:	8526                	mv	a0,s1
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	2ae080e7          	jalr	686(ra) # 80003da6 <dirlookup>
    80005b00:	892a                	mv	s2,a0
    80005b02:	cd45                	beqz	a0,80005bba <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    80005b04:	ffffe097          	auipc	ra,0xffffe
    80005b08:	dbe080e7          	jalr	-578(ra) # 800038c2 <ilock>

  if(ip->nlink < 1)
    80005b0c:	04a91783          	lh	a5,74(s2)
    80005b10:	08f05263          	blez	a5,80005b94 <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b14:	04491703          	lh	a4,68(s2)
    80005b18:	4785                	li	a5,1
    80005b1a:	08f70563          	beq	a4,a5,80005ba4 <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80005b1e:	4641                	li	a2,16
    80005b20:	4581                	li	a1,0
    80005b22:	fd040513          	addi	a0,s0,-48
    80005b26:	ffffb097          	auipc	ra,0xffffb
    80005b2a:	198080e7          	jalr	408(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b2e:	4741                	li	a4,16
    80005b30:	f3c42683          	lw	a3,-196(s0)
    80005b34:	fd040613          	addi	a2,s0,-48
    80005b38:	4581                	li	a1,0
    80005b3a:	8526                	mv	a0,s1
    80005b3c:	ffffe097          	auipc	ra,0xffffe
    80005b40:	132080e7          	jalr	306(ra) # 80003c6e <writei>
    80005b44:	47c1                	li	a5,16
    80005b46:	08f51a63          	bne	a0,a5,80005bda <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80005b4a:	04491703          	lh	a4,68(s2)
    80005b4e:	4785                	li	a5,1
    80005b50:	08f70d63          	beq	a4,a5,80005bea <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80005b54:	8526                	mv	a0,s1
    80005b56:	ffffe097          	auipc	ra,0xffffe
    80005b5a:	fce080e7          	jalr	-50(ra) # 80003b24 <iunlockput>

  ip->nlink--;
    80005b5e:	04a95783          	lhu	a5,74(s2)
    80005b62:	37fd                	addiw	a5,a5,-1
    80005b64:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b68:	854a                	mv	a0,s2
    80005b6a:	ffffe097          	auipc	ra,0xffffe
    80005b6e:	c8e080e7          	jalr	-882(ra) # 800037f8 <iupdate>
  iunlockput(ip);
    80005b72:	854a                	mv	a0,s2
    80005b74:	ffffe097          	auipc	ra,0xffffe
    80005b78:	fb0080e7          	jalr	-80(ra) # 80003b24 <iunlockput>

  end_op();
    80005b7c:	fffff097          	auipc	ra,0xfffff
    80005b80:	aae080e7          	jalr	-1362(ra) # 8000462a <end_op>

  return 0;
    80005b84:	4501                	li	a0,0
    80005b86:	a0a1                	j	80005bce <sys_unlink+0x152>
    end_op();
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	aa2080e7          	jalr	-1374(ra) # 8000462a <end_op>
    return -1;
    80005b90:	557d                	li	a0,-1
    80005b92:	a835                	j	80005bce <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    80005b94:	00003517          	auipc	a0,0x3
    80005b98:	abc50513          	addi	a0,a0,-1348 # 80008650 <syscalls+0x200>
    80005b9c:	ffffb097          	auipc	ra,0xffffb
    80005ba0:	98e080e7          	jalr	-1650(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005ba4:	854a                	mv	a0,s2
    80005ba6:	00000097          	auipc	ra,0x0
    80005baa:	e6a080e7          	jalr	-406(ra) # 80005a10 <isdirempty>
    80005bae:	f925                	bnez	a0,80005b1e <sys_unlink+0xa2>
    iunlockput(ip);
    80005bb0:	854a                	mv	a0,s2
    80005bb2:	ffffe097          	auipc	ra,0xffffe
    80005bb6:	f72080e7          	jalr	-142(ra) # 80003b24 <iunlockput>

bad:
  iunlockput(dp);
    80005bba:	8526                	mv	a0,s1
    80005bbc:	ffffe097          	auipc	ra,0xffffe
    80005bc0:	f68080e7          	jalr	-152(ra) # 80003b24 <iunlockput>
  end_op();
    80005bc4:	fffff097          	auipc	ra,0xfffff
    80005bc8:	a66080e7          	jalr	-1434(ra) # 8000462a <end_op>
  return -1;
    80005bcc:	557d                	li	a0,-1
}
    80005bce:	60ae                	ld	ra,200(sp)
    80005bd0:	640e                	ld	s0,192(sp)
    80005bd2:	74ea                	ld	s1,184(sp)
    80005bd4:	794a                	ld	s2,176(sp)
    80005bd6:	6169                	addi	sp,sp,208
    80005bd8:	8082                	ret
    panic("unlink: writei");
    80005bda:	00003517          	auipc	a0,0x3
    80005bde:	a8e50513          	addi	a0,a0,-1394 # 80008668 <syscalls+0x218>
    80005be2:	ffffb097          	auipc	ra,0xffffb
    80005be6:	948080e7          	jalr	-1720(ra) # 8000052a <panic>
    dp->nlink--;
    80005bea:	04a4d783          	lhu	a5,74(s1)
    80005bee:	37fd                	addiw	a5,a5,-1
    80005bf0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005bf4:	8526                	mv	a0,s1
    80005bf6:	ffffe097          	auipc	ra,0xffffe
    80005bfa:	c02080e7          	jalr	-1022(ra) # 800037f8 <iupdate>
    80005bfe:	bf99                	j	80005b54 <sys_unlink+0xd8>
    return -1;
    80005c00:	557d                	li	a0,-1
    80005c02:	b7f1                	j	80005bce <sys_unlink+0x152>

0000000080005c04 <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    80005c04:	715d                	addi	sp,sp,-80
    80005c06:	e486                	sd	ra,72(sp)
    80005c08:	e0a2                	sd	s0,64(sp)
    80005c0a:	fc26                	sd	s1,56(sp)
    80005c0c:	f84a                	sd	s2,48(sp)
    80005c0e:	f44e                	sd	s3,40(sp)
    80005c10:	f052                	sd	s4,32(sp)
    80005c12:	ec56                	sd	s5,24(sp)
    80005c14:	0880                	addi	s0,sp,80
    80005c16:	89ae                	mv	s3,a1
    80005c18:	8ab2                	mv	s5,a2
    80005c1a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005c1c:	fb040593          	addi	a1,s0,-80
    80005c20:	ffffe097          	auipc	ra,0xffffe
    80005c24:	476080e7          	jalr	1142(ra) # 80004096 <nameiparent>
    80005c28:	892a                	mv	s2,a0
    80005c2a:	12050e63          	beqz	a0,80005d66 <create+0x162>
    return 0;

  ilock(dp);
    80005c2e:	ffffe097          	auipc	ra,0xffffe
    80005c32:	c94080e7          	jalr	-876(ra) # 800038c2 <ilock>
  
  if((ip = dirlookup(dp, name, 0)) != 0){
    80005c36:	4601                	li	a2,0
    80005c38:	fb040593          	addi	a1,s0,-80
    80005c3c:	854a                	mv	a0,s2
    80005c3e:	ffffe097          	auipc	ra,0xffffe
    80005c42:	168080e7          	jalr	360(ra) # 80003da6 <dirlookup>
    80005c46:	84aa                	mv	s1,a0
    80005c48:	c921                	beqz	a0,80005c98 <create+0x94>
    iunlockput(dp);
    80005c4a:	854a                	mv	a0,s2
    80005c4c:	ffffe097          	auipc	ra,0xffffe
    80005c50:	ed8080e7          	jalr	-296(ra) # 80003b24 <iunlockput>
    ilock(ip);
    80005c54:	8526                	mv	a0,s1
    80005c56:	ffffe097          	auipc	ra,0xffffe
    80005c5a:	c6c080e7          	jalr	-916(ra) # 800038c2 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005c5e:	2981                	sext.w	s3,s3
    80005c60:	4789                	li	a5,2
    80005c62:	02f99463          	bne	s3,a5,80005c8a <create+0x86>
    80005c66:	0444d783          	lhu	a5,68(s1)
    80005c6a:	37f9                	addiw	a5,a5,-2
    80005c6c:	17c2                	slli	a5,a5,0x30
    80005c6e:	93c1                	srli	a5,a5,0x30
    80005c70:	4705                	li	a4,1
    80005c72:	00f76c63          	bltu	a4,a5,80005c8a <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005c76:	8526                	mv	a0,s1
    80005c78:	60a6                	ld	ra,72(sp)
    80005c7a:	6406                	ld	s0,64(sp)
    80005c7c:	74e2                	ld	s1,56(sp)
    80005c7e:	7942                	ld	s2,48(sp)
    80005c80:	79a2                	ld	s3,40(sp)
    80005c82:	7a02                	ld	s4,32(sp)
    80005c84:	6ae2                	ld	s5,24(sp)
    80005c86:	6161                	addi	sp,sp,80
    80005c88:	8082                	ret
    iunlockput(ip);
    80005c8a:	8526                	mv	a0,s1
    80005c8c:	ffffe097          	auipc	ra,0xffffe
    80005c90:	e98080e7          	jalr	-360(ra) # 80003b24 <iunlockput>
    return 0;
    80005c94:	4481                	li	s1,0
    80005c96:	b7c5                	j	80005c76 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005c98:	85ce                	mv	a1,s3
    80005c9a:	00092503          	lw	a0,0(s2)
    80005c9e:	ffffe097          	auipc	ra,0xffffe
    80005ca2:	a8c080e7          	jalr	-1396(ra) # 8000372a <ialloc>
    80005ca6:	84aa                	mv	s1,a0
    80005ca8:	c521                	beqz	a0,80005cf0 <create+0xec>
  ilock(ip);
    80005caa:	ffffe097          	auipc	ra,0xffffe
    80005cae:	c18080e7          	jalr	-1000(ra) # 800038c2 <ilock>
  ip->major = major;
    80005cb2:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005cb6:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005cba:	4a05                	li	s4,1
    80005cbc:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005cc0:	8526                	mv	a0,s1
    80005cc2:	ffffe097          	auipc	ra,0xffffe
    80005cc6:	b36080e7          	jalr	-1226(ra) # 800037f8 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005cca:	2981                	sext.w	s3,s3
    80005ccc:	03498a63          	beq	s3,s4,80005d00 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005cd0:	40d0                	lw	a2,4(s1)
    80005cd2:	fb040593          	addi	a1,s0,-80
    80005cd6:	854a                	mv	a0,s2
    80005cd8:	ffffe097          	auipc	ra,0xffffe
    80005cdc:	2de080e7          	jalr	734(ra) # 80003fb6 <dirlink>
    80005ce0:	06054b63          	bltz	a0,80005d56 <create+0x152>
  iunlockput(dp);
    80005ce4:	854a                	mv	a0,s2
    80005ce6:	ffffe097          	auipc	ra,0xffffe
    80005cea:	e3e080e7          	jalr	-450(ra) # 80003b24 <iunlockput>
  return ip;
    80005cee:	b761                	j	80005c76 <create+0x72>
    panic("create: ialloc");
    80005cf0:	00003517          	auipc	a0,0x3
    80005cf4:	a8850513          	addi	a0,a0,-1400 # 80008778 <syscalls+0x328>
    80005cf8:	ffffb097          	auipc	ra,0xffffb
    80005cfc:	832080e7          	jalr	-1998(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80005d00:	04a95783          	lhu	a5,74(s2)
    80005d04:	2785                	addiw	a5,a5,1
    80005d06:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005d0a:	854a                	mv	a0,s2
    80005d0c:	ffffe097          	auipc	ra,0xffffe
    80005d10:	aec080e7          	jalr	-1300(ra) # 800037f8 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005d14:	40d0                	lw	a2,4(s1)
    80005d16:	00003597          	auipc	a1,0x3
    80005d1a:	92a58593          	addi	a1,a1,-1750 # 80008640 <syscalls+0x1f0>
    80005d1e:	8526                	mv	a0,s1
    80005d20:	ffffe097          	auipc	ra,0xffffe
    80005d24:	296080e7          	jalr	662(ra) # 80003fb6 <dirlink>
    80005d28:	00054f63          	bltz	a0,80005d46 <create+0x142>
    80005d2c:	00492603          	lw	a2,4(s2)
    80005d30:	00003597          	auipc	a1,0x3
    80005d34:	91858593          	addi	a1,a1,-1768 # 80008648 <syscalls+0x1f8>
    80005d38:	8526                	mv	a0,s1
    80005d3a:	ffffe097          	auipc	ra,0xffffe
    80005d3e:	27c080e7          	jalr	636(ra) # 80003fb6 <dirlink>
    80005d42:	f80557e3          	bgez	a0,80005cd0 <create+0xcc>
      panic("create dots");
    80005d46:	00003517          	auipc	a0,0x3
    80005d4a:	a4250513          	addi	a0,a0,-1470 # 80008788 <syscalls+0x338>
    80005d4e:	ffffa097          	auipc	ra,0xffffa
    80005d52:	7dc080e7          	jalr	2012(ra) # 8000052a <panic>
    panic("create: dirlink");
    80005d56:	00003517          	auipc	a0,0x3
    80005d5a:	a4250513          	addi	a0,a0,-1470 # 80008798 <syscalls+0x348>
    80005d5e:	ffffa097          	auipc	ra,0xffffa
    80005d62:	7cc080e7          	jalr	1996(ra) # 8000052a <panic>
    return 0;
    80005d66:	84aa                	mv	s1,a0
    80005d68:	b739                	j	80005c76 <create+0x72>

0000000080005d6a <sys_open>:

uint64
sys_open(void)
{
    80005d6a:	7131                	addi	sp,sp,-192
    80005d6c:	fd06                	sd	ra,184(sp)
    80005d6e:	f922                	sd	s0,176(sp)
    80005d70:	f526                	sd	s1,168(sp)
    80005d72:	f14a                	sd	s2,160(sp)
    80005d74:	ed4e                	sd	s3,152(sp)
    80005d76:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d78:	08000613          	li	a2,128
    80005d7c:	f5040593          	addi	a1,s0,-176
    80005d80:	4501                	li	a0,0
    80005d82:	ffffd097          	auipc	ra,0xffffd
    80005d86:	012080e7          	jalr	18(ra) # 80002d94 <argstr>
    return -1;
    80005d8a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d8c:	0c054163          	bltz	a0,80005e4e <sys_open+0xe4>
    80005d90:	f4c40593          	addi	a1,s0,-180
    80005d94:	4505                	li	a0,1
    80005d96:	ffffd097          	auipc	ra,0xffffd
    80005d9a:	fba080e7          	jalr	-70(ra) # 80002d50 <argint>
    80005d9e:	0a054863          	bltz	a0,80005e4e <sys_open+0xe4>

  begin_op();
    80005da2:	fffff097          	auipc	ra,0xfffff
    80005da6:	808080e7          	jalr	-2040(ra) # 800045aa <begin_op>

  if(omode & O_CREATE){
    80005daa:	f4c42783          	lw	a5,-180(s0)
    80005dae:	2007f793          	andi	a5,a5,512
    80005db2:	cbdd                	beqz	a5,80005e68 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005db4:	4681                	li	a3,0
    80005db6:	4601                	li	a2,0
    80005db8:	4589                	li	a1,2
    80005dba:	f5040513          	addi	a0,s0,-176
    80005dbe:	00000097          	auipc	ra,0x0
    80005dc2:	e46080e7          	jalr	-442(ra) # 80005c04 <create>
    80005dc6:	892a                	mv	s2,a0
    if(ip == 0){
    80005dc8:	c959                	beqz	a0,80005e5e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005dca:	04491703          	lh	a4,68(s2)
    80005dce:	478d                	li	a5,3
    80005dd0:	00f71763          	bne	a4,a5,80005dde <sys_open+0x74>
    80005dd4:	04695703          	lhu	a4,70(s2)
    80005dd8:	47a5                	li	a5,9
    80005dda:	0ce7ec63          	bltu	a5,a4,80005eb2 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005dde:	fffff097          	auipc	ra,0xfffff
    80005de2:	bdc080e7          	jalr	-1060(ra) # 800049ba <filealloc>
    80005de6:	89aa                	mv	s3,a0
    80005de8:	10050263          	beqz	a0,80005eec <sys_open+0x182>
    80005dec:	00000097          	auipc	ra,0x0
    80005df0:	8e2080e7          	jalr	-1822(ra) # 800056ce <fdalloc>
    80005df4:	84aa                	mv	s1,a0
    80005df6:	0e054663          	bltz	a0,80005ee2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005dfa:	04491703          	lh	a4,68(s2)
    80005dfe:	478d                	li	a5,3
    80005e00:	0cf70463          	beq	a4,a5,80005ec8 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005e04:	4789                	li	a5,2
    80005e06:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005e0a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005e0e:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005e12:	f4c42783          	lw	a5,-180(s0)
    80005e16:	0017c713          	xori	a4,a5,1
    80005e1a:	8b05                	andi	a4,a4,1
    80005e1c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e20:	0037f713          	andi	a4,a5,3
    80005e24:	00e03733          	snez	a4,a4
    80005e28:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e2c:	4007f793          	andi	a5,a5,1024
    80005e30:	c791                	beqz	a5,80005e3c <sys_open+0xd2>
    80005e32:	04491703          	lh	a4,68(s2)
    80005e36:	4789                	li	a5,2
    80005e38:	08f70f63          	beq	a4,a5,80005ed6 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e3c:	854a                	mv	a0,s2
    80005e3e:	ffffe097          	auipc	ra,0xffffe
    80005e42:	b46080e7          	jalr	-1210(ra) # 80003984 <iunlock>
  end_op();
    80005e46:	ffffe097          	auipc	ra,0xffffe
    80005e4a:	7e4080e7          	jalr	2020(ra) # 8000462a <end_op>

  return fd;
}
    80005e4e:	8526                	mv	a0,s1
    80005e50:	70ea                	ld	ra,184(sp)
    80005e52:	744a                	ld	s0,176(sp)
    80005e54:	74aa                	ld	s1,168(sp)
    80005e56:	790a                	ld	s2,160(sp)
    80005e58:	69ea                	ld	s3,152(sp)
    80005e5a:	6129                	addi	sp,sp,192
    80005e5c:	8082                	ret
      end_op();
    80005e5e:	ffffe097          	auipc	ra,0xffffe
    80005e62:	7cc080e7          	jalr	1996(ra) # 8000462a <end_op>
      return -1;
    80005e66:	b7e5                	j	80005e4e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005e68:	f5040513          	addi	a0,s0,-176
    80005e6c:	ffffe097          	auipc	ra,0xffffe
    80005e70:	20c080e7          	jalr	524(ra) # 80004078 <namei>
    80005e74:	892a                	mv	s2,a0
    80005e76:	c905                	beqz	a0,80005ea6 <sys_open+0x13c>
    ilock(ip);
    80005e78:	ffffe097          	auipc	ra,0xffffe
    80005e7c:	a4a080e7          	jalr	-1462(ra) # 800038c2 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e80:	04491703          	lh	a4,68(s2)
    80005e84:	4785                	li	a5,1
    80005e86:	f4f712e3          	bne	a4,a5,80005dca <sys_open+0x60>
    80005e8a:	f4c42783          	lw	a5,-180(s0)
    80005e8e:	dba1                	beqz	a5,80005dde <sys_open+0x74>
      iunlockput(ip);
    80005e90:	854a                	mv	a0,s2
    80005e92:	ffffe097          	auipc	ra,0xffffe
    80005e96:	c92080e7          	jalr	-878(ra) # 80003b24 <iunlockput>
      end_op();
    80005e9a:	ffffe097          	auipc	ra,0xffffe
    80005e9e:	790080e7          	jalr	1936(ra) # 8000462a <end_op>
      return -1;
    80005ea2:	54fd                	li	s1,-1
    80005ea4:	b76d                	j	80005e4e <sys_open+0xe4>
      end_op();
    80005ea6:	ffffe097          	auipc	ra,0xffffe
    80005eaa:	784080e7          	jalr	1924(ra) # 8000462a <end_op>
      return -1;
    80005eae:	54fd                	li	s1,-1
    80005eb0:	bf79                	j	80005e4e <sys_open+0xe4>
    iunlockput(ip);
    80005eb2:	854a                	mv	a0,s2
    80005eb4:	ffffe097          	auipc	ra,0xffffe
    80005eb8:	c70080e7          	jalr	-912(ra) # 80003b24 <iunlockput>
    end_op();
    80005ebc:	ffffe097          	auipc	ra,0xffffe
    80005ec0:	76e080e7          	jalr	1902(ra) # 8000462a <end_op>
    return -1;
    80005ec4:	54fd                	li	s1,-1
    80005ec6:	b761                	j	80005e4e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005ec8:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005ecc:	04691783          	lh	a5,70(s2)
    80005ed0:	02f99223          	sh	a5,36(s3)
    80005ed4:	bf2d                	j	80005e0e <sys_open+0xa4>
    itrunc(ip);
    80005ed6:	854a                	mv	a0,s2
    80005ed8:	ffffe097          	auipc	ra,0xffffe
    80005edc:	af8080e7          	jalr	-1288(ra) # 800039d0 <itrunc>
    80005ee0:	bfb1                	j	80005e3c <sys_open+0xd2>
      fileclose(f);
    80005ee2:	854e                	mv	a0,s3
    80005ee4:	fffff097          	auipc	ra,0xfffff
    80005ee8:	b92080e7          	jalr	-1134(ra) # 80004a76 <fileclose>
    iunlockput(ip);
    80005eec:	854a                	mv	a0,s2
    80005eee:	ffffe097          	auipc	ra,0xffffe
    80005ef2:	c36080e7          	jalr	-970(ra) # 80003b24 <iunlockput>
    end_op();
    80005ef6:	ffffe097          	auipc	ra,0xffffe
    80005efa:	734080e7          	jalr	1844(ra) # 8000462a <end_op>
    return -1;
    80005efe:	54fd                	li	s1,-1
    80005f00:	b7b9                	j	80005e4e <sys_open+0xe4>

0000000080005f02 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005f02:	7175                	addi	sp,sp,-144
    80005f04:	e506                	sd	ra,136(sp)
    80005f06:	e122                	sd	s0,128(sp)
    80005f08:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005f0a:	ffffe097          	auipc	ra,0xffffe
    80005f0e:	6a0080e7          	jalr	1696(ra) # 800045aa <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005f12:	08000613          	li	a2,128
    80005f16:	f7040593          	addi	a1,s0,-144
    80005f1a:	4501                	li	a0,0
    80005f1c:	ffffd097          	auipc	ra,0xffffd
    80005f20:	e78080e7          	jalr	-392(ra) # 80002d94 <argstr>
    80005f24:	02054963          	bltz	a0,80005f56 <sys_mkdir+0x54>
    80005f28:	4681                	li	a3,0
    80005f2a:	4601                	li	a2,0
    80005f2c:	4585                	li	a1,1
    80005f2e:	f7040513          	addi	a0,s0,-144
    80005f32:	00000097          	auipc	ra,0x0
    80005f36:	cd2080e7          	jalr	-814(ra) # 80005c04 <create>
    80005f3a:	cd11                	beqz	a0,80005f56 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f3c:	ffffe097          	auipc	ra,0xffffe
    80005f40:	be8080e7          	jalr	-1048(ra) # 80003b24 <iunlockput>
  end_op();
    80005f44:	ffffe097          	auipc	ra,0xffffe
    80005f48:	6e6080e7          	jalr	1766(ra) # 8000462a <end_op>
  return 0;
    80005f4c:	4501                	li	a0,0
}
    80005f4e:	60aa                	ld	ra,136(sp)
    80005f50:	640a                	ld	s0,128(sp)
    80005f52:	6149                	addi	sp,sp,144
    80005f54:	8082                	ret
    end_op();
    80005f56:	ffffe097          	auipc	ra,0xffffe
    80005f5a:	6d4080e7          	jalr	1748(ra) # 8000462a <end_op>
    return -1;
    80005f5e:	557d                	li	a0,-1
    80005f60:	b7fd                	j	80005f4e <sys_mkdir+0x4c>

0000000080005f62 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f62:	7135                	addi	sp,sp,-160
    80005f64:	ed06                	sd	ra,152(sp)
    80005f66:	e922                	sd	s0,144(sp)
    80005f68:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f6a:	ffffe097          	auipc	ra,0xffffe
    80005f6e:	640080e7          	jalr	1600(ra) # 800045aa <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f72:	08000613          	li	a2,128
    80005f76:	f7040593          	addi	a1,s0,-144
    80005f7a:	4501                	li	a0,0
    80005f7c:	ffffd097          	auipc	ra,0xffffd
    80005f80:	e18080e7          	jalr	-488(ra) # 80002d94 <argstr>
    80005f84:	04054a63          	bltz	a0,80005fd8 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005f88:	f6c40593          	addi	a1,s0,-148
    80005f8c:	4505                	li	a0,1
    80005f8e:	ffffd097          	auipc	ra,0xffffd
    80005f92:	dc2080e7          	jalr	-574(ra) # 80002d50 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f96:	04054163          	bltz	a0,80005fd8 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005f9a:	f6840593          	addi	a1,s0,-152
    80005f9e:	4509                	li	a0,2
    80005fa0:	ffffd097          	auipc	ra,0xffffd
    80005fa4:	db0080e7          	jalr	-592(ra) # 80002d50 <argint>
     argint(1, &major) < 0 ||
    80005fa8:	02054863          	bltz	a0,80005fd8 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005fac:	f6841683          	lh	a3,-152(s0)
    80005fb0:	f6c41603          	lh	a2,-148(s0)
    80005fb4:	458d                	li	a1,3
    80005fb6:	f7040513          	addi	a0,s0,-144
    80005fba:	00000097          	auipc	ra,0x0
    80005fbe:	c4a080e7          	jalr	-950(ra) # 80005c04 <create>
     argint(2, &minor) < 0 ||
    80005fc2:	c919                	beqz	a0,80005fd8 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005fc4:	ffffe097          	auipc	ra,0xffffe
    80005fc8:	b60080e7          	jalr	-1184(ra) # 80003b24 <iunlockput>
  end_op();
    80005fcc:	ffffe097          	auipc	ra,0xffffe
    80005fd0:	65e080e7          	jalr	1630(ra) # 8000462a <end_op>
  return 0;
    80005fd4:	4501                	li	a0,0
    80005fd6:	a031                	j	80005fe2 <sys_mknod+0x80>
    end_op();
    80005fd8:	ffffe097          	auipc	ra,0xffffe
    80005fdc:	652080e7          	jalr	1618(ra) # 8000462a <end_op>
    return -1;
    80005fe0:	557d                	li	a0,-1
}
    80005fe2:	60ea                	ld	ra,152(sp)
    80005fe4:	644a                	ld	s0,144(sp)
    80005fe6:	610d                	addi	sp,sp,160
    80005fe8:	8082                	ret

0000000080005fea <sys_chdir>:

uint64
sys_chdir(void)
{
    80005fea:	7135                	addi	sp,sp,-160
    80005fec:	ed06                	sd	ra,152(sp)
    80005fee:	e922                	sd	s0,144(sp)
    80005ff0:	e526                	sd	s1,136(sp)
    80005ff2:	e14a                	sd	s2,128(sp)
    80005ff4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ff6:	ffffc097          	auipc	ra,0xffffc
    80005ffa:	b86080e7          	jalr	-1146(ra) # 80001b7c <myproc>
    80005ffe:	892a                	mv	s2,a0
  
  begin_op();
    80006000:	ffffe097          	auipc	ra,0xffffe
    80006004:	5aa080e7          	jalr	1450(ra) # 800045aa <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006008:	08000613          	li	a2,128
    8000600c:	f6040593          	addi	a1,s0,-160
    80006010:	4501                	li	a0,0
    80006012:	ffffd097          	auipc	ra,0xffffd
    80006016:	d82080e7          	jalr	-638(ra) # 80002d94 <argstr>
    8000601a:	04054b63          	bltz	a0,80006070 <sys_chdir+0x86>
    8000601e:	f6040513          	addi	a0,s0,-160
    80006022:	ffffe097          	auipc	ra,0xffffe
    80006026:	056080e7          	jalr	86(ra) # 80004078 <namei>
    8000602a:	84aa                	mv	s1,a0
    8000602c:	c131                	beqz	a0,80006070 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000602e:	ffffe097          	auipc	ra,0xffffe
    80006032:	894080e7          	jalr	-1900(ra) # 800038c2 <ilock>
  if(ip->type != T_DIR){
    80006036:	04449703          	lh	a4,68(s1)
    8000603a:	4785                	li	a5,1
    8000603c:	04f71063          	bne	a4,a5,8000607c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006040:	8526                	mv	a0,s1
    80006042:	ffffe097          	auipc	ra,0xffffe
    80006046:	942080e7          	jalr	-1726(ra) # 80003984 <iunlock>
  iput(p->cwd);
    8000604a:	15093503          	ld	a0,336(s2)
    8000604e:	ffffe097          	auipc	ra,0xffffe
    80006052:	a2e080e7          	jalr	-1490(ra) # 80003a7c <iput>
  end_op();
    80006056:	ffffe097          	auipc	ra,0xffffe
    8000605a:	5d4080e7          	jalr	1492(ra) # 8000462a <end_op>
  p->cwd = ip;
    8000605e:	14993823          	sd	s1,336(s2)
  return 0;
    80006062:	4501                	li	a0,0
}
    80006064:	60ea                	ld	ra,152(sp)
    80006066:	644a                	ld	s0,144(sp)
    80006068:	64aa                	ld	s1,136(sp)
    8000606a:	690a                	ld	s2,128(sp)
    8000606c:	610d                	addi	sp,sp,160
    8000606e:	8082                	ret
    end_op();
    80006070:	ffffe097          	auipc	ra,0xffffe
    80006074:	5ba080e7          	jalr	1466(ra) # 8000462a <end_op>
    return -1;
    80006078:	557d                	li	a0,-1
    8000607a:	b7ed                	j	80006064 <sys_chdir+0x7a>
    iunlockput(ip);
    8000607c:	8526                	mv	a0,s1
    8000607e:	ffffe097          	auipc	ra,0xffffe
    80006082:	aa6080e7          	jalr	-1370(ra) # 80003b24 <iunlockput>
    end_op();
    80006086:	ffffe097          	auipc	ra,0xffffe
    8000608a:	5a4080e7          	jalr	1444(ra) # 8000462a <end_op>
    return -1;
    8000608e:	557d                	li	a0,-1
    80006090:	bfd1                	j	80006064 <sys_chdir+0x7a>

0000000080006092 <sys_exec>:

uint64
sys_exec(void)
{
    80006092:	7145                	addi	sp,sp,-464
    80006094:	e786                	sd	ra,456(sp)
    80006096:	e3a2                	sd	s0,448(sp)
    80006098:	ff26                	sd	s1,440(sp)
    8000609a:	fb4a                	sd	s2,432(sp)
    8000609c:	f74e                	sd	s3,424(sp)
    8000609e:	f352                	sd	s4,416(sp)
    800060a0:	ef56                	sd	s5,408(sp)
    800060a2:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800060a4:	08000613          	li	a2,128
    800060a8:	f4040593          	addi	a1,s0,-192
    800060ac:	4501                	li	a0,0
    800060ae:	ffffd097          	auipc	ra,0xffffd
    800060b2:	ce6080e7          	jalr	-794(ra) # 80002d94 <argstr>
    return -1;
    800060b6:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800060b8:	0c054a63          	bltz	a0,8000618c <sys_exec+0xfa>
    800060bc:	e3840593          	addi	a1,s0,-456
    800060c0:	4505                	li	a0,1
    800060c2:	ffffd097          	auipc	ra,0xffffd
    800060c6:	cb0080e7          	jalr	-848(ra) # 80002d72 <argaddr>
    800060ca:	0c054163          	bltz	a0,8000618c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800060ce:	10000613          	li	a2,256
    800060d2:	4581                	li	a1,0
    800060d4:	e4040513          	addi	a0,s0,-448
    800060d8:	ffffb097          	auipc	ra,0xffffb
    800060dc:	be6080e7          	jalr	-1050(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800060e0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800060e4:	89a6                	mv	s3,s1
    800060e6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800060e8:	02000a13          	li	s4,32
    800060ec:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800060f0:	00391793          	slli	a5,s2,0x3
    800060f4:	e3040593          	addi	a1,s0,-464
    800060f8:	e3843503          	ld	a0,-456(s0)
    800060fc:	953e                	add	a0,a0,a5
    800060fe:	ffffd097          	auipc	ra,0xffffd
    80006102:	bb8080e7          	jalr	-1096(ra) # 80002cb6 <fetchaddr>
    80006106:	02054a63          	bltz	a0,8000613a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000610a:	e3043783          	ld	a5,-464(s0)
    8000610e:	c3b9                	beqz	a5,80006154 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006110:	ffffb097          	auipc	ra,0xffffb
    80006114:	9c2080e7          	jalr	-1598(ra) # 80000ad2 <kalloc>
    80006118:	85aa                	mv	a1,a0
    8000611a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000611e:	cd11                	beqz	a0,8000613a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006120:	6605                	lui	a2,0x1
    80006122:	e3043503          	ld	a0,-464(s0)
    80006126:	ffffd097          	auipc	ra,0xffffd
    8000612a:	be2080e7          	jalr	-1054(ra) # 80002d08 <fetchstr>
    8000612e:	00054663          	bltz	a0,8000613a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006132:	0905                	addi	s2,s2,1
    80006134:	09a1                	addi	s3,s3,8
    80006136:	fb491be3          	bne	s2,s4,800060ec <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000613a:	10048913          	addi	s2,s1,256
    8000613e:	6088                	ld	a0,0(s1)
    80006140:	c529                	beqz	a0,8000618a <sys_exec+0xf8>
    kfree(argv[i]);
    80006142:	ffffb097          	auipc	ra,0xffffb
    80006146:	894080e7          	jalr	-1900(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000614a:	04a1                	addi	s1,s1,8
    8000614c:	ff2499e3          	bne	s1,s2,8000613e <sys_exec+0xac>
  return -1;
    80006150:	597d                	li	s2,-1
    80006152:	a82d                	j	8000618c <sys_exec+0xfa>
      argv[i] = 0;
    80006154:	0a8e                	slli	s5,s5,0x3
    80006156:	fc040793          	addi	a5,s0,-64
    8000615a:	9abe                	add	s5,s5,a5
    8000615c:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd3e80>
  int ret = exec(path, argv);
    80006160:	e4040593          	addi	a1,s0,-448
    80006164:	f4040513          	addi	a0,s0,-192
    80006168:	fffff097          	auipc	ra,0xfffff
    8000616c:	156080e7          	jalr	342(ra) # 800052be <exec>
    80006170:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006172:	10048993          	addi	s3,s1,256
    80006176:	6088                	ld	a0,0(s1)
    80006178:	c911                	beqz	a0,8000618c <sys_exec+0xfa>
    kfree(argv[i]);
    8000617a:	ffffb097          	auipc	ra,0xffffb
    8000617e:	85c080e7          	jalr	-1956(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006182:	04a1                	addi	s1,s1,8
    80006184:	ff3499e3          	bne	s1,s3,80006176 <sys_exec+0xe4>
    80006188:	a011                	j	8000618c <sys_exec+0xfa>
  return -1;
    8000618a:	597d                	li	s2,-1
}
    8000618c:	854a                	mv	a0,s2
    8000618e:	60be                	ld	ra,456(sp)
    80006190:	641e                	ld	s0,448(sp)
    80006192:	74fa                	ld	s1,440(sp)
    80006194:	795a                	ld	s2,432(sp)
    80006196:	79ba                	ld	s3,424(sp)
    80006198:	7a1a                	ld	s4,416(sp)
    8000619a:	6afa                	ld	s5,408(sp)
    8000619c:	6179                	addi	sp,sp,464
    8000619e:	8082                	ret

00000000800061a0 <sys_pipe>:

uint64
sys_pipe(void)
{
    800061a0:	7139                	addi	sp,sp,-64
    800061a2:	fc06                	sd	ra,56(sp)
    800061a4:	f822                	sd	s0,48(sp)
    800061a6:	f426                	sd	s1,40(sp)
    800061a8:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800061aa:	ffffc097          	auipc	ra,0xffffc
    800061ae:	9d2080e7          	jalr	-1582(ra) # 80001b7c <myproc>
    800061b2:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800061b4:	fd840593          	addi	a1,s0,-40
    800061b8:	4501                	li	a0,0
    800061ba:	ffffd097          	auipc	ra,0xffffd
    800061be:	bb8080e7          	jalr	-1096(ra) # 80002d72 <argaddr>
    return -1;
    800061c2:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800061c4:	0e054063          	bltz	a0,800062a4 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800061c8:	fc840593          	addi	a1,s0,-56
    800061cc:	fd040513          	addi	a0,s0,-48
    800061d0:	fffff097          	auipc	ra,0xfffff
    800061d4:	dcc080e7          	jalr	-564(ra) # 80004f9c <pipealloc>
    return -1;
    800061d8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800061da:	0c054563          	bltz	a0,800062a4 <sys_pipe+0x104>
  fd0 = -1;
    800061de:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800061e2:	fd043503          	ld	a0,-48(s0)
    800061e6:	fffff097          	auipc	ra,0xfffff
    800061ea:	4e8080e7          	jalr	1256(ra) # 800056ce <fdalloc>
    800061ee:	fca42223          	sw	a0,-60(s0)
    800061f2:	08054c63          	bltz	a0,8000628a <sys_pipe+0xea>
    800061f6:	fc843503          	ld	a0,-56(s0)
    800061fa:	fffff097          	auipc	ra,0xfffff
    800061fe:	4d4080e7          	jalr	1236(ra) # 800056ce <fdalloc>
    80006202:	fca42023          	sw	a0,-64(s0)
    80006206:	06054863          	bltz	a0,80006276 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000620a:	4691                	li	a3,4
    8000620c:	fc440613          	addi	a2,s0,-60
    80006210:	fd843583          	ld	a1,-40(s0)
    80006214:	68a8                	ld	a0,80(s1)
    80006216:	ffffb097          	auipc	ra,0xffffb
    8000621a:	626080e7          	jalr	1574(ra) # 8000183c <copyout>
    8000621e:	02054063          	bltz	a0,8000623e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006222:	4691                	li	a3,4
    80006224:	fc040613          	addi	a2,s0,-64
    80006228:	fd843583          	ld	a1,-40(s0)
    8000622c:	0591                	addi	a1,a1,4
    8000622e:	68a8                	ld	a0,80(s1)
    80006230:	ffffb097          	auipc	ra,0xffffb
    80006234:	60c080e7          	jalr	1548(ra) # 8000183c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006238:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000623a:	06055563          	bgez	a0,800062a4 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000623e:	fc442783          	lw	a5,-60(s0)
    80006242:	07e9                	addi	a5,a5,26
    80006244:	078e                	slli	a5,a5,0x3
    80006246:	97a6                	add	a5,a5,s1
    80006248:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000624c:	fc042503          	lw	a0,-64(s0)
    80006250:	0569                	addi	a0,a0,26
    80006252:	050e                	slli	a0,a0,0x3
    80006254:	9526                	add	a0,a0,s1
    80006256:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000625a:	fd043503          	ld	a0,-48(s0)
    8000625e:	fffff097          	auipc	ra,0xfffff
    80006262:	818080e7          	jalr	-2024(ra) # 80004a76 <fileclose>
    fileclose(wf);
    80006266:	fc843503          	ld	a0,-56(s0)
    8000626a:	fffff097          	auipc	ra,0xfffff
    8000626e:	80c080e7          	jalr	-2036(ra) # 80004a76 <fileclose>
    return -1;
    80006272:	57fd                	li	a5,-1
    80006274:	a805                	j	800062a4 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006276:	fc442783          	lw	a5,-60(s0)
    8000627a:	0007c863          	bltz	a5,8000628a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000627e:	01a78513          	addi	a0,a5,26
    80006282:	050e                	slli	a0,a0,0x3
    80006284:	9526                	add	a0,a0,s1
    80006286:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000628a:	fd043503          	ld	a0,-48(s0)
    8000628e:	ffffe097          	auipc	ra,0xffffe
    80006292:	7e8080e7          	jalr	2024(ra) # 80004a76 <fileclose>
    fileclose(wf);
    80006296:	fc843503          	ld	a0,-56(s0)
    8000629a:	ffffe097          	auipc	ra,0xffffe
    8000629e:	7dc080e7          	jalr	2012(ra) # 80004a76 <fileclose>
    return -1;
    800062a2:	57fd                	li	a5,-1
}
    800062a4:	853e                	mv	a0,a5
    800062a6:	70e2                	ld	ra,56(sp)
    800062a8:	7442                	ld	s0,48(sp)
    800062aa:	74a2                	ld	s1,40(sp)
    800062ac:	6121                	addi	sp,sp,64
    800062ae:	8082                	ret

00000000800062b0 <kernelvec>:
    800062b0:	7111                	addi	sp,sp,-256
    800062b2:	e006                	sd	ra,0(sp)
    800062b4:	e40a                	sd	sp,8(sp)
    800062b6:	e80e                	sd	gp,16(sp)
    800062b8:	ec12                	sd	tp,24(sp)
    800062ba:	f016                	sd	t0,32(sp)
    800062bc:	f41a                	sd	t1,40(sp)
    800062be:	f81e                	sd	t2,48(sp)
    800062c0:	fc22                	sd	s0,56(sp)
    800062c2:	e0a6                	sd	s1,64(sp)
    800062c4:	e4aa                	sd	a0,72(sp)
    800062c6:	e8ae                	sd	a1,80(sp)
    800062c8:	ecb2                	sd	a2,88(sp)
    800062ca:	f0b6                	sd	a3,96(sp)
    800062cc:	f4ba                	sd	a4,104(sp)
    800062ce:	f8be                	sd	a5,112(sp)
    800062d0:	fcc2                	sd	a6,120(sp)
    800062d2:	e146                	sd	a7,128(sp)
    800062d4:	e54a                	sd	s2,136(sp)
    800062d6:	e94e                	sd	s3,144(sp)
    800062d8:	ed52                	sd	s4,152(sp)
    800062da:	f156                	sd	s5,160(sp)
    800062dc:	f55a                	sd	s6,168(sp)
    800062de:	f95e                	sd	s7,176(sp)
    800062e0:	fd62                	sd	s8,184(sp)
    800062e2:	e1e6                	sd	s9,192(sp)
    800062e4:	e5ea                	sd	s10,200(sp)
    800062e6:	e9ee                	sd	s11,208(sp)
    800062e8:	edf2                	sd	t3,216(sp)
    800062ea:	f1f6                	sd	t4,224(sp)
    800062ec:	f5fa                	sd	t5,232(sp)
    800062ee:	f9fe                	sd	t6,240(sp)
    800062f0:	893fc0ef          	jal	ra,80002b82 <kerneltrap>
    800062f4:	6082                	ld	ra,0(sp)
    800062f6:	6122                	ld	sp,8(sp)
    800062f8:	61c2                	ld	gp,16(sp)
    800062fa:	7282                	ld	t0,32(sp)
    800062fc:	7322                	ld	t1,40(sp)
    800062fe:	73c2                	ld	t2,48(sp)
    80006300:	7462                	ld	s0,56(sp)
    80006302:	6486                	ld	s1,64(sp)
    80006304:	6526                	ld	a0,72(sp)
    80006306:	65c6                	ld	a1,80(sp)
    80006308:	6666                	ld	a2,88(sp)
    8000630a:	7686                	ld	a3,96(sp)
    8000630c:	7726                	ld	a4,104(sp)
    8000630e:	77c6                	ld	a5,112(sp)
    80006310:	7866                	ld	a6,120(sp)
    80006312:	688a                	ld	a7,128(sp)
    80006314:	692a                	ld	s2,136(sp)
    80006316:	69ca                	ld	s3,144(sp)
    80006318:	6a6a                	ld	s4,152(sp)
    8000631a:	7a8a                	ld	s5,160(sp)
    8000631c:	7b2a                	ld	s6,168(sp)
    8000631e:	7bca                	ld	s7,176(sp)
    80006320:	7c6a                	ld	s8,184(sp)
    80006322:	6c8e                	ld	s9,192(sp)
    80006324:	6d2e                	ld	s10,200(sp)
    80006326:	6dce                	ld	s11,208(sp)
    80006328:	6e6e                	ld	t3,216(sp)
    8000632a:	7e8e                	ld	t4,224(sp)
    8000632c:	7f2e                	ld	t5,232(sp)
    8000632e:	7fce                	ld	t6,240(sp)
    80006330:	6111                	addi	sp,sp,256
    80006332:	10200073          	sret
    80006336:	00000013          	nop
    8000633a:	00000013          	nop
    8000633e:	0001                	nop

0000000080006340 <timervec>:
    80006340:	34051573          	csrrw	a0,mscratch,a0
    80006344:	e10c                	sd	a1,0(a0)
    80006346:	e510                	sd	a2,8(a0)
    80006348:	e914                	sd	a3,16(a0)
    8000634a:	6d0c                	ld	a1,24(a0)
    8000634c:	7110                	ld	a2,32(a0)
    8000634e:	6194                	ld	a3,0(a1)
    80006350:	96b2                	add	a3,a3,a2
    80006352:	e194                	sd	a3,0(a1)
    80006354:	4589                	li	a1,2
    80006356:	14459073          	csrw	sip,a1
    8000635a:	6914                	ld	a3,16(a0)
    8000635c:	6510                	ld	a2,8(a0)
    8000635e:	610c                	ld	a1,0(a0)
    80006360:	34051573          	csrrw	a0,mscratch,a0
    80006364:	30200073          	mret
	...

000000008000636a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000636a:	1141                	addi	sp,sp,-16
    8000636c:	e422                	sd	s0,8(sp)
    8000636e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006370:	0c0007b7          	lui	a5,0xc000
    80006374:	4705                	li	a4,1
    80006376:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006378:	c3d8                	sw	a4,4(a5)
}
    8000637a:	6422                	ld	s0,8(sp)
    8000637c:	0141                	addi	sp,sp,16
    8000637e:	8082                	ret

0000000080006380 <plicinithart>:

void
plicinithart(void)
{
    80006380:	1141                	addi	sp,sp,-16
    80006382:	e406                	sd	ra,8(sp)
    80006384:	e022                	sd	s0,0(sp)
    80006386:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006388:	ffffb097          	auipc	ra,0xffffb
    8000638c:	7c8080e7          	jalr	1992(ra) # 80001b50 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006390:	0085171b          	slliw	a4,a0,0x8
    80006394:	0c0027b7          	lui	a5,0xc002
    80006398:	97ba                	add	a5,a5,a4
    8000639a:	40200713          	li	a4,1026
    8000639e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800063a2:	00d5151b          	slliw	a0,a0,0xd
    800063a6:	0c2017b7          	lui	a5,0xc201
    800063aa:	953e                	add	a0,a0,a5
    800063ac:	00052023          	sw	zero,0(a0)
}
    800063b0:	60a2                	ld	ra,8(sp)
    800063b2:	6402                	ld	s0,0(sp)
    800063b4:	0141                	addi	sp,sp,16
    800063b6:	8082                	ret

00000000800063b8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800063b8:	1141                	addi	sp,sp,-16
    800063ba:	e406                	sd	ra,8(sp)
    800063bc:	e022                	sd	s0,0(sp)
    800063be:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063c0:	ffffb097          	auipc	ra,0xffffb
    800063c4:	790080e7          	jalr	1936(ra) # 80001b50 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800063c8:	00d5179b          	slliw	a5,a0,0xd
    800063cc:	0c201537          	lui	a0,0xc201
    800063d0:	953e                	add	a0,a0,a5
  return irq;
}
    800063d2:	4148                	lw	a0,4(a0)
    800063d4:	60a2                	ld	ra,8(sp)
    800063d6:	6402                	ld	s0,0(sp)
    800063d8:	0141                	addi	sp,sp,16
    800063da:	8082                	ret

00000000800063dc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800063dc:	1101                	addi	sp,sp,-32
    800063de:	ec06                	sd	ra,24(sp)
    800063e0:	e822                	sd	s0,16(sp)
    800063e2:	e426                	sd	s1,8(sp)
    800063e4:	1000                	addi	s0,sp,32
    800063e6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800063e8:	ffffb097          	auipc	ra,0xffffb
    800063ec:	768080e7          	jalr	1896(ra) # 80001b50 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800063f0:	00d5151b          	slliw	a0,a0,0xd
    800063f4:	0c2017b7          	lui	a5,0xc201
    800063f8:	97aa                	add	a5,a5,a0
    800063fa:	c3c4                	sw	s1,4(a5)
}
    800063fc:	60e2                	ld	ra,24(sp)
    800063fe:	6442                	ld	s0,16(sp)
    80006400:	64a2                	ld	s1,8(sp)
    80006402:	6105                	addi	sp,sp,32
    80006404:	8082                	ret

0000000080006406 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006406:	1141                	addi	sp,sp,-16
    80006408:	e406                	sd	ra,8(sp)
    8000640a:	e022                	sd	s0,0(sp)
    8000640c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000640e:	479d                	li	a5,7
    80006410:	06a7c963          	blt	a5,a0,80006482 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006414:	00022797          	auipc	a5,0x22
    80006418:	bec78793          	addi	a5,a5,-1044 # 80028000 <disk>
    8000641c:	00a78733          	add	a4,a5,a0
    80006420:	6789                	lui	a5,0x2
    80006422:	97ba                	add	a5,a5,a4
    80006424:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006428:	e7ad                	bnez	a5,80006492 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000642a:	00451793          	slli	a5,a0,0x4
    8000642e:	00024717          	auipc	a4,0x24
    80006432:	bd270713          	addi	a4,a4,-1070 # 8002a000 <disk+0x2000>
    80006436:	6314                	ld	a3,0(a4)
    80006438:	96be                	add	a3,a3,a5
    8000643a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000643e:	6314                	ld	a3,0(a4)
    80006440:	96be                	add	a3,a3,a5
    80006442:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006446:	6314                	ld	a3,0(a4)
    80006448:	96be                	add	a3,a3,a5
    8000644a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000644e:	6318                	ld	a4,0(a4)
    80006450:	97ba                	add	a5,a5,a4
    80006452:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006456:	00022797          	auipc	a5,0x22
    8000645a:	baa78793          	addi	a5,a5,-1110 # 80028000 <disk>
    8000645e:	97aa                	add	a5,a5,a0
    80006460:	6509                	lui	a0,0x2
    80006462:	953e                	add	a0,a0,a5
    80006464:	4785                	li	a5,1
    80006466:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000646a:	00024517          	auipc	a0,0x24
    8000646e:	bae50513          	addi	a0,a0,-1106 # 8002a018 <disk+0x2018>
    80006472:	ffffc097          	auipc	ra,0xffffc
    80006476:	048080e7          	jalr	72(ra) # 800024ba <wakeup>
}
    8000647a:	60a2                	ld	ra,8(sp)
    8000647c:	6402                	ld	s0,0(sp)
    8000647e:	0141                	addi	sp,sp,16
    80006480:	8082                	ret
    panic("free_desc 1");
    80006482:	00002517          	auipc	a0,0x2
    80006486:	32650513          	addi	a0,a0,806 # 800087a8 <syscalls+0x358>
    8000648a:	ffffa097          	auipc	ra,0xffffa
    8000648e:	0a0080e7          	jalr	160(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006492:	00002517          	auipc	a0,0x2
    80006496:	32650513          	addi	a0,a0,806 # 800087b8 <syscalls+0x368>
    8000649a:	ffffa097          	auipc	ra,0xffffa
    8000649e:	090080e7          	jalr	144(ra) # 8000052a <panic>

00000000800064a2 <virtio_disk_init>:
{
    800064a2:	1101                	addi	sp,sp,-32
    800064a4:	ec06                	sd	ra,24(sp)
    800064a6:	e822                	sd	s0,16(sp)
    800064a8:	e426                	sd	s1,8(sp)
    800064aa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800064ac:	00002597          	auipc	a1,0x2
    800064b0:	31c58593          	addi	a1,a1,796 # 800087c8 <syscalls+0x378>
    800064b4:	00024517          	auipc	a0,0x24
    800064b8:	c7450513          	addi	a0,a0,-908 # 8002a128 <disk+0x2128>
    800064bc:	ffffa097          	auipc	ra,0xffffa
    800064c0:	676080e7          	jalr	1654(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064c4:	100017b7          	lui	a5,0x10001
    800064c8:	4398                	lw	a4,0(a5)
    800064ca:	2701                	sext.w	a4,a4
    800064cc:	747277b7          	lui	a5,0x74727
    800064d0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800064d4:	0ef71163          	bne	a4,a5,800065b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064d8:	100017b7          	lui	a5,0x10001
    800064dc:	43dc                	lw	a5,4(a5)
    800064de:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064e0:	4705                	li	a4,1
    800064e2:	0ce79a63          	bne	a5,a4,800065b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064e6:	100017b7          	lui	a5,0x10001
    800064ea:	479c                	lw	a5,8(a5)
    800064ec:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064ee:	4709                	li	a4,2
    800064f0:	0ce79363          	bne	a5,a4,800065b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800064f4:	100017b7          	lui	a5,0x10001
    800064f8:	47d8                	lw	a4,12(a5)
    800064fa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064fc:	554d47b7          	lui	a5,0x554d4
    80006500:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006504:	0af71963          	bne	a4,a5,800065b6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006508:	100017b7          	lui	a5,0x10001
    8000650c:	4705                	li	a4,1
    8000650e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006510:	470d                	li	a4,3
    80006512:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006514:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006516:	c7ffe737          	lui	a4,0xc7ffe
    8000651a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd375f>
    8000651e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006520:	2701                	sext.w	a4,a4
    80006522:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006524:	472d                	li	a4,11
    80006526:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006528:	473d                	li	a4,15
    8000652a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000652c:	6705                	lui	a4,0x1
    8000652e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006530:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006534:	5bdc                	lw	a5,52(a5)
    80006536:	2781                	sext.w	a5,a5
  if(max == 0)
    80006538:	c7d9                	beqz	a5,800065c6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000653a:	471d                	li	a4,7
    8000653c:	08f77d63          	bgeu	a4,a5,800065d6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006540:	100014b7          	lui	s1,0x10001
    80006544:	47a1                	li	a5,8
    80006546:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006548:	6609                	lui	a2,0x2
    8000654a:	4581                	li	a1,0
    8000654c:	00022517          	auipc	a0,0x22
    80006550:	ab450513          	addi	a0,a0,-1356 # 80028000 <disk>
    80006554:	ffffa097          	auipc	ra,0xffffa
    80006558:	76a080e7          	jalr	1898(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000655c:	00022717          	auipc	a4,0x22
    80006560:	aa470713          	addi	a4,a4,-1372 # 80028000 <disk>
    80006564:	00c75793          	srli	a5,a4,0xc
    80006568:	2781                	sext.w	a5,a5
    8000656a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000656c:	00024797          	auipc	a5,0x24
    80006570:	a9478793          	addi	a5,a5,-1388 # 8002a000 <disk+0x2000>
    80006574:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006576:	00022717          	auipc	a4,0x22
    8000657a:	b0a70713          	addi	a4,a4,-1270 # 80028080 <disk+0x80>
    8000657e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006580:	00023717          	auipc	a4,0x23
    80006584:	a8070713          	addi	a4,a4,-1408 # 80029000 <disk+0x1000>
    80006588:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000658a:	4705                	li	a4,1
    8000658c:	00e78c23          	sb	a4,24(a5)
    80006590:	00e78ca3          	sb	a4,25(a5)
    80006594:	00e78d23          	sb	a4,26(a5)
    80006598:	00e78da3          	sb	a4,27(a5)
    8000659c:	00e78e23          	sb	a4,28(a5)
    800065a0:	00e78ea3          	sb	a4,29(a5)
    800065a4:	00e78f23          	sb	a4,30(a5)
    800065a8:	00e78fa3          	sb	a4,31(a5)
}
    800065ac:	60e2                	ld	ra,24(sp)
    800065ae:	6442                	ld	s0,16(sp)
    800065b0:	64a2                	ld	s1,8(sp)
    800065b2:	6105                	addi	sp,sp,32
    800065b4:	8082                	ret
    panic("could not find virtio disk");
    800065b6:	00002517          	auipc	a0,0x2
    800065ba:	22250513          	addi	a0,a0,546 # 800087d8 <syscalls+0x388>
    800065be:	ffffa097          	auipc	ra,0xffffa
    800065c2:	f6c080e7          	jalr	-148(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    800065c6:	00002517          	auipc	a0,0x2
    800065ca:	23250513          	addi	a0,a0,562 # 800087f8 <syscalls+0x3a8>
    800065ce:	ffffa097          	auipc	ra,0xffffa
    800065d2:	f5c080e7          	jalr	-164(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    800065d6:	00002517          	auipc	a0,0x2
    800065da:	24250513          	addi	a0,a0,578 # 80008818 <syscalls+0x3c8>
    800065de:	ffffa097          	auipc	ra,0xffffa
    800065e2:	f4c080e7          	jalr	-180(ra) # 8000052a <panic>

00000000800065e6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800065e6:	7119                	addi	sp,sp,-128
    800065e8:	fc86                	sd	ra,120(sp)
    800065ea:	f8a2                	sd	s0,112(sp)
    800065ec:	f4a6                	sd	s1,104(sp)
    800065ee:	f0ca                	sd	s2,96(sp)
    800065f0:	ecce                	sd	s3,88(sp)
    800065f2:	e8d2                	sd	s4,80(sp)
    800065f4:	e4d6                	sd	s5,72(sp)
    800065f6:	e0da                	sd	s6,64(sp)
    800065f8:	fc5e                	sd	s7,56(sp)
    800065fa:	f862                	sd	s8,48(sp)
    800065fc:	f466                	sd	s9,40(sp)
    800065fe:	f06a                	sd	s10,32(sp)
    80006600:	ec6e                	sd	s11,24(sp)
    80006602:	0100                	addi	s0,sp,128
    80006604:	8aaa                	mv	s5,a0
    80006606:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006608:	00c52c83          	lw	s9,12(a0)
    8000660c:	001c9c9b          	slliw	s9,s9,0x1
    80006610:	1c82                	slli	s9,s9,0x20
    80006612:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006616:	00024517          	auipc	a0,0x24
    8000661a:	b1250513          	addi	a0,a0,-1262 # 8002a128 <disk+0x2128>
    8000661e:	ffffa097          	auipc	ra,0xffffa
    80006622:	5a4080e7          	jalr	1444(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006626:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006628:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000662a:	00022c17          	auipc	s8,0x22
    8000662e:	9d6c0c13          	addi	s8,s8,-1578 # 80028000 <disk>
    80006632:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006634:	4b0d                	li	s6,3
    80006636:	a0ad                	j	800066a0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006638:	00fc0733          	add	a4,s8,a5
    8000663c:	975e                	add	a4,a4,s7
    8000663e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006642:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006644:	0207c563          	bltz	a5,8000666e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006648:	2905                	addiw	s2,s2,1
    8000664a:	0611                	addi	a2,a2,4
    8000664c:	19690d63          	beq	s2,s6,800067e6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006650:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006652:	00024717          	auipc	a4,0x24
    80006656:	9c670713          	addi	a4,a4,-1594 # 8002a018 <disk+0x2018>
    8000665a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000665c:	00074683          	lbu	a3,0(a4)
    80006660:	fee1                	bnez	a3,80006638 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006662:	2785                	addiw	a5,a5,1
    80006664:	0705                	addi	a4,a4,1
    80006666:	fe979be3          	bne	a5,s1,8000665c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000666a:	57fd                	li	a5,-1
    8000666c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000666e:	01205d63          	blez	s2,80006688 <virtio_disk_rw+0xa2>
    80006672:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006674:	000a2503          	lw	a0,0(s4)
    80006678:	00000097          	auipc	ra,0x0
    8000667c:	d8e080e7          	jalr	-626(ra) # 80006406 <free_desc>
      for(int j = 0; j < i; j++)
    80006680:	2d85                	addiw	s11,s11,1
    80006682:	0a11                	addi	s4,s4,4
    80006684:	ffb918e3          	bne	s2,s11,80006674 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006688:	00024597          	auipc	a1,0x24
    8000668c:	aa058593          	addi	a1,a1,-1376 # 8002a128 <disk+0x2128>
    80006690:	00024517          	auipc	a0,0x24
    80006694:	98850513          	addi	a0,a0,-1656 # 8002a018 <disk+0x2018>
    80006698:	ffffc097          	auipc	ra,0xffffc
    8000669c:	c96080e7          	jalr	-874(ra) # 8000232e <sleep>
  for(int i = 0; i < 3; i++){
    800066a0:	f8040a13          	addi	s4,s0,-128
{
    800066a4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800066a6:	894e                	mv	s2,s3
    800066a8:	b765                	j	80006650 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800066aa:	00024697          	auipc	a3,0x24
    800066ae:	9566b683          	ld	a3,-1706(a3) # 8002a000 <disk+0x2000>
    800066b2:	96ba                	add	a3,a3,a4
    800066b4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800066b8:	00022817          	auipc	a6,0x22
    800066bc:	94880813          	addi	a6,a6,-1720 # 80028000 <disk>
    800066c0:	00024697          	auipc	a3,0x24
    800066c4:	94068693          	addi	a3,a3,-1728 # 8002a000 <disk+0x2000>
    800066c8:	6290                	ld	a2,0(a3)
    800066ca:	963a                	add	a2,a2,a4
    800066cc:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    800066d0:	0015e593          	ori	a1,a1,1
    800066d4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800066d8:	f8842603          	lw	a2,-120(s0)
    800066dc:	628c                	ld	a1,0(a3)
    800066de:	972e                	add	a4,a4,a1
    800066e0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800066e4:	20050593          	addi	a1,a0,512
    800066e8:	0592                	slli	a1,a1,0x4
    800066ea:	95c2                	add	a1,a1,a6
    800066ec:	577d                	li	a4,-1
    800066ee:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800066f2:	00461713          	slli	a4,a2,0x4
    800066f6:	6290                	ld	a2,0(a3)
    800066f8:	963a                	add	a2,a2,a4
    800066fa:	03078793          	addi	a5,a5,48
    800066fe:	97c2                	add	a5,a5,a6
    80006700:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006702:	629c                	ld	a5,0(a3)
    80006704:	97ba                	add	a5,a5,a4
    80006706:	4605                	li	a2,1
    80006708:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000670a:	629c                	ld	a5,0(a3)
    8000670c:	97ba                	add	a5,a5,a4
    8000670e:	4809                	li	a6,2
    80006710:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006714:	629c                	ld	a5,0(a3)
    80006716:	973e                	add	a4,a4,a5
    80006718:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000671c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006720:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006724:	6698                	ld	a4,8(a3)
    80006726:	00275783          	lhu	a5,2(a4)
    8000672a:	8b9d                	andi	a5,a5,7
    8000672c:	0786                	slli	a5,a5,0x1
    8000672e:	97ba                	add	a5,a5,a4
    80006730:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006734:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006738:	6698                	ld	a4,8(a3)
    8000673a:	00275783          	lhu	a5,2(a4)
    8000673e:	2785                	addiw	a5,a5,1
    80006740:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006744:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006748:	100017b7          	lui	a5,0x10001
    8000674c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006750:	004aa783          	lw	a5,4(s5)
    80006754:	02c79163          	bne	a5,a2,80006776 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006758:	00024917          	auipc	s2,0x24
    8000675c:	9d090913          	addi	s2,s2,-1584 # 8002a128 <disk+0x2128>
  while(b->disk == 1) {
    80006760:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006762:	85ca                	mv	a1,s2
    80006764:	8556                	mv	a0,s5
    80006766:	ffffc097          	auipc	ra,0xffffc
    8000676a:	bc8080e7          	jalr	-1080(ra) # 8000232e <sleep>
  while(b->disk == 1) {
    8000676e:	004aa783          	lw	a5,4(s5)
    80006772:	fe9788e3          	beq	a5,s1,80006762 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006776:	f8042903          	lw	s2,-128(s0)
    8000677a:	20090793          	addi	a5,s2,512
    8000677e:	00479713          	slli	a4,a5,0x4
    80006782:	00022797          	auipc	a5,0x22
    80006786:	87e78793          	addi	a5,a5,-1922 # 80028000 <disk>
    8000678a:	97ba                	add	a5,a5,a4
    8000678c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006790:	00024997          	auipc	s3,0x24
    80006794:	87098993          	addi	s3,s3,-1936 # 8002a000 <disk+0x2000>
    80006798:	00491713          	slli	a4,s2,0x4
    8000679c:	0009b783          	ld	a5,0(s3)
    800067a0:	97ba                	add	a5,a5,a4
    800067a2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800067a6:	854a                	mv	a0,s2
    800067a8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800067ac:	00000097          	auipc	ra,0x0
    800067b0:	c5a080e7          	jalr	-934(ra) # 80006406 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800067b4:	8885                	andi	s1,s1,1
    800067b6:	f0ed                	bnez	s1,80006798 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800067b8:	00024517          	auipc	a0,0x24
    800067bc:	97050513          	addi	a0,a0,-1680 # 8002a128 <disk+0x2128>
    800067c0:	ffffa097          	auipc	ra,0xffffa
    800067c4:	4b6080e7          	jalr	1206(ra) # 80000c76 <release>
}
    800067c8:	70e6                	ld	ra,120(sp)
    800067ca:	7446                	ld	s0,112(sp)
    800067cc:	74a6                	ld	s1,104(sp)
    800067ce:	7906                	ld	s2,96(sp)
    800067d0:	69e6                	ld	s3,88(sp)
    800067d2:	6a46                	ld	s4,80(sp)
    800067d4:	6aa6                	ld	s5,72(sp)
    800067d6:	6b06                	ld	s6,64(sp)
    800067d8:	7be2                	ld	s7,56(sp)
    800067da:	7c42                	ld	s8,48(sp)
    800067dc:	7ca2                	ld	s9,40(sp)
    800067de:	7d02                	ld	s10,32(sp)
    800067e0:	6de2                	ld	s11,24(sp)
    800067e2:	6109                	addi	sp,sp,128
    800067e4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800067e6:	f8042503          	lw	a0,-128(s0)
    800067ea:	20050793          	addi	a5,a0,512
    800067ee:	0792                	slli	a5,a5,0x4
  if(write)
    800067f0:	00022817          	auipc	a6,0x22
    800067f4:	81080813          	addi	a6,a6,-2032 # 80028000 <disk>
    800067f8:	00f80733          	add	a4,a6,a5
    800067fc:	01a036b3          	snez	a3,s10
    80006800:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006804:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006808:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000680c:	7679                	lui	a2,0xffffe
    8000680e:	963e                	add	a2,a2,a5
    80006810:	00023697          	auipc	a3,0x23
    80006814:	7f068693          	addi	a3,a3,2032 # 8002a000 <disk+0x2000>
    80006818:	6298                	ld	a4,0(a3)
    8000681a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000681c:	0a878593          	addi	a1,a5,168
    80006820:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006822:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006824:	6298                	ld	a4,0(a3)
    80006826:	9732                	add	a4,a4,a2
    80006828:	45c1                	li	a1,16
    8000682a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000682c:	6298                	ld	a4,0(a3)
    8000682e:	9732                	add	a4,a4,a2
    80006830:	4585                	li	a1,1
    80006832:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006836:	f8442703          	lw	a4,-124(s0)
    8000683a:	628c                	ld	a1,0(a3)
    8000683c:	962e                	add	a2,a2,a1
    8000683e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd300e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006842:	0712                	slli	a4,a4,0x4
    80006844:	6290                	ld	a2,0(a3)
    80006846:	963a                	add	a2,a2,a4
    80006848:	058a8593          	addi	a1,s5,88
    8000684c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000684e:	6294                	ld	a3,0(a3)
    80006850:	96ba                	add	a3,a3,a4
    80006852:	40000613          	li	a2,1024
    80006856:	c690                	sw	a2,8(a3)
  if(write)
    80006858:	e40d19e3          	bnez	s10,800066aa <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000685c:	00023697          	auipc	a3,0x23
    80006860:	7a46b683          	ld	a3,1956(a3) # 8002a000 <disk+0x2000>
    80006864:	96ba                	add	a3,a3,a4
    80006866:	4609                	li	a2,2
    80006868:	00c69623          	sh	a2,12(a3)
    8000686c:	b5b1                	j	800066b8 <virtio_disk_rw+0xd2>

000000008000686e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000686e:	1101                	addi	sp,sp,-32
    80006870:	ec06                	sd	ra,24(sp)
    80006872:	e822                	sd	s0,16(sp)
    80006874:	e426                	sd	s1,8(sp)
    80006876:	e04a                	sd	s2,0(sp)
    80006878:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000687a:	00024517          	auipc	a0,0x24
    8000687e:	8ae50513          	addi	a0,a0,-1874 # 8002a128 <disk+0x2128>
    80006882:	ffffa097          	auipc	ra,0xffffa
    80006886:	340080e7          	jalr	832(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000688a:	10001737          	lui	a4,0x10001
    8000688e:	533c                	lw	a5,96(a4)
    80006890:	8b8d                	andi	a5,a5,3
    80006892:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006894:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006898:	00023797          	auipc	a5,0x23
    8000689c:	76878793          	addi	a5,a5,1896 # 8002a000 <disk+0x2000>
    800068a0:	6b94                	ld	a3,16(a5)
    800068a2:	0207d703          	lhu	a4,32(a5)
    800068a6:	0026d783          	lhu	a5,2(a3)
    800068aa:	06f70163          	beq	a4,a5,8000690c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068ae:	00021917          	auipc	s2,0x21
    800068b2:	75290913          	addi	s2,s2,1874 # 80028000 <disk>
    800068b6:	00023497          	auipc	s1,0x23
    800068ba:	74a48493          	addi	s1,s1,1866 # 8002a000 <disk+0x2000>
    __sync_synchronize();
    800068be:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068c2:	6898                	ld	a4,16(s1)
    800068c4:	0204d783          	lhu	a5,32(s1)
    800068c8:	8b9d                	andi	a5,a5,7
    800068ca:	078e                	slli	a5,a5,0x3
    800068cc:	97ba                	add	a5,a5,a4
    800068ce:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800068d0:	20078713          	addi	a4,a5,512
    800068d4:	0712                	slli	a4,a4,0x4
    800068d6:	974a                	add	a4,a4,s2
    800068d8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800068dc:	e731                	bnez	a4,80006928 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800068de:	20078793          	addi	a5,a5,512
    800068e2:	0792                	slli	a5,a5,0x4
    800068e4:	97ca                	add	a5,a5,s2
    800068e6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800068e8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800068ec:	ffffc097          	auipc	ra,0xffffc
    800068f0:	bce080e7          	jalr	-1074(ra) # 800024ba <wakeup>

    disk.used_idx += 1;
    800068f4:	0204d783          	lhu	a5,32(s1)
    800068f8:	2785                	addiw	a5,a5,1
    800068fa:	17c2                	slli	a5,a5,0x30
    800068fc:	93c1                	srli	a5,a5,0x30
    800068fe:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006902:	6898                	ld	a4,16(s1)
    80006904:	00275703          	lhu	a4,2(a4)
    80006908:	faf71be3          	bne	a4,a5,800068be <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000690c:	00024517          	auipc	a0,0x24
    80006910:	81c50513          	addi	a0,a0,-2020 # 8002a128 <disk+0x2128>
    80006914:	ffffa097          	auipc	ra,0xffffa
    80006918:	362080e7          	jalr	866(ra) # 80000c76 <release>
}
    8000691c:	60e2                	ld	ra,24(sp)
    8000691e:	6442                	ld	s0,16(sp)
    80006920:	64a2                	ld	s1,8(sp)
    80006922:	6902                	ld	s2,0(sp)
    80006924:	6105                	addi	sp,sp,32
    80006926:	8082                	ret
      panic("virtio_disk_intr status");
    80006928:	00002517          	auipc	a0,0x2
    8000692c:	f1050513          	addi	a0,a0,-240 # 80008838 <syscalls+0x3e8>
    80006930:	ffffa097          	auipc	ra,0xffffa
    80006934:	bfa080e7          	jalr	-1030(ra) # 8000052a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
