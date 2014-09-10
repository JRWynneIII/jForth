.macro NEXT
lodsl
jmp *(%eax)
.endm

.macro PUSHRSP reg
lea -4(%ebp),%ebp
movl \reg,(%ebp)
.endm

.macro POPRSP reg
mov (%ebp),\reg
lea 4(%ebp),%ebp
.endm

/* DOCOL: the interpreter function */

  .text
  .align 4

DOCOL :
  PUSHRSP %esi /*Push esi onto the return stack. I think esi is the current instruction pointer?*/
  addl $4,%eax  /*eax points to the codeword so make */
  movl %eax,%esi  /*esi point to the first data word*/
  NEXT

/* Assembler entry point */

  .text
  .globl _start

_start :
  cld
  mov %esp,var_SO /*save initial data stack pointer in forth variable SO*/
  mov $return_stack_top,%ebp  /*Initialize the return stack*/
  call set_up_data_segment
  mov $cold_start,%esi  /*Initialize the interpreter*/
  NEXT  /*Run the interpreter!!!*/

  .section .rodata

cold_start : /*high level code without a codeword*/
  .int QUIT
  .set F_IMMED,0x80
  .set F_HIDDEN,0x20
  .set F_LENMASK,0x1f   /*length mask*/

  /*store chain of links*/
  .set link,0
  .macro defword name, namelen, flags=0, label
  .section .rodata
  .align 4
  .globl name_\label

name_\label :
  .int link /*link*/
  .set link,name_\label
  .byte \flags+\namelen /*flags + length byte*/
  .ascii "\name"  /*the name*/
  .align 4
  .globl \label
  
\label :
  .int DOCOL  /*codeword - the interpreter*/
  /*list of word pointers follows*/
  .endm

  .macro defcode name, namelen, flags=0, label
  .section .rodata
  .align 4
  .globl name_\label
name_\label : 
  .int link
  .set link,name_\label:
  .byte \flags+\namelen
  .ascii "\name"
  .align 4
  .globl \label
\label :
  .int code_\label
  .text
  //.align 4
  .globl code_\label
code_\label :  /*assembler code follows*/
  .endm

  defcode "DROP",4,,DROP
  pop %eax
  NEXT

  defcode "SWAP",4,,SWAP
  pop %eax
  pop %ebx
  push %eax
  push $ebx
  NEXT

  defcode "DUP",3,,DUP
  mov (%esp),%eax
  push %eax
  NEXT


