/*
========================================================================================================
-> libC_SB - Implementação de funções básicas da biblioteca C em Assembly x86-64
-> Este arquivo contém implementações de funções como printf, scanf, conversões, etc.
-> Este arquivo também trabalha com tipos primitivos: char, short, int, long int, float e double
-> Disciplina: Software Básico - IFNMG (2025) / Autor: Patrick Duarte Pimenta
    ==> OBS: Implementação foi adaptada para o assembly do macOS, 
            portanto, algumas mudanças de sintaxe como .section, e
            chamada syscall serão percebidas, entretanto, serão mudanças mínimas
========================================================================================================            
*/

# ______________________________________________________________________________________________________
.bss
        # CONSTANTES DO SISTEMA
    .equ STDIN_FD, 0                                    # Entrada padrão
    .equ STDOUT_FD, 1                                   # Saída padrão
    .equ STDERR_FD, 2                                   # Saída de erro

    # SYSCALLS DO MACOS
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

    # CONSTANTES PARA COMPATIBILIDADE COM C
    .equ EOF, -1                                        # End of File
    .equ NULL, 0                                        # Ponteiro nulo
    .equ FILE_STRUCT_SIZE, 32                           # Tamanho da estrutura FILE (simplificada)

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
# ______________________________________________________________________________________________________

# ______________________________________________________________________________________________________
.data
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

    # |---------------------------------------------|
    # |         TESTES COM A FUNÇÃO PRINTF          |
    # |---------------------------------------------|

    # Valores mínimos para cada tipo signed
    test_char_min: .byte -128                           # Char mínimo: -128
    test_short_min: .short -32768                       # Short mínimo: -32768
    test_int_min: .long -2147483648                     # Int mínimo: -2147483648
    test_long_min: .quad -9223372036854775808           # Long mínimo: -9223372036854775808
    test_float_min: .float -3.4028235e+38               # Float mínimo: -3.4028235e+38
    test_double_min: .double -1.7976931348623157e+308   # Double mínimo: -1.7976931348623157e+308
    
    # Valores máximos para cada tipo signed  
    test_char_max: .byte 127                            # Char máximo: 127
    test_short_max: .short 32767                        # Short máximo: 32767
    test_int_max: .long 2147483647                      # Int máximo: 2147483647
    test_long_max: .quad 9223372036854775807            # Long máximo: 9223372036854775807
    test_float_max: .float 3.4028235e+38                # Float máximo: 3.4028235e+38
    test_double_max: .double 1.7976931348623157e+308    # Double máximo: 1.7976931348623157e+308
    
    # Strings de formato para cada tipo (valores positivos)
    format_char: .string "Char: %c\n"
    format_short: .string "Short: %hd\n"
    format_int: .string "Int: %d\n"
    format_long: .string "Long: %ld\n"
    format_float: .string "Float: %f\n"
    format_double: .string "Double: %lf\n"
    
    # Strings de formato para cada tipo (valores negativos)
    format_char_neg: .string "Char (neg): %c\n"
    format_short_neg: .string "Short (neg): %hd\n"
    format_int_neg: .string "Int (neg): %d\n"
    format_long_neg: .string "Long (neg): %ld\n"
    format_float_neg: .string "Float (neg): %f\n"
    format_double_neg: .string "Double (neg): %lf\n"
    
    # |---------------------------------------------|
    # |      STRINGS PARA VALORES MIN/MAX           |
    # |---------------------------------------------|
    
    # Headers para testes de valores extremos
    min_max_header: .string "\n=== TESTE DA FUNÇAO PRINTF ===\n"
    min_header: .string "\n--- VALORES MÍNIMOS ---\n"
    max_header: .string "\n--- VALORES MÁXIMOS ---\n"
    
    # Strings de formato para valores mínimos
    format_char_min: .string "Char MIN: %c (valor: %d)\n"
    format_short_min: .string "Short MIN: %hd\n"
    format_int_min: .string "Int MIN: %d\n"
    format_long_min: .string "Long MIN: %ld\n"
    format_float_min: .string "Float MIN: %f\n"
    format_double_min: .string "Double MIN: %lf\n"
    
    # Strings de formato para valores máximos
    format_char_max: .string "Char MAX: %c (valor: %d)\n"
    format_short_max: .string "Short MAX: %hd\n"
    format_int_max: .string "Int MAX: %d\n"
    format_long_max: .string "Long MAX: %ld\n"
    format_float_max: .string "Float MAX: %f\n"
    format_double_max: .string "Double MAX: %lf\n"
    
    # Mensagens de teste

    # |---------------------------------------------|
    # |         TESTES COM A FUNÇÃO SCANF           |
    # |---------------------------------------------|

    # |---------------------------------------------|
    # |         TESTES COM A FUNÇÃO FOPEN           |
    # |---------------------------------------------|

    # |---------------------------------------------|
    # |         TESTES COM A FUNÇÃO FCLOSE          |
    # |---------------------------------------------|

    # |---------------------------------------------|
    # |         TESTES COM A FUNÇÃO FPRINTF         |
    # |---------------------------------------------|

    # |---------------------------------------------|
    # |         TESTES COM A FUNÇÃO FSCANF          |
    # |---------------------------------------------|
    
