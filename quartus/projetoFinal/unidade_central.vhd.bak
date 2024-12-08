LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY CPU IS
    Port (
        clk      : in std_logic;                          -- Clock
        reset    : in std_logic;                          -- Reset
        in_data  : in std_logic_vector(7 downto 0);       -- Entrada externa
        out_data : out std_logic_vector(7 downto 0)       -- Saída externa
    );
END CPU;

ARCHITECTURE Behavioral OF CPU IS

    -- Sinais internos para comunicação entre os componentes
    signal instrucao        : std_logic_vector(7 downto 0);
    signal pc_out           : std_logic_vector(7 downto 0);
    signal ula_out          : std_logic_vector(7 downto 0);
    signal ula_operacao     : std_logic_vector(3 downto 0);
    signal ula_a, ula_b     : std_logic_vector(7 downto 0);
    signal mem_data_in      : std_logic_vector(7 downto 0);
    signal mem_data_out     : std_logic_vector(7 downto 0);
    signal mem_address      : std_logic_vector(7 downto 0);
    signal mem_read         : std_logic;
    signal mem_write        : std_logic;
    signal pc_enable        : std_logic;
    signal ula_enable       : std_logic;
	 signal reg_a, reg_b, reg_r, reg_i : std_logic_vector(7 DOWNTO 0) := "00000000";
    signal mem_enable       : std_logic;
    signal input_enable     : std_logic;
    signal output_enable    : std_logic;
    signal zero_flag, neg_flag, carry_flag, overflow_flag : std_logic;

    -- Instância do contador de programa (PC)
    COMPONENT program_counter IS
        Port (
            clk       : in std_logic;
            reset     : in std_logic;
            load      : in std_logic;                   
            increment : in std_logic;                   
            addr_in   : in std_logic_vector(7 downto 0);
            addr_out  : out std_logic_vector(7 downto 0)
        );
    END COMPONENT;

    -- Instância da unidade de memória
    COMPONENT memory_unit IS
        Port (
            clock       : in std_logic;
            data_in     : in std_logic_vector(7 downto 0);
            rdaddress   : in std_logic_vector(7 downto 0);
            wraddress   : in std_logic_vector(7 downto 0);
            wren        : in std_logic;
            data_out    : out std_logic_vector(7 downto 0)
        );
    END COMPONENT;

    -- Instância da ULA
    COMPONENT ULA IS
        Port (
            operacao : in std_logic_vector(3 downto 0);
            operA    : in std_logic_vector(7 downto 0);
            operB    : in std_logic_vector(7 downto 0);
            result   : out std_logic_vector(7 downto 0);
            Neg, Igual, Carry, Borrow, Overflow : out std_logic        
        );
    END COMPONENT;

    -- Instância da unidade de controle
    COMPONENT UnidadeControle IS
        Port (
            clk           : in std_logic;
            reset         : in std_logic;
            instrucao     : in std_logic_vector(7 downto 0);
            mem_enable    : out std_logic;
            input_enable  : out std_logic;
            output_enable : out std_logic;
            programcounter: out std_logic;
            ULA_enable    : out std_logic;
            operA         : out std_logic_vector(7 downto 0);
            operB         : out std_logic_vector(7 downto 0);
            regAUX0       : out std_logic_vector(1 downto 0);
            regAUX1       : out std_logic_vector(1 downto 0);
            operacao      : out std_logic_vector(3 downto 0);
            igual         : in std_logic;
            neg           : in std_logic;
            carry         : in std_logic;
            borrow        : in std_logic;
            overflow      : in std_logic
        );
    END COMPONENT;

BEGIN
    -- Instância do Contador de Programa
    program_counter_inst : program_counter
        Port Map (
            clk       => clk,
            reset     => reset,
            load      => pc_enable,
            increment => '1',
            addr_in   => mem_address,
            addr_out  => pc_out
        );

    -- Instância da Unidade de Memória
    memory_inst : memory_unit
        Port Map (
            clock     => clk,
            data_in   => ula_out,
            rdaddress => pc_out,
            wraddress => mem_address,
            wren      => mem_write,
            data_out  => mem_data_out
        );

    -- Instância da ULA
    ula_inst : ULA
        Port Map (
            operacao => ula_operacao,
            operA    => ula_a,
            operB    => ula_b,
            result   => ula_out,
            Neg      => neg_flag,
            Igual    => zero_flag,
            Carry    => carry_flag,
            Borrow   => overflow_flag,
            Overflow => overflow_flag
        );

    -- Instância da Unidade de Controle
    controle_inst : UnidadeControle
        Port Map (
            clk           => clk,
            reset         => reset,
            instrucao     => instrucao,
            mem_enable    => mem_enable,
            --mem_read      => mem_read,
            --mem_write     => mem_write,
            input_enable  => input_enable,
            output_enable => output_enable,
            programcounter=> pc_enable,
            ULA_enable    => ula_enable,
            operA         => ula_a,
            operB         => ula_b,
            regAUX0       => open,
            regAUX1       => open,
            operacao      => ula_operacao,
            igual         => zero_flag,
            neg           => neg_flag,
            carry         => carry_flag,
            borrow        => overflow_flag,
            overflow      => overflow_flag
        );

    -- Entrada e saída conectadas à memória e ao controle
    instrucao <= mem_data_out;
    out_data <= ula_out;
END Behavioral;
