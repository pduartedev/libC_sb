# libC_sb

Biblioteca mínima em Assembly (libC_sb)
--------------------------------------

libC_sb é uma coleção de rotinas escritas em Assembly projetadas para atuar como uma biblioteca de baixo nível (estilo "libC") que pode ser ligada a projetos em C ou usada nativamente. O repositório contém fontes em Assembly e exemplos de uso/compilação.

Observação: este README é sugestivo — atualize os detalhes (arquitetura alvo, montador, flags de build) conforme o seu projeto.

Principais funcionalidades
- Rotinas utilitárias base em Assembly (por exemplo: manipulação de strings, I/O simples, conversões numéricas)  
- Projeto pensado para ser linkável com programas em C
- Estrutura pensada para gerar uma biblioteca estática (libC_sb.a) ou objetos separados

Composição do repositório
- src/        — arquivos-fonte em Assembly (.s, .asm)
- include/    — headers C (se aplicável) para expor as rotinas
- examples/   — exemplos em C que demonstram o uso da biblioteca
- lib/        — artefatos de build (biblioteca estática)
- build/      — objetos intermediários

Requisitos
- Montador/assembler (ex.: nasm, gas) conforme a sintaxe utilizada nos fontes
- gcc/clang (para linkagem e testes com C)
- ar (para criar biblioteca estática)
- make (opcional, recomendado)

Exemplos de build (ajuste para sua arquitetura)
- Montando com nasm (x86_64 ELF) e criando lib estática:
  ```bash
  mkdir -p build lib
  nasm -f elf64 -o build/foo.o src/foo.asm
  nasm -f elf64 -o build/bar.o src/bar.asm
  ar rcs lib/libC_sb.a build/*.o
  ```
- Montando arquivos .s com gcc (AT&T/GAS) e criando lib:
  ```bash
  mkdir -p build lib
  gcc -c -o build/foo.o src/foo.s
  gcc -c -o build/bar.o src/bar.s
  ar rcs lib/libC_sb.a build/*.o
  ```
- Linkando com um programa C:
  ```bash
  gcc examples/main.c -Llib -lC_sb -o examples/main
  ./examples/main
  ```

Dicas de portabilidade
- Atualize a sintaxe de assembly (AT&T vs Intel) e flags do montador de acordo com seu alvo.
- Se for usar em sistemas embarcados, adapte o fluxo de link e os scripts de link (linker script) conforme necessário.

Estrutura de um Makefile simples
```makefile
ASM=nasm
ASMFLAGS=-f elf64
SRC=$(wildcard src/*.asm)
OBJ=$(patsubst src/%.asm,build/%.o,$(SRC))

all: lib/libC_sb.a

build/%.o: src/%.asm
	mkdir -p build
	$(ASM) $(ASMFLAGS) -o $@ $<

lib/libC_sb.a: $(OBJ)
	mkdir -p lib
	ar rcs $@ $^

clean:
	rm -rf build lib examples/*.o examples/main
```

Como contribuir
- Fork do repositório
- Crie uma branch com uma descrição curta (ex: feature/add-itoa)
- Adicione testes/exemplos que demonstrem a mudança
- Abra um pull request com descrição clara e etapas para reproduzir

Boas práticas para commits
- Commits pequenos e atômicos
- Mensagens no estilo: tipo: breve-descrição (ex.: feat: add optimized strlen)
- Inclua casos de teste quando possível

Licença
- Por enquanto: escolha uma licença (ex.: MIT). Substitua por aquela que preferir.

Contato
- Autor: pduartedev
- Abra issues no repositório para bugs, sugestões ou dúvidas.

Notas finais
- Linguagem predominante deste repositório: Assembly (100%).  
- Atualize este README com instruções específicas da arquitetura alvo e exemplos reais presentes em src/ e examples/.
