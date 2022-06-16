-- febit.vhd
-- DAPHNE FPGA AFE front end for one bit. This module does the following:
-- single LVDS receiver with IDELAY and ISERDES (master + slave cascaded)
-- LVDS input is DDR 14 bit
--
-- Jamieson Olsen <jamieson@fnal.gov>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity febit is
port(
    din_p, din_n:  std_logic;  -- LVDS data input from AFE chip
    clock:        in std_logic;  -- master clock
    clock7x:      in std_logic;  -- 7 x clock, from internal PLL, not from IOB
    reset:       in std_logic;
    bitslip:     in std_logic;
    load:        in std_logic;                     
    cntvalue:    in std_logic_vector(4 downto 0);  
    q:           out std_logic_vector(13 downto 0)
  );
end febit;

architecture febit_arch of febit is

    signal clock7xb: std_logic;
    signal din_ibuf, din_delayed : std_logic;
    signal icascade1, icascade2  : std_logic;
    
begin

    -- LVDS input buffer with internal termination

    IBUFDS_inst: IBUFDS
    generic map(
        DIFF_TERM    => TRUE,
        IBUF_LOW_PWR => FALSE,
        IOSTANDARD   => "LVDS"
    )
    port map(
        I  => din_p,
        IB => din_n,
        O  => din_ibuf
    );

    -- adjustable input delay 2.5ns in 32 78ps steps

    IDELAYE2_inst: IDELAYE2
    generic map(
        CINVCTRL_SEL          => "FALSE",
        DELAY_SRC             => "IDATAIN",
        HIGH_PERFORMANCE_MODE => "TRUE",
        IDELAY_TYPE           => "VAR_LOAD", -- simple parallel load mode 
        IDELAY_VALUE          => 0,
        PIPE_SEL              => "FALSE",
        REFCLK_FREQUENCY      => 200.0,   -- 200 MHz
        SIGNAL_PATTERN        => "DATA"
    )
    port map(
        CNTVALUEOUT => open,
        DATAOUT     => din_delayed,
        C           => clock,
        CE          => '0',
        CINVCTRL    => '0',
        CNTVALUEIN  => cntvalue,
        DATAIN      => '0', 
        IDATAIN     => din_ibuf,
        INC         => '0', 
        LD          => load,
        LDPIPEEN    => '0',
        REGRST      => '0' -- no reset on this primitive (but there IS a reset on the controller!)
    );

    clock7xb <= not clock7x;  -- LOCAL inversion on fast clock! Important! Don't use a separate BUFG net for this!

    -- master/slave cascaded pair of ISERDES serial-to-parallel converters, inspired by selectio_wiz 

    iserdese2_master_inst: ISERDESE2
    generic map(
        DATA_RATE         => "DDR",
        DATA_WIDTH        => 14,
        INTERFACE_TYPE    => "NETWORKING",
        DYN_CLKDIV_INV_EN => "FALSE", 
        DYN_CLK_INV_EN    => "FALSE",
        NUM_CE            => 2,
        OFB_USED          => "FALSE",
        IOBDELAY          => "IFD", 
        SERDES_MODE       => "MASTER"
    )
    port map(
        Q1                => q(0),
        Q2                => q(1),
        Q3                => q(2),
        Q4                => q(3),
        Q5                => q(4),
        Q6                => q(5),
        Q7                => q(6),
        Q8                => q(7),
        SHIFTOUT1         => icascade1,        -- connection to slave
        SHIFTOUT2         => icascade2,
        BITSLIP           => bitslip,          -- sync to clk
        CE1               => '1',              -- clock always enabled
        CE2               => '1', 
        CLK               => clock7x,           -- fast bit clock
        CLKB              => clock7xb,          -- inverted fast clock
        CLKDIV            => clock,             -- slow clock
        CLKDIVP           => '0',              -- not used tie low
        D                 => '0',              -- from iob, not used
        DDLY              => din_delayed,      -- from idelay use this one
        RST               => reset,            -- sync to clk
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
        IOBDELAY          => "IFD", 
        SERDES_MODE       => "SLAVE"
    )
   port map(
        Q1                => open,
        Q2                => open,
        Q3                => q(8),
        Q4                => q(9),
        Q5                => q(10),
        Q6                => q(11),
        Q7                => q(12),
        Q8                => q(13),
        SHIFTOUT1         => open,      -- not used on slave
        SHIFTOUT2         => open,
        SHIFTIN1          => icascade1, -- from master
        SHIFTIN2          => icascade2,
        BITSLIP           => bitslip,   
        CE1               => '1',       
        CE2               => '1',      
        CLK               => clock7x,    
        CLKB              => clock7xb,   
        CLKDIV            => clock, 
        CLKDIVP           => '0',       -- tie low
        D                 => '0',       -- not used on slave
        DDLY              => '0',       -- not used on slave
        RST               => reset,     -- sync to clk
        DYNCLKDIVSEL      => '0',
        DYNCLKSEL         => '0',
        OFB               => '0',
        OCLK              => '0',
        OCLKB             => '0',
        O                 => open
    );

end febit_arch;