# ______________________________________________________________________________________________________

# ______________________________________________________________________________________________________
.text
    # FUNÇÕES PRINCIPAIS DA BIBLIOTECA
    .globl _main
    .globl _printf                                          # Printf
    .globl _scanf                                           # Scanf   
    .globl _fopen                                           # Abrir arquivos
    .globl _fclose                                          # Fechar arquivos
    .globl _fprintf                                         # Fprintf para arquivos
    .globl _fscanf                                          # Fscanf para arquivos

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
    
    # FUNÇÕES AUXILIARES
    .globl _get_next_printf_arg                             # Obtém o próximo argumento para printf
    .globl _test_printf_all_types                           # Função de teste para todos os tipos
    .globl _test_min_max_values                             # Função de teste para valores mínimos e máximos

    # FUNÇÕES DE TESTES
    .globl _test_printf_all_types                           # Test todos os valroes da função printf

    # FUNÇÃO PRINCIPAL
    .globl _main
# ______________________________________________________________________________________________________

# ######################################################################################################
# PRINTF - Implementação de printf com suporte aos tipos char, short, int ,long int, float e double
# ######################################################################################################

_printf:
    # Entrada: %rdi = format string, %rsi, %rdx, %rcx, %r8, %r9 = argumentos
    # Saída: %rax = número de caracteres impressos
    
    pushq %rbp
    movq %rsp, %rbp

    # Preserva os registradores callee-saved
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    pushq %rbx

    # Aqui faz a alocação do espço para as variáveis locais que iremos trabalhar
    subq $64, %rsp

    # Salva os argumentos
    movq %rdi, -8(%rbp)                                 # format string
    movq %rsi, -16(%rbp)                                # arg1
    movq %rdx, -24(%rbp)                                # arg2
    movq %rcx, -32(%rbp)                                # arg3
    movq %r8, -40(%rbp)                                 # arg4
    movq %r9, -48(%rbp)                                 # arg5


    # Inicialização das variáveis
    movl $0, -52(%rbp)                                  # contador de caracteres
    movl $0, -56(%rbp)                                  # arg_index (inicializa em 0)
    leaq output_buffer(%rip), %r12                      # ponteiro para o buffer
    movq %r12, %r13                                     # inicio do buffer

    printf_main_loop:
        movq -8(%rbp), %rax                             # ponteiro que aponta para a string de formato
        movb (%rax), %bl                                # caractere atual
        testb %bl, %bl                                  # verifica se é o terminador nulo
        jz printf_output

        cmpb $'%', %bl                                  # verifica se é um especificador
        je printf_format_handler

        # Caractere normal - copia para o buffer
        movb %bl, (%r12)
        incq %r12
        incq -52(%rbp)                                  # incrementa o contador de caracteres
        incq -8(%rbp)                                   # avança o ponteiro da string de formato
        jmp printf_main_loop

    printf_format_handler:
        incq -8(%rbp)                                   # pula '%'
        movq -8(%rbp), %rax                             # pega o próximo caractere após '%'
        movb (%rax), %bl                                # pega o primeiro caractere do especificador
        
        # Verificar se é 'h' (para %hd)
        cmpb $'h', %bl
        je check_hd_format
        
        # Verificar se é 'l' (para %ld ou %lf)  
        cmpb $'l', %bl
        je check_l_format
        
        # Caracteres simples (%c, %d, %f, %%)
        incq -8(%rbp)                                   # avança o ponteiro
        
        cmpb $'c', %bl
        je printf_char
        
        cmpb $'d', %bl
        je printf_int
        
        cmpb $'f', %bl
        je printf_float
        
        cmpb $'%', %bl
        je printf_percent
        
        # Ignora especificador não reconhecido
        jmp printf_main_loop

    check_hd_format:
        # Verificar se o próximo caractere é 'd' (%hd)
        incq -8(%rbp)                                   # avança para o segundo caractere
        movq -8(%rbp), %rax
        
        movb (%rax), %bl                                # pega o 'd'
        incq -8(%rbp)                                   # avança novamente
        
        cmpb $'d', %bl
        je printf_short
        
        # Se não for 'd', ignora
        jmp printf_main_loop

    check_l_format:
        # Verificar se é %ld ou %lf
        incq -8(%rbp)                                   # avança para o segundo caractere
        movq -8(%rbp), %rax
        movb (%rax), %bl                                # pega o segundo caractere
        incq -8(%rbp)                                   # avança novamente
        
        cmpb $'d', %bl
        je printf_long
        
        cmpb $'f', %bl
        je printf_double
        
        # Se não for 'd' nem 'f', ignora
        jmp printf_main_loop

    # Printa caractere
    printf_char:
        call _get_next_printf_arg
        
        movb %al, (%r12)                                # coloca o caractere no buffer
        incq %r12
        incl -52(%rbp)
        
        jmp printf_main_loop

    # Printa short (%hd)
    printf_short:
        call _get_next_printf_arg
        
        movswq %ax, %rax                                # extender short para long
        movq %rax, %rdi                                 # valor em short int
        movq %r12, %rsi                                 # posição do buffer
        
        call _short_to_str
        
        addq %rax, %r12                                 # avança o buffer
        addl %eax, -52(%rbp)                            # adiciona para o contador de caracteres
        
        jmp printf_main_loop

    # Printa int (%d)
    printf_int:
        call _get_next_printf_arg
        
        movq %rax, %rdi                                 # valor inteiro
        movq %r12, %rsi                                 # posição do buffer
        
        call _int_to_str
        
        addq %rax, %r12                                 # avança o buffer
        addl %eax, -52(%rbp)                            # adiciona para o contador de caracteres
        
        jmp printf_main_loop

    # Printa long (%ld)
    printf_long:
        call _get_next_printf_arg
        movq %rax, %rdi                                 # valor em long int
        movq %r12, %rsi                                 # posição do buffer
        call _long_to_str
        addq %rax, %r12                                 # avança o buffer
        addl %eax, -52(%rbp)                            # adiciona para o contador de caracteres
        jmp printf_main_loop

    # Printa float (%f)
    printf_float:
        # Para float, não usar _get_next_printf_arg pois float vem em XMM
        # Em vez disso, o valor já deve estar em XMM0 quando chamado
        call _get_next_printf_arg                       # obtém o valor como inteiro (representação binária)
        movd %eax, %xmm0                                # move para XMM0 como float
        movq %r12, %rdi                                 # posição do buffer
        
        # Chama a função que espera valor em XMM0
        subq $16, %rsp                                  # alinhar stack para SSE
        call _float_to_str                              # função que usa XMM0
        addq $16, %rsp                                  # restaurar stack
        
        addq %rax, %r12                                 # avança o buffer
        addl %eax, -52(%rbp)                            # adiciona para o contador de caracteres
        jmp printf_main_loop

    # Printa double (%lf)
    printf_double:
        # Para double, não usar _get_next_printf_arg pois double também vem em XMM
        # Em vez disso, o valor já deve estar em XMM0 quando chamado
        call _get_next_printf_arg                       # obtém o valor como inteiro (representação binária)
        movq %rax, %xmm0                                # move para XMM0 como double
        movq %r12, %rdi                                 # posição do buffer
        
        # Chama a função que espera valor em XMM0
        subq $16, %rsp                                  # alinhar stack para SSE
        call _double_to_str                             # função que usa XMM0
        addq $16, %rsp                                  # restaurar stack

        addq %rax, %r12                                 # avança o buffer
        addl %eax, -52(%rbp)                            # adiciona para o contador de caracteres
        jmp printf_main_loop

        
    printf_percent:
        movb $'%', (%r12)
        incq %r12
        incl -52(%rbp)
        jmp printf_main_loop
        
    printf_output:
        # Escreve o buffer para stdout
        movq $SYS_WRITE, %rax
        movq $STDOUT_FD, %rdi
        movq %r13, %rsi                                 # início do buffer
        movl -52(%rbp), %edx                            # contador de caracteres
        syscall
        
        # Retorna o número de caracteres escritos
        movl -52(%rbp), %eax
        
        # Restaura os registradores e a stack
        addq $64, %rsp
        popq %rbx
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        ret

