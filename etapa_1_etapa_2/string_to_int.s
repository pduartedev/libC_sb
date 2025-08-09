# compilar: clang -o main string_to_int.s; ./main; echo $?
# ========================================================================================================
# Implementação em Assembly AMD64 (sintaxe AT&T) para converter uma string numérica com sinal para inteiro
# Instituto Federal do Norte de Minas Gerais - Campus Montes Claros
# - Entrada: %rdi = ponteiro para string terminada em null
# - Saída: %rax = valor inteiro resultante
# ========================================================================================================

.data
    # Definição das strings de teste
    str_teste1: .string "123"
    str_teste2: .string "-456"
    str_teste3: .string "+789"
    str_teste4: .string "0"
    str_teste5: .string ""

.text

# Função Principal
.globl _main

# Funções
.globl _string_to_int

# FunçÕes Auxiliares
.globl _string_vazia
.globl _pula_sinal
.globl _processa_digitos


_string_to_int:
    # Prólogo da função
    pushq %rbp                                              # Salva base pointer anterior
    movq %rsp, %rbp                                         # Estabelece um novo frame
    pushq %rbx                                              # Salva registradores callee-saved
    pushq %rcx
    pushq %rdx

    cmpq $0, %rdi                                           # Verifica se o ponteiro é válido
    je .string_vazia                                        # Pula se o ponteiro for NULL

    # Carregar primeiro caractere da string
    movb (%rdi), %al                                        # Carrega o primeiro caractere da string

    cmpb $0, %al                                            # Verifica se é '\0' (string vazia)
    je .string_vazia                                        # Pula se a string vazia

    # Inicializando variáveis
    movq $0, %rdx                                           # rdx = 0 (resultado final)
    movq $1, %rcx                                           # rcx = 1 (Multiplicador: 1=positivo, -1=negativo)

    # Verifica o sinal '+'
    cmpb $'+', %al                                          # Se o sinal for positivo
    je .pula_sinal                                          # Se sim, pula o símbolo de sinal '+'

    # Verifica o sinal '-' 
    cmpb $'-', %al                                          # Se o sinal for negativo
    jne .processa_digitos                                   # Se NÃO for '-', vai processar direto (sem pular)

    # Se chegou até aqui, É '-'
    movq $-1, %rcx                                          # rcx = -1 (número negativo)
    jmp .pula_sinal                                         # Pula para chamar o método de pular o sinal

    .string_vazia:
        call _string_vazia
        jmp .fim_string_to_int

    .pula_sinal:
        call _pula_sinal
        jmp .processa_digitos

    .processa_digitos:
        call _processa_digitos
        jmp .fim_string_to_int

    .fim_string_to_int:
        movq %rdx, %rax                                     # Move resultado para RAX
        imulq %rcx, %rax                                    # Aplica sinal
        
        # EPÍLOGO
        popq %rdx
        popq %rcx
        popq %rbx
        movq %rbp, %rsp                                     # Restaura stack pointer
        popq %rbp                                           # Restaura base pointer
        ret

_string_vazia:
    # PRÓLOGO
    pushq %rbp
    movq %rsp, %rbp

    movq $0, %rdx                                           # Retorna 0 para string vazia

    # EPÍLOGO
    movq %rbp, %rsp
    popq %rbp
    ret

_pula_sinal:
    # PRÓLOGO
    pushq %rbp
    movq %rsp, %rbp

    incq %rdi                                               # Pula o caractere de sinal
    movb (%rdi), %al                                        # Carrega próximo caractere após o sinal

    # EPÍLOGO
    movq %rbp, %rsp
    popq %rbp
    ret

_processa_digitos:
    # PRÓLOGO
    pushq %rbp
    movq %rsp, %rbp
    
    .loop_digitos:
        cmpb $0, %al                                        # Verifica se está no fim da string
        je .fim_processa_digitos
        
        # Verifica se é dígito válido ('0' a '9')
        cmpb $'0', %al                                      # Menor que '0'?
        jl .fim_processa_digitos                            # Se sim, não é dígito
        
        cmpb $'9', %al                                      # Maior que '9'?
        jg .fim_processa_digitos                            # Se sim, não é dígito
        
        # Converte caractere para número
        subb $'0', %al                                      # '5' - '0' = 5
        movzbq %al, %rbx                                    # Estende para 64 bits
        
        # Multiplica resultado por 10 e soma novo dígito
        imulq $10, %rdx                                     # rdx = rdx * 10
        addq %rbx, %rdx                                     # rdx = rdx + dígito
        
        incq %rdi                                           # Incrementa para o próximo caractere
        movb (%rdi), %al                                    # Carrega o próximo caractere em %al

        jmp .loop_digitos                                   # Salta para o próximo loop

    .fim_processa_digitos:
        # EPÍLOGO
        movq %rbp, %rsp
        popq %rbp
        ret



# Funcao main
_main:
    leaq str_teste3(%rip), %rdi
    call _string_to_int
    
    movq %rax, %rdi                                         # Passa o resultado para RDI
    
    movq $0x2000001, %rax
    syscall