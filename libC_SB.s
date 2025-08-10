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

    # SYSCALLS DO MACOS (formato correto para assembly)
    .equ SYS_READ, 0x2000003                            # Ler dados
    .equ SYS_WRITE, 0x2000004                           # Escrever dados  
    .equ SYS_OPEN, 0x2000005                            # Abrir arquivo
    .equ SYS_CLOSE, 0x2000006                           # Fechar arquivo
    .equ SYS_LSEEK, 0x20000C7                           # Seek em arquivo
    .equ SYS_FSYNC, 0x200005F                           # Sincronizar arquivo com disco
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
    .comm temp_byte, 1                                  # Buffer para um byte
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

    # Headers para testes de valores extremos
    printf_test_header: .string "\n=== TESTE DA FUNÇAO PRINTF ===\n"
    min_header: .string "\n--- VALORES DE DEMONSTRAÇÃO (MIN) ---\n"
    max_header: .string "\n--- VALORES DE DEMONSTRAÇÃO (MAX) ---\n"

    # Formato único para teste completo com todos os tipos
    
        format_all_min_max: .string "
    === TESTE COMPLETO DA FUNÇÃO PRINTF ===

    DEMONSTRAÇÃO min: Char:%c Short:%hd Int:%d Long:%ld Float:%f Double:%lf
    DEMONSTRAÇÃO max: Char:%c Short:%hd Int:%d Long:%ld Float:%f Double:%lf
"

    # Valores máximos para cada tipo signed  
    test_char_max: .byte 90                             # Char máximo: 'Z' (90) para demonstração
    test_short_max: .short 32767                        # Short máximo: 32767
    test_int_max: .long 2147483647                      # Int máximo: 2147483647
    test_long_max: .quad 9223372036854775807            # Long máximo: 9223372036854775807
    test_float_max: .float 999999.999999                # Float grande positivo para demonstração
    test_double_max: .double 123456789.123456789        # Double grande positivo para demonstração    # Strings de formato para cada tipo (valores positivos)

    # Valores mínimos para cada tipo signed  
    test_char_min: .byte 65                             # Char mínimo: 'A' (65) para demonstração
    test_short_min: .short -32768                       # Short mínimo: -32768
    test_int_min: .long -2147483648                     # Int mínimo: -2147483648
    test_long_min: .quad -9223372036854775808           # Long mínimo: -9223372036854775808
    test_float_min: .float -999999.999999               # Float grande negativo para demonstração
    test_double_min: .double -123456789.123456789       # Double grande negativo para demonstração
    
    format_char: .string "Char: %c\n"
    format_short: .string "Short: %hd\n"
    format_int: .string "Int: %d\n"
    format_long: .string "Long: %ld\n"
    format_float: .string "Float: %f\n" 
    format_double: .string "Double: %lf\n"
    
    # Strings de formato para valores máximos
    format_char_max: .string "Char MAX: %c (valor: %d)\n"
    format_short_max: .string "Short MAX: %hd\n"
    format_int_max: .string "Int MAX: %d\n"
    format_long_max: .string "Long MAX: %ld\n"
    format_float_max: .string "Float MAX: %f\n"
    format_double_max: .string "Double MAX: %lf\n"
    
    # Strings de formato para valores mínimos
    format_char_min: .string "Char MIN: %c (valor: %d)\n"
    format_short_min: .string "Short MIN: %hd\n"
    format_int_min: .string "Int MIN: %d\n"
    format_long_min: .string "Long MIN: %ld\n"
    format_float_min: .string "Float MIN: %f\n"
    format_double_min: .string "Double MIN: %lf\n"
    
    # Strings de formato para cada tipo (valores negativos)
    format_char_neg: .string "Char (neg): %c\n"
    format_short_neg: .string "Short (neg): %hd\n"
    format_int_neg: .string "Int (neg): %d\n"
    format_long_neg: .string "Long (neg): %ld\n"
    format_float_neg: .string "Float (neg): %f\n"
    format_double_neg: .string "Double (neg): %lf\n"
    
    # |---------------------------------------------|
    # |         TESTES COM A FUNÇÃO SCANF           |
    # |---------------------------------------------|
    
    # Headers e mensagens para testes de scanf
    scanf_header: .string "\n=== TESTE DA FUNÇÃO SCANF ===\n"
    
    # Strings para prompts de entrada do scanf
    scanf_char_prompt: .string "Digite um caractere: "
    scanf_char_format: .string "%c"
    scanf_char_result: .string "Char lido: %c (ASCII: %d)\n"
    
    scanf_short_prompt: .string "Digite um numero short: "
    scanf_short_format: .string "%hd"
    scanf_short_result: .string "Short lido: %hd\n"
    
    scanf_long_prompt: .string "Digite um numero long: "
    scanf_long_format: .string "%ld"
    scanf_long_result: .string "Long lido: %ld\n"
    
    scanf_int_prompt: .string "Digite um numero int: "
    scanf_int_format: .string "%d"
    scanf_int_result: .string "Int lido: %d\n"
    
    scanf_float_prompt: .string "Digite um numero float: "
    scanf_float_format: .string "%f"
    scanf_float_result: .string "Float lido: %f\n"
    
    scanf_double_prompt: .string "Digite um numero double: "
    scanf_double_format: .string "%lf"
    scanf_double_result: .string "Double lido: %lf\n"
    
    # Variáveis para armazenar os valores lidos - 12 valores (pares min/max para cada tipo)
    .align 8
    char_input:      .byte 0     # Char 1 (pequeno)
    char_input2:     .byte 0     # Char 2 (grande) 
    short_input:     .short 0    # Short 1 (pequeno)
    short_input2:    .short 0    # Short 2 (grande)
    int_input:       .long 0     # Int 1 (pequeno)
    int_input2:      .long 0     # Int 2 (grande)
    long_input:      .quad 0     # Long 1 (pequeno)
    long_input2:     .quad 0     # Long 2 (grande)
    float_input:     .long 0     # Float 1 (pequeno)
    float_input2:    .long 0     # Float 2 (grande)
    double_input:    .quad 0     # Double 1 (pequeno)
    double_input2:   .quad 0     # Double 2 (grande)

    # Variáveis para teste com 12 valores (mínimos e máximos)
    char_input3:     .byte 0     # Char 3 (adicional)
    char_input4:     .byte 0     # Char MIN (-128)
    char_input5:     .byte 0     # Char MAX (127)
    short_input3:    .short 0    # Short MIN (-32768)
    short_input4:    .short 0    # Short MAX (32767)
    int_input3:      .long 0     # Int MIN (-2147483648)
    int_input4:      .long 0     # Int MAX (2147483647)
    long_input3:     .quad 0     # Long MIN (-9223372036854775808)
    long_input4:     .quad 0     # Long MAX (9223372036854775807)
    float_input3:    .long 0     # Float MIN (-999999.999999)
    float_input4:    .long 0     # Float MAX (999999.999999)
    double_input3:   .quad 0     # Double MIN (-999999999999999.999999999999999)
    double_input4:   .quad 0     # Double MAX (999999999999999.999999999999999)


    # Strings para teste de múltiplos tipos em uma única chamada
    scanf_multi_prompt: .string "Digite valores EXTREMOS (char:-128/127, short:-32768/32767, int:-2147483648/2147483647, float:±3.4e38, double:±1.7e308):\n"
    scanf_multi_format: .string "%c %hd %d %f %lf"
    scanf_multi_result: .string "Valores EXTREMOS lidos:\n  Char: %c (valor: %d)\n  Short: %hd\n  Int: %d\n  Float: %f\n  Double: %lf\n"

    # Strings para testes individuais de scanf - VALORES MÍNIMOS
    scanf_char_min_prompt: .string "TESTE 1 - Digite char MÍNIMO (-128 ou caractere especial): "
    scanf_char_min_format: .string "%c"
    scanf_char_min_result: .string "Char MÍNIMO lido: '%c' (valor: %d)\n"

    scanf_short_min_prompt: .string "TESTE 2 - Digite short MÍNIMO (-32768): "
    scanf_short_min_format: .string "%hd"
    scanf_short_min_result: .string "Short MÍNIMO lido: %hd\n"

    scanf_int_min_prompt: .string "TESTE 3 - Digite int MÍNIMO (-2147483648): "
    scanf_int_min_format: .string "%d"
    scanf_int_min_result: .string "Int MÍNIMO lido: %d\n"

    scanf_long_min_prompt: .string "TESTE 4 - Digite long MÍNIMO (-9223372036854775808): "
    scanf_long_min_format: .string "%ld"
    scanf_long_min_result: .string "Long MÍNIMO lido: %ld\n"

    scanf_float_min_prompt: .string "TESTE 5 - Digite float MÍNIMO (-3.4e38): "
    scanf_float_min_format: .string "%f"
    scanf_float_min_result: .string "Float MÍNIMO lido: %f\n"

    scanf_double_min_prompt: .string "TESTE 6 - Digite double MÍNIMO (-1.7e308): "
    scanf_double_min_format: .string "%lf"
    scanf_double_min_result: .string "Double MÍNIMO lido: %lf\n"

    # Strings para testes individuais de scanf - VALORES MÁXIMOS
    scanf_char_max_prompt: .string "TESTE 7 - Digite char MÁXIMO (127 ou ~): "
    scanf_char_max_format: .string "%c"
    scanf_char_max_result: .string "Char MÁXIMO lido: '%c' (valor: %d)\n"

    scanf_short_max_prompt: .string "TESTE 8 - Digite short MÁXIMO (32767): "
    scanf_short_max_format: .string "%hd"
    scanf_short_max_result: .string "Short MÁXIMO lido: %hd\n"

    scanf_int_max_prompt: .string "TESTE 9 - Digite int MÁXIMO (2147483647): "
    scanf_int_max_format: .string "%d"
    scanf_int_max_result: .string "Int MÁXIMO lido: %d\n"

    scanf_long_max_prompt: .string "TESTE 10 - Digite long MÁXIMO (9223372036854775807): "
    scanf_long_max_format: .string "%ld"
    scanf_long_max_result: .string "Long MÁXIMO lido: %ld\n"

    scanf_float_max_prompt: .string "TESTE 11 - Digite float MÁXIMO (3.4e38): "
    scanf_float_max_format: .string "%f"
    scanf_float_max_result: .string "Float MÁXIMO lido: %f\n"

    scanf_double_max_prompt: .string "TESTE 12 - Digite double MÁXIMO (1.7e308): "
    scanf_double_max_format: .string "%lf"
    scanf_double_max_result: .string "Double MÁXIMO lido: %lf\n"

    # Cabeçalhos para os testes
    scanf_test_header: .string "\n=== TESTE DA FUNÇAO SCANF ===\n"
    scanf_min_header: .string "\n=== TESTES COM VALORES MÍNIMOS ===\n"
    scanf_max_header: .string "\n=== TESTES COM VALORES MÁXIMOS ===\n"

    # Strings para scanf único com 12 valores
    scanf_12_prompt: .string "\nDigite 12 valores (char short int long float double char short int long float double):\nPrimeiros 6 (MÍNIMOS): A -32768 -2147483648 -9223372036854775808 -3.4e38 -1.7e308\nSegundos 6 (MÁXIMOS): Z 32767 2147483647 9223372036854775807 3.4e38 1.7e308\nEntrada: "
    scanf_6_format: .string "%c %hd %d %ld %f %lf"
    scanf_12_format: .string "%c %hd %d %ld %f %lf %c %hd %d %ld %f %lf"
    # String para resultado dos 12 valores
    scanf_12_result: .string "\n=== RESULTADOS DOS 12 VALORES LIDOS ===\n\nVALORES MÍNIMOS:\n  1. Char: '%c' (valor: %d)\n  2. Short: %hd\n  3. Int: %d\n  4. Long: %ld\n  5. Float: %f\n  6. Double: %lf\n\nVALORES MÁXIMOS:\n  7. Char: '%c' (valor: %d)\n  8. Short: %hd\n  9. Int: %d\n  10. Long: %ld\n  11. Float: %f\n  12. Double: %lf\n"
    
    # Strings para scanf único com 6 valores
    scanf_6_test_header: .string "\n######################################################################################################\n#                                SCANF - 6 VALORES EM UMA ÚNICA CHAMADA                          #\n######################################################################################################\n"
    scanf_6_prompt: .string "Digite 6 valores separados por espaço (char short int long float double): "
    scanf_6_result: .string "\n=== RESULTADOS DOS 6 VALORES LIDOS ===\n1. Char: '%c' (valor: %d)\n2. Short: %hd\n3. Int: %d\n4. Long: %ld\n5. Float: %f\n6. Double: %lf\n"

    # |---------------------------------------------|
    # |         TESTES COM A FUNÇÃO FOPEN/CLOSE     |
    # |---------------------------------------------|
    
    # Strings para teste de fopen/fclose
    fopen_test_header: .string "\n=== TESTE DA FUNÇÃO FOPEN/FCLOSE ===\n"
    fopen_test_filename: .string "teste_arquivo.txt"
    fopen_mode_read: .string "r"
    fopen_mode_write: .string "w"
    fopen_mode_append: .string "a"
    fopen_mode_read_write: .string "r+"
    fopen_mode_write_read: .string "w+"
    fopen_mode_append_read: .string "a+"
    
    fopen_test_creating: .string "Criando arquivo 'teste_arquivo.txt' com modo 'w'...\n"
    fopen_test_success: .string "Arquivo aberto com sucesso! FILE* = %ld\n"
    fopen_test_error: .string "Erro ao abrir arquivo!\n"
    fopen_test_closing: .string "Fechando arquivo...\n"
    fopen_test_close_success: .string "Arquivo fechado com sucesso!\n"
    fopen_test_close_error: .string "Erro ao fechar arquivo!\n"
    
    fopen_test_reading: .string "Tentando abrir arquivo para leitura com modo 'r'...\n"
    fopen_test_appending: .string "Abrindo arquivo para anexar com modo 'a'...\n"

    # |---------------------------------------------|
    # |         TESTES COM A FUNÇÃO FPRINTF         |
    # |---------------------------------------------|
    
    # Strings para teste de fprintf
    fprintf_test_header: .string "\n=== TESTE DA FUNÇÃO FPRINTF ===\n"
    fprintf_test_filename: .string "fprintf_test.txt"
    fprintf_test_opening: .string "Abrindo arquivo 'fprintf_test.txt' para escrita...\n"
    fprintf_test_writing: .string "Escrevendo dados formatados no arquivo...\n"
    fprintf_test_success: .string "Fprintf executado com sucesso! %d caracteres escritos.\n"
    fprintf_test_error: .string "Erro ao executar fprintf!\n"
    fprintf_test_content_header: .string "=== DADOS ESCRITOS NO ARQUIVO ===\n"
    fprintf_sample_data: .string "Teste de fprintf:\nChar: %c (valor: %d)\nShort: %hd\nInt: %d\nLong: %ld\nFloat: %f\nDouble: %lf\nFim do teste.\n"
    test_string_simple: .string "Hello fprintf!\n"
    format_test_char: .string "Char: %c\n"
    format_test_short: .string "Short: %hd\n"
    format_test_int: .string "Int: %d\n"
    format_test_long: .string "Long: %ld\n"
    format_test_float: .string "Float: %f\n"
    format_test_double: .string "Double: %lf\n"
    syscall_write_test: .string "Syscall write direto: %d bytes escritos\n"
    lseek_test: .string "Teste lseek: %d\n"
    byte_by_byte_test: .string "Byte-by-byte write: %d bytes escritos\n"
    write_result_msg: .string " [Write retornou: %d]\n"
    write_args_msg: .string " [Args: fd=%d, tamanho=%d]\n"
    file_ptr_msg: .string " [FILE*=%p]\n"
    fd_loaded_msg: .string " [FD carregado=%d]\n"
    fprintf_test_reading_back: .string "Lendo de volta o conteúdo do arquivo...\n"
    debug_file_ptr: .string "DEBUG: FILE* = %p\n"
    debug_fd: .string "DEBUG: fd = %d\n"
    debug_fprintf_write: .string "DEBUG: Escrevendo %d caracteres no fd %d\n"
    debug_fprintf_result: .string "DEBUG: Resultado da escrita: %d\n"

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
    .globl _get_next_scanf_arg                              # Obtém o próximo argumento para scanf
    .globl _skip_whitespace                                 # Pula espaços em branco, tabs e newlines
    .globl _skip_number_in_buffer                           # implementação básica para avançar buffer TODO: CORRIGIR!!!
    .globl _parse_fopen_mode                                # Função auxiliar para parse do modo de fopen
    .globl _find_free_file_slot                             # Encontra um slot livre na tabela de arquivos

    # FUNÇÕES DE TESTES
    .globl _test_fopen_fclose                               # Test da função fopen/fclose
    .globl _test_printf_all_types                           # Test todos os valores da função printf
    .globl _test_scanf_all_types                            # Test todos os valroes da função scanf

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

    # Aqui faz a alocação do espaço para as variáveis locais que iremos trabalhar
    subq $128, %rsp                                     # Mais espaço para argumentos adicionais

    # Salva os argumentos dos registradores
    movq %rdi, -8(%rbp)                                 # format string
    movq %rsi, -16(%rbp)                                # arg1
    movq %rdx, -24(%rbp)                                # arg2
    movq %rcx, -32(%rbp)                                # arg3
    movq %r8, -40(%rbp)                                 # arg4
    movq %r9, -48(%rbp)                                 # arg5
    
    # Argumentos 6+ já estão na stack (a partir de 16(%rbp))
    # Não precisamos copiá-los, apenas acessá-los quando necessário


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
        
        movq %rax, %rdi                                 # char value como argumento
        movq %r12, %rsi                                 # buffer de destino
        call _char_to_str                               # converter char para string
        
        addq %rax, %r12                                 # avança o buffer pelo número de caracteres
        addl %eax, -52(%rbp)                            # adiciona ao contador de caracteres
        
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
        addq $128, %rsp                                  # Corresponde ao subq $128 anterior
        popq %rbx
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        ret