# ######################################################################################################
# SCANF - Implementação de scanf com suporte aos tipos: %d, %s, %c, %f, %lf  
# ######################################################################################################

_scanf:
    # TODO: Implementar scanf completo
    # Entrada: %rdi = format string, %rsi, %rdx, %rcx, %r8, %r9 = ponteiros para variáveis
    # Saída: %rax = número de items lidos
    movq $0, %rax
    ret

# ######################################################################################################
# FPRINTF - Implementação de fprintf para escrita em arquivos
# ######################################################################################################

_fprintf:
    # TODO: Implementar fprintf
    # Entrada: %rdi = FILE *stream, %rsi = format string, demais = argumentos
    # Saída: %rax = número de caracteres escritos
    movq $0, %rax
    ret

# ######################################################################################################
# FSCANF - Implementação de fscanf para leitura de arquivos
# ######################################################################################################

_fscanf:
    # TODO: Implementar fscanf  
    # Entrada: %rdi = FILE *stream, %rsi = format string, demais = ponteiros
    # Saída: %rax = número de items lidos
    movq $0, %rax
    ret

# ######################################################################################################
# FOPEN - Implementação de fopen para abertura de arquivos
# ######################################################################################################

_fopen:
    # TODO: Implementar fopen
    # Entrada: %rdi = nome do arquivo, %rsi = modo ("r", "w", "a", etc.)
    # Saída: %rax = FILE * (ponteiro para FILE, NULL se erro)
    movq $0, %rax
    ret

# ######################################################################################################
# FCLOSE - Implementação de fclose para fechamento de arquivos
# ######################################################################################################

_fclose:
    # TODO: Implementar fclose
    # Entrada: %rdi = FILE *stream
    # Saída: %rax = 0 (sucesso) ou EOF (erro)
    movq $0, %rax
    ret

# ######################################################################################################
# FUNÇÕES DE CONVERSÃO STRING-TO-TYPE
# ######################################################################################################

_str_to_char:
    # TODO: Implementar conversão string para char
    # Entrada: %rdi = ponteiro para string
    # Saída: %rax = valor char convertido
    movq $0, %rax
    ret

