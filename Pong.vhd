----------------------------------------------------------------------------------
-- PONG 
-- 2 PLAYER PONG 
-- Tested on Alterra FPGA vis Quartus
-- This code was written for a computer monitor with a 1280 by 1024 resolution (60 fps)
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity VGAInterface is
    Port ( CLOCK_50: in  STD_LOGIC;
           VGA_R : out  STD_LOGIC_VECTOR (7 downto 0);
           VGA_G : out  STD_LOGIC_VECTOR (7 downto 0);
           VGA_B : out  STD_LOGIC_VECTOR (7 downto 0);
           VGA_HS : out  STD_LOGIC;
           VGA_VS : out  STD_LOGIC;
			  VGA_BLANK_N : out  STD_LOGIC;
			  VGA_CLK : out  STD_LOGIC;
			  VGA_SYNC_N : out  STD_LOGIC;
           KEY : in  STD_LOGIC_VECTOR (3 downto 0);
           SW : in  STD_LOGIC_VECTOR (17 downto 0);
--            HEX0 : out  STD_LOGIC_VECTOR (6 downto 0);
--            HEX1 : out  STD_LOGIC_VECTOR (6 downto 0);
--			  HEX2 : out  STD_LOGIC_VECTOR (6 downto 0);
--			  HEX3 : out  STD_LOGIC_VECTOR (6 downto 0);
			  HEX4 : out  STD_LOGIC_VECTOR (6 downto 0);
--			  HEX5 : out  STD_LOGIC_VECTOR (6 downto 0);
			  HEX6 : out  STD_LOGIC_VECTOR (6 downto 0);
--			  HEX7 : out  STD_LOGIC_VECTOR (6 downto 0);
			  LEDR : out  STD_LOGIC_VECTOR (17 downto 0);
			  LEDG : out  STD_LOGIC_VECTOR (8 downto 0));
end VGAInterface;

architecture Behavioral of VGAInterface is	
	component VGAFrequency is -- Altera PLL used to generate 108Mhz clock 
	PORT ( areset		: IN STD_LOGIC;
			 inclk0		: IN STD_LOGIC;
			 c0		: OUT STD_LOGIC ;
			 locked		: OUT STD_LOGIC);
	end component;
	
	component VGAController is -- Module declaration for the VGA controller
     Port ( PixelClock : in  STD_LOGIC;
           inRed : in STD_LOGIC_VECTOR (7 downto 0);
			  inGreen : in STD_LOGIC_VECTOR (7 downto 0);
			  inBlue : in STD_LOGIC_VECTOR (7 downto 0);
			  outRed : out STD_LOGIC_VECTOR (7 downto 0);
			  outGreen : out STD_LOGIC_VECTOR (7 downto 0);
			  outBlue : out STD_LOGIC_VECTOR (7 downto 0);
           VertSynchOut : out  STD_LOGIC;
           HorSynchOut : out  STD_LOGIC;
           XPosition : out  STD_LOGIC_VECTOR (10 downto 0);
           YPosition : out  STD_LOGIC_VECTOR (10 downto 0));
	end component;

	-- Variables for screen resolution 1280 x 1024
	signal XPixelPosition : STD_LOGIC_VECTOR (10 downto 0);	-- screen pixels
	signal YPixelPosition : STD_LOGIC_VECTOR (10 downto 0);
	
	signal redValue : STD_LOGIC_VECTOR (7 downto 0) := "00000000";  -- screen colors
	signal greenValue :STD_LOGIC_VECTOR (7 downto 0) := "00000000";
	signal blueValue : STD_LOGIC_VECTOR (7 downto 0) := "00000000";
	
	-- Freq Mul/Div signals (PLL I/O variables used to generate 108MHz clock)
	constant resetFreq : STD_LOGIC := '0';
	signal PixelClock: STD_LOGIC;
	signal lockedPLL : STD_LOGIC; -- dummy variable

	-- Variables used for displaying the white dot to screen for demo
	-- player 1
	signal XDotPosition : STD_LOGIC_VECTOR (10 downto 0) := "00011110000";
	signal YDotPosition : STD_LOGIC_VECTOR (10 downto 0) := "01000000000";
	-- Player 2 00011110000
	signal XDotPosition2 : STD_LOGIC_VECTOR (10 downto 0) := "10000010000";
	signal YDotPosition2 : STD_LOGIC_VECTOR (10 downto 0) := "01000000000";
	
	
	
	-- ball declaration
	signal XballPosition : STD_LOGIC_VECTOR (10 downto 0) := "01010000000";
	signal YballPosition : STD_LOGIC_VECTOR (10 downto 0) := "01000000000";
	
	type ball_state is (ld, lu, rd, ru,r,u);
	signal ps: ball_state := ld;
