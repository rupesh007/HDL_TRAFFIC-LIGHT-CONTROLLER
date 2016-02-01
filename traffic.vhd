library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;


entity traffic is 
port (
	clk, reset, cblink : in std_logic;     --input for the traffic light controller 
	hws, frs: in std_logic_vector (1 downto 0) --sensors input
);

end traffic;



architecture t_controller of traffic is 
--enumerated states
TYPE m_state IS (gr, rg, gr_to_yr, yr_to_rr, rr_to_ry, rg_to_ry, ry_to_rr,rr_to_yr,BLINK,INVALID);
TYPE t_light_color IS (blank, red, yellow, redyellow, green);

--Timer instantiation 
component timer is 
	port (
		clk, reset, t_en, tblink : in std_logic;
		timer_in : in std_logic_vector (1 downto 0);
		hw_sensor,fr_sensor : in std_logic_vector (1 downto 0);
		delay_notify: out std_logic;
		blank_out: out std_logic;
		timer_out : out std_logic_vector (5 downto 0)	
	); 

end component;


signal state: m_state;
signal highway_color, farmroad_color:t_light_color;
signal timer_enable: std_logic;
signal delay_request: std_logic_vector (1 downto 0);
signal delay_ack: std_logic;
signal bl_out: std_logic;
signal ticks_out: std_logic_vector (5 downto 0); --just to copy the ticks value to the output

begin 
 --port mapping
 
  Tm_con_map: timer port map(clk,reset,timer_enable,cblink,delay_request, hws,frs,delay_ack,bl_out,ticks_out);
 
PROCESS (clk,reset,cblink)
	begin
		if reset = '1' then
			state <= gr;
			timer_enable <= '1'; --request for delay
		elsif (clk'event and clk = '1') then 
			if (delay_ack = '1') then
				case state is
					when BLINK 	  => 		state <= gr;
					when gr       => 		state <= gr_to_yr;
					when gr_to_yr => 		state <= yr_to_rr;
					when yr_to_rr => 		state <= rr_to_ry;
					when rr_to_ry => 		state <= rg;					
					when rg       => 		state <= rg_to_ry;
					when rg_to_ry => 		state <= ry_to_rr;
					when ry_to_rr => 		state <= rr_to_yr;
					when rr_to_yr => 		state <= gr;
					when OTHERS   => 		state <= INVALID;
					
				end case;
			end if;
		elsif (cblink='1') then 
			state <= BLINK;
		end if;
	
END PROCESS;


PROCESS (clk)
	begin
		if (clk'event and clk = '1') then
			case state is 
				when gr => 	delay_request <= "00"; 			--requests for 30 sec delay
						highway_color <= green;
						farmroad_color <= red;
				when rg =>   	delay_request <= "01";		-- requests for 5 sec delay..also note the hw sens
						highway_color <= red;
						farmroad_color <= green;
				
				when BLINK => 	delay_request <= "11";									
					if (bl_out = '1') then		 	--this signal is toggled in timer module	
						highway_color <= blank;
						farmroad_color <= blank;
					else 	highway_color <= yellow;
						farmroad_color <= yellow;
					end if;
				when gr_to_yr =>  highway_color <= yellow;   --no timing consideration here
						  farmroad_color <= red;
				
				when yr_to_rr=>   delay_request <= "10";	--request for 2 sec delay
						  highway_color <= red;
						  farmroad_color <= red;
								  
				when rr_to_ry=>   highway_color <= red;
						  farmroad_color <= redyellow;
				
				when rg_to_ry=>   highway_color <= red;
						  farmroad_color <= yellow;
				
				when ry_to_rr=>   delay_request <= "10";
						  highway_color <= red;
						  farmroad_color <= red;
				
				when rr_to_yr=>   highway_color <= redyellow;
						  farmroad_color <= red;
				
				when OTHERS =>   highway_color <= blank;
						 farmroad_color <= blank;
			end case;
		end if;
END PROCESS;

END t_controller;
