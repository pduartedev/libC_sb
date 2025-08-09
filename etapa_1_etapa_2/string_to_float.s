# ========================================================================================================
# Implementação em Assembly AMD64 (sintaxe AT&T) para converter uma string numérica com sinal para float
# Instituto Federal do Norte de Minas Gerais - Campus Montes Claros
# - Entrada: %rdi = ponteiro para string terminada em null
# - Saída:   %xmm0 = valor float resultante
# ========================================================================================================

.data
    # Constantes para cálculos de ponto flutuante
    const_10: .float 10.0
    const_0_1: .float 0.1
    const_0: .float 0.0
    
.text

# Funções
.globl _string_to_float

# FunçÕes Auxiliares
.globl _string_vazia_float
.globl _pula_sinal
.globl _processa_digitos_float

_string_to_float:
    # Prólogo da função
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %rcx
    pushq %rdx

    
    cmpq $0, %rdi                                # Verifica se o ponteiro é válido
    je .string_vazia                             # Pula se o ponteiro for NULL

    # Inicializa variáveis
    movss const_0(%rip), %xmm0                   # xmm0 = 0.0 (resultado final)
    movss const_0(%rip), %xmm1                   # xmm1 = 0.0 (parte decimal)
    movq $1, %rcx                                # rcx = 1 (sinal: 1=positivo, -1=negativo)
    movq $0, %rdx                                # rdx = 0 (flag: 0=parte inteira, 1=parte decimal)

    # Carregar primeiro caractere
    movb (%rdi), %al

    cmpb $0, %al                                # Verifica se é '\0' (string vazia)
    je .string_vazia                            # Pula se a string vazia

    # Verifica o sinal '+'
    cmpb $'+', %al                              # Se o sinal for positivo
    je .pula_sinal                              # Se sim, pula o símbolo de sinal '+'

    # Verifica o sinal '-' 
    cmpb $'-', %al                              # Se o sinal for negativo
    jne .processa_digitos_float                 # Se NÃO for '-', vai processar direto (sem pular)
    
    # Se chegou até aqui, É '-'
    movq $-1, %rcx                              # rcx = -1 (número negativo)
    jmp .pula_sinal                             # Pula para chamar o método de pular o sinal

    .string_vazia:
        call _string_vazia_float
        jmp .fim_string_to_float

    .pula_sinal:
        call _pula_sinal
        call .processa_digitos_float

    .processa_digitos_float:
        call _processa_digitos_float

    .fim_string_to_float:
        cmpq $-1, %rcx                          # Aplica o sinal quando o número for negativo
        jne .positivo                           # Se não, o número é positivo
    
        # Nega o resultado
        movss const_10(%rip), %xmm2             # Carregar -1.0 (temporário)
        subss %xmm2, %xmm2                      # xmm2 = 0
        subss %xmm0, %xmm2                      # xmm2 = -xmm0
        movaps %xmm2, %xmm0                     # xmm0 = resultado negativo

    .positivo:
        # EPÍLOGO
        popq %rdx
        popq %rcx
        popq %rbx
        movq %rbp, %rsp                         # Restaura stack pointer
        popq %rbp                               # Restaura base pointer
        ret

_string_vazia_float:
    # PRÓLOGO
    pushq %rbp
    movq %rsp, %rbp
    
    movss const_0(%rip), %xmm0                  # Retornar 0.0

    # EPÍLOGO
    movq %rbp, %rsp
    popq %rbp
    ret

_pula_sinal:
    # PRÓLOGO
    pushq %rbp
    movq %rsp, %rbp

    incq %RDI                                   # Pula o caractere de sinal
    movb (%rdi), %al                            # Carrega próximo caractere após o sinal

    # EPÍLOGO
    movq %rbp, %rsp
    popq %rbp
    ret

_processa_digitos_float:
    pushq %rbp
    movq %rsp, %rbp
    
    movss const_0_1(%rip), %xmm3                # xmm3 = 0.1 (multiplicador decimal)
    
    .loop_digitos:
        movb (%rdi), %al
        cmpb $0, %al                            # Se chegou no fim da string
        je .fim_processa_digitos_float
        
        cmpb $'.', %al                          # Se encotrou um ponto decimal
        je .encontrou_ponto
        
        # Verificar se é dígito
        cmpb $'0', %al
        jl .fim_processa_digitos_float

        cmpb $'9', %al
        jg .fim_processa_digitos_float
        
        # Converter caractere para número
        subb $'0', %al
        movzbq %al, %rbx
        cvtsi2ss %rbx, %xmm2                    # Converte para float
        
        # Verificar se estamos na parte decimal
        cmpq $1, %rdx
        je .parte_decimal
        
        # Parte inteira: resultado = resultado * 10 + dígito
        mulss const_10(%rip), %xmm0
        addss %xmm2, %xmm0
        jmp .proximo_caractere
        
        .parte_decimal:
            # Parte decimal: acumular em xmm1
            mulss %xmm3, %xmm2                      # Dígito * multiplicador
            addss %xmm2, %xmm1                      # Somar à parte decimal
            mulss const_0_1(%rip), %xmm3            # Reduzir o multiplicador
            jmp .proximo_caractere
            
        .encontrou_ponto:
            movq $1, %rdx                       # Marcar que encontrou parte decimal
        
        .proximo_caractere:
            incq %rdi
            jmp .loop_digitos
        
    .fim_processa_digitos_float:
        # Somar parte inteira + parte decimal
        addss %xmm1, %xmm0
        
        # EPÍLOGO
        movq %rbp, %rsp
        popq %rbp
        ret


# Casos foram testados em um arquivo test em C, através do uso de "extern"
# Pois o registrador %rdi não consegue imprimir um valor float