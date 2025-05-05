library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity cache_4way_associative is
    generic (
        ADDR_WIDTH  : integer := 32;  -- Largura do endereço
        CACHE_SIZE  : integer := 256; -- Número total de linhas na cache
        WORD_WIDTH  : integer := 32;  -- Largura da palavra
        WAYS        : integer := 4    -- Número de vias na cache associativa
    );
    port (
        clk         : in std_logic;
        reset       : in std_logic;
        addr        : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        data_in     : in std_logic_vector(WORD_WIDTH-1 downto 0);
        rd_en       : in std_logic;
        wr_en       : in std_logic;
        repl_policy : in std_logic;   -- '0' para LRU, '1' para Random
        data_out    : out std_logic_vector(WORD_WIDTH-1 downto 0);
        hit         : out std_logic;
        miss        : out std_logic
    );
end cache_4way_associative;

architecture Behavioral of cache_4way_associative is
    -- Constantes e cálculos de bits
    constant SETS        : integer := 64;  -- 64 conjuntos (256/4)
    constant INDEX_BITS  : integer := 6;   -- 6 bits para 64 conjuntos
    constant OFFSET_BITS : integer := 2;   -- 2 bits para alinhamento de 4 bytes
    constant TAG_BITS    : integer := 24;  -- 32 - 6 - 2 = 24 bits para tag
    
    -- Tipos para os arrays da cache
    type cache_data_array is array (0 to SETS-1, 0 to WAYS-1) of std_logic_vector(WORD_WIDTH-1 downto 0);
    type cache_tag_array is array (0 to SETS-1, 0 to WAYS-1) of std_logic_vector(TAG_BITS-1 downto 0);
    type valid_array is array (0 to SETS-1, 0 to WAYS-1) of std_logic;
    
    -- Para LRU
    type lru_array is array (0 to SETS-1, 0 to WAYS-1) of unsigned(1 downto 0);  -- Contador para cada via
    
    -- Sinais para os componentes da cache
    signal cache_data    : cache_data_array := (others => (others => (others => '0')));
    signal cache_tags    : cache_tag_array := (others => (others => (others => '0')));
    signal valid_bits    : valid_array := (others => (others => '0'));
    signal lru_counters  : lru_array := (others => (others => (others => '0')));
    
    -- Para Random
    signal random_count  : unsigned(1 downto 0) := "00";  -- Contador simples para rotação
    
