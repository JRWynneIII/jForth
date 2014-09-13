.set JONES_VERSION,47

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
  mov %esp,var_S0 /*save initial data stack pointer in forth variable SO*/
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
  .set link,name_\label
  .byte \flags+\namelen
  .ascii "\name"
  .align 4
  .globl \label
\label :
  .int code_\label
  .text
  //.align 4
  .globl code_\label
code_\label :  
  .endm

  defcode "DROP",4,,DROP
  pop %eax
  NEXT

  defcode "SWAP",4,,SWAP
  pop %eax
  pop %ebx
  push %eax
  push %ebx
  NEXT

  defcode "DUP",3,,DUP
  mov (%esp),%eax
  push %eax
  NEXT

  defcode "OVER",4,,OVER
  mov 4(%esp),%eax
  push %eax
  NEXT

  defcode "ROT",3,,ROT
  pop %eax
  pop %ebx
  pop %ecx
  push %ebx
  push %eax
  push %ecx
  NEXT

  defcode "-ROT",4,,NROT
  pop %eax
  pop %ebx
  pop %ecx
  push %eax
  push %ecx
  push %ebx
  NEXT
  
  defcode "2DROP",5,,TWODROP
  pop %eax
  pop %eax
  NEXT

  defcode "2DUP",4,,TWODUP
  mov (%esp),%eax
  mov 4(%esp),%ebx
  push %ebx
  push %eax
  NEXT

  defcode "2SWAP",5,,TWOSWAP 
  pop %eax
  pop %ebx
  pop %ecx
  pop %edx
  push %ebx
  push %eax
  push %edx
  push %ecx
  NEXT

  defcode "?DUP",4,,QDUP
  movl (%esp),%eax
  test %eax,%eax
  jz 1f
  push %eax