_str_to_short:
    # TODO: Implementar conversão string para short
    # Entrada: %rdi = ponteiro para string  
    # Saída: %rax = valor short convertido
    movq $0, %rax
    ret

_str_to_int:
    # TODO: Implementar conversão string para int
    # Entrada: %rdi = ponteiro para string
    # Saída: %rax = valor int convertido
    movq $0, %rax
    ret

_str_to_long:
    # TODO: Implementar conversão string para long
    # Entrada: %rdi = ponteiro para string
    # Saída: %rax = valor long convertido
    movq $0, %rax
    ret

_str_to_float:
    # TODO: Implementar conversão string para float (usar registradores XMM)
    # Entrada: %rdi = ponteiro para string
    # Saída: %xmm0 = valor float convertido
    xorps %xmm0, %xmm0
    ret

_str_to_double:
    # TODO: Implementar conversão string para double (usar registradores XMM)
    # Entrada: %rdi = ponteiro para string
    # Saída: %xmm0 = valor double convertido
    xorpd %xmm0, %xmm0
    ret

# ######################################################################################################
# FUNÇÕES DE CONVERSÃO TYPE-TO-STRING
# ######################################################################################################

_char_to_str:
    # Entrada: %rdi = valor char, %rsi = buffer de destino
    # Saída: %rax = ponteiro para string resultante
    pushq %rbp
    movq %rsp, %rbp
    
    # rdi = char value, rsi = buffer
    movb %dil, (%rsi)                                   # armazena o caractere
    movb $0, 1(%rsi)                                    # termina a string com nulo
    movq $1, %rax                                       # return o tamanho
    
    popq %rbp
    ret

# Converte short para string
_short_to_str:
    # Entrada: %rdi = valor short, %rsi = buffer de destino
    # Saída: %rax = número de caracteres convertidos
    pushq %rbp
    movq %rsp, %rbp

    # Preserva registradores que serão utilizados
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    # Preparação dos dados
    movswq %di, %r12                                    # extende short (16-bit) para long (64-bit)
    movq %rsi, %r13                                     # salva o ponteiro do buffer de destino
    movq $0, %r15                                       # inicializa o contador de caracteres

    # Verifica se o número é negativo
    testq %r12, %r12
    jns short_positive                                  # pula se não for negativo

    # Tratamento de números negativos
    movb $'-', (%r13)                                   # adiciona o sinal de menos no buffer
    incq %r13                                           # avança o ponteiro do buffer
    incq %r15                                           # conta o caractere do sinal
    negq %r12                                           # converte para positivo (módulo)

    short_positive:
        # Caso especial: número zero
        testq %r12, %r12 
        jnz short_convert_digits                        # se não for zero, continua
        
        # Se for zero, simplesmente adiciona '0' e termina
        movb $'0', (%r13)
        movb $0, 1(%r13)                                # terminador nulo
        incq %r15                                       # conta o dígito '0'
        movq %r15, %rax                                 # retorna a quantidade de caracteres
        jmp short_done

    short_convert_digits:
        # Primeira passada: conta quantos dígitos tem o número
        movq %r12, %rax                                 # copia o valor para contagem
        movq $0, %r14                                   # contador de dígitos
        
    short_count_digits:
        movq $0, %rdx                                   # limpa rdx
        movq $10, %rcx                                  # divisor = 10
        divq %rcx                                       # rax = quociente, rdx = resto
        incq %r14                                       # incrementa o contador de dígitos
        testq %rax, %rax                                # verifica se ainda há dígitos
        jnz short_count_digits                          # continua se rax != 0
        
        # Agora sabemos quantos dígitos temos em %r14
        # Posiciona ponteiro no final dos dígitos para escrever de trás para frente
        movq %r13, %rcx                                 # ponteiro atual do buffer
        addq %r14, %rcx                                 # aponta para depois do último dígito
        decq %rcx                                       # aponta para o último dígito
        
        # Segunda passada: converte os dígitos de trás para frente
        movq %r12, %rax                                 # restaura o valor original
        
    short_write_digits:
        movq $0, %rdx                                   # limpa rdx
        movq $10, %r8                                   # divisor = 10
        divq %r8                                        # rax = quociente, rdx = resto (dígito)
        
        # Converte dígito para ASCII e escreve no buffer
        addb $'0', %dl                                  # converte o dígito para ASCII
        movb %dl, (%rcx)                                # escreve o dígito na posição
        decq %rcx                                       # move para a posição anterior
        
        # Continua se ainda há mais dígitos
        testq %rax, %rax
        jnz short_write_digits
        
        # Atualiza ponteiro do buffer e contador
        addq %r14, %r13                                 # avança o ponteiro pelos dígitos escritos
        addq %r14, %r15                                 # adiciona os dígitos ao contador total
        
        # Adiciona terminador nulo
        movb $0, (%r13)                                 # adiciona o terminador nulo
        
        movq %r15, %rax                                 # retorna o número de caracteres convertidos
        
    short_done:
        # Restaura registradores preservados
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        ret

