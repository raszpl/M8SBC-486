----------------------------------------------------------------------------------
-- Company: maniek86.xyz
-- Engineer: Piotr Grzesik
-- 
-- Create Date:    23:21:17 10/14/2025 
-- Design Name: 
-- Module Name:    isa_driver - Behavioral 
-- Project Name: Hamster 1 chipset
-- Target Devices: M8SBC-486 REV 1.0
-- Tool versions: 
-- Description: 8 and 16-bit ISA driver
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

ENTITY isa_driver IS
	PORT (
		CLK				: IN	STD_LOGIC;
		RESET				: IN	STD_LOGIC;
		ADS				: IN	STD_LOGIC;
		RW					: IN  STD_LOGIC;
		MIO				: IN	STD_LOGIC;
		EN_ISA			: IN  STD_LOGIC; -- negated
		
		WAITSTATE_16C	: IN	INTEGER RANGE 0 to 15; -- From ADS to check 16B signals
		WAITSTATE_END	: IN  INTEGER RANGE 0 to 127; -- From check to end of transfer
		
		ISA_MEMCS16		: IN		STD_LOGIC;
		ISA_IOCS16		: IN		STD_LOGIC;
		ISA_IO_READY	: IN		STD_LOGIC; -- Input from ISA
		
		ISA_RDY			: OUT	STD_LOGIC; -- Output from driver
		ISA_MEM_WR		: OUT	STD_LOGIC;
		ISA_MEM_RD		: OUT	STD_LOGIC;
		ISA_IO_WR		: OUT	STD_LOGIC;
		ISA_IO_RD		: OUT	STD_LOGIC;
		
		BS8_O				: OUT	STD_LOGIC;
		BS16_O			: OUT	STD_LOGIC;
		
		ISA_SBHE			: OUT STD_LOGIC
	);
END ISA_DRIVER;

ARCHITECTURE behavioral OF isa_driver IS

	TYPE drv_state_type IS (st1_wait_for_ads, st2_check_16b, st3_wait_state); 
   SIGNAL drv_state, drv_next_state 		: drv_state_type; 
	
	SIGNAL RDY_I			: STD_LOGIC;
	SIGNAL ISA_16B_I		: STD_LOGIC;
	
	SIGNAL WAITSTATE_16C_total : INTEGER RANGE 0 to 127 := 0;
	SIGNAL WAITSTATE_END_total : INTEGER RANGE 0 to 127 := 0;
	
	SIGNAL WS_COUNT		: INTEGER RANGE 0 to 127 := 0;
	
	SIGNAL LAST_CS		: STD_LOGIC := '1';
	SIGNAL EXTRA_WS	: STD_LOGIC := '0';
	CONSTANT NCOUNT	: INTEGER := 2;
	CONSTANT NACTIVE	: STD_LOGIC := '1';