# ######################################################################################################
# SCANF - Implementação de scanf com suporte aos tipos: char, short, int, long, float, double
# ######################################################################################################

_scanf:
    # Entrada: %rdi = format string, %rsi, %rdx, %rcx, %r8, %r9 = ponteiros para variáveis
    # Saída: %rax = número de items lidos
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

    # Verificar se já existe dados no buffer (input_position > 0)
    movq input_position(%rip), %rcx
    cmpq $0, %rcx
    jg scanf_use_existing_buffer

    # Ler entrada do usuário (primeira vez)
    movq $SYS_READ, %rax
    movq $STDIN_FD, %rdi
    movq -24(%rbp), %rsi            # usa o buffer_ptr
    movq $BUFFER_SIZE, %rdx
    syscall

    # Verificar se houve erro na leitura
    cmpl $0, %eax
    jle scanf_complete_error
    movl %eax, -36(%rbp)            # bytes_read = resultado da syscall
    movq %rax, input_size(%rip)     # salva tamanho lido
    movq $0, input_position(%rip)   # zera posição inicial

    scanf_use_existing_buffer:
    # Processar formato e argumentos
    movq -8(%rbp), %r12             # r12 = format_ptr
    movq -24(%rbp), %r13            # r13 = buffer_ptr (entrada do usuário)
    addq input_position(%rip), %r13 # ajusta para posição atual no buffer

    scanf_parse_loop:
        movb (%r12), %al                # al = caractere atual do formato
        testb %al, %al                  # verifica o fim da string
        jz scanf_complete_success
        
        cmpb $'%', %al                  # verificar se é o especificador
        jne scanf_skip_char
        
        # Processa o especificador
        incq %r12                       # próximo caractere após '%'
        movb (%r12), %al                # al = tipo do especificador
        movb %al, -45(%rbp)             # salva format_char
        
        # Determina o ponteiro do argumento atual de forma dinâmica
        movl -44(%rbp), %ecx            # ecx = arg_index
        
        # Verifica se é um dos primeiros 5 argumentos (registradores)
        cmpl $5, %ecx
        jl scanf_register_args
        
        # Argumentos 6+ estão na stack do caller
        # Posição na stack: 16 + (arg_index - 5) * 8 + (%rbp)
        subl $5, %ecx                   # ecx = arg_index - 5 (offset a partir do 6º)
        imulq $8, %rcx                  # ecx = offset * 8 bytes
        addq $16, %rcx                  # ecx = 16 + offset (posição na stack)
        movq (%rbp,%rcx), %r14          # r14 = argumento da stack
        jmp scanf_process_type
        
    scanf_register_args:
        # Argumentos 0-4 estão salvos nas variáveis locais
        # Calcula o offset: -56 + arg_index * 8
        movl -44(%rbp), %ecx            # ecx = arg_index
        imulq $8, %rcx                  # ecx = arg_index * 8
        subq %rcx, %r14                 # r14 = base_offset - (arg_index * 8)
        movq $-56, %r14                 # base offset para arg0
        subq %rcx, %r14                 # r14 = -56 - (arg_index * 8)
        movq (%rbp,%r14), %r14          # r14 = argumento salvo
        jmp scanf_process_type

    scanf_process_type:
        # Verificar tipo do especificador
        cmpb $'c', %al                  # char
        je scanf_read_char
        
        cmpb $'h', %al                  # verifica se é %hd (short)
        je scanf_check_short
        
        cmpb $'d', %al                  # int
        je scanf_read_int
        
        cmpb $'l', %al                  # verifica se é %ld (long)
        je scanf_check_long
        
        cmpb $'f', %al                  # float
        je scanf_read_float

    scanf_check_short:
        incq %r12                       # próximo caractere
        movb (%r12), %al

        cmpb $'d', %al
        
        je scanf_read_short
        jmp scanf_complete_error
        
    scanf_check_long:
        incq %r12                      # próximo caractere
        movb (%r12), %al
        
        cmpb $'d', %al
        
        je scanf_read_long
        cmpb $'f', %al                 # %lf (double)
        
        je scanf_read_double
        jmp scanf_complete_error
        
    scanf_read_char:
        # Ler um caractere usando função de conversão
        call _skip_whitespace         # pula espaços/tabs/newlines
        
        movq %r13, %rdi               # string de entrada 
        call _str_to_char             # converter string para char
        
        movb %al, (%r14)              # *arg = char value
        incq %r13                     # avançar buffer (apenas 1 posição para char)
        incq input_position(%rip)     # atualizar posição global
        
        jmp scanf_item_processed
        
    scanf_read_short:
        # Ler short
        call _skip_whitespace        # pula espaços em branco
        
        movq %r13, %rdi              # string de entrada
        
        call _str_to_short           # converte para short
        
        movw %ax, (%r14)             # *arg = short value
        
        call _skip_number_in_buffer  # avançar buffer
        
        jmp scanf_item_processed
        
    scanf_read_int:
        # Ler int
        call _skip_whitespace        # pula espaços em branco
        
        movq %r13, %rdi              # string de entrada
        
        call _str_to_int             # converte para int
        
        movl %eax, (%r14)            # *arg = int value
        
        call _skip_number_in_buffer  # avança o buffer
        
        jmp scanf_item_processed
        
    scanf_read_long:
        # Ler long
        call _skip_whitespace        # pula espaços em branco
        
        movq %r13, %rdi              # string de entrada
        
        call _str_to_long            # converte para long
        
        movq %rax, (%r14)            # *arg = long value
        
        call _skip_number_in_buffer  # avança o buffer
        
        jmp scanf_item_processed
        
    scanf_read_float:
        # Ler float
        call _skip_whitespace       # pula espaços em branco
        
        movq %r13, %rdi             # string de entrada
        
        call _str_to_float          # converte para float, retorna chars consumidos em %rax
        
        pushq %rax                  # salva número de caracteres consumidos
        
        movd %xmm0, %eax            # obtém representação binária do float
        
        movl %eax, (%r14)           # *arg = float value (como bits)
        
        popq %rax                   # recupera número de caracteres consumidos
        addq %rax, %r13             # avança buffer pelo número de caracteres lidos
        addq %rax, input_position(%rip) # atualiza posição global
        
        jmp scanf_item_processed
        
    scanf_read_double:
        # Ler double
        call _skip_whitespace      # pula espaços em branco
        
        movq %r13, %rdi            # string de entrada
        
        call _str_to_double        # converte para double, retorna chars consumidos em %rax
        
        pushq %rax                 # salva número de caracteres consumidos
        
        movq %xmm0, %rax           # obtém representação binária do double
        movq %rax, (%r14)          # *arg = double value (como bits)
        
        popq %rax                  # recupera número de caracteres consumidos  
        addq %rax, %r13            # avança buffer pelo número de caracteres lidos
        addq %rax, input_position(%rip) # atualiza posição global
        
        jmp scanf_item_processed
        
    scanf_item_processed:
        incl -40(%rbp)             # items_read++
        incl -44(%rbp)             # arg_index++
        
    scanf_skip_char:
        incq %r12                  # próximo caractere no formato
        jmp scanf_parse_loop
        
    scanf_complete_error:
        movl $-1, %eax             # retornar -1 (erro)
        jmp scanf_complete_done
        
    scanf_complete_success:
        movl -40(%rbp), %eax       # retornar items_read 
        
    scanf_complete_done:
        # Restaurar stack
        addq $88, %rsp             # total de bytes alocados
        popq %rbp

        ret

# ######################################################################################################
# FPRINTF - Implementação de fprintf para escrita em arquivos
# ######################################################################################################

