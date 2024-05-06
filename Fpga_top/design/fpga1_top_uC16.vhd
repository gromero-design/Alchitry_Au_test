-------------------------------------------------------------------------------
--                    Top Module
-- fpga1_top_uc16 : master processor (_uc16)
-- Opus1 - 16 bits processor
-------------------------------------------------------------------------------
--    fpgahelp.com
--    Copyright 1994-2024 GHRS
--    All rights reserved.                                 
--    GiLL Romero
------------------------------------------------------------------------   
--     Filename:  fpga1_top_uc16.vhd
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
--
--   References :
--   **********
--       work.fpga1_pkg.all; application specific package.
--
--   Nomenclature:
--   ************
--     suffixes:
--             _o => output
--             _n => output inverted (negated)
--             _b => input  inverted (negated)
--             _r => registered signal
--
--     alternates: (not used in modules / submodules)
--             _l => active low (low)
--
--   Dependencies :
--   ************
--
--   entity_name(arch_name1, arch_name2,..)
--
-- fpga1_top(rtl)
--        |__ clk
--        |__ reset 
--        |__ uC16u_xil(rtl)
--        |      |___ uart(rtl)
--        |      |___ Opus16_xil(rtl)
--        |      |          |____ opus16_core (ip) 
--        |      |          |____ prog_ram    (ip)
--        |__ fpga1_regs(rtl)
--        |__ fpga1_regs(rtl)

------------------------------------------------------------------------
-- Modification History : (Date, Initials, Comments)
-- 01-01-24 gill creation
------------------------------------------------------------------------   
--
--  Revision Control:
--
--/*
-- * $Header:$
-- * $Log:$
-- */
-- Base Address Register defined at the top
-- BASE_ADDR_REG = x"0000"
-- register address = BASE_ADDR_REG(15:4) & s_io_addr(3 downto 0)

------------------------------------------------------------------------
-- PBUS_WIDTH defines the size of the program memory
-- 16 = 64K
-- 15 = 32K
-- 14 = 16K
-- 13 =  8K
-- 12 =  4K
-- 11 =  2K
-- 10 =  1K
------------------------------------------------------------------------

------------------------------------------------------------------------
-- LIBRARY 

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_STD.all;
use IEEE.std_logic_unsigned.all;

library work;
use work.fpga1_pkg.all;

------------------------------------------------------------------------
-- ENTITY   ALCHITRY

entity fpga1_top_uc16 is
    generic(BASE_ADDR_REG0	: std_logic_vector := x"0000";-- local space x0000-x000F
            BASE_ADDR_REG1	: std_logic_vector := x"0100";-- user space x0100-x010F
            PBUS_WIDTH      : integer          := 14;     -- 16K or x"4000" program RAM
            ABUS_WIDTH      : integer          := 16;
            DBUS_WIDTH      : integer          := 16;
            OBUS_WIDTH      : integer          := 16;
            UART_CLOCK		: integer          := 100000000; --100 000 000 MHz
            UART_BRATE		: integer          :=    115200;
       		UART_ADDR    	: std_logic_vector := x"0010";-- uC16 space x0000-x00FF
    		TEST_UART		: std_logic        :='0';
            TEST_CFG        : std_logic_vector := x"2024";-- YYYY
            TEST_DATE       : std_logic_vector := x"0502";-- MMDD : fpga1_top date
            OPID			: integer          := 0; -- processor ID
            DEBUG_ENABLED	: integer          := 0);

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
		pb			: in  std_logic_vector(PUSHB_MSB downto 0);  -- push buttons        btnU        : in  std_logic; -- active high
        led		    : out std_logic_vector(LEDS_MSB downto 0); -- active high
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

end entity fpga1_top_uc16;


-------------------------------------------------------------------------------
-- ARCHITECTURE: structural
-------------------------------------------------------------------------------

