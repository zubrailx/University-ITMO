global exit
global string_length
global print_string
global print_char
global print_newline
global print_uint
global print_int
global read_char
global read_word
global parse_uint
global parse_int
global string_equals
global string_copy

section .text

; Params:
;   -
; Out:
;   !exit
exit: 
    mov rax, 60
    mov rdi, 0
    syscall
    ret 

; Params:
;   rdi - string ptr
; Out:
;   rax - string length
string_length:
    xor rax, rax
.loop:
    inc rax
    cmp byte [rdi + rax - 1], 0 ;starts with 1, ends with 1+length-1
    jne .loop
    dec rax
    ret

; Params:
;   rdi - pointer on null-terminated string
;   rsi - descriptor for writing
; Out:
;   >1 - string in std
print_string:
    call string_length
    mov rdx, rax    ; string length
    mov r8, rsi
    mov rsi, rdi    ; string source
    mov rdi, r8     ; writing descriptor
    mov rax, 1      ; call number
    syscall 
    ret

; Params:
;   rdi - code of char
; Out:
;   >1 - char code in std
print_char:
    mov rax, 1      ; value in rdi
    mov rdx, 1      ; length
    push rdi        
    mov rdi, 1      ; forgotten line (set descriptor)
    mov rsi, rsp  ; the address of char in stack
    syscall
    pop rdi
    ret

; Params:
;   -
; Out:
;   >1 - \n (0xA)
print_newline:
    mov rdi, 10
    call print_char
    ret 

; Params:
;   rdi - unsigned int 8 bytes
; Out:
;   >1 - unsigned int in decimal
print_uint:
    push 0          ; null terminated string
    mov rbx, 10     ; devident
    mov rax, rdi    ; put in rax for calculation
    add rsp, 7
.count:
    xor rdx, rdx
    div rbx         ; rax div rcx -% rax
    add dl, '0'     ; one lowest byte
    mov dh, byte [rsp]
    add rsp, 1
    push dx
    test rax, rax
    jne .count
    mov rdi, rsp
    call print_string
    mov rdi, rsp
    call string_length
    add rsp, rax
    inc rsp         ; jump over null-terminator
    ret

; Params:
;   rdi - signed int 8 bytes
; Out:
;   >1 - signed in in decimal
print_int:
    push rbx
    mov rbx, rdi
    cmp rbx, 0
    jns .count
    mov rdi, '-'
    call print_char
    mov rdi, rbx
    neg rdi
.count:
    call print_uint
    pop rbx
    ret

; Params:
;   rdi - first null-terminated string pointer
;   rsi - second null-terminated string pointer
; Out:
;   rax - equals ? 1 : 0
string_equals:
    push rdi
    push rsi
    call string_length
    mov rdi, [rsp]
    push rax
    call string_length
    cmp rax, [rsp]
    je .check
    add rsp, 3*8
.error:
    mov rax, 0
    ret

.check:
    pop rcx
    pop rsi
    pop rdi
.loop:
    cmp rcx, 0
    jbe .end
    mov dl, byte [rsi + rcx - 1]
    cmp dl, byte [rdi + rcx - 1]
    jne .error
    dec rcx
    jmp .loop

.end:
    mov rax, 1
    ret

; Params:
;   >0 - one char
; Out:
;   rax - EOF ? 0 : char_symbol
read_char:
    push 0
    mov rsi, rsp
    mov rax, 0
    mov rdi, 0
    mov rdx, 1
    syscall
    pop rax
    ret 

; Params:
;   rdi - buffer address
;   rsi - buffer size
;   >0 - symbols in ASCII
; Out:
;   rax - buffer address, failure  - 0
;   rdx - size of word
; Description:
;   Reads word of std-in.
;   1) Skips space chars from the beginning of input (0x20, 0x9, 0xA)
;   2) Adds null-terminator to string
read_word:
    push rdi        ; address of buffer start
    push r12
    mov r12, rdi    ; callee saved registers
    push r13
    mov r13, rsi
.loop_space:
    call read_char
    cmp rax, 0x20
    je .loop_space
    cmp rax, 0x09
    je .loop_space
    cmp rax, 0xA
    je .loop_space
.loop:
    cmp rax, 0x0
    je .finally
    cmp rax, 0x20
    je .finally
    cmp rax, 0x9
    je .finally
    cmp rax, 0xA
    je .finally
    dec r13        ; will be if size=n n+1 cuz of null-terminator
    cmp r13, 0
    jbe .overflow
    mov byte [r12], al
    inc r12
    call read_char
    jmp .loop
    
.finally:
    mov byte [r12], 0   ; putting null terminator
    pop r13             ; pop r13
    pop r12             ; pop r12
    mov rdi, [rsp]      ; get rdi from rsp to add func args
    call string_length  
    mov rdx, rax        ; put size in rdx
    pop rax             ; put rdi in rax
    ret

.overflow:
    pop r13             ; get back everything from stack
    pop r12
    pop rdi
    mov rax, 0
    ret
    
; Params:
;   rdi - string on ptr (unsigned integer)
; Out:
;   rax - unsigned integer
;   rdx - failure ? 0 : integer_length_in_decimal
parse_uint:
    mov rsi, 0x0A       ; base
    xor r8, r8          ; result
    xor rax, rax
    xor rcx, rcx        ; length counter
.loop:
    mov al, byte[rdi + rcx]
    cmp al, '0'
    jb .finally
    cmp al, '9'
    ja .finally
    sub al, '0'
    push rax
    mov rax, r8
    mul rsi
    mov r8, rax
    pop rax

    add r8, rax
    inc rcx
    jmp .loop

.finally:
    mov rdx, rcx
    mov rax, r8  
    ret

; Params:
;   rdi - string on ptr (signed integer)
; Out:
;   rax - signed integer
;   rdx - failure ? 0 : integer_length_in_decimal + sign
parse_int:
    xor rax, rax
    mov al, byte [rdi]
    inc rdi
    cmp al, '-'
    je .negative
    cmp al, '+'
    je .positive
    dec rdi
.positive:
    call parse_uint
    ret

.negative:
    call parse_uint
    neg rax
    inc rdx         ; symbol minus
    ret 

; Params:
;   rdi - string ptr
;   rsi - buffer ptr
;   rdx - buffer size
; Out:
;   rax - (can be places in buffer) ? string_size : 0
; Description:
;   Coping string in buffer.
string_copy:
    call string_length  ; return rax
    cmp rdx, rax
    jb .else
    mov rcx, rax
.loop:
    test rcx, rcx
    je .end
    dec rcx                 ; idk should i print string termination symbol
    mov dl, byte [rdi + rcx]   ; put string in buffer
    mov byte [rsi + rcx], dl
    jmp .loop
.end:
    mov byte [rsi + rax], 0
    ret
.else:
    mov rax, 0
    ret   
