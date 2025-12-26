----------------------------------------------------------------------------------
-- Company: maniek86.xyz
-- Engineer: Piotr Grzesik
-- 
-- Create Date:    19:21:33 11/27/2025 
-- Design Name: 
-- Module Name:    CMOS - Behavioral 
-- Project Name: Hamster 1 chipset
-- Target Devices: M8SBC-486 REV 1.0
-- Tool versions: 
-- Description: Simple CMOS RTC (non volatile) implementation
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
USE IEEE.NUMERIC_STD.ALL;

ENTITY CMOS IS
	PORT (
		CLK_IN	: IN	STD_LOGIC;
		DATA_IN	: IN	STD_LOGIC_VECTOR(7 downto 0);
		DATA_OUT	: OUT	STD_LOGIC_VECTOR(7 downto 0);
		CMOS_CS	: IN	STD_LOGIC;
		WR			: IN	STD_LOGIC;
		RD			: IN	STD_LOGIC;
		A0			: IN	STD_LOGIC;
		
		CLK_PIT	: IN	STD_LOGIC
	);
END CMOS;

ARCHITECTURE Behavioral OF CMOS IS
	-- Clock divider counter
	SIGNAL PIT_DIVIDER	: INTEGER RANGE 0 TO 1193182 := 0;
	SIGNAL TICK_1HZ		: STD_LOGIC := '0';
	
    -- Time Registers
	SIGNAL SECONDS	: INTEGER RANGE 0 TO 60 := 0;
	SIGNAL MINUTES	: INTEGER RANGE 0 TO 60 := 0;
	SIGNAL HOURS	: INTEGER RANGE 0 TO 24 := 0;
	SIGNAL WEEKDAY	: INTEGER RANGE 0 TO 8 := 7; -- 1-7 (Sun-Sat)
	SIGNAL DAY		: INTEGER RANGE 0 TO 32 := 1;
	SIGNAL MONTH	: INTEGER RANGE 0 to 13 := 11;
	SIGNAL YEAR		: INTEGER RANGE 0 TO 100 := 25;
	SIGNAL CENTURY	: INTEGER RANGE 0 TO 99 := 20;
	
	-- Helper signal for calendar logic
	SIGNAL MAX_DAYS_IN_MONTH : INTEGER RANGE 28 TO 31;
	SIGNAL IS_LEAP_YEAR      : BOOLEAN;
	
	SIGNAL CURRENT_REGISTER		: STD_LOGIC_VECTOR(7 downto 0) := x"00";
	
