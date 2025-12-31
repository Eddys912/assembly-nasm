; ==============================================================================
; Exercise: 07_substring_search.asm
; Description: Searches for a substring within a main text
; Platform: Linux x86-64 (NASM)
; ==============================================================================
; Features:
; - Reads single input in format: "main text|substring"
; - Searches for substring using byte-by-byte comparison
; - Returns position (0-based) if found, or indicates that it is not a substring
; - Supports texts up to 200 characters
; ==============================================================================

section .data
  msg_input       db "Enter the main text and the substring separated by '|': ", 0xA
  len_input       equ $ - msg_input
  msg_found       db "YES it is a substring (found at position "
  len_found       equ $ - msg_found
  msg_not_found   db "NO it is a substring"
  len_not_found   equ $ - msg_not_found
  msg_close       db ")"
  len_close       equ 1

  newline         db 0xA
  len_nl          equ 1
  separator       db "|"

section .bss
  input_buffer    resb 300      ; buffer for complete input
  main_text       resb 200      ; extracted main text
  search_text     resb 100      ; substring to search for
  output_buffer   resb 20       ; buffer for number conversion
  main_len        resq 1        ; length of main text
  search_len      resq 1        ; length of substring

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

number_to_string:
  push rbx
  push rcx
  push rdi

  mov rbx, output_buffer + 19
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
  lea rdx, [output_buffer + 19]
  sub rdx, rbx

  pop rdi
  pop rcx
  pop rbx
  ret

print_number:
  call number_to_string
  call print_str
  ret

parse_input:
  push rbx
  push rcx
  push rsi
  push rdi
  push r12
  push r13

  mov rsi, input_buffer
  mov rdi, main_text
  xor rcx, rcx                  ; character counter in main text

.find_separator:
  movzx rbx, byte [rsi]
  cmp bl, 0
  je .end_main                  ; end of entry without separator
  cmp bl, 0xA
  je .end_main                  ; line break without separator
  cmp bl, '|'
  je .found_separator

  mov [rdi], bl
  inc rsi
  inc rdi
  inc rcx
  jmp .find_separator

.found_separator:
  mov byte [rdi], 0             ; terminate main text with null
  mov [main_len], rcx           ; save length of main text
  inc rsi                       ; skip separator

  mov rdi, search_text
  xor rcx, rcx                  ; character counter in substring

.extract_search:
  movzx rbx, byte [rsi]
  cmp bl, 0
  je .end_search
  cmp bl, 0xA
  je .end_search
  cmp bl, 0xD
  je .end_search

  mov [rdi], bl
  inc rsi
  inc rdi
  inc rcx
  jmp .extract_search

.end_search:
  mov byte [rdi], 0             ; end substring with null
  mov [search_len], rcx         ; save substring length
  jmp .done

.end_main:                      ; No separator found, consider everything as main text
  mov byte [rdi], 0
  mov [main_len], rcx
  mov qword [search_len], 0     ; empty substring

.done:
  pop r13
  pop r12
  pop rdi
  pop rsi
  pop rcx
  pop rbx
  ret

find_substring:
  push rbx
  push rcx
  push rdx
  push rsi
  push rdi
  push r12
  push r13
  push r14
  push r15

  mov r12, rsi                  ; r12 = main text
  mov r13, rdi                  ; r13 = substring
  mov r14, rcx                  ; r14 = main text length
  mov r15, rdx                  ; r15 = substring length

  ; If the substring is longer than the text, it cannot be found
  cmp r15, r14
  jg .not_found

  ; If the substring is empty, it is considered to be found at position 0
  cmp r15, 0
  je .found_at_zero

  ; Calculate search limit: main_len - search_len + 1
  mov rbx, r14
  sub rbx, r15
  inc rbx                       ; rbx = number of positions to check

  xor r8, r8                    ; r8 = current position in main text

.search_loop:
  cmp r8, rbx
  jge .not_found

  ; Compare substring from current position
  mov rsi, r12
  add rsi, r8                   ; rsi = main text + offset
  mov rdi, r13                  ; rdi = substring
  mov rcx, r15                  ; rcx = substring length

  ; Compare byte by byte
  push r8
  push rbx
  xor rbx, rbx                  ; rbx = index within substring

.compare_loop:
  cmp rbx, rcx
  je .match_found               ; all bytes match

  mov al, [rsi + rbx]
  mov dl, [rdi + rbx]
  cmp al, dl
  jne .no_match                 ; difference found

  inc rbx
  jmp .compare_loop

.match_found:
  pop rbx
  pop r8
  mov rax, r8                   ; return position
  jmp .done

.no_match:
  pop rbx
  pop r8
  inc r8                        ; next position
  jmp .search_loop

.found_at_zero:
  xor rax, rax
  jmp .done

.not_found:
  mov rax, -1

.done:
  pop r15
  pop r14
  pop r13
  pop r12
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

  mov rsi, main_text
  mov rdi, search_text
  mov rcx, [main_len]
  mov rdx, [search_len]
  call find_substring

  cmp rax, -1
  je .not_found

  push rax                      ; Substring found and save position

  mov rsi, msg_found
  mov rdx, len_found
  call print_str

  pop rax                       ; regain position
  call print_number

  mov rsi, msg_close
  mov rdx, len_close
  call print_str

  jmp .print_newline

.not_found:
  mov rsi, msg_not_found
  mov rdx, len_not_found
  call print_str

.print_newline:
  call print_newline

  mov rax, 60                   ; sys_exit
  xor rdi, rdi                  ; status = 0
  syscall
