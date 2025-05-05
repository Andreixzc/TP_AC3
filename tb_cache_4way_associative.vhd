library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_cache_4way_associative is
end tb_cache_4way_associative;

architecture Behavioral of tb_cache_4way_associative is
    -- Constantes
    constant ADDR_WIDTH : integer := 32;
    constant CACHE_SIZE : integer := 256;
    constant WORD_WIDTH : integer := 32;
    constant WAYS       : integer := 4;
    constant CLK_PERIOD : time := 10 ns;
    
    -- Sinais para conectar ao cache
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '0';
    signal addr         : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal data_in      : std_logic_vector(WORD_WIDTH-1 downto 0) := (others => '0');
    signal rd_en        : std_logic := '0';
    signal wr_en        : std_logic := '0';
    signal repl_policy  : std_logic := '0';  -- '0' para LRU, '1' para Random
    signal data_out     : std_logic_vector(WORD_WIDTH-1 downto 0);
    signal hit          : std_logic;
    signal miss         : std_logic;
    
    -- Componente a ser testado
    component cache_4way_associative is
        generic (
            ADDR_WIDTH  : integer := 32;
            CACHE_SIZE  : integer := 256;
            WORD_WIDTH  : integer := 32;
            WAYS        : integer := 4
        );
        port (
            clk         : in std_logic;
            reset       : in std_logic;
            addr        : in std_logic_vector(ADDR_WIDTH-1 downto 0);
            data_in     : in std_logic_vector(WORD_WIDTH-1 downto 0);
            rd_en       : in std_logic;
            wr_en       : in std_logic;
            repl_policy : in std_logic;
            data_out    : out std_logic_vector(WORD_WIDTH-1 downto 0);
            hit         : out std_logic;
            miss        : out std_logic
        );
    end component;
    
    -- Constantes específicas para o teste
    constant SETS : integer := CACHE_SIZE / WAYS;  -- 64 conjuntos
    
