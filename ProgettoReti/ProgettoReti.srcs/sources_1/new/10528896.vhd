library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
    generic (START_ADDRESS : unsigned(15 downto 0) := "0000000000000000");
    port (
        i_clk         : in  std_logic; -- Clock
        i_start       : in  std_logic; -- Il modulo parte nell'elaborazione quando il segnale START in ingresso viene portato a 1. Il segnale di START rimarrà alto fino a che il segnale di DONE non verrà portato alto.
        i_rst         : in  std_logic; -- Inizializza la macchina pronta per ricevere il primo segnale di start.
        i_data        : in  std_logic_vector(7 downto 0); -- Segnale che arriva dalla memoria dopo richiesta di lettura.
        o_address     : out std_logic_vector(15 downto 0); -- Indirizzo da mandare alla memoria, all'indirizzo 0 ho i primi 8 bit, all'indirizzo 1 altri 8 bit e così via.
        o_done        : out std_logic; -- Notifica la fine dell'elaborazione. Il segnale DONE deve rimanere alto fino a che il segnale di START non è riportato a 0.
        o_en          : out std_logic; -- Segnale di Enable da mandare alla memoria per poter comunicare (sia in lettura che in scrittura).
        o_we          : out std_logic; -- Write Enable. 1 per scrivere. 0 per leggere.
        o_data        : out std_logic_vector (7 downto 0) -- Segnale da mandare alla memoria.
    );
end project_reti_logiche;


architecture projectRetiLogiche of project_reti_logiche is

    type state_type is (
        S_RST, -- Stato di partenza della FSM e stato in cui si andrà in presenza di un segnale di Reset.
        S_START, -- Stato iniziale, il componente inizia alla ricezione di un segnale i_start. In questo stato viene fornito alla RAM l'indirizzo dell'Input Mask.
        S_INPUT_MASK, -- Stato in cui il componente legge ed elabora l'Input Mask che gli è arrivata da memoria.
        S_COORD_X, -- Stato in cui il componente legge ed elabora la X del punto da valutare che gli è arrivata da memoria.
        S_COORD_Y, -- Stato in cui il componente legge ed elabora la Y del punto da valutare che gli è arrivata da memoria.
        S_C1X, -- Lettura ed elaborazione della X del 1° centroide.
        S_C1Y, -- Lettura ed elaborazione della Y del 1° centroide, calcolo della distanza totale e sua elaborazione.
        S_C2X, -- Lettura ed elaborazione della X del 2° centroide.
        S_C2Y, -- Lettura ed elaborazione della Y del 2° centroide, calcolo della distanza totale e sua elaborazione.
        S_C3X, -- Lettura ed elaborazione della X del 3° centroide.
        S_C3Y, -- Lettura ed elaborazione della Y del 3° centroide, calcolo della distanza totale e sua elaborazione.
        S_C4X, -- Lettura ed elaborazione della X del 4° centroide.
        S_C4Y, -- Lettura ed elaborazione della Y del 4° centroide, calcolo della distanza totale e sua elaborazione.
        S_C5X, -- Lettura ed elaborazione della X del 5° centroide.
        S_C5Y, -- Lettura ed elaborazione della Y del 5° centroide, calcolo della distanza totale e sua elaborazione.
        S_C6X, -- Lettura ed elaborazione della X del 6° centroide.
        S_C6Y, -- Lettura ed elaborazione della Y del 6° centroide, calcolo della distanza totale e sua elaborazione.
        S_C7X, -- Lettura ed elaborazione della X del 7° centroide.
        S_C7Y, -- Lettura ed elaborazione della Y del 7° centroide, calcolo della distanza totale e sua elaborazione.
        S_C8X, -- Lettura ed elaborazione della X del 8° centroide.
        S_C8Y, -- Lettura ed elaborazione della Y del 8° centroide, calcolo della distanza totale e sua elaborazione.
        S_DONE, -- Stato in cui si segnala che il risultato è stato scritto in RAM, o_done è portato ad '1'.
        S_END  -- Stato di fine elaborazione: i_start è stato portato a '0' e o_done pure. Il componente è pronto per una successiva elaborazione che avverrà al prossimo segnale di i_start.
    );
    
    -- Segnali per registri
    signal next_state, current_state : state_type;
    signal input_mask_reg : std_logic_vector(7 downto 0) := "11111111";
    signal input_mask_signal : std_logic_vector(7 downto 0) := "11111111";
    signal x_coord_reg : std_logic_vector(7 downto 0) := "00000000";
    signal x_coord_signal : std_logic_vector(7 downto 0) := "00000000";
    signal y_coord_reg : std_logic_vector(7 downto 0) := "00000000";
    signal y_coord_signal : std_logic_vector(7 downto 0) := "00000000";
    signal x_value_reg : std_logic_vector(7 downto 0) := "00000000";
    signal x_value_signal : std_logic_vector(7 downto 0) := "00000000";
    signal min_distance_reg : unsigned(8 downto 0) := "111111111"; -- 9 bit perchè massima distanza è 255 + 255 = 510
    signal min_distance_signal : unsigned(8 downto 0) := "111111111"; -- 9 bit perchè massima distanza è 255 + 255 = 510
    signal out_mask_tmp_reg :  std_logic_vector(7 downto 0) := "00000000";
    signal out_mask_tmp_signal :  std_logic_vector(7 downto 0) := "00000000";
    signal out_done_tmp_reg :  std_logic := '0'; -- Uso registro per o_done per evitare alee (glitches)
    signal out_done_tmp_signal :  std_logic := '0'; -- Uso registro per o_done per evitare alee (glitches)
    
    -- Segnali interni
    signal is_immediate : std_logic := '0';
    signal next_found_state : state_type := S_DONE;
    signal distance_x : unsigned(8 downto 0) := "000000000";
    signal distance_y : unsigned(8 downto 0) := "000000000";
    signal distance_mask : std_logic_vector(7 downto 0) := "00000000";
    signal distance_tot : unsigned(8 downto 0) := "111111111"; -- 9 bit perchè massima distanza è 255 + 255 = 510
    
