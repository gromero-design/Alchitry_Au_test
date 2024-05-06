-------------------------------------------------------------------------------
--                    Top Module
-- fpga1_top : top level single processor
-------------------------------------------------------------------------------
-- Board: Alchitry Artix 7 xcA35T-1CPG236G
-- Flash: 
------------------------------------------------------------------------
--    fpgahelp.com
--    Copyright 1994-2024 GHRS
--    All rights reserved.                                 
--    GiLL Romero
------------------------------------------------------------------------   
--     Filename:  fpga1_top.vhd
--         Date:  Jan, 2001
--       Author:  Gill Romero
--        Email:  fpgahelp@gmail.com
--        Phone:  617-905-0508
------------------------------------------------------------------------   
--                   Model : Module RTL
--    Development Platform : Windows 10
--   VHDL Software Version : Altera Model Sim / Vivado sim
--          Synthesis Tool : Vivado 20.1, Xilinx Synthesis Tool version 18.x
--                           Quartus Prime 20.1, Altera Synthesis Tool version 17.1
-----------------------------------------------------------------------   
--
--  Description :
--  ***********
--  This is the Entity and architecture of the Artix7 basys3 development board.
--
--  -- I/O ports
-- LEDs    active high
-- Buttons active high
-- Segment active low
-- Anode   active low  

-- LEDs & SW & distribution on Alchitry I/O board
-- bits:   [23:16]      [15:8]       [7:0]
--        xLEDs[7:0]   xLEDs[7:0]   xLEDs[7:0]
--         SW3 [7:0]    SW2 [7:0]    SW1 [7:0]

--   References :
--   **********
--       work.fpga1_pkg.all; application specific package.
--
--   Dependencies :
--   fpga1_top
--       |____fpga1_top_uC16
--                |_______ uC16_xil(uC16)
--                            |_________ uart
--                            |_________ opus16_xil(wrapper)
--                                         |____ opus16_core 
--                                         |____ prog_ram    
--
------------------------------------------------------------------------   
-- Modification History : (Date, Initials, Comments)
-- 03-01-24 gill creation
-- 03-12-24 Alchitry setup
-- 03-23-24 single processor for test only

------------------------------------------------------------------------   
--
--  Revision Control:
--
--/*
-- * $Header:$
-- * $Log:$
-- */
------------------------------------------------------------------------
-- LIBRARY 

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_STD.all;
use IEEE.std_logic_unsigned.all;

library work;
use work.fpga1_pkg.all;

------------------------------------------------------------------------
-- ENTITY

entity fpga1_top is
    generic(ABUS_WIDTH      : integer          := 16;
            DBUS_WIDTH      : integer          := 16;
            OBUS_WIDTH      : integer          := 16);

    port (
        -- system interface
        sysrst_n  : in std_logic;  -- system reset, active LOW
        sysclk    : in std_logic;  -- main clock
        
        -- UART interface #1 Main
        uart_rx 	: in   std_logic; -- TxD FT232, RxD FPGA
        uart_tx		: out  std_logic; -- RxD FT232, TxD FPGA
        
        -- Local LEDs, I/Os
        led         : out std_logic_vector(HWLEDS_MSB downto 0); -- active high
        vp			: in std_logic;
        vn			: in std_logic;
        
        -- Peripherals, Au I/O board
        btnU        : in  std_logic; -- button UP
        btnL        : in  std_logic; -- button Left
        btnC        : in  std_logic; -- button Center
        btnR        : in  std_logic; -- button Rigth
        btnD        : in  std_logic; -- button Down
        xled        : out std_logic_vector(HWXLEDS_MSB downto 0); -- active high
        sw          : in  std_logic_vector(HWDIPSW_MSB downto 0); -- close / open
        seg         : out std_logic_vector(D7SEG_MSB downto 0); -- segment active low
        an          : out std_logic_vector(ANODE_MSB downto 0); -- anode active low
        dp          : out std_logic
        );
  
end entity fpga1_top;


-------------------------------------------------------------------------------
-- ARCHITECTURE: structural
-------------------------------------------------------------------------------

architecture struct of fpga1_top is
-------------------------------------------------------------------------------
-- Signal and Constant definitions
-------------------------------------------------------------------------------
signal clk			: std_logic;
signal reset		: std_logic;
signal locked		: std_logic;

-- From/To uC16 processor
signal s_user_led    : std_logic_vector(LEDS_MSB downto 0);  -- user LEDS
signal s_user_pb     : std_logic_vector(PUSHB_MSB downto 0);  -- push buttons
signal s_user_sw     : std_logic_vector(DIPSW_MSB downto 0);  -- dip switch