# Converte int para string  
_int_to_str:
    # Entrada: %rdi = valor int, %rsi = buffer de destino
    # Saída: %rax = número de caracteres convertidos
    pushq %rbp
    movq %rsp, %rbp

    # Preserva registradores que serão utilizados
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    # Preparação dos dados
    movslq %edi, %r12                                   # extende int (32-bit) para long (64-bit)
    movq %rsi, %r13                                     # salva o ponteiro do buffer de destino
    movq $0, %r15                                       # inicializa o contador de caracteres

    # Verifica se o número é negativo
    testq %r12, %r12
    jns int_positive                                    # pula se não for negativo

    # Tratamento de números negativos
    movb $'-', (%r13)                                   # adiciona sinal de menos no buffer
    incq %r13                                           # avança o ponteiro do buffer
    incq %r15                                           # conta o caractere do sinal
    negq %r12                                           # converte para positivo (módulo)

    int_positive:
        # Caso especial: número zero
        testq %r12, %r12 
        jnz int_convert_digits                          # se não for igual a zero, continua
        
        # Se for zero, simplesmente adiciona '0' e termina
        movb $'0', (%r13)
        movb $0, 1(%r13)                                # terminador nulo
        incq %r15                                       # conta o dígito '0'
        movq %r15, %rax                                 # retorna a quantidade de caracteres
        jmp int_done

    int_convert_digits:
        # Primeira passada: conta quantos dígitos tem o número
        movq %r12, %rax                                 # copia o valor para contagem
        movq $0, %r14                                   # contador de dígitos
        
    int_count_digits:
        movq $0, %rdx                                   # limpa rdx
        movq $10, %rcx                                  # divisor = 10
        divq %rcx                                       # rax = quociente, rdx = resto
        incq %r14                                       # incrementa contador de dígitos
        testq %rax, %rax                                # verifica se ainda há dígitos
        jnz int_count_digits                            # continua se rax != 0
        
        # Agora sabemos quantos dígitos temos em %r14
        # Posiciona ponteiro no final dos dígitos para escrever de trás para frente
        movq %r13, %rcx                                 # ponteiro atual do buffer
        addq %r14, %rcx                                 # aponta para depois do último dígito
        decq %rcx                                       # aponta para o último dígito
        
        # Segunda passada: converte os dígitos de trás para frente
        movq %r12, %rax                                 # restaura valor original
        
    int_write_digits:
        movq $0, %rdx                                   # limpa rdx
        movq $10, %r8                                   # divisor = 10
        divq %r8                                        # rax = quociente, rdx = resto (dígito)
        
        # Converte dígito para ASCII e escreve no buffer
        addb $'0', %dl                                  # converte o dígito para ASCII
        movb %dl, (%rcx)                                # escreve o dígito na posição
        decq %rcx                                       # move para a posição anterior
        
        # Continua se ainda há mais dígitos
        testq %rax, %rax
        jnz int_write_digits
        
        # Atualiza ponteiro do buffer e contador
        addq %r14, %r13                                 # avança o ponteiro pelos dígitos escritos
        addq %r14, %r15                                 # adiciona os dígitos ao contador total
        
        movb $0, (%r13)                                 # adiciona o terminador nulo
        
        movq %r15, %rax                                 # retorna  o número de caracteres convertidos
        
    int_done:
        # Restaura registradores preservados
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        ret

# Converte long para string
_long_to_str:
    # Entrada: %rdi = valor long, %rsi = buffer de destino
    # Saída: %rax = número de caracteres convertidos
    pushq %rbp
    movq %rsp, %rbp

    # Preserva os registradores que serão utilizados
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    # Preparação dos dados
    movq %rdi, %r12                                     # salva o valor long (64-bit)
    movq %rsi, %r13                                     # salva o ponteiro do buffer de destino
    movq $0, %r15                                       # inicializa o contador de caracteres

    # Verifica se o número é negativo
    testq %r12, %r12
    jns long_positive                                   # pula se não for negativo

    # Tratamento de números negativos
    movb $'-', (%r13)                                   # adiciona o sinal de menos no buffer
    incq %r13                                           # avança o ponteiro do buffer
    incq %r15                                           # conta o caractere do sinal
    negq %r12                                           # converte para positivo (módulo)

    long_positive:
        # Caso especial: número zero
        testq %r12, %r12 
        jnz long_convert_digits                         # se não for igual a zero, continua
        
        # Se for zero, simplesmente adiciona '0' e termina
        movb $'0', (%r13)
        movb $0, 1(%r13)                                # terminador nulo
        incq %r15                                       # conta o dígito '0'
        movq %r15, %rax                                 # retorna a quantidade de caracteres
        jmp long_done

    long_convert_digits:
        # Primeira passada: conta quantos dígitos tem o número
        movq %r12, %rax                                 # copia o valor para contagem
        movq $0, %r14                                   # contador de dígitos
        
    long_count_digits:
        movq $0, %rdx                                   # limpa rdx
        movq $10, %rcx                                  # divisor = 10
        divq %rcx                                       # rax = quociente, rdx = resto
        incq %r14                                       # incrementa contador de dígitos
        testq %rax, %rax                                # verifica se ainda há dígitos
        jnz long_count_digits                           # continua se rax != 0
        
        # Agora sabemos quantos dígitos temos em %r14
        # Posiciona ponteiro no final dos dígitos para escrever de trás para frente
        movq %r13, %rcx                                 # ponteiro atual do buffer
        addq %r14, %rcx                                 # aponta para depois do último dígito
        decq %rcx                                       # aponta para o último dígito
        
        # Segunda passada: converte os dígitos de trás para frente
        movq %r12, %rax                                 # restaura o valor original
        
    long_write_digits:
        movq $0, %rdx                                   # limpa rdx
        movq $10, %r8                                   # divisor = 10
        divq %r8                                        # rax = quociente, rdx = resto (dígito)
        
        # Converte dígito para ASCII e escreve no buffer
        addb $'0', %dl                                  # converte o dígito para ASCII
        movb %dl, (%rcx)                                # escreve o dígito na posição
        decq %rcx                                       # move para a posição anterior
        
        # Continua se ainda há mais dígitos
        testq %rax, %rax
        jnz long_write_digits
        
        # Atualiza ponteiro do buffer e contador
        addq %r14, %r13                                 # avança o ponteiro pelos dígitos escritos
        addq %r14, %r15                                 # adiciona dígitos ao contador total
        
        # Adiciona terminador nulo
        movb $0, (%r13)                                 # adiciona o terminador nulo

        movq %r15, %rax                                 # retorna o número de caracteres convertidos

    long_done:
        # Restaura registradores preservados
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        ret

