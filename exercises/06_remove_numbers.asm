; ==============================================================================
; Exercise: 06_remove_numbers.asm
; Description: Removes all digits from a string
; Platform: Linux x86-64 (NASM)
; ==============================================================================
; Features:
; - Filters all digits (0-9) from the string
; - Preserves all other characters
; - Displays the original string and the filtered string
; - Supports strings up to 200 characters long
; ==============================================================================

section .data
  msg_input       db "Enter a string: ", 0xA
  len_input       equ $ - msg_input
  msg_original    db "Original string: "
  len_original    equ $ - msg_original
  msg_result      db "No numbers: "
  len_result      equ $ - msg_result

  newline         db 0xA
  len_nl          equ 1

section .bss
  input_buffer    resb 200      ; buffer for input
  output_buffer   resb 200      ; buffer for string without numbers
  input_len       resq 1        ; input length
  output_len      resq 1        ; output length

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
  push rbx
  push rcx
  push rdi
  push rsi
  push rdx

  mov rax, 0                    ; sys_read
  mov rdi, 0                    ; stdin
  mov rsi, input_buffer
  mov rdx, 200
  syscall

  mov rcx, rax                  ; save length

  ; Check if the last character is newline
  cmp rcx, 0
  je .done

  dec rcx                       ; set index to last character
  cmp byte [input_buffer + rcx], 0xA
  jne .no_newline

  ; Replace newline with null
  mov byte [input_buffer + rcx], 0
  mov rax, rcx                  ; return length without newline
  jmp .done

.no_newline:
  inc rcx
  mov rax, rcx

.done:
  pop rdx
  pop rsi
  pop rdi
  pop rcx
  pop rbx
  ret

remove_digits:
  push rbx
  push rcx
  push rsi
  push rdi
  push r12

  xor r12, r12                  ; r12 = character counter

  ; If the string is empty, finish
  test rcx, rcx
  jz .done

.process_loop:
  movzx rbx, byte [rsi]         ; Get the current character

  ; Check if it's a digit ('0' = 48, '9' = 57)
  cmp bl, '0'
  jl .not_digit
  cmp bl, '9'
  jg .not_digit

  jmp .skip_char

.not_digit:
  mov [rdi], bl
  inc rdi
  inc r12                       ; increase counter

.skip_char:
  inc rsi
  dec rcx
  jnz .process_loop

.done:
  mov rax, r12                  ; return length of the resulting string
  pop r12
  pop rdi
  pop rsi
  pop rcx
  pop rbx
  ret

_start:
  mov rsi, msg_input
  mov rdx, len_input
  call print_str

  call read_stdin
  mov [input_len], rax          ; save length

  call print_newline

  mov rsi, msg_original
  mov rdx, len_original
  call print_str

  mov rsi, input_buffer
  mov rdx, [input_len]
  call print_str

  call print_newline

  mov rsi, input_buffer
  mov rdi, output_buffer
  mov rcx, [input_len]
  call remove_digits
  mov [output_len], rax         ; save resulting length

  mov rsi, msg_result
  mov rdx, len_result
  call print_str

  mov rsi, output_buffer
  mov rdx, [output_len]
  call print_str

  call print_newline

  mov rax, 60                   ; sys_exit
  xor rdi, rdi                  ; status = 0
  syscall