-- From/To hardware, Au I/O board
signal hw_led    : std_logic_vector(HWLEDS_MSB downto 0);  -- user LEDS
signal hw_xled   : std_logic_vector(HWXLEDS_MSB downto 0);  -- user LEDS
signal hw_pb     : std_logic_vector(HWPUSHB_MSB downto 0);  -- push buttons
signal hw_sw     : std_logic_vector(HWDIPSW_MSB downto 0);  -- dip switch

-- Control lines from uC16
signal s_page		: std_logic_vector(15 downto 0);
signal s_page_wr	: std_logic;
signal s_oport		: std_logic_vector(15 downto 0);

signal s_uart_txd_in	: std_logic;
signal s_uart_rxd_out	: std_logic;

-- External Registers
signal s_reg_100 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_101 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_102 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_103 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_104 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_105 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_106 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_107 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_108 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_109 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_10a 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_10b 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_10c 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_10d 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_10e 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_10f 	: std_logic_vector(DBUS_WIDTH-1 downto 0);

-------------------------------------------------------------------------------
-- Component Definitions
-------------------------------------------------------------------------------

component clk_wiz_0_c1c2
	port(
	    clk_in1         : in std_logic;
	    clk_out1        : out std_logic;
	    locked			: out std_logic;
	    reset           : in std_logic
	);
end component;
	
-- Opus1-16 custom processor
component fpga1_top_uc16
    generic(OPID : integer);
    port (
        -- system interface
        rst_in    : in std_logic;  -- system reset, active HIGH
        clk_in    : in std_logic;  -- main clock
        
        -- UART interface #1
        uart_txd_in    : in  std_logic; -- TxD FT232, RxD FPGA
        uart_rxd_out   : out std_logic; -- RxD FT232, TxD FPGA

        -- Control
        page        : out std_logic_vector(ABUS_WIDTH-1 downto 0);
        pagewr      : out std_logic;
        oport       : out std_logic_vector(DBUS_WIDTH-1 downto 0);
        
        -- Peripherals
		pb			: in  std_logic_vector(PUSHB_MSB downto 0);  -- push buttons
        led         : out std_logic_vector(LEDS_MSB downto 0); -- active high
        sw          : in  std_logic_vector(DIPSW_MSB downto 0); -- close / open
        seg         : out std_logic_vector(D7SEG_MSB downto 0); -- segment active low
        an          : out std_logic_vector(ANODE_MSB downto 0); -- anode active low
        dp          : out std_logic;
        vp          : in  std_logic;
        vn          : in  std_logic;
        
        -- Parallel Port Interconnect
        
        -- Registers Out
        reg100_io   : out std_logic_vector(15 downto 0); 
        reg101_io   : out std_logic_vector(15 downto 0); 
        reg102_io   : out std_logic_vector(15 downto 0); 
        reg103_io   : out std_logic_vector(15 downto 0); 
        reg104_io   : out std_logic_vector(15 downto 0); 
        reg105_io   : out std_logic_vector(15 downto 0); 
        reg106_io   : out std_logic_vector(15 downto 0); 
        reg107_io   : out std_logic_vector(15 downto 0); 

        -- Registers In
        reg108_io   : in  std_logic_vector(15 downto 0); 
        reg109_io   : in  std_logic_vector(15 downto 0); 
        reg10a_io   : in  std_logic_vector(15 downto 0); 
        reg10b_io   : in  std_logic_vector(15 downto 0); 
        reg10c_io   : in  std_logic_vector(15 downto 0); 
        reg10d_io   : in  std_logic_vector(15 downto 0); 
        reg10e_io   : in  std_logic_vector(15 downto 0); 
        reg10f_io   : in  std_logic_vector(15 downto 0)
        );
end component;

-------------------------------------------------------------------------------
-- BEGIN Architecture definition.
-------------------------------------------------------------------------------

begin

