; ==============================================================================
; Exercise: 01_arithmetic_operations.asm
; Description: Performs basic arithmetic operations between two operands
; Platform: Linux x86-64 (NASM)
; ==============================================================================
; Features:
; - Supports signed 16-bit integers (loaded as 64 bits)
; - Handles negative results correctly
; - Detects and reports division by zero
; - Uses signed multiplication and division (imul, idiv)
; ==============================================================================

section .data
  operand1        dw 10
  operand2        dw 10

  msg_add         db "Addition = "
  len_add         equ $ - msg_add
  msg_sub         db "Subtraction = "
  len_sub         equ $ - msg_sub
  msg_mul         db "Multiplication = "
  len_mul         equ $ - msg_mul
  msg_div         db "Division = "
  len_div         equ $ - msg_div

  msg_div_zero    db "Error: Division by zero", 0xA
  len_div_zero    equ $ - msg_div_zero

  newline         db 0xA
  len_nl          equ 1

section .bss
  buffer resb 20

section .text
  global _start

print_str:
  push rax
  push rdi
  mov rax, 1                    ; sys_write
  mov rdi, 1                    ; stdout
  syscall
  pop rdi
  pop rax
  ret

print_newline:
  push rsi
  push rdx
  mov rsi, newline
  mov rdx, len_nl
  call print_str
  pop rdx
  pop rsi
  ret

number_to_string:
  push rbx
  push rcx
  push rdi

  mov rbx, buffer + 19
  mov byte [rbx], 0             ; null terminator
  dec rbx

  test rax, rax
  jnz .not_zero
  mov byte [rbx], '0'
  dec rbx
  jmp .done

.not_zero:
  cmp rax, 0
  jge .positive
  neg rax                       ; convert to positive
  mov rcx, 1                    ; flag: it's negative
  jmp .convert

.positive:
  mov rcx, 0                    ; flag: positive

.convert:
  mov rdi, 10

.divide_loop:
  xor rdx, rdx
  div rdi
  add dl, '0'
  mov [rbx], dl
  dec rbx
  test rax, rax
  jnz .divide_loop

  cmp rcx, 1
  jne .done
  mov byte [rbx], '-'
  dec rbx

.done:
  inc rbx
  mov rsi, rbx
  lea rdx, [buffer + 19]
  sub rdx, rbx

  pop rdi
  pop rcx
  pop rbx
  ret

print_result:
  call print_str                ; prints the message (e.g., Addition = )
  call number_to_string         ; converts rax → rsi/rdx
  call print_str                ; prints the number
  call print_newline
  ret

_start:
  movsx r8, word [operand1]     ; load operand1 with sign
  movsx r9, word [operand2]     ; load operand2 with sign

  ; Addition
  mov rax, r8
  add rax, r9
  mov rsi, msg_add
  mov rdx, len_add
  call print_result

  ; Subtraction
  mov rax, r8
  sub rax, r9
  mov rsi, msg_sub
  mov rdx, len_sub
  call print_result

  ; Multiplication
  mov rax, r8
  imul rax, r9
  mov rsi, msg_mul
  mov rdx, len_mul
  call print_result

  ; Division
  cmp r9, 0
  je .division_by_zero

  mov rax, r8
  cqo
  idiv r9
  mov rsi, msg_div
  mov rdx, len_div
  call print_result
  jmp .end_division

.division_by_zero:
  mov rsi, msg_div_zero
  mov rdx, len_div_zero
  call print_str
  call print_newline
  jmp .end_division

.end_division:
  mov rax, 60                   ; sys_exit
  xor rdi, rdi                  ; status = 0
  syscall