architecture rtl of fpga1_top_uc16 is
-------------------------------------------------------------------------------
-- Signal and Constant definitions
-------------------------------------------------------------------------------
constant BOOT_ADDRESS   : integer := 2**PBUS_WIDTH-256;
constant PCODE_OVW_BIT  : integer := 1;  -- code protection bit
constant TARGET_RST_BIT : integer := 0;  -- target reset bit

-- System clock and reset.
signal clk				: std_logic;
signal s_reset			: std_logic;

signal s_40nScnt    	: std_logic_vector(2 downto 0); -- 40 nano Sec sync counter
signal s_nScnt      	: std_logic_vector(31 downto 0); -- nano Sec sync counter
signal s_Spulse			: std_logic;    -- 1.0  S pulse
signal s_Spulse_ack		: std_logic;    -- 1.0  S pulse ack
signal s_Second			: std_logic;    -- 1.0  S square wave
                    	
-- I/O signals      	
signal s_user_led   	: std_logic_vector(LEDS_MSB downto 0);  -- user LEDS
signal s_user_pb    	: std_logic_vector(PUSHB_MSB downto 0);  -- push buttons
signal s_user_sw    	: std_logic_vector(DIPSW_MSB downto 0);  -- dip switch
signal s_blueled    	: std_logic;
signal s_hitled     	: std_logic;
signal s_seg			: std_logic_vector(D7SEG_MSB downto 0);
signal s_an				: std_logic_vector(ANODE_MSB downto 0);
signal s_dp				: std_logic;
                    	
-- uC16 interface
signal s_uC_addr     : std_logic_vector(ABUS_WIDTH-1 downto 0);
signal s_uC_page     : std_logic_vector(ABUS_WIDTH-1 downto 0);
signal s_uC_pagewr   : std_logic;
signal s_uC_down     : std_logic;
signal s_uC_dinp     : std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_uC_dinp0    : std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_uC_dinp1    : std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_uC_dvld     : std_logic;
signal s_uC_dout     : std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_uC_dout_r0  : std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_uC_dout_r1  : std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_uC_wr       : std_logic;
signal s_uC_rd       : std_logic;
signal s_uC_mio      : std_logic;
signal s_uC_busen    : std_logic;
signal s_uC_oport    : std_logic_vector(OBUS_WIDTH-1 downto 0);
signal s_uC_sync     : std_logic;
signal s_uC_hcode    : std_logic;
signal s_uC_dbus     : std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_uC_vopc     : std_logic; -- 0=no protect, 1=protect
signal s_uC_pcode    : std_logic; -- 0=no protect, 1=protect
signal s_uC_ecode    : std_logic_vector(ABUS_WIDTH-1 downto 0); -- end code protection
signal s_uC_bcode    : std_logic_vector(ABUS_WIDTH-1 downto 0); -- start of boot code protection
signal s_uC_pcode_r  : std_logic; -- 0=no protect, 1=protect
signal s_uC_ecode_r  : std_logic_vector(ABUS_WIDTH-1 downto 0); -- end code protection
signal s_uC_bcode_r  : std_logic_vector(ABUS_WIDTH-1 downto 0); -- start of boot code protection
-- regs/ios
signal s_uC_wregs    : std_logic;
signal s_uC_rregs    : std_logic;
    
-- Control lines from uC16
signal s_serial_rxd : std_logic;
signal s_serial_txd : std_logic;
signal s_tp1		: std_logic;	-- available test point/UART
signal s_tp2		: std_logic;	-- available test point/UART
signal s_tpack		: std_logic;	-- s_tp acknowledge
signal s_uC_iport    : std_logic_vector(7 downto 0);

signal s_heartbeat  : std_logic;
signal s_timerbeat  : std_logic;

-- Internal Registers
signal s_reg_cs0	: std_logic;
signal s_base_adr0	: std_logic_vector(ABUS_WIDTH-1 downto 0);
signal s_reg_00 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_01 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_02 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_03 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_04 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_05 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_06 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_07 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_08 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_09 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_0a 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_0b 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_0c 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_0d 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_0e 	: std_logic_vector(DBUS_WIDTH-1 downto 0);
signal s_reg_0f 	: std_logic_vector(DBUS_WIDTH-1 downto 0);