1: NEXT

  defcode "1+",2,,INCR
  incl (%esp)   
  NEXT

  defcode "1-",2,,DECR
  decl (%esp)  
  NEXT

  defcode "4+",2,,INCR4
  addl $4,(%esp)   
  NEXT

  defcode "4-",2,,DECR4
  subl $4,(%esp)  
  NEXT

  defcode "+",1,,ADD
  pop %eax   
  addl %eax,(%esp)
  NEXT

  defcode "-",1,,SUB
  pop %eax   
  subl %eax,(%esp)
  NEXT

  defcode "*",1,,MUL
  pop %eax
  pop %ebx
  imull %ebx,%eax
  push %eax  
  NEXT

  defcode "/MOD",4,,DIVMOD
  xor %edx,%edx
  pop %ebx
  pop %eax
  idivl %ebx
  push %edx   // push remainder
  push %eax   // push quotient
  NEXT

  defcode "=",1,,EQU  // top two words are equal?
  pop %eax
  pop %ebx
  cmp %ebx,%eax
  sete %al
  movzbl %al,%eax
  pushl %eax
  NEXT

  defcode "<>",2,,NEQU  // top two words are not equal?
  pop %eax
  pop %ebx
  cmp %ebx,%eax
  setne %al
  movzbl %al,%eax
  pushl %eax
  NEXT

  defcode "<",1,,LT
  pop %eax
  pop %ebx
  cmp %eax,%ebx
  setl %al
  movzbl %al,%eax
  pushl %eax
  NEXT

  defcode ">",1,,GT
  pop %eax
  pop %ebx
  cmp %eax,%ebx
  setg %al
  movzbl %al,%eax
  pushl %eax
  NEXT

  defcode "<=",2,,LE
  pop %eax
  pop %ebx
  cmp %eax,%ebx
  setle %al
  movzbl %al,%eax
  pushl %eax
  NEXT

  defcode ">=",2,,GE
  pop %eax
  pop %ebx
  cmp %eax,%ebx
  setge %al
  movzbl %al,%eax
  pushl %eax
  NEXT

  defcode "0=",2,,ZEQU  // top of stack equals 0?
  pop %eax
  test %eax,%eax
  setz %al
  movzbl %al,%eax
  pushl %eax
  NEXT

  defcode "0<>",3,,ZNEQU  // top of stack not 0?
  pop %eax
  test %eax,%eax
  setnz %al
  movzbl %al,%eax
  pushl %eax
  NEXT

  defcode "0<",2,,ZLT // comparisons with 0
  pop %eax
  test %eax,%eax
  setl %al
  movzbl %al,%eax
  pushl %eax
  NEXT

  defcode "0>",2,,ZGT
  pop %eax
  test %eax,%eax
  setg %al
  movzbl %al,%eax
  pushl %eax
  NEXT

  defcode "0<=",3,,ZLE
  pop %eax
  test %eax,%eax
  setle %al
  movzbl %al,%eax
  pushl %eax
  NEXT

  defcode "0>=",3,,ZGE
  pop %eax
  test %eax,%eax
  setge %al
  movzbl %al,%eax
  pushl %eax
  NEXT

  defcode "AND",3,,AND  // bitwise AND
  pop %eax
  andl %eax,(%esp)
  NEXT

  defcode "OR",2,,OR  // bitwise OR
  pop %eax
  orl %eax,(%esp)
  NEXT

  defcode "XOR",3,,XOR  // bitwise XOR
  pop %eax
  xorl %eax,(%esp)
  NEXT

  defcode "INVERT",6,,INVERT // this is the FORTH bitwise "NOT" function (cf. NEGATE and NOT)
  notl (%esp)
  NEXT
   
  defcode "EXIT",4,,EXIT
  POPRSP %esi   // pop return stack into %esi
  NEXT

  defcode "LIT",3,,LIT
  // %esi points to the next command, but in this case it points to the next
  // literal 32 bit integer.  Get that literal into %eax and increment %esi.
  // On x86, it's a convenient single byte instruction!  (cf. NEXT macro)
  lodsl
  push %eax   // push the literal number on to stack
  NEXT

  defcode "!",1,,STORE
  pop %ebx    // address to store at
  pop %eax    // data to store there
  mov %eax,(%ebx)   // store it
  NEXT

  defcode "@",1,,FETCH
  pop %ebx    // address to fetch
  mov (%ebx),%eax   // fetch it
  push %eax   // push value onto stack
  NEXT

  defcode "+!",2,,ADDSTORE
  pop %ebx    // address
  pop %eax    // the amount to add
  addl %eax,(%ebx)  // add it
  NEXT

  defcode "-!",2,,SUBSTORE
  pop %ebx    // address
  pop %eax    // the amount to subtract
  subl %eax,(%ebx)  // add it
  NEXT

  defcode "C!",2,,STOREBYTE
  pop %ebx    // address to store at
  pop %eax    // data to store there
  movb %al,(%ebx)   // store it
  NEXT

  defcode "C@",2,,FETCHBYTE
  pop %ebx    // address to fetch
  xor %eax,%eax
  movb (%ebx),%al   // fetch it
  push %eax   // push value onto stack
  NEXT

/* C@C! is a useful byte copy primitive. */
  defcode "C@C!",4,,CCOPY
  movl 4(%esp),%ebx // source address
  movb (%ebx),%al   // get source character
  pop %edi    // destination address
  stosb     // copy to destination
  push %edi   // increment destination address
  incl 4(%esp)    // increment source address
  NEXT

/* and CMOVE is a block copy operation. */
  defcode "CMOVE",5,,CMOVE
  mov %esi,%edx   // preserve %esi
  pop %ecx    // length
  pop %edi    // destination address
  pop %esi    // source address
  rep movsb   // copy source to destination
  mov %edx,%esi   // restore %esi
  NEXT


  .macro defvar name, namelen, flags=0, label, initial=0
  defcode \name,\namelen,\flags,\label
  push $var_\name
  NEXT
  .data
  .align 4
