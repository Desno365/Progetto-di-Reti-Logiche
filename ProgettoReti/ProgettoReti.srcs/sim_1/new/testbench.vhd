library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity project_tb is
end project_tb;

architecture projecttb of project_tb is

	constant c_CLOCK_PERIOD			: time := 100 ns;
	signal   tb_done				: std_logic;
	signal   mem_address			: std_logic_vector (15 downto 0) := (others => '0');
	signal   tb_rst					: std_logic := '0';
	signal   tb_start				: std_logic := '0';
	signal   tb_clk					: std_logic := '0';
	signal   mem_o_data,mem_i_data	: std_logic_vector (7 downto 0); -- mem output data, mem input data
	signal   enable_wire			: std_logic; -- mem enable
	signal   mem_we					: std_logic; -- mem write enable


	-- Dichiarazione RAM
	type ram_type is array (65535 downto 0) of std_logic_vector(7 downto 0);
    signal count : integer := 0;
    signal ram_set : std_logic := '0';

	-- Inizializzazione RAM come da esempio su specifica
	signal RAM: ram_type := (0 => std_logic_vector(to_unsigned( 185 , 8)),
							 1 => std_logic_vector(to_unsigned( 75 , 8)),
							 2 => std_logic_vector(to_unsigned( 32 , 8)),
							 3 => std_logic_vector(to_unsigned( 111 , 8)),
							 4 => std_logic_vector(to_unsigned( 213 , 8)),
							 5 => std_logic_vector(to_unsigned( 79 , 8)),
							 6 => std_logic_vector(to_unsigned( 33 , 8)),
							 7 => std_logic_vector(to_unsigned( 1 , 8)),
							 8 => std_logic_vector(to_unsigned( 33 , 8)),
							 9 => std_logic_vector(to_unsigned( 80 , 8)),
							 10 => std_logic_vector(to_unsigned( 35 , 8)),
							 11 => std_logic_vector(to_unsigned( 12 , 8)),
							 12 => std_logic_vector(to_unsigned( 254 , 8)),
							 13 => std_logic_vector(to_unsigned( 215 , 8)),
							 14 => std_logic_vector(to_unsigned( 78 , 8)),
							 15 => std_logic_vector(to_unsigned( 211 , 8)),
							 16 => std_logic_vector(to_unsigned( 121 , 8)),
							 17 => std_logic_vector(to_unsigned( 78 , 8)),
							 18 => std_logic_vector(to_unsigned( 33 , 8)),
				 others => (others =>'0'));


	-- Componente da sintetizzare per il progetto
	component project_reti_logiche is
	port (
		  i_clk         : in  std_logic; -- Clock
		  i_start       : in  std_logic; -- Il modulo partirà nella elaborazione quando il segnale START in ingresso verrà portato a 1. Il segnale di START rimarrà alto fino a che il segnale di DONE non verrà portato alto;
		  i_rst         : in  std_logic; -- Inizializza la macchina pronta per ricevere il primo segnale di start
		  i_data        : in  std_logic_vector(7 downto 0); -- Segnale che arriva dalla memoria dopo richiesta di lettura
		  o_address     : out std_logic_vector(15 downto 0); -- Indirizzo da mandare alla memoria, all'indirizzo 0 ho i primi 8 bit, all'indirizzo 1 altri 8 bit e così via
		  o_done        : out std_logic; -- Notifica la fine dell’elaborazione. Il segnale DONE deve rimanere alto fino a che il segnale di START non è riportato a 0.
		  o_en          : out std_logic; -- Segnale di Enable da mandare alla memoria per poter comunicare (sia in lettura che in scrittura)
		  o_we          : out std_logic; -- Write Enable. 1 per scrivere. 0 per leggere
		  o_data        : out std_logic_vector (7 downto 0) -- Segnale da mandare alla memoria
		  );
	end component project_reti_logiche;


	-- Collegamenti segnali testbench con componente
	begin
	UUT: project_reti_logiche
	port map (
			  i_clk      	=> tb_clk,
			  i_start       => tb_start,
			  i_rst      	=> tb_rst,
			  i_data    	=> mem_o_data, -- l'ouput della memoria è dato come ingresso al componente
			  o_address  	=> mem_address,
			  o_done      	=> tb_done,
			  o_en   		=> enable_wire,
			  o_we 			=> mem_we,
			  o_data    	=> mem_i_data -- l'ouput del componente è dato come ingresso alla memoria
			  );


	-- Processo per generazione Clock
	p_CLK_GEN : process is
	begin
		wait for c_CLOCK_PERIOD/2;
		tb_clk <= not tb_clk;
	end process p_CLK_GEN;


	-- Processo per gestione memoria
    MEM : process(tb_clk)
    begin
        if tb_clk'event and tb_clk = '1' then
            if(tb_rst = '1' or ram_set = '1') then
                mem_o_data <= mem_i_data after 2 ns;
                if(count = 0) then
                    count <= 1;
                elsif(count = 1) then
                    RAM <= (0 => std_logic_vector(to_unsigned( 185 , 8)),
                            1 => std_logic_vector(to_unsigned( 75 , 8)),
                            2 => std_logic_vector(to_unsigned( 32 , 8)),
                            3 => std_logic_vector(to_unsigned( 111 , 8)),
                            4 => std_logic_vector(to_unsigned( 213 , 8)),
                            5 => std_logic_vector(to_unsigned( 79 , 8)),
                            6 => std_logic_vector(to_unsigned( 33 , 8)),
                            7 => std_logic_vector(to_unsigned( 1 , 8)),
                            8 => std_logic_vector(to_unsigned( 33 , 8)),
                            9 => std_logic_vector(to_unsigned( 80 , 8)),
                            10 => std_logic_vector(to_unsigned( 35 , 8)),
                            11 => std_logic_vector(to_unsigned( 12 , 8)),
                            12 => std_logic_vector(to_unsigned( 254 , 8)),
                            13 => std_logic_vector(to_unsigned( 215 , 8)),
                            14 => std_logic_vector(to_unsigned( 78 , 8)),
                            15 => std_logic_vector(to_unsigned( 78 , 8)),
                            16 => std_logic_vector(to_unsigned( 37 , 8)),
                            17 => std_logic_vector(to_unsigned( 78 , 8)),
                            18 => std_logic_vector(to_unsigned( 33 , 8)),
                            others => (others =>'0'));
                    count <= 2;
                elsif(count = 2) then
                    RAM <= (0 => std_logic_vector(to_unsigned( 0 , 8)),
                            1 => std_logic_vector(to_unsigned( 75 , 8)),
                            2 => std_logic_vector(to_unsigned( 32 , 8)),
                            3 => std_logic_vector(to_unsigned( 111 , 8)),
                            4 => std_logic_vector(to_unsigned( 213 , 8)),
                            5 => std_logic_vector(to_unsigned( 79 , 8)),
                            6 => std_logic_vector(to_unsigned( 33 , 8)),
                            7 => std_logic_vector(to_unsigned( 1 , 8)),
                            8 => std_logic_vector(to_unsigned( 33 , 8)),
                            9 => std_logic_vector(to_unsigned( 80 , 8)),
                            10 => std_logic_vector(to_unsigned( 35 , 8)),
                            11 => std_logic_vector(to_unsigned( 12 , 8)),
                            12 => std_logic_vector(to_unsigned( 254 , 8)),
                            13 => std_logic_vector(to_unsigned( 215 , 8)),
                            14 => std_logic_vector(to_unsigned( 78 , 8)),
                            15 => std_logic_vector(to_unsigned( 211 , 8)),
                            16 => std_logic_vector(to_unsigned( 121 , 8)),
                            17 => std_logic_vector(to_unsigned( 78 , 8)),
                            18 => std_logic_vector(to_unsigned( 33 , 8)),
                            others => (others =>'0'));
                    count <= 3;
                elsif(count = 3) then
                    RAM <= (0 => std_logic_vector(to_unsigned( 255 , 8)),
                            1 => std_logic_vector(to_unsigned( 78 , 8)),
                            2 => std_logic_vector(to_unsigned( 33 , 8)),
                            3 => std_logic_vector(to_unsigned( 78 , 8)),
                            4 => std_logic_vector(to_unsigned( 33 , 8)),
                            5 => std_logic_vector(to_unsigned( 78 , 8)),
                            6 => std_logic_vector(to_unsigned( 33 , 8)),
                            7 => std_logic_vector(to_unsigned( 78 , 8)),
                            8 => std_logic_vector(to_unsigned( 33 , 8)),
                            9 => std_logic_vector(to_unsigned( 78 , 8)),
                            10 => std_logic_vector(to_unsigned( 33 , 8)),
                            11 => std_logic_vector(to_unsigned( 78 , 8)),
                            12 => std_logic_vector(to_unsigned( 33 , 8)),
                            13 => std_logic_vector(to_unsigned( 78 , 8)),
                            14 => std_logic_vector(to_unsigned( 33 , 8)),
                            15 => std_logic_vector(to_unsigned( 78 , 8)),
                            16 => std_logic_vector(to_unsigned( 33 , 8)),
                            17 => std_logic_vector(to_unsigned( 78 , 8)),
                            18 => std_logic_vector(to_unsigned( 33 , 8)),
                            others => (others =>'0'));
                    count <= 4;
                elsif(count = 4) then
                    RAM <= (0 => std_logic_vector(to_unsigned( 213 , 8)), -- 1101'0101
                            1 => std_logic_vector(to_unsigned( 252 , 8)),
                            2 => std_logic_vector(to_unsigned( 250 , 8)),
                            3 => std_logic_vector(to_unsigned( 255 , 8)),
                            4 => std_logic_vector(to_unsigned( 255 , 8)),
                            5 => std_logic_vector(to_unsigned( 255 , 8)),
                            6 => std_logic_vector(to_unsigned( 255 , 8)),
                            7 => std_logic_vector(to_unsigned( 255 , 8)),
                            8 => std_logic_vector(to_unsigned( 255 , 8)),
                            9 => std_logic_vector(to_unsigned( 255 , 8)),
                            10 => std_logic_vector(to_unsigned( 255 , 8)),
                            11 => std_logic_vector(to_unsigned( 255 , 8)),
                            12 => std_logic_vector(to_unsigned( 255 , 8)),
                            13 => std_logic_vector(to_unsigned( 255 , 8)),
                            14 => std_logic_vector(to_unsigned( 255 , 8)),
                            15 => std_logic_vector(to_unsigned( 250 , 8)),
                            16 => std_logic_vector(to_unsigned( 252 , 8)),
                            17 => std_logic_vector(to_unsigned( 2 , 8)),
                            18 => std_logic_vector(to_unsigned( 5 , 8)),
                            others => (others =>'0'));
                    count <= 5;
                elsif(count = 5) then
                    RAM <= (0 => std_logic_vector(to_unsigned( 128 , 8)), -- 1000'0000
                            1 => std_logic_vector(to_unsigned( 0 , 8)),
                            2 => std_logic_vector(to_unsigned( 0 , 8)),
                            3 => std_logic_vector(to_unsigned( 111 , 8)),
                            4 => std_logic_vector(to_unsigned( 213 , 8)),
                            5 => std_logic_vector(to_unsigned( 79 , 8)),
                            6 => std_logic_vector(to_unsigned( 33 , 8)),
                            7 => std_logic_vector(to_unsigned( 1 , 8)),
                            8 => std_logic_vector(to_unsigned( 33 , 8)),
                            9 => std_logic_vector(to_unsigned( 80 , 8)),
                            10 => std_logic_vector(to_unsigned( 35 , 8)),
                            11 => std_logic_vector(to_unsigned( 12 , 8)),
                            12 => std_logic_vector(to_unsigned( 254 , 8)),
                            13 => std_logic_vector(to_unsigned( 215 , 8)),
                            14 => std_logic_vector(to_unsigned( 78 , 8)),
                            15 => std_logic_vector(to_unsigned( 78 , 8)),
                            16 => std_logic_vector(to_unsigned( 37 , 8)),
                            17 => std_logic_vector(to_unsigned( 78 , 8)),
                            18 => std_logic_vector(to_unsigned( 33 , 8)),
                            others => (others =>'0'));
                    count <= 6;
                elsif(count = 6) then
                    RAM <= (0 => std_logic_vector(to_unsigned( 255 , 8)), -- 1111'1111
                            1 => std_logic_vector(to_unsigned( 0 , 8)),
                            2 => std_logic_vector(to_unsigned( 0 , 8)),
                            3 => std_logic_vector(to_unsigned( 0 , 8)),
                            4 => std_logic_vector(to_unsigned( 0 , 8)),
                            5 => std_logic_vector(to_unsigned( 0 , 8)),
                            6 => std_logic_vector(to_unsigned( 0 , 8)),
                            7 => std_logic_vector(to_unsigned( 0 , 8)),
                            8 => std_logic_vector(to_unsigned( 0 , 8)),
                            9 => std_logic_vector(to_unsigned( 0 , 8)),
                            10 => std_logic_vector(to_unsigned( 0 , 8)),
                            11 => std_logic_vector(to_unsigned( 0 , 8)),
                            12 => std_logic_vector(to_unsigned( 0 , 8)),
                            13 => std_logic_vector(to_unsigned( 0 , 8)),
                            14 => std_logic_vector(to_unsigned( 0 , 8)),
                            15 => std_logic_vector(to_unsigned( 0 , 8)),
                            16 => std_logic_vector(to_unsigned( 0 , 8)),
                            17 => std_logic_vector(to_unsigned( 255 , 8)),
                            18 => std_logic_vector(to_unsigned( 255 , 8)),
                            others => (others =>'0'));
                    count <= 7;
                elsif(count = 7) then
                    RAM <= (0 => std_logic_vector(to_unsigned( 185 , 8)),
                            1 => std_logic_vector(to_unsigned( 75 , 8)),
                            2 => std_logic_vector(to_unsigned( 32 , 8)),
                            3 => std_logic_vector(to_unsigned( 111 , 8)),
                            4 => std_logic_vector(to_unsigned( 213 , 8)),
                            5 => std_logic_vector(to_unsigned( 79 , 8)),
                            6 => std_logic_vector(to_unsigned( 33 , 8)),
                            7 => std_logic_vector(to_unsigned( 1 , 8)),
                            8 => std_logic_vector(to_unsigned( 33 , 8)),
                            9 => std_logic_vector(to_unsigned( 80 , 8)),
                            10 => std_logic_vector(to_unsigned( 35 , 8)),
                            11 => std_logic_vector(to_unsigned( 12 , 8)),
                            12 => std_logic_vector(to_unsigned( 254 , 8)),
                            13 => std_logic_vector(to_unsigned( 215 , 8)),
                            14 => std_logic_vector(to_unsigned( 78 , 8)),
                            15 => std_logic_vector(to_unsigned( 78 , 8)),
                            16 => std_logic_vector(to_unsigned( 37 , 8)),
                            17 => std_logic_vector(to_unsigned( 78 , 8)),
                            18 => std_logic_vector(to_unsigned( 33 , 8)),
                            others => (others =>'0'));
                    count <= 8;
                elsif(count = 8) then
                    RAM <= (0 => std_logic_vector(to_unsigned( 0 , 8)),
                            1 => std_logic_vector(to_unsigned( 75 , 8)),
                            2 => std_logic_vector(to_unsigned( 32 , 8)),
                            3 => std_logic_vector(to_unsigned( 111 , 8)),
                            4 => std_logic_vector(to_unsigned( 213 , 8)),
                            5 => std_logic_vector(to_unsigned( 79 , 8)),
                            6 => std_logic_vector(to_unsigned( 33 , 8)),
                            7 => std_logic_vector(to_unsigned( 1 , 8)),
                            8 => std_logic_vector(to_unsigned( 33 , 8)),
                            9 => std_logic_vector(to_unsigned( 80 , 8)),
                            10 => std_logic_vector(to_unsigned( 35 , 8)),
                            11 => std_logic_vector(to_unsigned( 12 , 8)),
                            12 => std_logic_vector(to_unsigned( 254 , 8)),
                            13 => std_logic_vector(to_unsigned( 215 , 8)),
                            14 => std_logic_vector(to_unsigned( 78 , 8)),
                            15 => std_logic_vector(to_unsigned( 211 , 8)),
                            16 => std_logic_vector(to_unsigned( 121 , 8)),
                            17 => std_logic_vector(to_unsigned( 78 , 8)),
                            18 => std_logic_vector(to_unsigned( 33 , 8)),
                            others => (others =>'0'));
                    count <= 9;
                 elsif(count = 9) then
                    RAM <= (0 => std_logic_vector(to_unsigned( 255 , 8)),
                            1 => std_logic_vector(to_unsigned( 78 , 8)),
                            2 => std_logic_vector(to_unsigned( 33 , 8)),
                            3 => std_logic_vector(to_unsigned( 78 , 8)),
                            4 => std_logic_vector(to_unsigned( 33 , 8)),
                            5 => std_logic_vector(to_unsigned( 78 , 8)),
                            6 => std_logic_vector(to_unsigned( 33 , 8)),
                            7 => std_logic_vector(to_unsigned( 78 , 8)),
                            8 => std_logic_vector(to_unsigned( 33 , 8)),
                            9 => std_logic_vector(to_unsigned( 78 , 8)),
                            10 => std_logic_vector(to_unsigned( 33 , 8)),
                            11 => std_logic_vector(to_unsigned( 78 , 8)),
                            12 => std_logic_vector(to_unsigned( 33 , 8)),
                            13 => std_logic_vector(to_unsigned( 78 , 8)),
                            14 => std_logic_vector(to_unsigned( 33 , 8)),
                            15 => std_logic_vector(to_unsigned( 78 , 8)),
                            16 => std_logic_vector(to_unsigned( 33 , 8)),
                            17 => std_logic_vector(to_unsigned( 78 , 8)),
                            18 => std_logic_vector(to_unsigned( 33 , 8)),
                            others => (others =>'0'));
                    count <= 10;
                elsif(count = 10) then
                    RAM <= (0 => std_logic_vector(to_unsigned( 213 , 8)), -- 1101'0101
                            1 => std_logic_vector(to_unsigned( 252 , 8)),
                            2 => std_logic_vector(to_unsigned( 250 , 8)),
                            3 => std_logic_vector(to_unsigned( 255 , 8)),
                            4 => std_logic_vector(to_unsigned( 255 , 8)),
                            5 => std_logic_vector(to_unsigned( 255 , 8)),
                            6 => std_logic_vector(to_unsigned( 255 , 8)),
                            7 => std_logic_vector(to_unsigned( 255 , 8)),
                            8 => std_logic_vector(to_unsigned( 255 , 8)),
                            9 => std_logic_vector(to_unsigned( 255 , 8)),
                            10 => std_logic_vector(to_unsigned( 255 , 8)),
                            11 => std_logic_vector(to_unsigned( 255 , 8)),
                            12 => std_logic_vector(to_unsigned( 255 , 8)),
                            13 => std_logic_vector(to_unsigned( 255 , 8)),
                            14 => std_logic_vector(to_unsigned( 255 , 8)),
                            15 => std_logic_vector(to_unsigned( 250 , 8)),
                            16 => std_logic_vector(to_unsigned( 252 , 8)),
                            17 => std_logic_vector(to_unsigned( 2 , 8)),
                            18 => std_logic_vector(to_unsigned( 5 , 8)),
                            others => (others =>'0'));
                    count <= 11;
                elsif(count = 11) then
                    RAM <= (0 => std_logic_vector(to_unsigned( 128 , 8)), -- 1000'0000
                            1 => std_logic_vector(to_unsigned( 0 , 8)),
                            2 => std_logic_vector(to_unsigned( 0 , 8)),
                            3 => std_logic_vector(to_unsigned( 111 , 8)),
                            4 => std_logic_vector(to_unsigned( 213 , 8)),
                            5 => std_logic_vector(to_unsigned( 79 , 8)),
                            6 => std_logic_vector(to_unsigned( 33 , 8)),
                            7 => std_logic_vector(to_unsigned( 1 , 8)),
                            8 => std_logic_vector(to_unsigned( 33 , 8)),
                            9 => std_logic_vector(to_unsigned( 80 , 8)),
                            10 => std_logic_vector(to_unsigned( 35 , 8)),
                            11 => std_logic_vector(to_unsigned( 12 , 8)),
                            12 => std_logic_vector(to_unsigned( 254 , 8)),
                            13 => std_logic_vector(to_unsigned( 215 , 8)),
                            14 => std_logic_vector(to_unsigned( 78 , 8)),
                            15 => std_logic_vector(to_unsigned( 78 , 8)),
                            16 => std_logic_vector(to_unsigned( 37 , 8)),
                            17 => std_logic_vector(to_unsigned( 78 , 8)),
                            18 => std_logic_vector(to_unsigned( 33 , 8)),
                            others => (others =>'0'));
                    count <= 12;
                elsif(count = 12) then
                    RAM <= (0 => std_logic_vector(to_unsigned( 255 , 8)), -- 1111'1111
                            1 => std_logic_vector(to_unsigned( 0 , 8)),
                            2 => std_logic_vector(to_unsigned( 0 , 8)),
                            3 => std_logic_vector(to_unsigned( 0 , 8)),
                            4 => std_logic_vector(to_unsigned( 0 , 8)),
                            5 => std_logic_vector(to_unsigned( 0 , 8)),
                            6 => std_logic_vector(to_unsigned( 0 , 8)),
                            7 => std_logic_vector(to_unsigned( 0 , 8)),
                            8 => std_logic_vector(to_unsigned( 0 , 8)),
                            9 => std_logic_vector(to_unsigned( 0 , 8)),
                            10 => std_logic_vector(to_unsigned( 0 , 8)),
                            11 => std_logic_vector(to_unsigned( 0 , 8)),
                            12 => std_logic_vector(to_unsigned( 0 , 8)),
                            13 => std_logic_vector(to_unsigned( 0 , 8)),
                            14 => std_logic_vector(to_unsigned( 0 , 8)),
                            15 => std_logic_vector(to_unsigned( 0 , 8)),
                            16 => std_logic_vector(to_unsigned( 0 , 8)),
                            17 => std_logic_vector(to_unsigned( 255 , 8)),
                            18 => std_logic_vector(to_unsigned( 255 , 8)),
                            others => (others =>'0'));
                    count <= 13;
                end if;
            else
                if enable_wire = '1' then
                    if mem_we = '1' then
                        RAM(conv_integer(mem_address)) <= mem_i_data;
                        mem_o_data <= mem_i_data after 2 ns;
                    else
                        mem_o_data <= RAM(conv_integer(mem_address)) after 2 ns;
                    end if;
                end if;
            end if;
        end if;
    end process;


	-- Processo per testbench che esegue effettivamente il test
	test : process is
	begin
	    -- test 0 (fornito da professore)
		wait for 100 ns;
		wait for c_CLOCK_PERIOD;
		tb_rst <= '1';
		wait for c_CLOCK_PERIOD;
		tb_rst <= '0';
		wait for c_CLOCK_PERIOD;
		tb_start <= '1';
		wait for c_CLOCK_PERIOD;
		wait until tb_done = '1';
		wait for c_CLOCK_PERIOD;
		tb_start <= '0';
		wait until tb_done = '0';
		wait for c_CLOCK_PERIOD;

		-- Maschera di output = 00010001
		assert RAM(19) = std_logic_vector(to_unsigned(17 , 8)) report "TEST 0 FALLITO" severity failure;
	 
	    -- test 1 (aggiunto centroide 8 alla stessa distanza)
		wait for 100 ns;
		wait for c_CLOCK_PERIOD;
		tb_rst <= '1';
		wait for c_CLOCK_PERIOD;
		tb_rst <= '0';
		wait for c_CLOCK_PERIOD;
		tb_start <= '1';
		wait for c_CLOCK_PERIOD;
		wait until tb_done = '1';
		wait for c_CLOCK_PERIOD;
		tb_start <= '0';
		wait until tb_done = '0';
		wait for c_CLOCK_PERIOD;

		-- Maschera di output = 10010001
		assert RAM(19) = std_logic_vector(to_unsigned(145 , 8)) report "TEST 1 FALLITO" severity failure;
		
		-- test 2 (maschera di input 0000'0000)
		wait for 100 ns;
		wait for c_CLOCK_PERIOD;
		tb_rst <= '1';
		wait for c_CLOCK_PERIOD;
		tb_rst <= '0';
		wait for c_CLOCK_PERIOD;
		tb_start <= '1';
		wait for c_CLOCK_PERIOD;
		wait until tb_done = '1';
		wait for c_CLOCK_PERIOD;
		tb_start <= '0';
		wait until tb_done = '0';
		wait for c_CLOCK_PERIOD;

		-- Maschera di output = 00000000
		assert RAM(19) = std_logic_vector(to_unsigned(0 , 8)) report "TEST 2 FALLITO" severity failure;
		
		-- test 3 (tutti i punti a distanza 0)
		wait for 100 ns;
		wait for c_CLOCK_PERIOD;
		tb_rst <= '1';
		wait for c_CLOCK_PERIOD;
		tb_rst <= '0';
		wait for c_CLOCK_PERIOD;
		tb_start <= '1';
		wait for c_CLOCK_PERIOD;
		wait until tb_done = '1';
		wait for c_CLOCK_PERIOD;
		tb_start <= '0';
		wait until tb_done = '0';
		wait for c_CLOCK_PERIOD;

		-- Maschera di output = 11111111
		assert RAM(19) = std_logic_vector(to_unsigned(255 , 8)) report "TEST 3 FALLITO" severity failure;
	 
        -- test 4 (tutti i centroidi molto distanti, 9 bit nella distanza)
		wait for 100 ns;
		wait for c_CLOCK_PERIOD;
		tb_rst <= '1';
		wait for c_CLOCK_PERIOD;
		tb_rst <= '0';
		wait for c_CLOCK_PERIOD;
		tb_start <= '1';
		wait for c_CLOCK_PERIOD;
		wait until tb_done = '1';
		wait for c_CLOCK_PERIOD;
		tb_start <= '0';
		wait until tb_done = '0';
		wait for c_CLOCK_PERIOD;

		-- Maschera di output = 10000001
		assert RAM(19) = std_logic_vector(to_unsigned(129 , 8)) report "TEST 4 FALLITO" severity failure;
	 
        -- test 5 (solo un centroide da considerare per maschera)
		wait for 100 ns;
		wait for c_CLOCK_PERIOD;
		tb_rst <= '1';
		wait for c_CLOCK_PERIOD;
		tb_rst <= '0';
		wait for c_CLOCK_PERIOD;
		tb_start <= '1';
		wait for c_CLOCK_PERIOD;
		wait until tb_done = '1';
		wait for c_CLOCK_PERIOD;
		tb_start <= '0';
		wait until tb_done = '0';
		wait for c_CLOCK_PERIOD;

		-- Maschera di output = 10000000
		assert RAM(19) = std_logic_vector(to_unsigned(128 , 8)) report "TEST 5 FALLITO" severity failure;
 
        -- test 6 (tutti i punti a distanza massima)
		wait for 100 ns;
		wait for c_CLOCK_PERIOD;
		tb_rst <= '1';
		wait for c_CLOCK_PERIOD;
		tb_rst <= '0';
		wait for c_CLOCK_PERIOD;
		tb_start <= '1';
		wait for c_CLOCK_PERIOD;
		wait until tb_done = '1';
		wait for c_CLOCK_PERIOD;
		tb_start <= '0';
		wait until tb_done = '0';
		wait for c_CLOCK_PERIOD;

		-- Maschera di output = 11111111
		assert RAM(19) = std_logic_vector(to_unsigned(255 , 8)) report "TEST 6 FALLITO" severity failure;
	 
        -- test 7 (uguale a test 1 ma senza segnale di reset)
		wait for 100 ns;
		wait for c_CLOCK_PERIOD;
		ram_set <= '1';
		wait for c_CLOCK_PERIOD;
		ram_set <= '0';
		wait for c_CLOCK_PERIOD;
		tb_start <= '1';
		wait for c_CLOCK_PERIOD;
		wait until tb_done = '1';
		wait for c_CLOCK_PERIOD;
		tb_start <= '0';
		wait until tb_done = '0';
		wait for c_CLOCK_PERIOD;

		-- Maschera di output = 10010001
		assert RAM(19) = std_logic_vector(to_unsigned(145 , 8)) report "TEST 7 FALLITO" severity failure;
		
		-- test 8  (uguale a test 2 ma senza segnale di reset)
		wait for 100 ns;
		wait for c_CLOCK_PERIOD;
		ram_set <= '1';
		wait for c_CLOCK_PERIOD;
		ram_set <= '0';
		wait for c_CLOCK_PERIOD;
		tb_start <= '1';
		wait for c_CLOCK_PERIOD;
		wait until tb_done = '1';
		wait for c_CLOCK_PERIOD;
		tb_start <= '0';
		wait until tb_done = '0';
		wait for c_CLOCK_PERIOD;

		-- Maschera di output = 00000000
		assert RAM(19) = std_logic_vector(to_unsigned(0 , 8)) report "TEST 2 FALLITO" severity failure;
		
		-- test 9  (uguale a test 3 ma senza segnale di reset)
		wait for 100 ns;
		wait for c_CLOCK_PERIOD;
		ram_set <= '1';
		wait for c_CLOCK_PERIOD;
		ram_set <= '0';
		wait for c_CLOCK_PERIOD;
		tb_start <= '1';
		wait for c_CLOCK_PERIOD;
		wait until tb_done = '1';
		wait for c_CLOCK_PERIOD;
		tb_start <= '0';
		wait until tb_done = '0';
		wait for c_CLOCK_PERIOD;

		-- Maschera di output = 11111111
		assert RAM(19) = std_logic_vector(to_unsigned(255 , 8)) report "TEST 3 FALLITO" severity failure;
	 
        -- test 10  (uguale a test 4 ma senza segnale di reset)
		wait for 100 ns;
		wait for c_CLOCK_PERIOD;
		ram_set <= '1';
		wait for c_CLOCK_PERIOD;
		ram_set <= '0';
		wait for c_CLOCK_PERIOD;
		tb_start <= '1';
		wait for c_CLOCK_PERIOD;
		wait until tb_done = '1';
		wait for c_CLOCK_PERIOD;
		tb_start <= '0';
		wait until tb_done = '0';
		wait for c_CLOCK_PERIOD;

		-- Maschera di output = 10000001
		assert RAM(19) = std_logic_vector(to_unsigned(129 , 8)) report "TEST 4 FALLITO" severity failure;
	 
        -- test 11  (uguale a test 5 ma senza segnale di reset)
		wait for 100 ns;
		wait for c_CLOCK_PERIOD;
		ram_set <= '1';
		wait for c_CLOCK_PERIOD;
		ram_set <= '0';
		wait for c_CLOCK_PERIOD;
		tb_start <= '1';
		wait for c_CLOCK_PERIOD;
		wait until tb_done = '1';
		wait for c_CLOCK_PERIOD;
		tb_start <= '0';
		wait until tb_done = '0';
		wait for c_CLOCK_PERIOD;

		-- Maschera di output = 10000000
		assert RAM(19) = std_logic_vector(to_unsigned(128 , 8)) report "TEST 5 FALLITO" severity failure;
 
        -- test 12 (uguale a test 1 ma senza segnale di reset)
		wait for 100 ns;
		wait for c_CLOCK_PERIOD;
		ram_set <= '1';
		wait for c_CLOCK_PERIOD;
		ram_set <= '0';
		wait for c_CLOCK_PERIOD;
		tb_start <= '1';
		wait for c_CLOCK_PERIOD;
		wait until tb_done = '1';
		wait for c_CLOCK_PERIOD;
		tb_start <= '0';
		wait until tb_done = '0';
		wait for c_CLOCK_PERIOD;

		-- Maschera di output = 11111111
		assert RAM(19) = std_logic_vector(to_unsigned(255 , 8)) report "TEST 6 FALLITO" severity failure;
	 
	 
		assert false report "Simulation Ended!, TEST PASSATO" severity failure;
	end process test;

end projecttb; 
