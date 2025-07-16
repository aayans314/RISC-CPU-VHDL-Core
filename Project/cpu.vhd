-- Aayan Shah
-- CS 232 Spring 2025
-- Project7
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu is
	port (
        clk   : in  std_logic;                       -- main clock
        reset : in  std_logic;                       -- reset button

        PCview : out std_logic_vector( 7 downto 0);  -- debugging outputs
        IRview : out std_logic_vector(15 downto 0);
        RAview : out std_logic_vector(15 downto 0);
        RBview : out std_logic_vector(15 downto 0);
        RCview : out std_logic_vector(15 downto 0);
        RDview : out std_logic_vector(15 downto 0);
        REview : out std_logic_vector(15 downto 0);

        iport : in  std_logic_vector(7 downto 0);    -- input port
        oport : out std_logic_vector(15 downto 0)  -- output port
	);

end entity;

architecture rlt of cpu is
	-- defining the components that we will need
    component ProgramROM is 
        port (
            address : in  std_logic_vector(7 downto 0);
            clock   : in  std_logic;
            q       : out std_logic_vector(15 downto 0)
        );
    end component;

    component DataRAM is 
        port (
            address : in  std_logic_vector(7 downto 0);
            clock   : in  std_logic;
            data    : in  std_logic_vector(15 downto 0);
            wren    : in  std_logic;
            q       : out std_logic_vector(15 downto 0)
        );
    end component;

    component alu is
        port (
			srcA : in  unsigned(15 downto 0);         -- input A
			srcB : in  unsigned(15 downto 0);         -- input B
			op   : in  std_logic_vector(2 downto 0);  -- operation
			cr   : out std_logic_vector(3 downto 0);  -- condition outputs
			dest : out unsigned(15 downto 0));        -- output value

    end component;


	-- defining the states that we need
	type state_type is (Start, Fetch, ExcecuteSetup, ExecuteALU, ExecuteMemoryWait, ExecuteWrite, ExecuteReturnPause1, ExecuteReturnPause2, Halt);
	signal state : state_type;

	-- defining the internal signals needed
	signal OUTREG : std_logic_vector(15 downto 0);
	signal internal_counter : unsigned(2 downto 0);
	signal PC : unsigned(7 downto 0);
	signal IR : std_logic_vector(15 downto 0);
	signal SP : unsigned(15 downto 0);
	signal CR : std_logic_vector(3 downto 0);
	signal RA : std_logic_vector(15 downto 0);
	signal RB : std_logic_vector(15 downto 0);
	signal RC : std_logic_vector(15 downto 0);
	signal RD : std_logic_vector(15 downto 0); 
	signal RE : std_logic_vector(15 downto 0);
	signal MAR : unsigned(7 downto 0);
	signal MBR : std_logic_vector(15 downto 0);
	signal srcA : unsigned(15 downto 0);
	signal srcB : unsigned(15 downto 0);
	signal ALU_out : unsigned(15 downto 0);
	signal ALU_op : std_logic_vector(2 downto 0);
	signal ALU_con : std_logic_vector(3 downto 0);
	signal ROM_out : std_logic_vector(15 downto 0);
	signal RAM_out : std_logic_vector(15 downto 0);
	signal RAM_we : STD_LOGIC;