_fprintf:
    # Entrada: %rdi = FILE *stream, %rsi = format string, %rdx, %rcx, %r8, %r9 = argumentos
    # Saída: %rax = número de caracteres escritos
    
    # Configuração do quadro de pilha
    pushq %rbp
    movq %rsp, %rbp
    
    # Preserva registradores callee-saved
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    
    # Aloca espaço para variáveis locais (80 bytes alinhados)
    # -8(%rbp)  = file_ptr (FILE *)
    # -16(%rbp) = format_ptr (char *)
    # -24(%rbp) = buffer_ptr (char *)
    # -32(%rbp) = char_count (int)
    # -40(%rbp) = arg_index (int)
    # -48(%rbp) = arg1_saved (reg arg 1)
    # -56(%rbp) = arg2_saved (reg arg 2)
    # -64(%rbp) = arg3_saved (reg arg 3)
    # -72(%rbp) = arg4_saved (reg arg 4)
    # -80(%rbp) = stack_args_ptr (ponteiro para args na pilha)
    subq $80, %rsp
    
    # Salva argumentos em variáveis locais
    movq %rdi, -8(%rbp)         # file_ptr = FILE*
    movq %rsi, -16(%rbp)        # format_ptr = format string
    movq %rdx, -48(%rbp)        # arg1_saved = %rdx
    movq %rcx, -56(%rbp)        # arg2_saved = %rcx
    movq %r8, -64(%rbp)         # arg3_saved = %r8
    movq %r9, -72(%rbp)         # arg4_saved = %r9
    
    # Calcula ponteiro para argumentos na pilha (além dos 6 registradores)
    leaq 16(%rbp), %rax         # primeiro arg na pilha está em 16(%rbp)
    movq %rax, -80(%rbp)        # stack_args_ptr
    
    # Verifica se FILE* é válido
    cmpq $0, -8(%rbp)
    je fprintf_error
    
    # Verifica se format string é válida
    cmpq $0, -16(%rbp)
    je fprintf_error
    
    # Inicializa variáveis
    leaq output_buffer(%rip), %rax
    movq %rax, -24(%rbp)        # buffer_ptr = output_buffer
    movl $0, -32(%rbp)          # char_count = 0
    movl $0, -40(%rbp)          # arg_index = 0
    
    # IMPORTANTE: Limpa o buffer antes de usar
    pushq %rdi
    pushq %rsi  
    pushq %rcx
    movq %rax, %rdi             # destino = output_buffer
    movl $0, %eax               # valor = 0
    movl $BUFFER_SIZE, %ecx     # tamanho = BUFFER_SIZE
    rep stosb                   # limpa buffer
    popq %rcx
    popq %rsi
    popq %rdi
    
    # Restaura buffer_ptr
    leaq output_buffer(%rip), %rax
    movq %rax, -24(%rbp)        # buffer_ptr = output_buffer
    
    fprintf_loop:
        # Carrega próximo caractere do format string
        movq -16(%rbp), %rax    # rax = format_ptr
        movb (%rax), %bl        # bl = *format_ptr
        testb %bl, %bl          # verifica se chegou ao fim
        jz fprintf_write_buffer # se sim, escreve buffer e termina
        
        # Avança format_ptr
        incq -16(%rbp)          # format_ptr++
        
        # Verifica se é especificador de formato (%)
        cmpb $'%', %bl
        je fprintf_format_spec
        
        # Caractere normal - adiciona ao buffer
        movq -24(%rbp), %rax    # rax = buffer_ptr
        movb %bl, (%rax)        # *buffer_ptr = caractere
        incq -24(%rbp)          # buffer_ptr++
        incl -32(%rbp)          # char_count++
        
        jmp fprintf_loop
    
    fprintf_format_spec:
        # Processa especificador de formato
        movq -16(%rbp), %rax    # rax = format_ptr
        movb (%rax), %bl        # bl = próximo caractere
        testb %bl, %bl          # verifica se chegou ao fim
        jz fprintf_write_buffer # se sim, termina
        
        # Avança format_ptr
        incq -16(%rbp)          # format_ptr++
        
        # Verifica tipo do especificador
        cmpb $'c', %bl
        je fprintf_char
        cmpb $'h', %bl
        je fprintf_short_spec
        cmpb $'d', %bl
        je fprintf_int
        cmpb $'l', %bl
        je fprintf_long_spec
        cmpb $'f', %bl
        je fprintf_float
        cmpb $'%', %bl
        je fprintf_percent
        
        # Especificador desconhecido - ignora
        jmp fprintf_loop
    
    fprintf_char:
        # Processar %c
        call fprintf_get_next_arg   # retorna arg em %rax
        movq -24(%rbp), %rdx        # rdx = buffer_ptr
        movb %al, (%rdx)            # *buffer_ptr = (char)arg
        incq -24(%rbp)              # buffer_ptr++
        incl -32(%rbp)              # char_count++
        jmp fprintf_loop
    
    fprintf_short_spec:
        # Verifica se é %hd (short)
        movq -16(%rbp), %rax    # rax = format_ptr
        movb (%rax), %bl        # bl = próximo caractere
        cmpb $'d', %bl
        jne fprintf_loop        # se não é 'd', ignora
        incq -16(%rbp)          # format_ptr++ (pula o 'd')
        
        # Processar %hd
        call fprintf_get_next_arg   # retorna arg em %rax
        movswq %ax, %rdi            # sign-extend short para long
        movq -24(%rbp), %rsi        # rsi = buffer_ptr
        call _short_to_str          # converte short para string
        addq %rax, -24(%rbp)        # buffer_ptr += tamanho
        addl %eax, -32(%rbp)        # char_count += tamanho
        jmp fprintf_loop
    
    fprintf_int:
        # Processar %d
        call fprintf_get_next_arg   # retorna arg em %rax
        movslq %eax, %rdi           # sign-extend int para long
        movq -24(%rbp), %rsi        # rsi = buffer_ptr
        call _int_to_str            # converte int para string
        addq %rax, -24(%rbp)        # buffer_ptr += tamanho
        addl %eax, -32(%rbp)        # char_count += tamanho
        jmp fprintf_loop
    
    fprintf_long_spec:
        # Verifica se é %ld (long)
        movq -16(%rbp), %rax    # rax = format_ptr
        movb (%rax), %bl        # bl = próximo caractere
        cmpb $'d', %bl
        je fprintf_long_int
        cmpb $'f', %bl
        je fprintf_double
        jmp fprintf_loop        # especificador desconhecido
        
    fprintf_long_int:
        # Processar %ld
        incq -16(%rbp)          # format_ptr++ (pula o 'd')
        call fprintf_get_next_arg   # retorna arg em %rax
        movq %rax, %rdi             # arg como long
        movq -24(%rbp), %rsi        # rsi = buffer_ptr
        call _long_to_str           # converte long para string
        addq %rax, -24(%rbp)        # buffer_ptr += tamanho
        addl %eax, -32(%rbp)        # char_count += tamanho
        jmp fprintf_loop
    
    fprintf_double:
        # Processar %lf (double)
        incq -16(%rbp)          # format_ptr++ (pula o 'f')
        call fprintf_get_next_double # retorna double em %xmm0
        movq -24(%rbp), %rdi        # rdi = buffer_ptr
        call _double_to_str         # converte double para string
        addq %rax, -24(%rbp)        # buffer_ptr += tamanho
        addl %eax, -32(%rbp)        # char_count += tamanho
        jmp fprintf_loop
    
    fprintf_float:
        # Processar %f
        call fprintf_get_next_float # retorna float em %xmm0
        movq -24(%rbp), %rdi        # rdi = buffer_ptr
        call _float_to_str          # converte float para string
        addq %rax, -24(%rbp)        # buffer_ptr += tamanho
        addl %eax, -32(%rbp)        # char_count += tamanho
        jmp fprintf_loop
    
    fprintf_percent:
        # Processar %% (% literal)
        movq -24(%rbp), %rax    # rax = buffer_ptr
        movb $'%', (%rax)       # *buffer_ptr = '%'
        incq -24(%rbp)          # buffer_ptr++
        incl -32(%rbp)          # char_count++
        jmp fprintf_loop
    
    fprintf_write_buffer:
        # Escreve buffer no arquivo
        leaq output_buffer(%rip), %rax
        movq -24(%rbp), %rdx        # rdx = buffer_ptr
        subq %rax, %rdx             # rdx = tamanho do buffer
        testq %rdx, %rdx            # verifica se há algo para escrever
        jz fprintf_done             # se buffer vazio, termina
        
        # Syscall write
        movq $SYS_WRITE, %rax       # syscall write
        movq -8(%rbp), %rdi         # rdi = file_ptr
        movq (%rdi), %rdi           # rdi = fd
        leaq output_buffer(%rip), %rsi # rsi = buffer
        # rdx já contém o tamanho
        syscall
        
        # Verifica se write foi bem-sucedido
        cmpq $0, %rax
        jl fprintf_error
        
        # CORREÇÃO: Força sincronização para garantir que dados sejam escritos
        pushq %rax                  # salva resultado do write
        movq $SYS_FSYNC, %rax
        movq -8(%rbp), %rdi         # file_ptr
        movq (%rdi), %rdi           # fd
        syscall
        popq %rax                   # restaura resultado do write
        
        jmp fprintf_done
    
    fprintf_get_next_arg:
        # Retorna próximo argumento em %rax
        movl -40(%rbp), %eax        # eax = arg_index
        cmpl $0, %eax
        je fprintf_get_arg0
        cmpl $1, %eax
        je fprintf_get_arg1
        cmpl $2, %eax
        je fprintf_get_arg2
        cmpl $3, %eax
        je fprintf_get_arg3
        
        # Argumentos da pilha (index >= 4)
        subl $4, %eax               # index -= 4
        movq -80(%rbp), %rdx        # rdx = stack_args_ptr
        movq (%rdx,%rax,8), %rax    # rax = stack_args[index]
        jmp fprintf_inc_arg_index
        
    fprintf_get_arg0:
        movq -48(%rbp), %rax        # arg1_saved
        jmp fprintf_inc_arg_index
    fprintf_get_arg1:
        movq -56(%rbp), %rax        # arg2_saved
        jmp fprintf_inc_arg_index
    fprintf_get_arg2:
        movq -64(%rbp), %rax        # arg3_saved
        jmp fprintf_inc_arg_index
    fprintf_get_arg3:
        movq -72(%rbp), %rax        # arg4_saved
        jmp fprintf_inc_arg_index
        
    fprintf_inc_arg_index:
        incl -40(%rbp)              # arg_index++
        ret
    
    fprintf_get_next_float:
        # Similar a fprintf_get_next_arg mas para floats (retorna em %xmm0)
        movl -40(%rbp), %eax        # eax = arg_index
        cmpl $0, %eax
        je fprintf_get_float0
        cmpl $1, %eax
        je fprintf_get_float1
        cmpl $2, %eax
        je fprintf_get_float2
        cmpl $3, %eax
        je fprintf_get_float3
        
        # Argumentos da pilha
        subl $4, %eax
        movq -80(%rbp), %rdx
        movss (%rdx,%rax,8), %xmm0
        jmp fprintf_inc_arg_index
        
    fprintf_get_float0:
        movq -48(%rbp), %rax
        movd %eax, %xmm0
        jmp fprintf_inc_arg_index
    fprintf_get_float1:
        movq -56(%rbp), %rax
        movd %eax, %xmm0
        jmp fprintf_inc_arg_index
    fprintf_get_float2:
        movq -64(%rbp), %rax
        movd %eax, %xmm0
        jmp fprintf_inc_arg_index
    fprintf_get_float3:
        movq -72(%rbp), %rax
        movd %eax, %xmm0
        jmp fprintf_inc_arg_index
    
    fprintf_get_next_double:
        # Similar a fprintf_get_next_arg mas para doubles (retorna em %xmm0)
        movl -40(%rbp), %eax        # eax = arg_index
        cmpl $0, %eax
        je fprintf_get_double0
        cmpl $1, %eax
        je fprintf_get_double1
        cmpl $2, %eax
        je fprintf_get_double2
        cmpl $3, %eax
        je fprintf_get_double3
        
        # Argumentos da pilha
        subl $4, %eax
        movq -80(%rbp), %rdx
        movsd (%rdx,%rax,8), %xmm0
        jmp fprintf_inc_arg_index
        
    fprintf_get_double0:
        movq -48(%rbp), %rax
        movq %rax, %xmm0
        jmp fprintf_inc_arg_index
    fprintf_get_double1:
        movq -56(%rbp), %rax
        movq %rax, %xmm0
        jmp fprintf_inc_arg_index
    fprintf_get_double2:
        movq -64(%rbp), %rax
        movq %rax, %xmm0
        jmp fprintf_inc_arg_index
    fprintf_get_double3:
        movq -72(%rbp), %rax
        movq %rax, %xmm0
        jmp fprintf_inc_arg_index
    
    fprintf_error:
        movl $-1, %eax
        jmp fprintf_exit
        
    fprintf_done:
        movl -32(%rbp), %eax        # retorna char_count
        
    fprintf_exit:
        # Restaura registradores callee-saved
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        
        # Restaura pilha e retorna
        movq %rbp, %rsp
        popq %rbp
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
    # Entrada: %rdi = nome do arquivo, %rsi = modo ("r", "w", "a", etc.)
    # Saída: %rax = FILE * (ponteiro para FILE, NULL se erro)
    
    # Configuração do quadro de pilha
    pushq %rbp
    movq %rsp, %rbp
    
    # Preserva registradores callee-saved
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    
    # Aloca espaço para variáveis locais (48 bytes alinhados)
    # -8(%rbp)  = filename (char *)
    # -16(%rbp) = mode (char *)
    # -24(%rbp) = flags (int)
    # -32(%rbp) = fd (int)
    # -40(%rbp) = file_ptr (FILE *)
    subq $48, %rsp
    
    # Salva argumentos em variáveis locais
    movq %rdi, -8(%rbp)         # filename = %rdi
    movq %rsi, -16(%rbp)        # mode = %rsi
    
    # Verifica se os argumentos são válidos
    cmpq $0, -8(%rbp)
    je fopen_error              # filename é NULL
    cmpq $0, -16(%rbp)
    je fopen_error              # mode é NULL
    
    # Parse do modo de abertura para determinar flags
    movq -16(%rbp), %rdi        # %rdi = mode
    call _parse_fopen_mode      # retorna flags em %rax
    movq %rax, -24(%rbp)        # flags = resultado
    cmpq $-1, -24(%rbp)
    je fopen_error              # modo inválido
    
    # Abre o arquivo usando syscall open
    movq $SYS_OPEN, %rax        # syscall number para open
    movq -8(%rbp), %rdi         # %rdi = filename
    movq -24(%rbp), %rsi        # %rsi = flags
    movq $0644, %rdx            # %rdx = permissions (rw-r--r--)
    syscall
    
    # Verifica se a abertura foi bem-sucedida
    movq %rax, -32(%rbp)        # fd = resultado do syscall
    cmpq $0, -32(%rbp)
    jl fopen_error              # fd < 0 indica erro
    
    # Encontra um slot livre na tabela de arquivos
    call _find_free_file_slot
    movq %rax, -40(%rbp)        # file_ptr = resultado
    cmpq $0, -40(%rbp)
    je fopen_close_and_error    # não há slots livres
    
    # Inicializa a estrutura FILE
    movq -40(%rbp), %r12        # %r12 = file_ptr
    movq -32(%rbp), %rax        # %rax = fd
    movq %rax, (%r12)           # FILE->fd = fd
    
    movq -16(%rbp), %rax        # %rax = mode
    movq %rax, 8(%r12)          # FILE->mode = mode
    
    movq $0, 16(%r12)           # FILE->buffer = NULL
    movq $0, 24(%r12)           # FILE->buffer_pos = 0
    
    # Retorna ponteiro para FILE
    movq -40(%rbp), %rax        # return file_ptr
    jmp fopen_done
    
    fopen_close_and_error:
        # Fecha o arquivo já aberto antes de retornar erro
        movq $SYS_CLOSE, %rax
        movq -32(%rbp), %rdi        # %rdi = fd
        syscall
        # Fall through para fopen_error
    
    fopen_error:
        movq $0, %rax               # return NULL
    
    fopen_done:
        # Restaura registradores callee-saved
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        
        # Restaura pilha e retorna
        movq %rbp, %rsp
        popq %rbp
        ret