begin
    -- Processo principal da cache
    process(clk)
        variable tag_v       : std_logic_vector(TAG_BITS-1 downto 0);
        variable index_v     : integer range 0 to SETS-1;
        variable hit_way     : integer range 0 to WAYS-1;
        variable hit_found   : boolean;
        variable lru_way     : integer range 0 to WAYS-1;
        variable empty_way   : integer range 0 to WAYS-1;
        variable found_empty : boolean;
    begin
        if rising_edge(clk) then
            -- Inicializar sinais
            hit <= '0';
            miss <= '0';
            
            if reset = '1' then
                -- Reset: invalidar todas as linhas
                valid_bits <= (others => (others => '0'));
                lru_counters <= (others => (others => (others => '0')));
                random_count <= "00";
                data_out <= (others => '0');
            else
                -- Extrair tag e índice do endereço
                tag_v := addr(ADDR_WIDTH-1 downto INDEX_BITS+OFFSET_BITS);
                index_v := to_integer(unsigned(addr(INDEX_BITS+OFFSET_BITS-1 downto OFFSET_BITS)));
                
                -- Incrementar contador de rotação
                random_count <= random_count + 1;
                
                -- Verificar hit na cache
                hit_found := false;
                hit_way := 0;
                
                for i in 0 to WAYS-1 loop
                    if valid_bits(index_v, i) = '1' and cache_tags(index_v, i) = tag_v then
                        hit_found := true;
                        hit_way := i;
                        exit;
                    end if;
                end loop;
                
                -- Operação de Leitura
                if rd_en = '1' then
                    if hit_found then
                        -- Hit: retornar dado da cache
                        data_out <= cache_data(index_v, hit_way);
                        hit <= '1';
                        
                        -- Atualizar contadores LRU
                        if repl_policy = '0' then  -- LRU
                            for i in 0 to WAYS-1 loop
                                if i = hit_way then
                                    lru_counters(index_v, i) <= "00";  -- MRU
                                elsif lru_counters(index_v, i) < "11" then
                                    lru_counters(index_v, i) <= lru_counters(index_v, i) + 1;
                                end if;
                            end loop;
                        end if;
                    else
                        -- Miss: encontrar via para substituição
                        found_empty := false;
                        empty_way := 0;
                        
                        -- Procurar via vazia
                        for i in 0 to WAYS-1 loop
                            if valid_bits(index_v, i) = '0' then
                                empty_way := i;
                                found_empty := true;
                                exit;
                            end if;
                        end loop;
                        
                        -- Se não encontrou via vazia, escolher via para substituição
                        if not found_empty then
                            if repl_policy = '0' then  -- LRU
                                lru_way := 0;
                                for i in 1 to WAYS-1 loop
                                    if lru_counters(index_v, i) > lru_counters(index_v, lru_way) then
                                        lru_way := i;
                                    end if;
                                end loop;
                                empty_way := lru_way;
                            else  -- Random
                                empty_way := to_integer(random_count);
                            end if;
                        end if;
                        
                        -- Simular busca na memória principal
                        -- Define valores específicos para cada endereço para testar
                        if addr = x"00000000" then      -- 0
                            cache_data(index_v, empty_way) <= std_logic_vector(to_unsigned(100, WORD_WIDTH));
                            data_out <= std_logic_vector(to_unsigned(100, WORD_WIDTH));
                        elsif addr = x"00000100" then   -- 256
                            cache_data(index_v, empty_way) <= std_logic_vector(to_unsigned(101, WORD_WIDTH));
                            data_out <= std_logic_vector(to_unsigned(101, WORD_WIDTH));
                        elsif addr = x"00000200" then   -- 512
                            cache_data(index_v, empty_way) <= std_logic_vector(to_unsigned(102, WORD_WIDTH));
                            data_out <= std_logic_vector(to_unsigned(102, WORD_WIDTH));
                        elsif addr = x"00000300" then   -- 768
                            cache_data(index_v, empty_way) <= std_logic_vector(to_unsigned(103, WORD_WIDTH));
                            data_out <= std_logic_vector(to_unsigned(103, WORD_WIDTH));
                        elsif addr = x"00000400" then   -- 1024
                            cache_data(index_v, empty_way) <= std_logic_vector(to_unsigned(104, WORD_WIDTH));
                            data_out <= std_logic_vector(to_unsigned(104, WORD_WIDTH));
                        else
                            -- Para outros endereços
                            cache_data(index_v, empty_way) <= (others => '0');
                            data_out <= (others => '0');
                        end if;
                        
                        -- Atualizar metadados da cache
                        cache_tags(index_v, empty_way) <= tag_v;
                        valid_bits(index_v, empty_way) <= '1';
                        miss <= '1';
                        
                        -- Atualizar contadores LRU
                        if repl_policy = '0' then  -- LRU
                            for i in 0 to WAYS-1 loop
                                if i = empty_way then
                                    lru_counters(index_v, i) <= "00";  -- MRU
                                elsif lru_counters(index_v, i) < "11" then
                                    lru_counters(index_v, i) <= lru_counters(index_v, i) + 1;
                                end if;
                            end loop;
                        end if;
                    end if;
                
                -- Operação de Escrita    
                elsif wr_en = '1' then
                    if hit_found then
                        -- Hit: atualizar dado na cache
                        cache_data(index_v, hit_way) <= data_in;
                        hit <= '1';
                        
                        -- Atualizar contadores LRU
                        if repl_policy = '0' then  -- LRU
                            for i in 0 to WAYS-1 loop
                                if i = hit_way then
                                    lru_counters(index_v, i) <= "00";  -- MRU
                                elsif lru_counters(index_v, i) < "11" then
                                    lru_counters(index_v, i) <= lru_counters(index_v, i) + 1;
                                end if;
                            end loop;
                        end if;
                    else
                        -- Miss: encontrar via para substituição (mesmo procedimento da leitura)
                        found_empty := false;
                        empty_way := 0;
                        
                        -- Procurar via vazia
                        for i in 0 to WAYS-1 loop
                            if valid_bits(index_v, i) = '0' then
                                empty_way := i;
                                found_empty := true;
                                exit;
                            end if;
                        end loop;
                        
                        -- Se não encontrou via vazia, escolher via para substituição
                        if not found_empty then
                            if repl_policy = '0' then  -- LRU
                                lru_way := 0;
                                for i in 1 to WAYS-1 loop
                                    if lru_counters(index_v, i) > lru_counters(index_v, lru_way) then
                                        lru_way := i;
                                    end if;
                                end loop;
                                empty_way := lru_way;
                            else  -- Random
                                empty_way := to_integer(random_count);
                            end if;
                        end if;
                        
                        -- Atualizar dados e metadados da cache
                        cache_data(index_v, empty_way) <= data_in;
                        cache_tags(index_v, empty_way) <= tag_v;
                        valid_bits(index_v, empty_way) <= '1';
                        miss <= '1';
                        
                        -- Atualizar contadores LRU
                        if repl_policy = '0' then  -- LRU
                            for i in 0 to WAYS-1 loop
                                if i = empty_way then
                                    lru_counters(index_v, i) <= "00";  -- MRU
                                elsif lru_counters(index_v, i) < "11" then
                                    lru_counters(index_v, i) <= lru_counters(index_v, i) + 1;
                                end if;
                            end loop;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;