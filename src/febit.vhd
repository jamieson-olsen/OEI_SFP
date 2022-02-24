-- febit.vhd
-- aligment and deskew + serial to parallel converter for 1 AFE chip
-- uses the fast DCLK and slower FCLK from the AFE.
-- delay and bitslip controls are common to all 8 data channels
-- this module lives in one IO Bank in the FPGA, one clock region
--
-- Jamieson Olsen <jamieson@fnal.gov>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

use work.daphne_package.all;

entity febit is
port(

    -- AFE interface (LVDS)

    dclk_p, dclk_n: in std_logic;  -- fast bit clock 437.5MHz, MRCC
    fclk_p, fclk_n: in std_logic;  -- slower frame clock 62.5MHz, MRCC
    data_p, data_n: in std_logic_vector(7 downto 0);

    -- FPGA interface

    delay_clk: in  std_logic; -- clock for writing iserdes delay value, common to all 8 channels
    delay_ld:  in  std_logic; -- load delay value, sync to delay_clk
    delay_din: in  std_logic_vector(4 downto 0);  -- delay value to write range 0-31, sync to delay_clk

    fclk_out:  out std_logic; -- recovered clock
    reset:     in  std_logic; -- reset sync to fclk_out
    bitslip:   in  std_logic; -- common to all 8 channels, sync to fclk_out
    dout:      out array_8x16_type -- recovered/aligned parallel data sync to fclk_out

  );
end febit;

architecture febit_arch of febit is

    signal fclk_ibuf, fclk: std_logic;
    signal dclk_ibuf, dclk : std_logic;
    signal dclkb_ibuf, dclkb : std_logic;
    signal d_ibuf, ddly: std_logic_vector(7 downto 0);
    signal icascade1, icascade2: std_logic_vector(7 downto 0);

