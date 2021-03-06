#include "param.h"
#include "types.h"
#include "memlayout.h"
#include "elf.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "spinlock.h" //task 1.1
#include "proc.h" //task 1.1

/*
 * the kernel's page table.
 */
pagetable_t kernel_pagetable;

extern char etext[];  // kernel.ld sets this to end of kernel code.

extern char trampoline[]; // trampoline.S

// Make a direct-map page table for the kernel.
pagetable_t
kvmmake(void)
{
  pagetable_t kpgtbl;

  kpgtbl = (pagetable_t) kalloc();
  memset(kpgtbl, 0, PGSIZE);

  // uart registers
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);

  // virtio mmio disk interface
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);

  // PLIC
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);

  // map kernel text executable and read-only.
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);

  // map kernel data and the physical RAM we'll make use of.
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);

  // map the trampoline for trap entry/exit to
  // the highest virtual address in the kernel.
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);

  // map kernel stacks
  proc_mapstacks(kpgtbl);
  
  return kpgtbl;
}

// Initialize the one kernel_pagetable
void
kvminit(void)
{
  kernel_pagetable = kvmmake();
}

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
  w_satp(MAKE_SATP(kernel_pagetable));
  sfence_vma();
}

// Return the address of the PTE in page table pagetable
// that corresponds to virtual address va.  If alloc!=0,
// create any required page-table pages.
//
// The risc-v Sv39 scheme has three levels of page-table
// pages. A page-table page contains 512 64-bit PTEs.
// A 64-bit virtual address is split into five fields:
//   39..63 -- must be zero.
//   30..38 -- 9 bits of level-2 index.
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
  if(va >= MAXVA){
    panic("walk");
  }

  for(int level = 2; level > 0; level--) {
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
        return 0;
      memset(pagetable, 0, PGSIZE);
      *pte = PA2PTE(pagetable) | PTE_V;
    }
  }
  return &pagetable[PX(0, va)];
}

// Look up a virtual address, return the physical address,
// or 0 if not mapped.
// Can only be used to look up user pages.
uint64
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    return 0;

  pte = walk(pagetable, va, 0);
  if(pte == 0)
    return 0;
  if((*pte & PTE_V) == 0)
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}

// add a mapping to the kernel page table.
// only used when booting.
// does not flush TLB or enable paging.
void
kvmmap(pagetable_t kpgtbl, uint64 va, uint64 pa, uint64 sz, int perm)
{
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    panic("kvmmap");
}

// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
  last = PGROUNDDOWN(va + size - 1);
  for(;;){
    if((pte = walk(pagetable, a, 1)) == 0){
      return -1;
    }
    if(*pte & PTE_V){
      panic("remap");
    }
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(*pte & PTE_PG){ //if paged out, turn off valid flag 
       *pte &= ~PTE_V;
     }
    if(a == last)
      break;
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
}

// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{ 
  printf("In uvmunmap \n"); 
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0 && (*pte & PTE_PG) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
      panic("uvmunmap: not a leaf");
    if(do_free && (*pte & PTE_PG)==0){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;

    #if SELECTION!=NONE
       if(myproc()->pid>2){
         int i =0;
         while(((uint)myproc()->ram_pages.pages[i].virtual_address != a) && i<16){
           i++;
         }
       
        if(i<16){
          myproc()->ram_pages.pages[i].is_used = 0;
          myproc()->ram_pages.pages[i].page_counter = reset_counter();
          #if SELECTION==SCFIFO
            remove_page_from_q(myproc(), i);
          #endif
        }
      }
    #endif
    //TODO : maybe add clean in file fieldss
  }
}

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
  if(pagetable == 0)
    return 0;
  memset(pagetable, 0, PGSIZE);
  return pagetable;
}

// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
  char *mem;

  if(sz >= PGSIZE)
    panic("inituvm: more than a page");
  mem = kalloc();
  memset(mem, 0, PGSIZE);
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
  memmove(mem, src, sz);
}