# Converte float para string
_float_to_str:
    # Entrada: %xmm0 = valor float, %rdi = buffer de destino
    # Saída: %rax = ponteiro para string resultante
    
    # Prologo da função - preserva o estado do registrador
    pushq %rbp
    movq %rsp, %rbp
    
    # Preserva registradores callee-saved que serão utilizados
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    
    # %xmm0 contém o valor float
    # %rdi contém o ponteiro do buffer de destino
    movq %rdi, %r13                                     # salva o ponteiro do buffer
    movq $0, %r14                                       # inicializa contador de caracteres
    
    # Verificar se o float é negativo usando operação bit-wise
    movd %xmm0, %eax                                    # move float de XMM0 para EAX para verificar o sinal
    testl $0x80000000, %eax                             # testa o bit de sinal (bit 31 para float)
    jz float_positive                                   # pula se for positivo
    
    # Tratamento de números negativos
    movb $'-', (%r13)                                   # adiciona o sinal de menos no buffer
    incq %r13                                           # avança o ponteiro do buffer
    incq %r14                                           # incrementa o contador de caracteres
    
    # Aplicar valor absoluto usando instruções SSE
    movss .LC_float_abs_mask(%rip), %xmm1               # carrega a máscara para valor absoluto
    andps %xmm1, %xmm0                                  # aplica a máscara (remove sinal negativo)
    
    float_positive:
        # Separar a parte inteira da parte fracionária usando instruções SSE
        # Converte para double temporariamente para maior precisão nos cálculos
        cvtss2sd %xmm0, %xmm2                           # converte float para double em XMM2
        
        # Extrair parte inteira usando truncamento (remove casas decimais)
        cvttsd2si %xmm2, %r15                           # trunca para inteiro (parte inteira)
        
        # Calcular parte fracionária subtraindo a parte inteira do valor original
        cvtsi2sd %r15, %xmm3                            # converte a parte inteira de volta para double
        subsd %xmm3, %xmm2                              # XMM2 agora contém apenas a parte fracionária
        
        # Converter parte inteira para string
        movq %r15, %rdi                                 # valor inteiro para conversão
        movq %r13, %rsi                                 # buffer de destino
        call _long_to_str                               # chama a função de conversão long->string
        addq %rax, %r13                                 # avança o ponteiro do buffer pelo número de caracteres convertidos
        addq %rax, %r14                                 # adiciona ao contador total de caracteres
        
        # Adicionar ponto decimal na string
        movb $'.', (%r13)                               # insere o ponto decimal
        incq %r13                                       # avança o ponteiro do buffer
        incq %r14                                       # incrementa o contador de caracteres
        
        # Processar parte fracionária (6 dígitos de precisão para float)
        movl $6, %ecx                                   # define 6 casas decimais para float
        
    float_frac_loop:
        # Verifica se ainda há dígitos fracionários para processar
        testl %ecx, %ecx                                # testa se o contador é zero
        jz float_str_done                           # termina se processou todos os dígitos
        
        # Multiplicar parte fracionária por 10 para extrair próximo dígito
        movsd .LC_ten_double(%rip), %xmm4               # carrega constante 10.0 em double
        mulsd %xmm4, %xmm2                              # multiplica a parte fracionária por 10
        
        # Extrair o próximo dígito (parte inteira após multiplicação por 10)
        cvttsd2si %xmm2, %rax                           # converte para inteiro (obtém o dígito)
        cmpq $9, %rax                                   # verifica se é > 9
        jle float_digit_ok                              # se <= 9, está ok
        movq $9, %rax                                   # limita a 9
    float_digit_ok:
        cmpq $0, %rax                                   # verifica se é < 0
        jge float_digit_valid                           # se >= 0, está ok
        movq $0, %rax                                   # limita a 0
    float_digit_valid:
        addb $'0', %al                                  # converte o dígito numérico para caractere ASCII
        movb %al, (%r13)                                # armazena o dígito no buffer
        incq %r13                                       # avança o ponteiro do buffer
        incq %r14                                       # incrementa o contador de caracteres
        
        # Remover o dígito já processado da parte fracionária
        subb $'0', %al                                  # volta para o valor numérico
        cvtsi2sd %rax, %xmm5                            # converte o dígito de volta para double
        subsd %xmm5, %xmm2                              # subtrai o dígito da parte fracionária
        
        # Continua loop para próximo dígito
        decl %ecx                                       # decrementa o contador de dígitos restantes
        jmp float_frac_loop                         # volta para o processar próximo dígito
        
    float_str_done:
        # Finaliza a string com terminador nulo
        movb $0, (%r13)                                 # adiciona o terminador nulo (\0)
        movq %r14, %rax                                 # retorna o número total de caracteres convertidos
        
        # Epilogo da função - restaura registradores preservados
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        ret                                             # retorna para função chamadora