var_\name :
  .int \initial
  .endm

  defvar "STATE",5,,STATE
  defvar "HERE",4,,HERE
  defvar "LATEST",6,,LATEST,name_SYSCALL0 // SYSCALL0 must be last in built-in dictionary
  defvar "S0",2,,SZ
  defvar "BASE",4,,BASE,10

  .macro defconst name, namelen, flags=0, label, value
  defcode \name,\namelen,\flags,\label
  push $\value
  NEXT
  .endm
#include <asm/unistd.h>
  defconst "VERSION",7,,VERSION,JONES_VERSION
  defconst "R0",2,,RZ,return_stack_top
  defconst "DOCOL",5,,__DOCOL,DOCOL
  defconst "F_IMMED",7,,__F_IMMED,F_IMMED
  defconst "F_HIDDEN",8,,__F_HIDDEN,F_HIDDEN
  defconst "F_LENMASK",9,,__F_LENMASK,F_LENMASK

  defconst "SYS_EXIT",8,,SYS_EXIT,__NR_exit
  defconst "SYS_OPEN",8,,SYS_OPEN,__NR_open
  defconst "SYS_CLOSE",9,,SYS_CLOSE,__NR_close
  defconst "SYS_READ",8,,SYS_READ,__NR_read
  defconst "SYS_WRITE",9,,SYS_WRITE,__NR_write
  defconst "SYS_CREAT",9,,SYS_CREAT,__NR_creat
  defconst "SYS_BRK",7,,SYS_BRK,__NR_brk

  defconst "O_RDONLY",8,,__O_RDONLY,0
  defconst "O_WRONLY",8,,__O_WRONLY,1
  defconst "O_RDWR",6,,__O_RDWR,2
  defconst "O_CREAT",7,,__O_CREAT,0100
  defconst "O_EXCL",6,,__O_EXCL,0200
  defconst "O_TRUNC",7,,__O_TRUNC,01000
  defconst "O_APPEND",8,,__O_APPEND,02000
  defconst "O_NONBLOCK",10,,__O_NONBLOCK,04000

  defcode ">R",2,,TOR
  pop %eax    // pop parameter stack into %eax
  PUSHRSP %eax    // push it on to the return stack
  NEXT

  defcode "R>",2,,FROMR
  POPRSP %eax   // pop return stack on to %eax
  push %eax   // and push on to parameter stack
  NEXT

  defcode "RSP@",4,,RSPFETCH
  push %ebp
  NEXT

  defcode "RSP!",4,,RSPSTORE
  pop %ebp
  NEXT

  defcode "RDROP",5,,RDROP
  addl $4,%ebp    // pop return stack and throw away
  NEXT

  defcode "DSP@",4,,DSPFETCH
  mov %esp,%eax
  push %eax
  NEXT

  defcode "DSP!",4,,DSPSTORE
  pop %esp
  NEXT

  defcode "KEY",3,,KEY
  call _KEY
  push %eax   // push return value on stack
  NEXT
_KEY:
  mov (currkey),%ebx
  cmp (bufftop),%ebx
  jge 1f      // exhausted the input buffer?
  xor %eax,%eax
  mov (%ebx),%al    // get next key from input buffer
  inc %ebx
  mov %ebx,(currkey)  // increment currkey
  ret

1:  // Out of input; use read(2) to fetch more input from stdin.
  xor %ebx,%ebx   // 1st param: stdin
  mov $buffer,%ecx  // 2nd param: buffer
  mov %ecx,currkey
  mov $BUFFER_SIZE,%edx // 3rd param: max length
  mov $__NR_read,%eax // syscall: read
  int $0x80
  test %eax,%eax    // If %eax <= 0, then exit.
  jbe 2f
  addl %eax,%ecx    // buffer+%eax = bufftop
  mov %ecx,bufftop
  jmp _KEY

2:  // Error or end of input: exit the program.
  xor %ebx,%ebx
  mov $__NR_exit,%eax // syscall: exit
  int $0x80

  .data
  .align 4
currkey:
  .int buffer   // Current place in input buffer (next character to read).
bufftop:
  .int buffer   // Last valid data in input buffer + 1.

  defcode "EMIT",4,,EMIT
  pop %eax
  call _EMIT
  NEXT
