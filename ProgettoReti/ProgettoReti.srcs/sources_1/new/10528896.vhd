package CONSTANTS is
  constant MEM_BITS : natural := 16;
  constant CELL_BITS : natural := 8; -- Si assume che il numero di bit in una cella di memoria equivale anche al numero di centroidi
end package CONSTANTS;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.CONSTANTS.ALL;

entity project_reti_logiche is
    generic (
        START_ADDRESS : unsigned(MEM_BITS - 1 downto 0) := (others => '0')
    );
    port (
        i_clk      : in  std_logic; -- Clock
        i_start    : in  std_logic; -- Il modulo parte nell'elaborazione quando il segnale START in ingresso viene portato a 1. Il segnale di START rimarrà alto fino a che il segnale di DONE non verrà portato alto.
        i_rst      : in  std_logic; -- Inizializza la macchina pronta per ricevere il primo segnale di start.
        i_data     : in  std_logic_vector(CELL_BITS - 1 downto 0); -- Segnale che arriva dalla memoria dopo richiesta di lettura.
        o_address  : out std_logic_vector(MEM_BITS - 1 downto 0); -- Indirizzo da mandare alla memoria, all'indirizzo 0 ho i primi 8 bit, all'indirizzo 1 altri 8 bit e così via.
        o_done     : out std_logic; -- Notifica la fine dell'elaborazione. Il segnale DONE deve rimanere alto fino a che il segnale di START non è riportato a 0.
        o_en       : out std_logic; -- Segnale di Enable da mandare alla memoria per poter comunicare (sia in lettura che in scrittura).
        o_we       : out std_logic; -- Write Enable. 1 per scrivere. 0 per leggere.
        o_data     : out std_logic_vector (CELL_BITS - 1 downto 0) -- Segnale da mandare alla memoria.
    );
end project_reti_logiche;

architecture projectRetiLogiche of project_reti_logiche is

    type state_type is (
        S_RST, -- Stato di partenza della FSM e stato in cui si andrà in presenza di un segnale di Reset.
        S_START, -- Stato iniziale, il componente inizia alla ricezione di un segnale i_start. In questo stato viene fornito alla RAM l'indirizzo dell'Input Mask.
        S_INPUT_MASK, -- Stato in cui il componente legge ed elabora l'Input Mask che gli è arrivata da memoria.
        S_COORD_X, -- Stato in cui il componente legge ed elabora la X del punto da valutare che gli è arrivata da memoria.
        S_COORD_Y, -- Stato in cui il componente legge ed elabora la Y del punto da valutare che gli è arrivata da memoria.
        S_CX,
        S_CY,
        S_DONE -- Stato in cui si segnala che il risultato è stato scritto in RAM, o_done è portato ad '1'.
    );
    
    -- Segnali per registri
    signal next_state, current_state : state_type;
    signal input_mask_reg : std_logic_vector(CELL_BITS - 1 downto 0) := (others => '1');
    signal input_mask_signal : std_logic_vector(CELL_BITS - 1 downto 0) := (others => '1');
    signal x_coord_reg : std_logic_vector(CELL_BITS - 1 downto 0) := (others => '0');
    signal x_coord_signal : std_logic_vector(CELL_BITS - 1 downto 0) := (others => '0');
    signal y_coord_reg : std_logic_vector(CELL_BITS - 1 downto 0) := (others => '0');
    signal y_coord_signal : std_logic_vector(CELL_BITS - 1 downto 0) := (others => '0');
    signal x_value_reg : std_logic_vector(CELL_BITS - 1 downto 0) := (others => '0');
    signal x_value_signal : std_logic_vector(CELL_BITS - 1 downto 0) := (others => '0');
    signal centroid_num_reg : integer range -1 to CELL_BITS := 0;
    signal centroid_num_signal : integer range -1 to CELL_BITS := 0;
    signal min_distance_reg : unsigned(CELL_BITS downto 0) := (others => '1'); -- 1 bit in più per distanza massima che può andare in overflow
    signal min_distance_signal : unsigned(CELL_BITS downto 0) := (others => '1'); -- 1 bit in più per distanza massima che può andare in overflow
    signal out_mask_tmp_reg :  std_logic_vector(CELL_BITS - 1 downto 0) := (others => '0');
    signal out_mask_tmp_signal :  std_logic_vector(CELL_BITS - 1 downto 0) := (others => '0');
    signal out_done_tmp_reg :  std_logic := '0'; -- Uso registro per o_done per evitare alee (glitches)
    signal out_done_tmp_signal :  std_logic := '0'; -- Uso registro per o_done per evitare alee (glitches)
    
    -- Segnali interni
    signal is_immediate : std_logic := '0';
    signal next_centroid : integer range -1 to CELL_BITS := 0; -- -1 = stati precedenti a centroidi; 0 = primo centroide; ...; CELL_BITS = stati successivi a centroidi
    signal distance_x : unsigned(CELL_BITS downto 0) := (others => '0');
    signal distance_y : unsigned(CELL_BITS downto 0) := (others => '0');
    signal distance_tot : unsigned(CELL_BITS downto 0) := (others => '1'); -- 1 bit in più per distanza massima che può andare in overflow

