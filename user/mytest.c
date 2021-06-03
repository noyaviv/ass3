#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/param.h"


#define CHILD_NUM 2
#define PGSIZE 4096
#define MEM_SIZE 10000
#define SZ 1200


void exec_test() {
    
    if (!fork()) {
        printf("allocating pages\n");
        int *arr = (int *) (malloc(sizeof(int) * 5 * PGSIZE));
        for (int i = 0; i < 5 * PGSIZE; i = i + PGSIZE) {
            arr[i] = i / PGSIZE;
        }
        printf("forking\n");
        int pid = fork();
        if (!pid) {
            char *argv[] = {"myMemTest", "exectest", 0};
            exec(argv[0], argv);
        } else {
            wait(0);
        }
        exit(0);
    } else {
        wait(0);
    }
    
}

void exec_test_child() {
    printf("child allocating pages\n");
    int *arr = (int *) (malloc(sizeof(int) * 5 * PGSIZE));
    for (int i = 0; i < 5 * PGSIZE; i = i + PGSIZE) {
        arr[i] = i / PGSIZE;
    }
    printf("child exiting\n");
}


void run_test() {
    printf("test - start\n");

    // Allocate an array to write to.
    char* mem = (char*)(malloc(sizeof(char) * PGSIZE * 16));
    for(int i = PGSIZE; i < PGSIZE * 5; ++i) {
        mem[i] = 1;
    }

    int pid;
    int pid1;

    if( (pid = fork()) == 0 ) {
        
        printf("fork - child\n");
        if( (pid1 = fork()) == 0 ) {
            for (int i = PGSIZE * 5; i < PGSIZE * 10; ++i) {
                mem[i] = 1;
            }
            exit(0);
        } else {
            wait(0);
            printf("child finishes - exec ls\n");
            char *argv[] = {"ls", 0};
            exec(argv[0], argv);
        }
    } else {
        wait(0);
    }
    printf("test - end\n");
}

int main(int argc, char **argv) {
    run_test();
    printf("hey i am sweating\n");
    exit(0);
}