begin

	-- outputting the respective values to the RAM, ROM and ALU
	rom1 : ProgramRom port map(std_logic_vector(PC), clk, ROM_out);
	ram1 : DataRam port map(std_logic_vector(MAR), clk, MBR, RAM_we, RAM_out);
	alu1 : alu port map(srcA, srcB, ALU_op, ALU_con, ALU_out);

	-- mapping the internal signals to cpu output signals to later debug
	PCview <= std_logic_vector(PC);
	IRview <= IR;
	RAview <= RA;
	RBview <= RB;
	RCview <= RC;
	RDview <= RD;
	REview <= RE;
	oport <= OUTREG;

	-- main body that handles the state transitions based on the current instruction IR
	process (clk, reset)
	begin
		-- Reset conditions
		if reset = '0' then
			PC <= (others => '0');
			IR <= (others => '0');
			OUTREG <= (others => '0');
			MAR <= (others => '0');
			MBR <= (others => '0');
			RA <= (others => '0');
			RB <= (others => '0');
			RC <= (others => '0');
			RD <= (others => '0');
			RE <= (others => '0');
			SP <= (others => '0');
			CR <= (others => '0');
			internal_counter <= (others => '0');
			state <= Start;
		elsif (rising_edge(clk)) then
			-- State machine for instruction execution
			case state is
				-- wait 8 clock cycles before going to the Fetch state
				when Start =>
					internal_counter <= internal_counter + 1;
					if internal_counter = "111" then
						state <= Fetch;
						internal_counter <= (others => '0');
					end if;
				-- get the current instruction and increment PC by 1 before going to ExecuteSetup state
				when Fetch =>
					IR <= ROM_out;
					PC <= PC + 1;
					state <= ExcecuteSetup;
				-- handle the execution of the instruction based on the first 4 digits of the IR (opcode)
				when ExcecuteSetup =>
					ALU_op <= IR(14 downto 12);
					case IR(15 downto 12) is
						when "0000" =>
							if IR(11) = '1' then
								MAR <= unsigned(IR(7 downto 0)) + unsigned(RE(7 downto 0));
							else
								MAR <= unsigned(IR(7 downto 0));
							end if;
							state <= ExecuteALU;
						when "0001" => 
							if IR(11) = '1' then
								MAR <= unsigned(IR(7 downto 0)) + unsigned(RE(7 downto 0));
							else
								MAR <= unsigned(IR(7 downto 0));
							end if;
							case IR(10 downto 8) is
								when "000" =>
									MBR <= RA;
								when "001" =>
									MBR <= RB;
								when "010" =>
									MBR <= RC;
								when "011" =>
									MBR <= RD;
								when "100" =>
									MBR <= RE;
								when "101" =>
									MBR <= std_logic_vector(SP);
								when others=>
									null;
							end case;
							state <= ExecuteALU;
						when "0010" =>
							PC <= unsigned(IR(7 downto 0));
							state <= ExecuteALU;
						when "0011" =>
							case IR(11 downto 10) is
								when "00" =>
									case IR(9 downto 8) is
										when "00" =>
											if CR(0) = '1' then
												PC <= unsigned(IR(7 downto 0));
											end if;
										when "01" =>
											if CR(1) = '1' then
												PC <= unsigned(IR(7 downto 0));
											end if;
										when "10" =>
											if CR(2) = '1' then
												PC <= unsigned(IR(7 downto 0));
											end if;
										when others =>
											if CR(3) = '1' then
												PC <= unsigned(IR(7 downto 0));
											end if;
									end case;
									state <= ExecuteALU;
								when "01" =>
									PC <= unsigned(IR(7 downto 0));
									MAR <= SP(7 downto 0);
									SP <= SP + 1;
									MBR <= "0000" & CR & std_logic_vector(PC);
									state <= ExecuteALU;
								when "10" =>
									MAR <= SP(7 downto 0) - 1;
									SP <= SP - 1;
									state <= ExecuteALU;
								when "11" =>
									state <= Halt;
								when others =>
									state <= ExecuteALU;
									null;
							end case;
						when "0100" =>
							MAR <= SP(7 downto 0);
							SP <= SP + 1;
							case IR(11 downto 9) is
								when "000" =>
									MBR <= RA;
								when "001" =>
									MBR <= RB;
								when "010" =>
									MBR <= RC;
								when "011" =>
									MBR <= RD;
								when "100" =>
									MBR <= RE;
								when "101" =>
									MBR <= std_logic_vector(SP);
								when "110" =>
									MBR <= std_logic_vector(SP);
								when "111" =>
									MBR <= "000000000000" & CR;
								when others =>
									null;
							end case;
							state <= ExecuteALU;
						when "0101" =>
							MAR <= SP(7 downto 0) - 1;
							SP <= SP - 1;
							state <= ExecuteALU;
						when "1000" | "1001" | "1010" | "1011" | "1100" =>
							case IR(11 downto 9) is
								when "000" =>
									srcA <= unsigned(RA);
								when "001" =>
									srcA <= unsigned(RB);
								when "010" =>
									srcA <= unsigned(RC);
								when "011" =>
									srcA <= unsigned(RD);
								when "100" =>
									srcA <= unsigned(RE);
								when "101" =>
									srcA <= SP;
								when "110" =>
									srcA <= "0000000000000000";
								when "111" =>
									srcA <= "1111111111111111";
								when others =>
									null;
							end case;
							case IR(8 downto 6) is
								when "000" =>
									srcB <= unsigned(RA);
								when "001" =>
									srcB <= unsigned(RB);
								when "010" =>
									srcB <= unsigned(RC);
								when "011" =>
									srcB <= unsigned(RD);
								when "100" =>
									srcB <= unsigned(RE);
								when "101" =>
									srcB <= SP;
								when "110" =>
									srcB <= "0000000000000000";
								when "111" =>
									srcB <= "1111111111111111";
								when others =>
									null;
							end case;
							state <= ExecuteALU;
						when "1101" | "1110" =>
							case IR(10 downto 8) is
								when "000" =>
									srcA <= unsigned(RA);
								when "001" =>
									srcA <= unsigned(RB);
								when "010" =>
									srcA <= unsigned(RC);
								when "011" =>
									srcA <= unsigned(RD);
								when "100" =>
									srcA <= unsigned(RE);
								when "101" =>
									srcA <= SP;
								when "110" =>
									srcA <= "0000000000000000";
								when "111" =>
									srcA <= "1111111111111111";
								when others =>
									null;
							end case;
							srcB(0) <= IR(11);
							state <= ExecuteALU;
						when "1111" =>
							if IR(11) = '1' then
								srcA <= unsigned(IR(10) & IR(10) & IR(10) & IR(10) & IR(10) & IR(10) & IR(10) & IR(10) & IR(10 downto 3));
							else
								case IR(10 downto 8) is
									when "000" =>
										srcA <= unsigned(RA);
									when "001" =>
										srcA <= unsigned(RB);
									when "010" =>
										srcA <= unsigned(RC);
									when "011" =>
										srcA <= unsigned(RD);
									when "100" =>
										srcA <= unsigned(RE);
									when "101" =>
										srcA <= SP;
									when "110" =>
										srcA <= "00000000" & PC;
									when "111" =>
										srcA <= unsigned(IR);
									when others =>
										null;
								end case;
							end if;
							state <= ExecuteALU;
						when others =>
							state <= ExecuteALU;
							null;
					end case;
				-- either goto the ExecuteWrite state or ExecuteALU based on the opcode
				when ExecuteALU =>
					if IR(15 downto 12) = "0001" or IR(15 downto 12) = "0100" or IR(15 downto 10) = "001101" then
						RAM_we <= '1';
					end if;
					if IR(15 downto 12) = "0101" or IR(15 downto 12) = "0000" or IR(15 downto 10) = "001110" then
						state <= ExecuteMemoryWait;
					else
						state <= ExecuteWrite;
					end if;
				-- transition state that just exists to let the ROM catch up
				when ExecuteMemoryWait =>
					state <= ExecuteWrite;
				-- handle the writing of data based on the opcode
				when ExecuteWrite =>
					RAM_we <= '0';
					case IR(15 downto 12) is
						when "0000" => -- Load
							case IR(10 downto 8) is
								when "000" =>
									RA <= RAM_out;
								when "001" =>
									RB <= RAM_out;
								when "010" =>
									RC <= RAM_out;
								when "011" =>
									RD <= RAM_out;
								when "100" =>
									RE <= RAM_out;
								when "101" =>
									SP <= unsigned(RAM_out);
								when others =>
									null;
							end case;
							state <= Fetch;
						when "0011" =>
							case IR(11 downto 10) is
								when "10" =>
									PC <= unsigned(RAM_out(7 downto 0));
									CR <= RAM_out(11 downto 8);
									state <= ExecuteReturnPause1;
								when others =>
									state <= Fetch;
							end case;
						when "0101" =>
							case IR(11 downto 9) is
								when "000" =>
									RA <= RAM_out;
								when "001" =>
									RB <= RAM_out;
								when "010" =>
									RC <= RAM_out;
								when "011" =>
									RD <= RAM_out;
								when "100" =>
									RE <= RAM_out;
								when "101" =>
									SP <= unsigned(RAM_out);
								when "110" =>
									PC <= unsigned(RAM_out(7 downto 0));
								when others =>
									CR <= RAM_out(3 downto 0);
							end case;
							state <= Fetch;
						when "0110" =>
							case IR(11 downto 9) is
								when "000" =>
									OUTREG <= RA;
								when "001" =>
									OUTREG <= RB;
								when "010" =>
									OUTREG <= RC;
								when "011" =>
									OUTREG <= RD;
								when "100" =>
									OUTREG <= RE;
								when "101" =>
									OUTREG <= std_logic_vector(SP);
								when "110" =>
									OUTREG <= "00000000" & std_logic_vector(PC);
								when "111" =>
									OUTREG <= IR;
								when others =>
									null;
							end case;
							state <= Fetch;
						when "0111" =>
							case IR(11 downto 9) is
								when "000" =>
									RA(7 downto 0) <= iport;
								when "001" =>
									RB(7 downto 0) <= iport;
								when "010" =>
									RC(7 downto 0) <= iport;
								when "011" =>
									RD(7 downto 0) <= iport;
								when "100" =>
									RE(7 downto 0) <= iport;
								when "101" =>
									SP(7 downto 0) <= unsigned(iport);
								when others =>
									null;
							end case;
							state <= Fetch;
						when "1000" | "1001" | "1010" | "1011" | "1100" | "1101" | "1110" =>
							case IR(2 downto 0) is
								when "000" =>
									RA <= std_logic_vector(ALU_out);
								when "001" =>
									RB <= std_logic_vector(ALU_out);
								when "010" =>
									RC <= std_logic_vector(ALU_out);
								when "011" =>
									RD <= std_logic_vector(ALU_out);
								when "100" =>
									RE <= std_logic_vector(ALU_out);
								when "101" =>
									SP <= ALU_out;
								when others =>
									null;
							end case;
							CR <= ALU_con;
							state <= Fetch;
						when "1111" =>
							case IR(2 downto 0) is
								when "000" =>
									RA <= std_logic_vector(ALU_out);
								when "001" =>
									RB <= std_logic_vector(ALU_out);
								when "010" =>
									RC <= std_logic_vector(ALU_out);
								when "011" =>
									RD <= std_logic_vector(ALU_out);
								when "100" =>
									RE <= std_logic_vector(ALU_out);
								when "101" =>
									SP <= ALU_out;
								when others =>
									null;
							end case;
							CR <= ALU_con;
							state <= Fetch;
						when others =>
							null;
							state <= Fetch;
					end case;
				-- letting the RAM catch up
				when ExecuteReturnPause1 =>
					state <= ExecuteReturnPause2;
				-- letting the RAM catch up
				when ExecuteReturnPause2 =>
					state <= Fetch;
				-- stop everything and dont do anything until the user resets
				when Halt =>
					state <= Halt;
			end case;
		end if;
	end process;
end rlt;