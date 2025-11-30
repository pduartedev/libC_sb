# libC_SB - Implementação de Funções Básicas da Biblioteca C em Assembly x86-64

[![Assembly](https://img.shields.io/badge/Assembly-x86--64-blue.svg)](https://en.wikipedia.org/wiki/X86-64)
[![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-Educational-green.svg)](LICENSE)

> **Implementação educacional de funções fundamentais da biblioteca C padrão em Assembly x86-64 para macOS**

Este projeto foi desenvolvido como parte da disciplina de **Software Básico** no IFNMG (2025) e demonstra a implementação de baixo nível de funções essenciais da biblioteca C, incluindo I/O formatado, conversões de tipos e manipulação de arquivos.

---

## 📋 Índice

- [Características](#-características)
- [Funções Implementadas](#-funções-implementadas)
- [Tipos Suportados](#-tipos-suportados)
- [Arquitetura e Syscalls](#-arquitetura-e-syscalls)
- [Instalação e Compilação](#-instalação-e-compilação)
- [Exemplos de Uso](#-exemplos-de-uso)
- [Estrutura do Código](#-estrutura-do-código)
- [Testes](#-testes)
- [Detalhes Técnicos](#-detalhes-técnicos)
- [Limitações Conhecidas](#-limitações-conhecidas)
- [Contribuindo](#-contribuindo)
- [Autor](#-autor)

---

## 🚀 Características

- ✅ **Printf completo** - Suporte para `%c`, `%hd`, `%d`, `%ld`, `%f`, `%lf`
- ✅ **Scanf completo** - Leitura formatada de todos os tipos primitivos
- ✅ **Fprintf/Fscanf** - I/O formatado para arquivos
- ✅ **Fopen/Fclose** - Manipulação de arquivos com múltiplos modos
- ✅ **Conversões bidirecionais** - String ↔ Tipos primitivos
- ✅ **Ponto flutuante IEEE 754** - Suporte completo via SSE/AVX
- ✅ **Valores extremos** - Suporte para min/max de cada tipo
- ✅ **Buffer otimizado** - Sistema de buffering para I/O eficiente

---

## 📦 Funções Implementadas

### Funções Principais

| Função | Descrição | Assinatura |
|--------|-----------|------------|
| `_myPrintf` | Impressão formatada para stdout | `int myPrintf(const char *format, ...)` |
| `_myScanf` | Leitura formatada de stdin | `int myScanf(const char *format, ...)` |
| `_myFopen` | Abre um arquivo | `FILE* myFopen(const char *filename, const char *mode)` |
| `_myFclose` | Fecha um arquivo | `int myFclose(FILE *stream)` |
| `_myFprintf` | Escrita formatada em arquivo | `int myFprintf(FILE *stream, const char *format, ...)` |
| `_myFscanf` | Leitura formatada de arquivo | `int myFscanf(FILE *stream, const char *format, ...)` |

### Funções de Conversão String → Tipo

| Função | Tipo de Destino | Tamanho |
|--------|-----------------|---------|
| `_str_to_char` | `char` | 1 byte |
| `_str_to_short` | `short` | 2 bytes |
| `_str_to_int` | `int` | 4 bytes |
| `_str_to_long` | `long` | 8 bytes |
| `_str_to_float` | `float` | 4 bytes (IEEE 754) |
| `_str_to_double` | `double` | 8 bytes (IEEE 754) |

### Funções de Conversão Tipo → String

| Função | Tipo de Origem | Retorno |
|--------|----------------|---------|
| `_char_to_str` | `char` | Número de caracteres escritos |
| `_short_to_str` | `short` | Número de caracteres escritos |
| `_int_to_str` | `int` | Número de caracteres escritos |
| `_long_to_str` | `long` | Número de caracteres escritos |
| `_float_to_str` | `float` | Número de caracteres escritos |
| `_double_to_str` | `double` | Número de caracteres escritos |

---

## 🔢 Tipos Suportados

| Tipo | Tamanho | Range (Signed) | Especificador Printf | Especificador Scanf |
|------|---------|----------------|---------------------|---------------------|
| `char` | 1 byte | -128 a 127 | `%c` | `%c` |
| `short` | 2 bytes | -32,768 a 32,767 | `%hd` | `%hd` |
| `int` | 4 bytes | -2,147,483,648 a 2,147,483,647 | `%d` | `%d` |
| `long` | 8 bytes | -9,223,372,036,854,775,808 a 9,223,372,036,854,775,807 | `%ld` | `%ld` |
| `float` | 4 bytes | ±3.4E+38 (6-7 dígitos decimais) | `%f` | `%f` |
| `double` | 8 bytes | ±1.7E+308 (15-16 dígitos decimais) | `%lf` | `%lf` |

---

## ⚙️ Arquitetura e Syscalls

### Syscalls do macOS

O código utiliza as syscalls específicas do macOS (formato BSD):

```assembly
. equ SYS_READ,   0x2000003      # Ler dados
.equ SYS_WRITE,  0x2000004      # Escrever dados
.equ SYS_OPEN,   0x2000005      # Abrir arquivo
.equ SYS_CLOSE,  0x2000006      # Fechar arquivo
.equ SYS_LSEEK,  0x20000C7      # Seek em arquivo
.equ SYS_FSYNC,  0x200005F      # Sincronizar arquivo
.equ SYS_EXIT,   0x2000001      # Terminar programa
```

### File Descriptors

```assembly
. equ STDIN_FD,  0               # Entrada padrão
.equ STDOUT_FD, 1               # Saída padrão
.equ STDERR_FD, 2               # Saída de erro
```

### Flags de Arquivo

```assembly
. equ O_RDONLY, 0x0000           # Somente leitura (r)
.equ O_WRONLY, 0x0001           # Somente escrita (w)
.equ O_RDWR,   0x0002           # Leitura e escrita (r+)
.equ O_CREAT,  0x0200           # Criar arquivo
.equ O_TRUNC,  0x0400           # Truncar arquivo (w)
.equ O_APPEND, 0x0008           # Anexar ao final (a)
```

---

## 🛠️ Instalação e Compilação

### Pré-requisitos

- **macOS** (testado em versões recentes)
- **Xcode Command Line Tools** ou **LLVM/Clang**
- Processador x86-64 com suporte a SSE2

### Compilação

```bash
# Compilar o arquivo assembly
as -arch x86_64 libC_SB.s -o libC_SB.o

# Linkar (se houver um arquivo principal)
ld -macosx_version_min 10.14 -L/Library/Developer/CommandLineTools/SDKs/MacOSX. sdk/usr/lib \
   -lSystem libC_SB.o -o libC_SB

# Executar
./libC_SB
```

### Compilação com GCC/Clang (se integrado com C)

```bash
# Compilar assembly
as -arch x86_64 libC_SB.s -o libC_SB. o

# Compilar código C (se houver)
clang -c main.c -o main.o

# Linkar tudo
clang main.o libC_SB. o -o programa

# Executar
./programa
```

---

## 💡 Exemplos de Uso

### Exemplo 1: Printf Básico

```assembly
.data
    msg: .string "Inteiro: %d, Float: %f, Char: %c\n"
    valor_int: .long 42
    valor_float: .float 3.14159
    valor_char: .byte 'A'

.text
    . globl _main
_main:
    # Preparar argumentos
    leaq msg(%rip), %rdi           # formato
    movl valor_int(%rip), %esi     # arg1 (int)
    movss valor_float(%rip), %xmm0 # arg2 (float)
    movzbl valor_char(%rip), %edx  # arg3 (char)
    
    call _myPrintf
    
    # Sair
    movq $0x2000001, %rax
    xorq %rdi, %rdi
    syscall
```

**Saída esperada:**
```
Inteiro: 42, Float: 3.141590, Char: A
```

### Exemplo 2: Scanf de Múltiplos Tipos

```assembly
.data
    prompt: .string "Digite int, float, char: "
    formato: .string "%d %f %c"
    resultado: .string "Lidos: int=%d, float=%f, char=%c\n"
    
.bss
    . lcomm valor_int, 4
    .lcomm valor_float, 4
    .lcomm valor_char, 1

.text
    # Exibir prompt
    leaq prompt(%rip), %rdi
    call _myPrintf
    
    # Ler valores
    leaq formato(%rip), %rdi
    leaq valor_int(%rip), %rsi
    leaq valor_float(%rip), %rdx
    leaq valor_char(%rip), %rcx
    call _myScanf
    
    # Exibir resultados
    leaq resultado(%rip), %rdi
    movl valor_int(%rip), %esi
    movss valor_float(%rip), %xmm0
    movzbl valor_char(%rip), %edx
    call _myPrintf
```

### Exemplo 3: Manipulação de Arquivos

```assembly
.data
    filename: . string "dados.txt"
    mode_write: .string "w"
    mode_read: .string "r"
    formato_escrita: .string "Numero: %d\nFloat: %f\n"
    formato_leitura: .string "%d %f"
    
. bss
    . lcomm file_ptr, 8
    .lcomm num_lido, 4
    .lcomm float_lido, 4

.text
    # Abrir arquivo para escrita
    leaq filename(%rip), %rdi
    leaq mode_write(%rip), %rsi
    call _myFopen
    movq %rax, file_ptr(%rip)
    
    # Escrever dados
    movq file_ptr(%rip), %rdi
    leaq formato_escrita(%rip), %rsi
    movl $12345, %edx
    movss . LC_pi(%rip), %xmm0
    call _myFprintf
    
    # Fechar arquivo
    movq file_ptr(%rip), %rdi
    call _myFclose
    
    # Reabrir para leitura
    leaq filename(%rip), %rdi
    leaq mode_read(%rip), %rsi
    call _myFopen
    movq %rax, file_ptr(%rip)
    
    # Ler dados
    movq file_ptr(%rip), %rdi
    leaq formato_leitura(%rip), %rsi
    leaq num_lido(%rip), %rdx
    leaq float_lido(%rip), %rcx
    call _myFscanf
    
    # Fechar arquivo
    movq file_ptr(%rip), %rdi
    call _myFclose

.data
    .LC_pi: . float 3.14159265
```

---

## 📁 Estrutura do Código

### Seções

```
┌─────────────────────────────────────────┐
│          . bss (Dados não inicializados) │
├─────────────────────────────────────────┤
│ • Constantes do sistema (STDIN, SYS_*)  │
│ • Buffers (input, output, conversion)   │
│ • Tabela de arquivos                    │
│ • Variáveis globais de controle         │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│          .data (Dados inicializados)    │
├─────────────────────────────────────────┤
│ • Constantes de ponto flutuante (SSE)   │
│ • Strings de teste                      │
│ • Formatos de teste                     │
│ • Valores de teste (min/max)            │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│          .text (Código executável)      │
├─────────────────────────────────────────┤
│ • Funções principais (printf, scanf)    │
│ • Funções de arquivo (fopen, fprintf)   │
│ • Funções de conversão (str_to_*, etc)  │
│ • Funções auxiliares                    │
│ • Funções de teste                      │
└─────────────────────────────────────────┘
```

### Buffers

| Buffer | Tamanho | Propósito |
|--------|---------|-----------|
| `input_buffer` | 1024 bytes | Armazena entrada do usuário |
| `output_buffer` | 1024 bytes | Armazena saída antes de escrever |
| `conversion_buffer` | 64 bytes | Conversões temporárias |
| `temp_buffer` | 256 bytes | Operações auxiliares |
| `file_table` | 1024 bytes | Tabela de FILE* (até 16 arquivos) |

---

## 🧪 Testes

O código inclui funções de teste abrangentes:

### Testes de Printf

```assembly
_test_printf_all_types:
    # Testa valores mínimos e máximos de todos os tipos
    # Saída formatada com cabeçalhos
```

**Cobertura:**
- ✅ Char: ASCII printável e valores extremos
- ✅ Short: -32768 a 32767
- ✅ Int: -2147483648 a 2147483647
- ✅ Long: valores de 64 bits
- ✅ Float: ±999999.999999 (6 casas decimais)
- ✅ Double: ±123456789.123456789 (15 casas decimais)

### Testes de Scanf

```assembly
_test_scanf_all_types:
    # 12 testes individuais (6 min + 6 max)
    # Teste consolidado com 12 valores
```

**Cenários testados:**
- ✅ Leitura de valores extremos
- ✅ Múltiplos valores em uma única chamada
- ✅ Validação de parsing de números negativos
- ✅ Números em notação científica (float/double)

### Testes de Arquivo

```assembly
_test_fopen_fclose:
    # Testa abertura, escrita e fechamento
```

**Modos testados:**
- ✅ `"r"` - Leitura
- ✅ `"w"` - Escrita (trunca)
- ✅ `"a"` - Anexar
- ✅ `"r+"` - Leitura/escrita
- ✅ `"w+"` - Escrita/leitura (trunca)
- ✅ `"a+"` - Anexar/leitura

---

## 🔧 Detalhes Técnicos

### Convenção de Chamada (System V AMD64 ABI)

**Argumentos inteiros/ponteiros:**
1. `%rdi`
2. `%rsi`
3. `%rdx`
4. `%rcx`
5. `%r8`
6. `%r9`
7. Stack (16(%rbp), 24(%rbp), ...)

**Argumentos de ponto flutuante:**
1.  `%xmm0`
2. `%xmm1`
3. `%xmm2`
4. `%xmm3`
5.  `%xmm4`
6. `%xmm5`
7. `%xmm6`
8. `%xmm7`

**Retorno:**
- Inteiro/ponteiro: `%rax`
- Float/double: `%xmm0`

### Algoritmos de Conversão

#### String → Float/Double

1. **Parsing de sinal**: Detecta `-` ou `+`
2. **Parte inteira**: Acumula dígitos antes do `. `
3. **Parte fracionária**: Acumula dígitos após o `.` com divisor crescente
4. **Aplicação de sinal**: Multiplica por -1 se necessário

```assembly
# Pseudocódigo simplificado
result = 0. 0
divisor = 1.0

# Parte inteira
while (isdigit(*str)):
    result = result * 10. 0 + (*str - '0')
    str++

# Parte decimal
if (*str == '.'):
    str++
    while (isdigit(*str)):
        divisor *= 10.0
        result += (*str - '0') / divisor
        str++

if (negative):
    result = -result
```

#### Float/Double → String

1. **Extração do sinal**: Usa máscara de bits para isolar bit de sinal
2. **Separação inteira/decimal**: `int_part = (int)value`
3. **Multiplicação da parte decimal**: `frac_part = (value - int_part) * 10^precision`
4. **Conversão digit-by-digit**: Usa divisão e módulo

### Estrutura FILE Simplificada

```assembly
FILE:
    .quad fd           # File descriptor (0-15)
    .quad mode         # Modo de abertura (bitfield)
    .quad buffer       # Ponteiro para buffer interno
    .quad buffer_pos   # Posição atual no buffer
    # Total: 32 bytes por FILE
```

---

## ⚠️ Limitações Conhecidas

### Funcionalidades Não Implementadas

- ❌ Especificadores de largura/precisão (`%10d`, `%. 2f`)
- ❌ Flags de alinhamento (`%-10s`)
- ❌ Notação científica explícita (`%e`, `%E`)
- ❌ Hexadecimal (`%x`, `%X`)
- ❌ Strings (`%s`) - parcialmente implementado
- ❌ Ponteiros (`%p`)

### Limitações Técnicas

- **Precisão de float**: 6 casas decimais (vs.  7-8 do padrão C)
- **Precisão de double**: 15 casas decimais (vs. 15-17 do padrão C)
- **Tamanho do buffer**: 1024 bytes (pode truncar entradas grandes)
- **Máximo de arquivos abertos**: 16 simultâneos
- **Sem validação de overflow**: Pode ocorrer em conversões extremas

### Questões Conhecidas

1. **`_skip_number_in_buffer`**: Implementação básica, pode não funcionar com notação científica
2. **Float literals em `fprintf`**: Workaround usando `%s` para strings literais
3. **Alinhamento de stack**: Pode causar crashes em algumas versões do macOS sem ajustes

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Este é um projeto educacional, e melhorias são encorajadas.

### Como Contribuir

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'Adiciona MinhaFeature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5.  Abra um Pull Request

### Áreas para Melhoria

- [ ] Implementar especificadores de largura/precisão
- [ ] Adicionar suporte para `%s` (strings) completo
- [ ] Melhorar precisão de conversões de ponto flutuante
- [ ] Implementar `%x` (hexadecimal)
- [ ] Adicionar tratamento de erros mais robusto
- [ ] Otimizar funções de conversão para performance
- [ ] Adicionar suporte para notação científica (`%e`)
- [ ] Implementar `%p` para ponteiros
- [ ] Criar suite de testes automatizados
- [ ] Documentar algoritmos internos

---

## 👨‍💻 Autor

**Patrick Duarte Pimenta**  
Disciplina: Software Básico - IFNMG (2025)

---

## 📄 Licença

Este projeto foi desenvolvido para fins educacionais como parte da disciplina de Software Básico.

---

## 📚 Referências

- [System V AMD64 ABI](https://gitlab.com/x86-psABIs/x86-64-ABI)
- [Intel 64 and IA-32 Architectures Software Developer's Manuals](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)
- [macOS System Calls](https://opensource.apple.com/source/xnu/)
- [IEEE 754 Floating Point Standard](https://ieeexplore.ieee.org/document/8766229)
- [Assembly Language Step-by-Step - Jeff Duntemann](https://www.wiley.com/en-us/Assembly+Language+Step+by+Step%3A+Programming+with+Linux%2C+3rd+Edition-p-9780470497029)

---

## 🔗 Links Úteis

- [GNU Assembler (GAS) Documentation](https://sourceware.org/binutils/docs/as/)
- [NASM Documentation](https://www.nasm. us/xdoc/2.15.05/html/nasmdoc0.html)
- [x86-64 Instruction Reference](https://www.felixcloutier. com/x86/)
- [Godbolt Compiler Explorer](https://godbolt.org/) - Para comparar com código C

---

<div align="center">

**[⬆ Voltar ao topo](#libc_sb---implementação-de-funções-básicas-da-biblioteca-c-em-assembly-x86-64)**

---

*Desenvolvido com ⚙️ em Assembly puro*

</div>