# ######################################################################################################
# FCLOSE - Implementação de fclose para fechamento de arquivos
# ######################################################################################################

_fclose:
    # Entrada: %rdi = FILE *stream
    # Saída: %rax = 0 (sucesso) ou EOF (erro)
    pushq %rbp
    movq %rsp, %rbp
    
    # Verifica se o ponteiro FILE é válido
    testq %rdi, %rdi
    jz fclose_error             # ponteiro NULL
    
    # Verifica se o file descriptor é válido
    movq (%rdi), %rax           # carrega fd
    testq %rax, %rax
    jz fclose_error             # fd == 0 (já fechado)
    
    # Força sincronização antes de fechar
    pushq %rdi                  # salva ponteiro FILE
    movq $SYS_FSYNC, %rax
    movq (%rdi), %rdi           # fd como argumento para fsync
    syscall
    popq %rdi                   # restaura ponteiro FILE
    
    # Fecha o arquivo
    pushq %rdi                  # salva ponteiro FILE
    movq $SYS_CLOSE, %rax
    movq (%rdi), %rdi           # fd como argumento
    syscall
    popq %rdi                   # restaura ponteiro FILE
    
    # Verifica se o close foi bem-sucedido (valores negativos indicam erro)
    cmpq $0, %rax
    jl fclose_error             # se < 0, houve erro
    
    # Marca o slot como livre zerando o fd
    movq $0, (%rdi)             # FILE->fd = 0
    movq $0, 8(%rdi)            # FILE->mode = NULL
    movq $0, 16(%rdi)           # FILE->buffer = NULL
    movq $0, 24(%rdi)           # FILE->buffer_pos = 0
    
    # Sucesso
    movq $0, %rax
    jmp fclose_done
    
    fclose_error:
        movq $EOF, %rax             # retorna EOF (-1)
        
    fclose_done:
        popq %rbp
        ret

# ######################################################################################################
# FUNÇÕES DE CONVERSÃO STRING-TO-TYPE
# ######################################################################################################

_str_to_char:
    # Entrada: %rdi = ponteiro para string
    # Saída: %rax = valor char convertido (primeiro caractere da string)
    pushq %rbp
    movq %rsp, %rbp
    
    # Verifica se o ponteiro é válido (não NULL)
    testq %rdi, %rdi
    jz str_to_char_null
    
    # Carrega o primeiro caractere da string
    movb (%rdi), %al                                    # carrega o primeiro byte da string
    movzbq %al, %rax                                    # zero-extend para 64 bits (unsigned)
    
    # Verifica se é o terminador nulo
    testb %al, %al
    jz str_to_char_empty
    
    jmp str_to_char_done
    
    str_to_char_null:
        # Retorna 0 se ponteiro for NULL
        movq $0, %rax
        jmp str_to_char_done
        
    str_to_char_empty:
        # Retorna 0 se string for vazia (primeiro char é '\0')
        movq $0, %rax
        jmp str_to_char_done
    
    str_to_char_done:
        popq %rbp
        ret

_str_to_short:
    # Entrada: %rdi = ponteiro para string  
    # Saída: %rax = valor short convertido
    pushq %rbp
    movq %rsp, %rbp
    
    # Preserva os registradores que serão utilizados
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    
    # Verifica se o ponteiro é válido (não NULL)
    testq %rdi, %rdi
    jz str_to_short_null
    
    # Inicialização das variáveis
    movq %rdi, %r12                                     # ponteiro para a string
    movq $0, %r13                                       # resultado acumulado
    movq $0, %r14                                       # flag de sinal (0=positivo, 1=negativo)
    movq $1, %r15                                       # multiplicador (para conversão)
    
    # Verifica se o primeiro caractere é um sinal
    movb (%r12), %al                                    # carrega o primeiro caractere
    testb %al, %al                                      # verifica se chegou no final da string
    jz str_to_short_empty
    
    cmpb $'-', %al                                      # verifica se o sinal é negativo
    je str_to_short_negative

    cmpb $'+', %al                                      # verifica se o sinal é positivo
    je str_to_short_positive
    
    # Se não há sinal, começa a conversão diretamente
    jmp str_to_short_convert_loop
    
    str_to_short_negative:
        movq $1, %r14                                   # marca como negativo
        incq %r12                                       # pula o sinal '-'
        jmp str_to_short_convert_loop
        
    str_to_short_positive:
        incq %r12                                       # pula o sinal '+'
        jmp str_to_short_convert_loop
    
    str_to_short_convert_loop:
        movb (%r12), %al                                # carrega o caractere atual
        testb %al, %al                                  # verifica se é o fim da string
        jz str_to_short_done
        
        # Verifica se é um dígito válido
        cmpb $'0', %al
        jb str_to_short_done                            # se for menor que '0', para
        cmpb $'9', %al
        ja str_to_short_done                            # se for maior que '9', para
        
        # Converte caractere para dígito numérico
        subb $'0', %al                                  # converte ASCII para número
        movzbq %al, %rax                                # zero-extend para 64 bits
        
        # Multiplica o resultado anterior por 10 e adiciona ao novo dígito
        imulq $10, %r13                                 # r13 = r13 * 10
        addq %rax, %r13                                 # r13 = r13 + novo_dígito
        
        # Verifica overflow para short (-32768 a 32767)
        cmpq $32767, %r13                               # verifica se excede o limite positivo
        jg str_to_short_overflow
        
        incq %r12                                       # próximo caractere
        jmp str_to_short_convert_loop
    
    str_to_short_done:
        # Aplica o sinal se necessário
        testq %r14, %r14                                # verifica se é negativo
        jz str_to_short_apply_result                    # se positivo, vai direto
        
        # Verifica se há overflow para negativo
        cmpq $32768, %r13                               # verifica se excede o limite negativo
        jg str_to_short_overflow
        
        negq %r13                                       # aplica o sinal negativo
        
    str_to_short_apply_result:
        movq %r13, %rax                                 # retorna o resultado
        jmp str_to_short_exit
    
    str_to_short_null:
        # Retorna 0 se ponteiro for NULL
        movq $0, %rax
        jmp str_to_short_exit
        
    str_to_short_empty:
        # Retorna 0 se string for vazia
        movq $0, %rax
        jmp str_to_short_exit
        
    str_to_short_overflow:
        # Em caso de overflow, retorna o valor limite apropriado
        testq %r14, %r14                                # verifica sinal
        jz str_to_short_max_positive
        
        # Overflow negativo: retorna -32768
        movq $-32768, %rax
        jmp str_to_short_exit
        
    str_to_short_max_positive:
        # Overflow positivo: retorna 32767
        movq $32767, %rax
        jmp str_to_short_exit
    
    str_to_short_exit:
        # Restaura registradores preservados
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        ret

_str_to_int:
    # Entrada: %rdi = ponteiro para string  
    # Saída: %rax = valor int convertido
    pushq %rbp
    movq %rsp, %rbp
    
    # Preserva os registradores que serão utilizados
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    
    # Verifica se o ponteiro é válido (não NULL)
    testq %rdi, %rdi
    jz str_to_int_null
    
    # Inicialização das variáveis
    movq %rdi, %r12                                     # ponteiro para a string
    movq $0, %r13                                       # resultado acumulado
    movq $0, %r14                                       # flag de sinal (0=positivo, 1=negativo)
    movq $1, %r15                                       # multiplicador (para conversão)
    
    # Verifica se o primeiro caractere é um sinal
    movb (%r12), %al                                    # carrega o primeiro caractere
    testb %al, %al                                      # verifica se chegou no final da string
    jz str_to_int_empty
    
    cmpb $'-', %al                                      # verifica se o sinal é negativo
    je str_to_int_negative

    cmpb $'+', %al                                      # verifica se o sinal é positivo
    je str_to_int_positive
    
    # Se não há sinal, começa a conversão diretamente
    jmp str_to_int_convert_loop
    
    str_to_int_negative:
        movq $1, %r14                                   # marca como negativo
        incq %r12                                       # pula o sinal '-'
        jmp str_to_int_convert_loop
        
    str_to_int_positive:
        incq %r12                                       # pula o sinal '+'
        jmp str_to_int_convert_loop
    
    str_to_int_convert_loop:
        movb (%r12), %al                                # carrega o caractere atual
        testb %al, %al                                  # verifica se é o fim da string
        jz str_to_int_done
        
        # Verifica se é um dígito válido
        cmpb $'0', %al
        jb str_to_int_done                              # se for menor que '0', para
        cmpb $'9', %al
        ja str_to_int_done                              # se for maior que '9', para
        
        # Converte caractere para dígito numérico
        subb $'0', %al                                  # converte ASCII para número
        movzbq %al, %rax                                # zero-extend para 64 bits
        
        # Multiplica o resultado anterior por 10 e adiciona ao novo dígito
        imulq $10, %r13                                 # r13 = r13 * 10
        addq %rax, %r13                                 # r13 = r13 + novo_dígito
        
        # Verifica overflow para int (-2147483648 a 2147483647)
        cmpq $2147483647, %r13                          # verifica se excede o limite positivo
        jg str_to_int_overflow
        
        incq %r12                                       # próximo caractere
        jmp str_to_int_convert_loop
    
    str_to_int_done:
        # Aplica o sinal se necessário
        testq %r14, %r14                                # verifica se é negativo
        jz str_to_int_apply_result                      # se positivo, vai direto
        
        # Verifica se há overflow para negativo
        movq $2147483648, %rax                          # carrega limite negativo
        cmpq %rax, %r13                                 # verifica se excede o limite negativo
        jg str_to_int_overflow
        
        negq %r13                                       # aplica o sinal negativo
        
    str_to_int_apply_result:
        movq %r13, %rax                                 # retorna o resultado
        jmp str_to_int_exit
    
    str_to_int_null:
        # Retorna 0 se ponteiro for NULL
        movq $0, %rax
        jmp str_to_int_exit
        
    str_to_int_empty:
        # Retorna 0 se string for vazia
        movq $0, %rax
        jmp str_to_int_exit
        
    str_to_int_overflow:
        # Em caso de overflow, retorna o valor limite apropriado
        testq %r14, %r14                                # verifica sinal
        jz str_to_int_max_positive
        
        # Overflow negativo: retorna -2147483648
        movq $-2147483648, %rax
        jmp str_to_int_exit
        
    str_to_int_max_positive:
        # Overflow positivo: retorna 2147483647
        movq $2147483647, %rax
        jmp str_to_int_exit
    
    str_to_int_exit:
        # Restaura registradores preservados
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        ret

