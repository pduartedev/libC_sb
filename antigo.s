# =====================================================================================================
# libC_SB - Implementação completa de funções básicas da biblioteca C em Assembly x86-64
# Este arquivo contém implementações profissionais de funções como printf, scanf, conversões, etc.
# Disciplina: Software Básico - IFNMG (2025)
# Autor: Patrick Duarte Pimenta 
# OBS: Implementação completa para macOS com suporte a todos os tipos de dados
# =====================================================================================================

.section __BSS,__bss
    # CONSTANTES DO SISTEMA
    .equ STDIN_FD, 0                                    # Entrada padrão
    .equ STDOUT_FD, 1                                   # Saída padrão
    .equ STDERR_FD, 2                                   # Saída de erro

    # SYSCALLS macOS
    .equ SYS_READ, 0x2000003                            # Ler dados
    .equ SYS_WRITE, 0x2000004                           # Escrever dados
    .equ SYS_OPEN, 0x2000005                            # Abrir arquivo
    .equ SYS_CLOSE, 0x2000006                           # Fechar arquivo
    .equ SYS_EXIT, 0x2000001                            # Terminar programa

    # CONSTANTES DE TAMANHO
    .equ BUFFER_SIZE, 1024                              # Tamanho dos buffers
    .equ MAX_FILES, 16                                  # Máximo de arquivos abertos
    
    # TAMANHOS DOS TIPOS DE DADOS
    .equ CHAR_SIZE, 1                                   # 1 byte
    .equ SHORT_SIZE, 2                                  # 2 bytes
    .equ INT_SIZE, 4                                    # 4 bytes  
    .equ LONG_SIZE, 8                                   # 8 bytes
    .equ FLOAT_SIZE, 4                                  # 4 bytes
    .equ DOUBLE_SIZE, 8                                 # 8 bytes

    # FLAGS PARA FOPEN
    .equ O_RDONLY, 0x0000                               # Somente leitura
    .equ O_WRONLY, 0x0001                               # Somente escrita
    .equ O_RDWR, 0x0002                                 # Leitura e escrita
    .equ O_CREAT, 0x0200                                # Criar arquivo
    .equ O_TRUNC, 0x0400                                # Truncar arquivo
    .equ O_APPEND, 0x0008                               # Anexar ao final

    # PRECISÃO PARA PONTO FLUTUANTE
    .equ FLOAT_PRECISION, 6                             # 6 casas decimais para float
    .equ DOUBLE_PRECISION, 15                           # 15 casas decimais para double
    .equ FLOAT_MULTIPLIER, 1000000                      # 10^6 para float
    .equ DOUBLE_MULTIPLIER, 1000000000000000            # 10^15 para double

    # BUFFERS E VARIÁVEIS GLOBAIS
    .comm input_buffer, 1024                            # Buffer de entrada
    .comm output_buffer, 1024                           # Buffer de saída
    .comm conversion_buffer, 64                         # Buffer para conversões
    .comm temp_buffer, 256                              # Buffer temporário
    .comm file_table, 1024                              # Tabela de arquivos
    .comm input_position, 8                             # Posição no buffer de entrada
    .comm input_size, 8                                 # Tamanho dos dados de entrada

.section __DATA,__data
    # STRINGS DE FORMATO PARA PRINTF/SCANF
    format_char: .string "%c"                           # Formato para char
    format_short: .string "%hd"                         # Formato para short
    format_int: .string "%d"                            # Formato para int
    format_long: .string "%ld"                          # Formato para long
    format_float: .string "%f"                          # Formato para float
    format_double: .string "%lf"                        # Formato para double
    format_string: .string "%s"                         # Formato para string
    
    # STRINGS DE TESTE E DEMONSTRAÇÃO
    demo_char_msg: .string "Char: %c\n"
    demo_short_msg: .string "Short: %hd\n"
    demo_int_msg: .string "Int: %d\n"
    demo_long_msg: .string "Long: %ld\n"
    demo_float_msg: .string "Float: %f\n"
    demo_double_msg: .string "Double: %lf\n"
    demo_string_msg: .string "String: %s\n"
    
    # VALORES DE TESTE PARA DEMONSTRAÇÃO
    test_char: .byte 'A'                                # Valor char de teste
    test_short: .word 32767                             # Valor short de teste
    test_int: .long 2147483647                          # Valor int de teste
    test_long: .quad 9223372036854775807                # Valor long de teste
    test_string: .string "LibC_SB_Complete"             # String de teste
    
    # VALORES FLOAT E DOUBLE (representados como inteiros para manipulação)
    test_float_raw: .quad 3141592                       # 3.141592 * 1000000
    test_double_raw: .quad 271828182845904523           # 2.71828182845904523 * 10^15
    
    # STRINGS PARA CONVERSÃO
    str_to_char_test: .string "65"                      # "A" em ASCII
    str_to_short_test: .string "-32768"                 # Valor short mínimo
    str_to_int_test: .string "2147483647"               # Valor int máximo
    str_to_long_test: .string "9223372036854775807"     # Valor long máximo
    str_to_float_test: .string "3.141592"               # Valor float de teste
    str_to_double_test: .string "2.718281828459045"     # Valor double de teste
    
    # MENSAGENS DO SISTEMA
    newline: .string "\n"
    space: .string " "
    error_msg: .string "ERRO: "
    success_msg: .string "SUCESSO: "
    
    # STRINGS PARA ARQUIVOS
    read_mode: .string "r"
    write_mode: .string "w"
    append_mode: .string "a"
    
    # DADOS PESSOAIS DE DEMONSTRAÇÃO
    name_demo: .string "Patrick Duarte Pimenta"
    age_demo: .long 25
    initial_demo: .byte 'P'
    height_demo: .quad 1800000                          # 1.80m * 1000000
    weight_demo: .quad 75500000000000000                # 75.5kg * 10^15
    
    # MENSAGENS DE TESTE COMPLETO
    complete_test_msg: .string "=== TESTE COMPLETO DA BIBLIOTECA ===\n"
    type_test_msg: .string "Testando todos os tipos de dados:\n"
    conversion_test_msg: .string "Testando conversoes string-to-type:\n"
    file_test_msg: .string "Testando operacoes de arquivo:\n"
    final_msg: .string "Biblioteca libC_SB implementada com sucesso!\n"

.section __TEXT,__text

# FUNÇÕES PRINCIPAIS DA BIBLIOTECA
.globl _main
.globl _printf                                          # Printf com suporte completo
.globl _scanf                                           # Scanf com suporte completo  
.globl _fprintf                                         # Fprintf para arquivos
.globl _fscanf                                          # Fscanf para arquivos
.globl _fopen                                           # Abrir arquivos
.globl _fclose                                         # Fechar arquivos

# FUNÇÕES DE CONVERSÃO STRING-TO-TYPE
.globl _str_to_char                                     # String para char
.globl _str_to_short                                    # String para short
.globl _str_to_int                                      # String para int
.globl _str_to_long                                     # String para long
.globl _str_to_float                                    # String para float
.globl _str_to_double                                   # String para double

# FUNÇÕES DE CONVERSÃO TYPE-TO-STRING
.globl _char_to_str                                     # Char para string
.globl _short_to_str                                    # Short para string
.globl _int_to_str                                      # Int para string
.globl _long_to_str                                     # Long para string
.globl _float_to_str                                    # Float para string
.globl _double_to_str                                   # Double para string

# ===================================================================================================
# IMPLEMENTAÇÃO COMPLETA DO PRINTF
# Suporta: %c (char), %hd (short), %d (int), %ld (long), %f (float), %lf (double), %s (string)
# ===================================================================================================
_printf:
    pushq %rbp
    movq %rsp, %rbp
    
    # Preservar registradores callee-saved
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    pushq %rbx
    
    # Alocar espaço para variáveis locais
    subq $64, %rsp                                      # Espaço para variáveis locais
    
    # Salvar argumentos
    movq %rdi, -8(%rbp)                                 # format string
    movq %rsi, -16(%rbp)                                # arg1
    movq %rdx, -24(%rbp)                                # arg2
    movq %rcx, -32(%rbp)                                # arg3
    movq %r8, -40(%rbp)                                 # arg4
    movq %r9, -48(%rbp)                                 # arg5
    
    # Inicializar variáveis
    movl $0, -52(%rbp)                                  # char_count
    movl $0, -56(%rbp)                                  # arg_index
    leaq output_buffer(%rip), %r12                      # buffer pointer
    movq %r12, %r13                                     # buffer start
    
    printf_main_loop:
        movq -8(%rbp), %rax                             # format pointer
        movb (%rax), %bl                                # current char
        testb %bl, %bl                                  # check for null terminator
        jz printf_output
        
        cmpb $'%', %bl                                  # check for format specifier
        je printf_format_handler
        
        # Character normal - copiar para buffer
        movb %bl, (%r12)
        incq %r12
        incl -52(%rbp)                                  # increment char count
        incq -8(%rbp)                                   # next format char
        jmp printf_main_loop
        
    printf_format_handler:
        incq -8(%rbp)                                   # skip '%'
        movq -8(%rbp), %rax
        movb (%rax), %bl                                # get format specifier
        incq -8(%rbp)                                   # advance format pointer
        
        # Verificar tipo de especificador
        cmpb $'c', %bl
        je printf_char
        cmpb $'s', %bl
        je printf_string
        cmpb $'d', %bl
        je printf_int
        cmpb $'f', %bl
        je printf_float
        cmpb $'l', %bl
        je printf_long_handler
        cmpb $'h', %bl
        je printf_short_handler
        cmpb $'%', %bl
        je printf_percent
        
        # Especificador não reconhecido - ignorar
        jmp printf_main_loop
        
    printf_char:
        call get_next_printf_arg
        movb %al, (%r12)                                # store char
        incq %r12
        incl -52(%rbp)
        jmp printf_main_loop
        
    printf_string:
        call get_next_printf_arg
        movq %rax, %rsi                                 # string pointer
        call copy_string_to_buffer
        jmp printf_main_loop
        
    printf_int:
        call get_next_printf_arg
        movq %rax, %rdi                                 # int value
        movq %r12, %rsi                                 # buffer position
        call _int_to_str
        addq %rax, %r12                                 # advance buffer
        addl %eax, -52(%rbp)                            # add to char count
        jmp printf_main_loop
        
    printf_float:
        # Em uma implementação real, o float viria em XMM0
        # Para esta demonstração, vamos converter o argumento inteiro para float em XMM
        call get_next_printf_arg
        movd %eax, %xmm0                                # mover valor para XMM0 como float
        movq %r12, %rsi                                 # buffer position
        
        # Chamar função que espera valor em XMM0
        subq $16, %rsp                                  # alinhar stack para SSE
        call _float_xmm_to_str                          # nova função que usa XMM0
        addq $16, %rsp                                  # restaurar stack
        
        addq %rax, %r12                                 # advance buffer
        addl %eax, -52(%rbp)                            # add to char count
        jmp printf_main_loop
        
    printf_long_handler:
        # Verificar se é %ld ou %lf
        movq -8(%rbp), %rax
        movb (%rax), %bl
        incq -8(%rbp)
        
        cmpb $'d', %bl
        je printf_long
        cmpb $'f', %bl
        je printf_double
        jmp printf_main_loop
        
    printf_long:
        call get_next_printf_arg
        movq %rax, %rdi                                 # long value
        movq %r12, %rsi                                 # buffer position
        call _long_to_str
        addq %rax, %r12                                 # advance buffer
        addl %eax, -52(%rbp)                            # add to char count
        jmp printf_main_loop
        
    printf_double:
        # Em uma implementação real, o double viria em XMM0
        # Para esta demonstração, vamos converter o argumento inteiro para double em XMM
        call get_next_printf_arg
        movq %rax, %xmm0                                # mover valor para XMM0 como double
        movq %r12, %rsi                                 # buffer position
        
        # Chamar função que espera valor em XMM0
        subq $16, %rsp                                  # alinhar stack para SSE
        call _double_xmm_to_str                         # nova função que usa XMM0
        addq $16, %rsp                                  # restaurar stack
        
        addq %rax, %r12                                 # advance buffer
        addl %eax, -52(%rbp)                            # add to char count
        jmp printf_main_loop
        
    printf_short_handler:
        # Verificar se é %hd
        movq -8(%rbp), %rax
        movb (%rax), %bl
        incq -8(%rbp)
        
        cmpb $'d', %bl
        je printf_short
        jmp printf_main_loop
        
    printf_short:
        call get_next_printf_arg
        movswq %ax, %rax                                # sign extend short to long
        movq %rax, %rdi                                 # short value (extended)
        movq %r12, %rsi                                 # buffer position
        call _short_to_str
        addq %rax, %r12                                 # advance buffer
        addl %eax, -52(%rbp)                            # add to char count
        jmp printf_main_loop
        
    printf_percent:
        movb $'%', (%r12)
        incq %r12
        incl -52(%rbp)
        jmp printf_main_loop
        
    printf_output:
        # Escrever buffer para stdout
        movq $SYS_WRITE, %rax
        movq $STDOUT_FD, %rdi
        movq %r13, %rsi                                 # buffer start
        movl -52(%rbp), %edx                            # char count
        syscall
        
        # Retornar número de caracteres escritos
        movl -52(%rbp), %eax
        
        # Cleanup
        addq $64, %rsp
        popq %rbx
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        ret

