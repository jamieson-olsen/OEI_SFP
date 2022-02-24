-- fe.vhd
-- 40 channel front end based around AFE modules
-- (idelay and iserdes clocked by AFE dclk and fclk)
-- bitslip and delay adjustments on a per AFE basis
--
-- Jamieson Olsen <jamieson@fnal.gov>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

use work.daphne_package.all;

entity fe is
port(

    -- AFE interface (LVDS)

    dclk_p, dclk_n: in std_logic_vector(4 downto 0);
    fclk_p, fclk_n: in std_logic_vector(4 downto 0);
    data_p, data_n: in array_5x8_type;
    afe_clk_p, afe_clk_n:   out std_logic; -- 62.5MHz ref clk out to AFEs

    -- FPGA interface

    mclk:   in std_logic; -- master clock 62.5MHz
    sclk:   in std_logic; -- 200MHz system clock, constant, 
    reset:  in std_logic; -- async reset the front end logic (must do this before use!)

    delay_clk: in std_logic; -- clock for writing iserdes delay value
    delay_ld:  in std_logic_vector(4 downto 0); -- write delay value strobe
    delay_din: in std_logic_vector(4 downto 0); -- delay value to write range 0-31

    bitslip:  in  std_logic_vector(4 downto 0);
    fclk_out: out std_logic_vector(4 downto 0);
    dout:     out array_5x8x16_type

  );
end fe;

architecture fe_arch of fe is

    component febit
    port(
      
        dclk_p, dclk_n: in std_logic;  -- fast bit clock 437.5MHz, MRCC
        fclk_p, fclk_n: in std_logic;  -- slower frame clock 62.5MHz, MRCC
        data_p, data_n: in std_logic_vector(7 downto 0);
       
        delay_clk: in  std_logic; -- clock for writing iserdes delay value, common to all 8 channels
        delay_ld:  in  std_logic; -- load delay value, sync to delay_clk
        delay_din: in  std_logic_vector(4 downto 0);  -- delay value to write range 0-31, sync to delay_clk
    
        fclk_out:  out std_logic; -- recovered clock
        reset:     in  std_logic; -- reset sync to fclk_out
        bitslip:   in  std_logic; -- common to all 8 channels, sync to fclk_out
        dout:      out array_8x16_type -- recovered/aligned parallel data sync to fclk_out
    
      );
    end component;

    signal clock_out_temp: std_logic;

    signal rst_reg: std_logic_vector(15 downto 0);

    signal idelayctrl_rst_reg: std_logic;

begin

    -- Output the master clock to the AFEs 

    ODDR_inst: ODDR 
    generic map( DDR_CLK_EDGE => "OPPOSITE_EDGE" )
    port map(
        Q => clock_out_temp, 
        C => mclk,
        CE => '1',
        D1 => '1',
        D2 => '0',
        R  => '0',
        S  => '0');

    OBUFDS_inst: OBUFDS
        generic map(IOSTANDARD=>"LVDS")
        port map(
            I => clock_out_temp,
            O => afe_clk_p,
            OB => afe_clk_n);

    -- make the special reset pulse for the IDELAYCTRL module. needs to be minimum 59.28ns minimum

    rst_proc: process(sclk)
    begin
        if rising_edge(sclk) then -- sampling @ 200MHz
            rst_reg <= rst_reg(14 downto 0) & reset;
            if (rst_reg = X"0000") then
                idelayctrl_rst_reg <= '0';
            else
                idelayctrl_rst_reg <= '1';  -- high for 80ns
            end if;
        end if;
    end process rst_proc;
    
    -- this controller is REQUIRED for calibrating IDELAY elements...

    IDELAYCTRL_inst: IDELAYCTRL
        port map(
            REFCLK => sclk,
            RST    => idelayctrl_rst_reg, -- minimum pulse width is 60ns! MUST pulse this before using idelay!
            RDY    => open);

    -- instantiate the 5 AFEs

    gen_febit: for i in 4 downto 0 generate

        febit_inst: febit
        port map(
            dclk_p => dclk_p(i), dclk_n => dclk_n(i),
            fclk_p => fclk_p(i), fclk_n => fclk_n(i),
            data_p => data_p(i), data_n => data_n(i),
           
            delay_clk => delay_clk,
            delay_ld  => delay_ld(i),
            delay_din => delay_din,
        
            fclk_out  => fclk_out(i),
            reset     => reset,
            bitslip   => bitslip(i),
            dout      => dout(i));

    end generate gen_febit;

end fe_arch;