_EMIT:
  mov $1,%ebx   // 1st param: stdout

  // write needs the address of the byte to write
  mov %al,emit_scratch
  mov $emit_scratch,%ecx  // 2nd param: address

  mov $1,%edx   // 3rd param: nbytes = 1

  mov $__NR_write,%eax  // write syscall
  int $0x80
  ret

  .data     // NB: easier to fit in the .data section
emit_scratch:
  .space 1    // scratch used by EMIT

  defcode "WORD",4,,WORD
  call _WORD
  push %edi   // push base address
  push %ecx   // push length
  NEXT

_WORD:
  /* Search for first non-blank character.  Also skip \ comments. */
1:
  call _KEY   // get next key, returned in %eax
  cmpb $'\\',%al    // start of a comment?
  je 3f     // if so, skip the comment
  cmpb $' ',%al
  jbe 1b      // if so, keep looking

  /* Search for the end of the word, storing chars as we go. */
  mov $word_buffer,%edi // pointer to return buffer
2:
  stosb     // add character to return buffer
  call _KEY   // get next key, returned in %al
  cmpb $' ',%al   // is blank?
  ja 2b     // if not, keep looping

  /* Return the word (well, the static buffer) and length. */
  sub $word_buffer,%edi
  mov %edi,%ecx   // return length of the word
  mov $word_buffer,%edi // return address of the word
  ret

  /* Code to skip \ comments to end of the current line. */
3:
  call _KEY
  cmpb $'\n',%al    // end of line yet?
  jne 3b
  jmp 1b

  .data     // NB: easier to fit in the .data section
  // A static buffer where WORD returns.  Subsequent calls
  // overwrite this buffer.  Maximum word length is 32 chars.
word_buffer:
  .space 32

  defcode "NUMBER",6,,NUMBER
  pop %ecx    // length of string
  pop %edi    // start address of string
  call _NUMBER
  push %eax   // parsed number
  push %ecx   // number of unparsed characters (0 = no error)
  NEXT

_NUMBER:
  xor %eax,%eax
  xor %ebx,%ebx

  test %ecx,%ecx    // trying to parse a zero-length string is an error, but will return 0.
  jz 5f

  movl var_BASE,%edx  // get BASE (in %dl)

  // Check if first character is '-'.
  movb (%edi),%bl   // %bl = first character in string
  inc %edi
  push %eax   // push 0 on stack
  cmpb $'-',%bl   // negative number?
  jnz 2f
  pop %eax
  push %ebx   // push <> 0 on stack, indicating negative
  dec %ecx
  jnz 1f
  pop %ebx    // error: string is only '-'.
  movl $1,%ecx
  ret

  // Loop reading digits.
1:  imull %edx,%eax   // %eax *= BASE
  movb (%edi),%bl   // %bl = next character in string
  inc %edi

  // Convert 0-9, A-Z to a number 0-35.
2:  subb $'0',%bl   // < '0'?
  jb 4f
  cmp $10,%bl   // <= '9'?
  jb 3f
  subb $17,%bl    // < 'A'? (17 is 'A'-'0')
  jb 4f
  addb $10,%bl

3:  cmp %dl,%bl   // >= BASE?
  jge 4f

  // OK, so add it to %eax and loop.
  add %ebx,%eax
  dec %ecx
  jnz 1b

  // Negate the result if first character was '-' (saved on the stack).
4:  pop %ebx
  test %ebx,%ebx
  jz 5f
  neg %eax

5:  ret


  defcode "FIND",4,,FIND
  pop %ecx    // %ecx = length
  pop %edi    // %edi = address
  call _FIND
  push %eax   // %eax = address of dictionary entry (or NULL)
  NEXT

_FIND:
  push %esi   // Save %esi so we can use it in string comparison.

  // Now we start searching backwards through the dictionary for this word.
  mov var_LATEST,%edx // LATEST points to name header of the latest word in the dictionary
