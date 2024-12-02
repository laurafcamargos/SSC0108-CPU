LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY memory_unit IS
    PORT (
        clock       : IN STD_LOGIC;                   -- Clock da memória
        data_in     : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- Dados de entrada para escrita
        rdaddress   : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- Endereço de leitura
        wraddress   : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- Endereço de escrita
        wren        : IN STD_LOGIC;                    -- Sinal de escrita (1 para escrever)
        data_out    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)  -- Dados de saída de leitura
    );
END memory_unit;

ARCHITECTURE behavior OF memory_unit IS

    -- Instanciando a RAM 
    COMPONENT ram2port
        PORT (
            clock        : IN STD_LOGIC;
            data         : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            rdaddress    : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            wraddress    : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            wren         : IN STD_LOGIC;
            q            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

    -- Sinal de saída da RAM
    SIGNAL ram_data_out : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN

    -- Instanciando a RAM 256x8 com as ligações necessárias
    ram_instance : ram2port
        PORT MAP (
            clock       => clock,
            data        => data_in,
            rdaddress   => rdaddress,
            wraddress   => wraddress,
            wren        => wren,
            q           => ram_data_out
        );

    -- Conectando a saída da RAM à saída da unidade de memória
    data_out <= ram_data_out;

END behavior;