_str_to_long:
    # Entrada: %rdi = ponteiro para string  
    # Saída: %rax = valor long convertido
    pushq %rbp
    movq %rsp, %rbp
    
    # Preserva os registradores que serão utilizados
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    
    # Verifica se o ponteiro é válido (não NULL)
    testq %rdi, %rdi
    jz str_to_long_null
    
    # Inicialização das variáveis
    movq %rdi, %r12                                     # ponteiro para a string
    movq $0, %r13                                       # resultado acumulado
    movq $0, %r14                                       # flag de sinal (0=positivo, 1=negativo)
    movq $1, %r15                                       # multiplicador (para conversão)
    
    # Verifica se o primeiro caractere é um sinal
    movb (%r12), %al                                    # carrega o primeiro caractere
    testb %al, %al                                      # verifica se chegou no final da string
    jz str_to_long_empty
    
    cmpb $'-', %al                                      # verifica se o sinal é negativo
    je str_to_long_negative

    cmpb $'+', %al                                      # verifica se o sinal é positivo
    je str_to_long_positive
    
    # Se não há sinal, começa a conversão diretamente
    jmp str_to_long_convert_loop
    
    str_to_long_negative:
        movq $1, %r14                                   # marca como negativo
        incq %r12                                       # pula o sinal '-'
        jmp str_to_long_convert_loop
        
    str_to_long_positive:
        incq %r12                                       # pula o sinal '+'
        jmp str_to_long_convert_loop
    
    str_to_long_convert_loop:
        movb (%r12), %al                                # carrega o caractere atual
        testb %al, %al                                  # verifica se é o fim da string
        jz str_to_long_done
        
        # Verifica se é um dígito válido
        cmpb $'0', %al
        jb str_to_long_done                             # se for menor que '0', para
        cmpb $'9', %al
        ja str_to_long_done                             # se for maior que '9', para
        
        # Converte caractere para dígito numérico
        subb $'0', %al                                  # converte ASCII para número
        movzbq %al, %rax                                # zero-extend para 64 bits
        
        # Verifica overflow antes da multiplicação (limite positivo dividido por 10)
        movq $922337203685477580, %rdx                  # 9223372036854775807 / 10 = 922337203685477580
        cmpq %rdx, %r13
        jg str_to_long_overflow                         # se r13 > limite/10, vai dar overflow
        
        # Se r13 == limite/10, verifica se o último dígito causará overflow
        je str_to_long_check_last_digit
        
        # Multiplica o resultado anterior por 10 e adiciona ao novo dígito
        imulq $10, %r13                                 # r13 = r13 * 10
        addq %rax, %r13                                 # r13 = r13 + novo_dígito
        
        incq %r12                                       # próximo caractere
        jmp str_to_long_convert_loop
    
    str_to_long_check_last_digit:
        # Verifica se o último dígito causará overflow
        # Para positivo: último dígito deve ser <= 7 (9223372036854775807)
        # Para negativo: último dígito deve ser <= 8 (9223372036854775808)
        testq %r14, %r14                                # verifica se é negativo
        jnz str_to_long_check_negative_digit
        
        # Positivo: último dígito deve ser <= 7
        cmpq $7, %rax
        jg str_to_long_overflow
        jmp str_to_long_multiply_and_add
        
    str_to_long_check_negative_digit:
        # Negativo: último dígito deve ser <= 8
        cmpq $8, %rax
        jg str_to_long_overflow
        
    str_to_long_multiply_and_add:
        # Multiplica o resultado anterior por 10 e adiciona ao novo dígito
        imulq $10, %r13                                 # r13 = r13 * 10
        addq %rax, %r13                                 # r13 = r13 + novo_dígito
        
        incq %r12                                       # próximo caractere
        jmp str_to_long_convert_loop
    
    str_to_long_done:
        # Aplica o sinal se necessário
        testq %r14, %r14                                # verifica se é negativo
        jz str_to_long_apply_result                     # se positivo, vai direto
        
        negq %r13                                       # aplica o sinal negativo
        
    str_to_long_apply_result:
        movq %r13, %rax                                 # retorna o resultado
        jmp str_to_long_exit
    
    str_to_long_null:
        # Retorna 0 se ponteiro for NULL
        movq $0, %rax
        jmp str_to_long_exit
        
    str_to_long_empty:
        # Retorna 0 se string for vazia
        movq $0, %rax
        jmp str_to_long_exit
        
    str_to_long_overflow:
        # Em caso de overflow, retorna o valor limite apropriado
        testq %r14, %r14                                # verifica sinal
        jz str_to_long_max_positive
        
        # Overflow negativo: retorna -9223372036854775808
        movq $-9223372036854775808, %rax
        jmp str_to_long_exit
        
    str_to_long_max_positive:
        # Overflow positivo: retorna 9223372036854775807
        movq $9223372036854775807, %rax
        jmp str_to_long_exit
    
    str_to_long_exit:
        # Restaura registradores preservados
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        ret

_str_to_float:
    # Entrada: %rdi = ponteiro para string
    # Saída: %xmm0 = valor float convertido, %rax = número de caracteres consumidos
    pushq %rbp
    movq %rsp, %rbp
    
    # Preserva os registradores que serão utilizados
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    
    # Verifica se o ponteiro é válido (não NULL)
    testq %rdi, %rdi
    jz str_to_float_null
    
    # Inicialização das variáveis
    movq %rdi, %r12                                     # ponteiro para a string (início)
    pushq %rdi                                          # salva ponteiro inicial na stack
    movq $0, %r13                                       # parte inteira acumulada
    movq $0, %r14                                       # flag de sinal (0=positivo, 1=negativo)
    movq $0, %r15                                       # contador de dígitos após o ponto decimal
    
    # Inicializa registradores XMM
    xorps %xmm0, %xmm0                                  # resultado final = 0.0
    xorps %xmm1, %xmm1                                  # parte fracionária = 0.0
    movss .LC_ten_float(%rip), %xmm2                    # constante 10.0
    movss .LC_one_float(%rip), %xmm3                    # divisor para parte fracionária = 1.0
    
    # Verifica se o primeiro caractere é um sinal
    movb (%r12), %al                                    # carrega o primeiro caractere
    testb %al, %al                                      # verifica se chegou no final da string
    jz str_to_float_empty
    
    cmpb $'-', %al                                      # verifica se o sinal é negativo
    je str_to_float_negative

    cmpb $'+', %al                                      # verifica se o sinal é positivo
    je str_to_float_positive
    
    # Se não há sinal, começa a conversão diretamente
    jmp str_to_float_convert_integer
    
    str_to_float_negative:
        movq $1, %r14                                   # marca como negativo
        incq %r12                                       # pula o sinal '-'
        jmp str_to_float_convert_integer
        
    str_to_float_positive:
        incq %r12                                       # pula o sinal '+'
        jmp str_to_float_convert_integer
    
    str_to_float_convert_integer:
        # Converte a parte inteira
        movb (%r12), %al                                # carrega o caractere atual
        testb %al, %al                                  # verifica se é o fim da string
        jz str_to_float_combine_parts                   # CORREÇÃO: vai para combine_parts, não done
        
        # Verifica se encontrou o ponto decimal
        cmpb $'.', %al
        je str_to_float_decimal_point
        
        # Verifica se é um dígito válido
        cmpb $'0', %al
        jb str_to_float_combine_parts                   # CORREÇÃO: vai para combine_parts, não done
        cmpb $'9', %al
        ja str_to_float_combine_parts                   # CORREÇÃO: vai para combine_parts, não done
        
        # Converte caractere para dígito numérico
        subb $'0', %al                                  # converte ASCII para número
        movzbq %al, %rax                                # zero-extend para 64 bits
        
        # Multiplica a parte inteira por 10 e adiciona o novo dígito
        imulq $10, %r13                                 # r13 = r13 * 10
        addq %rax, %r13                                 # r13 = r13 + novo_dígito
        
        # Overflow check removido
        
        incq %r12                                       # próximo caractere
        jmp str_to_float_convert_integer
    
    str_to_float_decimal_point:
        incq %r12                                       # pula o ponto decimal
        jmp str_to_float_convert_fractional
    
    str_to_float_convert_fractional:
        # Converte a parte fracionária
        movb (%r12), %al                                # carrega o caractere atual
        testb %al, %al                                  # verifica se é o fim da string
        jz str_to_float_combine_parts
        
        # Verifica se é um dígito válido
        cmpb $'0', %al
        jb str_to_float_combine_parts                   # se for menor que '0', para

        cmpb $'9', %al
        ja str_to_float_combine_parts                   # se for maior que '9', para
        
        # Limita a 6 dígitos de precisão para float, mas ainda avança o ponteiro
        cmpq $6, %r15
        jge str_to_float_skip_remaining_digits
        
        # Converte caractere para dígito numérico
        subb $'0', %al                                  # converte ASCII para número
        movzbq %al, %rax                                # zero-extend para 64 bits
        
        # Converte dígito para float e adiciona à parte fracionária
        cvtsi2ss %rax, %xmm4                            # converte dígito para float
        
        # Multiplica o divisor por 10 para a próxima casa decimal
        mulss %xmm2, %xmm3                              # xmm3 = xmm3 * 10.0
        
        # Divide o dígito pelo divisor e adiciona à parte fracionária
        divss %xmm3, %xmm4                              # xmm4 = dígito / divisor
        addss %xmm4, %xmm1                              # adiciona à parte fracionária
        
        incq %r15                                       # incrementa contador de dígitos fracionários
        
    str_to_float_advance_pointer:
        incq %r12                                       # próximo caractere
        jmp str_to_float_convert_fractional
        
    str_to_float_skip_remaining_digits:
        # Pula dígitos restantes sem processar (mantém precisão de 6 dígitos)
        incq %r12                                       # próximo caractere
        jmp str_to_float_convert_fractional
    
    str_to_float_combine_parts:
        # Combina parte inteira e fracionária
        cvtsi2ss %r13, %xmm0                            # converte parte inteira para float
        addss %xmm1, %xmm0                              # adiciona parte fracionária

        # Aplica o sinal se necessário
        testq %r14, %r14                                # verifica se é negativo
        jz str_to_float_done                            # se positivo, termina
        
        # Aplica sinal negativo
        movss .LC_neg_one_float(%rip), %xmm5            # carrega -1.0
        mulss %xmm5, %xmm0                              # xmm0 = xmm0 * (-1.0)
        
        jmp str_to_float_done
    
    str_to_float_null:
        # Retorna 0.0 se ponteiro for NULL
        xorps %xmm0, %xmm0
        jmp str_to_float_done
        
    str_to_float_empty:
        # Retorna 0.0 se string for vazia
        xorps %xmm0, %xmm0
        jmp str_to_float_done
        
    str_to_float_overflow:
        # Em caso de overflow, retorna valor limite apropriado
        testq %r14, %r14                                # verifica sinal
        jz str_to_float_max_positive
        
        # Overflow negativo: retorna um valor grande negativo
        movss .LC_neg_one_float(%rip), %xmm0
        movss .LC_ten_float(%rip), %xmm4
        mulss %xmm4, %xmm0                              # -10.0
        mulss %xmm4, %xmm0                              # -100.0
        mulss %xmm4, %xmm0                              # -1000.0
        mulss %xmm4, %xmm0                              # -10000.0
        mulss %xmm4, %xmm0                              # -100000.0
        mulss %xmm4, %xmm0                              # -1000000.0
        jmp str_to_float_done
        
    str_to_float_max_positive:
        # Overflow positivo: retorna um valor grande positivo
        movss .LC_one_float(%rip), %xmm0
        movss .LC_ten_float(%rip), %xmm4
        mulss %xmm4, %xmm0                              # 10.0
        mulss %xmm4, %xmm0                              # 100.0
        mulss %xmm4, %xmm0                              # 1000.0
        mulss %xmm4, %xmm0                              # 10000.0
        mulss %xmm4, %xmm0                              # 100000.0
        mulss %xmm4, %xmm0                              # 1000000.0
        jmp str_to_float_done
    
    str_to_float_done:
        # Calcula quantos caracteres foram consumidos
        movq %r12, %rax                                 # ponteiro atual
        popq %rdx                                       # recupera ponteiro inicial da stack
        subq %rdx, %rax                                 # rax = caracteres consumidos
        
        # Restaura registradores preservados
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        ret