1:  test %edx,%edx    // NULL pointer?  (end of the linked list)
  je 4f

  // Compare the length expected and the length of the word.
  // Note that if the F_HIDDEN flag is set on the word, then by a bit of trickery
  // this won't pick the word (the length will appear to be wrong).
  xor %eax,%eax
  movb 4(%edx),%al  // %al = flags+length field
  andb $(F_HIDDEN|F_LENMASK),%al // %al = name length
  cmpb %cl,%al    // Length is the same?
  jne 2f

  // Compare the strings in detail.
  push %ecx   // Save the length
  push %edi   // Save the address (repe cmpsb will move this pointer)
  lea 5(%edx),%esi  // Dictionary string we are checking against.
  repe cmpsb    // Compare the strings.
  pop %edi
  pop %ecx
  jne 2f      // Not the same.

  // The strings are the same - return the header pointer in %eax
  pop %esi
  mov %edx,%eax
  ret

2:  mov (%edx),%edx   // Move back through the link field to the previous word
  jmp 1b      // .. and loop.

4:  // Not found.
  pop %esi
  xor %eax,%eax   // Return zero to indicate not found.
  ret

  defcode ">CFA",4,,TCFA
  pop %edi
  call _TCFA
  push %edi
  NEXT
_TCFA:
  xor %eax,%eax
  add $4,%edi   // Skip link pointer.
  movb (%edi),%al   // Load flags+len into %al.
  inc %edi    // Skip flags+len byte.
  andb $F_LENMASK,%al // Just the length, not the flags.
  add %eax,%edi   // Skip the name.
  addl $3,%edi    // The codeword is 4-byte aligned.
  andl $~3,%edi
  ret


  defword ">DFA",4,,TDFA
  .int TCFA   // >CFA   (get code field address)
  .int INCR4    // 4+   (add 4 to it to get to next word)
  .int EXIT   // EXIT   (return from FORTH word)

  defcode "CREATE",6,,CREATE

  // Get the name length and address.
  pop %ecx    // %ecx = length
  pop %ebx    // %ebx = address of name

  // Link pointer.
  movl var_HERE,%edi  // %edi is the address of the header
  movl var_LATEST,%eax  // Get link pointer
  stosl     // and store it in the header.

  // Length byte and the word itself.
  mov %cl,%al   // Get the length.
  stosb     // Store the length/flags byte.
  push %esi
  mov %ebx,%esi   // %esi = word
  rep movsb   // Copy the word
  pop %esi
  addl $3,%edi    // Align to next 4 byte boundary.
  andl $~3,%edi

  // Update LATEST and HERE.
  movl var_HERE,%eax
  movl %eax,var_LATEST
  movl %edi,var_HERE
  NEXT

  defcode ",",1,,COMMA
  pop %eax    // Code pointer to store.
  call _COMMA
  NEXT