-- External Registers
signal s_reg_cs1	: std_logic;
signal s_base_adr1	: std_logic_vector(ABUS_WIDTH-1 downto 0);
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

-- XADC
signal s_daddr_in            : std_logic_vector (6 downto 0); -- Address bus for the dynamic reconfiguration port
signal s_den_in              : std_logic;                     -- Enable Signal for the dynamic reconfiguration port
signal s_di_in               : std_logic_vector (15 downto 0);-- Input data bus for the dynamic reconfiguration port
signal s_dwe_in              : std_logic;                     -- Write Enable for the dynamic reconfiguration port
signal s_do_out              : std_logic_vector (15 downto 0);-- Output data bus for dynamic reconfiguration port
signal s_adcmm_data          : std_logic_vector (15 downto 0);-- Output data bus
signal s_drdy_out            : std_logic;                     -- Data ready signal for the dynamic reconfiguration port
signal s_dclk_in             : std_logic;                     -- Clock input for the dynamic reconfiguration port
signal s_busy_out            : std_logic;                     -- ADC Busy signal
signal s_channel_out         : std_logic_vector (4 downto 0); -- Channel Selection Outputs
signal s_eoc_out             : std_logic;                     -- End of Conversion Signal
signal s_eos_out             : std_logic;                     -- End of Sequence Signal
signal s_ot_out              : std_logic;                     -- Over-Temperature alarm output
signal s_user_temp_alarm_out : std_logic;                     -- Temperature-sensor alarm output
signal s_alarm_out           : std_logic;                     -- OR'ed output of all the Alarms
          
signal s_raw_data            : std_logic_vector (15 downto 0); 
signal s_degreeC             : std_logic_vector (15 downto 0); 
signal s_degreeF             : std_logic_vector (15 downto 0);
signal s_voltsAux6           : std_logic_vector (15 downto 0); 
signal s_data_rdy_out        : std_logic; 
          

-- for debug
signal s_target_rst	: std_logic;

-------------------------------------------------------------------------------
-- Component Definitions
-------------------------------------------------------------------------------
-- uC16 processor with Opus1 IP core, 1xUART, 16kx16 program
component uC16
    generic(PBUS_WIDTH  : integer;
            ABUS_WIDTH  : integer := 16;
            DBUS_WIDTH  : integer := 16;
            OBUS_WIDTH  : integer := 16;
    		UART_CLOCK	: integer;
    		UART_BRATE 	: integer;
    		UART_ADDR	: std_logic_vector;
    		TEST_UART	: std_logic;
    		OPID		: integer);
    port (
        -- system interface
        reset       : in std_logic;
        clk         : in std_logic;

        -- Serial Interface RS232 / RS422 #1
        serial_rxd		: in  std_logic;    -- receive data
        serial_txd		: out std_logic;    -- transmit dat
		tp1				: in std_logic;	    -- test input
		tp2				: in std_logic;	    -- test input
		tpack			: out std_logic;    -- test acknowledge
        uC_iport    	: in  std_logic_vector(7 downto 0);

		-- User Misc.
        heartbeat   : out std_logic;   -- I'm alive
        timerbeat	: out std_logic;   -- I'm alive
        secPulse    : in  std_logic;
        secPulse_ack: out std_logic;
        
        -- External Interface Port
        uC_addr     : out std_logic_vector(ABUS_WIDTH-1 downto 0);
        uC_page     : out std_logic_vector(ABUS_WIDTH-1 downto 0);
        uC_pagewr   : out std_logic;
        uC_down     : out std_logic;
        uC_dinp     : in  std_logic_vector(DBUS_WIDTH-1 downto 0);
        uC_dvld     : in  std_logic;
        uC_rd       : out std_logic;
        uC_dout     : out std_logic_vector(DBUS_WIDTH-1 downto 0);
        uC_wr       : out std_logic;
        uC_mio      : out std_logic;    -- memory=1 or io=0 access
        uC_busen    : out std_logic;    -- bus enable
        uC_oport    : out std_logic_vector(OBUS_WIDTH-1 downto 0);
        uC_sync		: out std_logic;
        uC_hcode	: out std_logic;
        uC_dbus     : out std_logic_vector(DBUS_WIDTH-1 downto 0); -- DEBUG BUS program memory
        uC_vopc     : out std_logic; -- DEBUG BUS opcode cycle
        uC_pcode    : in  std_logic; -- 0=no protect, 1=protect
        uC_ecode    : in  std_logic_vector(ABUS_WIDTH-1 downto 0); -- end code protection
        uC_bcode    : in  std_logic_vector(ABUS_WIDTH-1 downto 0)  -- start of boot code protection
        );
