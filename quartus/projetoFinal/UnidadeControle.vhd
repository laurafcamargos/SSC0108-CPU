library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UnidadeControle is
    Port (
        clk           : in std_logic;                           -- Clock
        reset         : in std_logic;                           -- Reset
		  load          : in std_logic;
		  input         : in std_logic_vector(7 downto 0);
		  output        : out std_logic_vector(7 downto 0)
    );
end UnidadeControle;

architecture Behavioral of UnidadeControle is
    type state_type is (search, decode, exec, memoria, controle_fluxo, op, out_put, in_put,espera);
	 TYPE mem_ram IS ARRAY(0 TO 255) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal estado : state_type;
    signal op_code : std_logic_vector(3 downto 0);
	 signal operacao : std_logic_vector(3 downto 0); 
    signal reg_sel : std_logic_vector(3 downto 0);
    signal reg_a, reg_b, reg_r : std_logic_vector(7 downto 0);
	 signal program_counter : std_logic_vector (7 downto 0);
	 signal instrucao     :  std_logic_vector(7 downto 0);
	 SIGNAL mem : mem_ram := (others => (others => '0'));
	 signal ula_out : std_logic_vector(7 downto 0) := "00000000";
	 signal neg_flag,zero_flag,carry_flag,borrow_flag,overflow_flag,ula_enable : STD_LOGIC;
	 signal regAUXA       :  std_logic_vector(7 downto 0);       -- Registrador selecionado
	 signal regAUXB       :  std_logic_vector(7 downto 0);       -- Registrador selecionado

	 -- Instância da ULA
    COMPONENT ULA IS
        Port (
        operacao : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
        operA    : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        operB    : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        result_output   : out STD_LOGIC_VECTOR(7 DOWNTO 0);
        Neg,Igual,Carry,Borrow,Overflow : OUT STD_LOGIC;
		  ula_enable : IN STD_LOGIC        
        );
    END COMPONENT;
