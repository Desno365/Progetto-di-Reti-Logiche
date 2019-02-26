library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
    generic (START_ADDRESS : unsigned(15 downto 0) := "0000000000000000");
    port (
        i_clk         : in  std_logic; -- Clock
        i_start       : in  std_logic; -- Il modulo parte nell'elaborazione quando il segnale START in ingresso viene portato a 1. Il segnale di START rimarrà alto fino a che il segnale di DONE non verrà portato alto;
        i_rst         : in  std_logic; -- Inizializza la macchina pronta per ricevere il primo segnale di start
        i_data        : in  std_logic_vector(7 downto 0); -- Segnale che arriva dalla memoria dopo richiesta di lettura
        o_address     : out std_logic_vector(15 downto 0); -- Indirizzo da mandare alla memoria, all'indirizzo 0 ho i primi 8 bit, all'indirizzo 1 altri 8 bit e così via
        o_done        : out std_logic; -- Notifica la fine dell'elaborazione. Il segnale DONE deve rimanere alto fino a che il segnale di START non è riportato a 0.
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
    signal min_distance_reg : unsigned(8 downto 0) := "111111111"; -- 9 bit perchè massima distanza è 255 + 255 = 510
    signal min_distance_signal : unsigned(8 downto 0) := "111111111"; -- 9 bit perchè massima distanza è 255 + 255 = 510
    signal out_mask_tmp_reg :  std_logic_vector(7 downto 0) := "00000000";
    signal out_mask_tmp_signal :  std_logic_vector(7 downto 0) := "00000000";
    
    signal distance_x : signed(8 downto 0) := "000000000";
    signal distance_y : signed(8 downto 0) := "000000000";
    signal distance_tot : unsigned(8 downto 0) := "111111111"; -- 9 bit perchè massima distanza è 255 + 255 = 510
    
    -- Trova lo stato successivo in base alla maschera (in_mask) e in base allo stato corrente (in_state)
    function get_next_state(constant in_state : in state_type; constant in_mask : in std_logic_vector(7 downto 0)) return state_type is 
    begin
        for i in 0 to 7 loop 
            if(in_mask(i) = '1' and state_type'POS(in_state) <= (4 + (i * 2))) then
                return state_type'VAL(5 + (i * 2));
            end if;
        end loop;
        return S_DONE;
    end get_next_state;
    
    -- Segnala se la maschera di ingresso permette di avere una risposta immediata (cioè se ha 1 oppure 0 bit attivati)
    function is_immediate_answer(constant in_mask : in std_logic_vector(7 downto 0)) return std_logic is 
    begin
        case in_mask is
            when "00000000"|"00000001"|"00000010"|"00000100"|"00001000"|"00010000"|"00100000"|"01000000"|"10000000" =>
                return '1';
            when others =>
                return '0';
        end case;
    end is_immediate_answer;
    
begin
    
    --- ###### GESTIONE STATI ######
    
    -- Gestione del clock, del reset e dello start
    -- Assegnamenti: current_state, x_value_reg, min_distance_reg, out_mask_tmp_reg, input_mask_reg, x_cord_reg, y_cord_reg
    state_clock: process(i_clk, i_rst, next_state, x_value_signal, min_distance_signal, out_mask_tmp_signal, input_mask_signal, x_cord_signal, y_cord_signal)
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
    -- Assegnamenti: next_state
    state_manager: process(current_state, i_start, input_mask_signal)
    begin
        case current_state is
            when S_RST =>
                if(i_start = '1') then
                    next_state <= S_START;
                else
                    next_state <= S_RST;
                end if;
            when S_START =>
                next_state <= S_INPUT_MASK;
            when S_INPUT_MASK =>
                if(is_immediate_answer(input_mask_signal) = '1') then
                    next_state <= S_DONE;
                else
                    next_state <= S_COORD_X;
                end if;
            when S_COORD_X =>
                next_state <= S_COORD_Y;
            when S_COORD_Y|S_C1Y|S_C2Y|S_C3Y|S_C4Y|S_C5Y|S_C6Y|S_C7Y =>
                next_state <= get_next_state(current_state, input_mask_signal);
            when S_C1X|S_C2X|S_C3X|S_C4X|S_C5X|S_C6X|S_C7X|S_C8X =>
                next_state <= state_type'SUCC(current_state);
            when S_C8Y =>
                next_state <= S_DONE;
            when S_DONE =>
                if(i_start = '1') then
                    next_state <= S_DONE;
                else
                    next_state <= S_END;
                end if;
            when S_END =>
                if(i_start = '1') then
                    next_state <= S_START;
                else
                    next_state <= S_END;
                end if;
        end case;
    end process;
    
    
    --- ###### INPUT ######
    
    -- Gestione dell'input e assegnamento di esso al giusto signal
    -- Assegnamenti:  input_mask_signal, x_cord_signal, y_cord_signal, x_value_signal
    input_mask_signal <= i_data when (current_state = S_INPUT_MASK) else input_mask_reg;
    x_cord_signal <= i_data when (current_state = S_COORD_X) else x_cord_reg;
    y_cord_signal <= i_data when (current_state = S_COORD_Y) else y_cord_reg;
    x_value_signal <= i_data when (current_state = S_C1X or current_state = S_C2X or current_state = S_C3X or current_state = S_C4X or current_state = S_C5X or current_state = S_C6X or current_state = S_C7X or current_state = S_C8X) else x_value_reg;
    
    
    --- ###### CALCOLO DISTANZA ######
    
    -- Calcolo della distanza totale
    -- Assegnamenti: distance_x, distance_y, distance_tot
    distance_x <= abs(signed('0' & x_value_reg) - signed('0' & x_cord_reg)) when (current_state /= S_RST and current_state /= S_START and current_state /= S_DONE and current_state /= S_END) else "000000000";
    distance_y <= abs(signed('0' & i_data) - signed('0' & y_cord_reg)) when (current_state /= S_RST and current_state /= S_START and current_state /= S_DONE and current_state /= S_END) else "000000000";
    distance_tot <= unsigned(distance_x + distance_y) when (current_state /= S_RST and current_state /= S_START and current_state /= S_DONE and current_state /= S_END) else "111111111";

    -- Controlla se la nuova distanza è minima
    -- Assegnamenti: out_mask_tmp_signal, min_distance_signal
    check_min: process(current_state, input_mask_signal, distance_tot, min_distance_reg, out_mask_tmp_reg)
    variable distance_mask : std_logic_vector(7 downto 0) := "00000000";
    begin
        case current_state is
            when S_C1Y =>
                distance_mask := "00000001"; -- Calcola distanza del 1° centroide
            when S_C2Y =>
                distance_mask := "00000010"; -- Calcola distanza del 2° centroide
            when S_C3Y =>
                distance_mask := "00000100"; -- Calcola distanza del 3° centroide
            when S_C4Y =>
                distance_mask := "00001000"; -- Calcola distanza del 4° centroide
            when S_C5Y =>
                distance_mask := "00010000"; -- Calcola distanza del 5° centroide
            when S_C6Y =>
                distance_mask := "00100000"; -- Calcola distanza del 6° centroide
            when S_C7Y =>
                distance_mask := "01000000"; -- Calcola distanza del 7° centroide
            when S_C8Y =>
                distance_mask := "10000000"; -- Calcola distanza del 8° centroide
            when others =>
                distance_mask := "00000000";
        end case;
        
        if(distance_mask /= "00000000") then -- Se siamo in uno stato in cui c'è da calcolare distanza
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
            if(current_state = S_INPUT_MASK and is_immediate_answer(input_mask_signal) = '1') then -- se è a risposta immediata possiamo dare dirrettamente la maschera di uscita
                out_mask_tmp_signal <= input_mask_signal;
                min_distance_signal <= "111111111";
            elsif(current_state = S_END) then  -- preset dei segnali per la possibile prossima elaborazione (nel caso non ci sia segnale di reset)
                out_mask_tmp_signal <= "00000000";
                min_distance_signal <= "111111111";
            else
                out_mask_tmp_signal <= out_mask_tmp_reg;
                min_distance_signal <= min_distance_reg;
            end if;
        end if;
    end process;
    
    
    --- ###### OUTPUT ######
    
    -- Assegnamento di o_address in base a stato successivo (il dato letto allo stato successivo dipende dallo stato in cui si andrà)
    with next_state select o_address <=
        "----------------" when S_RST,
        "----------------" when S_START,
        std_logic_vector(START_ADDRESS + 0) when S_INPUT_MASK, -- 0 input mask
        std_logic_vector(START_ADDRESS + 17) when S_COORD_X, -- 17 X del punto da valutare
        std_logic_vector(START_ADDRESS + 18) when S_COORD_y, -- 18 Y del punto da valutare
        std_logic_vector(START_ADDRESS + 1) when S_C1X, -- 1 X centroide 1
        std_logic_vector(START_ADDRESS + 2) when S_C1Y, -- 2 Y centroide 1
        std_logic_vector(START_ADDRESS + 3) when S_C2X, -- 3 X centroide 2
        std_logic_vector(START_ADDRESS + 4) when S_C2Y, -- 4 Y centroide 2
        std_logic_vector(START_ADDRESS + 5) when S_C3X, -- 5 X centroide 3
        std_logic_vector(START_ADDRESS + 6) when S_C3Y, -- 6 Y centroide 3
        std_logic_vector(START_ADDRESS + 7) when S_C4X, -- 7 X centroide 4
        std_logic_vector(START_ADDRESS + 8) when S_C4Y, -- 8 Y centroide 4
        std_logic_vector(START_ADDRESS + 9) when S_C5X, -- 9 X centroide 5
        std_logic_vector(START_ADDRESS + 10) when S_C5Y, -- 10 Y centroide 5
        std_logic_vector(START_ADDRESS + 11) when S_C6X, -- 11 X centroide 6
        std_logic_vector(START_ADDRESS + 12) when S_C6Y, -- 12 Y centroide 6
        std_logic_vector(START_ADDRESS + 13) when S_C7X, -- 13 X centroide 7
        std_logic_vector(START_ADDRESS + 14) when S_C7Y, -- 14 Y centroide 7
        std_logic_vector(START_ADDRESS + 15) when S_C8X, -- 15 X centroide 8
        std_logic_vector(START_ADDRESS + 16) when S_C8Y, -- 16 Y centroide 8
        std_logic_vector(START_ADDRESS + 19) when S_DONE, -- 19 out mask
        "----------------" when S_END;

    -- Assegnamento dell'output di enable per la RAM
    o_en <= '1' when (current_state /= S_RST and current_state /= S_DONE and current_state /= S_END) else '0';
    
    -- Assegnamento dell'output di scrittura della RAM
    o_we <= '1' when (next_state = S_DONE) else '0';
              
    -- Assegnamento del segnale di scrittura della RAM
    o_data <= out_mask_tmp_signal when (next_state = S_DONE) else "--------";
    
    -- Assegnamento dell'output di fine elaborazione
    o_done <= '1' when (current_state = S_DONE) else '0';

end projectArch;