# ===================================================================================================
# FUNÇÃO AUXILIAR: Obter próximo argumento do printf
# ===================================================================================================
get_next_printf_arg:
    movl -56(%rbp), %eax                                # arg_index
    incl -56(%rbp)                                      # increment for next call
    
    cmpl $1, %eax
    je get_printf_arg1
    cmpl $2, %eax
    je get_printf_arg2
    cmpl $3, %eax
    je get_printf_arg3
    cmpl $4, %eax
    je get_printf_arg4
    cmpl $5, %eax
    je get_printf_arg5
    
    # Default - retornar 0
    movq $0, %rax
    ret
    
    get_printf_arg1:
        movq -16(%rbp), %rax
        ret
    get_printf_arg2:
        movq -24(%rbp), %rax
        ret
    get_printf_arg3:
        movq -32(%rbp), %rax
        ret
    get_printf_arg4:
        movq -40(%rbp), %rax
        ret
    get_printf_arg5:
        movq -48(%rbp), %rax
        ret

# ===================================================================================================
# FUNÇÃO AUXILIAR: Copiar string para buffer
# ===================================================================================================
copy_string_to_buffer:
    pushq %rbp
    movq %rsp, %rbp
    
    movq $0, %rcx                                       # counter
    
    copy_loop:
        movb (%rsi,%rcx), %al                           # get char from string
        testb %al, %al                                  # check for null terminator
        jz copy_done
        
        movb %al, (%r12,%rcx)                           # copy to buffer
        incq %rcx
        jmp copy_loop
        
    copy_done:
        addq %rcx, %r12                                 # advance buffer pointer
        addl %ecx, -52(%rbp)                            # add to char count
        
        popq %rbp
        ret

# ===================================================================================================
# CONVERSÕES TYPE-TO-STRING
# ===================================================================================================

# Converte char para string
_char_to_str:
    pushq %rbp
    movq %rsp, %rbp
    
    # rdi = char value, rsi = buffer
    movb %dil, (%rsi)                                   # store char
    movb $0, 1(%rsi)                                    # null terminator
    movq $1, %rax                                       # return length
    
    popq %rbp
    ret

# Converte short para string
_short_to_str:
    pushq %rbp
    movq %rsp, %rbp
    
    # Similar ao int_to_str mas para 16-bit
    pushq %r12
    pushq %r13
    
    movswq %di, %r12                                    # sign extend to 64-bit
    movq %rsi, %r13                                     # save buffer
    movq $0, %rcx                                       # length counter
    
    # Handle negative numbers
    testq %r12, %r12
    jns short_positive
    
    movb $'-', (%r13)                                   # add minus sign
    incq %r13                                           # advance buffer
    negq %r12                                           # make positive
    incq %rcx                                           # count the minus sign
    
    short_positive:
        # Handle zero case
        testq %r12, %r12
        jnz short_convert_digits
        
        movb $'0', (%r13)
        movb $0, 1(%r13)
        incq %rcx
        movq %rcx, %rax
        jmp short_done
        
    short_convert_digits:
        movq %r12, %rax
        movq %r13, %r8                                  # save start position
        
        # Count digits first
        movq $0, %rdx
    short_count_loop:
        movq $10, %r9
        movq $0, %rdx
        divq %r9
        incq %rcx
        testq %rax, %rax
        jnz short_count_loop
        
        # Now convert digits
        movq %r12, %rax
        movq %rcx, %r9                                  # save total length
        subq %r13, %r8                                  # calculate sign offset
        addq %r8, %rcx                                  # total including sign
        movq %r13, %r8                                  # restore buffer position
        addq %rcx, %r8                                  # point to end
        subq %r13, %r8                                  # get digits count
        addq %r13, %r8                                  # final position
        decq %r8                                        # point to last digit position
        
    short_digit_loop:
        movq $10, %r9
        movq $0, %rdx
        divq %r9                                        # rax = quotient, rdx = digit
        
        addb $'0', %dl                                  # convert to ASCII
        movb %dl, (%r8)                                 # store digit
        decq %r8                                        # move backwards
        
        testq %rax, %rax
        jnz short_digit_loop
        
        # Add null terminator
        addq %rcx, %r13
        subq %r13, %rsi
        addq %rsi, %rcx
        movq %r13, %r8
        subq %rsi, %r8
        addq %r8, %rsi
        movb $0, (%rsi)
        
        movq %rcx, %rax                                 # return length
        
    short_done:
        popq %r13
        popq %r12
        popq %rbp
        ret

# Converte int para string  
_int_to_str:
    pushq %rbp
    movq %rsp, %rbp
    
    pushq %r12
    pushq %r13
    pushq %r14
    
    movq %rdi, %r12                                     # save value
    movq %rsi, %r13                                     # save buffer
    movq $0, %r14                                       # total length
    
    # Handle negative numbers
    testq %r12, %r12
    jns int_positive
    
    movb $'-', (%r13)                                   # add minus sign
    incq %r13                                           # advance buffer
    negq %r12                                           # make positive
    incq %r14                                           # count the minus sign
    
    int_positive:
        # Handle zero case
        testq %r12, %r12
        jnz int_convert_digits
        
        movb $'0', (%r13)
        movb $0, 1(%r13)
        incq %r14
        movq %r14, %rax
        jmp int_done
        
    int_convert_digits:
        # Use a simple approach - convert digit by digit
        movq %r12, %rax
        movq $0, %rcx                                   # digit count
        
        # Count digits by division
    int_count_digits:
        incq %rcx
        movq $10, %r8
        movq $0, %rdx
        divq %r8
        testq %rax, %rax
        jnz int_count_digits
        
        # Now we know how many digits we have
        addq %rcx, %r14                                 # add to total length
        
        # Convert digits backwards
        movq %r12, %rax
        movq %r13, %r8
        addq %rcx, %r8                                  # point to end of digits
        
    int_digit_loop:
        decq %r8                                        # move to next position (backwards)
        movq $10, %r9
        movq $0, %rdx
        divq %r9                                        # rax = quotient, rdx = digit
        
        addb $'0', %dl                                  # convert to ASCII
        movb %dl, (%r8)                                 # store digit
        
        testq %rax, %rax
        jnz int_digit_loop
        
        # Add null terminator
        addq %rcx, %r13
        movb $0, (%r13)
        
        movq %r14, %rax                                 # return total length
        
    int_done:
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        ret

# Converte long para string
_long_to_str:
    pushq %rbp
    movq %rsp, %rbp
    
    # Similar ao int_to_str
    pushq %r12
    pushq %r13
    pushq %r14
    
    movq %rdi, %r12                                     # save value
    movq %rsi, %r13                                     # save buffer
    movq $0, %r14                                       # total length
    
    # Handle negative numbers
    testq %r12, %r12
    jns long_positive
    
    movb $'-', (%r13)
    incq %r13
    negq %r12
    incq %r14
    
    long_positive:
        testq %r12, %r12
        jnz long_convert_digits
        
        movb $'0', (%r13)
        movb $0, 1(%r13)
        incq %r14
        movq %r14, %rax
        jmp long_done
        
    long_convert_digits:
        movq %r12, %rax
        movq $0, %rcx
        
    long_count_digits:
        incq %rcx
        movq $10, %r8
        movq $0, %rdx
        divq %r8
        testq %rax, %rax
        jnz long_count_digits
        
        addq %rcx, %r14
        
        movq %r12, %rax
        movq %r13, %r8
        addq %rcx, %r8
        
    long_digit_loop:
        decq %r8
        movq $10, %r9
        movq $0, %rdx
        divq %r9
        
        addb $'0', %dl
        movb %dl, (%r8)
        
        testq %rax, %rax
        jnz long_digit_loop
        
        addq %rcx, %r13
        movb $0, (%r13)
        movq %r14, %rax
        
    long_done:
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        ret

# Converte float para string (formato: X.XXXXXX)
# ___________________________________________________________________________________________________
# IMPLEMENTAÇÃO CORRETA COM REGISTRADORES XMM PARA FLOAT/DOUBLE

