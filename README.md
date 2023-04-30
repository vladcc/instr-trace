# instr-trace
collect the currently executing instructions of a running process with gdb

Example:

Compile a trivial program which sleeps for one microsecond at a time.
```
$ cat example.c 
#include <unistd.h>

void snooze(void)
{
        usleep(1);
}

int main(int argc, char * argv[])
{
        while (1)
                snooze();

        return 0;
}

$ gcc example.c -o example
```

Run it in the background.
```
$ ./example &
[1] 36877

$ pidof example
36877

$ ps -o pid,cmd,%cpu $(pidof example)
    PID CMD                         %CPU
  36877 ./example                    7.2
```

Collect the execution trace.
```
$ bash instr-trace.sh 
Use: instr-trace.sh <pid> <number-of-instrucions>

$ bash instr-trace.sh $(pidof example) 10000
instr-trace.sh: trace file is gdb.36877.itrace

$ cat gdb.36877.itrace | wc -l
10000

$ cat gdb.36877.itrace | head -n 5
=> 0x7fc1aa4e57fa <__GI___clock_nanosleep+90>:  mov    rbp,rax
=> 0x7fc1aa4e57fa <__GI___clock_nanosleep+90>:  mov    rbp,rax
=> 0x7fc1aa4e57fd <__GI___clock_nanosleep+93>:  mov    r15d,ebp
=> 0x7fc1aa4e5800 <__GI___clock_nanosleep+96>:  cmp    ebp,0xffffffea
=> 0x7fc1aa4e5803 <__GI___clock_nanosleep+99>:  jne    0x7fc1aa4e5809 <__GI___clock_nanosleep+105>
```

Make it more useful.

1. See only internal code, i.e. in main() and snooze()
```
$ cat gdb.36877.itrace | sort | uniq -c | grep -E 'main|snooze'
    110 => 0x562c80b97149 <snooze>:     endbr64 
    110 => 0x562c80b9714d <snooze+4>:   push   rbp
    110 => 0x562c80b9714e <snooze+5>:   mov    rbp,rsp
    110 => 0x562c80b97151 <snooze+8>:   mov    edi,0x1
    110 => 0x562c80b97156 <snooze+13>:  call   0x562c80b97050 <usleep@plt>
    110 => 0x562c80b9715b <snooze+18>:  nop
    110 => 0x562c80b9715c <snooze+19>:  pop    rbp
    110 => 0x562c80b9715d <snooze+20>:  ret    
    110 => 0x562c80b97171 <main+19>:    call   0x562c80b97149 <snooze>
    110 => 0x562c80b97176 <main+24>:    jmp    0x562c80b97171 <main+19>
```

