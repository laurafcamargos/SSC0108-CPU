library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UnidadeControleDiv is
    Port (
        clk           : in std_logic;                           -- Clock
        reset         : in std_logic;                           -- Reset
		  load          : in std_logic;
		  input         : in std_logic_vector(7 downto 0);
		  output        : out std_logic_vector(7 downto 0)
    );
end UnidadeControleDiv;

architecture Behavioral of UnidadeControleDiv is
    type state_type is (search, decode, exec, memoria, controle_fluxo, op, out_put, in_put,espera, cmp_en);
	 TYPE mem_ram IS ARRAY(0 TO 255) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal estado : state_type;
    signal op_code : std_logic_vector(3 downto 0);
	 signal operacao : std_logic_vector(3 downto 0); 
    signal reg_sel : std_logic_vector(3 downto 0);
    signal reg_a, reg_b, reg_r, rAUX : std_logic_vector(7 downto 0);
	 signal program_counter : std_logic_vector (7 downto 0);
	 signal instrucao     :  std_logic_vector(7 downto 0);
	 SIGNAL mem : mem_ram := (others => (others => '0'));
	 signal ula_out : std_logic_vector(7 downto 0) := "00000000";
	 signal neg_flag,zero_flag,carry_flag,borrow_flag,overflow_flag,ula_enable : STD_LOGIC;
	 signal regAUXA       :  std_logic_vector(7 downto 0);       -- Registrador selecionado
	 signal regAUXB       :  std_logic_vector(7 downto 0);       -- Registrador selecionado
	 signal r_write,cmp_flag,igual_flag : std_logic;
	 signal cmp_enable : std_logic;

	 -- Instância da ULA
    COMPONENT ULA IS
        Port (
        operacao : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
        operA    : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        operB    : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        result_output   : out STD_LOGIC_VECTOR(7 DOWNTO 0);
        Neg,Igual,Carry,Borrow,Overflow : OUT STD_LOGIC;
		  ula_enable : IN STD_LOGIC;
		  cmp_enable : IN STD_LOGIC
        );
    END COMPONENT;