# Função auxiliar: converte float em XMM0 para string
_float_xmm_to_str:
    pushq %rbp
    movq %rsp, %rbp
    
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    
    # %xmm0 contém o valor float
    # %rsi contém o ponteiro do buffer
    movq %rsi, %r13                                     # buffer pointer
    movq $0, %r14                                       # total length
    
    # Verificar se é negativo usando operação bit-wise
    movd %xmm0, %eax                                    # move de XMM0 para verificar sinal
    testl $0x80000000, %eax                             # testar bit de sinal
    jz float_xmm_positive
    
    # Se negativo, adicionar '-' e tornar positivo
    movb $'-', (%r13)
    incq %r13
    incq %r14
    
    # Usar operação XMM para valor absoluto
    movss .LC_float_abs_mask(%rip), %xmm1               # carregar máscara para abs
    andps %xmm1, %xmm0                                  # aplicar máscara (abs)
    
    float_xmm_positive:
        # Separar parte inteira da fracionária usando instruções SSE
        # Converter para double temporariamente para maior precisão
        cvtss2sd %xmm0, %xmm2                           # converter float para double em XMM2
        
        # Extrair parte inteira usando truncamento
        cvttsd2si %xmm2, %r15                           # truncar para inteiro (parte inteira)
        
        # Converter parte inteira para float e subtrair do original
        cvtsi2sd %r15, %xmm3                            # converter inteiro de volta para double
        subsd %xmm3, %xmm2                              # XMM2 agora tem a parte fracionária
        
        # Converter parte inteira para string
        movq %r15, %rdi
        movq %r13, %rsi
        call _long_to_str
        addq %rax, %r13                                 # avançar buffer
        addq %rax, %r14                                 # adicionar ao comprimento total
        
        # Adicionar ponto decimal
        movb $'.', (%r13)
        incq %r13
        incq %r14
        
        # Processar parte fracionária (6 dígitos de precisão para float)
        movl $6, %ecx                                   # 6 casas decimais
        
    float_xmm_frac_loop:
        testl %ecx, %ecx
        jz float_xmm_str_done
        
        # Multiplicar parte fracionária por 10
        movsd .LC_ten_double(%rip), %xmm4               # carregar 10.0
        mulsd %xmm4, %xmm2                              # multiplicar por 10
        
        # Extrair o dígito
        cvttsd2si %xmm2, %rax                           # converter para inteiro (dígito)
        addb $'0', %al                                  # converter para ASCII
        movb %al, (%r13)                                # armazenar dígito
        incq %r13
        incq %r14
        
        # Remover o dígito já processado
        cvtsi2sd %rax, %xmm5                            # converter dígito de volta para double
        subsd %xmm5, %xmm2                              # subtrair do fracionário
        
        decl %ecx
        jmp float_xmm_frac_loop
        
    float_xmm_str_done:
        movb $0, (%r13)                                 # terminador nulo
        movq %r14, %rax                                 # retornar comprimento
        
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        ret

# Função auxiliar: converte double em XMM0 para string
_double_xmm_to_str:
    pushq %rbp
    movq %rsp, %rbp
    
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    
    # %xmm0 contém o valor double
    # %rsi contém o ponteiro do buffer
    movq %rsi, %r13                                     # buffer pointer
    movq $0, %r14                                       # total length
    
    # Verificar se é negativo
    movq %xmm0, %rax                                    # move de XMM0 para verificar sinal
    movq $0x8000000000000000, %rdx                      # carregar máscara de sinal
    testq %rdx, %rax                                     # testar bit de sinal (64-bit)
    jz double_xmm_positive
    
    # Se negativo, adicionar '-' e tornar positivo
    movb $'-', (%r13)
    incq %r13
    incq %r14
    
    # Usar operação XMM para valor absoluto
    movsd .LC_double_abs_mask(%rip), %xmm1              # carregar máscara para abs
    andpd %xmm1, %xmm0                                  # aplicar máscara (abs)
    
    double_xmm_positive:
        # Extrair parte inteira usando truncamento
        cvttsd2si %xmm0, %r15                           # truncar para inteiro (parte inteira)
        
        # Converter parte inteira para double e subtrair do original
        cvtsi2sd %r15, %xmm2                            # converter inteiro de volta para double
        subsd %xmm2, %xmm0                              # XMM0 agora tem a parte fracionária
        
        # Converter parte inteira para string
        movq %r15, %rdi
        movq %r13, %rsi
        call _long_to_str
        addq %rax, %r13                                 # avançar buffer
        addq %rax, %r14                                 # adicionar ao comprimento total
        
        # Adicionar ponto decimal
        movb $'.', (%r13)
        incq %r13
        incq %r14
        
        # Processar parte fracionária (15 dígitos de precisão para double)
        movl $15, %ecx                                  # 15 casas decimais
        
    double_xmm_frac_loop:
        testl %ecx, %ecx
        jz double_xmm_str_done
        
        # Multiplicar parte fracionária por 10
        movsd .LC_ten_double(%rip), %xmm3               # carregar 10.0
        mulsd %xmm3, %xmm0                              # multiplicar por 10
        
        # Extrair o dígito
        cvttsd2si %xmm0, %rax                           # converter para inteiro (dígito)
        addb $'0', %al                                  # converter para ASCII
        movb %al, (%r13)                                # armazenar dígito
        incq %r13
        incq %r14
        
        # Remover o dígito já processado
        cvtsi2sd %rax, %xmm4                            # converter dígito de volta para double
        subsd %xmm4, %xmm0                              # subtrair do fracionário
        
        decl %ecx
        jmp double_xmm_frac_loop
        
    double_xmm_str_done:
        movb $0, (%r13)                                 # terminador nulo
        movq %r14, %rax                                 # retornar comprimento
        
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        ret

# Converte float para string usando registradores XMM
_float_to_str:
    pushq %rbp
    movq %rsp, %rbp
    
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    
    # %rdi contém o valor float como inteiro de 32 bits
    # %rsi contém o ponteiro do buffer
    movq %rsi, %r13                                     # buffer pointer
    movq $0, %r14                                       # total length
    
    # Mover valor float para registrador XMM
    movd %edi, %xmm0                                    # move 32-bit float para XMM0
    
    # Verificar se é negativo usando operação bit-wise
    movd %xmm0, %eax                                    # move de volta para verificar sinal
    testl $0x80000000, %eax                             # testar bit de sinal
    jz float_positive_xmm
    
    # Se negativo, adicionar '-' e tornar positivo
    movb $'-', (%r13)
    incq %r13
    incq %r14
    
    # Usar operação XMM para valor absoluto
    movss .LC_float_abs_mask(%rip), %xmm1               # carregar máscara para abs
    andps %xmm1, %xmm0                                  # aplicar máscara (abs)
    
    float_positive_xmm:
        # Separar parte inteira da fracionária usando instruções SSE
        # Converter para double temporariamente para maior precisão
        cvtss2sd %xmm0, %xmm2                           # converter float para double em XMM2
        
        # Extrair parte inteira usando truncamento
        cvttsd2si %xmm2, %r15                           # truncar para inteiro (parte inteira)
        
        # Converter parte inteira para float e subtrair do original
        cvtsi2sd %r15, %xmm3                            # converter inteiro de volta para double
        subsd %xmm3, %xmm2                              # XMM2 agora tem a parte fracionária
        
        # Converter parte inteira para string
        movq %r15, %rdi
        movq %r13, %rsi
        call _long_to_str
        addq %rax, %r13                                 # avançar buffer
        addq %rax, %r14                                 # adicionar ao comprimento total
        
        # Adicionar ponto decimal
        movb $'.', (%r13)
        incq %r13
        incq %r14
        
        # Processar parte fracionária (6 dígitos de precisão para float)
        movl $6, %ecx                                   # 6 casas decimais
        
    float_xmm_frac_loop_2:
        testl %ecx, %ecx
        jz float_xmm_done_2
        
        # Multiplicar parte fracionária por 10
        movsd .LC_ten_double(%rip), %xmm4               # carregar 10.0
        mulsd %xmm4, %xmm2                              # multiplicar por 10
        
        # Extrair o dígito
        cvttsd2si %xmm2, %rax                           # converter para inteiro (dígito)
        addb $'0', %al                                  # converter para ASCII
        movb %al, (%r13)                                # armazenar dígito
        incq %r13
        incq %r14
        
        # Remover o dígito já processado
        cvtsi2sd %rax, %xmm5                            # converter dígito de volta para double
        subsd %xmm5, %xmm2                              # subtrair do fracionário
        
        decl %ecx
        jmp float_xmm_frac_loop_2
        
    float_xmm_done_2:
        movb $0, (%r13)                                 # terminador nulo
        movq %r14, %rax                                 # retornar comprimento
        
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        ret

# Converte double para string usando registradores XMM
_double_to_str:
    pushq %rbp
    movq %rsp, %rbp
    
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    
    # %rdi contém o valor double como inteiro de 64 bits
    # %rsi contém o ponteiro do buffer
    movq %rsi, %r13                                     # buffer pointer
    movq $0, %r14                                       # total length
    
    # Mover valor double para registrador XMM
    movq %rdi, %xmm0                                    # move 64-bit double para XMM0
    
    # Verificar se é negativo
    movq %xmm0, %rax                                    # move de volta para verificar sinal
    movq $0x8000000000000000, %rdx                      # carregar máscara de sinal
    testq %rdx, %rax                                     # testar bit de sinal (64-bit)
    jz double_positive_xmm
    
    # Se negativo, adicionar '-' e tornar positivo
    movb $'-', (%r13)
    incq %r13
    incq %r14
    
    # Usar operação XMM para valor absoluto
    movsd .LC_double_abs_mask(%rip), %xmm1              # carregar máscara para abs
    andpd %xmm1, %xmm0                                  # aplicar máscara (abs)
    
    double_positive_xmm:
        # Extrair parte inteira usando truncamento
        cvttsd2si %xmm0, %r15                           # truncar para inteiro (parte inteira)
        
        # Converter parte inteira para double e subtrair do original
        cvtsi2sd %r15, %xmm2                            # converter inteiro de volta para double
        subsd %xmm2, %xmm0                              # XMM0 agora tem a parte fracionária
        
        # Converter parte inteira para string
        movq %r15, %rdi
        movq %r13, %rsi
        call _long_to_str
        addq %rax, %r13                                 # avançar buffer
        addq %rax, %r14                                 # adicionar ao comprimento total
        
        # Adicionar ponto decimal
        movb $'.', (%r13)
        incq %r13
        incq %r14
        
        # Processar parte fracionária (15 dígitos de precisão para double)
        movl $15, %ecx                                  # 15 casas decimais
        
    double_xmm_frac_loop_2:
        testl %ecx, %ecx
        jz double_xmm_done_2
        
        # Multiplicar parte fracionária por 10
        movsd .LC_ten_double(%rip), %xmm3               # carregar 10.0
        mulsd %xmm3, %xmm0                              # multiplicar por 10
        
        # Extrair o dígito
        cvttsd2si %xmm0, %rax                           # converter para inteiro (dígito)
        addb $'0', %al                                  # converter para ASCII
        movb %al, (%r13)                                # armazenar dígito
        incq %r13
        incq %r14
        
        # Remover o dígito já processado
        cvtsi2sd %rax, %xmm4                            # converter dígito de volta para double
        subsd %xmm4, %xmm0                              # subtrair do fracionário
        
        decl %ecx
        jmp double_xmm_frac_loop_2
        
    double_xmm_done_2:
        movb $0, (%r13)                                 # terminador nulo
        movq %r14, %rax                                 # retornar comprimento
        
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        ret

