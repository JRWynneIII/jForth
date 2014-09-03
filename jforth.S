SQUARE:
  call DUP
  call MUL
  ret
DUP:
  mov eax, esp
  push eax
  ret
MUL:
  pop eax
  pop ebx
  mul ebx
  push eax
  ret