begin
    -- Instanciação do componente a ser testado
    UUT: cache_4way_associative
        generic map (
            ADDR_WIDTH => ADDR_WIDTH,
            CACHE_SIZE => CACHE_SIZE,
            WORD_WIDTH => WORD_WIDTH,
            WAYS => WAYS
        )
        port map (
            clk => clk,
            reset => reset,
            addr => addr,
            data_in => data_in,
            rd_en => rd_en,
            wr_en => wr_en,
            repl_policy => repl_policy,
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
        
        -- TESTE 1: LRU Policy - Escrita em endereços diferentes mapeados para o mesmo conjunto
        report "Teste 1: LRU Policy - Escrita em endereços com mesmo índice";
        repl_policy <= '0';  -- LRU
        
        -- Escrever em 5 endereços que mapeiam para o mesmo conjunto (mais que as 4 vias)
        -- Exemplo: Conjunto 0 (bits de índice = 000000)
        -- Endereços: 0, 256, 512, 768, 1024 (todos com o mesmo índice)
        for i in 0 to 4 loop
            -- Preparar endereço: i * 2^(INDEX_BITS + OFFSET_BITS) = i * 2^8 = i * 256
            addr <= std_logic_vector(to_unsigned(i * 256, ADDR_WIDTH));
            data_in <= std_logic_vector(to_unsigned(100 + i, WORD_WIDTH));
            
            -- Ativar escrita
            wr_en <= '1';
            rd_en <= '0';
            wait for CLK_PERIOD;
            
            -- Verificar resultado
            report "Endereço: " & integer'image(i * 256) & 
                   ", Hit: " & std_logic'image(hit) & 
                   ", Miss: " & std_logic'image(miss);
            
            -- Desativar escrita
            wr_en <= '0';
            wait for CLK_PERIOD;
        end loop;
        
        -- Pequena pausa
        wait for CLK_PERIOD;
        
        -- Verificar qual foi substituído (o primeiro endereço deve ter sido substituído pelo LRU)
        -- Leitura do primeiro endereço (0) - deve ser um miss
        addr <= std_logic_vector(to_unsigned(0, ADDR_WIDTH));
        rd_en <= '1';
        wr_en <= '0';
        wait for CLK_PERIOD;
        
        report "LRU Test - Endereço: 0" & 
               ", Hit: " & std_logic'image(hit) & 
               ", Miss: " & std_logic'image(miss);
        
        rd_en <= '0';
        wait for CLK_PERIOD;
        
        -- Leitura dos outros endereços (256, 512, 768, 1024) - devem ser hits
        for i in 1 to 4 loop
            addr <= std_logic_vector(to_unsigned(i * 256, ADDR_WIDTH));
            rd_en <= '1';
            wait for CLK_PERIOD;
            
            report "LRU Test - Endereço: " & integer'image(i * 256) & 
                   ", Dado: " & integer'image(to_integer(unsigned(data_out))) & 
                   ", Hit: " & std_logic'image(hit) & 
                   ", Miss: " & std_logic'image(miss);
            
            -- Verificar se é hit para os últimos 4 endereços
            assert hit = '1'
                report "ERRO: Deveria ser hit para endereço " & integer'image(i * 256) severity note;
            
            rd_en <= '0';
            wait for CLK_PERIOD;
        end loop;
        
        -- TESTE 2: Random Policy - Escrita em endereços diferentes mapeados para o mesmo conjunto
        report "Teste 2: Random Policy - Escrita em endereços com mesmo índice";
        
        -- Reset para limpar a cache
        reset <= '1';
        wait for CLK_PERIOD * 2;
        reset <= '0';
        wait for CLK_PERIOD;
        
        repl_policy <= '1';  -- Random
        
        -- Escrever em 5 endereços que mapeiam para o mesmo conjunto
        for i in 0 to 4 loop
            addr <= std_logic_vector(to_unsigned(i * 256, ADDR_WIDTH));
            data_in <= std_logic_vector(to_unsigned(200 + i, WORD_WIDTH));
            
            wr_en <= '1';
            rd_en <= '0';
            wait for CLK_PERIOD;
            
            report "Endereço: " & integer'image(i * 256) & 
                   ", Hit: " & std_logic'image(hit) & 
                   ", Miss: " & std_logic'image(miss);
            
            wr_en <= '0';
            wait for CLK_PERIOD;
        end loop;
        
        -- Pequena pausa
        wait for CLK_PERIOD;
        
        -- Verificar os endereços para ver quais foram substituídos (um deve ter sido substituído aleatoriamente)
        for i in 0 to 4 loop
            addr <= std_logic_vector(to_unsigned(i * 256, ADDR_WIDTH));
            rd_en <= '1';
            wait for CLK_PERIOD;
            
            report "Random Test - Endereço: " & integer'image(i * 256) & 
                   ", Hit: " & std_logic'image(hit) & 
                   ", Miss: " & std_logic'image(miss);
            
            rd_en <= '0';
            wait for CLK_PERIOD;
        end loop;
        
        -- TESTE 3: Teste de localidade temporal (LRU) - acessar repetidamente o mesmo endereço
        report "Teste 3: Teste de localidade temporal (LRU)";
        
        -- Reset para limpar a cache
        reset <= '1';
        wait for CLK_PERIOD * 2;
        reset <= '0';
        wait for CLK_PERIOD;
        
        repl_policy <= '0';  -- LRU
        
        -- Escrever em 4 endereços que mapeiam para o mesmo conjunto
        for i in 0 to 3 loop
            addr <= std_logic_vector(to_unsigned(i * 256, ADDR_WIDTH));
            data_in <= std_logic_vector(to_unsigned(300 + i, WORD_WIDTH));
            
            wr_en <= '1';
            rd_en <= '0';
            wait for CLK_PERIOD;
            
            wr_en <= '0';
            wait for CLK_PERIOD;
        end loop;
        
        -- Pequena pausa
        wait for CLK_PERIOD;
        
        -- Acessar repetidamente o primeiro endereço para torná-lo MRU
        for i in 0 to 3 loop
            addr <= std_logic_vector(to_unsigned(0, ADDR_WIDTH));
            rd_en <= '1';
            wait for CLK_PERIOD;
            
            rd_en <= '0';
            wait for CLK_PERIOD;
        end loop;
        
        -- Pequena pausa
        wait for CLK_PERIOD;
        
        -- Acessar um novo endereço que mapeie para o mesmo conjunto
        addr <= std_logic_vector(to_unsigned(4 * 256, ADDR_WIDTH));
        data_in <= std_logic_vector(to_unsigned(304, WORD_WIDTH));
        wr_en <= '1';
        wait for CLK_PERIOD;
        wr_en <= '0';
        wait for CLK_PERIOD;
        
        -- Pequena pausa
        wait for CLK_PERIOD;
        
        -- Verificar se o endereço 256 foi substituído (segundo endereço seria o LRU)
        addr <= std_logic_vector(to_unsigned(256, ADDR_WIDTH));
        rd_en <= '1';
        wait for CLK_PERIOD;
        
        report "Localidade temporal - Endereço 256 (deve ser miss): " & 
               "Hit = " & std_logic'image(hit) & 
               ", Miss = " & std_logic'image(miss);
        
        rd_en <= '0';
        wait for CLK_PERIOD;
        
        -- O endereço 0 deve ainda estar na cache
        addr <= std_logic_vector(to_unsigned(0, ADDR_WIDTH));
        rd_en <= '1';
        wait for CLK_PERIOD;
        
        report "Localidade temporal - Endereço 0 (deve ser hit): " & 
               "Hit = " & std_logic'image(hit) & 
               ", Miss = " & std_logic'image(miss);
        
        rd_en <= '0';
        wait for CLK_PERIOD;
               
        -- Finalizando
        report "Teste concluído";
        wait;
    end process;
end Behavioral;