_COMMA:
  movl var_HERE,%edi  // HERE
  stosl     // Store it.
  movl %edi,var_HERE  // Update HERE (incremented)
  ret

  defcode "[",1,F_IMMED,LBRAC
  xor %eax,%eax
  movl %eax,var_STATE // Set STATE to 0.
  NEXT

  defcode "]",1,,RBRAC
  movl $1,var_STATE // Set STATE to 1.
  NEXT

  defword ":",1,,COLON
  .int WORD   // Get the name of the new word
  .int CREATE   // CREATE the dictionary entry / header
  .int LIT, DOCOL, COMMA  // Append DOCOL  (the codeword).
  .int LATEST, FETCH, HIDDEN // Make the word hidden (see below for definition).
  .int RBRAC    // Go into compile mode.
  .int EXIT   // Return from the function.

  defword ";",1,F_IMMED,SEMICOLON
  .int LIT, EXIT, COMMA // Append EXIT (so the word will return).
  .int LATEST, FETCH, HIDDEN // Toggle hidden flag -- unhide the word (see below for definition).
  .int LBRAC    // Go back to IMMEDIATE mode.
  .int EXIT   // Return from the function.

  defcode "IMMEDIATE",9,F_IMMED,IMMEDIATE
  movl var_LATEST,%edi  // LATEST word.
  addl $4,%edi    // Point to name/flags byte.
  xorb $F_IMMED,(%edi)  // Toggle the IMMED bit.
  NEXT

  defcode "HIDDEN",6,,HIDDEN
  pop %edi    // Dictionary entry.
  addl $4,%edi    // Point to name/flags byte.
  xorb $F_HIDDEN,(%edi) // Toggle the HIDDEN bit.
  NEXT

  defword "HIDE",4,,HIDE
  .int WORD   // Get the word (after HIDE).
  .int FIND   // Look up in the dictionary.
  .int HIDDEN   // Set F_HIDDEN flag.
  .int EXIT   // Return.

  defcode "'",1,,TICK
  lodsl     // Get the address of the next word and skip it.
  pushl %eax    // Push it on the stack.
  NEXT

  defcode "BRANCH",6,,BRANCH
  add (%esi),%esi   // add the offset to the instruction pointer
  NEXT

  defcode "0BRANCH",7,,ZBRANCH
  pop %eax
  test %eax,%eax    // top of stack is zero?
  jz code_BRANCH    // if so, jump back to the branch function above
  lodsl     // otherwise we need to skip the offset
  NEXT

  defcode "LITSTRING",9,,LITSTRING
  lodsl     // get the length of the string
  push %esi   // push the address of the start of the string
  push %eax   // push it on the stack
  addl %eax,%esi    // skip past the string
  addl $3,%esi    // but round up to next 4 byte boundary
  andl $~3,%esi
  NEXT

  defcode "TELL",4,,TELL
  mov $1,%ebx   // 1st param: stdout
  pop %edx    // 3rd param: length of string
  pop %ecx    // 2nd param: address of string
  mov $__NR_write,%eax  // write syscall
  int $0x80
  NEXT

  // QUIT must not return (ie. must not call EXIT).
  defword "QUIT",4,,QUIT
  .int RZ,RSPSTORE  // R0 RSP!, clear the return stack
  .int INTERPRET    // interpret the next word
  .int BRANCH,-8    // and loop (indefinitely)


  defcode "INTERPRET",9,,INTERPRET
  call _WORD    // Returns %ecx = length, %edi = pointer to word.

  // Is it in the dictionary?
  xor %eax,%eax
  movl %eax,interpret_is_lit // Not a literal number (not yet anyway ...)
  call _FIND    // Returns %eax = pointer to header or 0 if not found.
  test %eax,%eax    // Found?
  jz 1f

  // In the dictionary.  Is it an IMMEDIATE codeword?
  mov %eax,%edi   // %edi = dictionary entry
  movb 4(%edi),%al  // Get name+flags.
  push %ax    // Just save it for now.
  call _TCFA    // Convert dictionary entry (in %edi) to codeword pointer.
  pop %ax
  andb $F_IMMED,%al // Is IMMED flag set?
  mov %edi,%eax
  jnz 4f      // If IMMED, jump straight to executing.

  jmp 2f

1:  // Not in the dictionary (not a word) so assume it's a literal number.
  incl interpret_is_lit
  call _NUMBER    // Returns the parsed number in %eax, %ecx > 0 if error
  test %ecx,%ecx
  jnz 6f
  mov %eax,%ebx
  mov $LIT,%eax   // The word is LIT

2:  // Are we compiling or executing?
  movl var_STATE,%edx
  test %edx,%edx
  jz 4f     // Jump if executing.

  // Compiling - just append the word to the current dictionary definition.
  call _COMMA
  mov interpret_is_lit,%ecx // Was it a literal?
  test %ecx,%ecx
  jz 3f
  mov %ebx,%eax   // Yes, so LIT is followed by a number.
  call _COMMA
3:  NEXT

4:  // Executing - run it!
  mov interpret_is_lit,%ecx // Literal?
  test %ecx,%ecx    // Literal?
  jnz 5f

  // Not a literal, execute it now.  This never returns, but the codeword will
  // eventually call NEXT which will reenter the loop in QUIT.
  jmp *(%eax)