BEGIN


	SYNC_PROC: PROCESS (CLK, MIO)
   BEGIN
      IF(RISING_EDGE(CLK)) THEN
         IF (RESET = '1') THEN
            drv_state <= st1_wait_for_ads;
            -- reset output
				WS_COUNT <= 0;
				WAITSTATE_16C_total <= 0;
				WAITSTATE_END_total <= 0;
				
				EXTRA_WS <= '0';
				LAST_CS <= '1';
				
				RDY_I <= '0'; -- flip flop
				ISA_16B_I <= '0'; -- 0 is 8 bit, 1 is 16 bit
         ELSE
			
				IF drv_state = st1_wait_for_ads THEN
					
					IF (LAST_CS /= EN_ISA) AND (NACTIVE = '1') THEN
						EXTRA_WS <= '1';
						WAITSTATE_16C_total <= WAITSTATE_16C + NCOUNT;
						WAITSTATE_END_total <= WAITSTATE_END + NCOUNT;
					ELSE 
						EXTRA_WS <= '0';
						WAITSTATE_16C_total <= WAITSTATE_16C;
						WAITSTATE_END_total <= WAITSTATE_END;
					END IF;
				
					IF drv_next_state = st2_check_16b THEN -- on toggle from s1 to s2
						RDY_I <= '1';
					ELSE -- default low
						RDY_I <= '0';
					END IF;
				ELSE
					IF drv_next_state = st1_wait_for_ads THEN -- default on no transfer
						RDY_I <= '0'; 
						ISA_16B_I <= '0';
					END IF;
				END IF;
				
				IF drv_state = st2_check_16b THEN
					IF drv_next_state = st3_wait_state THEN -- on switch from st2 to st3 (cs16 check to rd/wr pull)
						-- 0 = IO, 1 = MEM
						IF MIO = '1' THEN -- mem
							IF ISA_MEMCS16 = '0' THEN
								ISA_16B_I <= '1'; -- 16 bit MEM transfer
							END IF;
						ELSE -- io
							IF ISA_IOCS16 = '0' THEN
								ISA_16B_I <= '1'; -- 16 bit IO transfer
							END IF;
						END IF;
					END IF;
				END IF;
				
			
				
				drv_state <= drv_next_state;
				
				
				IF drv_state /= st1_wait_for_ads THEN
					WS_COUNT <= WS_COUNT + 1;
				ELSE 
					WS_COUNT <= 0;
				END IF;
				
				LAST_CS <= EN_ISA;
				
         END IF;        
      END IF;
   END PROCESS;
	
	OUTPUT_DECODE: PROCESS (drv_state, drv_next_state, RW, MIO, WS_COUNT, ISA_16B_I) -- RW: 0 - read, 1 - write
		VARIABLE	RD		: STD_LOGIC;
		VARIABLE	WR		: STD_LOGIC;
		VARIABLE allow_drive : STD_LOGIC;
   BEGIN
      --insert statements to decode internal output signals
		RD := '1';
		WR := '1';
		ISA_MEM_WR <= '1';
		ISA_MEM_RD <= '1';
		ISA_IO_WR <= '1';
		ISA_IO_RD <= '1';
		ISA_SBHE <= '1';
		BS8_O <= '1';
		BS16_O <= '1';
		
		IF EXTRA_WS = '1' THEN
			IF WS_COUNT >= NCOUNT THEN
				allow_drive := '1';
			ELSE 
				allow_drive := '0';
			END IF;
		ELSE 
			allow_drive := '1';
		END IF;
		
		IF (drv_state = st2_check_16b) AND (allow_drive = '1') THEN
			ISA_SBHE <= '0'; -- in case device needs SBHE before pulling cs16
		END IF;
		
      IF (drv_state = st3_wait_state) AND (allow_drive = '1') THEN
         IF RW = '1' THEN -- write
				WR := '0';
			ELSE -- read
				RD := '0'; 
			END IF;
			
			-- 0 = IO, 1 = MEM
			IF MIO = '1' THEN
				ISA_MEM_WR <= WR;
				ISA_MEM_RD <= RD;
			ELSE

				ISA_IO_WR <= WR;

				ISA_IO_RD <= RD;
			END IF;
			
			-- "BS16 / BS8 must be driven active before the first RDY or BRDY is driven active"
			-- so we should be able to indicate 8/16 bit transfer even after ADS
			
			IF ISA_16B_I = '1' THEN -- 16 bit transfer
				ISA_SBHE <= '0'; -- keep 
				BS16_O <= '0';
			ELSE 
				ISA_SBHE <= '1'; -- deassert
				BS8_O <= '0';
			END IF;
			
		ELSE -- not S2
			ISA_MEM_WR <= '1';
			ISA_MEM_RD <= '1';
			ISA_IO_WR <= '1';
			ISA_IO_RD <= '1';
      END IF;
	
   END PROCESS;
	
	NEXT_STATE_DECODE: PROCESS(drv_state, ADS, EN_ISA, WS_COUNT, WAITSTATE_16C_total, WAITSTATE_END_total)
   BEGIN
      --declare default state for next_state to avoid latches
      drv_next_state <= drv_state;  -- default is to stay in current state

		-- ISA_16B_I

      CASE (drv_state) IS
         WHEN st1_wait_for_ads => -- Transfer begin, When ADS is 0 and RAMCS and 0 we activate
            IF (ADS = '0') AND (EN_ISA = '0') THEN
               drv_next_state <= st2_check_16b;
            END IF;
				
         WHEN st2_check_16b => -- Before pulling RD/WR
				IF EN_ISA = '1' THEN
					drv_next_state <= st1_wait_for_ads; -- ISA CS for some reason deasserted
				ELSE 
					IF ((ADS = '1') AND (WS_COUNT >= WAITSTATE_16C_total)) THEN -- Check 16b signals
						drv_next_state <= st3_wait_state;
					END IF;
				END IF;
				
			WHEN st3_wait_state => -- RD/WR pulled, waistate wait
				IF EN_ISA = '1' THEN
					drv_next_state <= st1_wait_for_ads; -- ISA CS for some reason deasserted
				ELSE 
					IF ((ADS = '1') AND (WS_COUNT >= WAITSTATE_END_total)) THEN -- end
						drv_next_state <= st1_wait_for_ads;
					END IF;
				END IF;

         WHEN OTHERS =>
            drv_next_state <= st1_wait_for_ads;
      END CASE;      
   END PROCESS;
	
	-- ISA_RDY - output from driver
	-- ISA_IO_READY - input from ISA
	-- RDY 1 = wait, 0 = ready
	
	-- ISA_IO_READY overrides our RDY, if ISA device wait, we should wait too 
	ISA_RDY <= RDY_I WHEN ISA_IO_READY = '1' ELSE '1'; 



END BEHAVIORAL;