// task 1 

void
update_pages_counters(){
  struct proc *p = myproc();
  for(int i=0 ; i<MAX_PSYC_PAGES; i++){
    if (p->ram_pages.pages[i].is_used){
      pte_t *pte = walk(p->pagetable,p->ram_pages.pages[i].virtual_address,0);
      p->ram_pages.pages[i].page_counter>>=1; //shift counter right
      if (*pte & PTE_A){
        p->ram_pages.pages[i].page_counter |= 1<<31; //put 1 in the msb
        *pte &= ~PTE_A; //turn off flag
      }
    }
  }
}

//check if there is a free page in ram mem, of so, return it's PSYC addr
int
find_free_page_in_ram(void){
  int free_index=0;
  struct proc *p =  myproc();
  while(free_index<16){
    //finidng free page in swap file memory
    if(!p->ram_pages.pages[free_index].is_used)
      return free_index; 
    else
      free_index++;
  }
  return -1;
}

// for SELECTION=LAPA ; count num of '1' in page counter
uint 
ones_counter(uint page_counter){
  uint ones_counter=0;
  uint page_counter_val=page_counter;
  while (page_counter_val > 0){
    if (page_counter_val % 2 != 0)
      ones_counter++;
    page_counter_val = (page_counter_val >> 1);
  }
  return ones_counter;
}

int
use_NFUA(struct proc *p){
  int min_page_index=-1;
  uint min_page_counter=0xffffffff; //max int value
  for (int i=0; i<MAX_PSYC_PAGES; i++){
    //finidng occupied page in swap file memory
    if(p->ram_pages.pages[i].is_used){
      uint64 a = PGROUNDDOWN(p->ram_pages.pages[i].virtual_address);
      pte_t *pte;
      if(((pte = walk(p->pagetable, a, 0)) != 0) && (*pte & PTE_V)){
        if (p->ram_pages.pages[i].page_counter<min_page_counter){
          min_page_counter=p->ram_pages.pages[i].page_counter;
          min_page_index=i;
        }
      }
    }
  }
  return min_page_index;
}

int
use_LAPA(struct proc *p){
  int min_page_index=0;
  uint min_num_of_ones=0xffffffff; //max int value
  uint min_page_counter=0xffffffff;
  uint same_amount_of_ones_counter=0;
  // find page with minimal appears of '1'
  for (int i=0; i<MAX_PSYC_PAGES; i++){
    uint cur_num_of_ones=0;
    //find occupied page in swap file memory
    if(p->ram_pages.pages[i].is_used){
      uint64 a = PGROUNDDOWN(p->ram_pages.pages[i].virtual_address);
      pte_t *pte;
      if(((pte = walk(p->pagetable, a, 0)) != 0) && (*pte & PTE_V)){
        cur_num_of_ones=ones_counter(p->ram_pages.pages[i].page_counter);
        if (cur_num_of_ones==min_num_of_ones)
          same_amount_of_ones_counter++; //CHECK IF BREAKS OUT TOTALLY
        else if(cur_num_of_ones<min_num_of_ones){
          same_amount_of_ones_counter=1;
          min_page_index=i;
          min_num_of_ones=cur_num_of_ones;
        }
      }
    }
  }
  // find page by minimal counter
  if (same_amount_of_ones_counter>1){
    for (int i=0; i<MAX_PSYC_PAGES; i++){
    //find occupied page in swap file memory
      if(p->ram_pages.pages[i].is_used){
        uint64 a = PGROUNDDOWN(p->ram_pages.pages[i].virtual_address);
        pte_t *pte;
        if(((pte = walk(p->pagetable, a, 0)) != 0) && (*pte & PTE_V)){
          if (p->ram_pages.pages[i].page_counter<min_page_counter ){
            min_page_counter=p->ram_pages.pages[i].page_counter;
            min_page_index=i;
          }
        }
      }
    }
  }
  return min_page_index;
}

