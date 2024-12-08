LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY unidade_central IS
    Port (
        clk            : in std_logic;                          -- Clock
        reset          : in std_logic;                          -- Reset
        out_data       : out std_logic_vector(7 downto 0);      -- Saída externa
        switches       : in std_logic_vector(7 downto 0);      -- Chaves de entrada (8 bits)
		  espera_input   : in std_logic;
		  pc_out_4       : out std_logic_vector(3 downto 0)
    );
END unidade_central;

ARCHITECTURE Behavioral OF unidade_central IS

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
    signal load_pc          : std_logic;
    signal data_out         : std_logic_vector(7 downto 0);
    signal regAUXA          : std_logic_vector(1 downto 0);
    signal regAUXB          : std_logic_vector(1 downto 0);
    signal zero_flag, neg_flag, carry_flag, overflow_flag, borrow_flag : std_logic;

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
            clock     : in std_logic;
            data_in   : in std_logic_vector(7 downto 0);
            rdaddress : in std_logic_vector(7 downto 0);
            wraddress : in std_logic_vector(7 downto 0);
            wren      : in std_logic;
            data_out  : out std_logic_vector(7 downto 0)
        );
    END COMPONENT;

    -- Declaração do componente input
    COMPONENT input IS
        Port (
            switches      : in std_logic_vector(7 downto 0);  -- Chaves de entrada (8 bits)
            data_out      : out std_logic_vector(7 downto 0);  -- Saída para barramento de dados
            input_enable  : in std_logic;                     -- Habilita leitura
            espera_input  : in std_logic                      -- Botão leitura
        );
    END COMPONENT;

    
    -- Instância da unidade de controle
    COMPONENT UnidadeControle IS
        Port (
            clk           : in std_logic;                           -- Clock
            reset         : in std_logic;                           -- Reset
            instrucao     : in std_logic_vector(7 downto 0);        -- Instrução completa de 8 bits
            mem_enable    : out std_logic;                          -- Enable para memória
            load_pc       : out std_logic;                          -- sobe o address in pra memoria
            input_enable  : out std_logic;                          -- Enable para entrada
            output_enable : out std_logic;                          -- Enable para saída
            programcounter: out std_logic;                         -- Enable para contador de programa
            ULA_enable    : out std_logic;                          -- Enable para ULA
            regAUXA       : out std_logic_vector(1 downto 0);       -- Registrador selecionado
            regAUXB       : out std_logic_vector(1 downto 0);       -- Registrador selecionado
            operacao      : out std_logic_vector(3 downto 0);       -- Operação
            igual         : in std_logic;                           -- Zero Flag da ULA
            neg           : in std_logic;                           -- Flag de sinal da ULA
            carry         : in std_logic;                           -- Flag de carry da ULA
            borrow        : in std_logic;                           -- Flag de borrow da ULA
            overflow      : in std_logic;                            -- Flag de overflow da ULA
            espera_input  : in std_logic                            -- Aguarda um sinal de entrada para continuar
        );
    END COMPONENT;