-------------------------------------------------------------------------------
-- Component Instantiation
-------------------------------------------------------------------------------
--Instantiation of sub-level modules
	clk1_2: clk_wiz_0_c1c2
	 PORT MAP(
		clk_in1		=> sysclk,
		clk_out1	=> clk,		-- 100MHz
		locked		=> locked,
		reset		=> '0'
	);

	master: fpga1_top_uc16
	generic map (
		OPID => 0)
    port map(
        -- system interface
        rst_in		=> reset,  -- system reset, active HIGH
        clk_in		=> clk,   -- main clock
        
        -- UART interface #1
        uart_txd_in		=> s_uart_txd_in,  -- TxD FT232, RxD FPGA
        uart_rxd_out	=> s_uart_rxd_out, -- RxD FT232, TxD FPGA
        -- Control
        page			=> s_page,
        pagewr			=> s_page_wr,
        oport			=> s_oport,
        
        -- Peripherals
        pb				=> s_user_pb,
        led				=> s_user_led,
        sw				=> s_user_sw,
        seg				=> seg,
        an				=> an,
        dp				=> dp,
        vp				=> vp,
        vn				=> vn,
        
        -- Registers Out
        reg100_io       => s_reg_100, --
        reg101_io       => s_reg_101, -- 
        reg102_io       => s_reg_102, --
        reg103_io       => s_reg_103, --
        reg104_io       => s_reg_104, -- 
        reg105_io       => s_reg_105, -- 
        reg106_io       => s_reg_106, -- 
        reg107_io       => s_reg_107, --

        -- Registers In
        reg108_io       => s_reg_108, --
        reg109_io       => s_reg_109, --
        reg10a_io       => s_reg_10a, --
        reg10b_io       => s_reg_10b, --
        reg10c_io       => s_reg_10c, --
        reg10d_io       => s_reg_10d, --
        reg10e_io       => s_reg_10e, --
        reg10f_io       => s_reg_10f  --
        );
        
    ---------------------------------------------------------------------------
    -- Register inputs
    ---------------------------------------------------------------------------
    process (clk)
    begin  -- slave resets
        if clk'event and clk = '1' then
            reset    <= not sysrst_n;
        end if;
    end process;

    process (clk)
    begin  --  push_buttons and switches
        if clk'event and clk = '1' then
            hw_pb    <= (btnU & btnR & btnC & btnL & btnD);
            hw_sw    <= sw;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Register output
    ---------------------------------------------------------------------------
    process (clk, reset)
    begin  -- LEDs
        if reset = '1' then
            led   <= (others => '0');
            xled  <= (others => '0');
        elsif clk'event and clk = '1' then
            led   <= hw_led;  -- LEDs active HIGH
            xled  <= hw_xled; -- LEDs active HIGH
        end if;
    end process;

    process (clk, reset)
    begin  -- LEDs
        if reset = '1' then
			uart_tx         <= '1'; -- pin2 UART #2
			s_uart_txd_in	<= '1';        -- pin3 UART #2
        elsif clk'event and clk = '1' then
			uart_tx			<= s_uart_rxd_out; -- pin2 UART #2
			s_uart_txd_in	<= uart_rx;        -- pin3 UART #2
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Concurrent statements
    ---------------------------------------------------------------------------
    
    ---------------------------------------------------------------------------
    -- I/O ports CONVERTER
    ---------------------------------------------------------------------------

    -- Outputs LEDs and 7-Seg display
    -- Normal operation
 	hw_led		<= locked & s_user_led(6 downto 0); -- new hwleds for 8 local leds?
    -- I/O board
	hw_xled		<= (s_reg_100(7 downto 0) & s_reg_101);
	
    -- Inputs switches and push buttons
    -- I/O board
	s_user_pb	<= hw_sw(23 downto 16) & "000" & hw_pb;
	s_user_sw	<= hw_sw(15 downto 0);
 	
	----------------------------------------------------------------------------
 	
	s_reg_108	<= x"00" & hw_sw(23 downto 16);
	s_reg_109	<= hw_sw(15 downto 0);
	s_reg_10a	<= x"00" & "000" & hw_pb;
	
	-- LEDs & SW & distribution on Alchitry board
	-- bits:   [23:16]      [15:8]       [7:0]
	--        LEDs[7:0]    LEDs[7:0]    LEDs[7:0]
	--        SW3 [7:0]    SW2 [7:0]    SW1 [7:0]
	
    ---------------------------------------------------------------------------
    -- Debug and Test Logic
    ---------------------------------------------------------------------------
	s_reg_10b	<= s_reg_103;
	s_reg_10c	<= s_reg_104;
	s_reg_10d	<= s_reg_105;
	s_reg_10e	<= s_reg_106;
	s_reg_10f	<= s_reg_107;

end architecture struct;                                    

-------------------------------------------------------------------------------
-- 
-------------------------------------------------------------------------------

-- CONFIGURATION

configuration fpga1_top_c of fpga1_top is

  for struct

  end for;
  
end fpga1_top_c;

-------------------------------------------------------------------------------
-- End of File
-------------------------------------------------------------------------------