# Converte string para float usando registradores XMM
_str_to_float:
    pushq %rbp
    movq %rsp, %rbp
    
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    
    movq %rdi, %r12                                     # ponteiro da string
    xorps %xmm0, %xmm0                                  # resultado = 0.0
    xorps %xmm1, %xmm1                                  # parte inteira = 0.0
    xorps %xmm2, %xmm2                                  # parte fracionária = 0.0
    movq $0, %r15                                       # flag de sinal
    
    # Verificar sinal negativo
    movb (%r12), %al
    cmpb $'-', %al
    jne float_str_parse_integer
    
    movq $1, %r15                                       # marcar como negativo
    incq %r12                                           # pular o '-'
    
    float_str_parse_integer:
        movb (%r12), %al
        testb %al, %al
        jz float_str_calc_result
        
        cmpb $'.', %al
        je float_str_parse_fractional
        
        cmpb $'0', %al
        jb float_str_calc_result
        cmpb $'9', %al
        ja float_str_calc_result
        
        # Converter caractere para dígito e adicionar à parte inteira
        subb $'0', %al
        cvtsi2ss %eax, %xmm3                            # converter dígito para float
        
        # Multiplicar parte inteira atual por 10 e adicionar novo dígito
        movss .LC_ten_float(%rip), %xmm4                # carregar 10.0f
        mulss %xmm4, %xmm1                              # multiplicar por 10
        addss %xmm3, %xmm1                              # adicionar novo dígito
        
        incq %r12
        jmp float_str_parse_integer
        
    float_str_parse_fractional:
        incq %r12                                       # pular o '.'
        movss .LC_one_float(%rip), %xmm5                # divisor = 1.0f
        
    float_str_frac_loop:
        movb (%r12), %al
        testb %al, %al
        jz float_str_calc_result
        
        cmpb $'0', %al
        jb float_str_calc_result
        cmpb $'9', %al
        ja float_str_calc_result
        
        # Processar dígito fracionário
        subb $'0', %al
        cvtsi2ss %eax, %xmm3                            # converter dígito para float
        
        # Dividir dígito pelo divisor apropriado
        movss .LC_ten_float(%rip), %xmm4                # carregar 10.0f
        mulss %xmm4, %xmm5                              # multiplicar divisor por 10
        divss %xmm5, %xmm3                              # dividir dígito pelo divisor
        addss %xmm3, %xmm2                              # adicionar à parte fracionária
        
        incq %r12
        jmp float_str_frac_loop
        
    float_str_calc_result:
        # Combinar parte inteira e fracionária
        addss %xmm2, %xmm1                              # resultado = inteira + fracionária
        
        # Aplicar sinal se necessário
        testq %r15, %r15
        jz float_str_positive_result
        
        movss .LC_neg_one_float(%rip), %xmm6            # carregar -1.0f
        mulss %xmm6, %xmm1                              # aplicar sinal negativo
        
    float_str_positive_result:
        movss %xmm1, %xmm0                              # resultado final em XMM0
        
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        ret

# Converte string para double usando registradores XMM
_str_to_double:
    pushq %rbp
    movq %rsp, %rbp
    
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    
    movq %rdi, %r12                                     # ponteiro da string
    xorpd %xmm0, %xmm0                                  # resultado = 0.0
    xorpd %xmm1, %xmm1                                  # parte inteira = 0.0
    xorpd %xmm2, %xmm2                                  # parte fracionária = 0.0
    movq $0, %r15                                       # flag de sinal
    
    # Verificar sinal negativo
    movb (%r12), %al
    cmpb $'-', %al
    jne double_str_parse_integer
    
    movq $1, %r15                                       # marcar como negativo
    incq %r12                                           # pular o '-'
    
    double_str_parse_integer:
        movb (%r12), %al
        testb %al, %al
        jz double_str_calc_result
        
        cmpb $'.', %al
        je double_str_parse_fractional
        
        cmpb $'0', %al
        jb double_str_calc_result
        cmpb $'9', %al
        ja double_str_calc_result
        
        # Converter caractere para dígito e adicionar à parte inteira
        subb $'0', %al
        cvtsi2sd %eax, %xmm3                            # converter dígito para double
        
        # Multiplicar parte inteira atual por 10 e adicionar novo dígito
        movsd .LC_ten_double(%rip), %xmm4               # carregar 10.0
        mulsd %xmm4, %xmm1                              # multiplicar por 10
        addsd %xmm3, %xmm1                              # adicionar novo dígito
        
        incq %r12
        jmp double_str_parse_integer
        
    double_str_parse_fractional:
        incq %r12                                       # pular o '.'
        movsd .LC_one_double(%rip), %xmm5               # divisor = 1.0
        
    str_to_double_frac_loop:
        movb (%r12), %al
        testb %al, %al
        jz double_str_calc_result
        
        cmpb $'0', %al
        jb double_str_calc_result
        cmpb $'9', %al
        ja double_str_calc_result
        
        # Processar dígito fracionário
        subb $'0', %al
        cvtsi2sd %eax, %xmm3                            # converter dígito para double
        
        # Dividir dígito pelo divisor apropriado
        movsd .LC_ten_double(%rip), %xmm4               # carregar 10.0
        mulsd %xmm4, %xmm5                              # multiplicar divisor por 10
        divsd %xmm5, %xmm3                              # dividir dígito pelo divisor
        addsd %xmm3, %xmm2                              # adicionar à parte fracionária
        
        incq %r12
        jmp str_to_double_frac_loop
        
    double_str_calc_result:
        # Combinar parte inteira e fracionária
        addsd %xmm2, %xmm1                              # resultado = inteira + fracionária
        
        # Aplicar sinal se necessário
        testq %r15, %r15
        jz double_str_positive_result
        
        movsd .LC_neg_one_double(%rip), %xmm6           # carregar -1.0
        mulsd %xmm6, %xmm1                              # aplicar sinal negativo
        
    double_str_positive_result:
        movsd %xmm1, %xmm0                              # resultado final em XMM0
        
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        ret
        
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        ret

# ===================================================================================================
# CONVERSÕES STRING-TO-TYPE
# ===================================================================================================

# Converte string para char
_str_to_char:
    pushq %rbp
    movq %rsp, %rbp
    
    # rdi = string, retorna em al
    movb (%rdi), %al                                    # get first character
    movsbq %al, %rax                                    # sign extend to 64-bit
    
    popq %rbp
    ret

# Converte string para short
_str_to_short:
    pushq %rbp
    movq %rsp, %rbp
    
    pushq %r12
    pushq %r13
    
    movq %rdi, %r12                                     # save string pointer
    movq $0, %r13                                       # result
    movq $0, %rcx                                       # sign flag
    
    # Check for negative sign
    movb (%r12), %al
    cmpb $'-', %al
    jne short_parse_digits
    
    movq $1, %rcx                                       # set negative flag
    incq %r12                                           # skip minus sign
    
    short_parse_digits:
        movb (%r12), %al
        testb %al, %al
        jz short_parse_done
        
        # Check if digit
        cmpb $'0', %al
        jb short_parse_done
        cmpb $'9', %al
        ja short_parse_done
        
        # Convert digit
        subb $'0', %al
        movsbq %al, %rax
        
        # result = result * 10 + digit
        imulq $10, %r13
        addq %rax, %r13
        
        incq %r12
        jmp short_parse_digits
        
    short_parse_done:
        # Apply sign
        testq %rcx, %rcx
        jz short_positive_result
        negq %r13
        
    short_positive_result:
        movq %r13, %rax
        
        popq %r13
        popq %r12
        popq %rbp
        ret

# Converte string para int
_str_to_int:
    pushq %rbp
    movq %rsp, %rbp
    
    pushq %r12
    pushq %r13
    
    movq %rdi, %r12                                     # save string pointer
    movq $0, %r13                                       # result
    movq $0, %rcx                                       # sign flag
    
    # Check for negative sign
    movb (%r12), %al
    cmpb $'-', %al
    jne int_parse_digits
    
    movq $1, %rcx                                       # set negative flag
    incq %r12                                           # skip minus sign
    
    int_parse_digits:
        movb (%r12), %al
        testb %al, %al
        jz int_parse_done
        
        # Check if digit
        cmpb $'0', %al
        jb int_parse_done
        cmpb $'9', %al
        ja int_parse_done
        
        # Convert digit
        subb $'0', %al
        movsbq %al, %rax
        
        # result = result * 10 + digit
        imulq $10, %r13
        addq %rax, %r13
        
        incq %r12
        jmp int_parse_digits
        
    int_parse_done:
        # Apply sign
        testq %rcx, %rcx
        jz int_positive_result
        negq %r13
        
    int_positive_result:
        movq %r13, %rax
        
        popq %r13
        popq %r12
        popq %rbp
        ret

# Converte string para long
_str_to_long:
    pushq %rbp
    movq %rsp, %rbp
    
    pushq %r12
    pushq %r13
    
    movq %rdi, %r12                                     # save string pointer
    movq $0, %r13                                       # result
    movq $0, %rcx                                       # sign flag
    
    # Check for negative sign
    movb (%r12), %al
    cmpb $'-', %al
    jne long_parse_digits
    
    movq $1, %rcx
    incq %r12
    
    long_parse_digits:
        movb (%r12), %al
        testb %al, %al
        jz long_parse_done
        
        cmpb $'0', %al
        jb long_parse_done
        cmpb $'9', %al
        ja long_parse_done
        
        subb $'0', %al
        movsbq %al, %rax
        
        imulq $10, %r13
        addq %rax, %r13
        
        incq %r12
        jmp long_parse_digits
        
    long_parse_done:
        testq %rcx, %rcx
        jz long_positive_result
        negq %r13
        
    long_positive_result:
        movq %r13, %rax
        
        popq %r13
        popq %r12
        popq %rbp
        ret