2. See the whole execution loop
```
$ cat gdb.36877.itrace | sort | uniq -c | wc -l
91

$ cat gdb.36877.itrace | sort | uniq -c 
    110 => 0x562c80b97050 <usleep@plt>: endbr64 
    110 => 0x562c80b97054 <usleep@plt+4>:       bnd jmp QWORD PTR [rip+0x2f75]        # 0x562c80b99fd0 <usleep@got[plt]>
    110 => 0x562c80b97149 <snooze>:     endbr64 
    110 => 0x562c80b9714d <snooze+4>:   push   rbp
    110 => 0x562c80b9714e <snooze+5>:   mov    rbp,rsp
    110 => 0x562c80b97151 <snooze+8>:   mov    edi,0x1
    110 => 0x562c80b97156 <snooze+13>:  call   0x562c80b97050 <usleep@plt>
    110 => 0x562c80b9715b <snooze+18>:  nop
    110 => 0x562c80b9715c <snooze+19>:  pop    rbp
    110 => 0x562c80b9715d <snooze+20>:  ret    
    110 => 0x562c80b97171 <main+19>:    call   0x562c80b97149 <snooze>
    110 => 0x562c80b97176 <main+24>:    jmp    0x562c80b97171 <main+19>
    110 => 0x7fc1aa4e57a0 <__GI___clock_nanosleep>:     endbr64 
    110 => 0x7fc1aa4e57a4 <__GI___clock_nanosleep+4>:   push   r15
    110 => 0x7fc1aa4e57a6 <__GI___clock_nanosleep+6>:   push   r14
    110 => 0x7fc1aa4e57a8 <__GI___clock_nanosleep+8>:   push   r13
    110 => 0x7fc1aa4e57aa <__GI___clock_nanosleep+10>:  push   r12
    110 => 0x7fc1aa4e57ac <__GI___clock_nanosleep+12>:  push   rbp
    110 => 0x7fc1aa4e57ad <__GI___clock_nanosleep+13>:  push   rbx
    110 => 0x7fc1aa4e57ae <__GI___clock_nanosleep+14>:  sub    rsp,0x48
    110 => 0x7fc1aa4e57b2 <__GI___clock_nanosleep+18>:  mov    rax,QWORD PTR fs:0x28
    110 => 0x7fc1aa4e57bb <__GI___clock_nanosleep+27>:  mov    QWORD PTR [rsp+0x38],rax
    110 => 0x7fc1aa4e57c0 <__GI___clock_nanosleep+32>:  xor    eax,eax
    110 => 0x7fc1aa4e57c2 <__GI___clock_nanosleep+34>:  cmp    edi,0x3
    110 => 0x7fc1aa4e57c5 <__GI___clock_nanosleep+37>:  je     0x7fc1aa4e58d0 <__GI___clock_nanosleep+304>
    110 => 0x7fc1aa4e57cb <__GI___clock_nanosleep+43>:  mov    r13d,esi
    110 => 0x7fc1aa4e57ce <__GI___clock_nanosleep+46>:  mov    r12,rdx
    110 => 0x7fc1aa4e57d1 <__GI___clock_nanosleep+49>:  mov    r14,rcx
    110 => 0x7fc1aa4e57d4 <__GI___clock_nanosleep+52>:  cmp    edi,0x2
    109 => 0x7fc1aa4e57d7 <__GI___clock_nanosleep+55>:  je     0x7fc1aa4e5838 <__GI___clock_nanosleep+152>
    109 => 0x7fc1aa4e57d9 <__GI___clock_nanosleep+57>:  test   edi,edi
    109 => 0x7fc1aa4e57db <__GI___clock_nanosleep+59>:  sete   bl
    109 => 0x7fc1aa4e57de <__GI___clock_nanosleep+62>:  mov    eax,DWORD PTR fs:0x18
    109 => 0x7fc1aa4e57e6 <__GI___clock_nanosleep+70>:  test   eax,eax
    109 => 0x7fc1aa4e57e8 <__GI___clock_nanosleep+72>:  jne    0x7fc1aa4e5848 <__GI___clock_nanosleep+168>
    109 => 0x7fc1aa4e57ea <__GI___clock_nanosleep+74>:  mov    r10,r14
    109 => 0x7fc1aa4e57ed <__GI___clock_nanosleep+77>:  mov    rdx,r12
    109 => 0x7fc1aa4e57f0 <__GI___clock_nanosleep+80>:  mov    esi,r13d
    109 => 0x7fc1aa4e57f3 <__GI___clock_nanosleep+83>:  mov    eax,0xe6
    109 => 0x7fc1aa4e57f8 <__GI___clock_nanosleep+88>:  syscall 
    111 => 0x7fc1aa4e57fa <__GI___clock_nanosleep+90>:  mov    rbp,rax
    110 => 0x7fc1aa4e57fd <__GI___clock_nanosleep+93>:  mov    r15d,ebp
    110 => 0x7fc1aa4e5800 <__GI___clock_nanosleep+96>:  cmp    ebp,0xffffffea
    110 => 0x7fc1aa4e5803 <__GI___clock_nanosleep+99>:  jne    0x7fc1aa4e5809 <__GI___clock_nanosleep+105>
    110 => 0x7fc1aa4e5809 <__GI___clock_nanosleep+105>: neg    r15d
    110 => 0x7fc1aa4e580c <__GI___clock_nanosleep+108>: mov    rax,QWORD PTR [rsp+0x38]
    110 => 0x7fc1aa4e5811 <__GI___clock_nanosleep+113>: sub    rax,QWORD PTR fs:0x28
    110 => 0x7fc1aa4e581a <__GI___clock_nanosleep+122>: jne    0x7fc1aa4e5963 <__GI___clock_nanosleep+451>
    110 => 0x7fc1aa4e5820 <__GI___clock_nanosleep+128>: add    rsp,0x48
    110 => 0x7fc1aa4e5824 <__GI___clock_nanosleep+132>: mov    eax,r15d
    110 => 0x7fc1aa4e5827 <__GI___clock_nanosleep+135>: pop    rbx
    110 => 0x7fc1aa4e5828 <__GI___clock_nanosleep+136>: pop    rbp
    110 => 0x7fc1aa4e5829 <__GI___clock_nanosleep+137>: pop    r12
    110 => 0x7fc1aa4e582b <__GI___clock_nanosleep+139>: pop    r13
    110 => 0x7fc1aa4e582d <__GI___clock_nanosleep+141>: pop    r14
    110 => 0x7fc1aa4e582f <__GI___clock_nanosleep+143>: pop    r15
    110 => 0x7fc1aa4e5831 <__GI___clock_nanosleep+145>: ret    
    110 => 0x7fc1aa4ea6d0 <__GI___nanosleep>:   endbr64 
    110 => 0x7fc1aa4ea6d4 <__GI___nanosleep+4>: sub    rsp,0x8
    110 => 0x7fc1aa4ea6d8 <__GI___nanosleep+8>: mov    rdx,rdi
    110 => 0x7fc1aa4ea6db <__GI___nanosleep+11>:        mov    rcx,rsi
    110 => 0x7fc1aa4ea6de <__GI___nanosleep+14>:        xor    edi,edi
    110 => 0x7fc1aa4ea6e0 <__GI___nanosleep+16>:        xor    esi,esi
    110 => 0x7fc1aa4ea6e2 <__GI___nanosleep+18>:        call   0x7fc1aa4e57a0 <__GI___clock_nanosleep>
    110 => 0x7fc1aa4ea6e7 <__GI___nanosleep+23>:        test   eax,eax
    110 => 0x7fc1aa4ea6e9 <__GI___nanosleep+25>:        jne    0x7fc1aa4ea6f0 <__GI___nanosleep+32>
    110 => 0x7fc1aa4ea6eb <__GI___nanosleep+27>:        add    rsp,0x8
    110 => 0x7fc1aa4ea6ef <__GI___nanosleep+31>:        ret    
    110 => 0x7fc1aa51c090 <usleep>:     endbr64 
    110 => 0x7fc1aa51c094 <usleep+4>:   sub    rsp,0x28
    110 => 0x7fc1aa51c098 <usleep+8>:   xor    esi,esi
    110 => 0x7fc1aa51c09a <usleep+10>:  mov    rax,QWORD PTR fs:0x28
    110 => 0x7fc1aa51c0a3 <usleep+19>:  mov    QWORD PTR [rsp+0x18],rax
    110 => 0x7fc1aa51c0a8 <usleep+24>:  xor    eax,eax
    110 => 0x7fc1aa51c0aa <usleep+26>:  mov    eax,edi
    110 => 0x7fc1aa51c0ac <usleep+28>:  imul   rax,rax,0x431bde83
    110 => 0x7fc1aa51c0b3 <usleep+35>:  shr    rax,0x32
    110 => 0x7fc1aa51c0b7 <usleep+39>:  movd   xmm0,eax
    110 => 0x7fc1aa51c0bb <usleep+43>:  imul   eax,eax,0xf4240
    110 => 0x7fc1aa51c0c1 <usleep+49>:  sub    edi,eax
    110 => 0x7fc1aa51c0c3 <usleep+51>:  imul   rdi,rdi,0x3e8
    110 => 0x7fc1aa51c0ca <usleep+58>:  movq   xmm1,rdi
    110 => 0x7fc1aa51c0cf <usleep+63>:  mov    rdi,rsp
    110 => 0x7fc1aa51c0d2 <usleep+66>:  punpcklqdq xmm0,xmm1
    110 => 0x7fc1aa51c0d6 <usleep+70>:  movaps XMMWORD PTR [rsp],xmm0
    110 => 0x7fc1aa51c0da <usleep+74>:  call   0x7fc1aa4ea6d0 <__GI___nanosleep>
    110 => 0x7fc1aa51c0df <usleep+79>:  mov    rdx,QWORD PTR [rsp+0x18]
    110 => 0x7fc1aa51c0e4 <usleep+84>:  sub    rdx,QWORD PTR fs:0x28
    110 => 0x7fc1aa51c0ed <usleep+93>:  jne    0x7fc1aa51c0f4 <usleep+100>
    110 => 0x7fc1aa51c0ef <usleep+95>:  add    rsp,0x28
    110 => 0x7fc1aa51c0f3 <usleep+99>:  ret
```