begin

    --- ###### GESTIONE STATI ######
    
    -- Gestione del clock e del reset
    -- Assegnamenti: current_state, x_value_reg, min_distance_reg, out_mask_tmp_reg, input_mask_reg, x_coord_reg, y_coord_reg
    registers_process: process(i_clk, i_rst, next_state, input_mask_signal, x_coord_signal, y_coord_signal, x_value_signal, centroid_num_signal, min_distance_signal, out_mask_tmp_signal, out_done_tmp_signal)
    begin
        if(i_clk'event and i_clk='1') then
            if(i_rst = '1') then
                current_state <= S_RST;
                input_mask_reg <= (others => '1');
                x_coord_reg <= (others => '0');
                y_coord_reg <= (others => '0');
                x_value_reg <= (others => '0');
                centroid_num_reg <= -1;
                min_distance_reg <= (others => '1');
                out_mask_tmp_reg <= (others => '0');
                out_done_tmp_reg <= '0';
            else
                current_state <= next_state;
                input_mask_reg <= input_mask_signal;
                x_coord_reg <= x_coord_signal;
                y_coord_reg <= y_coord_signal;
                x_value_reg <= x_value_signal;
                centroid_num_reg <= centroid_num_signal;
                min_distance_reg <= min_distance_signal;
                out_mask_tmp_reg <= out_mask_tmp_signal;
                out_done_tmp_reg <= out_done_tmp_signal;
            end if;
        end if;
    end process;
    
    -- Gestione dello stato del componente
    -- Assegnamenti: next_state, centroid_num_signal
    state_process: process(current_state, next_centroid, centroid_num_reg, i_start, is_immediate, distance_x, min_distance_reg)
    begin
        case current_state is
            when S_RST =>
                centroid_num_signal <= -1;
                if(i_start = '1') then
                    next_state <= S_START;
                else
                    next_state <= S_RST;
                end if;
            when S_START =>
                next_state <= S_INPUT_MASK;
            when S_INPUT_MASK =>
                centroid_num_signal <= -1;
                if(is_immediate = '1') then
                    next_state <= S_DONE;
                else
                    next_state <= S_COORD_X;
                end if;
            when S_COORD_X =>
                centroid_num_signal <= -1;
                next_state <= S_COORD_Y;
            when S_COORD_Y =>
                centroid_num_signal <= next_centroid;
                next_state <= S_CX;
            when S_CX =>
                if(distance_x > min_distance_reg) then -- se la distanza X è già maggiore della distanza minima è inutile calcolare la distanza Y, passiamo direttamente al centroide successivo
                    centroid_num_signal <= next_centroid;
                    if(next_centroid = CELL_BITS) then
                        next_state <= S_DONE;  -- Va allo stato finale, non ci sono altri centroidi da considerare
                    else
                        next_state <= S_CX; -- Va allo stato di lettura della X del prossimo centroide
                    end if;
                else
                    next_state <= S_CY;
                    centroid_num_signal <= centroid_num_reg;
                end if;
            when S_CY =>
                centroid_num_signal <= next_centroid;
                if(next_centroid = CELL_BITS) then
                    next_state <= S_DONE;
                else
                    next_state <= S_CX;
                end if;
            when S_DONE =>
                centroid_num_signal <= CELL_BITS;
                if(i_start = '1') then
                    next_state <= S_DONE;
                else
                    next_state <= S_RST;
                end if;
        end case;
    end process;
    
    -- Trova il centroide in base alla maschera e in base al centroide corrente, salta quindi i centroidi non da considerare
    -- Assegnamenti: next_centroid
    next_centroid_process: process(centroid_num_reg, input_mask_signal)
    begin
        next_centroid <= CELL_BITS;
        for i in 0 to CELL_BITS - 1 loop 
            if(input_mask_signal(i) = '1' and centroid_num_reg < i) then
                next_centroid <= i; -- sovrascrive CELL_BITS
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
    x_value_signal <= i_data when (current_state = S_CX) else x_value_reg;
    
    -- Elabora la Input Mask e segnala se la maschera di ingresso permette di avere una risposta immediata (cioè se ha 1 oppure 0 bit attivati)
    -- Per arrivare al risultato si è utilizzato un famoso "trucchetto": avere un bit attivato significa essere una potenza di 2. E una potenza di 2 la si può trovare facendo (N bitwise& N-1) = 0
    -- Assegnamenti: is_immediate
    is_immediate <= '1' when (unsigned(input_mask_signal) = 0) or (unsigned(input_mask_signal and std_logic_vector(unsigned(input_mask_signal) - 1)) = 0) else '0';
    
    
    --- ###### CALCOLO DISTANZA ######
    
    -- Calcolo della distanza totale
    -- Assegnamenti: distance_x, distance_y, distance_tot
    distance_x <= unsigned(abs(signed('0' & x_value_signal) - signed('0' & x_coord_signal)))
                    when (current_state /= S_RST and current_state /= S_START and current_state /= S_DONE)
                    else (others => '0');
    distance_y <= unsigned(abs(signed('0' & i_data) - signed('0' & y_coord_signal)))
                    when (current_state /= S_RST and current_state /= S_START and current_state /= S_DONE)
                    else (others => '0');
    distance_tot <= (distance_x + distance_y)
                    when (current_state /= S_RST and current_state /= S_START and current_state /= S_DONE)
                    else (others => '1');

    -- Controlla se la nuova distanza è minima
    -- Assegnamenti: out_mask_tmp_signal, min_distance_signal
    check_min: process(current_state, centroid_num_reg, input_mask_signal, is_immediate, distance_tot, min_distance_reg, out_mask_tmp_reg)
    begin
        if(current_state = S_CY) then -- Se siamo in uno stato in cui c'è da calcolare distanza
            if(distance_tot < min_distance_reg) then
                out_mask_tmp_signal <= (others => '0');
                out_mask_tmp_signal(centroid_num_reg) <= '1';
                min_distance_signal <= distance_tot;
            elsif(distance_tot = min_distance_reg) then
                out_mask_tmp_signal <= out_mask_tmp_reg;
                out_mask_tmp_signal(centroid_num_reg) <= '1';
                min_distance_signal <= min_distance_reg;
            else
                out_mask_tmp_signal <= out_mask_tmp_reg;
                min_distance_signal <= min_distance_reg;
            end if;
        else
            if(current_state = S_INPUT_MASK and is_immediate = '1') then -- se è a risposta immediata possiamo dare dirrettamente la maschera di uscita
                out_mask_tmp_signal <= input_mask_signal;
                min_distance_signal <= (others => '1');
            elsif(current_state = S_RST) then  -- preset dei segnali per la possibile prossima elaborazione (nel caso non ci sia segnale di reset esplicito)
                out_mask_tmp_signal <= (others => '0');
                min_distance_signal <= (others => '1');
            else
                out_mask_tmp_signal <= out_mask_tmp_reg;
                min_distance_signal <= min_distance_reg;
            end if;
        end if;
    end process;
    
    
    --- ###### OUTPUT ######
    
    -- Assegnamento di o_address in base allo stato successivo (il dato letto allo stato successivo dipende dallo stato in cui si andrà)
    with next_state select o_address <=
        (others => '-') when S_RST|S_START,
        std_logic_vector(START_ADDRESS + 0) when S_INPUT_MASK, -- Maschera d'ingresso
        std_logic_vector(START_ADDRESS + (CELL_BITS * 2) + 1) when S_COORD_X, -- X del punto da valutare
        std_logic_vector(START_ADDRESS + (CELL_BITS * 2) + 2) when S_COORD_y, -- Y del punto da valutare
        std_logic_vector(START_ADDRESS + (centroid_num_signal * 2) + 1) when S_CX, -- X centroide
        std_logic_vector(START_ADDRESS + (centroid_num_signal * 2) + 2) when S_CY, -- Y centroide
        std_logic_vector(START_ADDRESS + (CELL_BITS * 2) + 3) when S_DONE; -- Maschera di uscita

    -- Assegnamento di output che andranno in ingresso alla RAM
    -- Assegnamenti: o_en, o_we, o_data
    o_en <= '1' when (current_state /= S_RST and current_state /= S_DONE) else '0';
    o_we <= '1' when (next_state = S_DONE and current_state /= S_DONE) else '0';
    o_data <= out_mask_tmp_signal when (next_state = S_DONE and current_state /= S_DONE) else (others => '-');
    
    -- Gestione o_done
    -- Assegnamenti: o_done, out_done_tmp_signal
    out_done_tmp_signal <= '1' when (next_state = S_DONE) else '0';
    o_done <= out_done_tmp_reg; -- Uso registro per o_done per evitare alee (glitches)

end projectRetiLogiche;