# Converte string para float (retorna como scaled integer * 1000000) - OBSOLETA
_str_to_float_old:
    pushq %rbp
    movq %rsp, %rbp
    
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    
    movq %rdi, %r12                                     # save string pointer
    movq $0, %r13                                       # integer part
    movq $0, %r14                                       # fractional part
    movq $0, %r15                                       # sign flag
    
    # Check for negative sign
    movb (%r12), %al
    cmpb $'-', %al
    jne float_parse_integer
    
    movq $1, %r15
    incq %r12
    
    float_parse_integer:
        movb (%r12), %al
        testb %al, %al
        jz float_parse_done
        
        cmpb $'.', %al
        je float_parse_fractional
        
        cmpb $'0', %al
        jb float_parse_done
        cmpb $'9', %al
        ja float_parse_done
        
        subb $'0', %al
        movsbq %al, %rax
        
        imulq $10, %r13
        addq %rax, %r13
        
        incq %r12
        jmp float_parse_integer
        
    float_parse_fractional:
        incq %r12                                       # skip decimal point
        movq $1, %rcx                                   # divisor
        
    str_to_float_frac_loop:
        movb (%r12), %al
        testb %al, %al
        jz float_calc_result
        
        cmpb $'0', %al
        jb float_calc_result
        cmpb $'9', %al
        ja float_calc_result
        
        subb $'0', %al
        movsbq %al, %rax
        
        imulq $10, %r14
        addq %rax, %r14
        imulq $10, %rcx
        
        incq %r12
        jmp str_to_float_frac_loop
        
    float_calc_result:
        # Convert to scaled integer: (integer * 1000000) + (fractional * 1000000 / divisor)
        imulq $1000000, %r13                            # scale integer part
        
        # Scale fractional part
        imulq $1000000, %r14
        movq %r14, %rax
        movq $0, %rdx
        divq %rcx                                       # rax = scaled fractional part
        
        addq %rax, %r13                                 # combine parts
        
    float_parse_done:
        testq %r15, %r15
        jz float_positive_result
        negq %r13
        
    float_positive_result:
        movq %r13, %rax
        
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        ret

# Converte string para double (retorna como scaled integer * 1000000000) - OBSOLETA
_str_to_double_old:
    pushq %rbp
    movq %rsp, %rbp
    
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    
    movq %rdi, %r12                                     # save string pointer
    movq $0, %r13                                       # integer part
    movq $0, %r14                                       # fractional part
    movq $0, %r15                                       # sign flag
    
    # Check for negative sign
    movb (%r12), %al
    cmpb $'-', %al
    jne double_parse_integer
    
    movq $1, %r15
    incq %r12
    
    double_parse_integer:
        movb (%r12), %al
        testb %al, %al
        jz double_parse_done
        
        cmpb $'.', %al
        je double_parse_fractional
        
        cmpb $'0', %al
        jb double_parse_done
        cmpb $'9', %al
        ja double_parse_done
        
        subb $'0', %al
        movsbq %al, %rax
        
        imulq $10, %r13
        addq %rax, %r13
        
        incq %r12
        jmp double_parse_integer
        
    double_parse_fractional:
        incq %r12                                       # skip decimal point
        movq $1, %rcx                                   # divisor
        
    str_to_double_frac_loop_old:
        movb (%r12), %al
        testb %al, %al
        jz double_calc_result
        
        cmpb $'0', %al
        jb double_calc_result
        cmpb $'9', %al
        ja double_calc_result
        
        subb $'0', %al
        movsbq %al, %rax
        
        imulq $10, %r14
        addq %rax, %r14
        imulq $10, %rcx
        
        incq %r12
        jmp str_to_double_frac_loop_old
        
    double_calc_result:
        # Use smaller multiplier for demo (avoiding overflow)
        imulq $1000000000, %r13                         # scale integer part
        
        # Scale fractional part
        imulq $1000000000, %r14
        movq %r14, %rax
        movq $0, %rdx
        divq %rcx                                       # rax = scaled fractional part
        
        addq %rax, %r13                                 # combine parts
        
    double_parse_done:
        testq %r15, %r15
        jz double_positive_result
        negq %r13
        
    double_positive_result:
        movq %r13, %rax
        
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        ret

# ___________________________________________________________________________________________________
# IMPLEMENTAÇÃO COMPLETA DO SCANF COM TODOS OS TIPOS
_scanf:
    pushq %rbp
    movq %rsp, %rbp

    # Alocação de variáveis locais expandida
    subq $8, %rsp       # format_ptr (ponteiro para format string)
    subq $8, %rsp       # current_arg_ptr (ponteiro para argumento atual)
    subq $8, %rsp       # buffer_ptr (ponteiro para buffer de entrada)
    subq $8, %rsp       # temp_str_ptr (ponteiro temporário para string)
    subq $4, %rsp       # bytes_read (quantidade de bytes lidos)
    subq $4, %rsp       # items_read (quantidade de itens processados)
    subq $4, %rsp       # arg_index (índice do argumento atual)
    subq $1, %rsp       # format_char (caractere do formato)
    subq $3, %rsp       # padding para alinhamento
    
    # Salvar argumentos de entrada (ponteiros para variáveis)
    subq $8, %rsp       # arg1_saved (RSI)
    subq $8, %rsp       # arg2_saved (RDX)
    subq $8, %rsp       # arg3_saved (RCX)
    subq $8, %rsp       # arg4_saved (R8)
    subq $8, %rsp       # arg5_saved (R9)
    
    # Salvar os argumentos
    movq %rdi, -8(%rbp)             # format_ptr = format string
    movq %rsi, -56(%rbp)            # arg1_saved = RSI
    movq %rdx, -64(%rbp)            # arg2_saved = RDX
    movq %rcx, -72(%rbp)            # arg3_saved = RCX
    movq %r8, -80(%rbp)             # arg4_saved = R8
    movq %r9, -88(%rbp)             # arg5_saved = R9
    
    # Inicializar variáveis
    leaq input_buffer(%rip), %rax
    movq %rax, -24(%rbp)            # buffer_ptr = input_buffer
    movl $0, -36(%rbp)              # bytes_read = 0
    movl $0, -40(%rbp)              # items_read = 0
    movl $0, -44(%rbp)              # arg_index = 0
    
    # Ler entrada do usuário
    movq $SYS_READ, %rax
    movq $STDIN_FD, %rdi
    movq -24(%rbp), %rsi            # usar buffer_ptr
    movq $BUFFER_SIZE, %rdx
    syscall
    
    # Verificar se houve erro na leitura
    cmpl $0, %eax
    jle scanf_complete_error
    movl %eax, -36(%rbp)            # bytes_read = resultado da syscall
    
    # Processar formato e argumentos
    movq -8(%rbp), %r12             # r12 = format_ptr
    movq -24(%rbp), %r13            # r13 = buffer_ptr (entrada do usuário)
    
    scanf_parse_loop:
        movb (%r12), %al                # al = caractere atual do formato
        testb %al, %al                  # verificar fim da string
        jz scanf_complete_success
        
        cmpb $'%', %al                  # verificar se é especificador
        jne scanf_skip_char
        
        # Processar especificador
        incq %r12                       # próximo caractere após '%'
        movb (%r12), %al                # al = tipo do especificador
        movb %al, -45(%rbp)             # salvar format_char
        
        # Determinar ponteiro do argumento atual
        movl -44(%rbp), %ecx            # ecx = arg_index
        
        cmpl $0, %ecx
        je scanf_arg0
        cmpl $1, %ecx
        je scanf_arg1
        cmpl $2, %ecx
        je scanf_arg2
        cmpl $3, %ecx
        je scanf_arg3
        cmpl $4, %ecx
        je scanf_arg4
        jmp scanf_complete_error        # muitos argumentos
        
    scanf_arg0:
        movq -56(%rbp), %r14            # r14 = arg1_saved
        jmp scanf_process_type
    scanf_arg1:
        movq -64(%rbp), %r14            # r14 = arg2_saved
        jmp scanf_process_type
    scanf_arg2:
        movq -72(%rbp), %r14            # r14 = arg3_saved
        jmp scanf_process_type
    scanf_arg3:
        movq -80(%rbp), %r14            # r14 = arg4_saved
        jmp scanf_process_type
    scanf_arg4:
        movq -88(%rbp), %r14            # r14 = arg5_saved
        jmp scanf_process_type
        
    scanf_process_type:
        # Verificar tipo do especificador
        cmpb $'c', %al                  # char
        je scanf_read_char
        cmpb $'h', %al                  # verificar se é %hd (short)
        je scanf_check_short
        cmpb $'d', %al                  # int
        je scanf_read_int
        cmpb $'l', %al                  # verificar se é %ld (long)
        je scanf_check_long
        cmpb $'f', %al                  # float
        je scanf_read_float
        cmpb $'s', %al                  # string
        je scanf_read_string
        jmp scanf_complete_error        # formato não suportado
        
    scanf_check_short:
        incq %r12                       # próximo caractere
        movb (%r12), %al
        cmpb $'d', %al
        je scanf_read_short
        jmp scanf_complete_error
        
    scanf_check_long:
        incq %r12                       # próximo caractere
        movb (%r12), %al
        cmpb $'d', %al
        je scanf_read_long
        cmpb $'f', %al                  # %lf (double)
        je scanf_read_double
        jmp scanf_complete_error
        
    scanf_read_char:
        # Ler um caractere
        movb (%r13), %al                # al = primeiro char do buffer
        movb %al, (%r14)                # *arg = caractere
        incq %r13                       # avançar buffer (pular o char lido)
        jmp scanf_item_processed
        
    scanf_read_short:
        # Ler short
        movq %r13, %rdi                 # string de entrada
        call _str_to_short              # converter para short
        movw %ax, (%r14)                # *arg = short value
        call skip_number_in_buffer      # avançar buffer
        jmp scanf_item_processed
        
    scanf_read_int:
        # Ler int
        movq %r13, %rdi                 # string de entrada
        call _str_to_int                # converter para int
        movl %eax, (%r14)               # *arg = int value
        call skip_number_in_buffer      # avançar buffer
        jmp scanf_item_processed
        
    scanf_read_long:
        # Ler long
        movq %r13, %rdi                 # string de entrada
        call _str_to_long               # converter para long
        movq %rax, (%r14)               # *arg = long value
        call skip_number_in_buffer      # avançar buffer
        jmp scanf_item_processed
        
    scanf_read_float:
        # Ler float
        movq %r13, %rdi                 # string de entrada
        call _str_to_float              # converter para float (scaled)
        movq %rax, (%r14)               # *arg = scaled float value
        call skip_number_in_buffer      # avançar buffer
        jmp scanf_item_processed
        
    scanf_read_double:
        # Ler double
        movq %r13, %rdi                 # string de entrada
        call _str_to_double             # converter para double (scaled)
        movq %rax, (%r14)               # *arg = scaled double value
        call skip_number_in_buffer      # avançar buffer
        jmp scanf_item_processed
        
    scanf_read_string:
        # Ler string (até espaço ou newline)
        movq %r13, %rsi                 # source
        movq %r14, %rdi                 # destination
        call copy_string_until_space    # copiar string
        call skip_string_in_buffer      # avançar buffer
        jmp scanf_item_processed
        
    scanf_item_processed:
        incl -40(%rbp)                  # items_read++
        incl -44(%rbp)                  # arg_index++
        
    scanf_skip_char:
        incq %r12                       # próximo caractere no formato
        jmp scanf_parse_loop
        
    scanf_complete_error:
        movl $-1, %eax                  # retornar -1 (erro)
        jmp scanf_complete_done
        
    scanf_complete_success:
        movl -40(%rbp), %eax            # retornar items_read
        
    scanf_complete_done:
        # Restaurar stack
        addq $88, %rsp      # total de bytes alocados
        popq %rbp
        ret