begin
	     -- Instância da ULA
    ula_inst : ULA
        Port Map (
            operacao => op_code,
            operA    => regAUXA,
            operB    => regAUXB,
            result_output   => reg_r,
            Neg      => neg_flag,
            Igual    => zero_flag,
            Carry    => carry_flag,
            Borrow   => borrow_flag,
            Overflow => overflow_flag,
				ula_enable => ula_enable
        );
    -- Lógica de controle de sinais de controle e operações
    process(estado, op_code, reg_sel, zero_flag, neg_flag, carry_flag, overflow_flag, clk, reset)
    begin
			if reset = '0' then
            estado <= search;
				program_counter <= "00000000";
				ULA_enable <= '0';			
				operacao <= (others => '0');
			
				-- in A
				-- in B
				-- MOV R 0
				-- LOOPSTART
				-- 	CMP B 0
				--		JEQ END LOOP
				-- 	ADD R A
				--		STORE R 255
				-- 	SUB B, 1
				-- 	MOV B R
				-- 	LOAD R 255
				-- 	JPM LOOP START
				-- END LOOP
				
							
				
        elsif rising_edge(clk) then
			  case estado is
				-- Busca a próxima instrução
					when search =>
						 ula_enable <= '0';
						 instrucao <= mem(CONV_INTEGER(program_counter)); --converte pc pra int
						 estado <= op;
						 
					when op =>
						op_code <= instrucao(7 downto 4);  -- Extrai os 4 bits mais significativos
						reg_sel <= instrucao(3 downto 0);  -- Extrai os 4 bits menos significativos
						estado <= decode;
						
					-- Decodifica a instrução
					when decode =>
							  -- Operações de Aritmética e Lógica -ADD,SUB,AND,OR,CMP,NOT
							  if op_code = "0001" or op_code = "0010" or op_code = "0011" or op_code = "0100" 
							  or op_code = "1000" or op_code ="0101" then
									estado <= exec;
							 end if;
							  -- Instruções de Memória e Entrada/Saída - LOAD,STORE,IN,OUT,MOV
							  if op_code = "1001" or op_code = "1010" or op_code = "0110" or op_code = "0111" or op_code = "1110" then
									estado <= memoria;
									end if;
							  -- Instruções de Controle de Fluxo --JMP,JEQ,JGR
							  if op_code = "1011" or op_code = "1100" or op_code = "1101" then
									estado <= controle_fluxo;
								end if;	
							  -- Instrução de search --WAIT
							  if op_code = "1111" then
									estado <= espera;
								end if;
							  if op_code = "0000" then
									program_counter <= program_counter + 1;
									estado <= espera;
							    end if;					  

								 
					when espera =>
						if load = '1' then
						program_counter <= program_counter + 1;
							estado <= search;
						else
							estado <= espera;
						end if;
						
					-- Execução de operações aritméticas e lógicas
					when exec =>
						 if op_code = "1000" then
							ULA_enable <= '0';
						 else
							ULA_enable <= '1';
						 end if;
						 operacao <= op_code;
						 CASE reg_sel(3 DOWNTO 2) IS
								WHEN "00" => 
									regAUXA <= reg_a;  -- Registrador A
								WHEN "01" => 
							  regAUXA <= reg_b;  -- Registrador B
								WHEN "10" => 
							  regAUXA <= reg_r;  -- Registrador R
								WHEN "11" => 
								program_counter <= program_counter + 1;
							 if op_code = "0001" or op_code = "0010" then
									regAUXA <= "00000001";
							 end if;
							 -- load , store, 255
							 WHEN OTHERS => 
							  regAUXA <= (OTHERS => '0');  -- Valor padrão em caso de erro
						 END CASE;
            -- Seleção do segundo operando (B)
            CASE reg_sel(1 DOWNTO 0) IS
                WHEN "00" => 
                    regAUXB <= reg_a;  -- Registrador A
                WHEN "01" => 
                    regAUXB <= reg_b;  -- Registrador B
                WHEN "10" => 
                    regAUXB <= reg_r;  -- Registrador R
                WHEN "11" => 
					 program_counter <= program_counter + 1;
                    if op_code = "0001" or op_code = "0010" then
								regAUXB <= "00000001";
						  end if;
                WHEN OTHERS => 
                    regAUXB <= (OTHERS => '0');  -- Valor padrão em caso de erro
            END CASE;
				program_counter <= program_counter + 1;
				estado <= search;
				
					-- Controle de fluxo
					when controle_fluxo =>
						 case op_code is
							  when "1100" => -- JMP addr
									program_counter <= mem(CONV_INTEGER(program_counter + 1));
									estado <= search;
							  when "1101" => -- JEQ addr
									if zero_flag = '1' then
										 program_counter <= mem(CONV_INTEGER(program_counter + 1));
									end if;
									program_counter <= program_counter + 2;
									estado <= search;
									
							  when "1110" => -- JGR addr
									if neg_flag = '0' and zero_flag = '0' then
										 program_counter <= mem(CONV_INTEGER(program_counter + 1));
									end if;
									program_counter <= program_counter + 2;
									estado <= search;
							  when others => -- Caso inválido
									estado <= search;
						 end case;
						 estado <= search;

					-- Acesso à memória ou Entrada/Saída
					when memoria =>				
						 case op_code is
							  when "1001" => -- LOAD regx, address: carrega o valor do endereço address para regx.
									operacao <= "1001";
									program_counter <= program_counter + 1;
									
									estado <= search;
									
							  when "1010" => -- STORE regx, address: armazena o valor de regx no address
									operacao <= "1010";
									program_counter <= program_counter + 1;
									estado <= search;
									
							  when "0110" => -- IN
									operacao <= "0110";
									if load = '1' then
										regAUXA <= input;
										estado <= in_put;
									else
										estado <= memoria;
									end if;
									
							  when "0111" => -- OUT
									operacao <= "0111";
									 CASE reg_sel(3 DOWNTO 2) IS
											WHEN "00" => 
												regAUXA <= reg_a;  -- Registrador A
											WHEN "01" => 
												regAUXA <= reg_b;  -- Registrador B
											WHEN "10" => 
												regAUXA <= reg_r;  -- Registrador R
											WHEN "11" => 
												program_counter <= program_counter + 1;
												regAUXA <= "11111111";
											WHEN OTHERS => 
												regAUXA <= (OTHERS => '0');  -- Valor padrão em caso de erro
									 END CASE;	
									estado <= out_put;
									when "1110" => -- MOV Reg1, Reg2: Move o valor de Reg2 para Reg1
										CASE reg_sel(3 DOWNTO 2) IS
											WHEN "00" => 
												regAUXA <= reg_a;  -- Registrador A
											WHEN "01" => 
												regAUXA <= reg_b;  -- Registrador B
											WHEN "10" => 
												regAUXA <= reg_r;  -- Registrador R
											WHEN "11" => 
												program_counter <= program_counter + 1;
												regAUXA <= "11111111";
											WHEN OTHERS => 
												regAUXA <= (OTHERS => '0');  -- Valor padrão em caso de erro
									 END CASE;
									 CASE reg_sel(1 DOWNTO 0) IS
										 WHEN "00" => 
											  regAUXB <= reg_a;  -- Registrador A
										 WHEN "01" => 
											  regAUXB <= reg_b;  -- Registrador B
										 WHEN "10" => 
											  regAUXB <= reg_r;  -- Registrador R
										 WHEN "11" => 
										 program_counter <= program_counter + 1;
											  if op_code = "0001" or op_code = "0010" then
													regAUXB <= "00000001";
											  end if;
										 WHEN OTHERS => 
											  regAUXB <= (OTHERS => '0');  -- Valor padrão em caso de erro
									END CASE;
							  when others =>
									operacao <= (others => '0');
						 end case;
						 
						 when in_put =>
								program_counter <= program_counter + 1;
								estado <= search;
								CASE reg_sel(3 DOWNTO 2) IS
									WHEN "00" => 
										reg_a <= regAUXA;  -- Registrador A
									WHEN "01" => 
										reg_b <= regAUXA;  -- Registrador B
									WHEN OTHERS => 
										regAUXA <= (OTHERS => '0');  -- Valor padrão em caso de erro
									 END CASE;											
						 when out_put =>
								output <= regAUXA;
								program_counter <= program_counter + 1;
								estado <= search;
								
					-- Estado padrão (não deve ocorrer)
					when others =>
						 program_counter <= program_counter + 1;
						 estado <= search;
			  end case;
		  end if;
    end process;

end Behavioral;