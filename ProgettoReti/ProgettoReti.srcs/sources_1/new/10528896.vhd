-- ####################################
-- Progetto finale di Reti Logiche
-- Motta Dennis - Matrcola n. 865833
-- Anno Accademico 2018/2019
-- ####################################


-- ############ PACKAGE PER COSTANTI ############
package CONSTANTS is
  constant MEM_BITS : natural := 16; -- Numero di bit per un indirizzo di memoria. 
  constant CELL_BITS : natural := 8; -- Numero di bit in una cella di memoria che si assume equivalente al numero di centroidi da analizzare.
end package CONSTANTS;


-- ############ COMPONENTE ############
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.CONSTANTS.ALL;

entity project_reti_logiche is
    generic (
        START_ADDRESS : unsigned(MEM_BITS - 1 downto 0) := (others => '0') -- Indirizzo iniziale di memoria (dove è quindi salvata la maschera d'ingresso).
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

    -- ############ STATI DELLA FSM ############
    type state_type is (
        S_RST,          -- Stato di partenza della FSM e stato in cui si andrà in presenza di un segnale i_rst. Alla ricezione di un segnale i_start si passa allo stato S_START.
        S_START,        -- Stato iniziale. In questo stato viene fornito alla RAM l'indirizzo della maschera di ingresso specificato dal generic START_ADDRESS.
        S_INPUT_MASK,   -- Stato in cui il componente legge e salva in un registro la maschera di ingresso che gli è arrivata da memoria.
        S_COORD_X,      -- Stato in cui il componente legge e salva in un registro la X del punto da valutare che gli è arrivata da memoria.
        S_COORD_Y,      -- Stato in cui il componente legge e salva in un registro la Y del punto da valutare che gli è arrivata da memoria.
        S_CX,           -- Lettura e salvataggio delle X dei centroidi.
        S_CY,           -- Lettura delle Y dei centroidi. Si calcola la distanza tra il punto da valutare e il centroide con conseguente elaborazione.
        S_DONE          -- Stato in cui si segnala che il risultato è stato scritto in RAM: o_done è portato ad '1'.
    );
    
    -- ############ REGISTRI ############
    
    -- Segnali per registro dello stato corrente della FSM.
    signal current_state : state_type;
    signal next_state : state_type;
    
    -- Segnali per registro del il centroide corrente. 0 = stati precedenti ai centroidi; 1 = primo centroide; ...; CELL_BITS = ultimo centroide; (CELL_BITS + 1) = stati successivi ai centroidi.
    signal centroid_num_reg : natural range 0 to CELL_BITS + 1 := 0;
    signal centroid_num_signal : natural range 0 to CELL_BITS + 1 := 0;
    
    -- Segnali per registro della maschera d'ingresso.
    signal input_mask_reg : std_logic_vector(CELL_BITS - 1 downto 0) := (others => '1');
    signal input_mask_signal : std_logic_vector(CELL_BITS - 1 downto 0) := (others => '1');
    
    -- Segnali per registro della X del punto da valutare.
    signal x_coord_reg : std_logic_vector(CELL_BITS - 1 downto 0) := (others => '0');
    signal x_coord_signal : std_logic_vector(CELL_BITS - 1 downto 0) := (others => '0');
    
    -- Segnali per registro della Y del punto da valutare.
    signal y_coord_reg : std_logic_vector(CELL_BITS - 1 downto 0) := (others => '0');
    signal y_coord_signal : std_logic_vector(CELL_BITS - 1 downto 0) := (others => '0');
    
    -- Segnali per registro della X del centroide corrente.
    signal x_value_reg : std_logic_vector(CELL_BITS - 1 downto 0) := (others => '0');
    signal x_value_signal : std_logic_vector(CELL_BITS - 1 downto 0) := (others => '0');
    
    -- Segnali per registro della distanza minima trovata.
    signal min_distance_reg : unsigned(CELL_BITS downto 0) := (others => '1'); -- 1 bit in più per distanza massima che può andare in overflow
    signal min_distance_signal : unsigned(CELL_BITS downto 0) := (others => '1'); -- 1 bit in più per distanza massima che può andare in overflow
    
    -- Segnali per registro della maschera di uscita temporanea.
    signal out_mask_tmp_reg :  std_logic_vector(CELL_BITS - 1 downto 0) := (others => '0');
    signal out_mask_tmp_signal :  std_logic_vector(CELL_BITS - 1 downto 0) := (others => '0');
    
    -- Segnali per registro del valore da dare a o_done, si è usato un registro per evitare alee statiche (glitches) sul segnale che avrebbero compromesso il funzionamento.
    signal out_done_tmp_reg :  std_logic := '0';
    signal out_done_tmp_signal :  std_logic := '0';
    
    -- ############ SEGNALI INTERNI DEL COMPONENTE ############
    signal is_immediate : std_logic; -- Segnala se la maschera di ingresso permette di avere una risposta immediata (cioè se ha 1 oppure 0 bit attivati).
    signal next_centroid : natural range 0 to CELL_BITS + 1; -- 0 = stati precedenti ai centroidi; 1 = primo centroide; ...; CELL_BITS = ultimo centroide; (CELL_BITS + 1) = stati successivi ai centroidi.
    signal distance_x : unsigned(CELL_BITS downto 0); -- Distanza sulle ascisse tra centroide e punto da valutare.
    signal distance_y : unsigned(CELL_BITS downto 0); -- Distanza sulle ordinate tra centroide e punto da valutare.
    signal distance_tot : unsigned(CELL_BITS downto 0); -- Distanza totale, che non è altro che la somma di distance_x e distance_y. Usa 1 bit in più per possibile overflow.

begin

    -- ############ GESTIONE STATI ############
    
    -- Creazione dei registri
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
                centroid_num_reg <= 0;
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
    
    -- Trova il valore del possibile prossimo centroide utilizzando il valore del centroide corrente e la maschera d'ingresso, salta quindi i centroidi non da considerare.
    -- Assegnamenti: next_centroid
    next_centroid_process: process(centroid_num_reg, input_mask_signal)
    begin
        next_centroid <= CELL_BITS + 1;
        for i in 1 to CELL_BITS loop 
            if(input_mask_signal(i - 1) = '1' and centroid_num_reg < i) then
                next_centroid <= i; -- sovrascrive CELL_BITS + 1
                exit;
            end if;
        end loop;
    end process;
    
    -- Gestisce lo stato della FSM. Gli ingressi current_state e i_start servono alla FSM di base mentre gli altri segnali permettono le varie ottimizzazioni.
    -- Assegnamenti: next_state
    state_process: process(current_state, i_start, next_centroid, is_immediate, distance_x, min_distance_reg)
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
                if(is_immediate = '1') then -- Ottimizzazione: se la maschera d'ingresso ha 0 o 1 bit attivati, si passa direttamente allo stato S_DONE scrivendo il risultato nella RAM.
                    next_state <= S_DONE;
                else
                    next_state <= S_COORD_X;
                end if;
            when S_COORD_X =>
                next_state <= S_COORD_Y;
            when S_COORD_Y =>
                next_state <= S_CX;
            when S_CX =>
                if(distance_x > min_distance_reg) then -- Ottimizzazione: se la distanza X è già maggiore della distanza minima è inutile calcolare la distanza Y, passiamo direttamente al centroide successivo.
                    if(next_centroid = CELL_BITS + 1) then -- Se non ci sono altri centroidi da considerare si può passare allo stato finale, altriemnti si continua.
                        next_state <= S_DONE;
                    else
                        next_state <= S_CX;
                    end if;
                else
                    next_state <= S_CY;
                end if;
            when S_CY =>
                if(next_centroid = CELL_BITS + 1) then -- Se non ci sono altri centroidi da considerare si può passare allo stato finale, altriemnti si continua.
                    next_state <= S_DONE;
                else
                    next_state <= S_CX;
                end if;
            when S_DONE =>
                if(i_start = '1') then
                    next_state <= S_DONE;
                else
                    next_state <= S_RST;
                end if;
        end case;
    end process;
    
    -- Trova il valore effettivo di quello che sarà il prossimo centroide.
    -- Il centroide successivo dipende da next_state, cioè lo stato in cui andrà la FSM.
    -- Se il prossimo stato è S_CX si può passare al centroide successivo, specificato dal segnale next_centroid.
    -- Se il prossimo stato è S_CY bisogna tenere il valore del centroide corrente, specificato dal segnale centroid_num_reg.
    -- Assegnamenti: centroid_num_signal
    with next_state select centroid_num_signal <=
        0 when S_RST|S_START|S_INPUT_MASK|S_COORD_X|S_COORD_Y, -- Stati precedenti ai centroidi
        next_centroid when S_CX, -- Passa al prossimo centroide che verrà letto nello stato S_CX
        centroid_num_reg when S_CY, -- Mantiene lo stesso numero di centroide
        CELL_BITS + 1 when S_DONE; -- Stati successivi ai centroidi
    
    
    -- ############ INPUT ############
    
    -- Assegna all'ingresso del relativo registro il giusto segnale, che può essere il segnale i_data oppure il valore di uscita del registro.
    -- Assegnamenti:  input_mask_signal, x_coord_signal, y_coord_signal, x_value_signal
    input_mask_signal <= i_data when (current_state = S_INPUT_MASK) else input_mask_reg;
    x_coord_signal <= i_data when (current_state = S_COORD_X) else x_coord_reg;
    y_coord_signal <= i_data when (current_state = S_COORD_Y) else y_coord_reg;
    x_value_signal <= i_data when (current_state = S_CX) else x_value_reg;
    
    -- Segnala se la maschera di ingresso permette di avere una risposta immediata (cioè se ha 1 oppure 0 bit attivati).
    -- Per arrivare al risultato si è utilizzato un famoso "trucchetto": avere un bit attivato significa essere una potenza di 2.
    --- Ed N è una potenza di 2 se (N & N-1) = 0. Dove & rappresenta l'and bit a bit.
    -- Assegnamenti: is_immediate
    is_immediate <= '1' when (unsigned(input_mask_signal and std_logic_vector(unsigned(input_mask_signal) - 1)) = 0) else '0';
    
    
    -- ############ CALCOLO DISTANZA ED ELABORAZIONE ############
    
    -- Calcolo della distanza sulle ascisse, sulle ordinate e totale.
    -- Assegnamenti: distance_x, distance_y, distance_tot
    distance_x <= unsigned(abs(signed('0' & x_value_signal) - signed('0' & x_coord_signal)));
    distance_y <= unsigned(abs(signed('0' & i_data) - signed('0' & y_coord_signal)));
    distance_tot <= (distance_x + distance_y);

    -- Controlla se il centroide corrente è a distanza minima usando distance_tot.
    -- Se questa distanza è minore della distanza minima la si assegna a min_distance_signal e si sovrascrive out_mask_tmp_signal,
    -- se essa invece è uguale alla distanza minima si attiva il bit corrispondente al centroide in out_mask_tmp_signal.
    -- Assegnamenti: out_mask_tmp_signal, min_distance_signal
    check_min: process(current_state, centroid_num_reg, input_mask_signal, is_immediate, distance_tot, min_distance_reg, out_mask_tmp_reg)
    begin
        if(current_state = S_CY and distance_tot <= min_distance_reg) then -- Se siamo in uno stato in cui si calcola la distanza e se si ha un centroide a distanza minima...
            if(distance_tot = min_distance_reg) then -- Nuova distanza minima trovata.
                out_mask_tmp_signal <= out_mask_tmp_reg;
                out_mask_tmp_signal(centroid_num_reg - 1) <= '1';
                min_distance_signal <= min_distance_reg;
            else -- Centroide a distanza pari alla distanza minima.
                out_mask_tmp_signal <= (others => '0');
                out_mask_tmp_signal(centroid_num_reg - 1) <= '1';
                min_distance_signal <= distance_tot;
            end if;
        elsif(current_state = S_INPUT_MASK and is_immediate = '1') then -- Se è a risposta immediata possiamo assegnare immediatamente la maschera di uscita.
            out_mask_tmp_signal <= input_mask_signal;
            min_distance_signal <= (others => '1');
        elsif(current_state = S_RST) then  -- Preset dei segnali per la possibile prossima elaborazione (nel caso non ci sia segnale di reset esplicito).
            out_mask_tmp_signal <= (others => '0');
            min_distance_signal <= (others => '1');
        else
            out_mask_tmp_signal <= out_mask_tmp_reg;
            min_distance_signal <= min_distance_reg;
        end if;
    end process;
    
    
    -- ############ OUTPUT ############
    
    -- Assegna l'indirizzo di lettura della RAM in base allo stato successivo della FSM e al centroide successivo, il dato sarà quindi poi letto al ciclo di clock successivo.
    -- Assegnamenti: o_address
    with next_state select o_address <=
        (others => '-') when S_RST|S_START,
        std_logic_vector(START_ADDRESS + 0) when S_INPUT_MASK, -- Maschera d'ingresso
        std_logic_vector(START_ADDRESS + (CELL_BITS * 2) + 1) when S_COORD_X, -- X del punto da valutare
        std_logic_vector(START_ADDRESS + (CELL_BITS * 2) + 2) when S_COORD_y, -- Y del punto da valutare
        std_logic_vector(START_ADDRESS + (centroid_num_signal * 2) - 1) when S_CX, -- X centroidi
        std_logic_vector(START_ADDRESS + (centroid_num_signal * 2)) when S_CY, -- Y centroidi
        std_logic_vector(START_ADDRESS + (CELL_BITS * 2) + 3) when S_DONE; -- Maschera di uscita

    -- Assegnamento degli output che andranno in ingresso alla RAM (ram enable; ram write enable; ram data input), ciò viene fatto soltanto negli stati per cui è necessario.
    -- Assegnamenti: o_en, o_we, o_data
    o_en <= '1' when (current_state /= S_RST and current_state /= S_DONE) else '0';
    o_we <= '1' when (next_state = S_DONE and current_state /= S_DONE) else '0';
    o_data <= out_mask_tmp_signal when (next_state = S_DONE and current_state /= S_DONE) else (others => '-');
    
    -- Il segnale di fine elaborazione è abilitato quando si è nello stato S_DONE.
    -- Si assegna però a questo segnale out_done_tmp_reg, valore di uscita del registro. Ciò viene fatto per evitare glitch su questa uscita.
    -- Assegnamenti: o_done, out_done_tmp_signal
    out_done_tmp_signal <= '1' when (next_state = S_DONE) else '0';
    o_done <= out_done_tmp_reg;

end projectRetiLogiche;