int
use_SCFIFO(struct proc *p){
  pte_t *pte;
  int first_not_PU = -1;
  for (int i=0; i< p->ram_pages.q_size; i++){
    int currPageIndex = dequeue(p);
    if(currPageIndex == -1 || currPageIndex > MAX_PSYC_PAGES)
      panic("something wrong in page queue");
    
    struct ram_page curr_page = p->ram_pages.pages[currPageIndex];
    if(curr_page.is_used == 0)
      panic("In use_SCFIFO: unused page in ram_pages");

    //finidng used page in main memory
    pte = walk(p->pagetable, curr_page.virtual_address, 0);

    if((*pte & PTE_U) && !(*pte & PTE_A))
      return currPageIndex;

    if((*pte & PTE_U) && (first_not_PU==-1))
      first_not_PU = currPageIndex;

    insert_to_q(p,currPageIndex);
  }
  if(first_not_PU==-1)
    panic("Second_chance_FIFO_Algo didnt found page");
  remove_page_from_q(p, first_not_PU);
  return first_not_PU;
}

int
find_occupied_page_in_ram(struct proc *p){
  uint occupied_index=0;

  #if SELECTION == NFUA
    occupied_index = use_NFUA(p);

  #elif SELECTION == LAPA
    occupied_index = use_LAPA(p);
  
  #elif SELECTION==SCFIFO
    occupied_index = use_SCFIFO(p);
  #endif

  if( occupied_index > 15){
    //proc has a MAX_PSYC_PAGES pages
    panic("ram memory: somthing's wrong from find occupied page");
  }
  return occupied_index;
}

uint64
find_free_page_in_swapped(void){
  uint sp_index = 0;
  struct proc *p =  myproc();
  while(sp_index<16){
    //finidng occupied page in swap file memory
    if(!p->swapped_pages.pages[sp_index].is_used)
      return sp_index;
    else
      sp_index++;
  }

  //proc has a MAX_PSYC_PAGES pages
  return -1;
}

//moves random page from main memory to swaped file. return ot's free index in the ram array   
uint64
swap(int index){
  struct proc *p = myproc();

  uint sp_index = find_free_page_in_swapped();
  
  uint occupied_index = find_occupied_page_in_ram(p);
  if (occupied_index==-1)
    panic("No occupied_index \n"); 

  uint64 mm_va = p->ram_pages.pages[occupied_index].virtual_address;
  
  pte_t *pte;
  uint64 a = PGROUNDDOWN(mm_va); //opposite from align
  if((pte = walk(p->pagetable, a, 0)) == 0)
    return -1;
  uint64 pa = PTE2PA(*pte);
  
  //printf("writing to page sp_index: %d a_va is: %d mm_va is: %d\n",sp_index,a,mm_va);
  writeToSwapFile(p, (char*)pa, sp_index*PGSIZE, PGSIZE);
  
  p->swapped_pages.pages[sp_index].virtual_address = a;
  p->swapped_pages.pages[sp_index].is_used = 1; 
  p->ram_pages.pages[occupied_index].is_used = 0; //this index is no more occupied
  

  kfree((void*)pa); //Free the page of physical memory

  // update pte flags
  *pte |= PTE_PG; //page is on disc
  *pte &= ~PTE_V; //page is not valid

  return occupied_index; //this physical addres is available now
}

int
init_free_ram_page(pagetable_t pagetable, uint64 va, uint64 pa , int index){
  struct proc *p = myproc();
  uint64 a = PGROUNDDOWN(va);

  if(mappages(pagetable, a, PGSIZE, pa, PTE_W|PTE_X|PTE_R|PTE_U) < 0){
    kfree((void*)pa); //Free the page of physical memory
    uvmdealloc(pagetable, PGSIZE, PGSIZE);
    return 0; //init page failed
  }

  p->ram_pages.pages[index].virtual_address = va; //TODO : or a? 
  p->ram_pages.pages[index].is_used = 1;
  p->ram_pages.pages[index].page_counter=reset_counter();
  #if SELECTION==SCFIFO
    insert_to_q(p,index);
  #endif
  return 1; //success
}