_str_to_double:
    # Entrada: %rdi = ponteiro para string
    # Saída: %xmm0 = valor double convertido, %rax = número de caracteres consumidos
    pushq %rbp
    movq %rsp, %rbp
    
    # Preserva os registradores que serão utilizados
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    
    # Verifica se o ponteiro é válido (não NULL)
    testq %rdi, %rdi
    jz str_to_double_null
    
    # Inicialização das variáveis
    movq %rdi, %r12                                     # ponteiro para a string (início)
    pushq %rdi                                          # salva ponteiro inicial na stack
    movq $0, %r13                                       # parte inteira acumulada
    movq $0, %r14                                       # flag de sinal (0=positivo, 1=negativo)
    movq $0, %r15                                       # contador de dígitos após o ponto decimal
    
    # Inicializa registradores XMM para double
    xorpd %xmm0, %xmm0                                  # resultado final = 0.0
    xorpd %xmm1, %xmm1                                  # parte fracionária = 0.0
    movsd .LC_ten_double(%rip), %xmm2                   # constante 10.0
    movsd .LC_one_double(%rip), %xmm3                   # divisor para parte fracionária = 1.0
    
    # Verifica se o primeiro caractere é um sinal
    movb (%r12), %al                                    # carrega o primeiro caractere
    testb %al, %al                                      # verifica se chegou no final da string
    jz str_to_double_empty
    
    cmpb $'-', %al                                      # verifica se o sinal é negativo
    je str_to_double_negative

    cmpb $'+', %al                                      # verifica se o sinal é positivo
    je str_to_double_positive
    
    # Se não há sinal, começa a conversão diretamente
    jmp str_to_double_convert_integer
    
    str_to_double_negative:
        movq $1, %r14                                   # marca como negativo
        incq %r12                                       # pula o sinal '-'
        jmp str_to_double_convert_integer
        
    str_to_double_positive:
        incq %r12                                       # pula o sinal '+'
        jmp str_to_double_convert_integer
    
    str_to_double_convert_integer:
        # Converte a parte inteira
        movb (%r12), %al                                # carrega o caractere atual
        testb %al, %al                                  # verifica se é o fim da string
        jz str_to_double_combine_parts                  # CORREÇÃO: vai para combine_parts, não done
        
        # Verifica se encontrou o ponto decimal
        cmpb $'.', %al
        je str_to_double_decimal_point
        
        # Verifica se é um dígito válido
        cmpb $'0', %al
        jb str_to_double_combine_parts                  # CORREÇÃO: vai para combine_parts, não done
        cmpb $'9', %al
        ja str_to_double_combine_parts                  # CORREÇÃO: vai para combine_parts, não done
        
        # Converte caractere para dígito numérico
        subb $'0', %al                                  # converte ASCII para número
        movzbq %al, %rax                                # zero-extend para 64 bits
        
        # Multiplica a parte inteira por 10 e adiciona o novo dígito
        imulq $10, %r13                                 # r13 = r13 * 10
        addq %rax, %r13                                 # r13 = r13 + novo_dígito
        
        # Verifica overflow para a parte inteira (limita a 18 dígitos para double)
        movq $999999999999999999, %rdx                  # limite seguro para double (18 dígitos)
        cmpq %rdx, %r13                                 # verifica se excede limite seguro
        jg str_to_double_overflow
        
        incq %r12                                       # próximo caractere
        jmp str_to_double_convert_integer
    
    str_to_double_decimal_point:
        incq %r12                                       # pula o ponto decimal
        jmp str_to_double_convert_fractional
    
    str_to_double_convert_fractional:
        # Converte a parte fracionária
        movb (%r12), %al                                # carrega o caractere atual
        testb %al, %al                                  # verifica se é o fim da string
        jz str_to_double_combine_parts
        
        # Verifica se é um dígito válido
        cmpb $'0', %al
        jb str_to_double_combine_parts                  # se for menor que '0', para
        cmpb $'9', %al
        ja str_to_double_combine_parts                  # se for maior que '9', para
        
        # Limita a 15 dígitos de precisão para double, mas ainda avança o ponteiro
        cmpq $15, %r15
        jge str_to_double_skip_remaining_digits
        
        # Converte caractere para dígito numérico
        subb $'0', %al                                  # converte ASCII para número
        movzbq %al, %rax                                # zero-extend para 64 bits
        
        # Converte dígito para double e adiciona à parte fracionária
        cvtsi2sd %rax, %xmm4                            # converte dígito para double
        
        # Multiplica o divisor por 10 para a próxima casa decimal
        mulsd %xmm2, %xmm3                              # xmm3 = xmm3 * 10.0
        
        # Divide o dígito pelo divisor e adiciona à parte fracionária
        divsd %xmm3, %xmm4                              # xmm4 = dígito / divisor
        addsd %xmm4, %xmm1                              # adiciona à parte fracionária
        
        incq %r15                                       # incrementa o contador de dígitos fracionários
        
    str_to_double_advance_pointer:
        incq %r12                                       # próximo caractere
        jmp str_to_double_convert_fractional
        
    str_to_double_skip_remaining_digits:
        # Pula dígitos restantes sem processar (mantém precisão de 15 dígitos)
        incq %r12                                       # próximo caractere
        jmp str_to_double_convert_fractional
    
    str_to_double_combine_parts:
        # Combina parte inteira e fracionária
        cvtsi2sd %r13, %xmm0                            # converte parte inteira para double
        addsd %xmm1, %xmm0                              # adiciona parte fracionária
        
        # Aplica o sinal se necessário
        testq %r14, %r14                                # verifica se é negativo
        jz str_to_double_done                           # se positivo, termina
        
        # Aplica sinal negativo
        movsd .LC_neg_one_double(%rip), %xmm5           # carrega -1.0
        mulsd %xmm5, %xmm0                              # xmm0 = xmm0 * (-1.0)
        
        jmp str_to_double_done
    
    str_to_double_null:
        # Retorna 0.0 se ponteiro for NULL
        xorpd %xmm0, %xmm0
        jmp str_to_double_done
        
    str_to_double_empty:
        # Retorna 0.0 se string for vazia
        xorpd %xmm0, %xmm0
        jmp str_to_double_done
        
    str_to_double_overflow:
        # Em caso de overflow, retorna valor limite apropriado
        testq %r14, %r14                                # verifica sinal
        jz str_to_double_max_positive
        
        # Overflow negativo: retorna um valor grande negativo
        movsd .LC_neg_one_double(%rip), %xmm0
        movsd .LC_ten_double(%rip), %xmm4
        mulsd %xmm4, %xmm0                              # -10.0
        mulsd %xmm4, %xmm0                              # -100.0
        mulsd %xmm4, %xmm0                              # -1000.0
        mulsd %xmm4, %xmm0                              # -10000.0
        mulsd %xmm4, %xmm0                              # -100000.0
        mulsd %xmm4, %xmm0                              # -1000000.0
        mulsd %xmm4, %xmm0                              # -10000000.0
        mulsd %xmm4, %xmm0                              # -100000000.0
        mulsd %xmm4, %xmm0                              # -1000000000.0
        mulsd %xmm4, %xmm0                              # -10000000000.0
        mulsd %xmm4, %xmm0                              # -100000000000.0
        mulsd %xmm4, %xmm0                              # -1000000000000.0
        mulsd %xmm4, %xmm0                              # -10000000000000.0
        mulsd %xmm4, %xmm0                              # -100000000000000.0
        mulsd %xmm4, %xmm0                              # -1000000000000000.0
        jmp str_to_double_done
        
    str_to_double_max_positive:
        # Overflow positivo: retorna um valor grande positivo
        movsd .LC_one_double(%rip), %xmm0
        movsd .LC_ten_double(%rip), %xmm4
        mulsd %xmm4, %xmm0                              # 10.0
        mulsd %xmm4, %xmm0                              # 100.0
        mulsd %xmm4, %xmm0                              # 1000.0
        mulsd %xmm4, %xmm0                              # 10000.0
        mulsd %xmm4, %xmm0                              # 100000.0
        mulsd %xmm4, %xmm0                              # 1000000.0
        mulsd %xmm4, %xmm0                              # 10000000.0
        mulsd %xmm4, %xmm0                              # 100000000.0
        mulsd %xmm4, %xmm0                              # 1000000000.0
        mulsd %xmm4, %xmm0                              # 10000000000.0
        mulsd %xmm4, %xmm0                              # 100000000000.0
        mulsd %xmm4, %xmm0                              # 1000000000000.0
        mulsd %xmm4, %xmm0                              # 10000000000000.0
        mulsd %xmm4, %xmm0                              # 100000000000000.0
        mulsd %xmm4, %xmm0                              # 1000000000000000.0
        jmp str_to_double_done
    
    str_to_double_done:
        # Calcula quantos caracteres foram consumidos
        movq %r12, %rax                                 # ponteiro atual
        popq %rdx                                       # recupera ponteiro inicial da stack
        subq %rdx, %rax                                 # rax = caracteres consumidos
        
        # Restaura registradores preservados
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
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
        
        # Verificar overflow - se o valor for muito grande, usar valor máximo seguro
        movq $999999999, %rax                           # limite máximo seguro
        cmpq %rax, %r15                                 # compara com o limite
        jle float_int_ok                                # se <= limite, está ok
        movq %rax, %r15                                 # usa o limite máximo
    
    float_int_ok:
        movq $-999999999, %rax                          # limite mínimo seguro
        cmpq %rax, %r15                                 # compara com o limite
        jge float_int_valid                             # se >= limite, está ok
        movq %rax, %r15                                 # usa o limite mínimo
    
    float_int_valid:    
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
        jz float_str_done                               # termina se processou todos os dígitos
        
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
        
        # Verificar overflow - se o valor for muito grande, usar valor máximo seguro
        movq $999999999999999999, %rax                  # limite máximo seguro para double (18 dígitos)
        cmpq %rax, %r15                                 # compara com o limite
        jle double_int_ok                               # se <= limite, está ok
        movq %rax, %r15                                 # usa o limite máximo
        
        double_int_ok:
            movq $-999999999999999999, %rax                 # limite mínimo seguro para double (18 dígitos)
            cmpq %rax, %r15                                 # compara com o limite
            jge double_int_valid                            # se >= limite, está ok
            movq %rax, %r15                                 # usa o limite mínimo
        
        double_int_valid:
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
# FUNÇÕES AUXILIARES
# ######################################################################################################

# Função auxiliar para obter o próximo argumento de printf
_get_next_printf_arg:
    # Incrementa primeiro o índice de argumentos
    incl -56(%rbp)                                      # incrementa arg_index
    movl -56(%rbp), %eax                                # carrega o índice atual
    
    # Verifica se é um argumento inválido (0 ou negativo)
    testl %eax, %eax
    jle printf_arg_invalid
    
    # Argumentos 1-5: Salvos em posições fixas no stack frame local
    cmpl $5, %eax
    jle printf_get_register_arg
    
    # Argumentos 6+: Acessados da stack do caller
    jmp printf_get_stack_arg
    
    printf_get_register_arg:
        # Argumentos salvos em: arg1=-16(%rbp), arg2=-24(%rbp), arg3=-32(%rbp), arg4=-40(%rbp), arg5=-48(%rbp)
        # Fórmula: offset = -16 + (arg_index-1) * (-8) = -16 - 8*(eax-1) = -8 - 8*eax
        movl %eax, %ecx                                 # copia índice
        imull $8, %ecx                                  # multiplica por 8
        addl $8, %ecx                                   # ajusta para -8-8*eax
        negl %ecx                                       # torna negativo
        movslq %ecx, %rcx                               # extende para 64-bit
        movq (%rbp,%rcx), %rax                          # carrega: rbp + offset
        ret
    
    printf_get_stack_arg:
        # Argumentos na stack caller: arg6=16(%rbp), arg7=24(%rbp), arg8=32(%rbp), ...
        # Fórmula: offset = 16 + (arg_index-6) * 8 = 16 + 8*eax - 48 = 8*eax - 32
        movl %eax, %ecx                                 # copia índice  
        imull $8, %ecx                                  # multiplica por 8
        subl $32, %ecx                                  # subtrai 32 (8*eax - 32)
        movslq %ecx, %rcx                               # extende para 64-bit
        movq (%rbp,%rcx), %rax                          # carrega: rbp + offset
        ret
    
    printf_arg_invalid:
        # Retorna 0 para argumentos inválidos
        movq $0, %rax
        ret
    