BEGIN

    -- Processo de seleção de registradores e execução da ULA
    PROCESS(clk, reset)
		 VARIABLE temp_reg_a : std_logic_vector(7 downto 0);
		 VARIABLE temp_reg_b : std_logic_vector(7 downto 0);
		 VARIABLE temp_reg_R : std_logic_vector(7 downto 0);
    BEGIN
		  
        IF reset = '0' THEN
            -- Resetando os registradores e variáveis
            reg_a <= (OTHERS => '0');
            reg_b <= (OTHERS => '0');
            reg_r <= (OTHERS => '0');
            mem_address <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            -- Seleção do primeiro operando (A)
            CASE regAUXA IS
                WHEN "00" => 
                    ula_a <= reg_a;  -- Registrador A
                WHEN "01" => 
                    ula_a <= reg_b;  -- Registrador B
                WHEN "10" => 
                    ula_a <= reg_r;  -- Registrador R
                WHEN "11" => 
                    ula_a <= mem_data_out;  -- Valor imediato (manda a instrução pra ULA)
                WHEN OTHERS => 
                    ula_a <= (OTHERS => '0');  -- Valor padrão em caso de erro
            END CASE;

            -- Seleção do segundo operando (B)
            CASE regAUXB IS
                WHEN "00" => 
                    ula_b <= reg_a;  -- Registrador A
                WHEN "01" => 
                    ula_b <= reg_b;  -- Registrador B
                WHEN "10" => 
                    ula_b <= reg_r;  -- Registrador R
                WHEN "11" => 
                    ula_b <= mem_data_out;  -- Valor imediato
                WHEN OTHERS => 
                    ula_b <= (OTHERS => '0');  -- Valor padrão em caso de erro
            END CASE;

            -- Se a ULA estiver habilitada, executa a operação e armazena o resultado
            IF ula_enable = '1' THEN
                -- Se a operação não for NOT (uma operação unária), armazena o resultado da ULA no registrador R
                IF ula_operacao /= "1000" THEN  -- "1000" é o código para a operação CMP (senao perde o R)
                    reg_r <= ula_out;  -- Armazena o resultado da ULA no registrador R
                END IF;
            END IF;
        
		  
			  IF input_enable = '1' THEN
					CASE regAUXA IS
						 WHEN "00" => 
							  temp_reg_a := data_out;  -- Registrador A
						 WHEN "01" => 
							  temp_reg_b := data_out;  -- Registrador B
						 WHEN "10" => 
							  temp_reg_R := data_out;  -- Registrador R
						 WHEN "11" => 
							  temp_reg_a := data_out;  -- Valor imediato
						 WHEN OTHERS => 
							  temp_reg_a := (OTHERS => '0');  -- Valor padrão em caso de erro
					END CASE;
			  END IF;

			  -- Atribuindo as variáveis internas para os registradores
			  reg_a <= temp_reg_a;
			  reg_b <= temp_reg_b;
			  reg_R <= temp_reg_R;
			  
			  IF output_enable = '1' THEN
					CASE regAUXA IS
					 WHEN "00" => 
                    out_data <= reg_a;  -- Registrador A
                WHEN "01" => 
                    out_data <= reg_b;  -- Registrador B
                WHEN "10" => 
                    out_data <= reg_r;  -- Registrador R
                WHEN "11" => 
                    out_data <= mem_data_out;  -- Valor imediato (manda a instrução pra ULA)
                WHEN OTHERS => 
                    out_data <= (OTHERS => '0');  -- Valor padrão em caso de erro
					END CASE;
			  END IF;
		END IF;
    END PROCESS;

    -- Instância do componente input
    input_inst : input
        Port Map (
            switches      => switches,      -- Conecta as chaves de entrada
            data_out     => data_out,      -- Saída para o barramento de dados
            input_enable => input_enable,  -- Habilita leitura
            espera_input => espera_input   -- Botão de leitura (aguarda sinal de entrada)
        );

    -- Instância do Contador de Programa
    program_counter_inst : program_counter
        Port Map (
            clk       => clk,
            reset     => reset,
            load      => load_pc,
            increment => pc_enable,
            addr_in   => mem_address,
            addr_out  => pc_out
        );

    -- Instância da Unidade de Memória
    memory_inst : memory_unit
        Port Map (
            clock     => clk,
            data_in   => 
				_out,  -- Dados da ULA para memória
            rdaddress => pc_out,
            wraddress => ula_out,  -- Errado, deve ser controlado pela unidade de controle
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
            Borrow   => borrow_flag,
            Overflow => overflow_flag
        );

    -- Instância da Unidade de Controle
    unidade_controle_inst : UnidadeControle
        Port Map (
            clk           => clk,               -- Relaciona o sinal de clock da arquitetura
            reset         => reset,             -- Relaciona o sinal de reset da arquitetura
            instrucao     => mem_data_out,     -- A instrução é lida da memória (mem_data_out)
            mem_enable    => mem_write,        -- Habilita a escrita na memória
            load_pc       => load_pc,          -- Controla o sinal para carregar o valor no PC
            input_enable  => input_enable,     -- Habilita a entrada de dados (por exemplo, IN)
            output_enable => output_enable,    -- Habilita a saída de dados (por exemplo, OUT)
            programcounter => pc_enable,       -- Habilita a atualização do contador de programa
            ULA_enable    => ula_enable,       -- Habilita a execução da ULA
            regAUXA       => regAUXA,          -- Define o registrador auxiliar A (para operações)
            regAUXB       => regAUXB,          -- Define o registrador auxiliar B (para operações)
            operacao      => ula_operacao,     -- Envia a operação para a ULA
            igual         => zero_flag,        -- Flag de zero da ULA
            neg           => neg_flag,         -- Flag de sinal da ULA
            carry         => carry_flag,       -- Flag de carry da ULA
            borrow        => borrow_flag,      -- Flag de borrow da ULA
            overflow      => overflow_flag,    -- Flag de overflow da ULA
            espera_input  => espera_input      -- Sinal para aguardar entrada para continuar
        );
		  
		  
		  
END Behavioral;