end component;

component fpga1_regs8x8
    port (
        -- system interface
        reset      : in std_logic;   -- system reset
        clk        : in std_logic;   -- 100MHz
        
        -- IO Bus from uC16
        uC_addr     : in  std_logic_vector(15 downto 0);
        uC_din      : in  std_logic_vector(15 downto 0);
        uC_cs		: in  std_logic;
        uC_write    : in  std_logic;
        uC_read     : in  std_logic;
        uC_dout     : out std_logic_vector(15 downto 0);

        -- Registers Out
        reg00_io    : out std_logic_vector(15 downto 0); 
        reg01_io    : out std_logic_vector(15 downto 0); 
        reg02_io    : out std_logic_vector(15 downto 0); 
        reg03_io    : out std_logic_vector(15 downto 0); 
        reg04_io    : out std_logic_vector(15 downto 0); 
        reg05_io    : out std_logic_vector(15 downto 0); 
        reg06_io    : out std_logic_vector(15 downto 0); 
        reg07_io    : out std_logic_vector(15 downto 0); 

        -- Registers In
        reg08_io    : in  std_logic_vector(15 downto 0); 
        reg09_io    : in  std_logic_vector(15 downto 0); 
        reg0a_io    : in  std_logic_vector(15 downto 0); 
        reg0b_io    : in  std_logic_vector(15 downto 0); 
        reg0c_io    : in  std_logic_vector(15 downto 0); 
        reg0d_io    : in  std_logic_vector(15 downto 0); 
        reg0e_io    : in  std_logic_vector(15 downto 0); 
        reg0f_io    : in  std_logic_vector(15 downto 0)
        );
end component;

component xadc_wiz_0
    port (
          daddr_in        : in  STD_LOGIC_VECTOR (6 downto 0); -- Address bus for the dynamic reconfiguration port
          den_in          : in  STD_LOGIC;                     -- Enable Signal for the dynamic reconfiguration port
          di_in           : in  STD_LOGIC_VECTOR (15 downto 0);-- Input data bus for the dynamic reconfiguration port
          dwe_in          : in  STD_LOGIC;                     -- Write Enable for the dynamic reconfiguration port
          do_out          : out STD_LOGIC_VECTOR (15 downto 0);-- Output data bus for dynamic reconfiguration port
          drdy_out        : out STD_LOGIC;                     -- Data ready signal for the dynamic reconfiguration port
          dclk_in         : in  STD_LOGIC;                     -- Clock input for the dynamic reconfiguration port
          busy_out        : out STD_LOGIC;                     -- ADC Busy signal
          channel_out     : out STD_LOGIC_VECTOR (4 downto 0); -- Channel Selection Outputs
          eoc_out         : out STD_LOGIC;                     -- End of Conversion Signal
          eos_out         : out STD_LOGIC;                     -- End of Sequence Signal
          ot_out          : out STD_LOGIC;                     -- Over-Temperature alarm output
          user_temp_alarm_out : out  STD_LOGIC;                -- Temperature-sensor alarm output
          alarm_out       : out STD_LOGIC;                     -- OR'ed output of all the Alarms
          vp_in           : in  STD_LOGIC; -- Dedicated Analog Input Pair
          vn_in           : in  STD_LOGIC; -- Dedicated Analog Input Pair
          vauxp6          : in  STD_LOGIC;
          vauxn6          : in  STD_LOGIC
          );