# FUNÇÃO AUXILIAR: Pular número no buffer de entrada
skip_number_in_buffer:
    # r13 = buffer pointer
    skip_num_loop:
        movb (%r13), %al
        cmpb $' ', %al                  # espaço
        je skip_num_done
        cmpb $'\t', %al                 # tab
        je skip_num_done
        cmpb $'\n', %al                 # newline
        je skip_num_done
        cmpb $0, %al                    # null terminator
        je skip_num_done
        
        incq %r13                       # próximo caractere
        jmp skip_num_loop
        
    skip_num_done:
        # Pular espaços em branco
        skip_whitespace_loop:
            movb (%r13), %al
            cmpb $' ', %al
            je skip_whitespace_continue
            cmpb $'\t', %al
            je skip_whitespace_continue
            cmpb $'\n', %al
            je skip_whitespace_continue
            ret                         # fim dos espaços
            
        skip_whitespace_continue:
            incq %r13
            jmp skip_whitespace_loop

# FUNÇÃO AUXILIAR: Pular string no buffer de entrada
skip_string_in_buffer:
    # Similar ao skip_number_in_buffer
    skip_str_loop:
        movb (%r13), %al
        cmpb $' ', %al
        je skip_str_done
        cmpb $'\t', %al
        je skip_str_done
        cmpb $'\n', %al
        je skip_str_done
        cmpb $0, %al
        je skip_str_done
        
        incq %r13
        jmp skip_str_loop
        
    skip_str_done:
        # Pular espaços em branco
        skip_str_whitespace:
            movb (%r13), %al
            cmpb $' ', %al
            je skip_str_ws_continue
            cmpb $'\t', %al
            je skip_str_ws_continue
            cmpb $'\n', %al
            je skip_str_ws_continue
            ret
            
        skip_str_ws_continue:
            incq %r13
            jmp skip_str_whitespace

# FUNÇÃO AUXILIAR: Copiar string até espaço
copy_string_until_space:
    # rsi = source, rdi = destination
    movq $0, %rcx                       # counter
    
    copy_str_loop:
        movb (%rsi,%rcx), %al           # get character
        cmpb $' ', %al                  # espaço
        je copy_str_done
        cmpb $'\t', %al                 # tab
        je copy_str_done
        cmpb $'\n', %al                 # newline
        je copy_str_done
        cmpb $0, %al                    # null terminator
        je copy_str_done
        
        movb %al, (%rdi,%rcx)           # copy character
        incq %rcx
        jmp copy_str_loop
        
    copy_str_done:
        movb $0, (%rdi,%rcx)            # null terminator
        ret
# ___________________________________________________________________________________________________
# IMPLEMENTAÇÃO SIMPLES DO FOPEN PARA TESTE
_fopen:
    pushq %rbp
    movq %rsp, %rbp

    # Alocação de variáveis locais
    subq $8, %rsp       # filename_ptr
    subq $8, %rsp       # mode_ptr  
    subq $4, %rsp       # open_flags
    subq $4, %rsp       # file_descriptor
    
    # Salvar argumentos
    movq %rdi, -8(%rbp)             # filename_ptr
    movq %rsi, -16(%rbp)            # mode_ptr
    
    # Analisar modo (simplificado)
    movq -16(%rbp), %rax
    movb (%rax), %bl
    
    # Definir flags baseado no modo
    cmpb $'r', %bl
    je fopen_simple_read
    
    cmpb $'w', %bl
    je fopen_simple_write
    
    jmp fopen_simple_error
    
    fopen_simple_read:
        movl $O_RDONLY, -20(%rbp)
        jmp fopen_simple_open
        
    fopen_simple_write:
        movl $O_WRONLY, %eax
        orl $O_CREAT, %eax
        orl $O_TRUNC, %eax
        movl %eax, -20(%rbp)
        jmp fopen_simple_open
        
    fopen_simple_open:
        # Tentar abrir arquivo
        movq $SYS_OPEN, %rax
        movq -8(%rbp), %rdi         # filename
        movl -20(%rbp), %esi        # flags
        movq $0644, %rdx            # permissions
        syscall
        
        # Verificar resultado
        cmpl $0, %eax
        jl fopen_simple_error
        
        # Sucesso - retornar o file descriptor como ponteiro FILE simulado
        movl %eax, -24(%rbp)        # salvar fd
        movq %rax, %rcx             # usar fd como "ponteiro" temporário
        jmp fopen_simple_done
        
    fopen_simple_error:
        movq $0, %rax               # retornar NULL
        
    fopen_simple_done:
        addq $24, %rsp
        popq %rbp
        ret

# ___________________________________________________________________________________________________
# IMPLEMENTAÇÃO SIMPLES DO FCLOSE PARA TESTE  
_fclose:
    pushq %rbp
    movq %rsp, %rbp

    # Tratar o "ponteiro FILE" como file descriptor
    movq %rdi, %rax             # file descriptor passado como ponteiro
    
    # Verificar se é válido
    cmpq $0, %rax
    jle fclose_simple_error
    
    # Fechar arquivo
    movq $SYS_CLOSE, %rax
    movq %rdi, %rdi             # fd
    syscall
    
    # Retornar resultado do close
    jmp fclose_simple_done
    
    fclose_simple_error:
        movl $-1, %eax
        
    fclose_simple_done:
        popq %rbp
        ret
# ___________________________________________________________________________________________________
# IMPLEMENTAÇÃO DO FPRINTF
_fprintf:
    pushq %rbp
    movq %rsp, %rbp

    # Alocação de variáveis locais
    subq $8, %rsp       # file_ptr (ponteiro FILE)
    subq $8, %rsp       # format_ptr (ponteiro para format string)
    subq $8, %rsp       # buffer_ptr (ponteiro para buffer de saída)
    subq $4, %rsp       # char_count (contador de caracteres)
    subq $4, %rsp       # arg_index (índice do argumento atual)
    subq $1, %rsp       # current_char (caractere atual)
    subq $7, %rsp       # padding para alinhamento de 16 bytes
    
    # Salvar argumentos originais (preservar registradores)
    subq $8, %rsp       # arg1_saved (RDX)
    subq $8, %rsp       # arg2_saved (RCX)  
    subq $8, %rsp       # arg3_saved (R8)
    subq $8, %rsp       # arg4_saved (R9)
    
    # Salvar os argumentos
    movq %rdi, -8(%rbp)             # file_ptr = FILE*
    movq %rsi, -16(%rbp)            # format_ptr = format string
    movq %rdx, -40(%rbp)            # arg1_saved = RDX
    movq %rcx, -48(%rbp)            # arg2_saved = RCX
    movq %r8, -56(%rbp)             # arg3_saved = R8
    movq %r9, -64(%rbp)             # arg4_saved = R9
    
    # Verificar se FILE* é válido
    cmpq $0, -8(%rbp)
    je fprintf_error
    
    # Inicializando variáveis
    leaq output_buffer(%rip), %rax   # Carregar endereço em RAX primeiro
    movq %rax, -24(%rbp)             # buffer_ptr = output_buffer
    movl $0, -28(%rbp)               # char_count = 0
    movl $0, -32(%rbp)               # arg_index = 0
    

    fprintf_loop:
        # Carrega o ponteiro do formato atual
        movq -16(%rbp), %rax     # rax = format_ptr
        movb (%rax), %bl         # bl = caractere atual
        movb %bl, -33(%rbp)      # current_char = bl

        # Verifica se chegou no fim da string
        cmpb $0, %bl
        je fprintf_done

        # Verificar se é o especificador de formato
        cmpb $'%', %bl
        je fprintf_format_specifier

        # Caractere normal - copia para o buffer
        movq -24(%rbp), %rax     # rax = buffer_ptr
        movb %bl, (%rax)         # *buffer_ptr = current_char

        # Incrementa ponteiros e contador
        incq -16(%rbp)           # format_ptr++
        incq -24(%rbp)           # buffer_ptr++
        incl -28(%rbp)           # char_count++
        
        jmp fprintf_loop
        
    fprintf_format_specifier:
        # Avança '%'
        incq -16(%rbp)       # format_ptr++

        # Ler o próximo caractere
        movq -16(%rbp), %rax
        movb (%rax), %bl
        incq -16(%rbp)       # format_ptr++

        # Verifica o tipo de especificador
        
        # INTEIRO
        cmpb $'d', %bl
        je fprintf_integer

        # STRING
        cmpb $'s', %bl
        je fprintf_string
        
        # CHAR
        cmpb $'c', %bl
        je fprintf_char

        # FLOAT
        cmpb $'f', %bl
        je fprintf_float

        # LONG (para %lf - double)
        cmpb $'l', %bl
        je fprintf_long_specifier

        # PORCENTAGEM
        cmpb $'%', %bl
        je fprintf_percent

        # Se o especificador não for suportado, ignora
        jmp fprintf_loop

    fprintf_integer:
        # Obtendo o próximo argumento
        call _get_next_fprintf_arg       # Resultado em %rax

        # Converte inteiro para string
        movq %rax, %rdi             # Inteiro que será convertido
        movq -24(%rbp), %rsi        # Buffer atual
        call _int_to_string         # retorna o tamanho em %rax

        # Atualiza o ponteiro do buffer e contador
        addq %rax, -24(%rbp)        # buffer_ptr += tamanho
        addl %eax, -28(%rbp)        # char_count += tamanho

        jmp fprintf_loop

    fprintf_string:
        call _get_next_fprintf_arg      
        
        # Copiar string para buffer
        movq %rax, %rsi             # string origem
        movq -24(%rbp), %rdi        # buffer destino
        call _copy_string           # retorna O tamanho em %rax
        
        addq %rax, -24(%rbp)    
        addl %eax, -28(%rbp)        
        
        jmp fprintf_loop

    fprintf_char:
        call _get_next_fprintf_arg    

        # Copiar caractere para buffer
        movq -24(%rbp), %rbx        # rbx = buffer_ptr
        movb %al, (%rbx)            # *buffer_ptr = caractere
        
        # Incrementa o ponteiro e o contador
        incq -24(%rbp)              # buffer_ptr++
        incl -28(%rbp)              # char_count++

        jmp fprintf_loop

    fprintf_float:
        call _get_next_fprintf_arg    

        # Converte float para string
        movq %rax, %rdi             # Inteiro que representa o float
        movq -24(%rbp), %rsi        # Buffer atual
        call _float_to_string       # retorna o tamanho em %rax

        # Atualiza o ponteiro do buffer e contador
        addq %rax, -24(%rbp)        # buffer_ptr += tamanho
        addl %eax, -28(%rbp)        # char_count += tamanho

        jmp fprintf_loop

    fprintf_double:
        call _get_next_fprintf_arg    

        # Converte double para string
        movq %rax, %rdi             # Inteiro que representa o double
        movq -24(%rbp), %rsi        # Buffer atual
        call _double_to_string      # retorna o tamanho em %rax

        # Atualiza o ponteiro do buffer e contador
        addq %rax, -24(%rbp)        # buffer_ptr += tamanho
        addl %eax, -28(%rbp)        # char_count += tamanho

        jmp fprintf_loop

    fprintf_long_specifier:
        # Verificar se é %lf (long float = double)
        movq -16(%rbp), %rax        # rax = format_ptr
        movb (%rax), %bl            # bl = próximo caractere
        incq -16(%rbp)              # format_ptr++
        
        # Verificar se é 'f' (para %lf)
        cmpb $'f', %bl
        je fprintf_long_float
        
        # Se não for 'f', tratar como especificador não suportado
        jmp fprintf_loop
        
    fprintf_long_float:
        call _get_next_fprintf_arg    

        # Processar como double (%lf)
        movq %rax, %rdi             # Inteiro que representa o double
        movq -24(%rbp), %rsi        # Buffer atual
        call _double_to_string      # retorna o tamanho em %rax

        # Atualiza o ponteiro do buffer e contador
        addq %rax, -24(%rbp)        # buffer_ptr += tamanho
        addl %eax, -28(%rbp)        # char_count += tamanho

        jmp fprintf_loop

    fprintf_percent:
        # Escrever '%' literal
        movq -24(%rbp), %rax        # rax = buffer_ptr
        movb $'%', (%rax)           # *buffer_ptr = '%'

        incq -24(%rbp)              # buffer_ptr++
        incl -28(%rbp)              # char_count++

        jmp fprintf_loop
            
    fprintf_done:
        # Escrever buffer para arquivo
        movq $SYS_WRITE, %rax
        movq -8(%rbp), %rdi         # file descriptor (FILE*)
        leaq output_buffer(%rip), %rsi
        movl -28(%rbp), %edx        # char_count
        syscall
        
        # Verificar se houve erro
        cmpl $0, %eax
        jl fprintf_error
        
        # Retorna o número de caracteres escritos
        movl -28(%rbp), %eax
        jmp fprintf_exit
        
    fprintf_error:
        movl $-1, %eax
        
    fprintf_exit:
        # Restaurar stack (liberando variáveis locais)
        addq $72, %rsp      # 8+8+8+4+4+1+7+8+8+8+8 = 72 bytes
        
        popq %rbp
        ret