# Função auxiliar para obter o próximo argumento de scanf
_get_next_scanf_arg:
    # Incrementa primeiro o índice de argumentos
    incl -56(%rbp)                                      # incrementa arg_index
    movl -56(%rbp), %eax                                # carrega o índice atual
    
    # Verifica se é um argumento inválido (0 ou negativo)
    testl %eax, %eax
    jle scanf_arg_invalid
    
    # Argumentos 1-5: Salvos em posições fixas no stack frame local
    cmpl $5, %eax
    jle scanf_get_register_arg
    
    # Argumentos 6+: Acessados da stack do caller
    jmp scanf_get_stack_arg
    
    scanf_get_register_arg:
        # Argumentos salvos em: arg1=-16(%rbp), arg2=-24(%rbp), arg3=-32(%rbp), arg4=-40(%rbp), arg5=-48(%rbp)
        # Fórmula: offset = -8 - 8*arg_index
        movl %eax, %ecx                                 # copia índice
        imull $8, %ecx                                  # multiplica por 8
        addl $8, %ecx                                   # ajusta para -8-8*eax
        negl %ecx                                       # torna negativo
        movslq %ecx, %rcx                               # extende para 64-bit
        movq (%rbp,%rcx), %rax                          # carrega: rbp + offset
        ret
    
    scanf_get_stack_arg:
        # Argumentos na stack caller: arg6=16(%rbp), arg7=24(%rbp), arg8=32(%rbp), ...
        # Fórmula: offset = 8*arg_index - 32
        movl %eax, %ecx                                 # copia índice  
        imull $8, %ecx                                  # multiplica por 8
        subl $32, %ecx                                  # subtrai 32 (8*eax - 32)
        movslq %ecx, %rcx                               # extende para 64-bit
        movq (%rbp,%rcx), %rax                          # carrega: rbp + offset
        ret
    
    scanf_arg_invalid:
        # Retorna NULL para argumentos inválidos
        movq $0, %rax
        ret

# Função auxiliar para pular espaços em branco no buffer de entrada
_skip_whitespace:
    pushq %rax
    
    skip_whitespace_loop:
        movb (%r13), %al                                # carrega caractere atual
        
        testb %al, %al                                  # verifica se é fim da string
        jz skip_whitespace_done
        
        cmpb $' ', %al                                  # verifica se é espaço
        je skip_whitespace_next
        
        cmpb $'\t', %al                                 # verifica se é tab
        je skip_whitespace_next
        
        cmpb $'\n', %al                                 # verifica se é newline
        je skip_whitespace_next
        
        cmpb $'\r', %al                                 # verifica se é carriage return
        je skip_whitespace_next
        
        jmp skip_whitespace_done                        # não é espaço em branco, para
    
    skip_whitespace_next:
        incq %r13                                       # avança para próximo caractere
        incq input_position(%rip)                       # atualiza posição global
        jmp skip_whitespace_loop

    skip_whitespace_done:
        popq %rax
        ret

# Função auxiliar para pular número no buffer de entrada 
_skip_number_in_buffer:
    pushq %rax
    skip_number_loop:
        movb (%r13), %al                                # carrega caractere atual
        
        testb %al, %al                                  # verifica se é fim da string
        jz skip_number_done
        
        cmpb $' ', %al                                  # verifica se é espaço
        je skip_number_done
        
        cmpb $'\t', %al                                 # verifica se é tab
        je skip_number_done
        
        cmpb $'\n', %al                                 # verifica se é newline
        je skip_number_done
        
        cmpb $'\r', %al                                 # verifica se é carriage return
        je skip_number_done
        
        incq %r13                                       # avança para próximo caractere
        incq input_position(%rip)                       # atualiza posição global
        
        jmp skip_number_loop
    
    skip_number_done:
        popq %rax
        ret

# Função auxiliar para parse do modo de fopen
_parse_fopen_mode:
    # Entrada: %rdi = string do modo
    # Saída: %rax = flags do sistema (-1 se inválido)
    pushq %rbp
    movq %rsp, %rbp
    
    # Verifica primeiro caractere
    movb (%rdi), %al
    
    cmpb $'r', %al
    je parse_mode_read
    cmpb $'w', %al
    je parse_mode_write
    cmpb $'a', %al
    je parse_mode_append
    
    # Modo inválido
    movq $-1, %rax
    jmp parse_mode_done
    
    parse_mode_read:
        # Verifica se é "r" ou "r+"
        movb 1(%rdi), %al
        testb %al, %al
        jz parse_mode_read_only     # apenas "r"
        
        cmpb $'+', %al
        je parse_mode_read_write    # "r+"
        
        # Caractere inválido após 'r'
        movq $-1, %rax
        jmp parse_mode_done
        
    parse_mode_read_only:
        movq $O_RDONLY, %rax
        jmp parse_mode_done
        
    parse_mode_read_write:
        movq $O_RDWR, %rax
        jmp parse_mode_done
        
    parse_mode_write:
        # Verifica se é "w" ou "w+"
        movb 1(%rdi), %al
        testb %al, %al
        jz parse_mode_write_only    # apenas "w"
        
        cmpb $'+', %al
        je parse_mode_write_read    # "w+"
        
        # Caractere inválido após 'w'
        movq $-1, %rax
        jmp parse_mode_done
        
    parse_mode_write_only:
        movq $O_WRONLY, %rax
        orq $O_CREAT, %rax
        orq $O_TRUNC, %rax
        jmp parse_mode_done
        
    parse_mode_write_read:
        movq $O_RDWR, %rax
        orq $O_CREAT, %rax
        orq $O_TRUNC, %rax
        jmp parse_mode_done
        
    parse_mode_append:
        # Verifica se é "a" ou "a+"
        movb 1(%rdi), %al
        testb %al, %al
        jz parse_mode_append_only   # apenas "a"
        
        cmpb $'+', %al
        je parse_mode_append_read   # "a+"
        
        # Caractere inválido após 'a'
        movq $-1, %rax
        jmp parse_mode_done
        
    parse_mode_append_only:
        movq $O_WRONLY, %rax
        orq $O_CREAT, %rax
        orq $O_APPEND, %rax
        jmp parse_mode_done
        
    parse_mode_append_read:
        movq $O_RDWR, %rax
        orq $O_CREAT, %rax
        orq $O_APPEND, %rax
        
    parse_mode_done:
        popq %rbp
        ret

# Função auxiliar para encontrar slot livre na tabela de arquivos
_find_free_file_slot:
    # Saída: %rax = ponteiro para FILE livre (ou 0 se não há slots)
    pushq %rbp
    movq %rsp, %rbp
    pushq %r12
    pushq %r13
    
    leaq file_table(%rip), %r12  # início da tabela
    movq $MAX_FILES, %r13        # contador
    
    find_slot_loop:
        testq %r13, %r13
        jz find_slot_none           # não há mais slots
        
        # Verifica se o slot está livre (fd == 0)
        movq (%r12), %rax           # carrega fd
        testq %rax, %rax
        jz find_slot_found          # slot livre encontrado
        
        # Próximo slot
        addq $FILE_STRUCT_SIZE, %r12
        decq %r13
        jmp find_slot_loop
        
    find_slot_found:
        movq %r12, %rax             # retorna ponteiro para o slot
        jmp find_slot_done
        
    find_slot_none:
        movq $0, %rax               # não há slots livres
        
    find_slot_done:
        popq %r13
        popq %r12
        popq %rbp
        ret

# ######################################################################################################
# FUNÇÃO DE TESTE PARA FOPEN/FCLOSE
# ######################################################################################################
_test_fopen_fclose:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r12  # para armazenar FILE*
    
    # Imprime cabeçalho dos testes
    leaq fopen_test_header(%rip), %rdi
    call _printf
    
    # Teste 1: Criar arquivo com modo "w"
    leaq fopen_test_creating(%rip), %rdi
    call _printf
    
    leaq fopen_test_filename(%rip), %rdi
    leaq fopen_mode_write(%rip), %rsi
    call _fopen
    movq %rax, %r12             # salva FILE*
    
    testq %rax, %rax
    jz test_fopen_error1
    
    # Sucesso na abertura
    leaq fopen_test_success(%rip), %rdi
    movq %r12, %rsi
    call _printf
    
    # Fechar o arquivo
    leaq fopen_test_closing(%rip), %rdi
    call _printf
    
    movq %r12, %rdi
    call _fclose
    
    testq %rax, %rax
    jnz test_fclose_error1
    
    # Sucesso no fechamento
    leaq fopen_test_close_success(%rip), %rdi
    call _printf
    jmp test_fopen_continue1
    
    test_fopen_error1:
        leaq fopen_test_error(%rip), %rdi
        call _printf
        jmp test_fopen_continue1
        
    test_fclose_error1:
        leaq fopen_test_close_error(%rip), %rdi
        call _printf
        
    test_fopen_continue1:
        # Teste 2: Tentar abrir arquivo para leitura
        leaq fopen_test_reading(%rip), %rdi
        call _printf
        
        leaq fopen_test_filename(%rip), %rdi
        leaq fopen_mode_read(%rip), %rsi
        call _fopen
        movq %rax, %r12
        
        testq %rax, %rax
        jz test_fopen_error2
        
        # Sucesso na abertura para leitura
        leaq fopen_test_success(%rip), %rdi
        movq %r12, %rsi
        call _printf
        
        # Fechar o arquivo
        leaq fopen_test_closing(%rip), %rdi
        call _printf
        
        movq %r12, %rdi
        call _fclose
        
        testq %rax, %rax
        jnz test_fclose_error2
        
        leaq fopen_test_close_success(%rip), %rdi
        call _printf
        jmp test_fopen_continue2
    
    test_fopen_error2:
        leaq fopen_test_error(%rip), %rdi
        call _printf
        jmp test_fopen_continue2
        
    test_fclose_error2:
        leaq fopen_test_close_error(%rip), %rdi
        call _printf
        
    test_fopen_continue2:
        # Teste 3: Abrir arquivo para anexar
        leaq fopen_test_appending(%rip), %rdi
        call _printf
        
        leaq fopen_test_filename(%rip), %rdi
        leaq fopen_mode_append(%rip), %rsi
        call _fopen
        movq %rax, %r12
        
        testq %rax, %rax
        jz test_fopen_error3
        
        # Sucesso na abertura para anexar
        leaq fopen_test_success(%rip), %rdi
        movq %r12, %rsi
        call _printf
        
        # Fechar o arquivo
        leaq fopen_test_closing(%rip), %rdi
        call _printf
        
        movq %r12, %rdi
        call _fclose
        
        testq %rax, %rax
        jnz test_fclose_error3
        
        leaq fopen_test_close_success(%rip), %rdi
        call _printf
        jmp test_fopen_done
    
    test_fopen_error3:
        leaq fopen_test_error(%rip), %rdi
        call _printf
        jmp test_fopen_done
        
    test_fclose_error3:
        leaq fopen_test_close_error(%rip), %rdi
        call _printf
        
    test_fopen_done:
        popq %r12
        popq %rbp
        ret

# ######################################################################################################
# FUNÇÃO DE TESTE PARA PRINTF (VALORES MÍNIMOS E MÁXIMOS - TODOS OS TIPOS SIGNED)
# ######################################################################################################
_test_printf_all_types:
    pushq %rbp
    movq %rsp, %rbp
    
    # Imprime cabeçalho dos testes de valores extremos
    leaq printf_test_header(%rip), %rdi
    call _printf
    
    # |---------------------------------------------|
    # |             VALORES MÁXIMOS                |
    # |---------------------------------------------|
    
    # Imprime cabeçalho dos valores máximos
    leaq max_header(%rip), %rdi
    call _printf
    
    # Teste MAX 1: Char MAX (127)
    leaq format_char_max(%rip), %rdi
    movb test_char_max(%rip), %sil                      # Carrega char máximo como segundo argumento
    movb test_char_max(%rip), %dl                       # Carrega valor numérico para mostrar (sign extended)
    movsbq %dl, %rdx                                    # Sign extend byte to quad word
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
    
    # |---------------------------------------------|
    # |             VALORES MÍNIMOS                |
    # |---------------------------------------------|
    
    # Imprime cabeçalho dos valores mínimos
    leaq min_header(%rip), %rdi
    call _printf
    
    # Teste MIN 1: Char MIN (-128)
    leaq format_char_min(%rip), %rdi
    movb test_char_min(%rip), %sil                      # Carrega char mínimo como segundo argumento
    movb test_char_min(%rip), %dl                       # Carrega valor numérico para mostrar (sign extended)
    movsbq %dl, %rdx                                    # Sign extend byte to quad word
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
    # |         TESTE ÚNICO COM UMA CHAMADA         |
    # |---------------------------------------------|
    
    # Imprime todos os valores mínimos e máximos em uma única chamada printf
    # Formato: char_min, short_min, int_min, long_min, float_min, double_min, char_max, short_max, int_max, long_max, float_max, double_max
    leaq format_all_min_max(%rip), %rdi                # String de formato
    
    # Argumentos para valores MÍNIMOS (posições %rsi, %rdx, %rcx, %r8, %r9, stack)
    movb test_char_min(%rip), %sil                      # Char MIN (-128) - sign extended
    movswq test_short_min(%rip), %rdx                   # Short MIN (-32768) 
    movslq test_int_min(%rip), %rcx                     # Int MIN (-2147483648)
    movq test_long_min(%rip), %r8                       # Long MIN (-9223372036854775808)
    movl test_float_min(%rip), %r9d                     # Float MIN (representação binária)
    
    # Double MIN e argumentos MÁXIMOS vão na stack
    pushq $0                                            # Padding para alinhamento de 16 bytes
    
    # Empurra argumentos MÁXIMOS na stack (ordem reversa)
    movq test_double_max(%rip), %rax                    # Double MAX
    pushq %rax
    
    movl test_float_max(%rip), %eax                     # Float MAX  
    pushq %rax
    
    movq test_long_max(%rip), %rax                      # Long MAX
    pushq %rax
    
    movslq test_int_max(%rip), %rax                     # Int MAX
    pushq %rax
    
    movswq test_short_max(%rip), %rax                   # Short MAX
    pushq %rax
    
    movb test_char_max(%rip), %al                        # Char MAX - sign extended 
    movsbq %al, %rax                                    # Sign extend to quad word
    pushq %rax
    
    # Empurra argumentos MÍNIMOS restantes na stack (ordem reversa)
    movq test_double_min(%rip), %rax                    # Double MIN
    pushq %rax
    
    # Carrega float e double nos registradores XMM para compatibilidade
    movss test_float_min(%rip), %xmm0                   # Float MIN em XMM0
    movsd test_double_min(%rip), %xmm1                  # Double MIN em XMM1
    movss test_float_max(%rip), %xmm2                   # Float MAX em XMM2
    movsd test_double_max(%rip), %xmm3                   # Double MAX em XMM3

    # Chama printf com todos os argumentos
    call _printf
    
    # Limpa a stack (8 pushes * 8 bytes = 64 bytes)
    addq $64, %rsp
    
    popq %rbp
    ret