5:  // Executing a literal, which means push it on the stack.
  push %ebx
  NEXT

6:  // Parse error (not a known word or a number in the current BASE).
  // Print an error message followed by up to 40 characters of context.
  mov $2,%ebx   // 1st param: stderr
  mov $errmsg,%ecx  // 2nd param: error message
  mov $errmsgend-errmsg,%edx // 3rd param: length of string
  mov $__NR_write,%eax  // write syscall
  int $0x80

  mov (currkey),%ecx  // the error occurred just before currkey position
  mov %ecx,%edx
  sub $buffer,%edx  // %edx = currkey - buffer (length in buffer before currkey)
  cmp $40,%edx    // if > 40, then print only 40 characters
  jle 7f
  mov $40,%edx
7:  sub %edx,%ecx   // %ecx = start of area to print, %edx = length
  mov $__NR_write,%eax  // write syscall
  int $0x80

  mov $errmsgnl,%ecx  // newline
  mov $1,%edx
  mov $__NR_write,%eax  // write syscall
  int $0x80

  NEXT

  .section .rodata
errmsg: .ascii "PARSE ERROR: "
errmsgend:
errmsgnl: .ascii "\n"

  .data     // NB: easier to fit in the .data section
  .align 4
interpret_is_lit:
  .int 0      // Flag used to record if reading a literal

  defcode "CHAR",4,,CHAR
  call _WORD    // Returns %ecx = length, %edi = pointer to word.
  xor %eax,%eax
  movb (%edi),%al   // Get the first character of the word.
  push %eax   // Push it onto the stack.
  NEXT

  defcode "EXECUTE",7,,EXECUTE
  pop %eax    // Get xt into %eax
  jmp *(%eax)   // and jump to it.
        // After xt runs its NEXT will continue executing the current word.

  defcode "SYSCALL3",8,,SYSCALL3
  pop %eax    // System call number (see <asm/unistd.h>)
  pop %ebx    // First parameter.
  pop %ecx    // Second parameter
  pop %edx    // Third parameter
  int $0x80
  push %eax   // Result (negative for -errno)
  NEXT

  defcode "SYSCALL2",8,,SYSCALL2
  pop %eax    // System call number (see <asm/unistd.h>)
  pop %ebx    // First parameter.
  pop %ecx    // Second parameter
  int $0x80
  push %eax   // Result (negative for -errno)
  NEXT

  defcode "SYSCALL1",8,,SYSCALL1
  pop %eax    // System call number (see <asm/unistd.h>)
  pop %ebx    // First parameter.
  int $0x80
  push %eax   // Result (negative for -errno)
  NEXT

  defcode "SYSCALL0",8,,SYSCALL0
  pop %eax    // System call number (see <asm/unistd.h>)
  int $0x80
  push %eax   // Result (negative for -errno)
  NEXT

  .text
  .set INITIAL_DATA_SEGMENT_SIZE,65536
set_up_data_segment:
  xor %ebx,%ebx   // Call brk(0)
  movl $__NR_brk,%eax
  int $0x80
  movl %eax,var_HERE  // Initialise HERE to point at beginning of data segment.
  addl $INITIAL_DATA_SEGMENT_SIZE,%eax  // Reserve nn bytes of memory for initial data segment.
  movl %eax,%ebx    // Call brk(HERE+INITIAL_DATA_SEGMENT_SIZE)
  movl $__NR_brk,%eax
  int $0x80
  ret

/*
  We allocate static buffers for the return static and input buffer (used when
  reading in files and text that the user types in).
*/
  .set RETURN_STACK_SIZE,8192
  .set BUFFER_SIZE,4096

  .bss
/* FORTH return stack. */
  .align 4096
return_stack:
  .space RETURN_STACK_SIZE
return_stack_top:   // Initial top of return stack.

/* This is used as a temporary input buffer when reading from files or the terminal. */
  .align 4096
buffer:
  .space BUFFER_SIZE