--	signal ns: ball_state;
	
	-- scores
	signal player1 : std_logic_vector (3 downto 0);
	signal player2 : std_logic_vector (3 downto 0);
	
	signal displayPosition : STD_LOGIC_VECTOR (10 downto 0) := "01000000000";
	
	-- Variables for slow clock counter to generate a slower clock
	signal slowClockCounter : STD_LOGIC_VECTOR (20 downto 0) := "000000000000000000000";
	signal ballclk : std_logic;
	signal slowClock : STD_LOGIC;
	
	-- Vertical and Horizontal Synch Signals
	signal HS : STD_LOGIC; -- horizontal synch
	signal VS : STD_LOGIC; -- vertical synch
	
	
	
begin
	process (CLOCK_50)-- control process for a large counter to generate a slow clock
	begin
		if CLOCK_50'event and CLOCK_50 = '1' then
			slowClockCounter <= slowClockCounter + 1;
		end if;
	end process;

	slowClock <= slowClockCounter(20); -- slow clock signal
	ballclk <= slowClockCounter(18);
	
	process (slowClock)-- move dot Y position    player 1
	begin
		if slowClock'event and slowClock = '1' then
			if KEY(0) = '0' then -- detect button 0 pressed
				YDotPosition <= YDotPosition - 20;
			elsif KEY(1) = '0' then-- detect button 1 pressed
				ydotposition <= ydotposition + 20;
			end if;
		end if;
	end process;
	
	process (slowClock)				-- move dot position		player 2
	begin
		if slowClock'event and slowClock = '1' then
			if KEY(2) = '0' then 	-- detect button 2 pressed
				YDotPosition2 <= YDotPosition2 - 20;
			elsif KEY(3) = '0' then	-- detect button 3 pressed
				YDotPosition2 <= YDotPosition2 + 20;
			end if;
		end if;
	end process;
	
	process (ballclk)
	variable tps : ball_state := ps;
	variable tplayer1 : std_logic_vector (3 downto 0);
	variable tplayer2 : std_logic_vector (3 downto 0);
	--variable xballposition: std_logic_vector (10 downto 0); -- variable would have to change all values to exact, in my opinion, I should have started with this, too late
	--variable yballposition: std_logic_vector (10 downto 0);
	begin
		if ballclk'event and ballClk = '1' then
			case	tps is 
				when ld =>  -- if statement inside
					yballposition <= yballposition - 1;	
					xballposition <= xballposition - 1;
					if(yballposition - 18 = 100) then -- visually at the top
						tps := lu;
						yballposition <= yballposition; -- not needed, the paddle isnt accurate enough
					end if;
					if (xballposition - 20 = xdotposition) then -- we are at the left paddle
						case tps is
							when ld => -- visually going up
								if((yballposition < (ydotposition - 78)) or ((yballposition - 19) > (ydotposition + 81))) then
									tplayer2 := tplayer2 + 1;
										XballPosition <= "01010000000";
										YballPosition <= "01000000000";
									case tplayer2 is
										when "0000" => hex6 <= "1000000";
										when "0001" => hex6 <= "1111001";
										when "0010" => hex6 <= "0100100";
										when "0011" => hex6 <= "0110000";
										when "0100" => hex6 <= "0011001";
										when "0101" => hex6 <= "0010010";
										when "0110" => hex6 <= "0000010";
										when "0111" => hex6 <= "1111000";
										when "1000" => hex6 <= "0000000";
										when "1001" => hex6 <= "0011000";
										when "1010" => hex6 <= "0001000";
										when "1011" => hex6 <= "0000011";
										when "1100" => hex6 <= "0000110";
										when "1101" => hex6 <= "0100001";
										when "1110" => hex6 <= "0000100";
										when "1111" => hex6 <= "0001110";
									end case;
								else
									tps := rd;
								end if;
							when lu => -- visually going down
								if((yballposition < (ydotposition - 80) ) or ((yballposition - 19) > (ydotposition + 79))) then
									tplayer2 := tplayer2 + 1;
									XballPosition <= "01010000000";
									YballPosition <= "01000000000";
									case tplayer2 is
										when "0000" => hex6 <= "1000000";
										when "0001" => hex6 <= "1111001";
										when "0010" => hex6 <= "0100100";
										when "0011" => hex6 <= "0110000";
										when "0100" => hex6 <= "0011001";
										when "0101" => hex6 <= "0010010";
										when "0110" => hex6 <= "0000010";
										when "0111" => hex6 <= "1111000";
										when "1000" => hex6 <= "0000000";
										when "1001" => hex6 <= "0011000";
										when "1010" => hex6 <= "0001000";
										when "1011" => hex6 <= "0000011";
										when "1100" => hex6 <= "0000110";
										when "1101" => hex6 <= "0100001";
										when "1110" => hex6 <= "0000100";
										when "1111" => hex6 <= "0001110";
									end case;
								else
									tps := ru;
								end if;
							when others => tps := r;
						end case;
					end if;
				when lu =>
					yballposition <= yballposition + 1;
					xballposition <= xballposition - 1;
					if(yballposition  = 899) then
						tps := ld;
						yballposition <= yballposition; -- the ball wont go into the boarder
					end if;
					if(xballposition - 20 = xdotposition) then
						case tps is		-- two lines ahead, if the lowest point of the ball is higher than the paddle then player2 scores
							when ld =>	-- the nextline, if the highest point of the ball is lower then the lowest point of the paddle then player 2 scores,
								if((yballposition < (ydotposition - 78)) or ((yballposition - 19) > (ydotposition + 81))) then
									tplayer2 := tplayer2 + 1;
									XballPosition <= "01010000000";
									YballPosition <= "01000000000";
									case tplayer2 is
										when "0000" => hex6 <= "1000000";
										when "0001" => hex6 <= "1111001";
										when "0010" => hex6 <= "0100100";
										when "0011" => hex6 <= "0110000";
										when "0100" => hex6 <= "0011001";
										when "0101" => hex6 <= "0010010";
										when "0110" => hex6 <= "0000010";
										when "0111" => hex6 <= "1111000";
										when "1000" => hex6 <= "0000000";
										when "1001" => hex6 <= "0011000";
										when "1010" => hex6 <= "0001000";
										when "1011" => hex6 <= "0000011";
										when "1100" => hex6 <= "0000110";
										when "1101" => hex6 <= "0100001";
										when "1110" => hex6 <= "0000100";
										when "1111" => hex6 <= "0001110";
									end case;
								else
									tps := rd;
								end if;
							when lu => 
								if((yballposition < (ydotposition - 80) ) or ((yballposition - 19) > (ydotposition + 79))) then
									tplayer2 := tplayer2 + 1;
									XballPosition <= "01010000000";
									YballPosition <= "01000000000";
									case tplayer2 is
										when "0000" => hex6 <= "1000000";
										when "0001" => hex6 <= "1111001";
										when "0010" => hex6 <= "0100100";
										when "0011" => hex6 <= "0110000";
										when "0100" => hex6 <= "0011001";
										when "0101" => hex6 <= "0010010";
										when "0110" => hex6 <= "0000010";
										when "0111" => hex6 <= "1111000";
										when "1000" => hex6 <= "0000000";
										when "1001" => hex6 <= "0011000";
										when "1010" => hex6 <= "0001000";
										when "1011" => hex6 <= "0000011";
										when "1100" => hex6 <= "0000110";
										when "1101" => hex6 <= "0100001";
										when "1110" => hex6 <= "0000100";
										when "1111" => hex6 <= "0001110";
									end case;
								else
									tps := ru;
								end if;
							when others => tps := r;
						end case;
					end if;
				when rd =>
					yballposition <= yballposition - 1;
					xballposition <= xballposition + 1;
					if(yballposition - 18 = 100) then
						tps := ru;
						yballposition <= yballposition;
					end if;
					if(xballposition = xdotposition2) then
						case tps is
							when rd =>
								if((yballposition < (ydotposition2 - 78)) or ((yballposition - 19) > (ydotposition2 + 81))) then
									tplayer1 := tplayer1 + 1;
									XballPosition <= "01010000000";
									YballPosition <= "01000000000";
									case tplayer2 is
										when "0000" => hex4 <= "1000000";
										when "0001" => hex4 <= "1111001";
										when "0010" => hex4 <= "0100100";
										when "0011" => hex4 <= "0110000";
										when "0100" => hex4 <= "0011001";
										when "0101" => hex4 <= "0010010";
										when "0110" => hex4 <= "0000010";
										when "0111" => hex4 <= "1111000";
										when "1000" => hex4 <= "0000000";
										when "1001" => hex4 <= "0011000";
										when "1010" => hex4 <= "0001000";
										when "1011" => hex4 <= "0000011";
										when "1100" => hex4 <= "0000110";
										when "1101" => hex4 <= "0100001";
										when "1110" => hex4 <= "0000100";
										when "1111" => hex4 <= "0001110";
									end case;
								else
									tps := ld;
								end if;
							when ru =>
								if((yballposition < (ydotposition2 - 80)) or ((yballposition -19) > (ydotposition2 + 79))) then
									tplayer1 := tplayer1 + 1;
									XballPosition <= "01010000000";
									YballPosition <= "01000000000";
									case tplayer2 is
										when "0000" => hex4 <= "1000000";
										when "0001" => hex4 <= "1111001";
										when "0010" => hex4 <= "0100100";
										when "0011" => hex4 <= "0110000";
										when "0100" => hex4 <= "0011001";
										when "0101" => hex4 <= "0010010";
										when "0110" => hex4 <= "0000010";
										when "0111" => hex4 <= "1111000";
										when "1000" => hex4 <= "0000000";
										when "1001" => hex4 <= "0011000";
										when "1010" => hex4 <= "0001000";
										when "1011" => hex4 <= "0000011";
										when "1100" => hex4 <= "0000110";
										when "1101" => hex4 <= "0100001";
										when "1110" => hex4 <= "0000100";
										when "1111" => hex4 <= "0001110";
									end case;
								else
									tps := lu;
								end if;
							when others => tps := r;
						end case;
					end if;
				when ru =>
					yballposition <= yballposition + 1;
					xballposition <= xballposition + 1;
					if(yballposition = 899) then
						tps := rd;
						yballposition <= yballposition;
					end if;
					if(xballposition = xdotposition2) then
						case tps is
							when rd =>
								if((yballposition < (ydotposition2 - 78)) or ((yballposition - 19) > (ydotposition2 + 81))) then
									tplayer1 := tplayer1 + 1;
									XballPosition <= "01010000000";
									YballPosition <= "01000000000";
									case tplayer2 is
										when "0000" => hex4 <= "1000000";
										when "0001" => hex4 <= "1111001";
										when "0010" => hex4 <= "0100100";
										when "0011" => hex4 <= "0110000";
										when "0100" => hex4 <= "0011001";
										when "0101" => hex4 <= "0010010";
										when "0110" => hex4 <= "0000010";
										when "0111" => hex4 <= "1111000";
										when "1000" => hex4 <= "0000000";
										when "1001" => hex4 <= "0011000";
										when "1010" => hex4 <= "0001000";
										when "1011" => hex4 <= "0000011";
										when "1100" => hex4 <= "0000110";
										when "1101" => hex4 <= "0100001";
										when "1110" => hex4 <= "0000100";
										when "1111" => hex4 <= "0001110";
									end case;
								else
									tps := ld;
								end if;
							when ru =>
								if((yballposition < (ydotposition2 - 80)) or ((yballposition -19) > (ydotposition2 + 79))) then
									tplayer1 := tplayer1 + 1;
									XballPosition <= "01010000000";
									YballPosition <= "01000000000";
									case tplayer2 is
										when "0000" => hex4 <= "1000000";
										when "0001" => hex4 <= "1111001";
										when "0010" => hex4 <= "0100100";
										when "0011" => hex4 <= "0110000";
										when "0100" => hex4 <= "0011001";
										when "0101" => hex4 <= "0010010";
										when "0110" => hex4 <= "0000010";
										when "0111" => hex4 <= "1111000";
										when "1000" => hex4 <= "0000000";
										when "1001" => hex4 <= "0011000";
										when "1010" => hex4 <= "0001000";
										when "1011" => hex4 <= "0000011";
										when "1100" => hex4 <= "0000110";
										when "1101" => hex4 <= "0100001";
										when "1110" => hex4 <= "0000100";
										when "1111" => hex4 <= "0001110";
									end case;
								else
									tps := lu;
								end if;
							when others => tps := r;
						end case;
					end if;
				when r => 
					xballposition <= xballposition + 1;
				when u =>
					yballposition <= yballposition + 1;
			end case;
			if sw(0) = '1' then
				XballPosition <= "01010000000";	--	center
				YballPosition <= "01000000000";	
				tps := ld;
			end if;
			if sw(1) = '1' then
				XballPosition <= "01010000000";
				YballPosition <= "00001110111"; -- 119 for ball
				tps := r;
			end if;
			if sw(3) = '1' then
				XballPosition <= "01010000000";
				YballPosition <= "00001111000"; -- 119 for ball
				tps := r;
			end if;
			if sw(2) = '1' then
				XballPosition <= "01010000000";
				YballPosition <= "01110000011"; -- 899 for ball
				tps := r;
			end if;
			ps <= tps;
			player1 <= tplayer1;
			player2 <= tplayer2;
		end if;
	end process;
	
	-- Generates a 108Mhz frequency for the pixel clock using the PLL (The pixel clock determines how much time there is between drawing one pixel at a time)
	VGAFreqModule : VGAFrequency port map (resetFreq, CLOCK_50, PixelClock, lockedPLL);
	
	-- Module generates the X/Y pixel position on the screen as well as the horizontal and vertical synch signals for monitor with 1280 x 1024 resolution at 60 frams per second
	VGAControl : VGAController port map (PixelClock, redValue, greenValue, blueValue, VGA_R, VGA_G, VGA_B, VS, HS, XPixelPosition, YPixelPosition);
	
	-- OUTPUT ASSIGNMENTS FOR VGA SIGNALS
	VGA_VS <= VS;
	VGA_HS <= HS;
	VGA_BLANK_N <= '1';
	VGA_SYNC_N <= '1';			
	VGA_CLK <= PixelClock;
	
	-- OUTPUT ASSIGNEMNTS TO SEVEN SEGMENT DISPLAYS