begin
	     -- Instância da ULA
    ula_inst : ULA
        Port Map (
            operacao => op_code,
            operA    => regAUXA,
            operB    => regAUXB,
            result_output   => ula_out,
            Neg      => neg_flag,
            Igual    => zero_flag,
            Carry    => carry_flag,
            Borrow   => borrow_flag,
            Overflow => overflow_flag,
				ula_enable => ula_enable,
				cmp_enable => cmp_enable
        );
    -- Lógica de controle de sinais de controle e operações
    process(estado, op_code, reg_sel, zero_flag, neg_flag, carry_flag, overflow_flag, clk, reset)
    begin
			if reset = '0' then
            estado <= search;
				program_counter <= "00000000";
				ULA_enable <= '0';
				cmp_enable <= '0';
				operacao <= (others => '0');
				
			   -- divisao --
				mem(0)  <= "01100000"; -- in a
				mem(1)  <= "01100100"; -- in b
				mem(2)  <= "11101011"; -- mov r 0
				mem(3)  <= "10101011"; -- store r 255
				mem(4)  <= "11101000"; -- mov r a
				mem(5)  <= "00000000"; -- loop_start
				mem(6)  <= "00101001"; -- sub r b
				mem(7)  <= "11100010"; -- mov a r
				mem(8)  <= "10011011"; -- load r 255
				mem(9)  <= "00011011"; -- add a 1
				mem(10) <= "10101011"; -- store r 255
				mem(11) <= "11101000"; -- mov r a
				mem(12) <= "10001001"; -- cmp r b
				mem(13) <= "11010000"; -- jgr
				mem(14) <= "10011011"; -- load r 255
				mem(15) <= "01111000"; -- out r
				mem(16) <= "11110000"; -- wait

        elsif rising_edge(clk) then
			  case estado is
				-- Busca a próxima instrução
					when search =>
						 ula_enable <= '0';
						 cmp_enable <= '0';
						 r_write <= '0';
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
									cmp_enable <= '0';
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
									estado <= search;
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
							cmp_enable <= '0';
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
								 if op_code = "0001" or op_code = "0010" then
										regAUXA <= "00000001";
								 elsif op_code = "1000" then
										regAUXA <= "00000000";
								 end if;
				
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
					 if op_code = "0001" or op_code = "0010" then
									regAUXB <= "00000001";
					 elsif op_code = "1000" then
						 regAUXB <= "00000000";
					 end if;
					 
                WHEN OTHERS => 
                    regAUXB <= (OTHERS => '0');  -- Valor padrão em caso de erro
            END CASE;
				if op_code = "1000" then
					estado <= cmp_en;
				else
					program_counter <= program_counter + 1;
					estado <= search;
				end if;
				
				when cmp_en =>
					if op_code = "1000" then
							estado <= cmp_en;
					end if;
					program_counter <= program_counter + 1;
					estado <= search;
					
					-- Controle de fluxo
					when controle_fluxo =>
						 case op_code is
							  when "1011" => -- JMP addr
									program_counter <= "00000011";
									estado <= search;
							  when "1100" => -- JEQ addr
									if cmp_flag = '1' then
										 program_counter <= "00001100";
									end if;
									estado <= search;
									
							  when "1101" => -- JGR addr
									if igual_flag = '0' then
										 program_counter <= "00000101";
									else
										program_counter <= program_counter + 1;
									end if;
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
									CASE reg_sel(3 DOWNTO 2) IS
									WHEN "10" => 
										rAUX <= mem(255);  -- Registrador r
										r_write <= '1';
									WHEN "00" => 
										reg_a <= mem(255);  -- Registrador A
									WHEN "01" => 
										reg_b <= mem(255);  -- Registrador b
									WHEN OTHERS => 
										regAUXA <= (OTHERS => '0');  -- Valor padrão em caso de erro
									 END CASE;
									program_counter <= program_counter + 1;
									estado <= search;
									
							  when "1010" => -- STORE regx, address: armazena o valor de regx no address
									operacao <= "1010";
									CASE reg_sel(3 DOWNTO 2) IS
									WHEN "10" => 
										mem(255) <= reg_r;  -- Registrador r
									WHEN "00" => 
										mem(255) <= reg_a;  -- Registrador A
									WHEN "01" => 
										mem(255) <= reg_b;  -- Registrador b
									WHEN OTHERS => 
										regAUXA <= (OTHERS => '0');  -- Valor padrão em caso de erro
									 END CASE;
									 
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
												--program_counter <= program_counter + 1;
												regAUXA <= "11111111";
											WHEN OTHERS => 
												regAUXA <= (OTHERS => '0');  -- Valor padrão em caso de erro
									 END CASE;	
									estado <= out_put;
									
									
									when "1110" => -- MOV Reg1, Reg2: Move o valor de Reg2 para Reg1
										CASE reg_sel(3 DOWNTO 0) IS
											WHEN "0001" => 
												reg_a <= reg_b;  -- Registrador A
											WHEN "0010" => 
												reg_a <= reg_r;  -- Registrador B
												WHEN "0011" => 
												reg_a <= "00000000";  -- Registrador R
											WHEN "0100" => 
												reg_b <= reg_a;  -- Registrador R
												WHEN "0111" => 
												reg_b <= "00000000";  -- Registrador R
												WHEN "0110" => 
												reg_b <= reg_r;  -- Registrador R
												WHEN "1000" => 
												rAUX <= reg_a;  -- Registrador R
												r_write <= '1';
												WHEN "1001" => 
												reg_r <= reg_b;  -- Registrador R
												WHEN "1011" => 
												rAUX <= "00000000";  -- Registrador R
												r_write <= '1';
											WHEN "1111" => 
												--program_counter <= program_counter + 1;
												regAUXA <= "11111111";
											WHEN OTHERS => 
												regAUXA <= (OTHERS => '0');  -- Valor padrão em caso de erro
									END CASE;
									program_counter <= program_counter + 1;
									estado <= search;
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
		  
		  if ula_enable ='1' then
				reg_r <= ula_out;
		  elsif r_write = '1' then
				reg_r <= rAUX;
		  end if;
			if op_code = "1000" and cmp_enable <= '1' then 
				cmp_flag <= zero_flag;
				igual_flag <= neg_flag;
			end if;
			
    end process;

end Behavioral;