BEGIN

	PROCESS(CLK_IN)
		VARIABLE DATA_OUT_FINAL		: STD_LOGIC_VECTOR(7 downto 0);
	BEGIN
		DATA_OUT_FINAL := x"00";
		IF WR = '0' THEN -- Write
			IF FALLING_EDGE(CLK_IN) THEN
				IF (A0 = '0') THEN -- 0x70
					-- Cmos register
					CURRENT_REGISTER <= DATA_IN;
				END IF;
			END IF;			
		ELSIF RD = '0' THEN -- Read
			IF (A0 = '0') THEN -- 0x70
				DATA_OUT_FINAL := CURRENT_REGISTER;
			END IF;
			IF (A0 = '1') THEN -- 0x71
				CASE CURRENT_REGISTER IS
					WHEN x"00" => -- Seconds
						DATA_OUT_FINAL := std_logic_vector(to_unsigned(SECONDS, 8));
					WHEN x"02" => -- Minutes
						DATA_OUT_FINAL := std_logic_vector(to_unsigned(MINUTES, 8));
					WHEN x"04" => -- Hours
						DATA_OUT_FINAL := std_logic_vector(to_unsigned(HOURS, 8));
					WHEN x"06" => -- Weekday
						DATA_OUT_FINAL := std_logic_vector(to_unsigned(WEEKDAY, 8));
					WHEN x"07" => -- Day of month
						DATA_OUT_FINAL := std_logic_vector(to_unsigned(DAY, 8));
					WHEN x"08" => -- Month
						DATA_OUT_FINAL := std_logic_vector(to_unsigned(MONTH, 8));
					WHEN x"09" => -- Year
						DATA_OUT_FINAL := std_logic_vector(to_unsigned(YEAR, 8));
					WHEN x"32" => -- Century
						DATA_OUT_FINAL := std_logic_vector(to_unsigned(CENTURY, 8));
					WHEN x"0A" => -- Status register A
						-- STATUS REGISTER A (Offset 0x0A)
						-- Bit 7 (UIP): '0' -> Update NOT in progress (Always safe to read)
						-- Bits 6-4 (Div): '010' -> 32.768kHz reference (Standard)
						-- Bits 3-0 (Rate): '0110' -> 1kHz interrupt rate (Standard)
						-- Result: 00100110
						DATA_OUT_FINAL := "00100110";
					WHEN x"0B" => -- Status register B
						-- Bit 7 (SET): '0' -> Running normal
						-- Bit 2 (DM):  '1' -> BINARY MODE (Crucial! because we output std_logic_vector of integer)
						-- Bit 1 (24/12): '1' -> 24 Hour Format
						-- Result: 00000110 
						DATA_OUT_FINAL := "00000110";
						
					WHEN OTHERS =>
						DATA_OUT_FINAL := x"00";
				END CASE;
			END IF;
		ELSE
			DATA_OUT_FINAL := x"00";
		END IF;
		
		DATA_OUT <= DATA_OUT_FINAL; -- def
		
	END PROCESS;

	-- 1. Frequency Divider Process
	-- Assumes CLK_PIT is approx 1.1931818 MHz. 
	-- Generates a single cycle pulse (TICK_1HZ) every second.
	PROCESS(CLK_PIT)
	BEGIN
		IF rising_edge(CLK_PIT) THEN
			IF PIT_DIVIDER >= 1193181 THEN 
				PIT_DIVIDER <= 0;
				TICK_1HZ <= '1';
			ELSE
				PIT_DIVIDER <= PIT_DIVIDER + 1;
				TICK_1HZ <= '0';
			END IF;
		END IF;
	END PROCESS;

	-- 2. Leap Year Calculation
	-- A year is leap if divisible by 4.
	-- (Simplified logic: Since YEAR is 0-99, checking last 2 bits = 00 covers mod 4)
	IS_LEAP_YEAR <= (YEAR rem 4 = 0);

	-- 3. Max Days in Month Logic
	PROCESS(MONTH, IS_LEAP_YEAR)
	BEGIN
		CASE MONTH IS
			WHEN 4 | 6 | 9 | 11 => -- April, June, Sept, Nov
				MAX_DAYS_IN_MONTH <= 30;
			WHEN 2 =>              -- February
				IF IS_LEAP_YEAR THEN
					MAX_DAYS_IN_MONTH <= 29;
				ELSE
				MAX_DAYS_IN_MONTH <= 28;
				END IF;
			WHEN OTHERS =>         -- Jan, Mar, May, Jul, Aug, Oct, Dec
				MAX_DAYS_IN_MONTH <= 31;
		END CASE;
	END PROCESS;

	-- 4. Main Time-Keeping Process
	PROCESS(CLK_PIT)
	BEGIN
		IF rising_edge(CLK_PIT) THEN
			IF TICK_1HZ = '1' THEN
				-- Increment Seconds
				IF SECONDS >= 59 THEN
					SECONDS <= 0;

					-- Increment Minutes
					IF MINUTES >= 59 THEN
						MINUTES <= 0;

						-- Increment Hours
						IF HOURS >= 23 THEN
							HOURS <= 0;

							-- Increment Weekday (1-7)
							IF WEEKDAY >= 7 THEN
								WEEKDAY <= 1;
							ELSE
								WEEKDAY <= WEEKDAY + 1;
							END IF;

							-- Increment Day/Month/Year
							IF DAY >= MAX_DAYS_IN_MONTH THEN
								DAY <= 1;

								-- Increment Month
								IF MONTH >= 12 THEN
									MONTH <= 1;

									-- Increment Year
									IF YEAR >= 99 THEN
										YEAR <= 0;
										CENTURY <= CENTURY + 1;
									ELSE
										YEAR <= YEAR + 1;
									END IF;
								ELSE
									MONTH <= MONTH + 1;
								END IF;
							ELSE
								DAY <= DAY + 1;
							END IF; -- End Day check

						ELSE
							HOURS <= HOURS + 1;
						END IF; -- End Hours check
					ELSE
						MINUTES <= MINUTES + 1;
					END IF; -- End Minutes check
				ELSE
					SECONDS <= SECONDS + 1;
				END IF; -- End Seconds check
			END IF; -- End Tick check
		END IF;
	END PROCESS;

END BEHAVIORAL;