# Converte double para string
_double_to_str:
    # Entrada: %xmm0 = valor double, %rdi = buffer de destino
    # Saída: %rax = ponteiro para string resultante
    
    # Prologo da função - preserva o estado do registrador
    pushq %rbp
    movq %rsp, %rbp
    
    # Preserva o registradores callee-saved que serão utilizados
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    
    # %xmm0 contém o valor double
    # %rdi contém o ponteiro do buffer de destino
    movq %rdi, %r13                                     # salva o ponteiro do buffer
    movq $0, %r14                                       # inicializa o ocontador de caracteres
    
    # Verificar se o double é negativo usando operação bit-wise
    movq %xmm0, %rax                                    # move double de XMM0 para RAX para verificar o sinal
    movq $0x8000000000000000, %rdx                      # carrega a máscara do bit de sinal (bit 63 para double)
    testq %rdx, %rax                                    # testa o bit de sinal
    jz double_positive                                  # pula se for positivo
    
    # Tratamento de números negativos
    movb $'-', (%r13)                                   # adiciona o sinal de menos no buffer
    incq %r13                                           # avança o ponteiro do buffer
    incq %r14                                           # incrementa o contador de caracteres
    
    # Aplicar valor absoluto usando instruções SSE
    movsd .LC_double_abs_mask(%rip), %xmm1              # carrega a máscara para valor absoluto
    andpd %xmm1, %xmm0                                  # aplica a máscara (remove sinal negativo)
    
    double_positive:
        # Separar a parte inteira da parte fracionária
        # Extrair parte inteira usando truncamento (remove casas decimais)
        cvttsd2si %xmm0, %r15                           # trunca para inteiro (parte inteira)
        
        # Calcular parte fracionária subtraindo a parte inteira do valor original
        cvtsi2sd %r15, %xmm2                            # converte a parte inteira de volta para double
        subsd %xmm2, %xmm0                              # XMM0 agora contém apenas a parte fracionária
        
        # Converter parte inteira para string
        movq %r15, %rdi                                 # valor inteiro para conversão
        movq %r13, %rsi                                 # buffer de destino
        call _long_to_str                               # chama a função de conversão long->string
        addq %rax, %r13                                 # avança o ponteiro do buffer pelo número de caracteres convertidos
        addq %rax, %r14                                 # adiciona ao contador total de caracteres
        
        # Adicionar ponto decimal na string
        movb $'.', (%r13)                               # insere o ponto decimal
        incq %r13                                       # avança o ponteiro do buffer
        incq %r14                                       # incrementa o contador de caracteres
        
        # Processar parte fracionária (15 dígitos de precisão para double)
        movl $15, %ecx                                  # define 15 casas decimais para double
        
    double_frac_loop:
        # Verifica se ainda há dígitos fracionários para processar
        testl %ecx, %ecx                                # testa se o contador é zero
        jz double_str_done                              # termina se processou todos os dígitos
        
        # Multiplicar parte fracionária por 10 para extrair próximo dígito
        movsd .LC_ten_double(%rip), %xmm3               # carrega a constante 10.0 em double
        mulsd %xmm3, %xmm0                              # multiplica a parte fracionária por 10
        
        # Extrair o próximo dígito (parte inteira após multiplicação por 10)
        cvttsd2si %xmm0, %rax                           # converte para inteiro (obtém o dígito)
        cmpq $9, %rax                                   # verifica se é > 9
        jle double_digit_ok                             # se <= 9, está ok
        movq $9, %rax                                   # limita a 9
   
    double_digit_ok:
        cmpq $0, %rax                                   # verifica se é < 0
        jge double_digit_valid                          # se >= 0, está ok
        movq $0, %rax                                   # limita a 0
    
    double_digit_valid:
        # Salva o dígito numérico antes de converter para ASCII
        movq %rax, %r12                                 # salva o dígito numérico
        addb $'0', %al                                  # converte o dígito numérico para caractere ASCII
        movb %al, (%r13)                                # armazena o dígito no buffer
        incq %r13                                       # avança o ponteiro do buffer
        incq %r14                                       # incrementa o contador de caracteres
        
        # Remover o dígito já processado da parte fracionária
        cvtsi2sd %r12, %xmm4                            # converte o dígito numérico de volta para double
        subsd %xmm4, %xmm0                              # subtrai o dígito da parte fracionária
        
        # Continua loop para próximo dígito
        decl %ecx                                       # decrementa o contador de dígitos restantes
        jmp double_frac_loop                            # volta para processar o próximo dígito
        
    double_str_done:
        # Finaliza a string com terminador nulo
        movb $0, (%r13)                                 # adiciona o terminador nulo (\0)
        movq %r14, %rax                                 # retorna o número total de caracteres convertidos
        
        # Epilogo da função - restaura registradores preservados
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        ret

