library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
    generic (START_ADDRESS : unsigned(15 downto 0) := "0000000000000000");
    port (
        i_clk         : in  std_logic; -- Clock
        i_start       : in  std_logic; -- Il modulo parte nell'elaborazione quando il segnale START in ingresso viene portato a 1. Il segnale di START rimarr� alto fino a che il segnale di DONE non verr� portato alto;
        i_rst         : in  std_logic; -- Inizializza la macchina pronta per ricevere il primo segnale di start
        i_data        : in  std_logic_vector(7 downto 0); -- Segnale che arriva dalla memoria dopo richiesta di lettura
        o_address     : out std_logic_vector(15 downto 0); -- Indirizzo da mandare alla memoria, all'indirizzo 0 ho i primi 8 bit, all'indirizzo 1 altri 8 bit e cos� via
        o_done        : out std_logic; -- Notifica la fine dell'elaborazione. Il segnale DONE deve rimanere alto fino a che il segnale di START non � riportato a 0.
        o_en          : out std_logic; -- Segnale di Enable da mandare alla memoria per poter comunicare (sia in lettura che in scrittura)
        o_we          : out std_logic; -- Write Enable. 1 per scrivere. 0 per leggere
        o_data        : out std_logic_vector (7 downto 0) -- Segnale da mandare alla memoria
    );
end project_reti_logiche;


