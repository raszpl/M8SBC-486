----------------------------------------------------------------------------------
-- Company: maniek86.xyz
-- Engineer: Piotr Grzesik
-- 
-- Create Date:    00:33:27 10/04/2025 
-- Design Name: 
-- Module Name:    clock_section_isa - Behavioral 
-- Project Name: Hamster 1 chipset
-- Target Devices: M8SBC-486 REV 1.0
-- Tool versions: 
-- Description: Clock divider for ISA CLK signal
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
LIBRARY UNISIM;
USE UNISIM.VCOMPONENTS.ALL;



ENTITY clock_section_isa IS
	PORT (
		CLK_INPUT	: IN  STD_LOGIc;  -- 14.318 MHz in
		CLK_OUT		: OUT STD_LOGIC   -- 7.159 MHz out (/2)
	);
END clock_section_isa;

ARCHITECTURE Behavioral OF clock_section_isa IS
	--CONSTANT		divider		: INTEGER := 1; -- equal divider (1 is /4)... bs!
	--SIGNAL		count			: INTEGER RANGE 0 TO divider := 0;
	SIGNAL		out_state	: STD_LOGIC := '0';
BEGIN
	PROCESS (CLK_INPUT)
	BEGIN
		IF RISING_EDGE(CLK_INPUT) THEN
			out_state <= NOT out_state;
			--IF count >= divider THEN
			--	count <= 0;
			--	out_state <= NOT out_state;
			--ELSE 
			--	count <= count + 1;
			--END IF;
		END IF;
	END PROCESS;
	
	CLK_OUT <= out_state;
END Behavioral;

