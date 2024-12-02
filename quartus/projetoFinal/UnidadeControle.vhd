library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UnidadeControle is
    Port (
        clk           : in std_logic;                           -- Clock
        reset         : in std_logic;                           -- Reset
        instrucao     : in std_logic_vector(7 downto 0);        -- Instrução completa de 8 bits
        mem_enable    : out std_logic;                          -- Enable para memória
        --mem_read      : out std_logic;                          -- Enable para leitura de memória
        --mem_write     : out std_logic;                          -- Enable para escrita na memória
		  --up_pc         : out std_logic;                          -- sobe o program counter
        input_enable  : out std_logic;                          -- Enable para entrada
        output_enable : out std_logic;                          -- Enable para saída
        programcounter: out std_logic;                         -- Enable para contador de programa
        ULA_enable    : out std_logic;                          -- Enable para ULA
        operA         : out std_logic_vector(7 downto 0);       -- Operando A
        operB         : out std_logic_vector(7 downto 0);       -- Operando B
		  regAUX0       : out std_logic_vector(1 downto 0);       -- Registrador selecionado
		  regAUX1       : out std_logic_vector(1 downto 0);       -- Registrador selecionado
        operacao      : out std_logic_vector(3 downto 0);       -- Operação
        igual         : in std_logic;                           -- Zero Flag da ULA
        neg           : in std_logic;                           -- Flag de sinal da ULA
        carry         : in std_logic;                           -- Flag de carry da ULA
        borrow        : in std_logic;                           -- Flag de borrow da ULA
        overflow      : in std_logic                            -- Flag de overflow da ULA
    );
end UnidadeControle;

architecture Behavioral of UnidadeControle is
    type state_type is (espera, search, decode, exec, memoria, controle_fluxo, fetch);
    signal estado, proximo_estado : state_type;
    signal op_code : std_logic_vector(3 downto 0); 
    signal reg_sel : std_logic_vector(3 downto 0);
    signal reg_a, reg_b, reg_r : std_logic_vector(7 downto 0);
begin
    op_code <= instrucao(7 downto 4);  -- Extrai os 4 bits mais significativos
    reg_sel <= instrucao(3 downto 0); -- Extrai os 4 bits menos significativos

    -- Processo de controle principal (transições de estado)
    process(clk, reset)
    begin
        if reset = '0' then
            estado <= espera;
        elsif rising_edge(clk) then
            estado <= proximo_estado;
        end if;
    end process;

    -- Lógica de controle de sinais de controle e operações
    process(estado, op_code, reg_sel, igual, neg, carry, overflow)
    begin
        -- Inicializando todos os sinais com valores padrão
        mem_enable <= '0';
        input_enable <= '0';
        output_enable <= '0';
        programcounter <= '0';
        ULA_enable <= '0';
        operA <= (others => '0');
        operB <= (others => '0');
        operacao <= (others => '0');
        
        case estado is
            -- Estado de espera
            when espera =>
                if reset = '0' then
                    proximo_estado <= search;
                else
                    proximo_estado <= espera;
                end if;

            -- Busca a próxima instrução
            when search =>
                programcounter <= '1';  -- Incrementa o contador de programa (PC)
                proximo_estado <= decode;

            -- Decodifica a instrução
            when decode =>
                case op_code is
                    -- Operações de Aritmética e Lógica -ADD,SUB,AND,OR,CMP,NOT
                    when "0001" | "0010" | "0011" | "0100" | "1000" | "0101" =>
                        if reg_sel(1 DOWNTO 0) = "11" then
                            -- Configurar para buscar o valor imediato
                            proximo_estado <= fetch;
                        else
                            proximo_estado <= exec;
                        end if;

                    -- Instruções de Memória e Entrada/Saída - LOAD,STORE,IN,OUT,MOV
                    when "1001" | "1010" | "0110" | "0111" | "1110" =>
                        proximo_estado <= memoria;

                    -- Instruções de Controle de Fluxo --JMP,JEQ,JGR
                    when "1011" | "1100" | "1101" =>
                        proximo_estado <= controle_fluxo;

                    -- Instrução de Espera --WAIT
                    when "1111" =>
                        proximo_estado <= espera;

                    -- Instruções inválidas ou não implementadas
                    when others =>
                        proximo_estado <= espera;
                end case;
					 
				when fetch =>
					programcounter <= '1';  -- Incrementa o contador para acessar o próximo endereço
					operB <= instrucao;     -- Carrega o valor imediato no operando B
					proximo_estado <= exec; -- Transita para o estado de execução

            -- Execução de operações aritméticas e lógicas
            when exec =>
                ULA_enable <= '1';
                operacao <= op_code;
                case reg_sel is
                    when "0000" => operA <= reg_a; operB <= reg_a;
                    when "0001" => operA <= reg_a; operB <= reg_b;
                    when "0010" => operA <= reg_a; operB <= reg_r;
                    when "0100" => operA <= reg_b; operB <= reg_a;
                    when "0101" => operA <= reg_b; operB <= reg_b;
                    when "0110" => operA <= reg_b; operB <= reg_r;
                    when "1000" => operA <= reg_r; operB <= reg_a;
                    when "1001" => operA <= reg_r; operB <= reg_b;
                    when "1010" => operA <= reg_r; operB <= reg_r;
						  -- casos com valor imediato, considera-se que imediato já está em operB
						  when "0011" => operA <= reg_a;
						  when "0111" => operA <= reg_b;
						  when "1011" => operA <= reg_r;
                    when others => operA <= (others => '0'); operB <= (others => '0');
                end case;
                proximo_estado <= search;

            -- Controle de fluxo
            when controle_fluxo =>
                case op_code is
                    when "1100" => -- JMP addr
                        programcounter <= '1';
                        operB <= instrucao;
                    when "1101" => -- JEQ addr
                        if igual = '1' then
                            programcounter <= '1';
                            operB <= instrucao;
                        end if;
                    when "1110" => -- JGR addr
                        if neg = '0' and igual = '0' then
                            programcounter <= '1';
                            operB <= instrucao;
                        end if;
                    when others => -- Caso inválido
                        proximo_estado <= espera;
                end case;
					 programcounter <= '0';
                proximo_estado <= search;

            -- Acesso à memória ou Entrada/Saída
            when memoria =>
                mem_enable <= '1';
                case op_code is
                    when "1001" => -- LOAD regx, address: carrega o valor do endereço address para regx.
								programcounter <= '1';
								operB <= instrucao;
                        operacao <= "1001";
                    when "1010" => -- STORE regx, address: armazena o valor de regx no address
                        programcounter <= '1';
                        operacao <= "1010";
                        operA <= instrucao;
                    when "0110" => -- IN
                        input_enable <= '1';
                        operacao <= "0110";
                        operA <= instrucao;
                    when "0111" => -- OUT
                        output_enable <= '1';
                        operacao <= "0111";
                        operA <= instrucao;
                    when "1110" => -- MOV Reg1, Reg2: Move o valor de Reg2 para Reg1
								regAUX1 <= reg_sel(3 DOWNTO 2); --destino
								regAUX0 <= reg_sel(1 DOWNTO 0); --origem
                        
                    when others =>
                        mem_enable <= '0';
								programcounter <= '0';
                        operacao <= (others => '0');
                end case;
					 programcounter <= '0'; -- Para de incrementar o programcounter
                proximo_estado <= search;

            -- Estado padrão (não deve ocorrer)
            when others =>
                proximo_estado <= espera;
        end case;
    end process;

end Behavioral;