# ######################################################################################################
# OUTRAS FUNÇÕES AUXILIARES
# ######################################################################################################

# Função auxiliar para obter o próximo argumento de printf
_get_next_printf_arg:
    incl -56(%rbp)                                      # incrementar primeiro
    movl -56(%rbp), %eax                                # obter o índice do argumento atual

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

# ######################################################################################################
# FUNÇÃO DE TESTE PARA PRINTF (VALORES MÍNIMOS E MÁXIMOS - TODOS OS TIPOS SIGNED)
# ######################################################################################################
_test_printf_all_types:
    pushq %rbp
    movq %rsp, %rbp
    
    # Imprime cabeçalho dos testes de valores extremos
    leaq min_max_header(%rip), %rdi
    call _printf
    
    # |---------------------------------------------|
    # |             VALORES MÍNIMOS                |
    # |---------------------------------------------|
    
    # Imprime cabeçalho dos valores mínimos
    leaq min_header(%rip), %rdi
    call _printf
    
    # Teste MIN 1: Char MIN (-128)
    leaq format_char_min(%rip), %rdi
    movzbl test_char_min(%rip), %esi                    # Carrega char mínimo como segundo argumento
    movswq test_char_min(%rip), %rdx                    # Carrega valor numérico para mostrar
    call _printf
    
    # Teste MIN 2: Short MIN (-32768)
    leaq format_short_min(%rip), %rdi
    movswq test_short_min(%rip), %rsi                   # Carrega short mínimo
    call _printf
    
    # Teste MIN 3: Int MIN (-2147483648)
    leaq format_int_min(%rip), %rdi
    movslq test_int_min(%rip), %rsi                     # Carrega int mínimo
    call _printf
    
    # Teste MIN 4: Long MIN (-9223372036854775808)
    leaq format_long_min(%rip), %rdi
    movq test_long_min(%rip), %rsi                      # Carrega long mínimo
    call _printf
    
    # Teste MIN 5: Float MIN (-3.4028235e+38)
    leaq format_float_min(%rip), %rdi
    movss test_float_min(%rip), %xmm0                   # Carrega float mínimo em XMM0
    movl test_float_min(%rip), %esi                     # Também carrega como argumento inteiro
    call _printf
    
    # Teste MIN 6: Double MIN (-1.7976931348623157e+308)
    leaq format_double_min(%rip), %rdi
    movsd test_double_min(%rip), %xmm0                  # Carrega double mínimo em XMM0
    movq test_double_min(%rip), %rsi                    # Também carrega como argumento inteiro
    call _printf
    
    # |---------------------------------------------|
    # |             VALORES MÁXIMOS                |
    # |---------------------------------------------|
    
    # Imprime cabeçalho dos valores máximos
    leaq max_header(%rip), %rdi
    call _printf
    
    # Teste MAX 1: Char MAX (127)
    leaq format_char_max(%rip), %rdi
    movzbl test_char_max(%rip), %esi                    # Carrega char máximo como segundo argumento
    movswq test_char_max(%rip), %rdx                    # Carrega valor numérico para mostrar
    call _printf
    
    # Teste MAX 2: Short MAX (32767)
    leaq format_short_max(%rip), %rdi
    movswq test_short_max(%rip), %rsi                   # Carrega short máximo
    call _printf
    
    # Teste MAX 3: Int MAX (2147483647)
    leaq format_int_max(%rip), %rdi
    movslq test_int_max(%rip), %rsi                     # Carrega int máximo
    call _printf
    
    # Teste MAX 4: Long MAX (9223372036854775807)
    leaq format_long_max(%rip), %rdi
    movq test_long_max(%rip), %rsi                      # Carrega long máximo
    call _printf
    
    # Teste MAX 5: Float MAX (3.4028235e+38)
    leaq format_float_max(%rip), %rdi
    movss test_float_max(%rip), %xmm0                   # Carrega float máximo em XMM0
    movl test_float_max(%rip), %esi                     # Também carrega como argumento inteiro
    call _printf
    
    # Teste MAX 6: Double MAX (1.7976931348623157e+308)
    leaq format_double_max(%rip), %rdi
    movsd test_double_max(%rip), %xmm0                  # Carrega double máximo em XMM0
    movq test_double_max(%rip), %rsi                    # Também carrega como argumento inteiro
    call _printf
    
    popq %rbp
    ret

# ######################################################################################################
# FUNÇÃO PRINCIPAL - MAIN
# ######################################################################################################

_main:
    # Função principal para testar as implementações
    pushq %rbp
    movq %rsp, %rbp
    
    # |---------------------------------------------|
    # |         TESTES COM A FUNÇÃO PRINTF          |
    # |---------------------------------------------|
    # Chama a função de teste do printf
    call _test_printf_all_types
    
    # Retorna 0 (sucesso)
    movq $0, %rax
    popq %rbp
    ret
