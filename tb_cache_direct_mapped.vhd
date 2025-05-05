library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_cache_direct_mapped is
end tb_cache_direct_mapped;

architecture Behavioral of tb_cache_direct_mapped is
    -- Constantes
    constant ADDR_WIDTH : integer := 32;
    constant CACHE_SIZE : integer := 256;
    constant WORD_WIDTH : integer := 32;
    constant CLK_PERIOD : time := 10 ns;
    
    -- Sinais para conectar ao cache
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '0';
    signal addr         : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal data_in      : std_logic_vector(WORD_WIDTH-1 downto 0) := (others => '0');
    signal rd_en        : std_logic := '0';
    signal wr_en        : std_logic := '0';
    signal data_out     : std_logic_vector(WORD_WIDTH-1 downto 0);
    signal hit          : std_logic;
    signal miss         : std_logic;
    
    -- Componente a ser testado
    component cache_direct_mapped is
        generic (
            ADDR_WIDTH  : integer := 32;
            CACHE_SIZE  : integer := 256;
            WORD_WIDTH  : integer := 32
        );
        port (
            clk         : in std_logic;
            reset       : in std_logic;
            addr        : in std_logic_vector(ADDR_WIDTH-1 downto 0);
            data_in     : in std_logic_vector(WORD_WIDTH-1 downto 0);
            rd_en       : in std_logic;
            wr_en       : in std_logic;
            data_out    : out std_logic_vector(WORD_WIDTH-1 downto 0);
            hit         : out std_logic;
            miss        : out std_logic
        );
    end component;
    
begin
    -- Instanciação do componente a ser testado
    UUT: cache_direct_mapped
        generic map (
            ADDR_WIDTH => ADDR_WIDTH,
            CACHE_SIZE => CACHE_SIZE,
            WORD_WIDTH => WORD_WIDTH
        )
        port map (
            clk => clk,
            reset => reset,
            addr => addr,
            data_in => data_in,
            rd_en => rd_en,
            wr_en => wr_en,
            data_out => data_out,
            hit => hit,
            miss => miss
        );
    
    -- Geração do clock
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    -- Processo de estímulo
    stim_proc: process
    begin
        -- Aplicando reset
        reset <= '1';
        wait for CLK_PERIOD * 2;
        reset <= '0';
        wait for CLK_PERIOD;
        
        -- Teste 1: Escrita em 10 endereços diferentes
        report "Teste 1: Escrita em 10 endereços diferentes";
        for i in 0 to 9 loop
            -- Preparar endereço e dados
            addr <= std_logic_vector(to_unsigned(i * 4, ADDR_WIDTH));
            data_in <= std_logic_vector(to_unsigned(100 + i, WORD_WIDTH));
            
            -- Ativar escrita por um ciclo
            wr_en <= '1';
            rd_en <= '0';
            wait for CLK_PERIOD;
            
            -- Verificar resultado (esperamos miss na primeira escrita)
            report "Endereço: " & integer'image(i * 4) & 
                   ", Hit: " & std_logic'image(hit) & 
                   ", Miss: " & std_logic'image(miss);
            
            -- Desativar escrita
            wr_en <= '0';
            wait for CLK_PERIOD;
        end loop;
        
        -- Pequena pausa
        wait for CLK_PERIOD;
        
        -- Teste 2: Leitura dos mesmos 10 endereços (deve dar hit)
        report "Teste 2: Leitura de 10 endereços (esperando hits)";
        for i in 0 to 9 loop
            -- Preparar endereço
            addr <= std_logic_vector(to_unsigned(i * 4, ADDR_WIDTH));
            
            -- Ativar leitura por um ciclo
            rd_en <= '1';
            wr_en <= '0';
            wait for CLK_PERIOD;
            
            -- Verificar resultado (esperamos hit com dados corretos)
            report "Endereço: " & integer'image(i * 4) & 
                   ", Dado: " & integer'image(to_integer(unsigned(data_out))) & 
                   ", Hit: " & std_logic'image(hit) & 
                   ", Miss: " & std_logic'image(miss);
                   
            -- Verificar se o dado lido é igual ao escrito anteriormente
            assert to_integer(unsigned(data_out)) = 100 + i
                report "ERRO: Dado lido diferente do escrito" severity note;
            
            -- Desativar leitura
            rd_en <= '0';
            wait for CLK_PERIOD;
        end loop;
        
        -- Pequena pausa
        wait for CLK_PERIOD;
        
        -- Teste 3: Leitura de endereços não acessados anteriormente (deve dar miss)
        report "Teste 3: Leitura de endereços não acessados (esperando misses)";
        for i in 10 to 14 loop
            -- Preparar endereço
            addr <= std_logic_vector(to_unsigned(i * 4, ADDR_WIDTH));
            
            -- Ativar leitura por um ciclo
            rd_en <= '1';
            wr_en <= '0';
            wait for CLK_PERIOD;
            
            -- Verificar resultado (esperamos miss)
            report "Endereço: " & integer'image(i * 4) & 
                   ", Hit: " & std_logic'image(hit) & 
                   ", Miss: " & std_logic'image(miss);
            
            -- Desativar leitura
            rd_en <= '0';
            wait for CLK_PERIOD;
        end loop;
        
        -- Pequena pausa
        wait for CLK_PERIOD;
        
        -- Teste 4: Conflito de cache (dois endereços mapeados para mesma linha)
        report "Teste 4: Conflito de cache (mapeamento para mesma linha)";
        
        -- Escrevendo em endereço que mapeia para mesma linha do primeiro endereço
        -- Endereço = 0 + 256*4 = 1024 (mesmo índice que o endereço 0, mas tag diferente)
        addr <= std_logic_vector(to_unsigned(1024, ADDR_WIDTH));
        data_in <= std_logic_vector(to_unsigned(999, WORD_WIDTH));
        wr_en <= '1';
        rd_en <= '0';
        wait for CLK_PERIOD;
        wr_en <= '0';
        wait for CLK_PERIOD;
        
        -- Agora tentando ler o primeiro endereço (deve dar miss por causa do conflito)
        addr <= std_logic_vector(to_unsigned(0, ADDR_WIDTH));
        rd_en <= '1';
        wait for CLK_PERIOD;
        
        report "Endereço: 0" & 
               ", Dado: " & integer'image(to_integer(unsigned(data_out))) & 
               ", Hit: " & std_logic'image(hit) & 
               ", Miss: " & std_logic'image(miss);
        
        rd_en <= '0';
        wait for CLK_PERIOD;
               
        -- Finalizando
        report "Teste concluído";
        wait;
    end process;
end Behavioral;