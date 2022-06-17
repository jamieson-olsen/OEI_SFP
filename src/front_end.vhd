-- front_end.vhd
-- DAPHNE FPGA AFE front end. Automatic alignment version.
--
-- Jamieson Olsen <jamieson@fnal.gov>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

use work.daphne_package.all;

entity front_end is
port(

    -- AFE interface 5 x 9 = 45 LVDS pairs (7..0 = data, 8 = fclk)

    afe_p: in array_5x9_type;
    afe_n: in array_5x9_type;

    afe_clk_p:  out std_logic; -- copy of 62.5MHz master clock sent to AFEs
    afe_clk_n:  out std_logic;

    -- FPGA interface

    clock:   in  std_logic; -- master clock 62.5MHz
    clock7x: in  std_logic; -- 7 x master clock = 437.5MHz
    sclk:    in  std_logic; -- 200MHz system clock, constant
    reset:   in  std_logic;
    done:    out std_logic_vector(4 downto 0); -- status of automatic alignment FSM
    warn:    out std_logic_vector(4 downto 0); -- warn of bit errors on the "FCLK" sync pattern
    errcnt:  out array_5x8_type; -- bit error count on the "FCLK" pattern
    dout:    out array_5x9x14_type -- data synchronized to clock
  );
end front_end;

architecture fe_arch of front_end is

    component auto_afe
    port(
        afe_p: in std_logic_vector(8 downto 0);
        afe_n: in std_logic_vector(8 downto 0);
        clock:   in  std_logic;  -- master clock 62.5MHz
        clock7x: in  std_logic;  -- 7 x master clock = 437.5MHz
        reset:   in  std_logic;
        done:    out std_logic;
        warn:    out std_logic;
        errcnt:  out std_logic_vector(7 downto 0);
        dout:    out array_9x14_type
      );
    end component;

    signal clock_out_temp: std_logic;
    signal rst_reg: std_logic_vector(15 downto 0);
    signal idelayctrl_rst_reg: std_logic;

begin

    -- Forward the master clock to the AFEs (via ext clock fanout chip U20)

    ODDR_inst: ODDR 
    generic map( DDR_CLK_EDGE => "OPPOSITE_EDGE" )
    port map(
        Q => clock_out_temp, 
        C => clock,
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
    
    -- this controller is required for calibrating IDELAY elements...

    IDELAYCTRL_inst: IDELAYCTRL
        port map(
            REFCLK => sclk,
            RST    => idelayctrl_rst_reg, -- minimum pulse width is 60ns! MUST pulse this before using idelay!
            RDY    => open);

    -- make 5 automatic AFE modules

    gen_afe: for i in 4 downto 0 generate
        afe_inst: auto_afe
        port map(
            afe_p => afe_p(i),
            afe_n => afe_n(i),
            clock => clock,
            clock7x => clock7x,
            reset => reset,
            done => done(i),
            warn => warn(i),
            errcnt => errcnt(i),
            dout => dout(i)
        );
    end generate gen_afe;

end fe_arch;