end component;

component adcmm
    port (
          -- Outputs
          data_out        : out STD_LOGIC_VECTOR (15 downto 0);-- Output data
          data_rdy_out    : out STD_LOGIC;                     -- pipelined ready out
          
          -- Inputs
          clk             : in  STD_LOGIC;
          channel_sel     : in  STD_LOGIC_VECTOR (2 downto 0); -- Input data
          channel         : in  STD_LOGIC_VECTOR (4 downto 0); -- Channel Selection Outputs
          data_in         : in  STD_LOGIC_VECTOR (15 downto 0); -- Input data
          data_rdy_in     : in  STD_LOGIC                      -- data ready
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
    uC16_i: uC16
		generic map (
			PBUS_WIDTH  => PBUS_WIDTH,
			UART_CLOCK  => UART_CLOCK,
    		UART_BRATE  => UART_BRATE,
			UART_ADDR	=> UART_ADDR,
			TEST_UART	=> TEST_UART,
			OPID		=> OPID)
		
		port map (
			reset        => s_reset,
			clk          => clk,

			-- Serial Interface RS232 / RS422, main UART #1
			serial_rxd	 => s_serial_rxd,
			serial_txd	 => s_serial_txd,
			tp1			 => s_tp1,
			tp2			 => s_tp2,
			tpack		 => s_tpack,
			uC_iport     => s_uC_iport,
			
			-- User Misc.
			heartbeat    => s_heartbeat,
			timerbeat    => s_timerbeat,
			secPulse     => s_Spulse,
			secPulse_ack => s_Spulse_ack,
						
        	-- External Interface Port
			uC_addr      => s_uC_addr,
			uC_page      => s_uC_page,
			uC_pagewr    => s_uC_pagewr,
			uC_down      => s_uC_down,
			uC_dinp      => s_uC_dinp,
			uC_dvld      => s_uC_dvld,
			uC_rd        => s_uC_rd,
			uC_dout      => s_uC_dout,
			uC_wr        => s_uC_wr,
			uC_mio       => s_uC_mio,
			uC_busen     => s_uC_busen, 
			uC_oport     => s_uC_oport, 
			uC_sync      => s_uC_sync,  -- 1 machine cycle = 4 clocks
			uC_hcode     => s_uC_hcode,
			uC_dbus      => s_uC_dbus,
			uC_vopc      => s_uC_vopc,
			uC_pcode     => s_uC_pcode, -- 0=no protect, 1=protect   
			uC_ecode     => s_uC_ecode, -- end of program            
			uC_bcode     => s_uC_bcode  -- start of boot code 16K-256
        );
        
              
    regs_0: fpga1_regs8x8
        PORT MAP(
            -- system interface
            reset       => s_reset,
            clk         => clk,
            
            -- IO Bus from uC16
            uC_addr     => s_uC_addr, 
            uC_din      => s_uC_dout_r0,  
            uC_cs       => s_reg_cs0,
            uC_write    => s_uC_wregs,
            uC_read     => s_uC_rregs,
            uC_dout     => s_uC_dinp0,

            -- Registers Out
            reg00_io    => s_reg_00,-- an,7seg,dp
            reg01_io    => s_reg_01,-- Target reset and ID
            reg02_io    => s_reg_02,-- ECODE end of protected RAM area                            
            reg03_io    => s_reg_03,-- BCODE end of writable  RAM area                            
            reg04_io    => s_reg_04,-- Test register
            reg05_io    => s_reg_05,-- low  word for 1 mSec timer
            reg06_io    => s_reg_06,-- high work for 1 mSec timer
            reg07_io    => s_reg_07,-- triger src[15:14], scope src[13:12], PCODE[1], target rst[0]

            -- Registers In
            reg08_io    => s_reg_08,--
            reg09_io    => s_reg_09,--
            reg0a_io    => s_reg_0a,
            reg0b_io    => s_reg_0b,
            reg0c_io    => s_reg_0c,
            reg0d_io    => s_reg_0d,
            reg0e_io    => s_reg_0e,
            reg0f_io    => s_reg_0f
            );
            
    regs_1: fpga1_regs8x8 -- 8x8
        PORT MAP(
            -- system interface
            reset       => s_reset,
            clk         => clk,
            
            -- IO Bus from uC16
            uC_addr     => s_uC_addr, 
            uC_din      => s_uC_dout_r1,  
            uC_cs       => s_reg_cs1,
            uC_write    => s_uC_wregs,
            uC_read     => s_uC_rregs,
            uC_dout     => s_uC_dinp1,

            -- Registers Out
            reg00_io    => s_reg_100, --
            reg01_io    => s_reg_101, -- 
            reg02_io    => s_reg_102, --
            reg03_io    => s_reg_103, --
            reg04_io    => s_reg_104, -- 
            reg05_io    => s_reg_105, -- 
            reg06_io    => s_reg_106, -- 
            reg07_io    => s_reg_107, --

            -- Registers In
            reg08_io    => s_reg_108, --
            reg09_io    => s_reg_109, --
            reg0a_io    => s_reg_10a, --
            reg0b_io    => s_reg_10b, --
            reg0c_io    => s_reg_10c, --
            reg0d_io    => s_reg_10d, --
            reg0e_io    => s_reg_10e, --
            reg0f_io    => s_reg_10f  --
            );

    xadc_1: xadc_wiz_0
        PORT MAP(
          daddr_in            => s_daddr_in,            
          den_in              => s_den_in,              
          di_in               => s_di_in,               
          dwe_in              => s_dwe_in,              
          do_out              => s_do_out,              
          drdy_out            => s_drdy_out,            
          dclk_in             => clk,             
          busy_out            => s_busy_out,            
          channel_out         => s_channel_out,         
          eoc_out             => s_eoc_out,             
          eos_out             => s_eos_out,             
          ot_out              => s_ot_out,              
          user_temp_alarm_out => s_user_temp_alarm_out, 
          alarm_out           => s_alarm_out,           
          vp_in               => vp,         
          vn_in               => vn,
          vauxp6              => '0',               
          vauxn6              => '0'               
          );
          
    adcmm_1: adcmm
        PORT MAP(
          -- Outputs
          data_out        => s_adcmm_data,
          data_rdy_out    => s_data_rdy_out,
                    
          -- Inputs
          clk             => clk,
          channel_sel     => s_reg_01(10 downto 8),
          channel         => s_channel_out,
          data_in         => s_do_out,
          data_rdy_in     => s_eoc_out
          );
          
    ---------------------------------------------------------------------------
    -- Register inputs
    ---------------------------------------------------------------------------
    process (clk)
    begin  -- push_buttons and switches
        if clk'event and clk = '1' then
            s_user_pb    <= pb;
            s_user_sw    <= sw;
        end if;
    end process;

    process (clk)
    begin  -- push_buttons and switches
        if clk'event and clk = '1' then
            s_uC_dout_r0 <= s_uC_dout;
            s_uC_dout_r1 <= s_uC_dout;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Register output
    ---------------------------------------------------------------------------
    process (clk, s_reset)
    begin  -- process LEDs
        if s_reset = '1' then
            led <= (others => '0');
        elsif clk'event and clk = '1' then
            led <= s_user_led; -- LEDs active HIGH
        end if;
    end process;

    process (clk, s_reset)
    begin  -- process LEDs
        if s_reset = '1' then
   	        s_blueled  <= '0';
        elsif clk'event and clk = '1' then
        	if s_blueled = '0' then
	   	        s_blueled <= s_uC_down;
	   	    elsif s_target_rst = '1' then
	   	        s_blueled <= '0';
			end if;
        end if;
    end process;

    process (clk, s_reset)
    begin  -- process LEDs
        if s_reset = '1' then
   	        s_hitled   <= '0';
        elsif clk'event and clk = '1' then
        	if s_uC_hcode = '1' then
	   	        s_hitled <= '1';
	   	    elsif s_target_rst = '1' then
	   	        s_hitled <= '0';
			end if;
        end if;
    end process;

    process (clk,s_reset)
    begin -- UART #1, main : BT or USB
        if s_reset = '1' then
            uart_rxd_out <= '1';             
            s_serial_rxd <= '1';             
        elsif rising_edge(clk) then
       		-- UART connects to USB , wired UART shares with Xilinx
            uart_rxd_out <= s_serial_txd;
   	        s_serial_rxd <= uart_txd_in;
        end if;
    end process;
    
    ---------------------------------------------------------------------------
    -- 
    ---------------------------------------------------------------------------
    process (clk,s_reset)
    begin
      if s_reset = '1' then
        s_tp1   <= '0';
        s_tp2   <= '0';
      elsif clk'event and clk = '1' then
    	s_tp1   <= '0';
    	s_tp2   <= '0';
      end if;
    end process;

    process (clk,s_reset)
    begin
      if s_reset = '1' then
        s_uC_pcode_r  <= '0';
		s_uC_ecode_r  <= (others => '0');    -- end of program            
		s_uC_bcode_r  <= (others => '0');    -- start of boot code 16K-256
      elsif clk'event and clk = '1' then
		s_uC_pcode_r  <= s_reg_07(PCODE_OVW_BIT); -- 0=no protect, 1=protect   
		s_uC_ecode_r  <= s_reg_02;    -- end of program            
		s_uC_bcode_r  <= s_reg_03;    -- end of writable RAM area
      end if;
    end process;
    
    process (clk,s_reset)
    begin
      if s_reset = '1' then
        s_Second    <= '0';
        s_Spulse    <= '0';
		s_nScnt     <= (others => '0');
		s_40nScnt   <= (others => '0');
      elsif clk'event and clk = '1' then
   		s_40nScnt <= s_40nScnt + '1';
      	if (s_40nScnt = "011") then
			s_40nScnt  <= (others => '0');
      		s_nScnt    <= s_nScnt + '1';
      		if (s_nScnt > s_reg_06 & s_reg_05) then
      			s_nScnt     <= (others => '0');
      			s_Spulse    <= '1';
	      		s_Second    <= not s_Second;
      		end if;
	      	if (s_Spulse_ack = '1') then
    	  		s_Spulse <= '0';
    	  	end if;
      	end if;
      end if;
    end process;
    
    process (clk,s_reset)
    begin
      if s_reset = '1' then
        s_seg	<= (others => '0');
        s_an	<= (others => '0');
        s_dp	<= '0';
      elsif clk'event and clk = '1' then
        s_seg	<= s_reg_00(6 downto 0);
        s_dp	<= s_reg_00(7);
        s_an	<= s_reg_00(11 downto 8);
      end if;
    end process;

    ---------------------------------------------------------------------------
    -- Control logic: TO Interface data path.
    ---------------------------------------------------------------------------
    -- Input and Output 

    opus1_dinp:process (s_uC_dinp0,s_uC_dinp1,s_reg_cs0,s_reg_cs1)
--    process (clk)
    begin  
--		if clk'event and clk = '1' then
			if(s_reg_cs0 = '1') then
				s_uC_dinp <= s_uC_dinp0; 
			elsif(s_reg_cs1 = '1') then
			    s_uC_dinp <= s_uC_dinp1;
			else
				s_uC_dinp <= s_uC_dinp0; 
			end if;
--        end if;
    end process;
    
    ---------------------------------------------------------------------------
    process (clk,s_reset)
    begin  
        if s_reset = '1' then
			s_reg_08  <= (others => '0');
			s_reg_09  <= (others => '0');
			s_reg_0a  <= (others => '0');
			s_reg_0b  <= (others => '0');
			s_reg_0c  <= (others => '0');
			s_reg_0d  <= (others => '0');
			s_reg_0e  <= (others => '0');
			s_reg_0f  <= (others => '0');
        elsif rising_edge(clk) then
			s_reg_08  <= s_do_out;--
			s_reg_09  <= s_adcmm_data;--
			s_reg_0a  <= s_user_pb;
			s_reg_0b  <= s_user_sw;
			s_reg_0c  <= std_logic_vector(to_unsigned(BOOT_ADDRESS,16));
			s_reg_0d  <= TEST_DATE;
			s_reg_0e  <= TEST_CFG;
			s_reg_0f  <= s_uC_page; -- load with PAGE at reset/power up, ip core date
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Concurrent statements
    ---------------------------------------------------------------------------
    clk			<= clk_in;
    s_reset     <= rst_in;
    
    s_uC_dvld   <= '0';
    
	page        <= s_uC_page;
	pagewr      <= s_uC_pagewr;
	oport       <= s_uC_oport;

	seg			<= not s_seg;	
	an			<= not s_an;		
	dp			<= not s_dp;
				
	-- Registers/IOs ---
    s_uC_wregs  <= s_uC_wr and not s_uC_mio;
    s_uC_rregs  <= s_uC_rd and not s_uC_mio;
    
    s_base_adr0 <= BASE_ADDR_REG0;
    s_reg_cs0   <= '1' when (s_uC_addr(ABUS_WIDTH-1 downto 4) = s_base_adr0(ABUS_WIDTH-1 downto 4) and (s_uC_mio='0'))
                    else '0';

    s_base_adr1 <= BASE_ADDR_REG1;
    s_reg_cs1   <= '1' when (s_uC_addr(ABUS_WIDTH-1 downto 4) = s_base_adr1(ABUS_WIDTH-1 downto 4) and (s_uC_mio='0'))
                    else '0';

	s_target_rst <= s_reg_07(TARGET_RST_BIT);
	s_uC_iport	 <= x"00";

	s_uC_pcode   <= s_uC_pcode_r; -- 0=no protect, 1=protect   
	s_uC_ecode   <= s_uC_ecode_r; -- end of program            
	s_uC_bcode   <= s_uC_bcode_r; -- start of boot code 16K-256

	-- XADC 
	s_daddr_in   <= s_reg_01(6 downto 0);
	s_den_in     <= s_eoc_out;
	s_di_in      <= (others => '0');
	s_dwe_in     <= '0';

    ---------------------------------------------------------------------------
    -- I/O ports
    ---------------------------------------------------------------------------
    -- Local LEDs, main board
	s_user_led(0)	<= s_heartbeat or s_timerbeat;
	s_user_led(1)	<= s_reg_07(PCODE_OVW_BIT);
	s_user_led(2)	<= s_hitled;  -- write to protected ram
	s_user_led(3)	<= s_blueled; -- wrong/bad op-code
	s_user_led(4)	<= s_uC_oport(4) and s_Second; -- IRQ enabled;
	s_user_led(5)	<= s_ot_out; -- over temperature - chip
	s_user_led(6)	<= '0';
	s_user_led(7)	<= '0';
	s_user_led(15 downto 8) <= (others => '0');

	-- I/O board
    -- Registers Out
    reg100_io   <= s_reg_100; --
    reg101_io   <= s_reg_101; -- 
    reg102_io   <= s_reg_102; --
    reg103_io   <= s_reg_103; --
    reg104_io   <= s_reg_104; -- 
    reg105_io   <= s_reg_105; -- 
    reg106_io   <= s_reg_106; -- 
    reg107_io   <= s_reg_107; --

    -- Registers In
    s_reg_108    <= reg108_io; --
    s_reg_109    <= reg109_io; --
    s_reg_10a    <= reg10a_io; --
    s_reg_10b    <= reg10b_io; --
    s_reg_10c    <= reg10c_io; --
    s_reg_10d    <= reg10d_io; --
    s_reg_10e    <= reg10e_io; --
    s_reg_10f    <= reg10f_io; --
    
    ---------------------------------------------------------------------------
    -- Debug and Test Logic
    ---------------------------------------------------------------------------

    
    ---------------------------------------------------------------------------

end architecture rtl;                                    

-------------------------------------------------------------------------------
-- End of File
-------------------------------------------------------------------------------