--	HEX0 <= "0000000"; -- display 8	player 1 score
--	HEX1 <= "1111000"; -- display 7	player 2 score
	
	-- COLOR ASSIGNMENT STATEMENTS
	process (PixelClock)-- MODIFY CODE HERE TO DISPLAY COLORS IN DIFFERENT REGIONS ON THE SCREEN
	begin
		if (XPixelPosition = XDotPosition AND YPixelPosition = YDotPosition) then
			redValue <= "11111111";
			blueValue <= "11111111";
			greenValue <= "11111111";
		elsif (XPixelPosition = XDotPosition2 AND YPixelPosition = YDotPosition2) then
			redValue <= "11111111"; 
			blueValue <= "11111111";
			greenValue <= "11111111";
		elsif (xPixelPosition = xballposition AND YPixelPosition = yballposition) then
			redvalue <= "00000000";
			greenValue <= "00000000";
			blueValue <= "11110000";
		else
			if (XPixelPosition < 160) then		-- GREEN left boarder
				redValue <= "00100010"; 
				greenValue <= "10110001";
				BLUEValue <= "00001100";
			elsif (xPixelPosition < xdotPosition - 10) then -- between left boarder and left paddle
				if (YPixelPosition < 100) then	-- majenta
					redValue <= "11110111"; 
					greenValue <= "00001011";
					BLUEValue <= "11111101";
				elsif ( YPixelPosition < 900) then -- black
					redValue <= "00000000"; 
					greenValue <= "00000000";
					BLUEValue <= "00000000";
				else -- majenta
					redValue <= "11110111"; 
					greenValue <= "00001011";
					BLUEValue <= "11111101";
				end if; -- end of in between left boarder and left paddle
			elsif (xPixelPosition < xdotPosition) then		-- left paddle  ** the y pixels are upsidedown
				if (YPixelPosition < 100) then	-- majenta	0 - 99 majenta
					redValue <= "11110111"; 
					greenValue <= "00001011";
					BLUEValue <= "11111101";		
				elsif (YPixelPosition < YdotPosition - 79) then	-- 79 below ydot and below that its black
					if(ypixelposition > 99) then						-- restrict the black to as low as 100
						redValue <= "00000000"; 
						greenValue <= "00000000";
						BLUEValue <= "00000000";
					end if;
				elsif (yPixelPosition <= YdotPosition + 80) then	-- the innerpaddle part 80 above ydot
					if (ypixelposition < 900) then -- don't let the paddle go past 899
						redValue <= "00000000"; 
						greenValue <= "00000000";
						BLUEValue <= "11111111";	
					end if;
				elsif ( YPixelPosition < 900) then
					if(ypixelposition > ydotPosition + 80) then -- 899 and below are black
						redValue <= "00000000"; 
						greenValue <= "00000000";
						BLUEValue <= "00000000";
					end if;
				elsif ( Ypixelposition < 1024) then -- majenta, "top" boarder
					if (ypixelposition >= 900) then
						redValue <= "11110111"; 
						greenValue <= "00001011";
						BLUEValue <= "11111101";		
					end if;
				end if;										-- end of left paddle
			elsif (xpixelposition < xdotposition2) then		-- between paddles
				if (xpixelposition < xballposition - 19) then -- between left paddle and left of ball
					if (xpixelposition > xdotposition) then			-- make sure doesnt go past left paddle
						if (YPixelPosition < 100) then	-- majenta	-- bottom boarder
							redValue <= "11110111"; 
							greenValue <= "00001011";
							BLUEValue <= "11111101";
						elsif ( YPixelPosition < 900) then -- black	between top and bottom boarder
							redValue <= "00000000"; 
							greenValue <= "00000000";
							BLUEValue <= "00000000";
						else -- majenta							-- top boarder
							redValue <= "11110111"; 
							greenValue <= "00001011";
							BLUEValue <= "11111101";
						end if;
					end if;
				elsif (xpixelposition <= xballposition) then	-- right of ball to left of ball
					if (YPixelPosition < 100) then	-- majenta	-- bottom boarder
						redValue <= "11110111"; 
						greenValue <= "00001011";
						BLUEValue <= "11111101";
					elsif ( YPixelPosition < 900) then -- black	between top and bottom boarder
						if(ypixelposition < yballposition - 19) then  	-- bottom ball to bottom boarder
							if (ypixelposition > 99) then					-- greater then top of bottom boarder
								redValue <= "00000000"; 
								greenValue <= "00000000";
								BLUEValue <= "00000000";
							end if;
						elsif (ypixelposition <= yballposition) then -- top of ball to bottom of ball
							redValue <= "11111111"; 
							greenValue <= "00000000";
							BLUEValue <= "00000000";
						else 											-- top of ball to bottom of top boarder
							redValue <= "00000000"; 
							greenValue <= "00000000";
							BLUEValue <= "00000000";
						end if;
					else -- majenta							-- bottom of top boarder to top of top boarder
						redValue <= "11110111"; 
						greenValue <= "00001011";
						BLUEValue <= "11111101";
					end if;
				else
					if (YPixelPosition < 100) then	-- majenta
						redValue <= "11110111"; 
						greenValue <= "00001011";
						BLUEValue <= "11111101";
					elsif ( YPixelPosition < 900) then -- black
						redValue <= "00000000"; 
						greenValue <= "00000000";
						BLUEValue <= "00000000";
					else -- majenta
						redValue <= "11110111"; 
						greenValue <= "00001011";
						BLUEValue <= "11111101";
					end if;
				end if;				-- end of in between paddles
			elsif (xpixelposition < xdotposition2 + 10) then-- right paddle		distance from paddles to paddle 1040 - 240 = 800
				if (YPixelPosition < 100) then	-- majenta  0 - 99 bottom boarder
					redValue <= "11110111"; 
					greenValue <= "00001011";
					BLUEValue <= "11111101";		
				elsif (YPixelPosition < YdotPosition2 - 79) then	-- below (79 pixels below ydot2) are black
					if(ypixelposition > 99) then	-- goes only as low as 100
						redValue <= "00000000"; 
						greenValue <= "00000000";
						BLUEValue <= "00000000";
					end if;
				elsif (yPixelPosition <= YdotPosition2 + 80) then -- 79 below ydot2 and 80 pixels above ydot2
					if (ypixelposition < 900) then		-- not to go into the bottom boarder
						redValue <= "00000000"; 
						greenValue <= "00000000";
						BLUEValue <= "11111111";	
					end if;
				elsif ( YPixelPosition <= 899) then -- black as far as 899 and below
					if(ypixelposition > ydotposition2 + 80) then
						redValue <= "00000000"; 
						greenValue <= "00000000";
						BLUEValue <= "00000000";
					end if;
				elsif (ypixelposition < 1024) then	-- majenta	-- otherwise majenta
					if(ypixelposition >= 900) then -- 900 and up are majenta
						redValue <= "11110111"; 
						greenValue <= "00001011";
						BLUEValue <= "11111101";		
					end if;
				end if;	-- end of right paddle
			elsif (XPixelPosition < 1120) then	-- BLACK		-- between right paddle and right boarder
				if (YPixelPosition < 100) then	-- majenta top of bottom boarder to bottom
					redValue <= "11110111"; 
					greenValue <= "00001011";
					BLUEValue <= "11111101";
				elsif ( YPixelPosition < 900) then -- black bottom of top boarder to top of bottom boarder
					redValue <= "00000000"; 
					greenValue <= "00000000";
					BLUEValue <= "00000000";
				else -- majenta							top of screen to bottom of top boarder
					redValue <= "11110111"; 
					greenValue <= "00001011";
					BLUEValue <= "11111101";
				end if;	-- end of right paddle and right boarder
			else	-- green right boarder
				redValue <= "00100010";
				greenValue <= "10110001";
				BLUEValue <= "01001100";
			end if;	
		end if;
	end process;
end Behavioral;