architecture projectArch of project_reti_logiche is

    type state_type is (S_RST, S_START, S_INPUT_MASK, S_COORD_X, S_COORD_Y, S_C1X, S_C1Y, S_C2X, S_C2Y, S_C3X, S_C3Y, S_C4X, S_C4Y, S_C5X, S_C5Y, S_C6X, S_C6Y, S_C7X, S_C7Y, S_C8X, S_C8Y, S_DONE, S_END);
    signal next_state, current_state : state_type;
    
    signal input_mask_reg : std_logic_vector(7 downto 0) := "11111111";
    signal input_mask_signal : std_logic_vector(7 downto 0) := "11111111";
    signal x_cord_reg : std_logic_vector(7 downto 0) := "00000000";
    signal x_cord_signal : std_logic_vector(7 downto 0) := "00000000";
    signal y_cord_reg : std_logic_vector(7 downto 0) := "00000000";
    signal y_cord_signal : std_logic_vector(7 downto 0) := "00000000";
    signal x_value_reg : std_logic_vector(7 downto 0) := "00000000";
    signal x_value_signal : std_logic_vector(7 downto 0) := "00000000";
    signal min_distance_reg : unsigned(8 downto 0) := "111111111"; -- 9 bit perch� massima distanza � 255 + 255 = 510
    signal min_distance_signal : unsigned(8 downto 0) := "111111111"; -- 9 bit perch� massima distanza � 255 + 255 = 510
    signal out_mask_tmp_reg :  std_logic_vector(7 downto 0) := "00000000";
    signal out_mask_tmp_signal :  std_logic_vector(7 downto 0) := "00000000";
    
    signal distance_tot : unsigned(8 downto 0) := "111111111"; -- 9 bit perch� massima distanza � 255 + 255 = 510
    
    procedure get_next_state_and_outputs(
    in_index : in natural range 0 to 7;
    in_mask : in std_logic_vector(7 downto 0);
    signal out_state : out state_type;
    signal out_address : out std_logic_vector(15 downto 0);
    signal out_we : out std_logic) is 
    begin
        if(in_mask(0) = '1' and in_index <= 0) then
            out_state <= S_C1X;
            out_address <= std_logic_vector(START_ADDRESS + 1); -- 1 X centroide 1
            out_we <= '0';
        else
            if(in_mask(1) = '1' and in_index <= 1) then
                out_state <= S_C2X;
                out_address <= std_logic_vector(START_ADDRESS + 3); -- 3 X centroide 2
                out_we <= '0';
            else
                if(in_mask(2) = '1' and in_index <= 2) then
                    out_state <= S_C3X;
                    out_address <= std_logic_vector(START_ADDRESS + 5); -- 5 X centroide 3
                    out_we <= '0';
                else
                    if(in_mask(3) = '1' and in_index <= 3) then
                        out_state <= S_C4X;
                        out_address <= std_logic_vector(START_ADDRESS + 7); -- 7 X centroide 4
                        out_we <= '0';
                    else
                        if(in_mask(4) = '1' and in_index <= 4) then
                            out_state <= S_C5X;
                            out_address <= std_logic_vector(START_ADDRESS + 9); -- 9 X centroide 5
                            out_we <= '0';
                        else
                            if(in_mask(5) = '1' and in_index <= 5) then
                                out_state <= S_C6X;
                                out_address <= std_logic_vector(START_ADDRESS + 11); -- 11 X centroide 6
                                out_we <= '0';
                            else
                                if(in_mask(6) = '1' and in_index <= 6) then
                                    out_state <= S_C7X;
                                    out_address <= std_logic_vector(START_ADDRESS + 13); -- 13 X centroide 7
                                    out_we <= '0';
                                else
                                    if(in_mask(7) = '1' and in_index <= 7) then
                                        out_state <= S_C8X;
                                        out_address <= std_logic_vector(START_ADDRESS + 15); -- 15 X centroide 8
                                        out_we <= '0';
                                    else
                                        out_state <= S_DONE;
                                        out_address <= std_logic_vector(START_ADDRESS + 19); -- 19 out mask
                                        out_we <= '1';
                                    end if;
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end get_next_state_and_outputs;
    
    procedure is_immediate_answer(
    in_mask : in std_logic_vector(7 downto 0);
    variable out_is_immediate : out std_logic) is 
    begin
        case in_mask is
            when "00000000"|"00000001"|"00000010"|"00000100"|"00001000"|"00010000"|"00100000"|"01000000"|"10000000" =>
                out_is_immediate := '1';
            when others =>
                out_is_immediate := '0';
        end case;
    end is_immediate_answer;
    
    begin
    
    -- gestione del clock, del reset e dello start
    state_clock: process(i_clk, i_rst)
    begin
        if(i_clk'event and i_clk='1') then
            if(i_rst = '1') then
                current_state <= S_RST;
                x_value_reg <= "00000000";
                min_distance_reg <= "111111111";
                out_mask_tmp_reg <= "00000000";
                input_mask_reg <= "11111111";
                x_cord_reg <= "00000000";
                y_cord_reg <= "00000000";
            else
                current_state <= next_state;
                x_value_reg <= x_value_signal;
                min_distance_reg <= min_distance_signal;
                out_mask_tmp_reg <= out_mask_tmp_signal;
                input_mask_reg <= input_mask_signal;
                x_cord_reg <= x_cord_signal;
                y_cord_reg <= y_cord_signal;
            end if;
        end if;
    end process;
    
    -- Gestione dello stato del componente
    state_manager: process(current_state, i_start, input_mask_signal)
    variable immediate_answer : std_logic;
    begin
        case current_state is
            when S_RST =>
                if(i_start = '1') then
                    next_state <= S_START;
                else
                    next_state <= S_RST;
                end if;
                o_address <= "----------------";
                o_we <= '0';

            when S_START =>
                next_state <= S_INPUT_MASK;
                o_address <= std_logic_vector(START_ADDRESS); -- 0 input mask
                o_we <= '0';

            when S_INPUT_MASK =>
                is_immediate_answer(input_mask_signal, immediate_answer);
                if(immediate_answer = '1') then
                    next_state <= S_DONE;
                     o_address <= std_logic_vector(START_ADDRESS + 19); -- 19 out mask
                     o_we <= '1';
                else
                    next_state <= S_COORD_X;
                    o_address <= std_logic_vector(START_ADDRESS + 17); -- 17 X del punto da valutare
                    o_we <= '0';
                end if;

            when S_COORD_X =>
                next_state <= S_COORD_Y;
                o_address <= std_logic_vector(START_ADDRESS + 18); -- 18 Y del punto da valutare
                o_we <= '0';

            when S_COORD_Y =>
                get_next_state_and_outputs(0, input_mask_signal, next_state, o_address, o_we);

            when S_C1X =>
                next_state <= S_C1Y;
                o_address <= std_logic_vector(START_ADDRESS + 2); -- 2 Y centroide 1
                o_we <= '0';

            when S_C1Y =>
                get_next_state_and_outputs(1, input_mask_signal, next_state, o_address, o_we);

            when S_C2X =>
                next_state <= S_C2Y;
                o_address <= std_logic_vector(START_ADDRESS + 4); -- 4 Y centroide 2
                o_we <= '0';

            when S_C2Y =>
                get_next_state_and_outputs(2, input_mask_signal, next_state, o_address, o_we);

            when S_C3X =>
                next_state <= S_C3Y;
                o_address <= std_logic_vector(START_ADDRESS + 6); -- 6 Y centroide 3
                o_we <= '0';

            when S_C3Y =>
                get_next_state_and_outputs(3, input_mask_signal, next_state, o_address, o_we);

            when S_C4X =>
                next_state <= S_C4Y;
                o_address <= std_logic_vector(START_ADDRESS + 8); -- 8 Y centroide 4
                o_we <= '0';

            when S_C4Y =>
                get_next_state_and_outputs(4, input_mask_signal, next_state, o_address, o_we);

            when S_C5X =>          
                next_state <= S_C5Y;
                o_address <= std_logic_vector(START_ADDRESS + 10); -- 10 Y centroide 5
                o_we <= '0';

            when S_C5Y =>
                get_next_state_and_outputs(5, input_mask_signal, next_state, o_address, o_we);

            when S_C6X =>
                next_state <= S_C6Y;
                o_address <= std_logic_vector(START_ADDRESS + 12); -- 12 Y centroide 6
                o_we <= '0';

            when S_C6Y =>
                get_next_state_and_outputs(6, input_mask_signal, next_state, o_address, o_we);

            when S_C7X =>
                next_state <= S_C7Y;
                o_address <= std_logic_vector(START_ADDRESS + 14); -- 14 Y centroide 7
                o_we <= '0';

            when S_C7Y =>
                get_next_state_and_outputs(7, input_mask_signal, next_state, o_address, o_we);

            when S_C8X =>
                next_state <= S_C8Y;
                o_address <= std_logic_vector(START_ADDRESS + 16); -- 16 Y centroide 8
                o_we <= '0';

            when S_C8Y =>
                next_state <= S_DONE;
                o_address <= std_logic_vector(START_ADDRESS + 19); -- 19 out mask
                o_we <= '1';

            when S_DONE =>
                if(i_start = '1') then
                    next_state <= S_DONE;
                else
                    next_state <= S_END;
                end if;
                o_address <= "----------------";
                o_we <= '0';

            when S_END =>
                if(i_start = '1') then
                    next_state <= S_START;
                else
                    next_state <= S_END;
                end if;
                o_address <= "----------------";
                o_we <= '0';

        end case;
    end process;
    
    -- Gestione dell'input e assegnamento di esso al giusto signal
    input_manager: process(current_state, i_data, input_mask_reg, x_cord_reg, y_cord_reg, x_value_reg)
    begin
        case current_state is
            when S_INPUT_MASK =>
                input_mask_signal <= i_data; -- Input Mask
                x_cord_signal <= x_cord_reg;
                y_cord_signal <= y_cord_reg;
                x_value_signal <= x_value_reg;
            when S_COORD_X =>
                x_cord_signal <= i_data; -- X punto da valutare
                input_mask_signal <= input_mask_reg; 
                y_cord_signal <= y_cord_reg;
                x_value_signal <= x_value_reg;
            when S_COORD_Y =>
                y_cord_signal <= i_data; -- Y punto da valutare
                input_mask_signal <= input_mask_reg;
                x_cord_signal <= x_cord_reg;
                x_value_signal <= x_value_reg;
            when S_C1X|S_C2X|S_C3X|S_C4X|S_C5X|S_C6X|S_C7X|S_C8X =>
                x_value_signal <= i_data; -- X dei centroidi
                input_mask_signal <= input_mask_reg;
                x_cord_signal <= x_cord_reg;
                y_cord_signal <= y_cord_reg;
            when others =>
                input_mask_signal <= input_mask_reg;
                x_cord_signal <= x_cord_reg;
                y_cord_signal <= y_cord_reg;
                x_value_signal <= x_value_reg;
        end case;
    end process;
    
    -- Calcolo della distanza totale
    distance_calc: process(current_state, x_cord_reg, y_cord_reg, x_value_reg, i_data) -- i_data � per la variabile y del centroide presa direttamente dall'ingresso
    variable distance_x : signed(8 downto 0) := "000000000";
    variable distance_y : signed(8 downto 0) := "000000000";
    begin
        case current_state is
            when S_C1Y|S_C2Y|S_C3Y|S_C4Y|S_C5Y|S_C6Y|S_C7Y|S_C8Y =>
                distance_x := abs(signed('0' & x_value_reg) - signed('0' & x_cord_reg));
                distance_y := abs(signed('0' & i_data) - signed('0' & y_cord_reg));
                distance_tot <= unsigned(distance_x + distance_y);
            when others =>
                distance_tot <= "111111111";
        end case;
    end process;

    -- Controlla se la nuova distanza � minima
    check_min: process(current_state, input_mask_signal, distance_tot, min_distance_reg, out_mask_tmp_reg)
    variable distance_mask : std_logic_vector(7 downto 0) := "00000000";
    variable immediate_answer : std_logic;
    begin
        case current_state is
            when S_C1Y =>
                distance_mask := "00000001"; -- Calcola distanza del 1� centroide
            when S_C2Y =>
                distance_mask := "00000010"; -- Calcola distanza del 2� centroide
            when S_C3Y =>
                distance_mask := "00000100"; -- Calcola distanza del 3� centroide
            when S_C4Y =>
                distance_mask := "00001000"; -- Calcola distanza del 4� centroide
            when S_C5Y =>
                distance_mask := "00010000"; -- Calcola distanza del 5� centroide
            when S_C6Y =>
                distance_mask := "00100000"; -- Calcola distanza del 6� centroide
            when S_C7Y =>
                distance_mask := "01000000"; -- Calcola distanza del 7� centroide
            when S_C8Y =>
                distance_mask := "10000000"; -- Calcola distanza del 8� centroide
            when others =>
                distance_mask := "00000000";
        end case;
        
        if(distance_mask /= "00000000") then -- Se centroide da considerare per mask
            if(distance_tot < min_distance_reg) then
                out_mask_tmp_signal <= distance_mask;
                min_distance_signal <= distance_tot;
            elsif(distance_tot = min_distance_reg) then
                out_mask_tmp_signal <= (out_mask_tmp_reg or distance_mask);
                min_distance_signal <= min_distance_reg;
            else
                out_mask_tmp_signal <= out_mask_tmp_reg;
                min_distance_signal <= min_distance_reg;
            end if;
        else
            if(current_state = S_INPUT_MASK) then
                is_immediate_answer(input_mask_signal, immediate_answer);
                if(immediate_answer = '1') then -- se � a risposta immediata possiamo dare dirrettamente la maschera di uscita
                out_mask_tmp_signal <= input_mask_signal;
                min_distance_signal <= "111111111";
                end if;
            elsif(current_state = S_END) then  -- preset dei segnali per la possibile prossima elaborazione (nel caso non ci sia segnale di reset)
                out_mask_tmp_signal <= "00000000";
                min_distance_signal <= "111111111";
            else
                out_mask_tmp_signal <= out_mask_tmp_reg;
                min_distance_signal <= min_distance_reg;
            end if;
        end if;
    end process;
    
    -- Gestisce gli output di enable per la RAM
    o_en <= '0' when (current_state = S_RST or
                      current_state = S_DONE or
                      current_state = S_END) else '1';
    
    -- Gestisce l'ouput di fine elaborazione
    o_done <= '1' when (current_state = S_DONE) else '0';
              
    -- Assegnamenti del segnale d'ingresso alla RAM
    o_data <= out_mask_tmp_signal;

end projectArch;
