; ==============================================================================
; Exercise: 05_string_comparison.asm
; Description: Compares two strings entered on a single line or two lines
; Platform: Linux x86-64 (NASM)
; ==============================================================================
; Features:
; - Parses two text strings separated by spaces, tabs, or line breaks
; - Compares length and content byte by byte
; - Handles multiple separators and extra spaces
; ==============================================================================

section .data
  msg_input       db "Enter 2 strings separated by a space and press Enter: ", 0xA
  len_input       equ $ - msg_input
  msg_equal       db "The strings are EQUAL"
  len_equal       equ $ - msg_equal
  msg_different   db "The strings are DIFFERENT"
  len_different   equ $ - msg_different

  newline         db 0xA
  len_nl          equ 1

section .bss
  input_buffer    resb 200      ; raw input
  string1         resb 100      ; first token
  string2         resb 100      ; second token
  len1            resq 1        ; length of token1
  len2            resq 1        ; length of token2
  buffer_pos      resq 1        ; current position in input_buffer

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

read_stdin:
  push rax
  push rdi
  push rsi
  push rdx

  mov rax, 0                    ; sys_read
  mov rdi, 0                    ; stdin
  mov rsi, input_buffer
  mov rdx, 200
  syscall

  mov qword [buffer_pos], 0     ; reset parsing position

  pop rdx
  pop rsi
  pop rdi
  pop rax
  ret

parse_next_token:
  push rbx
  push rcx
  push rdi
  push rsi

  mov rsi, input_buffer
  add rsi, [buffer_pos]         ; rsi = input_buffer + buffer_pos
  mov rdi, r12                  ; r12 = pointer to destination buffer
  xor rcx, rcx                  ; length = 0

.skip_whitespace:
  movzx rbx, byte [rsi]
  cmp bl, 0
  je .done
  cmp bl, ' '
  je .next
  cmp bl, 0xA
  je .next
  cmp bl, 0xD
  je .next
  cmp bl, 9
  je .next
  jmp .copy

.next:
  inc rsi
  inc qword [buffer_pos]
  jmp .skip_whitespace

.copy:
  movzx rbx, byte [rsi]
  cmp bl, 0
  je .store_length
  cmp bl, ' '
  je .store_length
  cmp bl, 9
  je .store_length
  cmp bl, 0xA
  je .store_length
  cmp bl, 0xD
  je .store_length

  mov [rdi], bl                 ; copy byte
  inc rdi
  inc rcx
  inc rsi
  inc qword [buffer_pos]

  cmp rcx, 100
  jge .store_length
  jmp .copy

.store_length:
  mov byte [rdi], 0             ; null-terminate string
  mov rax, rcx                  ; return length

.done:
  pop rsi
  pop rdi
  pop rcx
  pop rbx
  ret

compare_strings:
  push rbx
  push rcx
  push rdx
  push rsi
  push rdi

  mov rcx, [len1]
  mov rdx, [len2]

  cmp rcx, rdx
  jne .different

  mov rbx, rcx
  mov rsi, string1
  mov rdi, string2

.compare_loop:
  test rbx, rbx
  jz .equal

  mov al, [rsi]
  mov dl, [rdi]
  cmp al, dl
  jne .different

  inc rsi
  inc rdi
  dec rbx
  jmp .compare_loop

.equal:
  mov rax, 1
  jmp .done

.different:
  xor rax, rax

.done:
  pop rdi
  pop rsi
  pop rdx
  pop rcx
  pop rbx
  ret

_start:
  mov rsi, msg_input
  mov rdx, len_input
  call print_str

  call read_stdin

  mov r12, string1
  call parse_next_token
  mov [len1], rax

  mov r12, string2
  call parse_next_token
  mov [len2], rax

  call compare_strings

  test rax, rax
  jnz .strings_equal

  mov rsi, msg_different
  mov rdx, len_different
  call print_str
  jmp .finish

.strings_equal:
  mov rsi, msg_equal
  mov rdx, len_equal
  call print_str

.finish:
  call print_newline

  mov rax, 60                   ; sys_exit
  xor rdi, rdi                  ; status = 0
  syscall
