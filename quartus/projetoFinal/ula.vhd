LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_1164.all ;
USE ieee.std_logic_unsigned.all ;
 
ENTITY ula IS
    PORT (
        operacao : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
        operA    : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        operB    : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        result_output   : out STD_LOGIC_VECTOR(7 DOWNTO 0);
        Neg,Igual,Carry,Borrow,Overflow : OUT STD_LOGIC;
		  ula_enable : IN STD_LOGIC;
		  cmp_enable : IN STD_LOGIC
        
    );
END ula;
 
ARCHITECTURE Behavioral OF ula IS
	constant ADIC : STD_LOGIC_VECTOR(3 DOWNTO 0):="0001";
	constant SUB  : STD_LOGIC_VECTOR(3 DOWNTO 0):="0010";
	constant OU   : STD_LOGIC_VECTOR(3 DOWNTO 0):="0011";
	constant E    : STD_LOGIC_VECTOR(3 DOWNTO 0):="0100";
	constant NAO  : STD_LOGIC_VECTOR(3 DOWNTO 0):="0101";
	constant CMP  : STD_LOGIC_VECTOR(3 DOWNTO 0):="1000"; 
	signal result_anterior : STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal result : STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal result_final : STD_LOGIC_VECTOR(7 DOWNTO 0);
BEGIN
    computa: process (operA, operB, operacao, result)

    VARIABLE temp : STD_LOGIC_VECTOR(8 DOWNTO 0);
    begin
		  Igual <= '0';
        case operacao is
        when ADIC =>
            temp := ('0'&operA) + ('0'&operB);
            result <= temp(7 DOWNTO 0);
            Carry <= temp(8);
            if (operA(7)=operB(7)) then
                if (operA(7) /= result(7)) then Overflow <= '1';
                    else Overflow <= '0';
                end if;
            else Overflow <= '0';
            end if;
        when SUB =>
            temp := ('0'&operA) - ('0'&operB);
            result <= temp(7 DOWNTO 0);
            Borrow <= temp(8);
            if (operA(7) /= operB(7)) then
                if (operA(7) /= result(7)) then Overflow <= '1';
                    else Overflow <= '0';
                end if;
            else Overflow <= '0';
            end if;
        when OU =>
            result <= operA or operB;
        when E =>
            result <= operA and operB;
        when NAO =>
            result <= not operA;
        when CMP =>
				if cmp_enable = '1' then
					temp := ('0'&operA) - ('0'&operB);
					if (operA = operB) then
						Igual <= '1';
					else
						Igual <= '0';
					end if;
					Neg <= temp(7); -- sinal
					Carry <= temp(8); -- Flag Carry/Borrow
					if (operA(7) /= operB(7)) and (operA(7) /= temp(7)) then
						 Overflow <= '1'; 
					else
						 Overflow <= '0';
					end if;
				end if;
        when others =>
            result <= "00000000";
            Igual <= '0';
            Neg <= '0';
            Carry <= '0';
            Overflow <= '0';
            Borrow <= '0';
        end case;
        
        --Neg <= result(7);
		  if ula_enable = '1' then
			result_final <= result; --registrador R
			result_anterior <= result;
			else
		 result_final <= result_anterior;
		end if;
    end process computa;
	 result_output <= result_final;
	 
		 
END Behavioral;