// this method finds the "blank" \the free entry in ram_pages
// and then initiallize it
int    
find_and_init_page(uint64 pa, uint64 va){
  struct proc *p =  myproc();
  int index =0;
  //finidng free page in main memory
  while(index<MAX_PSYC_PAGES){
    if(!p->ram_pages.pages[index].is_used){
      return init_free_ram_page(p->pagetable, va, pa, index);
    }
    index++;
  }
  return -1;
}

void
handle_page_fault(uint64 va){
  struct proc *p = myproc();
  uint64 align_va = PGROUNDDOWN(va);
  int free_pa_index; 
  pte_t *pte = walk(p->pagetable, align_va, 0);
  void * buffer =  kalloc(); 
  
  if(pte == 0){
    panic("in handle_page_fault, page table don't exists \n");
  }
  else if(!(*pte & PTE_PG)){ //enter when flag PTE_PG is off  
    panic("in handle_page_fault, page is not in the swap file");
  }  

  int i = 0; 
  while(i<16){
    uint64 curr_va = (uint64)p->swapped_pages.pages[i].virtual_address;
    if(curr_va == align_va || curr_va == va){
      if(p->swapped_pages.pages[i].is_used){
        break;
      }
    }
    i++; 
  }
  if (i>15){
    panic("in handle_page_fault, page not exists \n"); 
  }

  p->swapped_pages.pages[i].virtual_address = 0;
  p->swapped_pages.pages[i].is_used = 0; 
 
  memset(buffer,0,PGSIZE);
  readFromSwapFile(p, buffer, i*PGSIZE, PGSIZE); //reading page to pa 
  free_pa_index = find_free_page_in_ram(); 
  if (free_pa_index == -1){
    
    free_pa_index = swap(i); 
    if(free_pa_index == -1){
      panic("in handle_page_fault, no unused page in swap file \n");
    }
  }
   *pte &= ~PTE_PG;

  if(!init_free_ram_page(p->pagetable, va, (uint64)buffer, free_pa_index)){
    panic("in Handle_PGFLT, unexpectedly failed to find unused entry in main_mem array of the process");
  }
}

 
// Allocate PTEs and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
uint64
uvmalloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
  char *mem;
  uint64 a;

  if(newsz >= KERNBASE)
    return 0;

  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  #if SELECTION != NONE
    int curr_pages =0; 
    for(int l=0; l<16; l++){
      if(myproc()->ram_pages.pages[l].is_used)
        curr_pages++; 
      if(myproc()->swapped_pages.pages[l].is_used)
        curr_pages++; 
    }

    if (curr_pages == 32){
      panic("In uvmalloc, not enough space for pages"); 
    }
  #endif

  for(; a < newsz; a += PGSIZE){
    mem = kalloc();
    #if SELECTION == NONE
      if(mem == 0){
        uvmdealloc(pagetable, a, oldsz);
        return 0;
    }
    #else
      if(mem == 0){
        kfree(mem);
        uvmdealloc(pagetable, a, oldsz);
        return 0;
    }
    #endif
    memset(mem, 0, PGSIZE);
    // // task 1.1
    if(myproc()->pid > 2){
      #if SELECTION != NONE
        int ram_page_index = find_free_page_in_ram(); 
        if(ram_page_index ==  -1){ //no free ram page
          ram_page_index = swap(-1);
          if (ram_page_index == -1) { // if swap failed
            printf("error: process %d needs more than 32 page, exits...\n", myproc()->pid);
            exit(-1);   
          }          
        }
        init_free_ram_page(pagetable, a, (uint64)mem, ram_page_index); 
      #endif
    }
    else{
      if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
        kfree(mem);
        uvmdealloc(pagetable, a, oldsz);
        return 0;
      }
    }
  }
  return newsz;
}

