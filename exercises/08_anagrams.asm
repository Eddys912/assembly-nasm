; ==============================================================================
; Exercise: 08_anagrams.asm
; Description: Checks if two strings have the same characters
; Platform: Linux x86-64 (NASM)
; ==============================================================================
; Features:
; - Reads single input in format: "string1|string2"
; - Uses frequency tables to compare characters (256 ASCII)
; - Determines if both strings contain the same characters
; - Supports strings up to 100 characters each
; ==============================================================================

section .data
  msg_input         db "Enter two strings separated by '|': ", 0xA
  len_input         equ $ - msg_input
  msg_anagrams      db "YES, they have the same characters (they are anagrams)"
  len_anagrams      equ $ - msg_anagrams
  msg_not_anagrams  db "NO, they do not have the same characters"
  len_not_anagrams  equ $ - msg_not_anagrams

  newline           db 0xA
  len_nl            equ 1

section .bss
  input_buffer      resb 300    ; buffer for complete input
  string1           resb 100    ; first extracted string
  string2           resb 100    ; second extracted string
  freq_table1       resb 256    ; frequency table for string1
  freq_table2       resb 256    ; frequency table for string2
  len1              resq 1      ; length of string1
  len2              resq 1      ; length of string2

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
  mov rdx, 300
  syscall

  pop rdx
  pop rsi
  pop rdi
  pop rax
  ret

parse_input:
  push rbx
  push rcx
  push rsi
  push rdi

  mov rsi, input_buffer
  mov rdi, string1
  xor rcx, rcx                  ; character counter in string1

.find_separator:
  movzx rbx, byte [rsi]
  cmp bl, 0
  je .end_string1               ; end of input without separator
  cmp bl, 0xA
  je .end_string1               ; line break without separator
  cmp bl, '|'
  je .found_separator

  mov [rdi], bl
  inc rsi
  inc rdi
  inc rcx
  jmp .find_separator

.found_separator:
  mov byte [rdi], 0             ; end string1 with null
  mov [len1], rcx               ; save length of string1
  inc rsi                       ; skip separator

  ; Now extract string2
  mov rdi, string2
  xor rcx, rcx                  ; character counter in string2

.extract_string2:
  movzx rbx, byte [rsi]
  cmp bl, 0
  je .end_string2
  cmp bl, 0xA
  je .end_string2
  cmp bl, 0xD
  je .end_string2

  mov [rdi], bl
  inc rsi
  inc rdi
  inc rcx
  jmp .extract_string2

.end_string2:
  mov byte [rdi], 0             ; end string2 with null
  mov [len2], rcx               ; save length of string2
  jmp .done

.end_string1:                   ; No separator found, consider everything as string1
  mov byte [rdi], 0
  mov [len1], rcx
  mov qword [len2], 0           ; string2 empty

.done:
  pop rdi
  pop rsi
  pop rcx
  pop rbx
  ret

clear_freq_table:
  push rax
  push rcx
  push rdi

  mov rcx, 256                  ; 256 bytes (all ASCII characters)
  xor al, al                    ; al = 0
  rep stosb                     ; fill with zeros

  pop rdi
  pop rcx
  pop rax
  ret

calculate_frequencies:
  push rax
  push rbx
  push rcx
  push rsi
  push rdi

  call clear_freq_table

  ; If the string is empty, terminate
  test rcx, rcx
  jz .done

.count_loop:
  ; Get the current character
  movzx rax, byte [rsi]         ; rax = character (extended to 64 bits)

  ; Increase the frequency of this character
  inc byte [rdi + rax]

  ; Advance to the next character
  inc rsi
  dec rcx
  jnz .count_loop

.done:
  pop rdi
  pop rsi
  pop rcx
  pop rbx
  pop rax
  ret

compare_frequencies:
  push rbx
  push rcx
  push rdx
  push rsi
  push rdi

  mov rcx, 256                  ; compare the 256 bytes

.compare_loop:
  ; Get bytes from both tables
  mov al, [rsi]
  mov dl, [rdi]

  cmp al, dl
  jne .different

  inc rsi
  inc rdi
  dec rcx
  jnz .compare_loop

  ; If we get here, all frequencies are the same.
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

  call parse_input

  mov rsi, string1
  mov rcx, [len1]
  mov rdi, freq_table1
  call calculate_frequencies

  mov rsi, string2
  mov rcx, [len2]
  mov rdi, freq_table2
  call calculate_frequencies

  mov rsi, freq_table1
  mov rdi, freq_table2
  call compare_frequencies


  cmp rax, 1
  je .are_anagrams              ; Show result

  mov rsi, msg_not_anagrams
  mov rdx, len_not_anagrams
  call print_str
  jmp .print_newline

.are_anagrams:
  mov rsi, msg_anagrams
  mov rdx, len_anagrams
  call print_str

.print_newline:
  call print_newline

  mov rax, 60                   ; sys_exit
  xor rdi, rdi                  ; status = 0
  syscall