begin

    -- LVDS input buffers...

    FCLK_IBUFGDS_inst: IBUFDS 
    generic map( DIFF_TERM => TRUE, IBUF_LOW_PWR => FALSE, IOSTANDARD => "LVDS_25" )
    port map( I  => fclk_p, IB => fclk_n, O => fclk );

    --FCLK_BUFIO_inst: BUFIO
    --port map ( I => fclk_ibuf, O => fclk );

    DCLK_IBUFDS_inst: IBUFDS_DIFF_OUT
    generic map( DIFF_TERM => TRUE, IBUF_LOW_PWR => FALSE, IOSTANDARD => "LVDS_25" )
    port map( I  => dclk_p, IB => dclk_n, O => dclk, OB => dclkb );

    --DCLK_BUFIO_inst: BUFIO
    --port map ( I => dclk_ibuf, O => dclk );

    --DCLKB_BUFIO_inst: BUFIO
    --port map ( I => dclkb_ibuf, O => dclkb );

    gen_buf: for i in 7 downto 0 generate

        IBUFDS_inst: IBUFDS
        generic map( DIFF_TERM => TRUE, IBUF_LOW_PWR => FALSE, IOSTANDARD => "LVDS_25" )
        port map( I  => data_p(i), IB => data_n(i), O => d_ibuf(i) );

    end generate gen_buf;  

    -- Delay the data inputs...

    idelay_gen: for i in 7 downto 0 generate

        IDELAYE2_inst: IDELAYE2
        generic map(
            CINVCTRL_SEL          => "FALSE",
            DELAY_SRC             => "IDATAIN",
            HIGH_PERFORMANCE_MODE => "TRUE",
            IDELAY_TYPE           => "VAR_LOAD", 
            IDELAY_VALUE          => 0,
            PIPE_SEL              => "FALSE",
            REFCLK_FREQUENCY      => 200.0,
            SIGNAL_PATTERN        => "DATA")
        port map(
            CNTVALUEOUT => open,
            DATAOUT     => ddly(i),
            C           => delay_clk,
            CE          => '0',
            CINVCTRL    => '0',
            CNTVALUEIN  => delay_din,
            DATAIN      => '0', 
            IDATAIN     => d_ibuf(i),
            INC         => '0', 
            LD          => delay_ld,
            LDPIPEEN    => '0',
            REGRST      => '0');

    end generate idelay_gen;

    -- Convert serial to parallel...

    iserdes_gen: for i in 7 downto 0 generate

        iserdese2_master_inst: ISERDESE2
        generic map(
            DATA_RATE         => "DDR",
            DATA_WIDTH        => 14,
            INTERFACE_TYPE    => "NETWORKING",
            DYN_CLKDIV_INV_EN => "FALSE", 
            DYN_CLK_INV_EN    => "FALSE",
            NUM_CE            => 2,
            OFB_USED          => "FALSE",
            IOBDELAY          => "BOTH", 
            SERDES_MODE       => "MASTER"
        )
        port map(
            Q1                => dout(i)(0),
            Q2                => dout(i)(1),
            Q3                => dout(i)(2),
            Q4                => dout(i)(3),
            Q5                => dout(i)(4),
            Q6                => dout(i)(5),
            Q7                => dout(i)(6),
            Q8                => dout(i)(7),
            SHIFTOUT1         => icascade1(i),   -- connection to slave
            SHIFTOUT2         => icascade2(i),
            BITSLIP           => bitslip,        -- sync to fclk
            CE1               => '1',            -- clock always enabled
            CE2               => '1', 
            CLK               => dclk,           -- fast bit clock
            CLKB              => dclkb,          -- inverted fast clock
            CLKDIV            => fclk,           -- slow clock
            CLKDIVP           => '0',            -- not used tie low
            D                 => '0',            -- from iob, not used
            DDLY              => ddly(i),        -- from idelay use this one
            RST               => reset,          -- sync to fclk
            SHIFTIN1          => '0',
            SHIFTIN2          => '0',
            DYNCLKDIVSEL      => '0',
            DYNCLKSEL         => '0',
            OFB               => '0',
            OCLK              => '0',
            OCLKB             => '0',
            O                 => open
        );                      
    
        iserdese2_slave_inst: ISERDESE2
        generic map(
            DATA_RATE         => "DDR",
            DATA_WIDTH        => 14,
            INTERFACE_TYPE    => "NETWORKING",
            DYN_CLKDIV_INV_EN => "FALSE",
            DYN_CLK_INV_EN    => "FALSE",
            NUM_CE            => 2,
            OFB_USED          => "FALSE",
            IOBDELAY          => "BOTH", 
            SERDES_MODE       => "SLAVE"
        )
       port map(
            Q1                => open,
            Q2                => open,
            Q3                => dout(i)(8),
            Q4                => dout(i)(9),
            Q5                => dout(i)(10),
            Q6                => dout(i)(11),
            Q7                => dout(i)(12),
            Q8                => dout(i)(13),
            SHIFTOUT1         => open,         -- not used on slave
            SHIFTOUT2         => open,
            SHIFTIN1          => icascade1(i), -- from master
            SHIFTIN2          => icascade2(i),
            BITSLIP           => bitslip,      -- sync to fclk
            CE1               => '1',          -- always clock enable
            CE2               => '1',      
            CLK               => dclk,         -- fast bit clock
            CLKB              => dclkb,        -- inverted fast clock
            CLKDIV            => fclk, 
            CLKDIVP           => '0',       -- tie low
            D                 => '0',       -- not used on slave
            DDLY              => '0',       -- not used on slave
            RST               => reset,     -- sync to fclk
            DYNCLKDIVSEL      => '0',
            DYNCLKSEL         => '0',
            OFB               => '0',
            OCLK              => '0',
            OCLKB             => '0',
            O                 => open
        );

    dout(i)(14) <= '0';
    dout(i)(15) <= '0';

    end generate iserdes_gen;

    fclk_out <= fclk;

end febit_arch;