# ######################################################################################################
# FUNÇÃO PRINCIPAL - MAIN
# ######################################################################################################

# Função principal para testar as implementações
_main:
    pushq %rbp
    movq %rsp, %rbp

    # |---------------------------------------------|
    # |             _FPRINTF / TESTE                |
    # |---------------------------------------------|
    /*
    pushq %r12  # para salvar FILE*
    
    # Imprimir cabeçalho
    leaq fprintf_test_header(%rip), %rdi
    call _printf
    
    # Abrir arquivo para escrita
    leaq fprintf_test_filename(%rip), %rdi  # "fprintf_test.txt"
    leaq fopen_mode_write(%rip), %rsi       # "w"
    call _fopen
    movq %rax, %r12                         # salva FILE* em %r12
    
    # Verificar se arquivo foi aberto
    testq %r12, %r12
    jz main_fprintf_error
    
    # Teste 1: Char (%c)
    movq %r12, %rdi                         # FILE*
    leaq format_test_char(%rip), %rsi       # "Char: %c\n"
    movq $'A', %rdx                         # char 'A'
    call _fprintf
    
    pushq %rax
    leaq fprintf_test_success(%rip), %rdi
    popq %rsi
    call _printf
    
    # FECHAR e REABRIR para próxima escrita
    movq %r12, %rdi
    call _fclose
    leaq fprintf_test_filename(%rip), %rdi
    leaq fopen_mode_append(%rip), %rsi
    call _fopen
    movq %rax, %r12
    
    # Teste 2: Short (%hd)
    movq %r12, %rdi                         # FILE*
    leaq format_test_short(%rip), %rsi      # "Short: %hd\n"
    movq $-32768, %rdx                      # short mínimo
    call _fprintf
    
    pushq %rax
    leaq fprintf_test_success(%rip), %rdi
    popq %rsi
    call _printf
    
    # FECHAR e REABRIR para próxima escrita
    movq %r12, %rdi
    call _fclose
    leaq fprintf_test_filename(%rip), %rdi
    leaq fopen_mode_append(%rip), %rsi
    call _fopen
    movq %rax, %r12
    
    # Teste 3: Int (%d)
    movq %r12, %rdi                         # FILE*
    leaq format_test_int(%rip), %rsi        # "Int: %d\n"
    movq $2147483647, %rdx                  # int máximo
    call _fprintf
    
    pushq %rax
    leaq fprintf_test_success(%rip), %rdi
    popq %rsi
    call _printf
    
    # FECHAR e REABRIR para próxima escrita
    movq %r12, %rdi
    call _fclose
    leaq fprintf_test_filename(%rip), %rdi
    leaq fopen_mode_append(%rip), %rsi
    call _fopen
    movq %rax, %r12
    
    # Teste 4: Long (%ld)
    movq %r12, %rdi                         # FILE*
    leaq format_test_long(%rip), %rsi       # "Long: %ld\n"
    movq $9223372036854775807, %rdx         # long máximo
    call _fprintf
    
    pushq %rax
    leaq fprintf_test_success(%rip), %rdi
    popq %rsi
    call _printf
    
    # FECHAR e REABRIR para próxima escrita
    movq %r12, %rdi
    call _fclose
    leaq fprintf_test_filename(%rip), %rdi
    leaq fopen_mode_append(%rip), %rsi
    call _fopen
    movq %rax, %r12
    
    # Teste 5: Float (%f)
    movq %r12, %rdi                         # FILE*
    leaq format_test_float(%rip), %rsi      # "Float: %f\n"
    # Carregar float como bits em %rdx
    movl test_float_max(%rip), %edx         # carrega float como 32 bits
    call _fprintf
    
    pushq %rax
    leaq fprintf_test_success(%rip), %rdi
    popq %rsi
    call _printf
    
    # FECHAR e REABRIR para próxima escrita
    movq %r12, %rdi
    call _fclose
    leaq fprintf_test_filename(%rip), %rdi
    leaq fopen_mode_append(%rip), %rsi
    call _fopen
    movq %rax, %r12
    
    # Teste 6: Double (%lf)
    movq %r12, %rdi                         # FILE*
    leaq format_test_double(%rip), %rsi     # "Double: %lf\n"
    # Carregar double como bits em %rdx
    movq test_double_max(%rip), %rdx        # carrega double como 64 bits
    call _fprintf
    
    pushq %rax
    leaq fprintf_test_success(%rip), %rdi
    popq %rsi
    call _printf
    
    # Fechar arquivo final
    movq %r12, %rdi
    call _fclose
    
    jmp main_continue
    
    main_fprintf_error:
        leaq fprintf_test_error(%rip), %rdi
        call _printf
    
    main_continue:
        # Terminar programa
        movq $SYS_EXIT, %rax
        movq $0, %rdi
        syscall
    *?
    
    # |---------------------------------------------|
    # |               _FOPEN - TESTE                |
    # |---------------------------------------------|
    # call _test_fopen_fclose
    
    # |---------------------------------------------|
    # |               _PRINTF - TESTE               |
    # |---------------------------------------------|
    # call _test_printf_all_types
    
    # |---------------------------------------------|
    # |               _SCANF - TESTE                |
    # |---------------------------------------------|

    # leaq scanf_test_header(%rip), %rdi
    # call _printf

    # Teste 1: lendo cada tipo um por vez (vários scanfs)

    # echo -e "a\n-32767\n2147483647\n-9223372036854775807\n-999999.999999\n-123456789.123456789" | ./lib_c
    # echo -e "Z\n32767\n2147483647\n9223372036854775807\n123456789.123456\n123456789012345.123456789" | ./lib_c

    
    # Teste para ler um char
    /*leaq scanf_char_prompt(%rip), %rdi
    call _printf
    leaq scanf_char_format(%rip), %rdi
    leaq char_input(%rip), %rsi
    call _scanf
    leaq scanf_char_result(%rip), %rdi
    movzbq char_input(%rip), %rsi
    movzbq char_input(%rip), %rdx
    call _printf

    # Teste para ler um short
    leaq scanf_short_prompt(%rip), %rdi
    call _printf
    leaq scanf_short_format(%rip), %rdi
    leaq short_input(%rip), %rsi
    call _scanf
    leaq scanf_short_result(%rip), %rdi
    movswq short_input(%rip), %rsi
    call _printf

    # Teste para ler um int
    leaq scanf_int_prompt(%rip), %rdi
    call _printf
    leaq scanf_int_format(%rip), %rdi
    leaq int_input(%rip), %rsi
    call _scanf
    leaq scanf_int_result(%rip), %rdi
    movslq int_input(%rip), %rsi
    call _printf

    # Teste para ler um long
    leaq scanf_long_prompt(%rip), %rdi
    call _printf
    leaq scanf_long_format(%rip), %rdi
    leaq long_input(%rip), %rsi
    call _scanf
    leaq scanf_long_result(%rip), %rdi
    movq long_input(%rip), %rsi
    call _printf

    # Teste para ler um float
    leaq scanf_float_prompt(%rip), %rdi
    call _printf
    leaq scanf_float_format(%rip), %rdi
    leaq float_input(%rip), %rsi
    call _scanf
    leaq scanf_float_result(%rip), %rdi
    movss float_input(%rip), %xmm0
    movl float_input(%rip), %esi
    call _printf

    # Teste para ler um double
    leaq scanf_double_prompt(%rip), %rdi
    call _printf
    leaq scanf_double_format(%rip), %rdi
    leaq double_input(%rip), %rsi
    call _scanf
    leaq scanf_double_result(%rip), %rdi
    movsd double_input(%rip), %xmm0
    movq double_input(%rip), %rsi
    call _printf
    */

    # Teste escalável: demonstração com 12 valores (mínimos e máximos para cada tipo)    
    
    # echo "B -32768 -2147483648 -9223372036854775808 -123456.123456 -123456789012345.123456789012345 Y 32767 2147483647 9223372036854775807 123456.123456 123456789012345.123456789012345" | ./lib_c

    # Prompt para entrada dos 12 valores
    /*leaq scanf_12_prompt(%rip), %rdi
    call _printf
    
    # Scanf com 12 valores: %c %hd %d %ld %f %lf %c %hd %d %ld %f %lf
    leaq scanf_12_format(%rip), %rdi         # Formato dos 12 valores
    leaq char_input4(%rip), %rsi             # 1. Char MIN (-128)
    leaq short_input3(%rip), %rdx            # 2. Short MIN (-32768)  
    leaq int_input3(%rip), %rcx              # 3. Int MIN (-2147483648)
    leaq long_input3(%rip), %r8              # 4. Long MIN (-9223372036854775808)
    leaq float_input3(%rip), %r9             # 5. Float MIN (-999999.999999)
    
    # 6º-12º argumentos vão na stack (seguindo a convenção System V ABI)
    pushq $0                                 # Padding para alinhamento se necessário
    leaq double_input4(%rip), %rax           # 12. Double MAX
    pushq %rax
    leaq float_input4(%rip), %rax            # 11. Float MAX  
    pushq %rax
    leaq long_input4(%rip), %rax             # 10. Long MAX
    pushq %rax
    leaq int_input4(%rip), %rax              # 9. Int MAX
    pushq %rax
    leaq short_input4(%rip), %rax            # 8. Short MAX
    pushq %rax
    leaq char_input5(%rip), %rax             # 7. Char MAX
    pushq %rax
    leaq double_input3(%rip), %rax           # 6. Double MIN
    pushq %rax
    
    call _scanf
    
    # Limpa a stack (7 pushes * 8 bytes = 56 bytes + padding)
    addq $64, %rsp
    
    # Mostrar resultados dos 12 valores lidos
    leaq scanf_12_result(%rip), %rdi         # String de formato dos resultados
    
    # Preparar argumentos para printf (os primeiros 5 em registradores)
    movzbl char_input4(%rip), %esi           # 1. Char MIN (caractere)
    movsbq char_input4(%rip), %rdx           # 2. Char MIN (valor numérico)
    movswq short_input3(%rip), %rcx          # 3. Short MIN
    movslq int_input3(%rip), %r8             # 4. Int MIN
    movq long_input3(%rip), %r9              # 5. Long MIN
    
    # Os próximos argumentos vão na stack para printf
    pushq $0                                 # Padding para alinhamento
    movq double_input4(%rip), %rax           # 12. Double MAX
    pushq %rax
    movl float_input4(%rip), %eax            # 11. Float MAX como inteiro
    pushq %rax
    movq long_input4(%rip), %rax             # 10. Long MAX
    pushq %rax
    movslq int_input4(%rip), %rax            # 9. Int MAX
    pushq %rax
    movswq short_input4(%rip), %rax          # 8. Short MAX
    pushq %rax
    movsbq char_input5(%rip), %rax           # 7. Char MAX - valor numérico
    pushq %rax
    movzbl char_input5(%rip), %eax           # 7. Char MAX - caractere
    pushq %rax
    movq double_input3(%rip), %rax           # 6. Double MIN
    pushq %rax
    movl float_input3(%rip), %eax            # 5. Float MIN como inteiro
    pushq %rax
    
    # Carrega valores float e double nos registradores XMM
    movss float_input3(%rip), %xmm0          # Float MIN
    movsd double_input3(%rip), %xmm1         # Double MIN
    movss float_input4(%rip), %xmm2          # Float MAX
    movsd double_input4(%rip), %xmm3         # Double MAX
    
    call _printf
    
    # Limpa a stack (9 pushes * 8 bytes = 72 bytes + padding)
    addq $80, %rsp
    */

    popq %rbp
    
    # Saída normal do programa usando return (não syscall direto)
    movq $0, %rax                                       # código de retorno 0
    ret                                                 # retorna para o sistema