// Deallocate user pages to bring the process size from oldsz to
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
  if(newsz >= oldsz)
    return oldsz;

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
      freewalk((pagetable_t)child);
      pagetable[i] = 0;
    } else if(pte & PTE_V){
      panic("freewalk: leaf");
    }
  }
  kfree((void*)pagetable);
}

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
  if(sz > 0)
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
}

// Given a parent process's page table, copy
// its memory into a child's page table.
// Copies both the page table and the
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{ 
  printf("In uvmcopy \n"); 
  pte_t *pte;
  pte_t *pte_new;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0 && !(*pte & PTE_PG)){
         panic("uvmcopy: page not present");
     }
     
    if((*pte & PTE_V) == 0 && (*pte & PTE_PG)){
      if((pte_new = walk(new, i, 0))){
        *pte_new &= ~PTE_V;
        *pte_new |= PTE_PG;
      }
    }
    else if(*pte & PTE_V){
      pa = PTE2PA(*pte);
      flags = PTE_FLAGS(*pte);
      if((mem = kalloc()) == 0)
        goto err;
      memmove(mem, (char*)pa, PGSIZE);
      if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
        kfree(mem);
        goto err;
      }
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
  return -1;
}

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
  if(pte == 0)
    panic("uvmclear");
  *pte &= ~PTE_U;
}

// Copy from kernel to user.
// Copy len bytes from src to virtual address dstva in a given page table.
// Return 0 on success, -1 on error.
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    va0 = PGROUNDDOWN(dstva);
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);

    len -= n;
    src += n;
    dstva = va0 + PGSIZE;
  }
  return 0;
}

// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    va0 = PGROUNDDOWN(srcva);
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);

    len -= n;
    dst += n;
    srcva = va0 + PGSIZE;
  }
  return 0;
}

// Copy a null-terminated string from user to kernel.
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    va0 = PGROUNDDOWN(srcva);
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    if(n > max)
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
        got_null = 1;
        break;
      } else {
        *dst = *p;
      }
      --n;
      --max;
      p++;
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    return 0;
  } else {
    return -1;
  }
}

void
insert_to_q(struct proc *p, int pageIndex){
  if(pageIndex >= MAX_PSYC_PAGES || pageIndex< 0 || p->ram_pages.q_size==MAX_PSYC_PAGES){
    panic("somthing wrong in insert_to_q");
  }
  p->ram_pages.fifo_q[p->ram_pages.q_size] = pageIndex;
  p->ram_pages.q_size++;
}

int
dequeue(struct proc *p){
  if(p-> ram_pages.q_size ==0)
    panic("Dequeue is imposible since queue is empty");
  int output = p->ram_pages.fifo_q[0];
  for(int i = 1; i< p->ram_pages.q_size; i++){ 
      p->ram_pages.fifo_q[i-1] = p->ram_pages.fifo_q[i];
  }
  p->ram_pages.fifo_q[p->ram_pages.q_size -1] = -1;
  p->ram_pages.q_size --;
  return output;
}

int
remove_page_from_q(struct proc *p, int pageIndex){
  if(pageIndex >= MAX_PSYC_PAGES || pageIndex< 0){
    panic("somthing wrong in remove_page_from_q");
  }
  int found =0;
  for(int i = 0; i< p->ram_pages.q_size; i++){ 
    if(p->ram_pages.fifo_q[i]==pageIndex){
      //found the page
      found =1;
    }
    else if(found){
      p->ram_pages.fifo_q[i-1] = p->ram_pages.fifo_q[i];
    }
  }
  if(found){
     p->ram_pages.fifo_q[p->ram_pages.q_size -1] = -1;
     p->ram_pages.q_size  --;
  }
  return found;
}

void
CleanQueue(struct proc *p){
  for(int i = 0; i < 16; i++){
      p->ram_pages.fifo_q[i]=-1;
    }
    p->ram_pages.q_size = 0;
}



