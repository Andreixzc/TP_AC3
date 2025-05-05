# Implementação de Hierarquia de Memória Cache em VHDL

Este projeto contém a implementação de uma hierarquia de memória com um nível de cache em VHDL, incluindo duas configurações: mapeamento direto (direct-mapped) e mapeamento associativo de 4 vias (4-way set-associative).

## Estrutura do Projeto

O projeto é composto pelos seguintes arquivos:

- `cache_direct_mapped.vhd`: Implementação da cache com mapeamento direto
- `tb_cache_direct_mapped.vhd`: Testbench para a cache com mapeamento direto
- `cache_4way_associative.vhd`: Implementação da cache associativa de 4 vias
- `tb_cache_4way_associative.vhd`: Testbench para a cache associativa
- `run_simulations.bat`: Script para execução das simulações no Windows
- `run_simulations.sh`: Script para execução das simulações no Linux/Mac
- `Relatorio.pdf`: Relatório com descrição das implementações e análise dos resultados

## Requisitos

Para executar as simulações, você precisará ter instalado:

- **GHDL**: Um simulador de código aberto para VHDL
  - Windows: [Baixe aqui](https://github.com/ghdl/ghdl/releases)
  - Linux: `sudo apt-get install ghdl` (Ubuntu/Debian)
  - Mac: `brew install ghdl` (com Homebrew)

- **GTKWave**: Um visualizador de formas de onda para VCD/LXT/LXT2/VZT
  - Windows: [Baixe aqui](https://sourceforge.net/projects/gtkwave/files/)
  - Linux: `sudo apt-get install gtkwave` (Ubuntu/Debian)
  - Mac: `brew install gtkwave` (com Homebrew)

## Como Executar as Simulações

### No Windows

1. Abra um terminal (Prompt de Comando ou PowerShell)
2. Navegue até o diretório do projeto
3. Execute o script batch:
   ```
   run_simulations.bat
   ```
   Alternativamente, você pode simplesmente dar um duplo clique no arquivo `run_simulations.bat` no explorador de arquivos.

### No Linux/Mac

1. Abra um terminal
2. Navegue até o diretório do projeto
3. Torne o script shell executável (apenas na primeira vez):
   ```
   chmod +x run_simulations.sh
   ```
4. Execute o script:
   ```
   ./run_simulations.sh
   ```

## Como Visualizar os Resultados

### Arquivos de Saída

As simulações geram os seguintes arquivos:

- `direct_mapped_results.txt`: Resultados da simulação da cache com mapeamento direto
- `associative_results.txt`: Resultados da simulação da cache associativa
- `direct_mapped_test.vcd`: Arquivo de forma de onda da cache com mapeamento direto
- `associative_test.vcd`: Arquivo de forma de onda da cache associativa


## Descrição das Implementações

### Cache com Mapeamento Direto
- Tamanho: 256 linhas
- Divisão do endereço: Tag (22 bits), Índice (8 bits), Offset (2 bits)
- Política de escrita: Write-through

### Cache Associativa de 4 Vias
- Tamanho: 64 conjuntos × 4 vias = 256 linhas totais
- Divisão do endereço: Tag (24 bits), Índice (6 bits), Offset (2 bits)
- Política de escrita: Write-through
- Políticas de substituição implementadas:
  - LRU (Least Recently Used)
  - Random

Para mais detalhes sobre as implementações e análise dos resultados, consulte o arquivo `Relatorio.pdf`.