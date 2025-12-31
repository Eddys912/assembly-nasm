; ==============================================================================
; Exercise: 02_fibonacci.asm
; Description: Generates and displays the first N terms of the Fibonacci
; Platform: Linux x86-64 (NASM)
; ==============================================================================
; Features:
; - Handles signed numbers up to 64 bits
; - Prints each number followed by a space
; - At the end, prints a line break
; - Recommended maximum: 93 terms (avoids 64-bit overflow)
; ==============================================================================

section .data
  space           db " "
  len_space       equ 1
  newline         db 0xA
  len_nl          equ 1

section .bss
  buffer          resb 20

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

print_space:
  push rsi
  push rdx
  mov rsi, space
  mov rdx, len_space
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
  div rdi                       ; rax = rax / 10, rdx = rax % 10
  add dl, '0'
  mov [rbx], dl
  dec rbx
  test rax, rax
  jnz .divide_loop

  ; Add sign if negative
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

print_number:
  call number_to_string
  call print_str                ; print number
  call print_space
  ret

_start:
  ; Initialize Fibonacci terms
  mov rbx, 0                    ; F(n-2) = 0
  mov r12, 1                    ; F(n-1) = 1
  mov r13, 93                   ; Number of terms to print (maximum safe: 93)

  mov rax, rbx
  call print_number

  mov rax, r12
  call print_number

  ; Adjust counter (we have already printed 2 terms)
  sub r13, 2
  cmp r13, 0
  jle .end_fib                  ; if <= 0, finish

.fib_loop:
  ; Calculate the next term: F(n) = F(n-2) + F(n-1)
  mov rax, rbx
  add rax, r12

  ; Update for next iteration
  mov rbx, r12                  ; F(n-2) = F(n-1)
  mov r12, rax                  ; F(n-1) = F(n)

  call print_number

  dec r13
  jnz .fib_loop

.end_fib:
  call print_newline

  mov rax, 60                   ; sys_exit
  xor rdi, rdi                  ; status = 0
  syscall