begin
    
    --- ###### GESTIONE STATI ######
    
    -- Gestione del clock e del reset
    -- Assegnamenti: current_state, x_value_reg, min_distance_reg, out_mask_tmp_reg, input_mask_reg, x_coord_reg, y_coord_reg
    register_process: process(i_clk, i_rst, next_state, x_value_signal, min_distance_signal, out_mask_tmp_signal, out_done_tmp_signal, input_mask_signal, x_coord_signal, y_coord_signal)
    begin
        if(i_clk'event and i_clk='1') then
            if(i_rst = '1') then
                current_state <= S_RST;
                x_value_reg <= "00000000";
                min_distance_reg <= "111111111";
                out_mask_tmp_reg <= "00000000";
                out_done_tmp_reg <= '0';
                input_mask_reg <= "11111111";
                x_coord_reg <= "00000000";
                y_coord_reg <= "00000000";
            else
                current_state <= next_state;
                x_value_reg <= x_value_signal;
                min_distance_reg <= min_distance_signal;
                out_mask_tmp_reg <= out_mask_tmp_signal;
                out_done_tmp_reg <= out_done_tmp_signal;
                input_mask_reg <= input_mask_signal;
                x_coord_reg <= x_coord_signal;
                y_coord_reg <= y_coord_signal;
            end if;
        end if;
    end process;
    
    -- Gestione dello stato del componente
    -- Assegnamenti: next_state
    state_process: process(current_state, i_start, is_immediate, distance_x, min_distance_reg, next_found_state)
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
                if(is_immediate = '1') then
                    next_state <= S_DONE;
                else
                    next_state <= S_COORD_X;
                end if;
            when S_COORD_X =>
                next_state <= S_COORD_Y;
            when S_COORD_Y|S_C1Y|S_C2Y|S_C3Y|S_C4Y|S_C5Y|S_C6Y|S_C7Y =>
                --next_state <= get_next_state(current_state, input_mask_signal);
                next_state <= next_found_state;
            when S_C1X|S_C2X|S_C3X|S_C4X|S_C5X|S_C6X|S_C7X|S_C8X =>
                if(distance_x > min_distance_reg) then -- se la distanza X è già maggiore della distanza minima è inutile calcolare la distanza Y, passiamo direttamente a centroide successivo
                    --next_state <= get_next_state(current_state, input_mask_signal);
                    next_state <= next_found_state;
                else
                    next_state <= state_type'SUCC(current_state);
                end if;
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
    
    -- Trova lo stato successivo in base alla maschera e in base allo stato corrente, salta quindi i centroidi non da considerare
    -- Assegnamenti: next_found_state
    next_found_state_process: process(current_state, input_mask_signal)
    begin
        next_found_state <= S_DONE;
        for i in 0 to 7 loop 
            if(input_mask_signal(i) = '1' and state_type'POS(current_state) <= (4 + (i * 2))) then
                next_found_state <= state_type'VAL(5 + (i * 2)); -- sovrascrive S_DONE
                exit;
            end if;
        end loop;
    end process;
    
    
    --- ###### INPUT ######
    
    -- Gestione dell'input e assegnamento di esso al giusto signal (se non siamo in uno stato di assegnamento dell'input mantiene il valore precedente)
    -- Assegnamenti:  input_mask_signal, x_coord_signal, y_coord_signal, x_value_signal
    input_mask_signal <= i_data when (current_state = S_INPUT_MASK) else input_mask_reg;
    x_coord_signal <= i_data when (current_state = S_COORD_X) else x_coord_reg;
    y_coord_signal <= i_data when (current_state = S_COORD_Y) else y_coord_reg;
    with current_state select x_value_signal <=
        i_data when S_C1X,
        i_data when S_C2X,
        i_data when S_C3X,
        i_data when S_C4X,
        i_data when S_C5X,
        i_data when S_C6X,
        i_data when S_C7X,
        i_data when S_C8X,
        x_value_reg when others;
    --x_value_signal <= i_data when (current_state = S_C1X or current_state = S_C2X or current_state = S_C3X or current_state = S_C4X or current_state = S_C5X or current_state = S_C6X or current_state = S_C7X or current_state = S_C8X) else x_value_reg;
    
    -- Elabora la Input Mask e segnala se la maschera di ingresso permette di avere una risposta immediata (cioè se ha 1 oppure 0 bit attivati)
    -- Assegnamenti: is_immediate
    with input_mask_signal select is_immediate <=
        '1' when "00000000",
        '1' when "00000001",
        '1' when "00000010",
        '1' when "00000100",
        '1' when "00001000",
        '1' when "00010000",
        '1' when "00100000",
        '1' when "01000000",
        '1' when "10000000",
        '0' when others; -- Risposta NON immediata
    
    
    --- ###### CALCOLO DISTANZA ######
    
    -- Calcolo della distanza totale
    -- Assegnamenti: distance_x, distance_y, distance_tot
    distance_x <= unsigned(abs(signed('0' & x_value_signal) - signed('0' & x_coord_signal))) when (current_state /= S_RST and current_state /= S_START and current_state /= S_DONE and current_state /= S_END) else "000000000";
    distance_y <= unsigned(abs(signed('0' & i_data) - signed('0' & y_coord_signal))) when (current_state /= S_RST and current_state /= S_START and current_state /= S_DONE and current_state /= S_END) else "000000000";
    distance_tot <= (distance_x + distance_y) when (current_state /= S_RST and current_state /= S_START and current_state /= S_DONE and current_state /= S_END) else "111111111";

    -- Assegnamento di distance_mask sulla base di quale centroide si sta calcolando la distanza
    with current_state select distance_mask <=
        "00000001" when S_C1Y, -- Calcola distanza del 1° centroide
        "00000010" when S_C2Y, -- Calcola distanza del 2° centroide
        "00000100" when S_C3Y, -- Calcola distanza del 3° centroide
        "00001000" when S_C4Y, -- Calcola distanza del 4° centroide
        "00010000" when S_C5Y, -- Calcola distanza del 5° centroide
        "00100000" when S_C6Y, -- Calcola distanza del 6° centroide
        "01000000" when S_C7Y, -- Calcola distanza del 7° centroide
        "10000000" when S_C8Y, -- Calcola distanza del 8° centroide
        "00000000" when others;

    -- Controlla se la nuova distanza è minima
    -- Assegnamenti: out_mask_tmp_signal, min_distance_signal
    check_min: process(current_state, distance_mask, input_mask_signal, is_immediate, distance_tot, min_distance_reg, out_mask_tmp_reg)
    begin
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
            if(current_state = S_INPUT_MASK and is_immediate = '1') then -- se è a risposta immediata possiamo dare dirrettamente la maschera di uscita
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
    
    -- Assegnamento di o_address in base allo stato successivo (il dato letto allo stato successivo dipende dallo stato in cui si andrà)
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

    -- Assegnamento di output che andranno in ingresso alla RAM
    -- Assegnamenti: o_en, o_we, o_data
    o_en <= '1' when (current_state /= S_RST and current_state /= S_DONE and current_state /= S_END) else '0';
    o_we <= '1' when (next_state = S_DONE and current_state /= S_DONE) else '0';
    o_data <= out_mask_tmp_signal when (next_state = S_DONE and current_state /= S_DONE) else "--------";
    
    -- Assegnamento di o_done
    out_done_tmp_signal <= '1' when (next_state = S_DONE) else '0';
    o_done <= out_done_tmp_reg; -- Uso registro per o_done per evitare alee (glitches)

end projectRetiLogiche;