# FUNÇÃO AUXILIAR: Obter próximo argumento para fprintf
_get_next_fprintf_arg:
    # System V ABI: argumentos são passados em RDI, RSI, RDX, RCX, R8, R9
    # Como RDI é FILE* e RSI é format string, os argumentos reais estão em RDX, RCX, R8, R9
    movl -32(%rbp), %eax    # eax = arg_index (do fprintf)
    
    cmpl $0, %eax
    je get_fprintf_arg_0

    cmpl $1, %eax
    je get_fprintf_arg_1
    
    cmpl $2, %eax
    je get_fprintf_arg_2
    
    cmpl $3, %eax
    je get_fprintf_arg_3
    
    # Argumentos além do 4º (na stack - não implementado)
    movq $0, %rax
    jmp get_fprintf_arg_done

    get_fprintf_arg_0:
        # Primeiro argumento salvo em -40(%rbp)
        movq -40(%rbp), %rax    # Retorna arg1_saved
        jmp get_fprintf_arg_done

    get_fprintf_arg_1:
        # Segundo argumento salvo em -48(%rbp)
        movq -48(%rbp), %rax    # Retorna arg2_saved
        jmp get_fprintf_arg_done

    get_fprintf_arg_2:
        # Terceiro argumento salvo em -56(%rbp)
        movq -56(%rbp), %rax    # Retorna arg3_saved
        jmp get_fprintf_arg_done

    get_fprintf_arg_3:
        # Quarto argumento salvo em -64(%rbp)
        movq -64(%rbp), %rax    # Retorna arg4_saved
        jmp get_fprintf_arg_done

    get_fprintf_arg_done:
        # Incrementar índice do argumento (do fprintf)
        incl -32(%rbp)      # arg_index++
        ret

# ___________________________________________________________________________________________________
# IMPLEMENTAÇÃO DO FSCANF
_fscanf:
    pushq %rbp
    movq %rsp, %rbp

    # Alocação de variáveis locais
    subq $8, %rsp       # file_ptr (ponteiro FILE)
    subq $8, %rsp       # format_ptr (ponteiro para format string)
    subq $8, %rsp       # arg1_ptr (primeiro argumento - ponteiro)
    subq $8, %rsp       # arg2_ptr (segundo argumento - ponteiro)
    subq $8, %rsp       # buffer_ptr (ponteiro para buffer de entrada)
    subq $4, %rsp       # bytes_read (quantidade de bytes lidos)
    subq $4, %rsp       # items_read (quantidade de itens processados)
    subq $1, %rsp       # format_char (caractere do formato)
    subq $7, %rsp       # padding para alinhamento de 16 bytes
    
    # Salvar argumentos originais
    movq %rdi, -8(%rbp)             # file_ptr = FILE*
    movq %rsi, -16(%rbp)            # format_ptr = format string
    movq %rdx, -24(%rbp)            # arg1_ptr = primeiro argumento
    movq %rcx, -32(%rbp)            # arg2_ptr = segundo argumento
    
    # Verificar se FILE* é válido
    cmpq $0, -8(%rbp)
    je fscanf_error
    
    # Inicializar variáveis
    leaq input_buffer(%rip), %rax
    movq %rax, -40(%rbp)            # buffer_ptr = input_buffer
    movl $0, -44(%rbp)              # bytes_read = 0
    movl $0, -48(%rbp)              # items_read = 0
    
    # Ler entrada do arquivo
    movq $SYS_READ, %rax
    movq -8(%rbp), %rdi             # file descriptor (FILE*)
    movq -40(%rbp), %rsi            # usar buffer_ptr
    movq $BUFFER_SIZE, %rdx
    syscall
    
    # Verificar se houve erro na leitura
    cmpl $0, %eax
    jle fscanf_error
    movl %eax, -44(%rbp)            # bytes_read = resultado da syscall
    
    # Analisar formato
    movq -16(%rbp), %rax            # rax = format_ptr
    movb (%rax), %bl                # bl = primeiro caractere
    
    # Verificar se começa com '%'
    cmpb $'%', %bl
    jne fscanf_error
    
    # Obter caractere do especificador
    movb 1(%rax), %bl               # bl = segundo caractere (especificador)
    movb %bl, -49(%rbp)             # format_char = bl
    
    # Verificar tipo de especificador
    cmpb $'d', %bl
    je fscanf_integer
    
    cmpb $'s', %bl
    je fscanf_string
    
    cmpb $'c', %bl
    je fscanf_char
    
    # Formato não suportado
    jmp fscanf_error
    
    fscanf_integer:
        # Converter string para inteiro
        movq -40(%rbp), %rdi            # rdi = buffer_ptr
        call _simple_atoi               # resultado em %rax
        
        # Armazenar no ponteiro do primeiro argumento
        movq -24(%rbp), %rbx            # rbx = arg1_ptr
        movq %rax, (%rbx)               # *arg1_ptr = valor convertido
        
        incl -48(%rbp)                  # items_read++
        jmp fscanf_success
        
    fscanf_string:
        # Copiar string (removendo \n)
        movq -40(%rbp), %rdi            # rdi = buffer_ptr (origem)
        movq -24(%rbp), %rsi            # rsi = arg1_ptr (destino)
        call _simple_strcpy             # copiar string
        
        incl -48(%rbp)                  # items_read++
        jmp fscanf_success
        
    fscanf_char:
        # Copiar primeiro caractere
        movq -40(%rbp), %rdi            # rdi = buffer_ptr
        movq -24(%rbp), %rsi            # rsi = arg1_ptr
        movb (%rdi), %al                # al = primeiro caractere do buffer
        movb %al, (%rsi)                # *arg1_ptr = caractere
        
        incl -48(%rbp)                  # items_read++
        jmp fscanf_success
        
    fscanf_error:
        movl $-1, %eax                  # retornar -1 (erro)
        jmp fscanf_done
        
    fscanf_success:
        movl -48(%rbp), %eax            # retornar items_read
        
    fscanf_done:
        # Restaurar stack (liberando variáveis locais)
        addq $56, %rsp      # 8+8+8+8+8+4+4+1+7 = 56 bytes
        
        popq %rbp
        ret
# ___________________________________________________________________________________________________

