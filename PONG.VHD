----------------------------------------------------------------------------------
-- VGA Colour Cycle
-- Digital 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity VGATop is
  port(clk50  		: in std_logic;
		 rst    		: in std_logic;
		 rightBut1	: in std_logic;
		 leftBut1	: in std_logic;
		 rightBut2	: in std_logic;
		 leftBut2	: in std_logic;
       r      		: out std_logic;
       g      		: out std_logic;
       b      		: out std_logic;
       hSync  		: out std_logic;
       vSync  		: out std_logic);
end VGATop;

architecture RTL of VGATop is

-- Signals
signal clk25  : std_logic;
signal vidOn  : std_logic;
signal clkTick: std_logic;
signal clkCnt : std_logic_vector(24 downto 0);
signal colour : std_logic_vector(2 downto 0);
signal rgb    : std_logic_vector(2 downto 0);
signal row 	  : std_logic_vector(9 downto 0);
signal col    : std_logic_vector(9 downto 0);
signal rowInt : integer range 0 to 525;
signal colInt : integer range 0 to 800;

signal BallX  : integer range 0 to 639;
signal BallY  : integer range 0 to 479;

signal Ball1  : integer range 0 to 639;
signal Ball2  : integer range 0 to 479;
signal Ball3  : integer range 0 to 639;
signal Ball4  : integer range 0 to 479;

signal pongX  : integer range 0 to 639;
signal pongY : integer range 0 to 479;

signal pong1  : integer range 0 to 639;
signal pong2  : integer range 0 to 479;
signal pong3  : integer range 0 to 639;
signal pong4  : integer range 0 to 479;

signal pongA  : integer range 0 to 639;
signal pongB : integer range 0 to 479;



-- Components
component VGASync
	port(	clk	  :	in std_logic;
			rst	  :	in std_logic;
			hSync   :	out std_logic;
			vSync   :	out std_logic;
			row	  :	out std_logic_vector(9 downto 0);
			col	  :	out std_logic_vector(9 downto 0);
			vidOn   :	out std_logic
	);
end component VGASync;
	
begin

-- Create integer versions of the row and column trackers
rowInt <= to_integer(unsigned(row));
colInt <= to_integer(unsigned(col));

-- VGA synchronisation block
uVGASync: VGASync
	port map(
		clk 	=> clk25,
		rst 	=> rst,
		hSync => hSync,
		vSync => vSync,
		row	=> row,
		col	=>	col,
		vidOn	=> vidOn
   );
  
-- Generate a 25Mhz clock from a 50MHz clock
ClkGen : process (clk50, rst)
begin
	if(rst = '0') then
		clk25 <= '0';
   elsif(clk50'event and clk50='1') then
    clk25 <= not(clk25);
	 clkCnt<=std_logic_vector(unsigned(clkCnt)+1);
  end if;
end process;

clkTick <= clkCnt(17);

-- Change the 3-bit colour periodically
ColourGen : process (clk25, rst)
variable timeCnt : integer range 0 to 100000000 := 0;
variable colCnt  : integer range 0 to 7 := 0;
begin
	if(rst='0') then
		timeCnt := 0;
	elsif(clk25'event and clk25='1') then
		timeCnt := timeCnt + 1;
		if timeCnt = 50000000 then
			colCnt := colCnt + 1;
			timeCnt := 0;
		end if;
	end if;
	colour <= std_logic_vector(to_unsigned(colCnt, colour'length));
end process;

-- Track the pixel location and trace RGB values to the pixel
-- VGA Display 640 x 480: x is 0 -> 639, y is 0 -> 479
TraceXYPixels : process (clk25, rst, vidOn)
variable x: integer :=0; -- Row pixel
variable y: integer :=0; -- Column pixel
begin
	-- Create variables from the input signals
	x := colInt;
	y := rowInt;
	
	BallX <= 320;
	BallY <= 240;
	
	BallX <= Ball1;
	BallY <= Ball2;

	pongX <=270;
	pongY <= 50;
	
	pongA <=270;
	pongB <= 410;
	
	pongX <= pong1;
	pongY <= pong2;
	
	pongA <= pong3;
	pongB <= pong4;
	
	
	-- If reset, set default RGB values (black)
	if(rst='0') then
		rgb <= "000";
	elsif (x >=  pongX and x<= pongX+100 and y>=pongY and y<= pongY+ 5) then
		rgb <= "001";
	
	elsif (x >=  pongA and x<= pongA+100 and y>=pongB and y<= pongB+ 5 ) then
		rgb <= "010";
	
	elsif (x >= BallX and x<= BallX+ 10 and y>= BallY and y<= BallY+ 10) then
		rgb <= "100";
		
	elsif (x >= 0 and x<=640 and y>=0 and y<= 480) then
		rgb <= "000";
		
	
	end if;
end process;

Ball:process(clkTick,rst)
variable x: integer := 320;
variable y: integer := 240;

variable dX :integer := 0;
variable dY :integer := 0;

begin
	if(rst = '0')then
		x:= 320;
	elsif(clkTick'event and clkTick = '1') then
			if(dX =0) then
			x:=x+1;
				if(dY =0) then
				y:=y+1;
				else
				y:=y-1;
				end if;
			else
			 x := x-1;
				if(dY =0) then
				y:=y+1;
				else
				y:=y-1;
				end if;
			end if;
		if(x > 634)then
			dX := 1;
		elsif(x < 5)then
			dX := 0;
		end if;
		
		if(y > 400)then
			dY := 1;
		elsif(y < 50)then
			dY := 0;
		end if;
		Ball1 <= x;
		Ball2 <= y;
end if;	
end process;

MoveBat1:process(clkTick, rst, rightBut1, leftBut1)
variable x: integer := 270;
variable y: integer := 50;

begin
	if(rst = '0')then
		x := 320;
		elsif(clkTick'event and clkTick = '1')then
			if(rightBut1 ='1') then
			x := x+1;
			if(x > 520) then
			x := 520;
			end if;
			
			elsif(leftBut1 ='1') then
			x := x-1;
				if(x < 20) then
				x := 20;
			end if;
	else
		x := x;
	end if;
	pong1 <= x;
	pong2 <= y;
end if;
end process;

MoveBat2:process(clkTick, rst, rightBut2, leftBut2)
variable x: integer := 270;
variable y:integer := 410;

begin
	if(rst = '0')then
		x := 320;
		elsif(clkTick'event and clkTick = '1')then
			if(rightBut2 ='1') then
			 x := x+1;
			 if(x > 520) then
			 x := 520;
			 end if;
		elsif(leftBut2 ='1') then
			x := x-1;
			if(x < 20) then
			x := 20;
			end if;
		else
			x := x;
		end if;
		pong3 <= x;
		pong4 <= y;
	end if;
end process;



-- Drive outputs
r <= rgb(2) and vidOn;
g <= rgb(1) and vidOn;
b <= rgb(0) and vidOn;

end RTL;
