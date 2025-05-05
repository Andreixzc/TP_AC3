library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity cache_direct_mapped is
    generic (
        ADDR_WIDTH  : integer := 32;  -- Largura do endereço
        CACHE_SIZE  : integer := 256; -- Número de linhas na cache
        WORD_WIDTH  : integer := 32   -- Largura da palavra
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
end cache_direct_mapped;

architecture Behavioral of cache_direct_mapped is
    -- Constantes e cálculos de bits
    constant INDEX_BITS  : integer := integer(ceil(log2(real(CACHE_SIZE))));  -- 8 bits para 256 linhas
    constant OFFSET_BITS : integer := 2;                                       -- 2 bits para alinhamento de 4 bytes
    constant TAG_BITS    : integer := ADDR_WIDTH - INDEX_BITS - OFFSET_BITS;  -- Restante dos bits para tag

    -- Tipos para os arrays da cache
    type cache_data_array is array (0 to CACHE_SIZE-1) of std_logic_vector(WORD_WIDTH-1 downto 0);
    type cache_tag_array is array (0 to CACHE_SIZE-1) of std_logic_vector(TAG_BITS-1 downto 0);
    type valid_array is array (0 to CACHE_SIZE-1) of std_logic;

    -- Sinais para os componentes da cache
    signal cache_data    : cache_data_array := (others => (others => '0'));
    signal cache_tags    : cache_tag_array := (others => (others => '0'));
    signal valid_bits    : valid_array := (others => '0');

begin
    -- Processo principal de controle da cache
    process(clk)
        variable tag_v   : std_logic_vector(TAG_BITS-1 downto 0);
        variable index_v : integer range 0 to CACHE_SIZE-1;
        variable hit_v   : std_logic;
    begin
        if rising_edge(clk) then
            -- Inicializar sinais
            hit <= '0';
            miss <= '0';
            
            if reset = '1' then
                -- Reset: invalidar todas as linhas
                valid_bits <= (others => '0');
                data_out <= (others => '0');
            else
                -- Extrair tag e índice do endereço
                tag_v := addr(ADDR_WIDTH-1 downto INDEX_BITS+OFFSET_BITS);
                index_v := to_integer(unsigned(addr(INDEX_BITS+OFFSET_BITS-1 downto OFFSET_BITS)));
                
                -- Verificar hit: tag corresponde e linha válida
                hit_v := '0';
                if (valid_bits(index_v) = '1') and (cache_tags(index_v) = tag_v) then
                    hit_v := '1';
                end if;
                
                -- Operações
                if rd_en = '1' then
                    -- Leitura
                    if hit_v = '1' then
                        -- Hit
                        data_out <= cache_data(index_v);
                        hit <= '1';
                    else
                        -- Miss - carregar da memória (simulado)
                        cache_data(index_v) <= (others => '0');  -- Dados fictícios
                        cache_tags(index_v) <= tag_v;
                        valid_bits(index_v) <= '1';
                        data_out <= (others => '0');  -- Dados fictícios
                        miss <= '1';
                    end if;
                elsif wr_en = '1' then
                    -- Escrita (write-through)
                    cache_data(index_v) <= data_in;
                    cache_tags(index_v) <= tag_v;
                    valid_bits(index_v) <= '1';
                    
                    -- Indicar hit/miss
                    if hit_v = '1' then
                        hit <= '1';
                    else
                        miss <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;