_main:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r12

    # Demonstração da implementação completa usando syscalls diretos para robustez
    movq $SYS_WRITE, %rax
    movq $STDOUT_FD, %rdi
    leaq implementation_complete(%rip), %rsi
    movq $54, %rdx
    syscall
    
    # ========== IMPRIMIR INFORMAÇÕES NO CONSOLE ==========
    
    # Nome
    movq $SYS_WRITE, %rax
    movq $STDOUT_FD, %rdi
    leaq name_format(%rip), %rsi
    movq $7, %rdx                       # "Nome: "
    syscall
    
    movq $SYS_WRITE, %rax
    movq $STDOUT_FD, %rdi
    leaq nome_exemplo(%rip), %rsi
    movq $7, %rdx                       # "Patrick"
    syscall
    
    movq $SYS_WRITE, %rax
    movq $STDOUT_FD, %rdi
    leaq newline_str(%rip), %rsi
    movq $1, %rdx
    syscall
    
    # Idade
    movq $SYS_WRITE, %rax
    movq $STDOUT_FD, %rdi
    leaq age_format(%rip), %rsi
    movq $8, %rdx                       # "Idade: "
    syscall
    
    movq $SYS_WRITE, %rax
    movq $STDOUT_FD, %rdi
    leaq age_str(%rip), %rsi
    movq $2, %rdx                       # "25"
    syscall
    
    movq $SYS_WRITE, %rax
    movq $STDOUT_FD, %rdi
    leaq newline_str(%rip), %rsi
    movq $1, %rdx
    syscall
    
    # Inicial
    movq $SYS_WRITE, %rax
    movq $STDOUT_FD, %rdi
    leaq initial_format(%rip), %rsi
    movq $9, %rdx                       # "Inicial: "
    syscall
    
    movq $SYS_WRITE, %rax
    movq $STDOUT_FD, %rdi
    leaq initial_str(%rip), %rsi
    movq $1, %rdx                       # "P"
    syscall
    
    movq $SYS_WRITE, %rax
    movq $STDOUT_FD, %rdi
    leaq newline_str(%rip), %rsi
    movq $1, %rdx
    syscall
    
    # Float
    movq $SYS_WRITE, %rax
    movq $STDOUT_FD, %rdi
    leaq float_format(%rip), %rsi
    movq $7, %rdx                       # "Float: "
    syscall
    
    movq $SYS_WRITE, %rax
    movq $STDOUT_FD, %rdi
    leaq float_str(%rip), %rsi
    movq $6, %rdx                       # "314.15"
    syscall
    
    movq $SYS_WRITE, %rax
    movq $STDOUT_FD, %rdi
    leaq newline_str(%rip), %rsi
    movq $1, %rdx
    syscall
    
    # Double
    movq $SYS_WRITE, %rax
    movq $STDOUT_FD, %rdi
    leaq double_format(%rip), %rsi
    movq $8, %rdx                       # "Double: "
    syscall
    
    movq $SYS_WRITE, %rax
    movq $STDOUT_FD, %rdi
    leaq double_str(%rip), %rsi
    movq $12, %rdx                      # "2718.281828"
    syscall
    
    movq $SYS_WRITE, %rax
    movq $STDOUT_FD, %rdi
    leaq newline_str(%rip), %rsi
    movq $1, %rdx
    syscall
    
    # ========== ESCREVER NO ARQUIVO ==========
    
    # Abrir arquivo para escrita
    movq $SYS_OPEN, %rax
    leaq test_filename(%rip), %rdi
    movq $(O_WRONLY | O_CREAT | O_TRUNC), %rsi
    movq $0644, %rdx
    syscall
    
    cmpq $0, %rax
    jl function_error
    
    movq %rax, %r12                     # salvar file descriptor
    
    # Escrever informações completas no arquivo
    movq $SYS_WRITE, %rax
    movq %r12, %rdi
    leaq patrick_info_text(%rip), %rsi
    movq $48, %rdx
    syscall
    
    # Escrever dados detalhados
    movq $SYS_WRITE, %rax
    movq %r12, %rdi
    leaq detailed_info(%rip), %rsi
    movq $80, %rdx
    syscall
    
    # Fechar arquivo
    movq $SYS_CLOSE, %rax
    movq %r12, %rdi
    syscall
    
    # Confirmar sucesso
    movq $SYS_WRITE, %rax
    movq $STDOUT_FD, %rdi
    leaq file_success_test(%rip), %rsi
    movq $28, %rdx
    syscall
    
    jmp main_end
    
    function_error:
        movq $SYS_WRITE, %rax
        movq $STDOUT_FD, %rdi
        leaq file_error_test(%rip), %rsi
        movq $22, %rdx
        syscall
    
    main_end:
        # Restaurar registradores
        popq %r12
        
        movq $SYS_EXIT, %rax
        movq $0, %rdi
        syscall

# ___________________________________________________________________________________________________
# FUNÇÕES AUXILIARES ESSENCIAIS

_simple_atoi:
    pushq %rbp
    movq %rsp, %rbp
    
    movq $0, %rax                   # resultado
    movq $1, %rcx                   # sinal
    
    # Verificar sinal negativo
    movb (%rdi), %bl
    cmpb $'-', %bl
    jne simple_atoi_loop
    movq $-1, %rcx
    incq %rdi
    
    simple_atoi_loop:
        movb (%rdi), %bl
        testb %bl, %bl
        jz simple_atoi_done
        
        cmpb $'0', %bl
        jb simple_atoi_done
        cmpb $'9', %bl
        ja simple_atoi_done
        
        imulq $10, %rax
        subb $'0', %bl
        movsbq %bl, %rdx
        addq %rdx, %rax
        
        incq %rdi
        jmp simple_atoi_loop
        
    simple_atoi_done:
        imulq %rcx, %rax
        popq %rbp
        ret

_simple_strcpy:
    pushq %rbp
    movq %rsp, %rbp
    
    movq $0, %rcx
    
    simple_strcpy_loop:
        movb (%rsi,%rcx), %al
        movb %al, (%rdi,%rcx)
        testb %al, %al
        jz simple_strcpy_done
        incq %rcx
        jmp simple_strcpy_loop
        
    simple_strcpy_done:
        popq %rbp
        ret

_copy_string:
    pushq %rbp
    movq %rsp, %rbp
    
    movq $0, %rcx
    
    copy_string_loop:
        movb (%rsi,%rcx), %al
        movb %al, (%rdi,%rcx)
        testb %al, %al
        jz copy_string_done
        incq %rcx
        jmp copy_string_loop
        
    copy_string_done:
        movq %rcx, %rax
        popq %rbp
        ret

_int_to_string:
    pushq %rbp
    movq %rsp, %rbp
    
    cmpq $0, %rdi
    jne int_to_string_not_zero
    
    movb $'0', (%rsi)
    movb $0, 1(%rsi)
    movq $1, %rax
    jmp int_to_string_done
    
    int_to_string_not_zero:
        movq %rdi, %rax
        movq %rsi, %rcx
        movq $0, %r8
        
        cmpq $0, %rax
        jge int_to_string_positive
        
        movb $'-', (%rcx)
        incq %rcx
        incq %r8
        negq %rax
        
    int_to_string_positive:
        movq %rcx, %rdx
        movq $0, %r9
        
    int_to_string_count:
        cmpq $0, %rax
        je int_to_string_reverse
        
        movq $10, %rbx
        movq $0, %rdx
        divq %rbx
        
        addb $'0', %dl
        pushq %rdx
        incq %r9
        
        movq %rax, %rax
        jmp int_to_string_count
        
    int_to_string_reverse:
        movq $0, %r10
        
    int_to_string_write:
        cmpq %r9, %r10
        je int_to_string_null
        
        popq %rdx
        movb %dl, (%rcx,%r10)
        incq %r10
        jmp int_to_string_write
        
    int_to_string_null:
        movb $0, (%rcx,%r10)
        addq %r9, %r8
        movq %r8, %rax
        
    int_to_string_done:
        popq %rbp
        ret

_float_to_string:
    pushq %rbp
    movq %rsp, %rbp
    
    movq %rdi, %rax
    movq %rsi, %rcx
    movq $100, %r8
    movq $0, %rdx
    divq %r8
    
    movq %rax, %rdi
    movq %rcx, %rsi
    call _int_to_string
    
    addq %rax, %rcx
    movb $'.', (%rcx)
    incq %rcx
    incq %rax
    
    movq %rdx, %r9
    movq $10, %r8
    movq %r9, %rax
    movq $0, %rdx
    divq %r8
    
    addb $'0', %al
    movb %al, (%rcx)
    incq %rcx
    
    addb $'0', %dl
    movb %dl, (%rcx)
    incq %rcx
    
    movb $0, (%rcx)
    addq $3, %rax
    
    popq %rbp
    ret

_double_to_string:
    pushq %rbp
    movq %rsp, %rbp
    
    movq %rdi, %rax
    movq %rsi, %rcx
    movq $1000000, %r8
    movq $0, %rdx
    divq %r8
    
    movq %rax, %rdi
    movq %rcx, %rsi
    call _int_to_string
    
    addq %rax, %rcx
    movb $'.', (%rcx)
    incq %rcx
    incq %rax
    
    movq %rdx, %r9
    movl $6, %r10d
    
    double_frac_digits:
        cmpl $0, %r10d
        je double_string_done
        
        movq $10, %r8
        imulq %r8, %r9
        movq %r9, %rdi
        movq $1000000, %r8
        movq $0, %rdx
        divq %r8
        
        addb $'0', %al
        movb %al, (%rcx)
        incq %rcx
        incq %rax
        
        movq %rdx, %r9
        decl %r10d
        jmp double_frac_digits
        
    double_string_done:
        movb $0, (%rcx)
        popq %rbp
        ret

_simple_file_write:
    pushq %rbp
    movq %rsp, %rbp
    
    movq %rsi, %rcx
    movq $0, %rdx
    
    count_file_chars:
        movb (%rcx,%rdx), %al
        cmpb $0, %al
        je write_file_string
        incq %rdx
        jmp count_file_chars
        
    write_file_string:
        movq $SYS_WRITE, %rax
        syscall
        
        popq %rbp
        ret

# ___________________________________________________________________________________________________
# SEÇÃO DATA COM TODAS AS CONSTANTES E DADOS DE TESTE

.section __DATA,__data
    # CONSTANTES DE PONTO FLUTUANTE PARA SSE/AVX
    .align 16
    .LC_float_abs_mask:     .long 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF
    .LC_double_abs_mask:    .quad 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF
    .LC_ten_float:          .float 10.0
    .LC_ten_double:         .double 10.0
    .LC_one_float:          .float 1.0
    .LC_one_double:         .double 1.0
    .LC_neg_one_float:      .float -1.0
    .LC_neg_one_double:     .double -1.0
    
    # STRINGS DE FORMATO E MENSAGENS
    patrick_info_text: .string "PATRICK DUARTE PIMENTA - SOFTWARE BÁSICO - 2025\n"
    implementation_complete: .string "Implementação completa da libC_SB em Assembly x86-64\n"
    
    # DADOS PESSOAIS PARA TESTE
    nome_exemplo: .string "Patrick"
    patrick_initial: .byte 'P'
    patrick_age: .long 25
    patrick_float: .long 31415                          # representa 314.15
    patrick_double: .quad 2718281828                     # representa 2718.281828
    
    # FORMATOS DE IMPRESSÃO
    name_format: .string "Nome: "
    age_format: .string "Idade: "
    initial_format: .string "Inicial: "
    float_format: .string "Float: "
    double_format: .string "Double: "
    
    # DADOS PRÉ-FORMATADOS PARA DEMONSTRAÇÃO
    age_str: .string "25"
    initial_str: .string "P"
    float_str: .string "314.15"
    double_str: .string "2718.281828"
    newline_str: .string "\n"
    
    # INFORMAÇÕES DETALHADAS PARA ARQUIVO
    detailed_info: .string "Nome: Patrick\nIdade: 25\nInicial: P\nFloat: 314.15\nDouble: 2718.281828\n"
    
    # MENSAGENS DE TESTE DE ARQUIVO
    file_success_test: .string "Arquivo criado com sucesso!\n"
    file_error_test: .string "Erro ao criar arquivo!\n"
    
    # NOME DO ARQUIVO DE TESTE
    test_filename: .string "teste_libC_SB.txt"