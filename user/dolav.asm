
user/_dolav:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <child_test>:
#define MEM_SIZE 10000
#define SZ 1200

#define PRINT_TEST_START(TEST_NAME)   printf("\n----------------------\nstarting test - %s\n----------------------\n",TEST_NAME);
#define PRINT_TEST_END(TEST_NAME)   printf("\nfinished test - %s\n----------------------\n",TEST_NAME);
void child_test() {
   0:	711d                	addi	sp,sp,-96
   2:	ec86                	sd	ra,88(sp)
   4:	e8a2                	sd	s0,80(sp)
   6:	e4a6                	sd	s1,72(sp)
   8:	e0ca                	sd	s2,64(sp)
   a:	fc4e                	sd	s3,56(sp)
   c:	f852                	sd	s4,48(sp)
   e:	f456                	sd	s5,40(sp)
  10:	f05a                	sd	s6,32(sp)
  12:	ec5e                	sd	s7,24(sp)
  14:	e862                	sd	s8,16(sp)
  16:	1080                	addi	s0,sp,96
    PRINT_TEST_START("child test");
  18:	00001597          	auipc	a1,0x1
  1c:	f2058593          	addi	a1,a1,-224 # f38 <malloc+0xe6>
  20:	00001517          	auipc	a0,0x1
  24:	f2850513          	addi	a0,a0,-216 # f48 <malloc+0xf6>
  28:	00001097          	auipc	ra,0x1
  2c:	d6c080e7          	jalr	-660(ra) # d94 <printf>
    if (!fork()) {
  30:	00001097          	auipc	ra,0x1
  34:	9e4080e7          	jalr	-1564(ra) # a14 <fork>
  38:	cd15                	beqz	a0,74 <child_test+0x74>
            free(arr[i]);
            printf("arr[%d] avg = %d\n", i, sum);
        }
        exit(0);
    } else {
        wait(0);
  3a:	4501                	li	a0,0
  3c:	00001097          	auipc	ra,0x1
  40:	9e8080e7          	jalr	-1560(ra) # a24 <wait>
    }
    PRINT_TEST_END("child test");
  44:	00001597          	auipc	a1,0x1
  48:	ef458593          	addi	a1,a1,-268 # f38 <malloc+0xe6>
  4c:	00001517          	auipc	a0,0x1
  50:	f5c50513          	addi	a0,a0,-164 # fa8 <malloc+0x156>
  54:	00001097          	auipc	ra,0x1
  58:	d40080e7          	jalr	-704(ra) # d94 <printf>
}
  5c:	60e6                	ld	ra,88(sp)
  5e:	6446                	ld	s0,80(sp)
  60:	64a6                	ld	s1,72(sp)
  62:	6906                	ld	s2,64(sp)
  64:	79e2                	ld	s3,56(sp)
  66:	7a42                	ld	s4,48(sp)
  68:	7aa2                	ld	s5,40(sp)
  6a:	7b02                	ld	s6,32(sp)
  6c:	6be2                	ld	s7,24(sp)
  6e:	6c42                	ld	s8,16(sp)
  70:	6125                	addi	sp,sp,96
  72:	8082                	ret
  74:	84aa                	mv	s1,a0
            arr[i] = (int *) (malloc(MEM_SIZE * sizeof(int)));
  76:	6a29                	lui	s4,0xa
  78:	c40a0513          	addi	a0,s4,-960 # 9c40 <__global_pointer$+0x82af>
  7c:	00001097          	auipc	ra,0x1
  80:	dd6080e7          	jalr	-554(ra) # e52 <malloc>
  84:	892a                	mv	s2,a0
  86:	faa43023          	sd	a0,-96(s0)
            children[i] = fork();
  8a:	00001097          	auipc	ra,0x1
  8e:	98a080e7          	jalr	-1654(ra) # a14 <fork>
  92:	86aa                	mv	a3,a0
        int ind = 0;
  94:	00153993          	seqz	s3,a0
            for (int j = 0; j < MEM_SIZE; ++j) {
  98:	87ca                	mv	a5,s2
  9a:	c40a0713          	addi	a4,s4,-960
  9e:	974a                	add	a4,a4,s2
                arr[i][j] = children[i];
  a0:	c394                	sw	a3,0(a5)
            for (int j = 0; j < MEM_SIZE; ++j) {
  a2:	0791                	addi	a5,a5,4
  a4:	fee79ee3          	bne	a5,a4,a0 <child_test+0xa0>
            arr[i] = (int *) (malloc(MEM_SIZE * sizeof(int)));
  a8:	6529                	lui	a0,0xa
  aa:	c4050513          	addi	a0,a0,-960 # 9c40 <__global_pointer$+0x82af>
  ae:	00001097          	auipc	ra,0x1
  b2:	da4080e7          	jalr	-604(ra) # e52 <malloc>
  b6:	892a                	mv	s2,a0
  b8:	faa43423          	sd	a0,-88(s0)
            children[i] = fork();
  bc:	00001097          	auipc	ra,0x1
  c0:	958080e7          	jalr	-1704(ra) # a14 <fork>
  c4:	86aa                	mv	a3,a0
            ind = children[i] ? ind : i + 1;
  c6:	e111                	bnez	a0,ca <child_test+0xca>
  c8:	4989                	li	s3,2
            for (int j = 0; j < MEM_SIZE; ++j) {
  ca:	87ca                	mv	a5,s2
  cc:	6729                	lui	a4,0xa
  ce:	c4070713          	addi	a4,a4,-960 # 9c40 <__global_pointer$+0x82af>
  d2:	974a                	add	a4,a4,s2
                arr[i][j] = children[i];
  d4:	c394                	sw	a3,0(a5)
            for (int j = 0; j < MEM_SIZE; ++j) {
  d6:	0791                	addi	a5,a5,4
  d8:	fee79ee3          	bne	a5,a4,d4 <child_test+0xd4>
        for (int i = ind; i < CHILD_NUM; ++i) {
  dc:	4785                	li	a5,1
  de:	0137cb63          	blt	a5,s3,f4 <child_test+0xf4>
  e2:	4909                	li	s2,2
            wait(0);
  e4:	4501                	li	a0,0
  e6:	00001097          	auipc	ra,0x1
  ea:	93e080e7          	jalr	-1730(ra) # a24 <wait>
        for (int i = ind; i < CHILD_NUM; ++i) {
  ee:	2985                	addiw	s3,s3,1
  f0:	ff299ae3          	bne	s3,s2,e4 <child_test+0xe4>
        for (int i = 0; i < CHILD_NUM; ++i) {
  f4:	fa040b13          	addi	s6,s0,-96
  f8:	89a6                	mv	s3,s1
  fa:	6aa9                	lui	s5,0xa
  fc:	c40a8a93          	addi	s5,s5,-960 # 9c40 <__global_pointer$+0x82af>
            sum = sum / MEM_SIZE;
 100:	6a09                	lui	s4,0x2
 102:	710a0a1b          	addiw	s4,s4,1808
            printf("arr[%d] avg = %d\n", i, sum);
 106:	00001c17          	auipc	s8,0x1
 10a:	e8ac0c13          	addi	s8,s8,-374 # f90 <malloc+0x13e>
        for (int i = 0; i < CHILD_NUM; ++i) {
 10e:	4b89                	li	s7,2
                sum = sum + arr[i][j];
 110:	000b3503          	ld	a0,0(s6)
 114:	87aa                	mv	a5,a0
 116:	015506b3          	add	a3,a0,s5
            int sum = 0;
 11a:	8926                	mv	s2,s1
                sum = sum + arr[i][j];
 11c:	4398                	lw	a4,0(a5)
 11e:	0127093b          	addw	s2,a4,s2
            for (int j = 0; j < MEM_SIZE; ++j) {
 122:	0791                	addi	a5,a5,4
 124:	fed79ce3          	bne	a5,a3,11c <child_test+0x11c>
            free(arr[i]);
 128:	00001097          	auipc	ra,0x1
 12c:	ca2080e7          	jalr	-862(ra) # dca <free>
            printf("arr[%d] avg = %d\n", i, sum);
 130:	0349463b          	divw	a2,s2,s4
 134:	85ce                	mv	a1,s3
 136:	8562                	mv	a0,s8
 138:	00001097          	auipc	ra,0x1
 13c:	c5c080e7          	jalr	-932(ra) # d94 <printf>
        for (int i = 0; i < CHILD_NUM; ++i) {
 140:	2985                	addiw	s3,s3,1
 142:	0b21                	addi	s6,s6,8
 144:	fd7996e3          	bne	s3,s7,110 <child_test+0x110>
        exit(0);
 148:	4501                	li	a0,0
 14a:	00001097          	auipc	ra,0x1
 14e:	8d2080e7          	jalr	-1838(ra) # a1c <exit>

0000000000000152 <alloc_dealloc_test>:
void alloc_dealloc_test() {
 152:	7139                	addi	sp,sp,-64
 154:	fc06                	sd	ra,56(sp)
 156:	f822                	sd	s0,48(sp)
 158:	f426                	sd	s1,40(sp)
 15a:	f04a                	sd	s2,32(sp)
 15c:	ec4e                	sd	s3,24(sp)
 15e:	e852                	sd	s4,16(sp)
 160:	e456                	sd	s5,8(sp)
 162:	0080                	addi	s0,sp,64
    PRINT_TEST_START("alloc dealloc test");
 164:	00001597          	auipc	a1,0x1
 168:	e7458593          	addi	a1,a1,-396 # fd8 <malloc+0x186>
 16c:	00001517          	auipc	a0,0x1
 170:	ddc50513          	addi	a0,a0,-548 # f48 <malloc+0xf6>
 174:	00001097          	auipc	ra,0x1
 178:	c20080e7          	jalr	-992(ra) # d94 <printf>
    printf("alloc dealloc test\n");
 17c:	00001517          	auipc	a0,0x1
 180:	e7450513          	addi	a0,a0,-396 # ff0 <malloc+0x19e>
 184:	00001097          	auipc	ra,0x1
 188:	c10080e7          	jalr	-1008(ra) # d94 <printf>
    if (!fork()) {
 18c:	00001097          	auipc	ra,0x1
 190:	888080e7          	jalr	-1912(ra) # a14 <fork>
 194:	c91d                	beqz	a0,1ca <alloc_dealloc_test+0x78>
            }
        }
        sbrk(-PGSIZE * 20);
        exit(0);
    } else {
        wait(0);
 196:	4501                	li	a0,0
 198:	00001097          	auipc	ra,0x1
 19c:	88c080e7          	jalr	-1908(ra) # a24 <wait>
    }
    PRINT_TEST_END("alloc dealloc test");
 1a0:	00001597          	auipc	a1,0x1
 1a4:	e3858593          	addi	a1,a1,-456 # fd8 <malloc+0x186>
 1a8:	00001517          	auipc	a0,0x1
 1ac:	e0050513          	addi	a0,a0,-512 # fa8 <malloc+0x156>
 1b0:	00001097          	auipc	ra,0x1
 1b4:	be4080e7          	jalr	-1052(ra) # d94 <printf>
}
 1b8:	70e2                	ld	ra,56(sp)
 1ba:	7442                	ld	s0,48(sp)
 1bc:	74a2                	ld	s1,40(sp)
 1be:	7902                	ld	s2,32(sp)
 1c0:	69e2                	ld	s3,24(sp)
 1c2:	6a42                	ld	s4,16(sp)
 1c4:	6aa2                	ld	s5,8(sp)
 1c6:	6121                	addi	sp,sp,64
 1c8:	8082                	ret
 1ca:	84aa                	mv	s1,a0
        int *arr = (int *) (sbrk(PGSIZE * 20));
 1cc:	6551                	lui	a0,0x14
 1ce:	00001097          	auipc	ra,0x1
 1d2:	8d6080e7          	jalr	-1834(ra) # aa4 <sbrk>
 1d6:	87aa                	mv	a5,a0
        for (int i = 0; i < PGSIZE * 20 / sizeof(int); ++i) { arr[i] = 0; }
 1d8:	6751                	lui	a4,0x14
 1da:	972a                	add	a4,a4,a0
 1dc:	0007a023          	sw	zero,0(a5)
 1e0:	0791                	addi	a5,a5,4
 1e2:	fee79de3          	bne	a5,a4,1dc <alloc_dealloc_test+0x8a>
        sbrk(-PGSIZE * 20);
 1e6:	7531                	lui	a0,0xfffec
 1e8:	00001097          	auipc	ra,0x1
 1ec:	8bc080e7          	jalr	-1860(ra) # aa4 <sbrk>
        printf("dealloc complete\n");
 1f0:	00001517          	auipc	a0,0x1
 1f4:	e1850513          	addi	a0,a0,-488 # 1008 <malloc+0x1b6>
 1f8:	00001097          	auipc	ra,0x1
 1fc:	b9c080e7          	jalr	-1124(ra) # d94 <printf>
        arr = (int *) (sbrk(PGSIZE * 20));
 200:	6551                	lui	a0,0x14
 202:	00001097          	auipc	ra,0x1
 206:	8a2080e7          	jalr	-1886(ra) # aa4 <sbrk>
 20a:	892a                	mv	s2,a0
        for (int i = 0; i < PGSIZE * 20 / sizeof(int); ++i) { arr[i] = 2; }
 20c:	6751                	lui	a4,0x14
 20e:	972a                	add	a4,a4,a0
        arr = (int *) (sbrk(PGSIZE * 20));
 210:	87aa                	mv	a5,a0
        for (int i = 0; i < PGSIZE * 20 / sizeof(int); ++i) { arr[i] = 2; }
 212:	4689                	li	a3,2
 214:	c394                	sw	a3,0(a5)
 216:	0791                	addi	a5,a5,4
 218:	fef71ee3          	bne	a4,a5,214 <alloc_dealloc_test+0xc2>
            if (i % PGSIZE == 0) {
 21c:	6985                	lui	s3,0x1
 21e:	19fd                	addi	s3,s3,-1
                printf("arr[%d]=%d\n", i, arr[i]);
 220:	00001a97          	auipc	s5,0x1
 224:	e00a8a93          	addi	s5,s5,-512 # 1020 <malloc+0x1ce>
        for (int i = 0; i < PGSIZE * 20 / sizeof(int); ++i) {
 228:	6a15                	lui	s4,0x5
 22a:	a029                	j	234 <alloc_dealloc_test+0xe2>
 22c:	2485                	addiw	s1,s1,1
 22e:	0911                	addi	s2,s2,4
 230:	01448f63          	beq	s1,s4,24e <alloc_dealloc_test+0xfc>
            if (i % PGSIZE == 0) {
 234:	0134f7b3          	and	a5,s1,s3
 238:	2781                	sext.w	a5,a5
 23a:	fbed                	bnez	a5,22c <alloc_dealloc_test+0xda>
                printf("arr[%d]=%d\n", i, arr[i]);
 23c:	00092603          	lw	a2,0(s2)
 240:	85a6                	mv	a1,s1
 242:	8556                	mv	a0,s5
 244:	00001097          	auipc	ra,0x1
 248:	b50080e7          	jalr	-1200(ra) # d94 <printf>
 24c:	b7c5                	j	22c <alloc_dealloc_test+0xda>
        sbrk(-PGSIZE * 20);
 24e:	7531                	lui	a0,0xfffec
 250:	00001097          	auipc	ra,0x1
 254:	854080e7          	jalr	-1964(ra) # aa4 <sbrk>
        exit(0);
 258:	4501                	li	a0,0
 25a:	00000097          	auipc	ra,0x0
 25e:	7c2080e7          	jalr	1986(ra) # a1c <exit>

0000000000000262 <advance_alloc_dealloc_test>:

void advance_alloc_dealloc_test() {
 262:	7139                	addi	sp,sp,-64
 264:	fc06                	sd	ra,56(sp)
 266:	f822                	sd	s0,48(sp)
 268:	f426                	sd	s1,40(sp)
 26a:	f04a                	sd	s2,32(sp)
 26c:	ec4e                	sd	s3,24(sp)
 26e:	e852                	sd	s4,16(sp)
 270:	e456                	sd	s5,8(sp)
 272:	e05a                	sd	s6,0(sp)
 274:	0080                	addi	s0,sp,64
    PRINT_TEST_START("advanced alloc dealloc test");
 276:	00001597          	auipc	a1,0x1
 27a:	dba58593          	addi	a1,a1,-582 # 1030 <malloc+0x1de>
 27e:	00001517          	auipc	a0,0x1
 282:	cca50513          	addi	a0,a0,-822 # f48 <malloc+0xf6>
 286:	00001097          	auipc	ra,0x1
 28a:	b0e080e7          	jalr	-1266(ra) # d94 <printf>
    if (!fork()) {
 28e:	00000097          	auipc	ra,0x0
 292:	786080e7          	jalr	1926(ra) # a14 <fork>
 296:	10051f63          	bnez	a0,3b4 <advance_alloc_dealloc_test+0x152>
 29a:	89aa                	mv	s3,a0
        int *arr = (int *) (sbrk(PGSIZE * 20));
 29c:	6551                	lui	a0,0x14
 29e:	00001097          	auipc	ra,0x1
 2a2:	806080e7          	jalr	-2042(ra) # aa4 <sbrk>
 2a6:	84aa                	mv	s1,a0
        for (int i = 0; i < PGSIZE * 20 / sizeof(int); ++i) { arr[i] = 0; }
 2a8:	6951                	lui	s2,0x14
 2aa:	992a                	add	s2,s2,a0
        int *arr = (int *) (sbrk(PGSIZE * 20));
 2ac:	87aa                	mv	a5,a0
        for (int i = 0; i < PGSIZE * 20 / sizeof(int); ++i) { arr[i] = 0; }
 2ae:	0007a023          	sw	zero,0(a5)
 2b2:	0791                	addi	a5,a5,4
 2b4:	ff279de3          	bne	a5,s2,2ae <advance_alloc_dealloc_test+0x4c>
        int pid = fork();
 2b8:	00000097          	auipc	ra,0x0
 2bc:	75c080e7          	jalr	1884(ra) # a14 <fork>
        if (!pid) {
 2c0:	e921                	bnez	a0,310 <advance_alloc_dealloc_test+0xae>
            sbrk(-PGSIZE * 20);
 2c2:	7531                	lui	a0,0xfffec
 2c4:	00000097          	auipc	ra,0x0
 2c8:	7e0080e7          	jalr	2016(ra) # aa4 <sbrk>
            printf("dealloc complete\n");
 2cc:	00001517          	auipc	a0,0x1
 2d0:	d3c50513          	addi	a0,a0,-708 # 1008 <malloc+0x1b6>
 2d4:	00001097          	auipc	ra,0x1
 2d8:	ac0080e7          	jalr	-1344(ra) # d94 <printf>
            printf("should cause segmentation fault\n");
 2dc:	00001517          	auipc	a0,0x1
 2e0:	d7450513          	addi	a0,a0,-652 # 1050 <malloc+0x1fe>
 2e4:	00001097          	auipc	ra,0x1
 2e8:	ab0080e7          	jalr	-1360(ra) # d94 <printf>
            for (int i = 0; i < PGSIZE * 20 / sizeof(int); ++i) {
                arr[i] = 1;
 2ec:	4785                	li	a5,1
 2ee:	c09c                	sw	a5,0(s1)
            for (int i = 0; i < PGSIZE * 20 / sizeof(int); ++i) {
 2f0:	0491                	addi	s1,s1,4
 2f2:	ff249ee3          	bne	s1,s2,2ee <advance_alloc_dealloc_test+0x8c>
            }
            printf("test failed\n");
 2f6:	00001517          	auipc	a0,0x1
 2fa:	d8250513          	addi	a0,a0,-638 # 1078 <malloc+0x226>
 2fe:	00001097          	auipc	ra,0x1
 302:	a96080e7          	jalr	-1386(ra) # d94 <printf>
            exit(0);
 306:	4501                	li	a0,0
 308:	00000097          	auipc	ra,0x0
 30c:	714080e7          	jalr	1812(ra) # a1c <exit>
        }
        wait(0);
 310:	4501                	li	a0,0
 312:	00000097          	auipc	ra,0x0
 316:	712080e7          	jalr	1810(ra) # a24 <wait>
 31a:	6795                	lui	a5,0x5
        int sum = 0;
        for (int i = 0; i < PGSIZE * 20 / sizeof(int); ++i) { sum = sum + arr[i]; }
 31c:	37fd                	addiw	a5,a5,-1
 31e:	fffd                	bnez	a5,31c <advance_alloc_dealloc_test+0xba>
        sbrk(-PGSIZE * 20);
 320:	7531                	lui	a0,0xfffec
 322:	00000097          	auipc	ra,0x0
 326:	782080e7          	jalr	1922(ra) # aa4 <sbrk>
        int father = 1;
        char *bytes;
        char *origStart = sbrk(0);
 32a:	4501                	li	a0,0
 32c:	00000097          	auipc	ra,0x0
 330:	778080e7          	jalr	1912(ra) # aa4 <sbrk>
 334:	8aaa                	mv	s5,a0
        int count = 0;
        int max_size = 0;
 336:	894e                	mv	s2,s3
        for (int i = 0; i < 20; ++i) {
            father = father && fork() > 0;
            if (!father) { break; }
            if (father) {
                bytes = (char *) (sbrk(PGSIZE));
                max_size = max_size + PGSIZE;
 338:	6b05                	lui	s6,0x1
                for (int i = 0; i < PGSIZE; ++i) { bytes[i] = 1; }
 33a:	4485                	li	s1,1
        for (int i = 0; i < 20; ++i) {
 33c:	6a51                	lui	s4,0x14
            father = father && fork() > 0;
 33e:	00000097          	auipc	ra,0x0
 342:	6d6080e7          	jalr	1750(ra) # a14 <fork>
 346:	0aa05263          	blez	a0,3ea <advance_alloc_dealloc_test+0x188>
                bytes = (char *) (sbrk(PGSIZE));
 34a:	6505                	lui	a0,0x1
 34c:	00000097          	auipc	ra,0x0
 350:	758080e7          	jalr	1880(ra) # aa4 <sbrk>
                max_size = max_size + PGSIZE;
 354:	012b093b          	addw	s2,s6,s2
                for (int i = 0; i < PGSIZE; ++i) { bytes[i] = 1; }
 358:	87aa                	mv	a5,a0
 35a:	6705                	lui	a4,0x1
 35c:	972a                	add	a4,a4,a0
 35e:	00978023          	sb	s1,0(a5) # 5000 <__global_pointer$+0x366f>
 362:	0785                	addi	a5,a5,1
 364:	fef71de3          	bne	a4,a5,35e <advance_alloc_dealloc_test+0xfc>
        for (int i = 0; i < 20; ++i) {
 368:	fd491be3          	bne	s2,s4,33e <advance_alloc_dealloc_test+0xdc>
 36c:	4485                	li	s1,1
            father = father && fork() > 0;
 36e:	4781                	li	a5,0
            }
        }
        for (int i = 0; i < max_size; ++i) {
            count = count + origStart[i];
 370:	00fa8733          	add	a4,s5,a5
 374:	00074703          	lbu	a4,0(a4) # 1000 <malloc+0x1ae>
 378:	013709bb          	addw	s3,a4,s3
        for (int i = 0; i < max_size; ++i) {
 37c:	0785                	addi	a5,a5,1
 37e:	0007871b          	sext.w	a4,a5
 382:	ff2747e3          	blt	a4,s2,370 <advance_alloc_dealloc_test+0x10e>
        }
        printf("count:%d\n", count);
 386:	85ce                	mv	a1,s3
 388:	00001517          	auipc	a0,0x1
 38c:	d0050513          	addi	a0,a0,-768 # 1088 <malloc+0x236>
 390:	00001097          	auipc	ra,0x1
 394:	a04080e7          	jalr	-1532(ra) # d94 <printf>
        if (father) {
 398:	c889                	beqz	s1,3aa <advance_alloc_dealloc_test+0x148>
 39a:	44d1                	li	s1,20
            for (int i = 0; i < 20; ++i) { wait(0); }
 39c:	4501                	li	a0,0
 39e:	00000097          	auipc	ra,0x0
 3a2:	686080e7          	jalr	1670(ra) # a24 <wait>
 3a6:	34fd                	addiw	s1,s1,-1
 3a8:	f8f5                	bnez	s1,39c <advance_alloc_dealloc_test+0x13a>
        }
        exit(0);
 3aa:	4501                	li	a0,0
 3ac:	00000097          	auipc	ra,0x0
 3b0:	670080e7          	jalr	1648(ra) # a1c <exit>
    } else {
        wait(0);
 3b4:	4501                	li	a0,0
 3b6:	00000097          	auipc	ra,0x0
 3ba:	66e080e7          	jalr	1646(ra) # a24 <wait>
    }
    PRINT_TEST_END("advanced alloc dealloc test");
 3be:	00001597          	auipc	a1,0x1
 3c2:	c7258593          	addi	a1,a1,-910 # 1030 <malloc+0x1de>
 3c6:	00001517          	auipc	a0,0x1
 3ca:	be250513          	addi	a0,a0,-1054 # fa8 <malloc+0x156>
 3ce:	00001097          	auipc	ra,0x1
 3d2:	9c6080e7          	jalr	-1594(ra) # d94 <printf>
}
 3d6:	70e2                	ld	ra,56(sp)
 3d8:	7442                	ld	s0,48(sp)
 3da:	74a2                	ld	s1,40(sp)
 3dc:	7902                	ld	s2,32(sp)
 3de:	69e2                	ld	s3,24(sp)
 3e0:	6a42                	ld	s4,16(sp)
 3e2:	6aa2                	ld	s5,8(sp)
 3e4:	6b02                	ld	s6,0(sp)
 3e6:	6121                	addi	sp,sp,64
 3e8:	8082                	ret
            father = father && fork() > 0;
 3ea:	84ce                	mv	s1,s3
        for (int i = 0; i < max_size; ++i) {
 3ec:	f92041e3          	bgtz	s2,36e <advance_alloc_dealloc_test+0x10c>
        printf("count:%d\n", count);
 3f0:	4581                	li	a1,0
 3f2:	00001517          	auipc	a0,0x1
 3f6:	c9650513          	addi	a0,a0,-874 # 1088 <malloc+0x236>
 3fa:	00001097          	auipc	ra,0x1
 3fe:	99a080e7          	jalr	-1638(ra) # d94 <printf>
        if (father) {
 402:	b765                	j	3aa <advance_alloc_dealloc_test+0x148>

0000000000000404 <exec_test>:
void exec_test() {
 404:	7179                	addi	sp,sp,-48
 406:	f406                	sd	ra,40(sp)
 408:	f022                	sd	s0,32(sp)
 40a:	1800                	addi	s0,sp,48
    PRINT_TEST_START("exec test");
 40c:	00001597          	auipc	a1,0x1
 410:	c8c58593          	addi	a1,a1,-884 # 1098 <malloc+0x246>
 414:	00001517          	auipc	a0,0x1
 418:	b3450513          	addi	a0,a0,-1228 # f48 <malloc+0xf6>
 41c:	00001097          	auipc	ra,0x1
 420:	978080e7          	jalr	-1672(ra) # d94 <printf>
    if (!fork()) {
 424:	00000097          	auipc	ra,0x0
 428:	5f0080e7          	jalr	1520(ra) # a14 <fork>
 42c:	c515                	beqz	a0,458 <exec_test+0x54>
        } else {
            wait(0);
        }
        exit(0);
    } else {
        wait(0);
 42e:	4501                	li	a0,0
 430:	00000097          	auipc	ra,0x0
 434:	5f4080e7          	jalr	1524(ra) # a24 <wait>
    }
    PRINT_TEST_END("exec test");
 438:	00001597          	auipc	a1,0x1
 43c:	c6058593          	addi	a1,a1,-928 # 1098 <malloc+0x246>
 440:	00001517          	auipc	a0,0x1
 444:	b6850513          	addi	a0,a0,-1176 # fa8 <malloc+0x156>
 448:	00001097          	auipc	ra,0x1
 44c:	94c080e7          	jalr	-1716(ra) # d94 <printf>
}
 450:	70a2                	ld	ra,40(sp)
 452:	7402                	ld	s0,32(sp)
 454:	6145                	addi	sp,sp,48
 456:	8082                	ret
        printf("allocating pages\n");
 458:	00001517          	auipc	a0,0x1
 45c:	c5050513          	addi	a0,a0,-944 # 10a8 <malloc+0x256>
 460:	00001097          	auipc	ra,0x1
 464:	934080e7          	jalr	-1740(ra) # d94 <printf>
        int *arr = (int *) (malloc(sizeof(int) * 5 * PGSIZE));
 468:	6551                	lui	a0,0x14
 46a:	00001097          	auipc	ra,0x1
 46e:	9e8080e7          	jalr	-1560(ra) # e52 <malloc>
            arr[i] = i / PGSIZE;
 472:	00052023          	sw	zero,0(a0) # 14000 <__global_pointer$+0x1266f>
 476:	6711                	lui	a4,0x4
 478:	972a                	add	a4,a4,a0
 47a:	4685                	li	a3,1
 47c:	c314                	sw	a3,0(a4)
 47e:	6721                	lui	a4,0x8
 480:	972a                	add	a4,a4,a0
 482:	4689                	li	a3,2
 484:	c314                	sw	a3,0(a4)
 486:	6731                	lui	a4,0xc
 488:	972a                	add	a4,a4,a0
 48a:	468d                	li	a3,3
 48c:	c314                	sw	a3,0(a4)
 48e:	6741                	lui	a4,0x10
 490:	00e507b3          	add	a5,a0,a4
 494:	4711                	li	a4,4
 496:	c398                	sw	a4,0(a5)
         printf("forking\n");
 498:	00001517          	auipc	a0,0x1
 49c:	c2850513          	addi	a0,a0,-984 # 10c0 <malloc+0x26e>
 4a0:	00001097          	auipc	ra,0x1
 4a4:	8f4080e7          	jalr	-1804(ra) # d94 <printf>
        int pid = fork();
 4a8:	00000097          	auipc	ra,0x0
 4ac:	56c080e7          	jalr	1388(ra) # a14 <fork>
        if (!pid) {
 4b0:	e915                	bnez	a0,4e4 <exec_test+0xe0>
            char *argv[] = {"myMemTest", "exectest", 0};
 4b2:	00001517          	auipc	a0,0x1
 4b6:	c1e50513          	addi	a0,a0,-994 # 10d0 <malloc+0x27e>
 4ba:	fca43c23          	sd	a0,-40(s0)
 4be:	00001797          	auipc	a5,0x1
 4c2:	c2278793          	addi	a5,a5,-990 # 10e0 <malloc+0x28e>
 4c6:	fef43023          	sd	a5,-32(s0)
 4ca:	fe043423          	sd	zero,-24(s0)
            exec(argv[0], argv);
 4ce:	fd840593          	addi	a1,s0,-40
 4d2:	00000097          	auipc	ra,0x0
 4d6:	582080e7          	jalr	1410(ra) # a54 <exec>
        exit(0);
 4da:	4501                	li	a0,0
 4dc:	00000097          	auipc	ra,0x0
 4e0:	540080e7          	jalr	1344(ra) # a1c <exit>
            wait(0);
 4e4:	4501                	li	a0,0
 4e6:	00000097          	auipc	ra,0x0
 4ea:	53e080e7          	jalr	1342(ra) # a24 <wait>
 4ee:	b7f5                	j	4da <exec_test+0xd6>

00000000000004f0 <exec_test_child>:
void exec_test_child() {
 4f0:	1141                	addi	sp,sp,-16
 4f2:	e406                	sd	ra,8(sp)
 4f4:	e022                	sd	s0,0(sp)
 4f6:	0800                	addi	s0,sp,16
    printf("child allocating pages\n");
 4f8:	00001517          	auipc	a0,0x1
 4fc:	bf850513          	addi	a0,a0,-1032 # 10f0 <malloc+0x29e>
 500:	00001097          	auipc	ra,0x1
 504:	894080e7          	jalr	-1900(ra) # d94 <printf>
    int *arr = (int *) (malloc(sizeof(int) * 5 * PGSIZE));
 508:	6551                	lui	a0,0x14
 50a:	00001097          	auipc	ra,0x1
 50e:	948080e7          	jalr	-1720(ra) # e52 <malloc>
    for (int i = 0; i < 5 * PGSIZE; i = i + PGSIZE) {
        arr[i] = i / PGSIZE;
 512:	00052023          	sw	zero,0(a0) # 14000 <__global_pointer$+0x1266f>
 516:	6791                	lui	a5,0x4
 518:	97aa                	add	a5,a5,a0
 51a:	4705                	li	a4,1
 51c:	c398                	sw	a4,0(a5)
 51e:	67a1                	lui	a5,0x8
 520:	97aa                	add	a5,a5,a0
 522:	4709                	li	a4,2
 524:	c398                	sw	a4,0(a5)
 526:	67b1                	lui	a5,0xc
 528:	97aa                	add	a5,a5,a0
 52a:	470d                	li	a4,3
 52c:	c398                	sw	a4,0(a5)
 52e:	67c1                	lui	a5,0x10
 530:	953e                	add	a0,a0,a5
 532:	4791                	li	a5,4
 534:	c11c                	sw	a5,0(a0)
    }
    printf("child exiting\n");
 536:	00001517          	auipc	a0,0x1
 53a:	bd250513          	addi	a0,a0,-1070 # 1108 <malloc+0x2b6>
 53e:	00001097          	auipc	ra,0x1
 542:	856080e7          	jalr	-1962(ra) # d94 <printf>
}
 546:	60a2                	ld	ra,8(sp)
 548:	6402                	ld	s0,0(sp)
 54a:	0141                	addi	sp,sp,16
 54c:	8082                	ret

000000000000054e <priority_test>:
void priority_test() {
 54e:	715d                	addi	sp,sp,-80
 550:	e486                	sd	ra,72(sp)
 552:	e0a2                	sd	s0,64(sp)
 554:	fc26                	sd	s1,56(sp)
 556:	f84a                	sd	s2,48(sp)
 558:	f44e                	sd	s3,40(sp)
 55a:	f052                	sd	s4,32(sp)
 55c:	ec56                	sd	s5,24(sp)
 55e:	e85a                	sd	s6,16(sp)
 560:	e45e                	sd	s7,8(sp)
 562:	e062                	sd	s8,0(sp)
 564:	0880                	addi	s0,sp,80
    PRINT_TEST_START("priority test");
 566:	00001597          	auipc	a1,0x1
 56a:	bb258593          	addi	a1,a1,-1102 # 1118 <malloc+0x2c6>
 56e:	00001517          	auipc	a0,0x1
 572:	9da50513          	addi	a0,a0,-1574 # f48 <malloc+0xf6>
 576:	00001097          	auipc	ra,0x1
 57a:	81e080e7          	jalr	-2018(ra) # d94 <printf>
    if (!fork()) {
 57e:	00000097          	auipc	ra,0x0
 582:	496080e7          	jalr	1174(ra) # a14 <fork>
 586:	cd15                	beqz	a0,5c2 <priority_test+0x74>
            }
            printf("sum %d = %d\n", i, sum);
        }
        exit(0);
    } else {
        wait(0);
 588:	4501                	li	a0,0
 58a:	00000097          	auipc	ra,0x0
 58e:	49a080e7          	jalr	1178(ra) # a24 <wait>
    }
    PRINT_TEST_END("priority test");
 592:	00001597          	auipc	a1,0x1
 596:	b8658593          	addi	a1,a1,-1146 # 1118 <malloc+0x2c6>
 59a:	00001517          	auipc	a0,0x1
 59e:	a0e50513          	addi	a0,a0,-1522 # fa8 <malloc+0x156>
 5a2:	00000097          	auipc	ra,0x0
 5a6:	7f2080e7          	jalr	2034(ra) # d94 <printf>
}
 5aa:	60a6                	ld	ra,72(sp)
 5ac:	6406                	ld	s0,64(sp)
 5ae:	74e2                	ld	s1,56(sp)
 5b0:	7942                	ld	s2,48(sp)
 5b2:	79a2                	ld	s3,40(sp)
 5b4:	7a02                	ld	s4,32(sp)
 5b6:	6ae2                	ld	s5,24(sp)
 5b8:	6b42                	ld	s6,16(sp)
 5ba:	6ba2                	ld	s7,8(sp)
 5bc:	6c02                	ld	s8,0(sp)
 5be:	6161                	addi	sp,sp,80
 5c0:	8082                	ret
 5c2:	84aa                	mv	s1,a0
        int *arr = (int *) (malloc(sizeof(int) * PGSIZE * 6));
 5c4:	6561                	lui	a0,0x18
 5c6:	00001097          	auipc	ra,0x1
 5ca:	88c080e7          	jalr	-1908(ra) # e52 <malloc>
 5ce:	89aa                	mv	s3,a0
        for (int i = 0; i < PGSIZE / sizeof(int); ++i) {
 5d0:	8926                	mv	s2,s1
        int *arr = (int *) (malloc(sizeof(int) * PGSIZE * 6));
 5d2:	4a05                	li	s4,1
            int accessed_index = i + ((i % 2 == 0) ? 0 : i % (6 * sizeof(int))) * (PGSIZE / sizeof(int));
 5d4:	4781                	li	a5,0
            arr[accessed_index] = 1;
 5d6:	4a85                	li	s5,1
               if (i % 10 == 0) { sleep(1); }
 5d8:	4ba9                	li	s7,10
        for (int i = 0; i < PGSIZE / sizeof(int); ++i) {
 5da:	40000b13          	li	s6,1024
            int accessed_index = i + ((i % 2 == 0) ? 0 : i % (6 * sizeof(int))) * (PGSIZE / sizeof(int));
 5de:	4c61                	li	s8,24
 5e0:	a011                	j	5e4 <priority_test+0x96>
 5e2:	0a05                	addi	s4,s4,1
            arr[accessed_index] = 1;
 5e4:	00f907bb          	addw	a5,s2,a5
 5e8:	078a                	slli	a5,a5,0x2
 5ea:	97ce                	add	a5,a5,s3
 5ec:	0157a023          	sw	s5,0(a5) # 10000 <__global_pointer$+0xe66f>
               if (i % 10 == 0) { sleep(1); }
 5f0:	037967bb          	remw	a5,s2,s7
 5f4:	cf91                	beqz	a5,610 <priority_test+0xc2>
        for (int i = 0; i < PGSIZE / sizeof(int); ++i) {
 5f6:	0019079b          	addiw	a5,s2,1
 5fa:	0007891b          	sext.w	s2,a5
 5fe:	87ca                	mv	a5,s2
 600:	01690e63          	beq	s2,s6,61c <priority_test+0xce>
            int accessed_index = i + ((i % 2 == 0) ? 0 : i % (6 * sizeof(int))) * (PGSIZE / sizeof(int));
 604:	8b85                	andi	a5,a5,1
 606:	dff1                	beqz	a5,5e2 <priority_test+0x94>
 608:	038a77b3          	remu	a5,s4,s8
 60c:	07aa                	slli	a5,a5,0xa
 60e:	bfd1                	j	5e2 <priority_test+0x94>
               if (i % 10 == 0) { sleep(1); }
 610:	8556                	mv	a0,s5
 612:	00000097          	auipc	ra,0x0
 616:	49a080e7          	jalr	1178(ra) # aac <sleep>
 61a:	bff1                	j	5f6 <priority_test+0xa8>
 61c:	4901                	li	s2,0
 61e:	6a05                	lui	s4,0x1
 620:	9a4e                	add	s4,s4,s3
            printf("sum %d = %d\n", i, sum);
 622:	00001b17          	auipc	s6,0x1
 626:	b06b0b13          	addi	s6,s6,-1274 # 1128 <malloc+0x2d6>
        for (int i = 0; i < 6 * sizeof(int); ++i) {
 62a:	4ae1                	li	s5,24
 62c:	0009059b          	sext.w	a1,s2
            for (int j = 0; j < PGSIZE / sizeof(int); ++j) {
 630:	00c91693          	slli	a3,s2,0xc
 634:	00d987b3          	add	a5,s3,a3
 638:	96d2                	add	a3,a3,s4
            int sum = 0;
 63a:	8626                	mv	a2,s1
                sum = sum + arr[i * PGSIZE / sizeof(int) + j];
 63c:	4398                	lw	a4,0(a5)
 63e:	9e39                	addw	a2,a2,a4
            for (int j = 0; j < PGSIZE / sizeof(int); ++j) {
 640:	0791                	addi	a5,a5,4
 642:	fef69de3          	bne	a3,a5,63c <priority_test+0xee>
            printf("sum %d = %d\n", i, sum);
 646:	855a                	mv	a0,s6
 648:	00000097          	auipc	ra,0x0
 64c:	74c080e7          	jalr	1868(ra) # d94 <printf>
        for (int i = 0; i < 6 * sizeof(int); ++i) {
 650:	0905                	addi	s2,s2,1
 652:	fd591de3          	bne	s2,s5,62c <priority_test+0xde>
        exit(0);
 656:	4501                	li	a0,0
 658:	00000097          	auipc	ra,0x0
 65c:	3c4080e7          	jalr	964(ra) # a1c <exit>

0000000000000660 <fork_test>:

void fork_test() {
 660:	7179                	addi	sp,sp,-48
 662:	f406                	sd	ra,40(sp)
 664:	f022                	sd	s0,32(sp)
 666:	ec26                	sd	s1,24(sp)
 668:	e84a                	sd	s2,16(sp)
 66a:	e44e                	sd	s3,8(sp)
 66c:	1800                	addi	s0,sp,48
    PRINT_TEST_START("fork test");
 66e:	00001597          	auipc	a1,0x1
 672:	aca58593          	addi	a1,a1,-1334 # 1138 <malloc+0x2e6>
 676:	00001517          	auipc	a0,0x1
 67a:	8d250513          	addi	a0,a0,-1838 # f48 <malloc+0xf6>
 67e:	00000097          	auipc	ra,0x0
 682:	716080e7          	jalr	1814(ra) # d94 <printf>
    if (!fork()) {
 686:	00000097          	auipc	ra,0x0
 68a:	38e080e7          	jalr	910(ra) # a14 <fork>
 68e:	e54d                	bnez	a0,738 <fork_test+0xd8>
        char *arr = (char *) (malloc(sizeof(char) * PGSIZE * 24));
 690:	6561                	lui	a0,0x18
 692:	00000097          	auipc	ra,0x0
 696:	7c0080e7          	jalr	1984(ra) # e52 <malloc>
 69a:	892a                	mv	s2,a0
        for (int i = PGSIZE * 1; i < PGSIZE * 2; ++i) {
 69c:	6985                	lui	s3,0x1
 69e:	99aa                	add	s3,s3,a0
 6a0:	6489                	lui	s1,0x2
 6a2:	94aa                	add	s1,s1,a0
        char *arr = (char *) (malloc(sizeof(char) * PGSIZE * 24));
 6a4:	87ce                	mv	a5,s3
            arr[i] = 1;
 6a6:	4705                	li	a4,1
 6a8:	00e78023          	sb	a4,0(a5)
        for (int i = PGSIZE * 1; i < PGSIZE * 2; ++i) {
 6ac:	0785                	addi	a5,a5,1
 6ae:	fe979de3          	bne	a5,s1,6a8 <fork_test+0x48>
            }
        printf("Creating first child\n");
 6b2:	00001517          	auipc	a0,0x1
 6b6:	a9650513          	addi	a0,a0,-1386 # 1148 <malloc+0x2f6>
 6ba:	00000097          	auipc	ra,0x0
 6be:	6da080e7          	jalr	1754(ra) # d94 <printf>
        if (!fork()) {
 6c2:	00000097          	auipc	ra,0x0
 6c6:	352080e7          	jalr	850(ra) # a14 <fork>
 6ca:	c131                	beqz	a0,70e <fork_test+0xae>
            for (int i = PGSIZE * 1; i < PGSIZE * 2; ++i) {
                arr[i] = 1;
            }
            exit(0);
        } else {
            wait(0);
 6cc:	4501                	li	a0,0
 6ce:	00000097          	auipc	ra,0x0
 6d2:	356080e7          	jalr	854(ra) # a24 <wait>
        }
        printf("Creating second child\n");
 6d6:	00001517          	auipc	a0,0x1
 6da:	a8a50513          	addi	a0,a0,-1398 # 1160 <malloc+0x30e>
 6de:	00000097          	auipc	ra,0x0
 6e2:	6b6080e7          	jalr	1718(ra) # d94 <printf>
        if (!fork()) {
 6e6:	00000097          	auipc	ra,0x0
 6ea:	32e080e7          	jalr	814(ra) # a14 <fork>
 6ee:	e91d                	bnez	a0,724 <fork_test+0xc4>
 6f0:	678d                	lui	a5,0x3
 6f2:	97ca                	add	a5,a5,s2
 6f4:	6711                	lui	a4,0x4
 6f6:	974a                	add	a4,a4,s2
            for (int i = PGSIZE * 3; i < PGSIZE * 4; ++i) {
                arr[i] = 1;
 6f8:	4685                	li	a3,1
 6fa:	00d78023          	sb	a3,0(a5) # 3000 <__global_pointer$+0x166f>
            for (int i = PGSIZE * 3; i < PGSIZE * 4; ++i) {
 6fe:	0785                	addi	a5,a5,1
 700:	fee79de3          	bne	a5,a4,6fa <fork_test+0x9a>
            }
            exit(0);
 704:	4501                	li	a0,0
 706:	00000097          	auipc	ra,0x0
 70a:	316080e7          	jalr	790(ra) # a1c <exit>
                arr[i] = 1;
 70e:	4785                	li	a5,1
 710:	00f98023          	sb	a5,0(s3) # 1000 <malloc+0x1ae>
            for (int i = PGSIZE * 1; i < PGSIZE * 2; ++i) {
 714:	0985                	addi	s3,s3,1
 716:	fe999de3          	bne	s3,s1,710 <fork_test+0xb0>
            exit(0);
 71a:	4501                	li	a0,0
 71c:	00000097          	auipc	ra,0x0
 720:	300080e7          	jalr	768(ra) # a1c <exit>
        } else {
            wait(0);
 724:	4501                	li	a0,0
 726:	00000097          	auipc	ra,0x0
 72a:	2fe080e7          	jalr	766(ra) # a24 <wait>
        }
        exit(0);
 72e:	4501                	li	a0,0
 730:	00000097          	auipc	ra,0x0
 734:	2ec080e7          	jalr	748(ra) # a1c <exit>
    } else {
        wait(0);
 738:	4501                	li	a0,0
 73a:	00000097          	auipc	ra,0x0
 73e:	2ea080e7          	jalr	746(ra) # a24 <wait>
    }
    PRINT_TEST_END("fork test");
 742:	00001597          	auipc	a1,0x1
 746:	9f658593          	addi	a1,a1,-1546 # 1138 <malloc+0x2e6>
 74a:	00001517          	auipc	a0,0x1
 74e:	85e50513          	addi	a0,a0,-1954 # fa8 <malloc+0x156>
 752:	00000097          	auipc	ra,0x0
 756:	642080e7          	jalr	1602(ra) # d94 <printf>
}
 75a:	70a2                	ld	ra,40(sp)
 75c:	7402                	ld	s0,32(sp)
 75e:	64e2                	ld	s1,24(sp)
 760:	6942                	ld	s2,16(sp)
 762:	69a2                	ld	s3,8(sp)
 764:	6145                	addi	sp,sp,48
 766:	8082                	ret

0000000000000768 <main>:
int main(int argc, char **argv) {
 768:	1141                	addi	sp,sp,-16
 76a:	e406                	sd	ra,8(sp)
 76c:	e022                	sd	s0,0(sp)
 76e:	0800                	addi	s0,sp,16
    if (argc >= 1) {
 770:	00a05d63          	blez	a0,78a <main+0x22>
 774:	87ae                	mv	a5,a1
        if (strcmp(argv[1], "exectest") == 0) {
 776:	00001597          	auipc	a1,0x1
 77a:	96a58593          	addi	a1,a1,-1686 # 10e0 <malloc+0x28e>
 77e:	6788                	ld	a0,8(a5)
 780:	00000097          	auipc	ra,0x0
 784:	04a080e7          	jalr	74(ra) # 7ca <strcmp>
 788:	c911                	beqz	a0,79c <main+0x34>
            exec_test_child();
            exit(0);
        }
    }
   fork_test(); // passed
 78a:	00000097          	auipc	ra,0x0
 78e:	ed6080e7          	jalr	-298(ra) # 660 <fork_test>
//    priority_test(); // passed
//    exec_test(); // passed
//    alloc_dealloc_test(); // passed
//    advance_alloc_dealloc_test(); // passed
    // child_test(); // fails!!!
    exit(0);
 792:	4501                	li	a0,0
 794:	00000097          	auipc	ra,0x0
 798:	288080e7          	jalr	648(ra) # a1c <exit>
            exec_test_child();
 79c:	00000097          	auipc	ra,0x0
 7a0:	d54080e7          	jalr	-684(ra) # 4f0 <exec_test_child>
            exit(0);
 7a4:	4501                	li	a0,0
 7a6:	00000097          	auipc	ra,0x0
 7aa:	276080e7          	jalr	630(ra) # a1c <exit>

00000000000007ae <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 7ae:	1141                	addi	sp,sp,-16
 7b0:	e422                	sd	s0,8(sp)
 7b2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 7b4:	87aa                	mv	a5,a0
 7b6:	0585                	addi	a1,a1,1
 7b8:	0785                	addi	a5,a5,1
 7ba:	fff5c703          	lbu	a4,-1(a1)
 7be:	fee78fa3          	sb	a4,-1(a5)
 7c2:	fb75                	bnez	a4,7b6 <strcpy+0x8>
    ;
  return os;
}
 7c4:	6422                	ld	s0,8(sp)
 7c6:	0141                	addi	sp,sp,16
 7c8:	8082                	ret

00000000000007ca <strcmp>:

int
strcmp(const char *p, const char *q)
{
 7ca:	1141                	addi	sp,sp,-16
 7cc:	e422                	sd	s0,8(sp)
 7ce:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 7d0:	00054783          	lbu	a5,0(a0)
 7d4:	cb91                	beqz	a5,7e8 <strcmp+0x1e>
 7d6:	0005c703          	lbu	a4,0(a1)
 7da:	00f71763          	bne	a4,a5,7e8 <strcmp+0x1e>
    p++, q++;
 7de:	0505                	addi	a0,a0,1
 7e0:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 7e2:	00054783          	lbu	a5,0(a0)
 7e6:	fbe5                	bnez	a5,7d6 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 7e8:	0005c503          	lbu	a0,0(a1)
}
 7ec:	40a7853b          	subw	a0,a5,a0
 7f0:	6422                	ld	s0,8(sp)
 7f2:	0141                	addi	sp,sp,16
 7f4:	8082                	ret

00000000000007f6 <strlen>:

uint
strlen(const char *s)
{
 7f6:	1141                	addi	sp,sp,-16
 7f8:	e422                	sd	s0,8(sp)
 7fa:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 7fc:	00054783          	lbu	a5,0(a0)
 800:	cf91                	beqz	a5,81c <strlen+0x26>
 802:	0505                	addi	a0,a0,1
 804:	87aa                	mv	a5,a0
 806:	4685                	li	a3,1
 808:	9e89                	subw	a3,a3,a0
 80a:	00f6853b          	addw	a0,a3,a5
 80e:	0785                	addi	a5,a5,1
 810:	fff7c703          	lbu	a4,-1(a5)
 814:	fb7d                	bnez	a4,80a <strlen+0x14>
    ;
  return n;
}
 816:	6422                	ld	s0,8(sp)
 818:	0141                	addi	sp,sp,16
 81a:	8082                	ret
  for(n = 0; s[n]; n++)
 81c:	4501                	li	a0,0
 81e:	bfe5                	j	816 <strlen+0x20>

0000000000000820 <memset>:

void*
memset(void *dst, int c, uint n)
{
 820:	1141                	addi	sp,sp,-16
 822:	e422                	sd	s0,8(sp)
 824:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 826:	ca19                	beqz	a2,83c <memset+0x1c>
 828:	87aa                	mv	a5,a0
 82a:	1602                	slli	a2,a2,0x20
 82c:	9201                	srli	a2,a2,0x20
 82e:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 832:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 836:	0785                	addi	a5,a5,1
 838:	fee79de3          	bne	a5,a4,832 <memset+0x12>
  }
  return dst;
}
 83c:	6422                	ld	s0,8(sp)
 83e:	0141                	addi	sp,sp,16
 840:	8082                	ret

0000000000000842 <strchr>:

char*
strchr(const char *s, char c)
{
 842:	1141                	addi	sp,sp,-16
 844:	e422                	sd	s0,8(sp)
 846:	0800                	addi	s0,sp,16
  for(; *s; s++)
 848:	00054783          	lbu	a5,0(a0)
 84c:	cb99                	beqz	a5,862 <strchr+0x20>
    if(*s == c)
 84e:	00f58763          	beq	a1,a5,85c <strchr+0x1a>
  for(; *s; s++)
 852:	0505                	addi	a0,a0,1
 854:	00054783          	lbu	a5,0(a0)
 858:	fbfd                	bnez	a5,84e <strchr+0xc>
      return (char*)s;
  return 0;
 85a:	4501                	li	a0,0
}
 85c:	6422                	ld	s0,8(sp)
 85e:	0141                	addi	sp,sp,16
 860:	8082                	ret
  return 0;
 862:	4501                	li	a0,0
 864:	bfe5                	j	85c <strchr+0x1a>

0000000000000866 <gets>:

char*
gets(char *buf, int max)
{
 866:	711d                	addi	sp,sp,-96
 868:	ec86                	sd	ra,88(sp)
 86a:	e8a2                	sd	s0,80(sp)
 86c:	e4a6                	sd	s1,72(sp)
 86e:	e0ca                	sd	s2,64(sp)
 870:	fc4e                	sd	s3,56(sp)
 872:	f852                	sd	s4,48(sp)
 874:	f456                	sd	s5,40(sp)
 876:	f05a                	sd	s6,32(sp)
 878:	ec5e                	sd	s7,24(sp)
 87a:	1080                	addi	s0,sp,96
 87c:	8baa                	mv	s7,a0
 87e:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 880:	892a                	mv	s2,a0
 882:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 884:	4aa9                	li	s5,10
 886:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 888:	89a6                	mv	s3,s1
 88a:	2485                	addiw	s1,s1,1
 88c:	0344d863          	bge	s1,s4,8bc <gets+0x56>
    cc = read(0, &c, 1);
 890:	4605                	li	a2,1
 892:	faf40593          	addi	a1,s0,-81
 896:	4501                	li	a0,0
 898:	00000097          	auipc	ra,0x0
 89c:	19c080e7          	jalr	412(ra) # a34 <read>
    if(cc < 1)
 8a0:	00a05e63          	blez	a0,8bc <gets+0x56>
    buf[i++] = c;
 8a4:	faf44783          	lbu	a5,-81(s0)
 8a8:	00f90023          	sb	a5,0(s2) # 14000 <__global_pointer$+0x1266f>
    if(c == '\n' || c == '\r')
 8ac:	01578763          	beq	a5,s5,8ba <gets+0x54>
 8b0:	0905                	addi	s2,s2,1
 8b2:	fd679be3          	bne	a5,s6,888 <gets+0x22>
  for(i=0; i+1 < max; ){
 8b6:	89a6                	mv	s3,s1
 8b8:	a011                	j	8bc <gets+0x56>
 8ba:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 8bc:	99de                	add	s3,s3,s7
 8be:	00098023          	sb	zero,0(s3)
  return buf;
}
 8c2:	855e                	mv	a0,s7
 8c4:	60e6                	ld	ra,88(sp)
 8c6:	6446                	ld	s0,80(sp)
 8c8:	64a6                	ld	s1,72(sp)
 8ca:	6906                	ld	s2,64(sp)
 8cc:	79e2                	ld	s3,56(sp)
 8ce:	7a42                	ld	s4,48(sp)
 8d0:	7aa2                	ld	s5,40(sp)
 8d2:	7b02                	ld	s6,32(sp)
 8d4:	6be2                	ld	s7,24(sp)
 8d6:	6125                	addi	sp,sp,96
 8d8:	8082                	ret

00000000000008da <stat>:

int
stat(const char *n, struct stat *st)
{
 8da:	1101                	addi	sp,sp,-32
 8dc:	ec06                	sd	ra,24(sp)
 8de:	e822                	sd	s0,16(sp)
 8e0:	e426                	sd	s1,8(sp)
 8e2:	e04a                	sd	s2,0(sp)
 8e4:	1000                	addi	s0,sp,32
 8e6:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 8e8:	4581                	li	a1,0
 8ea:	00000097          	auipc	ra,0x0
 8ee:	172080e7          	jalr	370(ra) # a5c <open>
  if(fd < 0)
 8f2:	02054563          	bltz	a0,91c <stat+0x42>
 8f6:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 8f8:	85ca                	mv	a1,s2
 8fa:	00000097          	auipc	ra,0x0
 8fe:	17a080e7          	jalr	378(ra) # a74 <fstat>
 902:	892a                	mv	s2,a0
  close(fd);
 904:	8526                	mv	a0,s1
 906:	00000097          	auipc	ra,0x0
 90a:	13e080e7          	jalr	318(ra) # a44 <close>
  return r;
}
 90e:	854a                	mv	a0,s2
 910:	60e2                	ld	ra,24(sp)
 912:	6442                	ld	s0,16(sp)
 914:	64a2                	ld	s1,8(sp)
 916:	6902                	ld	s2,0(sp)
 918:	6105                	addi	sp,sp,32
 91a:	8082                	ret
    return -1;
 91c:	597d                	li	s2,-1
 91e:	bfc5                	j	90e <stat+0x34>

0000000000000920 <atoi>:

int
atoi(const char *s)
{
 920:	1141                	addi	sp,sp,-16
 922:	e422                	sd	s0,8(sp)
 924:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 926:	00054603          	lbu	a2,0(a0)
 92a:	fd06079b          	addiw	a5,a2,-48
 92e:	0ff7f793          	andi	a5,a5,255
 932:	4725                	li	a4,9
 934:	02f76963          	bltu	a4,a5,966 <atoi+0x46>
 938:	86aa                	mv	a3,a0
  n = 0;
 93a:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 93c:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 93e:	0685                	addi	a3,a3,1
 940:	0025179b          	slliw	a5,a0,0x2
 944:	9fa9                	addw	a5,a5,a0
 946:	0017979b          	slliw	a5,a5,0x1
 94a:	9fb1                	addw	a5,a5,a2
 94c:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 950:	0006c603          	lbu	a2,0(a3)
 954:	fd06071b          	addiw	a4,a2,-48
 958:	0ff77713          	andi	a4,a4,255
 95c:	fee5f1e3          	bgeu	a1,a4,93e <atoi+0x1e>
  return n;
}
 960:	6422                	ld	s0,8(sp)
 962:	0141                	addi	sp,sp,16
 964:	8082                	ret
  n = 0;
 966:	4501                	li	a0,0
 968:	bfe5                	j	960 <atoi+0x40>

000000000000096a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 96a:	1141                	addi	sp,sp,-16
 96c:	e422                	sd	s0,8(sp)
 96e:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 970:	02b57463          	bgeu	a0,a1,998 <memmove+0x2e>
    while(n-- > 0)
 974:	00c05f63          	blez	a2,992 <memmove+0x28>
 978:	1602                	slli	a2,a2,0x20
 97a:	9201                	srli	a2,a2,0x20
 97c:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 980:	872a                	mv	a4,a0
      *dst++ = *src++;
 982:	0585                	addi	a1,a1,1
 984:	0705                	addi	a4,a4,1
 986:	fff5c683          	lbu	a3,-1(a1)
 98a:	fed70fa3          	sb	a3,-1(a4) # 3fff <__global_pointer$+0x266e>
    while(n-- > 0)
 98e:	fee79ae3          	bne	a5,a4,982 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 992:	6422                	ld	s0,8(sp)
 994:	0141                	addi	sp,sp,16
 996:	8082                	ret
    dst += n;
 998:	00c50733          	add	a4,a0,a2
    src += n;
 99c:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 99e:	fec05ae3          	blez	a2,992 <memmove+0x28>
 9a2:	fff6079b          	addiw	a5,a2,-1
 9a6:	1782                	slli	a5,a5,0x20
 9a8:	9381                	srli	a5,a5,0x20
 9aa:	fff7c793          	not	a5,a5
 9ae:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 9b0:	15fd                	addi	a1,a1,-1
 9b2:	177d                	addi	a4,a4,-1
 9b4:	0005c683          	lbu	a3,0(a1)
 9b8:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 9bc:	fee79ae3          	bne	a5,a4,9b0 <memmove+0x46>
 9c0:	bfc9                	j	992 <memmove+0x28>

00000000000009c2 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 9c2:	1141                	addi	sp,sp,-16
 9c4:	e422                	sd	s0,8(sp)
 9c6:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 9c8:	ca05                	beqz	a2,9f8 <memcmp+0x36>
 9ca:	fff6069b          	addiw	a3,a2,-1
 9ce:	1682                	slli	a3,a3,0x20
 9d0:	9281                	srli	a3,a3,0x20
 9d2:	0685                	addi	a3,a3,1
 9d4:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 9d6:	00054783          	lbu	a5,0(a0)
 9da:	0005c703          	lbu	a4,0(a1)
 9de:	00e79863          	bne	a5,a4,9ee <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 9e2:	0505                	addi	a0,a0,1
    p2++;
 9e4:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 9e6:	fed518e3          	bne	a0,a3,9d6 <memcmp+0x14>
  }
  return 0;
 9ea:	4501                	li	a0,0
 9ec:	a019                	j	9f2 <memcmp+0x30>
      return *p1 - *p2;
 9ee:	40e7853b          	subw	a0,a5,a4
}
 9f2:	6422                	ld	s0,8(sp)
 9f4:	0141                	addi	sp,sp,16
 9f6:	8082                	ret
  return 0;
 9f8:	4501                	li	a0,0
 9fa:	bfe5                	j	9f2 <memcmp+0x30>

00000000000009fc <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 9fc:	1141                	addi	sp,sp,-16
 9fe:	e406                	sd	ra,8(sp)
 a00:	e022                	sd	s0,0(sp)
 a02:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 a04:	00000097          	auipc	ra,0x0
 a08:	f66080e7          	jalr	-154(ra) # 96a <memmove>
}
 a0c:	60a2                	ld	ra,8(sp)
 a0e:	6402                	ld	s0,0(sp)
 a10:	0141                	addi	sp,sp,16
 a12:	8082                	ret

0000000000000a14 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 a14:	4885                	li	a7,1
 ecall
 a16:	00000073          	ecall
 ret
 a1a:	8082                	ret

0000000000000a1c <exit>:
.global exit
exit:
 li a7, SYS_exit
 a1c:	4889                	li	a7,2
 ecall
 a1e:	00000073          	ecall
 ret
 a22:	8082                	ret

0000000000000a24 <wait>:
.global wait
wait:
 li a7, SYS_wait
 a24:	488d                	li	a7,3
 ecall
 a26:	00000073          	ecall
 ret
 a2a:	8082                	ret

0000000000000a2c <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 a2c:	4891                	li	a7,4
 ecall
 a2e:	00000073          	ecall
 ret
 a32:	8082                	ret

0000000000000a34 <read>:
.global read
read:
 li a7, SYS_read
 a34:	4895                	li	a7,5
 ecall
 a36:	00000073          	ecall
 ret
 a3a:	8082                	ret

0000000000000a3c <write>:
.global write
write:
 li a7, SYS_write
 a3c:	48c1                	li	a7,16
 ecall
 a3e:	00000073          	ecall
 ret
 a42:	8082                	ret

0000000000000a44 <close>:
.global close
close:
 li a7, SYS_close
 a44:	48d5                	li	a7,21
 ecall
 a46:	00000073          	ecall
 ret
 a4a:	8082                	ret

0000000000000a4c <kill>:
.global kill
kill:
 li a7, SYS_kill
 a4c:	4899                	li	a7,6
 ecall
 a4e:	00000073          	ecall
 ret
 a52:	8082                	ret

0000000000000a54 <exec>:
.global exec
exec:
 li a7, SYS_exec
 a54:	489d                	li	a7,7
 ecall
 a56:	00000073          	ecall
 ret
 a5a:	8082                	ret

0000000000000a5c <open>:
.global open
open:
 li a7, SYS_open
 a5c:	48bd                	li	a7,15
 ecall
 a5e:	00000073          	ecall
 ret
 a62:	8082                	ret

0000000000000a64 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 a64:	48c5                	li	a7,17
 ecall
 a66:	00000073          	ecall
 ret
 a6a:	8082                	ret

0000000000000a6c <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 a6c:	48c9                	li	a7,18
 ecall
 a6e:	00000073          	ecall
 ret
 a72:	8082                	ret

0000000000000a74 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 a74:	48a1                	li	a7,8
 ecall
 a76:	00000073          	ecall
 ret
 a7a:	8082                	ret

0000000000000a7c <link>:
.global link
link:
 li a7, SYS_link
 a7c:	48cd                	li	a7,19
 ecall
 a7e:	00000073          	ecall
 ret
 a82:	8082                	ret

0000000000000a84 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 a84:	48d1                	li	a7,20
 ecall
 a86:	00000073          	ecall
 ret
 a8a:	8082                	ret

0000000000000a8c <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 a8c:	48a5                	li	a7,9
 ecall
 a8e:	00000073          	ecall
 ret
 a92:	8082                	ret

0000000000000a94 <dup>:
.global dup
dup:
 li a7, SYS_dup
 a94:	48a9                	li	a7,10
 ecall
 a96:	00000073          	ecall
 ret
 a9a:	8082                	ret

0000000000000a9c <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 a9c:	48ad                	li	a7,11
 ecall
 a9e:	00000073          	ecall
 ret
 aa2:	8082                	ret

0000000000000aa4 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 aa4:	48b1                	li	a7,12
 ecall
 aa6:	00000073          	ecall
 ret
 aaa:	8082                	ret

0000000000000aac <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 aac:	48b5                	li	a7,13
 ecall
 aae:	00000073          	ecall
 ret
 ab2:	8082                	ret

0000000000000ab4 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 ab4:	48b9                	li	a7,14
 ecall
 ab6:	00000073          	ecall
 ret
 aba:	8082                	ret

0000000000000abc <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 abc:	1101                	addi	sp,sp,-32
 abe:	ec06                	sd	ra,24(sp)
 ac0:	e822                	sd	s0,16(sp)
 ac2:	1000                	addi	s0,sp,32
 ac4:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 ac8:	4605                	li	a2,1
 aca:	fef40593          	addi	a1,s0,-17
 ace:	00000097          	auipc	ra,0x0
 ad2:	f6e080e7          	jalr	-146(ra) # a3c <write>
}
 ad6:	60e2                	ld	ra,24(sp)
 ad8:	6442                	ld	s0,16(sp)
 ada:	6105                	addi	sp,sp,32
 adc:	8082                	ret

0000000000000ade <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 ade:	7139                	addi	sp,sp,-64
 ae0:	fc06                	sd	ra,56(sp)
 ae2:	f822                	sd	s0,48(sp)
 ae4:	f426                	sd	s1,40(sp)
 ae6:	f04a                	sd	s2,32(sp)
 ae8:	ec4e                	sd	s3,24(sp)
 aea:	0080                	addi	s0,sp,64
 aec:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 aee:	c299                	beqz	a3,af4 <printint+0x16>
 af0:	0805c863          	bltz	a1,b80 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 af4:	2581                	sext.w	a1,a1
  neg = 0;
 af6:	4881                	li	a7,0
 af8:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 afc:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 afe:	2601                	sext.w	a2,a2
 b00:	00000517          	auipc	a0,0x0
 b04:	68050513          	addi	a0,a0,1664 # 1180 <digits>
 b08:	883a                	mv	a6,a4
 b0a:	2705                	addiw	a4,a4,1
 b0c:	02c5f7bb          	remuw	a5,a1,a2
 b10:	1782                	slli	a5,a5,0x20
 b12:	9381                	srli	a5,a5,0x20
 b14:	97aa                	add	a5,a5,a0
 b16:	0007c783          	lbu	a5,0(a5)
 b1a:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 b1e:	0005879b          	sext.w	a5,a1
 b22:	02c5d5bb          	divuw	a1,a1,a2
 b26:	0685                	addi	a3,a3,1
 b28:	fec7f0e3          	bgeu	a5,a2,b08 <printint+0x2a>
  if(neg)
 b2c:	00088b63          	beqz	a7,b42 <printint+0x64>
    buf[i++] = '-';
 b30:	fd040793          	addi	a5,s0,-48
 b34:	973e                	add	a4,a4,a5
 b36:	02d00793          	li	a5,45
 b3a:	fef70823          	sb	a5,-16(a4)
 b3e:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 b42:	02e05863          	blez	a4,b72 <printint+0x94>
 b46:	fc040793          	addi	a5,s0,-64
 b4a:	00e78933          	add	s2,a5,a4
 b4e:	fff78993          	addi	s3,a5,-1
 b52:	99ba                	add	s3,s3,a4
 b54:	377d                	addiw	a4,a4,-1
 b56:	1702                	slli	a4,a4,0x20
 b58:	9301                	srli	a4,a4,0x20
 b5a:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 b5e:	fff94583          	lbu	a1,-1(s2)
 b62:	8526                	mv	a0,s1
 b64:	00000097          	auipc	ra,0x0
 b68:	f58080e7          	jalr	-168(ra) # abc <putc>
  while(--i >= 0)
 b6c:	197d                	addi	s2,s2,-1
 b6e:	ff3918e3          	bne	s2,s3,b5e <printint+0x80>
}
 b72:	70e2                	ld	ra,56(sp)
 b74:	7442                	ld	s0,48(sp)
 b76:	74a2                	ld	s1,40(sp)
 b78:	7902                	ld	s2,32(sp)
 b7a:	69e2                	ld	s3,24(sp)
 b7c:	6121                	addi	sp,sp,64
 b7e:	8082                	ret
    x = -xx;
 b80:	40b005bb          	negw	a1,a1
    neg = 1;
 b84:	4885                	li	a7,1
    x = -xx;
 b86:	bf8d                	j	af8 <printint+0x1a>

0000000000000b88 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 b88:	7119                	addi	sp,sp,-128
 b8a:	fc86                	sd	ra,120(sp)
 b8c:	f8a2                	sd	s0,112(sp)
 b8e:	f4a6                	sd	s1,104(sp)
 b90:	f0ca                	sd	s2,96(sp)
 b92:	ecce                	sd	s3,88(sp)
 b94:	e8d2                	sd	s4,80(sp)
 b96:	e4d6                	sd	s5,72(sp)
 b98:	e0da                	sd	s6,64(sp)
 b9a:	fc5e                	sd	s7,56(sp)
 b9c:	f862                	sd	s8,48(sp)
 b9e:	f466                	sd	s9,40(sp)
 ba0:	f06a                	sd	s10,32(sp)
 ba2:	ec6e                	sd	s11,24(sp)
 ba4:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 ba6:	0005c903          	lbu	s2,0(a1)
 baa:	18090f63          	beqz	s2,d48 <vprintf+0x1c0>
 bae:	8aaa                	mv	s5,a0
 bb0:	8b32                	mv	s6,a2
 bb2:	00158493          	addi	s1,a1,1
  state = 0;
 bb6:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 bb8:	02500a13          	li	s4,37
      if(c == 'd'){
 bbc:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 bc0:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 bc4:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 bc8:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 bcc:	00000b97          	auipc	s7,0x0
 bd0:	5b4b8b93          	addi	s7,s7,1460 # 1180 <digits>
 bd4:	a839                	j	bf2 <vprintf+0x6a>
        putc(fd, c);
 bd6:	85ca                	mv	a1,s2
 bd8:	8556                	mv	a0,s5
 bda:	00000097          	auipc	ra,0x0
 bde:	ee2080e7          	jalr	-286(ra) # abc <putc>
 be2:	a019                	j	be8 <vprintf+0x60>
    } else if(state == '%'){
 be4:	01498f63          	beq	s3,s4,c02 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 be8:	0485                	addi	s1,s1,1
 bea:	fff4c903          	lbu	s2,-1(s1) # 1fff <__global_pointer$+0x66e>
 bee:	14090d63          	beqz	s2,d48 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 bf2:	0009079b          	sext.w	a5,s2
    if(state == 0){
 bf6:	fe0997e3          	bnez	s3,be4 <vprintf+0x5c>
      if(c == '%'){
 bfa:	fd479ee3          	bne	a5,s4,bd6 <vprintf+0x4e>
        state = '%';
 bfe:	89be                	mv	s3,a5
 c00:	b7e5                	j	be8 <vprintf+0x60>
      if(c == 'd'){
 c02:	05878063          	beq	a5,s8,c42 <vprintf+0xba>
      } else if(c == 'l') {
 c06:	05978c63          	beq	a5,s9,c5e <vprintf+0xd6>
      } else if(c == 'x') {
 c0a:	07a78863          	beq	a5,s10,c7a <vprintf+0xf2>
      } else if(c == 'p') {
 c0e:	09b78463          	beq	a5,s11,c96 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 c12:	07300713          	li	a4,115
 c16:	0ce78663          	beq	a5,a4,ce2 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 c1a:	06300713          	li	a4,99
 c1e:	0ee78e63          	beq	a5,a4,d1a <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 c22:	11478863          	beq	a5,s4,d32 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 c26:	85d2                	mv	a1,s4
 c28:	8556                	mv	a0,s5
 c2a:	00000097          	auipc	ra,0x0
 c2e:	e92080e7          	jalr	-366(ra) # abc <putc>
        putc(fd, c);
 c32:	85ca                	mv	a1,s2
 c34:	8556                	mv	a0,s5
 c36:	00000097          	auipc	ra,0x0
 c3a:	e86080e7          	jalr	-378(ra) # abc <putc>
      }
      state = 0;
 c3e:	4981                	li	s3,0
 c40:	b765                	j	be8 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 c42:	008b0913          	addi	s2,s6,8
 c46:	4685                	li	a3,1
 c48:	4629                	li	a2,10
 c4a:	000b2583          	lw	a1,0(s6)
 c4e:	8556                	mv	a0,s5
 c50:	00000097          	auipc	ra,0x0
 c54:	e8e080e7          	jalr	-370(ra) # ade <printint>
 c58:	8b4a                	mv	s6,s2
      state = 0;
 c5a:	4981                	li	s3,0
 c5c:	b771                	j	be8 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 c5e:	008b0913          	addi	s2,s6,8
 c62:	4681                	li	a3,0
 c64:	4629                	li	a2,10
 c66:	000b2583          	lw	a1,0(s6)
 c6a:	8556                	mv	a0,s5
 c6c:	00000097          	auipc	ra,0x0
 c70:	e72080e7          	jalr	-398(ra) # ade <printint>
 c74:	8b4a                	mv	s6,s2
      state = 0;
 c76:	4981                	li	s3,0
 c78:	bf85                	j	be8 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 c7a:	008b0913          	addi	s2,s6,8
 c7e:	4681                	li	a3,0
 c80:	4641                	li	a2,16
 c82:	000b2583          	lw	a1,0(s6)
 c86:	8556                	mv	a0,s5
 c88:	00000097          	auipc	ra,0x0
 c8c:	e56080e7          	jalr	-426(ra) # ade <printint>
 c90:	8b4a                	mv	s6,s2
      state = 0;
 c92:	4981                	li	s3,0
 c94:	bf91                	j	be8 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 c96:	008b0793          	addi	a5,s6,8
 c9a:	f8f43423          	sd	a5,-120(s0)
 c9e:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 ca2:	03000593          	li	a1,48
 ca6:	8556                	mv	a0,s5
 ca8:	00000097          	auipc	ra,0x0
 cac:	e14080e7          	jalr	-492(ra) # abc <putc>
  putc(fd, 'x');
 cb0:	85ea                	mv	a1,s10
 cb2:	8556                	mv	a0,s5
 cb4:	00000097          	auipc	ra,0x0
 cb8:	e08080e7          	jalr	-504(ra) # abc <putc>
 cbc:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 cbe:	03c9d793          	srli	a5,s3,0x3c
 cc2:	97de                	add	a5,a5,s7
 cc4:	0007c583          	lbu	a1,0(a5)
 cc8:	8556                	mv	a0,s5
 cca:	00000097          	auipc	ra,0x0
 cce:	df2080e7          	jalr	-526(ra) # abc <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 cd2:	0992                	slli	s3,s3,0x4
 cd4:	397d                	addiw	s2,s2,-1
 cd6:	fe0914e3          	bnez	s2,cbe <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 cda:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 cde:	4981                	li	s3,0
 ce0:	b721                	j	be8 <vprintf+0x60>
        s = va_arg(ap, char*);
 ce2:	008b0993          	addi	s3,s6,8
 ce6:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 cea:	02090163          	beqz	s2,d0c <vprintf+0x184>
        while(*s != 0){
 cee:	00094583          	lbu	a1,0(s2)
 cf2:	c9a1                	beqz	a1,d42 <vprintf+0x1ba>
          putc(fd, *s);
 cf4:	8556                	mv	a0,s5
 cf6:	00000097          	auipc	ra,0x0
 cfa:	dc6080e7          	jalr	-570(ra) # abc <putc>
          s++;
 cfe:	0905                	addi	s2,s2,1
        while(*s != 0){
 d00:	00094583          	lbu	a1,0(s2)
 d04:	f9e5                	bnez	a1,cf4 <vprintf+0x16c>
        s = va_arg(ap, char*);
 d06:	8b4e                	mv	s6,s3
      state = 0;
 d08:	4981                	li	s3,0
 d0a:	bdf9                	j	be8 <vprintf+0x60>
          s = "(null)";
 d0c:	00000917          	auipc	s2,0x0
 d10:	46c90913          	addi	s2,s2,1132 # 1178 <malloc+0x326>
        while(*s != 0){
 d14:	02800593          	li	a1,40
 d18:	bff1                	j	cf4 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 d1a:	008b0913          	addi	s2,s6,8
 d1e:	000b4583          	lbu	a1,0(s6)
 d22:	8556                	mv	a0,s5
 d24:	00000097          	auipc	ra,0x0
 d28:	d98080e7          	jalr	-616(ra) # abc <putc>
 d2c:	8b4a                	mv	s6,s2
      state = 0;
 d2e:	4981                	li	s3,0
 d30:	bd65                	j	be8 <vprintf+0x60>
        putc(fd, c);
 d32:	85d2                	mv	a1,s4
 d34:	8556                	mv	a0,s5
 d36:	00000097          	auipc	ra,0x0
 d3a:	d86080e7          	jalr	-634(ra) # abc <putc>
      state = 0;
 d3e:	4981                	li	s3,0
 d40:	b565                	j	be8 <vprintf+0x60>
        s = va_arg(ap, char*);
 d42:	8b4e                	mv	s6,s3
      state = 0;
 d44:	4981                	li	s3,0
 d46:	b54d                	j	be8 <vprintf+0x60>
    }
  }
}
 d48:	70e6                	ld	ra,120(sp)
 d4a:	7446                	ld	s0,112(sp)
 d4c:	74a6                	ld	s1,104(sp)
 d4e:	7906                	ld	s2,96(sp)
 d50:	69e6                	ld	s3,88(sp)
 d52:	6a46                	ld	s4,80(sp)
 d54:	6aa6                	ld	s5,72(sp)
 d56:	6b06                	ld	s6,64(sp)
 d58:	7be2                	ld	s7,56(sp)
 d5a:	7c42                	ld	s8,48(sp)
 d5c:	7ca2                	ld	s9,40(sp)
 d5e:	7d02                	ld	s10,32(sp)
 d60:	6de2                	ld	s11,24(sp)
 d62:	6109                	addi	sp,sp,128
 d64:	8082                	ret

0000000000000d66 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 d66:	715d                	addi	sp,sp,-80
 d68:	ec06                	sd	ra,24(sp)
 d6a:	e822                	sd	s0,16(sp)
 d6c:	1000                	addi	s0,sp,32
 d6e:	e010                	sd	a2,0(s0)
 d70:	e414                	sd	a3,8(s0)
 d72:	e818                	sd	a4,16(s0)
 d74:	ec1c                	sd	a5,24(s0)
 d76:	03043023          	sd	a6,32(s0)
 d7a:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 d7e:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 d82:	8622                	mv	a2,s0
 d84:	00000097          	auipc	ra,0x0
 d88:	e04080e7          	jalr	-508(ra) # b88 <vprintf>
}
 d8c:	60e2                	ld	ra,24(sp)
 d8e:	6442                	ld	s0,16(sp)
 d90:	6161                	addi	sp,sp,80
 d92:	8082                	ret

0000000000000d94 <printf>:

void
printf(const char *fmt, ...)
{
 d94:	711d                	addi	sp,sp,-96
 d96:	ec06                	sd	ra,24(sp)
 d98:	e822                	sd	s0,16(sp)
 d9a:	1000                	addi	s0,sp,32
 d9c:	e40c                	sd	a1,8(s0)
 d9e:	e810                	sd	a2,16(s0)
 da0:	ec14                	sd	a3,24(s0)
 da2:	f018                	sd	a4,32(s0)
 da4:	f41c                	sd	a5,40(s0)
 da6:	03043823          	sd	a6,48(s0)
 daa:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 dae:	00840613          	addi	a2,s0,8
 db2:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 db6:	85aa                	mv	a1,a0
 db8:	4505                	li	a0,1
 dba:	00000097          	auipc	ra,0x0
 dbe:	dce080e7          	jalr	-562(ra) # b88 <vprintf>
}
 dc2:	60e2                	ld	ra,24(sp)
 dc4:	6442                	ld	s0,16(sp)
 dc6:	6125                	addi	sp,sp,96
 dc8:	8082                	ret

0000000000000dca <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 dca:	1141                	addi	sp,sp,-16
 dcc:	e422                	sd	s0,8(sp)
 dce:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 dd0:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 dd4:	00000797          	auipc	a5,0x0
 dd8:	3c47b783          	ld	a5,964(a5) # 1198 <freep>
 ddc:	a805                	j	e0c <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 dde:	4618                	lw	a4,8(a2)
 de0:	9db9                	addw	a1,a1,a4
 de2:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 de6:	6398                	ld	a4,0(a5)
 de8:	6318                	ld	a4,0(a4)
 dea:	fee53823          	sd	a4,-16(a0)
 dee:	a091                	j	e32 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 df0:	ff852703          	lw	a4,-8(a0)
 df4:	9e39                	addw	a2,a2,a4
 df6:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 df8:	ff053703          	ld	a4,-16(a0)
 dfc:	e398                	sd	a4,0(a5)
 dfe:	a099                	j	e44 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 e00:	6398                	ld	a4,0(a5)
 e02:	00e7e463          	bltu	a5,a4,e0a <free+0x40>
 e06:	00e6ea63          	bltu	a3,a4,e1a <free+0x50>
{
 e0a:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 e0c:	fed7fae3          	bgeu	a5,a3,e00 <free+0x36>
 e10:	6398                	ld	a4,0(a5)
 e12:	00e6e463          	bltu	a3,a4,e1a <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 e16:	fee7eae3          	bltu	a5,a4,e0a <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 e1a:	ff852583          	lw	a1,-8(a0)
 e1e:	6390                	ld	a2,0(a5)
 e20:	02059813          	slli	a6,a1,0x20
 e24:	01c85713          	srli	a4,a6,0x1c
 e28:	9736                	add	a4,a4,a3
 e2a:	fae60ae3          	beq	a2,a4,dde <free+0x14>
    bp->s.ptr = p->s.ptr;
 e2e:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 e32:	4790                	lw	a2,8(a5)
 e34:	02061593          	slli	a1,a2,0x20
 e38:	01c5d713          	srli	a4,a1,0x1c
 e3c:	973e                	add	a4,a4,a5
 e3e:	fae689e3          	beq	a3,a4,df0 <free+0x26>
  } else
    p->s.ptr = bp;
 e42:	e394                	sd	a3,0(a5)
  freep = p;
 e44:	00000717          	auipc	a4,0x0
 e48:	34f73a23          	sd	a5,852(a4) # 1198 <freep>
}
 e4c:	6422                	ld	s0,8(sp)
 e4e:	0141                	addi	sp,sp,16
 e50:	8082                	ret

0000000000000e52 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 e52:	7139                	addi	sp,sp,-64
 e54:	fc06                	sd	ra,56(sp)
 e56:	f822                	sd	s0,48(sp)
 e58:	f426                	sd	s1,40(sp)
 e5a:	f04a                	sd	s2,32(sp)
 e5c:	ec4e                	sd	s3,24(sp)
 e5e:	e852                	sd	s4,16(sp)
 e60:	e456                	sd	s5,8(sp)
 e62:	e05a                	sd	s6,0(sp)
 e64:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 e66:	02051493          	slli	s1,a0,0x20
 e6a:	9081                	srli	s1,s1,0x20
 e6c:	04bd                	addi	s1,s1,15
 e6e:	8091                	srli	s1,s1,0x4
 e70:	0014899b          	addiw	s3,s1,1
 e74:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 e76:	00000517          	auipc	a0,0x0
 e7a:	32253503          	ld	a0,802(a0) # 1198 <freep>
 e7e:	c515                	beqz	a0,eaa <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 e80:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 e82:	4798                	lw	a4,8(a5)
 e84:	02977f63          	bgeu	a4,s1,ec2 <malloc+0x70>
 e88:	8a4e                	mv	s4,s3
 e8a:	0009871b          	sext.w	a4,s3
 e8e:	6685                	lui	a3,0x1
 e90:	00d77363          	bgeu	a4,a3,e96 <malloc+0x44>
 e94:	6a05                	lui	s4,0x1
 e96:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 e9a:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 e9e:	00000917          	auipc	s2,0x0
 ea2:	2fa90913          	addi	s2,s2,762 # 1198 <freep>
  if(p == (char*)-1)
 ea6:	5afd                	li	s5,-1
 ea8:	a895                	j	f1c <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 eaa:	00000797          	auipc	a5,0x0
 eae:	2f678793          	addi	a5,a5,758 # 11a0 <base>
 eb2:	00000717          	auipc	a4,0x0
 eb6:	2ef73323          	sd	a5,742(a4) # 1198 <freep>
 eba:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 ebc:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 ec0:	b7e1                	j	e88 <malloc+0x36>
      if(p->s.size == nunits)
 ec2:	02e48c63          	beq	s1,a4,efa <malloc+0xa8>
        p->s.size -= nunits;
 ec6:	4137073b          	subw	a4,a4,s3
 eca:	c798                	sw	a4,8(a5)
        p += p->s.size;
 ecc:	02071693          	slli	a3,a4,0x20
 ed0:	01c6d713          	srli	a4,a3,0x1c
 ed4:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 ed6:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 eda:	00000717          	auipc	a4,0x0
 ede:	2aa73f23          	sd	a0,702(a4) # 1198 <freep>
      return (void*)(p + 1);
 ee2:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 ee6:	70e2                	ld	ra,56(sp)
 ee8:	7442                	ld	s0,48(sp)
 eea:	74a2                	ld	s1,40(sp)
 eec:	7902                	ld	s2,32(sp)
 eee:	69e2                	ld	s3,24(sp)
 ef0:	6a42                	ld	s4,16(sp)
 ef2:	6aa2                	ld	s5,8(sp)
 ef4:	6b02                	ld	s6,0(sp)
 ef6:	6121                	addi	sp,sp,64
 ef8:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 efa:	6398                	ld	a4,0(a5)
 efc:	e118                	sd	a4,0(a0)
 efe:	bff1                	j	eda <malloc+0x88>
  hp->s.size = nu;
 f00:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 f04:	0541                	addi	a0,a0,16
 f06:	00000097          	auipc	ra,0x0
 f0a:	ec4080e7          	jalr	-316(ra) # dca <free>
  return freep;
 f0e:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 f12:	d971                	beqz	a0,ee6 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 f14:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 f16:	4798                	lw	a4,8(a5)
 f18:	fa9775e3          	bgeu	a4,s1,ec2 <malloc+0x70>
    if(p == freep)
 f1c:	00093703          	ld	a4,0(s2)
 f20:	853e                	mv	a0,a5
 f22:	fef719e3          	bne	a4,a5,f14 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 f26:	8552                	mv	a0,s4
 f28:	00000097          	auipc	ra,0x0
 f2c:	b7c080e7          	jalr	-1156(ra) # aa4 <sbrk>
  if(p == (char*)-1)
 f30:	fd5518e3          	bne	a0,s5,f00 <malloc+0xae>
        return 0;
 f34:	4501                	li	a0,0
 f36:	bf45                	j	ee6 <malloc+0x94>
