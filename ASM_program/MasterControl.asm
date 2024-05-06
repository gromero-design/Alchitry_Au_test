   //////////////////////////////////////////////////////////////////////
   // PROGRAM :		Master Processor
   //////////////////////////////////////////////////////////////////////
   // Filename:  MasterControl.asm
   //     Date:  Jan, 2024
   //   Author:  Gill Romero
   //    Email:  fpgahelp@gmail.com
   //    Phone:  617-905-0508
   //////////////////////////////////////////////////////////////////////
   // Application:
   // Single processor
   //////////////////////////////////////////////////////////////////////
   // check comments with //g or //g# , #=1 to 99
   //////////////////////////////////////////////////////////////////////
   
   //////////////////////////////////////////////////////////////////////
   // Registers, Pointers and flags usage:
   //
   // Pointers
   // p0 : Program counter DON'T TOUCH
   // p1 to p7 : available
   // p8 : contains the address of the UART #2 Data register DON'T TOUCH
   // p9 : contains the address of the UART #2 Status register DON'T TOUCH
   // pA : contains the address of the UART #1 Data register DON'T TOUCH
   // pB : contains the address of the UART #1 Status register DON'T TOUCH
   // pC : used by tx_line, tx_page, tx_prmt routines
   // pD : pointer to debug variables DON'T TOUCH, or save/restore 
   // pE : available
   // pF : Stack pointer
   //
   // Registers
   // r0 : auxilary reg, temp, modified by arith/logic operations
   // r1 : chkstat, rdchar, tohex2,asc2hex input value
   // r2 : hex2asc, input value tohex2,asc2hex, output value dishexs
   // r3 : tx_page, tx_line, dishexs
   // r4 : tx_page, tx_line
   // r5 to rf : available
   
   // uflag(0) available
   // uflag(1) walking LEDs or copy switch to LEDs
   // uflag(2) Display H:M or M:S
   // uflag(3) available
   // uflag(4) available
   // uflag(5) used by memory dump
   // uflag(6) used by asc2hex routine
   // uflag(7) available, used by boot loader 
   // uflag(8) irq, flag
   // uflag(9) irq, flag
   // uflag(A-F) available

   // uport(0) main loop trigger/signal
   // uport(1) available
   // uport(2) available
   // uport(3) available 
   // uport(4) IRQ enable, hw interrupt enable flag
   // uport(5) available
   // uport(6) available
   // uport(7) available
   // uport(8) INT1, indicator
   // uport(9) INT2, indicator
   // uport(A-F) available
   //
   // Register and Pointer definitions
   //=====================================
   //
   // POINTER REGISTERS
   //=====================================
   // P0 pointer 0 -> program counter 'p0' Program counter 'PC' don't touch
   // P1 pointer 1 -> user pointer    'p1' write/read routines, SESMA
   // P2 pointer 2 -> user pointer    'p2' write/read routines       
   // P3 pointer 3 -> user pointer    'p3' write/read routines       
   // P4 pointer 4 -> user pointer    'p4'
   // P5 pointer 5 -> user pointer    'p5'
   // P6 pointer 6 -> user pointer    'p6'
   // P7 pointer 7 -> user pointer    'p7'
   // P8 pointer 8 -> user pointer    'p8'
   // P9 pointer 9 -> user pointer    'p9'
   // PA pointer 10-> user pointer    'pA' UART Data register don't touch
   // PB pointer 11-> user pointer    'pB' UART Status register don't touch
   // PC pointer 12-> user pointer    'pC' used by tx_line, tx_page, tx_prmt routines.
   // PD pointer 13-> user pointer    'pD' pointer to debug variables don't touch
   // PE pointer 14-> user pointer    'pE'
   // PF pointer 15-> stack pointer   'pF' Stack Pointer 'SP' don't touch
   //
   //
   // REGISTERS
   //=====================================
   // R0 register 0 -> temporary ACC  'r0' modified by arith/logic instructions
   // R1 register 1 -> user register  'r1' any routine
   // R2 register 2 -> user register  'r2' asc2hex, hex2asc,tohex2
   // R3 register 3 -> user register  'r3' asc2hex, tx_page, tx_line, dishexs
   // R4 register 4 -> user register  'r4' tx_page, tx_line, application
   // R5 register 5 -> user register  'r5' any routine
   // R6 register 6 -> user register  'r6' any routine
   // R7 register 7 -> user register  'r7' any routine
   // R8 register 8 -> user register  'r8' any routine
   // R9 register 9 -> user register  'r9' any routine
   // RA register 10-> user register  'rA' Boot Loader,  any routine
   // RB register 11-> user register  'rB' any routine
   // RC register 12-> user register  'rC' Boot Loader
   // RD register 13-> user register  'rD' any routine
   // RE register 14-> user register  'rE' any routine
   // RF register 15-> status/control 'rF' any routine
   //
   // R0 can be used in Input and Output I/O access
   // R0 is modified by arithemtic and logic instructions, temp reg
   //=====================================
   //////////////////////////////////////////////////////////////////////
   // Register and memory map for uC16 (Opus1 core + UART + Program Memory
   //////////////////////////////////////////////////////////////////////
   // 'h0000 - 'h00FF uC16 I/O map internal
   //		Internal Register I/O map 'h0000 to 'h000F
   //		UART #1 I/O map 'h0010-'h0011 4 addresses
   //		UART #2 I/O map 'h0014-'h0015 4 addresses
   //		Available for future use 'h0018 to 'h00FF
   //
   //		Registers I/O map
   // 'h0100 - 'hFFFF user I/O map external
   //
   //		buff/BRAM memory map
   // 'h0000 - 'hFFFF user mem map external
   //
   // GPREG_xx  address 'h0000-'h000F General purpose registers
   // UART #1   address 'h0010-'h0013
   // UART #2   address 'h0014-'h0017
   // Available address 'h0018 to 'h00FF
   // APPREG_xx address 'h0100-'hFFFF Application registers
   // REGxx_IO  address 'hxxxx + BAR (Base Address Register)
   //

   //////////////////////////////////////////////////////////////////////
   //////////////////////////////////////////////////////////////////////
   // Main Address Defines
   //////////////////////////////////////////////////////////////////////
   //////////////////////////////////////////////////////////////////////
   // The boot loader must always be in the last program memory positions.
   // 4K  -> 'h0F00
   // 8K  -> 'h1F00
   // 16K -> 'h3F00 <---- 16384
   // 32K -> 'h7F00
   // 64K -> 'hFF00

define	RESET_ADDR		'h0000 // Reset vector address
define	MAIN_ADDR		'h0010 // Main entry address
define	BOOT_ADDR		'h3F00 // Boot loader address
define	STACK_LENGTH		64 //

   //////////////////////////////////////////////////////////////////////
   // REAL TIME CLOCK
   //////////////////////////////////////////////////////////////////////
   // Defines are in hexadecimal, the clock routine will do the rest
define YEAR      'h2024 //  Year 2024
define MONTH     'h0004 //  Month (Jan=1 to Dec=12)
define DATE      'h0123 //  day/Date (Mon=0 to Sun=6)/(Date=1 to 28/29/30/31)
define HOUR          00 //  hours - 24 hours format
define MINUTE        00 //  minutes
define SECONDS       00 //  seconds

   //////////////////////////////////////////////////////////////////////
   // 1 second values in hex to program the 20nS counter on HW
   //////////////////////////////////////////////////////////////////////
   // 1Sec/20nSec= 100,000,000 = 'h017d7840
define HIGHSEC	'h017d // GPREG_06
define LOWSEC 	'h7840 // GPREG_05
   
   //////////////////////////////////////////////////////////////////////
   // System defines
   //////////////////////////////////////////////////////////////////////
   
   //////////////////////////////////////////////////////////////////////
   // Defines for external DRAM,SRAM
   //////////////////////////////////////////////////////////////////////
   // To be used with LDMAM instruction (Load Memory Access Mode)	
   // ldmam mo ; // internal read , internal write. IRIW 
   // ldmam m1 ; // external read , internal write. XRIW
   // ldmam m2 ; // internal read , external write. IRXW
   // ldmam m3 ; // external read , external write. XRXW

   //////////////////////////////////////////////////////////////////////
   // Key defines, add as many as you need
   //////////////////////////////////////////////////////////////////////
define   CTLX 	'h03 // ^C
define   ETX  	'h03 // ^C
define   CTLD 	'h04 // ^D
define   CTLE 	'h05 // ^E
define   CTLI 	'h09 // ^I
define   CR   	'h0D // ^M
define   LF   	'h0A // ^J
define   FF   	'h0C // ^L
define   CTLL 	'h0C // ^L
define   CTLP 	'h10 // ^P
define   CTLR 	'h12 // ^R
define   CTLZ 	'h1A // ^Z
define   ESC  	'h1B // ^[
define   NULL 	'h00 // ^@
define   CTLS 	'h13 // ^S
define   CTL_ 	'h1F // ^S
define   SPC  	'h20 // Space
define   POUND  'h23 // #
define   FSLASH 'h2F // /
define   BSLASH 'h5c // \
define   UNDER	'h5F // Underline

define   NUMFILL 	5    // number of filling charaters in message
define   CHARFILL	'h2d // character to fill in this case is "-"

   //////////////////////////////////////////////////////////////////////
   // UART Data Reg
   //////////////////////////////////////////////////////////////////////
define   UARTDAT   'h0010 // UART Output Register
define   UARTSTA   'h0011 // UART Status Register
define   UARTDAT2  'h0014 // UART Output Register
define   UARTSTA2  'h0015 // UART Status Register

   // status lines
define   RXDVLD   'h0080 // valid or present input data
define   TXFULL   'h0040 // TX fifo full 
define   TXEMPT   'h0020 // TX fifo EMPTY 
define   TP2      'h0010 // test point 2
define   RXERR    'h0008 // RX error
define   RXFULL   'h0004 // RX fifo full
define   RXEMPT   'h0002 // RX fifo empty
define   TP1      'h0001 // test point 1
define   TP1_2    'h0011 // test point 1 and 2

   //////////////////////////////////////////////////////////////////////
   //////////////////////////////////////////////////////////////////////
   // User defines
   //////////////////////////////////////////////////////////////////////
   //////////////////////////////////////////////////////////////////////
define	SIGNED      'h8000 // Signed bit
define	ADC_DELAY	    50 // wait for XADC to finish

// Defines for the index of debug pointer P7
// strx rn,pD,SR_IX ; // example
define SR_IX	0 // external RAM page address
define IR_IX_LN	1 // internal RAM length
define IR_IX	2 // internal RAM address
define ER_IX	3 // external RAM address
define IRL_IX	4 // internal RAM address last
define ERL_IX	5 // external RAM address last
//				6
//				7

   /////////////////////////////////////////////////////////////////////
   // for testing only
define   BASEREGIO  'h0100 // Base register address port
define   IBASEREGIO 'h0100 // interconnect Base register address port

   // Application Registers 
   // 'h0000 - 'h000f register map
   // Registers - OUTPUTs
define   GPREG_00  'h0000 // holds the an,7seg,dp
define   GPREG_01  'h0001 // XADC channel,XADC address
define   GPREG_02  'h0002 // ECODE : end of program (protected) 
define   GPREG_03  'h0003 // BCODE : end of data/RAM
define   GPREG_04  'h0004 // use as bit test for now
define   GPREG_05  'h0005 // low  word for 1Sec counter
define   GPREG_06  'h0006 // high word for 1Sec counter
define   GPREG_07  'h0007 // triger src, scope src, PCODE, RESET

   // Registers - INPUTs
define   GPREG_08  'h0008 // XADC 
define   GPREG_09  'h0009 // XADC
define   GPREG_0A  'h000a // push buttons 
define   GPREG_0B  'h000b // switches
define   GPREG_0C  'h000c // Boot address
define   GPREG_0D  'h000d // TEST_CFG  : YEAR   
define   GPREG_0E  'h000e // TEST_DATE : Month-Date
define   GPREG_0F  'h000f // CORE_VERSION : opus1-16 ip core date

   // GPREG_07 = System Register - OUTPUT
define   TARGET_MSK 'h0001 // Target reset mask
define   TARGET_NSK 'hFFFE //
define   PCODE_MSK  'h0002 // Pcode mask
define   PCODE_NSK  'hFFFD //
define   SCOPE_MSK  'h3000 // Scope source
define   SCOPE_NSK  'hCFFF //
define   TRIGS_MSK  'hC000 // Trigger source
define   TRIGS_NSK  'h3FFF //
   //  0  'h0001 target reset pulse and clear registers
   //  1  'h0002 pcode 0=unprotected code, 1=protected code
   // 12  'hF000 bit 12,Scope   source, bit 0
   // 13         bit 13,Scope   source, bit 1
   // 14         bit 14,Trigger source, bit 0
   // 15         bit 15,Trigger source, bit 1

   // GPREG_0A = Push buttons - INPUT
define   BTND      'h0001 // button down
define   BTNL      'h0002 // button left
define   BTNC      'h0004 // button center
define   BTNR      'h0008 // button right
define   BTNU      'h0010 // button up

   // INTERCONNECT REGISTERS - IBASEREGIO
   // Multiprocessor interconnect
   // Slave interconnect registers map
   // Registers - OUTPUTs Slave #1
define   S1REG_0  'h0100 // i/o LEDs 23:16
define   S1REG_1  'h0101 // i/o LEDs 15:0
define   S1REG_2  'h0102 //
define   S1REG_3  'h0103 //
define   S1REG_4  'h0104 //
define   S1REG_5  'h0105 //
define   S1REG_6  'h0106 //
define   S1REG_7  'h0107 //

   // Registers - INPUTs Slave #1
define   S1REG_8  'h0108 // dip switch 23:16
define   S1REG_9  'h0109 // dip switch 15:0
define   S1REG_a  'h010a // 
define   S1REG_b  'h010b //
define   S1REG_c  'h010c //
define   S1REG_d  'h010d //
define   S1REG_e  'h010e //
define   S1REG_f  'h010f //

   // Registers - OUTPUTs Slave #2
define   S2REG_0  'h0110 //
define   S2REG_1  'h0111 //
define   S2REG_2  'h0112 //
define   S2REG_3  'h0113 //
define   S2REG_4  'h0114 //
define   S2REG_5  'h0115 //
define   S2REG_6  'h0116 //
define   S2REG_7  'h0117 //

   // Registers - INPUTs
define   S2REG_8  'h0118 // Slave #2
define   S2REG_9  'h0119 //
define   S2REG_a  'h011a // 
define   S2REG_b  'h011b //
define   S2REG_c  'h011c //
define   S2REG_d  'h011d //
define   S2REG_e  'h011e //
define   S2REG_f  'h011f //

   // Registers - OUTPUTs Slave #3
define   S3REG_0  'h0120 //
define   S3REG_1  'h0121 //
define   S3REG_2  'h0122 //
define   S3REG_3  'h0123 //
define   S3REG_4  'h0124 //
define   S3REG_5  'h0125 //
define   S3REG_6  'h0126 //
define   S3REG_7  'h0127 //

   // Registers - INPUTs
define   S3REG_8  'h0128 // Slave #3
define   S3REG_9  'h0129 //
define   S3REG_a  'h012a // 
define   S3REG_b  'h012b //
define   S3REG_c  'h012c //
define   S3REG_d  'h012d //
define   S3REG_e  'h012e //
define   S3REG_f  'h012f //

   // Registers - OUTPUTs Slave #4
define   S4REG_0  'h0130 //
define   S4REG_1  'h0131 //
define   S4REG_2  'h0132 //
define   S4REG_3  'h0133 //
define   S4REG_4  'h0134 //
define   S4REG_5  'h0135 //
define   S4REG_6  'h0136 //
define   S4REG_7  'h0137 //

   // Registers - INPUTs
define   S4REG_8  'h0138 // Slave #4
define   S4REG_9  'h0139 //
define   S4REG_a  'h013a // 
define   S4REG_b  'h013b //
define   S4REG_c  'h013c //
define   S4REG_d  'h013d //
define   S4REG_e  'h013e //
define   S4REG_f  'h013f //


   //////////////////////////////////////////////////////////////////////
   //
   // Code Area Protected
   //
   // All labels lower case
   //////////////////////////////////////////////////////////////////////

@RESET_ADDR // Reset vector
reset_v:	jmp   setup      ; // @'h000 reset vector
irq1_v:		jmp   hw_irq1    ; // @'h002 hardware irq vector
irq2_v:		jmp   hw_irq2    ; // @'h004 hardware irq vector
irq3_v:		jmp   hw_irq3    ; // @'h006 hardware irq vector
irq4_v:		jmp   hw_irq4    ; // @'h008 hardware irq vector

// Free from h000A to MAIN_ADDR
   
   //////////////////////////////////////////////////////////////////////
   //////////////////////////////////////////////////////////////////////
   // Program Section, Protected area
   //////////////////////////////////////////////////////////////////////
   //////////////////////////////////////////////////////////////////////
@MAIN_ADDR
setup:		cli					   ;
			ldpv  pA,UARTDAT       ; // initialize UART
	        ldpv  pB,UARTSTA       ;
         	ldpv  pF,stack         ; // initialize stack pointer
         	ldpv  pD,dbugptr       ; // initialize debug pointer
         	ldrv  r1,kpst00        ; // Initialize SESMA variables
         	str   r1,ssm_pst       ; // present state
         	str   r1,ssm_lst       ; // last state.

			// Insert User Initialization
			// Initialize local registers

			ldrv	r1,0			; // also xor r1,r1 works too!!
			outp	r1,GPREG_00		; // holds the an,7seg,dp  	        
			outp	r1,GPREG_01		; // XADC channel,XADC address
			outp	r1,GPREG_04		; // Test reg 	        
			ldrv	r1,zend_code   	; // end of program protected RAM
	        outp    r1,GPREG_02     ; //
			ldrv	r1,zend_ram  	; // start of unprotected RAM
	        outp    r1,GPREG_03     ; //
			ldrv	r1,'h0002 		; // trigger=00,source =00,for debugging
	        outp    r1,GPREG_07     ; // protected mode = 2
			ldrv	r1,LOWSEC 		; // low word for 1Sec counter
	        outp    r1,GPREG_05     ; // 15:0
			ldrv	r1,HIGHSEC 		; // high word for 1Sec counter
	        outp    r1,GPREG_06     ; // 31:16 1Sec based on 40nS clock

			// Initialize external RAM page 7
			// not implemented in HW
//			ldpagv	7				;
//			ldpv	p1,0			;
//			ldcv	c1,127			; // 128 words
//			xor		r1,r1			;
//			ldmam	m3				; // extrernal RAM R/W
//mainloop:	strpi	r1,p1			;
//			dcjnz	c1,mainloop		;
//			ldmam	m0				; // internal RAM R/W
			
			// Initialize flags and output ports	
		    uflag 	f2				; // H:M or M:S
	        uflag 	f5				; // memory pointer
	        uflag 	f6				; // asc2hex
	        uflag 	tA				; // application run
	        uflag 	fB				; // 1 mSec flag, clear by routine
	        uflag 	fC				; // millisecond delay flag
	        uflag 	fD				; // second delay flag

	        // do not touch
			uport	f4				; // hw interrupt enable flag 
			uport	f8				; // hw IRQ1 test
			uport	f9				; // hw IRQ2 test 
									 
	        jsr		init_xterm		; // initialize display rows/cols
	        jsr		d_targetrst		; // reset top fpga
         	ldpv	pC,chome_m      ; // cursor to home
         	jsr 	tx_line         ; // message out.
	        jsr		myapp			; // call application once to reffresh
			jsr		irq_enb			; // enable Interrupts
	        
    //////////////////////////////////////////////////////////////////////
	// Main Loop
    //////////////////////////////////////////////////////////////////////

main:		inpp  	r1,pB	     	; // read status reg
			bitv  	r1,RXDVLD   	; // test data valid RX
         	bra   	z,main2		  	; //
			jsr   	rdchar          ; // read command and call SESMA
			jsr   	sesma           ; // uses pointer 1 (p1), action routine has RTS
			////////////////////////////
			// action routine returns here
			////////////////////////////
main2:		inp		r1,GPREG_0A		;
			andv	r1,'h001F		; // mask push buttons
			bra		nz,main5		; // pb != 0
			jmp		fA,main3		; // one time run application
			uflag	fA				; // clear
			bra		main4			; // run app
main3:		jmp		fD,main			; // 1Sec run application
			uflag	fD				; // clear
main4:		jsr		myapp			; // call application
			jmp		main			;
			////////////////////////////
			// Execute app on PButtons
			////////////////////////////
			// This could be replaced with a jmp table
main5:		bitv	r1,BTNL			; // btnL
			bra		z,main6			;
			ldrv	r2,1			; // execute Temp F
			bra		main8			;
main6:		bitv	r1,BTNR			; // btnR
			bra		z,main7			;
			ldrv	r2,0			; // execute Temp C
			bra		main8			;
main7:		bitv	r1,BTNU			; // btnU
			bra		z,main7_1		;
			uflag	f2				; // H:M
			ldrv	r2,5			; // execute RTC
			bra		main8			;
main7_1:	bitv	r1,BTND			; // btnD
			bra		z,main			;
			uflag	t2				; // M:S
			ldrv	r2,5			; // execute RTC
main8:		str		r2,myapp_val	;
			jmp		main4			; // execute myapp
			
									
	//////////////////////////////////////////////////////////////
	// I/O access LEDs, switches and push buttons
	//////////////////////////////////////////////////////////////
d_xadc: 	ldpv	pC,decval4_m   	; // 
	 		jsr		tx_line	       	;
	 		jsr		asc2dec	       	;
	 		andv	r2,'h0007		; //g limit to 3 bits, adc=4..0 (for now)
	 		str		r2,myapp_val	;
	 		jsr		tx_prmtx2      	;
	 		uflag	tA				; // activate myapp 
	 		rts						;

d_walking: 	ldpv	pC,hexval2_m   	; // 
	 		jsr		tx_line	       	;
	 		jsr		asc2hex	       	;
	 		andv	r2,'hFF			;
	 		str		r2,pattern1		;
	 		xor		r3,r3			;
	 		str		r3,pattern2		;
	 		ldrv	r2,6			; //g limit to 3 bits, adc=4..0 (for now)
	 		str		r2,myapp_val	;
	 		jsr		tx_prmtx2      	;
	 		rts						;

d_switch: 	inp		r1,S1REG_8		; // save it
	 		outp	r1,S1REG_0		;
			inp		r1,S1REG_9		; // save it
	 		outp	r1,S1REG_1		;
	 		ldrv	r2,7			; // do nothing
	 		str		r2,myapp_val	;
	 		jsr		tx_prmtx2      	;
	 		rts						;
	 		
d_setled: 	ldpv	pC,hexval8_m   	; // 
	 		jsr		tx_line	       	;
	 		jsr		asc2hex	       	;
	 		outp	r3,S1REG_0		;
	 		outp	r2,S1REG_1		;
	 		ldrv	r2,7			; // do nothing
	 		str		r2,myapp_val	;
	 		jsr		tx_prmtx2      	;
	 		rts						;

	 		
	//////////////////////////////////////////////////////////////
	// Display Menus : start
	//////////////////////////////////////////////////////////////
   
         	// Version number always on        	
d_prgver:	ldpv  	pC,fg_blu_m     ; // display menu
         	jsr	  	tx_line      	; // clear screen
			ldpv	pC,version_m	;
			jsr		tx_line 		;
         	jsr 	tx_prmtx2       ; 
		 	ldpv	pC,hwversion_m  ; // display message
         	jsr 	tx_line         ; // message out.
         	inp		r2,GPREG_0D		;
         	jsr		dishex4			;
         	inp		r2,GPREG_0E		;
         	jsr		dishex4			;
         	jsr 	tx_prmtx2       ; 
		 	ldpv	pC,codelength_m ; // display message
         	jsr 	tx_line         ; // message out.
         	inp		r2,GPREG_02		;
         	jsr		dishex4			;
         	jsr 	tx_prmtx2       ; 
		 	ldpv	pC,datalength_m ; // display message
         	jsr 	tx_line         ; // message out.
         	inp		r2,GPREG_03		;
         	jsr		dishex4			;
         	jsr 	tx_prmtx2       ; 
		 	ldpv	pC,bootlength_m ; // display message
         	jsr 	tx_line         ; // message out.
         	inp		r2,GPREG_0C		;
         	jsr		dishex4			;
         	jsr 	tx_prmtx2       ; 
		 	ldpv	pC,ipversion_m  ; // display message
         	jsr 	tx_line         ; // message out.
         	inp		r2,GPREG_0F		;
         	jsr		dishex4			;
         	jsr 	tx_prmtx2       ; 
			rts						;  
         	
			// display real time clock always on
d_rtcmode:	uflag	t2				;
			bra		d_rtcval1		;
d_rtcval:	uflag	f2				;
d_rtcval1:	ldpv	p1,tmr1year		;
		 	ldcv	c1,5			; // columns
rtcdump: 	ldrpi	r2,p1			;
         	jsr		dishex4    		; // display signed
		 	dcjnz	c1,rtcdump		;
			ldpv  	pC,promptlf     ; // 
         	jsr   	tx_line         ; // output LF
d_rtcval2:	ldrv	r5,5			; // display clock
			str		r5,myapp_val	;
	 		uflag	tA				; // activate myapp 
			rts                		;

			   
clscreen:	ldpv  	pC,fg_wht_m     ; // display menu
         	jsr	  	tx_line      	; // clear screen
		 	ldpv	pC,cls_m      	; // display message
         	jsr 	tx_line         ; // clear screen
         	jsr 	tx_prmtx2       ; 
         	ldpv	pC,chome_m      ; // display message
         	jsr 	tx_line         ; // message out.
         	jsr 	tx_prmtx2       ; 
			rts						;

			// back to Main Menu, clear variables
d_menu:  	jsr	  	clscreen      	; // clear screen
		 	ldpv  	pC,menu         ; // display menu 
         	jmp   	d_txpage        ;
                  	
d_appset:	jsr	  	clscreen      	; // clear screen
		 	ldpv  	pC,appset_m     ; // display menu 
         	jmp   	d_txpage        ;
         	      	
d_sysset:	jsr	  	clscreen      	; // clear screen
		 	ldpv  	pC,sysset_m     ; // display menu 
         	jmp   	d_txpage        ;

d_debugq:  	jsr	  	clscreen      	; // clear screen
		 	ldpv  	pC,debugq_m     ; // display menu 
         	jmp   	d_txpage        ;
         	      	
d_debug:  	jsr	  	clscreen      	; // clear screen
		 	ldpv  	pC,debug_m      ; // display menu 
         	jmp   	d_txpage        ;
         	      	
d_help: 	jsr	  	clscreen      	; // clear screen
		 	ldpv  	pC,fg_yel_m     ; // display menu
         	jsr	  	tx_line      	; // clear screen
		 	ldpv  	pC,help_m       ; // display menu
         	jmp   	d_txpage        ;
         	         	   	
d_help_io: 	jsr	  	clscreen      	; // clear screen
		 	ldpv  	pC,fg_grn_m     ; // display menu
         	jsr	  	tx_line      	; // clear screen
		 	ldpv  	pC,help_io       ; // display menu
         	jmp   	d_txpage        ;
         	         	   	
d_helpa:  	jsr	  	clscreen      	; // clear screen
		 	ldpv  	pC,fg_grn_m     ; // display menu
         	jsr	  	tx_line      	; // clear screen
		 	ldpv  	pC,helpa_m      ; // display menu 
         	jmp   	d_txpage        ;

d_helps:  	jsr	  	clscreen      	; // clear screen
		 	ldpv  	pC,fg_grn_m     ; // display menu
         	jsr	  	tx_line      	; // clear screen
		 	ldpv  	pC,helps_m       ; // display menu 
         	jmp   	d_txpage        ;
         	      	
d_helpd:  	jsr	  	clscreen      	; // clear screen
		 	ldpv  	pC,fg_grn_m     ; // display menu
         	jsr	  	tx_line      	; // clear screen
		 	ldpv  	pC,helpd_m       ; // display menu 
         	jmp   	d_txpage        ;
         	      	
d_txpage:	jsr   tx_page          	;
         	jsr   tx_prmtcr        	; 
d_nothing: 	rts                    	;

	// Display Menus : ends
	//////////////////////////////////////////////////////////////

   			// Display Interconnect Registers
   			// p1=base register address, r3=row, r4=col
   			// use: r2,r8,r9,p1,c1,c2
d_regdump: 	ldpv  	pC,fg_yel_m     ; // display menu
         	jsr	  	tx_line      	; // clear screen
		 	ldp		p1,iregptr	;
			ldr		r8,r_rows	; // 4 rows
			ldr		r9,r_cols	; // 16 columns
			jsr		regdump		;
			jsr		tx_prmt    	;
			rts					;

regdump: 	ldc		c2,r8		; // rows
regdum1: 	mvpr	p1,r2		; // show current address
			jsr		dishex4		; // r2 contains the message pointer
			ldpv  	pC,colon_m	; // 
         	jsr   	tx_line         ; // output CR-LF
         	ldc		c1,r9		; // columns
regdum2: 	inpp	r2,p1		;
         	jsr		dishex4    	; // display signed
			incp	p1				;
		 	dcjnz	c1,regdum2	;
         	jsr		tx_prmt    	; 
         	dcjnz	c2,regdum1 	;
			rts					;

   			// Read REGS
d_aregs: 	ldpv  	pC,fg_yel_m     ; // display menu
         	jsr	  	tx_line      	; // clear screen
		 	ldr		r1,regptr	;
	 		mvrr	r1,r8		; // save address
         	mvrp	r1,p6		;
         	ldcv	c1,15       ; 
d_areg1: 	mvrr	r8,r2		;
			jsr		dishex4		; // r2 contains the message pointer
			ldpv  	pC,colon_m	; // 
         	jsr   	tx_line     ; // output CR-LF
			inpp	r2,p6       ;
         	jsr		dishex4     ;
         	jsr		tx_prmt     ; 
         	incp	p6          ;
         	inc		r8			;
         	dcjnz	c1,d_areg1  ;
         	jsr		tx_prmt     ; 
			rts                 ;

   			// Display 8x8 REGS
d_io_aregs:	ldpv  	pC,fg_yel_m     ; // display menu
         	jsr	  	tx_line      	; // clear screen
		 	ldpv  	pC,output_m		; // 
         	jsr   	tx_line         ; // output CR-LF
         	jsr		tx_prmt         ; 
			ldr		r1,regptr		;
	 		mvrr	r1,r8			; // save address
         	mvrp	r1,p6			;
         	ldcv	c1,7            ; 
d_io_areg1:	mvrr	r8,r2			;
			jsr		dishex4			; // r2 contains the message pointer
			ldpv  	pC,colon_m		; // 
         	jsr   	tx_line         ; // output CR-LF
			inpp	r2,p6           ;
         	jsr		dishex4         ;
         	jsr		tx_prmt         ; 
         	incp	p6              ;
         	inc		r8				;
         	dcjnz	c1,d_io_areg1   ;
         	ldpv  	pC,input_m		; // 
         	jsr   	tx_line         ; // output CR-LF
         	jsr		tx_prmt         ; 
			ldcv	c1,7            ; 
d_io_areg2:	mvrr	r8,r2			;
			jsr		dishex4			; // r2 contains the message pointer
			ldpv  	pC,colon_m		; // 
         	jsr   	tx_line         ; // output CR-LF
			inpp	r2,p6           ;
         	jsr		dishex4         ;
         	jsr		tx_prmt         ; 
         	incp	p6              ;
         	inc		r8				;
         	dcjnz	c1,d_io_areg2   ;
         	jsr		tx_prmt         ; 
			rts                     ;

         	// Memory Access = Internal/External (0/1)
d_mema:	 	ldr   r1,memacc	    	;
         	xorv  r1,1   			;
         	bra   nz,d_memon      	;
	 		xor   r2,r2	       		;
	 		str   r2,memop			;
         	ldpv  pC,memof_m      	; // display menu
         	bra   d_memof         	;
d_memon: 	ldrv  r2,3 	       		;
	 		str   r2,memop			;
	 		ldpv  pC,memon_m      	; 
d_memof: 	str   r1,memacc      	;
         	jsr   tx_line         	;
	 		jsr   tx_prmt         	; 
	 		rts		       			;
         	// Memory Access = Word/Byte (0/1)
d_memb:	 	ldr   	r1,memode  		;
         	xorv	r1,1		   	;
         	bra		nz,d_membyte    ;
         	ldpv	pC,memword_m    ; // display menu
         	bra		d_memword       ;
d_membyte: 	ldpv	pC,membyte_m    ; 
d_memword:	str		r1,memode      	;
         	jsr		tx_line         ;
	 		jsr		tx_prmt         ; 
	 		rts	                    ;
	 		
d_base:	 	ldpv  pC,hexval4_m    	; // Register Base Address
	 		jsr   tx_line	       	;
	 		jsr   asc2hex	       	;
	 		str   r2,regptr  		;
	 		jsr   tx_prmtx2        	;
	 		rts						;

   /////////////////////////////////////////////////////////////////////
   // System Subroutines
   /////////////////////////////////////////////////////////////////////
         	// Debug mode
         	// bit operation in bitop
s_bitop: 	ldr   r1,inpchar       	; // write command
			outpp r1,pA            	; //g1
s_bitop1:	str   r1,bitop			;
clrval:	 	ldrv  r1,'h3030        	; // "00" in ASCII
         	str   r1,cvalue1       	; 
         	str   r1,cvalue2       	;
         	rts                    	;
			// get address in cvalue1/2
a_getadr:	ldr   r1,inpchar       	;
			outpp r1,pA            	; //g1
a_geta1:   	ldr   r2,cvalue1       	;
         	ldr   r3,cvalue2       	;
         	ldcv  c1,7		     	;
a_geta2: 	shl   l,r2             	;
         	shl   k,r3             	;
         	dcjnz c1,a_geta2       	;
         	str   r3,cvalue2       	; 
         	or    r2,r1            	;
         	str   r2,cvalue1       	;
         	rts                    	; 
			// get value
a_getval:	jsr   a_setadd		;
         	jsr   tx_prmt       ; 
		 	ldp   p1,inpaddr	;
		 	ldr   r1,bitop		;
		 	cmprv r1,"m"		;// here check for M or IO
		 	bra   z,a_getmem	;
	 		inpp  r2,p1 		;// register
	 		bra   a_getend		;
a_getmem:	stp   p1,memptr		;
			stp   p1,memptrlast	;
			ldr	  r4,memop		;
			andv  r4,3			;
			bra	  nz,a_getex	;	
	 		ldrp  r2,p1			;
	 		bra	  a_getend		;
a_getex:	ldmam m1			; // external read , internal write.  XRD
	 		ldrp  r2,p1			;
a_getend:	ldmam m0			; // internal read , internal write.  IRW  	
			jsr   dishex4       ;
	 		jsr   tx_prmt       ; 
         	rts					;
         
a_setadd:	ldr   r1,cvalue1    ;
         	jsr   tohex2        ;
			mvrr  r2,r3			;
			ldr   r1,cvalue2    ;
        	jsr   tohex2        ;
        	shl4  r2	 		;
			shl4  r2			;
			or    r2,r3			;
			str   r2,inpaddr	;
        	ldrv  r1,'h3030     ;
        	str   r1,cvalue1    ; 
        	str   r1,cvalue2    ;
        	ldr   r1,inpchar    ; // delimiter
	 		str   r1,delimeter	;
			outpp r1,pA         ;
a_setadd2: 	rts                 ; 

a_regdat:	jsr   a_getadr      ; 
         	rts                 ; 

a_wrval1:	jsr   a_wrval		;
	 		jsr   a_wrout		;
e_wrval1:	rts					;
	
a_wrval2:	jsr   a_wrval       ;
        	ldr   r2,outdata	;
			not   r2			;
			ldr   r3,delimeter	;
			cmprv r3,"-"		;
			bra   ne,a_ones		;
			addv  r2,1			;
a_ones:		str   r2,outdata    ;
	 		jsr   a_wrout		;
e_wrval2:	rts					;
	
a_wrval:	ldr   r1,cvalue1    ;
        	jsr   tohex2        ;
        	mvrr  r2,r3         ; //save it and
        	ldr   r1,cvalue2    ;
        	jsr   tohex2        ;
	 		shl4  r2			;
	 		shl4  r2			;
        	or    r2,r3         ; // combine
        	str   r2,outdata    ;
	 		rts					;
	
         // write data into address
a_wrout:	ldr   r1,outdata       	;
        	ldr   r2,inpaddr       	;
        	ldr   r3,bitop			;
        	ldr   r4,memop			;
			cmprv r3,"w" 			; // write register
			bra   ne,a_w1			;
			mvrp  r2,p1				;
        	outpp r1,p1            	;
	 		bra   a_wend			;
a_w1:		cmprv r3,"s"			; // set bit
	 		bra   ne,a_w2			;
			mvrp  r2,p1				;
			ldpv  p3,h2btab			;
			ldr   r1,outdata		;// bit #
			addrp r1,p3				;
			mvrp  r1,p3				;
			ldrp  r1,p3				; // bit set
			inpp  r2,p1				; //g1
			or    r2,r1				;
			outpp r2,p1  			;
			bra   a_wend			;
a_w2:		cmprv r3,"c"			; // clear bit
	 		bra   ne,a_w3			;
	 		mvrp  r2,p1				;
	 		ldpv  p3,h2btab			;
	 		ldr   r1,outdata		;// bit #
	 		addrp r1,p3				;
	 		mvrp  r1,p3				;
	 		ldrp  r1,p3				; // bit set
	 		not   r1,r1				; // bit clear
	 		inpp  r2,p1				; //g1
	 		and   r2,r1				;
	 		outpp r2,p1  			;
	 		bra   a_wend			;
a_w3:		cmprv r3,"t"			; // toggle bit
	 		bra   ne,a_w4			;
	 		mvrp  r2,p1				;
	 		ldpv  p3,h2btab			;
	 		ldr   r1,outdata		;// bit #
	 		addrp r1,p3				;
	 		mvrp  r1,p3				;
	 		ldrp  r1,p3				; // bit set
	 		inpp  r2,p1				; //g1
	 		xor   r2,r1				;
	 		outpp r2,p1  			;
	 		bra   a_wend			;
a_w4:		cmprv r3,"i"			; // pulse bit
	 		bra   ne,a_w5			;
	 		mvrp  r2,p1				;
	 		ldpv  p3,h2btab			;
	 		ldr   r1,outdata		;// bit #
	 		addrp r1,p3				;
	 		mvrp  r1,p3				;
	 		ldrp  r1,p3				; // bit set
	 		inpp  r2,p1				; //g1
	 		xor   r2,r1				;
	 		outpp r2,p1  			; //g1
	 		xor   r2,r1				;
	 		outpp r2,p1  			;
	 		bra   a_wend			;
a_w5:		cmprv r3,"a"			; // AND with MEMORY or PORT 16bits
	 		bra   ne,a_w6			;
	 		mvrp  r2,p1				;
	 		inpp  r3,p1				; //g1
	 		and   r1,r3				;
	 		outpp r1,p1  			;
	 		bra   a_wend			;
a_w6:		cmprv r3,"o"			; // AND with MEMORY or PORT 16bits
	 		bra   ne,a_w7			;
	 		mvrp  r2,p1				;   	
	 		inpp  r3,p1				; //g1
	 		or    r1,r3				;   	
	 		outpp r1,p1  			;
	 		bra   a_wend			;
a_w7:		cmprv r3,"e"			; // XOR with MEMORY or PORT 16bits
	 		bra   ne,a_w8			;
	 		mvrp  r2,p1				;   	
	 		inpp  r3,p1				; //g1
	 		xor   r1,r3				;   	
	 		outpp r1,p1  			;
	 		bra   a_wend			;
a_w8:		cmprv r3,"m"			; // memory access
			bra   ne,a_wend			;
			ldp   p1,inpaddr		;
			ldr   r3,memop			;
			andv  r3,3				;
			bra   z,a_w9			;
			ldmam m2				; // internal read , external write.  XWR
a_w9:		strp  r1,p1				;
a_wend:		ldmam m0				; // internal read , internal write.  IRW 
			jsr   tx_prmt   		;
			jsr   tx_prmt   		;
			rts             		;
                            
a_quit:		nop                		;
			jsr   tx_prmt      		;
			rts                		;

			// use user flag 5
memnext:	uflag 	t5				; // use memory pointer here
			ldp   	p1,memptr		;
			stp	  	p1,memptrlast	;
			jmp   	memdump0		;
memdump:	ldp   	p1,memptrlast	;
memdump0:	mvpr  	p1,r8			; // save current address
			ldmam 	m0           	; // access internal memory for write/read
			ldr		r2,m_rows		;
			ldc		c2,r2			; // rows
        	ldr		r1,memode		;
			or		r1,r1			;// check for byte/word access
			bra		nz,memdumb1		;// nz byte, z word
        	// memory dump word
memdumw1: 	mvrr	r8,r2			;
			jsr		dishex4			; // r2 contains the message pointer
			ldpv  	pC,colon_m		; // 
         	jsr   	tx_line         ; // output CR-LF
			ldr		r2,m_cols		; // columns
			ldc		c1,r2			; // columns
memdumw2: 	ldr   	r1,memop		;
			andv  	r1,3			;
			bra   	z,rdmemw		;
			ldmam 	m1				; // external read , internal write.  XRD
rdmemw:		ldrpi 	r2,p1			;
        	ldmam 	m0            	; // internal read , internal write.  IRW
        	jsr   	dishex4      	; // display signed
			dcjnz 	c1,memdumw2		;
        	jsr   	tx_prmt      	;
        	addv	r8,8			; 
        	dcjnz 	c2,memdumw1  	;
        	jmp	  	f5,memdum4		;
        	stp   	p1,memptr    	;
        	uflag 	f5				;
        	jmp		memdum4			;
			// end
        	// memory dump byte
memdumb1: 	mvrr	r8,r2			;
			jsr		dishex4			; // r2 contains the message pointer
			ldpv  	pC,colon_m		; // 
         	jsr   	tx_line         ; // output CR-LF
			ldcv	c1,7			; // columns
memdumb2: 	ldr   	r1,memop		;
			andv  	r1,3			;
			bra   	z,rdmemb		;
			ldmam 	m1				; // external read , internal write.  XRD
rdmemb:		xor		r3,r3			;
			ldrpi	r2,p1			; // read buffer
			or		r3,r2			;
			ldrpi	r2,p1			;
			shl4	r2				;
			shl4	r2				;
			or		r3,r2			;
			swap	r3,r2			;
        	ldmam 	m0            	; // internal read , internal write.  IRW
        	jsr   	dishex4      	; // display signed
			dcjnz 	c1,memdumb2		;
        	jsr   	tx_prmt      	; 
        	addv	r8,16			; 
        	dcjnz 	c2,memdumb1  	;
        	jmp	  	f5,memdum4		;
        	stp   	p1,memptr    	;
        	uflag 	f5				;
        	jmp		memdum4			;
			// end
memdum4:   	jsr   	tx_prmt      	;
         	rts                		;
         	
vardump: 	ldpv	p1,varchk		;
			mvpr  	p1,r8			; // save current address
vardump0:	ldmam	m0         		; // internal read , internal write.  IRW
			ldr		r2,dbugrows		;
         	ldc		c2,r2			; // rows
vardum1: 	mvrr	r8,r2			;
			jsr		dishex4			; // r2 contains the message pointer
			ldpv  	pC,colon_m		; // 
         	jsr   	tx_line         ; // output CR-LF
			ldcv	c1,7			; // columns
vardum2: 	ldrpi	r2,p1			;
         	jsr		dishex4    		; // display signed
		 	dcjnz	c1,vardum2		;
         	jsr		tx_prmt    		; 
        	addv	r8,8			; 
         	dcjnz	c2,vardum1 		;
         	stp		p1,memptr  		;
			jsr		tx_prmt    		;
			rts                		;
         	
         	//################################
			// Memory fill parameters
			// example of fill memory address 34 with value 1
			// enter 0034 0001 or 0034,0001
			// example of fill memory address 1234 with value 5ac3
			// enter 1234 5ac3 or 1234,5ac3
			// address and value MUST BE 4 digits each
			// external memory support only 8 bits (1 byte)
			//################################
			// buffer length, increment
memlen:		ldpv	pC,hexval4_m    ; // RED/GREEN/BLUE
         	jsr   	tx_line         ;
         	jsr   	asc2hex         ; // return in r3,r2
			str		r3,buff_len 	; // 
			str		r2,buff_inc 	; // 
			jsr		tx_prmt			; 
			rts		                ;

			// Memory fill
			// buffer address,value (r2,r3)
memfill:	ldpv	pC,hexval4_m    ; // RED/GREEN/BLUE
         	jsr   	tx_line         ;
         	jsr   	asc2hex         ; // return in r3,r2
			str		r3,buff_addr 	; //
			str		r2,buff_value	; 
			mvrp	r3,p1			; // address   REG00
			ldr		r5,buff_inc		; // increment REG02
			ldr		r4,buff_len		; // length    REG03
			ldr   	r6,memop		;
			andv  	r6,3			;
			bra   	z,memfill2		;
			ldr		r1,memode		; // save memode before 
			ldmam 	m2				; // internal read , external write.  XWR
			or		r1,r1			; // check for byte/word access
			bra		nz,memfill3		;
memfill2:	strpi	r2,p1			; // word mode
			add  	r2,r5			;
			dec		r4				;
			bra		nz,memfill2		;
			bra		memfill4		;
			// big/little endian setup needed?
memfill3:	strpi	r2,p1			; // byte mode
			mvrr	r2,r3			;
			shr4	r3				; // Big Endian
			shr4	r3				;
			strpi	r3,p1			;
			add  	r2,r5			;
			dec		r4				;
			bra		nz,memfill3		;
memfill4:	ldmam 	m0				; // internal read , internal write.  IRW 
			jsr		tx_prmt			; 
			rts						;

   /////////////////////////////////////////////////////////////////////
   /////////////////////////////////////////////////////////////////////
   // System Subroutines
   // SESMA: Sequential State Machine
   // Search for k-value, return pointer to subroutine.
   // key in r1, pointer to table in p1.
   // all registers are save in stack.
   /////////////////////////////////////////////////////////////////////
   /////////////////////////////////////////////////////////////////////

sesma:   	strpi 	r2,pF            ;// push r2 and r3
         	strpi 	r3,pF            ;
         	ldp   	p1,ssm_pst       ; 
ssm_1:   	ldrp  	r2,p1            ;
         	or    	r2,r2            ;
         	bra   	e,ssm_2          ; 
         	cmpr  	r1,r2            ;
         	bra   	e,ssm_2          ;
         	mvpr  	p1,r3            ; // point to next state.
         	addv  	r3,4             ;
         	mvrp  	r3,p1            ; 
         	bra   	ssm_1            ;
ssm_2:   	ldrx  	r2,p1,1          ; // check code
         	cmprv 	r2,"R"           ; // "R" : restore last state ?
         	bra   	e,p_rest         ;
         	cmprv 	r2,"J"           ; // "J" : save state ?
         	bra   	e,p_jump         ;
         	cmprv 	r2,"S"           ; // "S" : jump to next state ?
         	bra   	ne,ssm_end       ;
p_save:  	ldr   	r2,ssm_pst       ; // read next state
         	str   	r2,ssm_lst       ; // save it 
p_jump:  	ldrx  	r2,p1,3          ; // read next state
         	str   	r2,ssm_pst       ; // 
         	bra   	ssm_end          ;
p_rest:  	ldr   	r2,ssm_lst       ;
         	str   	r2,ssm_pst       ;
ssm_end: 	ldrx  	r2,p1,2          ;// action
         	mvrp  	r2,p1            ;
         	ldrpd 	r3,pF            ;// pop r3 and r2
         	ldrpd 	r2,pF            ;
ssm_exec:	jmpp  	p1               ; // the called address must have a RTS.

         	//################################
			// UART associated routines
			// Transmit/Receive ASCII text
			//################################

   			// Transmit a single line
tx_line: 	
tx_line2:	inpp  	r3,pB	         ; // read status //g1
         	andv  	r3,TXEMPT        ; // transmit empty?
         	bra   	 z,tx_line2      ; // no , wait
tx_char: 	ldrpi 	r4,pC            ; // read character
         	cmprv 	r4,NULL          ; // Check end of line
         	bra   	z,tx_ends        ; //
			cmprv 	r4,"|"			 ;
			bra   	nz,tx_nxt		 ;
			ldcv 	c0,NUMFILL		 ; // number of user defined chars
tx_fill: 	inpp  	r3,pB	         ; // read status //g1
         	andv  	r3,TXFULL        ; // transmit full ?
         	bra   	nz,tx_fill       ; // yes, wait
         	ldrv  	r4,CHARFILL		 ; // the user char
			outpp 	r4,pA  			 ;
			dcjnz 	c0,tx_fill		 ;
         	bra   	tx_line2         ; // next one
tx_nxt:	 	cmprv 	r4,UNDER		 ;
			bra   	nz,tx_nxt2		 ;
			ldrv	r4,SPC			 ;
tx_nxt2:	outpp 	r4,pA            ; // output char //g1
         	inpp  	r3,pB	         ; //*read status //g1
         	andv  	r3,TXFULL        ; //*transmit full ?
         	bra   	nz,tx_line2      ; //*yes, wait
         	bra   	tx_char          ; // next character
tx_ends: 	rts						 ; // finished
   
   			// transmit a full page
tx_page: 	
tx_page2:	jsr   	tx_line          ; // read a line
         	mvpr  	pC,r1            ;
         	str   	r1,temp0         ; 
         	jsr   	tx_prmt          ; // output prompt
         	ldr   	r1,temp0         ;
         	mvrp  	r1,pC            ; 
         	ldrp  	r3,pC            ; // read current character
         	cmprv 	r3,ETX           ; // check for end of page
         	bra   	nz,tx_page2      ; // next line
         	rts                    	 ;

   			// Transmit prompt character
tx_prmtcr: 	ldpv  	pC,promptcr     ; // 
         	jsr   	tx_line         ; // output CR
         	rts                		; //

tx_prmtlf: 	ldpv  	pC,promptlf     ; // 
         	jsr   	tx_line         ; // output LF
         	rts                		; //

tx_prmt: 	ldpv  	pC,prompt       ; // 
         	jsr   	tx_line         ; // output CR-LF
         	rts                    	; //

tx_prmtx2:	ldpv  	pC,promptx2     ; // 
         	jsr   	tx_line         ; // output CR-LF-CR-LF
         	rts                    	; //

   			// Check for Transmitt ready
chkstat: 	inpp  	r1,pB	         ; // read status //g1
         	andv  	r1,TXFULL        ; // transmit full ?
         	bra   	nz,chkstat       ; // yes, wait
         	rts                    ;
			
			// display single digit from 0 to 9
			// digit in R2
disdigit:	addv	r2,'h30			; // convert to ASCII
			outpp	r2,pA           ; // display value
			ldrv	r2,CR			;
			outpp	r2,pA           ; // carriage return
			rts		                ;

   			// Display 2 or 4 hex values.
   			// use: r1,r2,r3,r4,pA,c1,c2
dishexs: 	mvrr  	r2,r3	       	;
		 	andv  	r3,SIGNED       ;
		 	bra   	z,dishex4       ;
		 	not   	r2	       		;
		 	addv  	r2,1			;
		 	ldrv  	r3,"-"			;
		 	outpp 	r3,pA  			; //g1
dishex4: 	mvrr  	r2,r3   		;
         	shr4  	r2      		;
         	shr4  	r2      		; 
         	jsr   	hex2asc 		; 
         	ldr   	r1,hex2val		;
         	outpp 	r1,pA   		;
         	jsr   	chkstat 		; 
         	ldr   	r1,hex1val		;
         	outpp 	r1,pA  			;
         	mvrr  	r3,r2   		;
dishex2: 	jsr   	hex2asc 		; 
         	ldr   	r1,hex2val		;
         	outpp 	r1,pA   		;
         	jsr   	chkstat 		; 
         	ldr   	r1,hex1val		;
         	outpp 	r1,pA   		;
         	jsr   	chkstat 		; 
         	ldrv  	r1,SPC  		;
         	outpp 	r1,pA   		;
         	rts             		; 
      
rdchar:  	inpp  	r1,pB			; // read status reg
         	bitv  	r1,RXDVLD		; // mask data valid bit
         	bra   	z,rdchar 		; // read again
         	inpp  	r1,pA	 		; // read data reg
         	andv  	r1,'hFF  		; // mask data
         	str   	r1,inpchar		; // save it
			rts						; // return in R1
   
rd_once:  	inpp  	r1,pB			; // read status reg
         	bitv  	r1,RXDVLD		; // mask data valid bit
         	bra   	z,rd_once2 		; // read again
         	inpp  	r1,pA	 		; // read data reg
         	andv  	r1,'hFF  		; // mask data
         	str   	r1,inpchar		; // save it
rd_once2:	rts						; // return in R1
   
			// Setup real time clock
setyear: 	ldpv  	pC,decval4_m	; // RTC setup
         	jsr   	tx_line			;
         	jsr   	asc2dec			; // return in r2
		 	str		r2,tmr1year		;
         	jsr   	tx_prmt			; 
         	rts						;
	     	      	
setmonth: 	ldpv  	pC,decval4_m	; // RTC setup
         	jsr   	tx_line			;
         	jsr   	asc2dec			; // return in r2
		 	str		r2,tmr1month	;
         	jsr   	tx_prmt			; 
         	rts						;
	     	      	
setdate: 	ldpv  	pC,decval4_m	; // RTC setup
         	jsr   	tx_line			;
         	jsr   	asc2dec			; // return in r2
		 	str		r2,tmr1date		;
         	jsr   	tx_prmt			; 
         	rts						;

sethour: 	ldpv  	pC,decval4_m	; // RTC setup
         	jsr   	tx_line			;
         	jsr   	asc2dec			; // return in r2
		 	str		r2,tmr1hour		;
		 	xor		r2,r2			;
		 	str		r2,tmr1min		;
		 	str		r2,tmr1sec		;
         	jsr   	tx_prmt			; 
         	rts						;
	     	      	
setmin: 	ldpv  	pC,decval4_m	; // RTC setup
         	jsr   	tx_line			;
         	jsr   	asc2dec			; // return in r2
		 	str		r2,tmr1min		;
		 	xor		r2,r2			;
		 	str		r2,tmr1sec		;
         	jsr   	tx_prmt			; 
         	rts						;
	     	      	
setsec: 	ldpv  	pC,decval4_m	; // RTC setup
         	jsr   	tx_line			;
         	jsr   	asc2dec			; // return in r2
		 	str		r2,tmr1sec		;
         	jsr   	tx_prmt			; 
         	rts						;
	     	      	
set_varchk:	ldpv  	pC,decval4_m	; // RTC setup
         	jsr   	tx_line			;
         	jsr   	asc2dec			; // return in r2
         	mvrr	r2,r1			;
         	jsr		dec2hex			;
		 	str		r3,dbugrows		;
         	jsr   	tx_prmt			; 
         	rts						;
	     	      	
set_creg: 	ldpv  	pC,decval4_m	; // RTC setup
         	jsr   	tx_line			;
         	jsr   	asc2dec			; // return in r2
         	mvrr	r2,r1			;
         	jsr		dec2hex			;
		 	str		r3,r_cols		;
         	jsr   	tx_prmt			; 
         	rts						;
	     	      	
set_rreg: 	ldpv  	pC,decval4_m	; // RTC setup
         	jsr   	tx_line			;
         	jsr   	asc2dec			; // return in r2
         	mvrr	r2,r1			;
         	jsr		dec2hex			;
		 	str		r3,r_rows		;
         	jsr   	tx_prmt			; 
         	rts						;
	     	      	
set_cmem: 	ldpv  	pC,decval4_m	; // RTC setup
         	jsr   	tx_line			;
         	jsr   	asc2dec			; // return in r2
         	mvrr	r2,r1			;
         	jsr		dec2hex			;
		 	str		r3,m_cols		;
         	jsr   	tx_prmt			; 
         	rts						;
	     	      	
set_rmem: 	ldpv  	pC,decval4_m	; // RTC setup
         	jsr   	tx_line			;
         	jsr   	asc2dec			; // return in r2
         	mvrr	r2,r1			;
         	jsr		dec2hex			;
		 	str		r3,m_rows		;
         	jsr   	tx_prmt			; 
         	rts						;
	     	      	
			// target reset pulse
d_targetrst:
			inp		r1,GPREG_07     ; // reset target
         	andv  	r1,TARGET_NSK   ;
		 	orv   	r1,TARGET_MSK	;
         	outp  	r1,GPREG_07     ;
			ldcv	c0,10  			; //
d_targetrst2:
			nop						;
			nop						;
			dcjnz	c0,d_targetrst2	;
			nop;
         	andv  	r1,TARGET_NSK   ;
         	outp  	r1,GPREG_07     ; 
         	ldpv  	pC,treset_m     ; // display message
         	jsr   	tx_line         ; // message out.
         	jsr   	tx_prmtx2       ; 
         	rts                    	;

init_xterm:	ldpv  	pC,initx_m		; // display setup
         	jsr   	tx_line			;
         	rts						;
         	
         	// Protected mode can be more secure if we set a hex number
         	// and match the entry value to clear the reg7 bit 1.
         	// future enhancement         	
d_pcode:	ldpv  	pC,hexval4_m     ; // pcode value must be equal to PCODE_MSK
         	jsr   	tx_line          ;
         	jsr   	asc2hex          ; // return in r2
         	andv  	r2,PCODE_MSK     ; // r2 = PCODE_MSK to set to 1
		 	inp   	r1,GPREG_07    	 ;
         	andv  	r1,PCODE_NSK   	 ;
         	or    	r1,r2	       	 ;
         	outp  	r1,GPREG_07      ;
         	jsr   	tx_prmt          ; 
         	ldpv	pC,enbfile_m     ;
         	jsr   	tx_line          ;
         	jsr   	tx_prmt          ; 
         	rts   	                 ;
	     	      	 
jmp_boot:	ldpv	pC,loadfile_m    ;
         	jsr   	tx_line          ;
         	jsr   	tx_prmt          ; 
         	jsr   	tx_prmt          ; 
         	jmp		BOOT_ADDR        ;
	     	      	 
			// Enable interrupts
irq_set:	ldpv	pC,hexval4_m    ;
         	jsr   	tx_line         ;
         	jsr   	asc2hex         ; // return in r2
			str		r2,irqmask    	; //
			or		r2,r2			; // temporary
			bra		z,irq_dis		;
irq_enb:	sei						;
			uport	t4				; // IRQ ON
			rts						; 
irq_dis:	cli						;
			uport	f4				; // IRQ OFF
			rts		                ;

			// page number selects external SRAM block 
d_pagenum:	ldpv	pC,hexval4_m    ; // 
         	jsr   	tx_line         ;
d_pagenum2:jsr   	asc2hex         ; // return in r2,r3
			andv	r2,'h0007		; // limit to 8 pages for testing
         	ldpag	r2				; // set address page reg = R2
			jsr		tx_prmt			; 
d_pagenum3:	rts						;

		
	////////////////////////////////////////////////////////////
	// Library of Routines/Functions
	////////////////////////////////////////////////////////////

	////////////////////////////////
	// Global delay: input r7
	//		R7 input  = delay
delay:		ldc		c1,r7			;
delay1:		nop						;
			dcjnz	c1,delay1		;
			rts						;

	////////////////////////////////
	// Interrupt 1mS delay: input r7
	//		R7 input  = delay
intdelay:	str		r7,tmr1value	; // set timer
			uflag	fC				; // clear flag
intdelay1:	jmp		tC,intdelay2	;
			bra		ne,intdelay1	;
intdelay2:	rts						;


	////////////////////////////////
	// MULTIPLICATION, unsigned
	//		R1 input  = multiplicand M
	//		R2 input  = multiplier   Q
	//		R3 temp   = product A
	//		R1 output = result high
	//		R2 output = result low
multiply:	xor		r3,r3			; // clear result
			ldcv	c0,15			; // 16 bits : c0=16-1
multiply1:	bitv	r2,1		   	; // bit 0
			bra		z,multiply2		;
			add		r3,r1			;
multiply2:	shr		l,r3			; // bit 0  = link bit A>>1>>L
			shr		k,r2			; // bit 15 = link bit L>>Q>>1
			dcjnz	c0,multiply1	;		
			swap	r3,r1      		; // R1=high, R3= M
multend:	rts						;		

	////////////////////////////////
	// DIVISION
	//		R5 input  = numerator
	//		R4 input  = denominator
	//		R6 output = result  
	//		R3 output = residual
division:	xor		r6,r6			; // clear result
divstart:	sub		r5,r4			;
			bra		s,divend	   	;
			mvrr	r5,r3      		; // residual = numpixels/colorseg
			inc		r6				;
			bra		divstart  		;
divend:		rts						;		

	// (R1)=0 is not leap year, (R1)<>0 it is leap year
	// used regs/ptrs : r1,r3,r4,r5,r6
leap_year:	// check for oldest lap year
			cmprv	r1,1752			; // oldest year leap or first one!!!
			bra		le,not_ly		; // 
check4:		shr		r1				; // shift right logical
			bra		c,not_ly		;
			shr		r1				; // shift right logical
			bra		c,not_ly		;
			// if we got here year is divisible by 4
			// now divide by 100 , use r1 already 1/4
check100:	mvrr	r1,r5			; // restore it
			ldrv	r4,25			; // divide by 25
			jsr		division		;			
			or		r3,r3			; // test for zero remainder
			bra		ne,is_ly		; // non zero is leap year
			// if we got here year is divisible by 100
			// now divide by 400, use r6 is already divided by 100
check400:	mvrr	r6,r5			; // restore it
			ldrv	r4,4			; // divide by 4
			jsr		division		;			
			or		r3,r3			; // test for zero remainder
			bra		ne,not_ly		; // non zero is not leap year
is_ly:		ldrv	r1,'hffff		;
			bra		leapend			;			
not_ly:		xor		r1,r1			;						
leapend:	rts						; //


	////////////////////////////////////////////////////////////
	// Convert HEX/DEC/ASCII values to HEX/DEC/ASCII
	////////////////////////////////////////////////////////////
	// Convert HEX value to DEC
	// register usage:
	//		R2 input  = 4 digit hex 
	//		R3 output = 4 digit decimal
	// use registers: R3/R4/R5/R6 all saved in stack
hex2dec:	dec		r2				;
			ldc		c1,r2			; // hex number
			xor		r3,r3			;
			xor		r4,r4			;
			xor		r5,r5			;
			xor		r6,r6			;
hex2dec1:	inc		r3				;
			cmprv	r3,'h000a		;
			bra		lt,hex2dec2		;
			xor		r3,r3			;
			inc		r4				;
			cmprv	r4,'h000a		;
			bra		lt,hex2dec2		;
			xor		r4,r4			;
			inc		r5				;
			cmprv	r5,'h000a		;
			bra		lt,hex2dec2		;
			xor		r5,r5			;
			inc		r6				;
			cmprv	r6,'h000a		;
			bra		lt,hex2dec2		;
			xor		r6,r6			;
hex2dec2:	dcjnz	c1,hex2dec1		;
			shl4	r4				; // 000x -> 00x0
			shl4	r5				; // 000x -> 00x0
			shl4	r5				; // 00x0 -> 0x00
			shl4	r6				; // 000x -> 00x0
			shl4	r6				; // 00x0 -> 0x00
			shl4	r6				; // 0x00 -> x000
			or		r3,r4			;
			or		r3,r5			;
			or		r3,r6			;
			rts						;	

	////////////////////////////////////////////////////////////
	// Convert DEC value to HEX
	// register usage:
	//		R1 input  = 4 digit decimal maximum 9999
	//		R2 input  = 1 digit decimal maximum 6(5535)
	//		R3 output = 4 digit hexadecimal
	// use registers: R4/R5/R6 all saved in stack
dec2hex:	ldpv	p8,dec2hextab	;
			ldrv	r5,'h000F		;
			xor		r4,r4			; // digit counter
dec2hex1:	mvrr	r1,r6			; // save it
			and		r1,r5			; // mask low nibble
			ldrpi	r2,p8			; // load multiplier
			jsr		multiply		; // R2=low 16 bits
			add		r4,r2			;
			mvrr	r6,r1			; // 
			shr4	r1				; // point to next nibble
			bra		nz,dec2hex1	   	;
			mvrr	r4,r3			;
			mvrr	r6,r1			;
dec2hex2:	rts						;		

	////////////////////////////////////////////////////////////
	// Convert HEX value to ASCII
	// register usage:
	// Inputs:  R2
	// Outputs:  hex1val, hex2val=R2
dec2asc:	// same routine	
hex2asc: 	strpi 	r2,pF            ; // push
         	andv  	r2,'h00F         ;
         	cmprv 	r2,'h00A         ;
         	bra   	lt,hex1          ;
         	addv  	r2,'h007         ;
hex1:    	addv  	r2,'h030         ;
         	str   	r2,hex1val       ;
         	ldrpd 	r2,pF            ; // pop
         	shr4  	r2               ; // shift right 4 logical
         	andv  	r2,'h00F         ;
         	cmprv 	r2,'h00A         ;
         	bra   	lt,hex2          ;
         	addv  	r2,'h007         ;
hex2:    	addv  	r2,'h030         ;
         	str   	r2,hex2val       ; 
         	rts                      ;

	////////////////////////////////////////////////////////////
	// Convert ASCII to HEX, cvalue1,cvalue2
	// register usage:
	// Inputs:  R1
	// Outputs: R2
tohex2:  	mvrr  	r1,r2            ; // save it
         	andv  	r1,'h00ff        ; 
         	subv  	r1,'h030         ; // remove any unwanted char
         	cmprv 	r1,9             ;
         	bra   	ls,tohex21       ;
         	andv  	r1,'h000f        ; 
         	addv  	r1,9             ;
tohex21: 	shr4  	r2               ;
         	shr4  	r2               ;
         	andv  	r2,'h00ff        ; 
         	subv  	r2,'h030         ; // remove any unwanted char
         	cmprv 	r2,9             ;
         	bra   	ls,tohex22       ;
         	andv  	r2,'h000f        ; 
         	addv  	r2,9             ;
tohex22: 	shl4  	r2               ;
         	andv  	r2,'h00f0        ; 
         	or    	r2,r1            ;
         	rts                      ; 

	////////////////////////////////////////////////////////////
	// Convert ASCII to HEX used by UART
	// register usage:
	// Used Flags: uflag 6
	// Used Reg: R1,R2,R3 and rdchar registers
	// Outputs:  R3,R2 = high,low
asc2hex: 	xor   	r2,r2           ; // clear result register
		 	xor   	r3,r3           ; // clear result register
		 	uflag 	f6				;
asc2hex1: 	jsr   	rdchar          ;
			outpp 	r1,pA           ; //g1 output char
asc2hex3: 	cmprv 	r1,CR           ;
         	bra   	z,asc2hex9      ;
		 	cmprv 	r1,"-"			;
		 	bra   	ne,asc2hex4		;
		 	uflag 	t6				;
asc2hex4: 	subv  	r1,'h030  		; // remove any unwanted char
         	bra   	s,asc2hex1 		; // reset counters.
         	shl  	l,r2      		; 
         	shl  	k,r3      		; 
         	shl  	l,r2      		; 
         	shl  	k,r3      		; 
         	shl  	l,r2      		; 
         	shl  	k,r3      		; 
         	shl  	l,r2      		; 
         	shl  	k,r3      		; 
         	cmprv 	r1,9      		;
         	bra   	ls,asc2hex2		;
         	andv  	r1,'h00F  		; // must be a-f
         	addv  	r1,9      		;
asc2hex2: 	or    	r2,r1     		;
         	// debugging
         	strx	r3,pD,0			;
         	strx	r2,pD,1			;
         	bra   	asc2hex1   		;
asc2hex9: 	jmp   	f6,asc2hexa		;
		 	not   	r2,r2			;
		 	not   	r3,r3			;
		 	addv  	r2,1			;
asc2hexa: 	rts                    	; 


	////////////////////////////////////////////////////////////
	// Convert ASCII to DEC used by UART
	// register usage:
	// Used Flags: uflag 7
	// Used Reg: R1,R2,R3 and rdchar registers
	// Outputs:  R3,R2 = high,low
asc2dec: 	xor   	r2,r2           ; // clear result register
		 	xor   	r3,r3           ; // clear result register
asc2dec1: 	jsr   	rdchar          ; // returns in R1
         	cmprv 	r1,CR           ;
         	bra   	z,asc2dec3      ;
         	cmprv	r1,'h0030		;
         	bra		lt,asc2dec1		;
         	cmprv	r1,'h0039		;
         	bra		hi,asc2dec1		;
			outpp 	r1,pA           ; //g1 output char
asc2dec2: 	subv  	r1,'h030  		; // remove any unwanted char
			shl  	l,r2      		; 
         	shl  	k,r3      		; 
         	shl  	l,r2      		; 
         	shl  	k,r3      		; 
         	shl  	l,r2      		; 
         	shl  	k,r3      		; 
         	shl  	l,r2      		; 
         	shl  	k,r3      		; 
		 	or    	r2,r1     		;
         	// debugging
         	strx	r3,pD,0			;
         	strx	r2,pD,1			;
         	bra   	asc2dec1   		;
asc2dec3: 	rts                    	; 

	////////////////////////////////////////////////////////////
	// Month check 28/29/30/31
	// January = 1 to December = 12
	// Monday  = 0 to Sunday = 6
	// Date    = 1 to 31

	// Initialize:
	// month  = 1;
	// Monday = 0;
	// date   = 1;

	// algorithm:
	//	if month = 2
	//		if leap_year
	//			monthcheck = 29
	//		else
	//			monthcheck = 28
	//	goto end
    //	else
	//		if month 1xxx (bit 3 high)
	//			goto August
	//		else
	//			if 0xx0 (bit 3 low and bit 0 low) 
	//				monthcheck = 30
	//			if 0xx1 (bit 3 low and bit 0 high)
	//				monthcheck = 31
	//			goto end
	//	endif
	//
	// august:
	//	if month 1xx0 (bit 3 high and bit 0 low)
	//		monthcheck = 31
	//	if month 1xx1 (bit 3 high and bit 0 high)
	//		monthcheck = 30
	//
	//	end:
	// Register usage	
	//		R5 input  = current month
	//		R6 input  = current year
	//		R8 output = max days for the month
monthchk:	cmprv	r5,2			; // current month
			bra		ne,monthchk0	; // is not February
			// check leapyear at:
			// reset, using default year
			// new year entered manually or remote
			// hw_int4 finds a new year
			// in these cases use a global variable leapyear
			// check if leapyearflag is 1 or 0
			// and jump accordingly 
			// or just call it every time
			//new code
//			push	r5				; // save regs
//			push	r6				;
//         	mvrr	r6,r1			; 
//			jsr		leap_year		;
//			pull	r6				; // restore regs
//			pull	r5				;
//			or		r1,r1			;
//			bra		z,month28		;
			// old code
			mvrr	r6,r9			;
			andv	r9,'h00ff		;
			bra		z,month28		; // not leap year, 2100/2200/2300 for example
			andv	r9,'h0003		; // every 4 years
			bra		nz,month28		; // not leap year
			// end code
month29:	ldrv	r8,29			;
			bra		monthchkend		; // leap year
month28:	ldrv	r8,28			;			
			bra		monthchkend		;
monthchk0:	bitv	r5,8			; //
			bra		nz,monthchk1	;
			bitv	r5,1			; // January to July
			bra		z,month30		;
month31:	ldrv	r8,31			;
			bra		monthchkend		;
month30:	ldrv	r8,30			;
			bra		monthchkend		;
monthchk1:	bitv	r5,1			; // August to December
			bra		z,month31		;
			bra		month30			;
monthchkend:
			rts						;
			
	//////////////////////////////////////////////////////////////////////
	// APP_LEAP_YEAR.ASM :  Leap Year calculation program.
	// To determine whether a year is a leap year, follow these steps:
	// 1. If the year is evenly divisible by 4, go to step 2. Otherwise, go to step 5.
	// 2. If the year is evenly divisible by 100, go to step 3. Otherwise, go to step 4.
	// 3. If the year is evenly divisible by 400, go to step 4. Otherwise, go to step 5.
	// 4. The year is a leap year (it has 366 days).
	// 5. The year is not a leap year (it has 365 days)	
	// Subroutine
	// R1 input leap year
	// (R1)=0 is not, (R1)<>0 it is
	// used regs/ptrs : r1,r3,r4,r5,r6
leap_year:	// check for oldest lap year
			cmprv	r1,1752			; // oldest year leap or first one!!!
			bra		le,not_ly		; // 
check4:		shr		r1				; // shift right logical
			bra		c,not_ly		;
			shr		r1				; // shift right logical
			bra		c,not_ly		;
			// if we got here year is divisible by 4
			// now divide by 100 , use r1 already 1/4
check100:	mvrr	r1,r5			; // restore it
			ldrv	r4,25			; // divide by 25
			jsr		division		;			
			or		r3,r3			; // test for zero remainder
			bra		ne,is_ly		; // non zero is leap year
			// if we got here year is divisible by 100
			// now divide by 400, use r6 is already divided by 100
check400:	mvrr	r6,r5			; // restore it
			ldrv	r4,4			; // divide by 4
			jsr		division		;			
			or		r3,r3			; // test for zero remainder
			bra		ne,not_ly		; // non zero is not leap year
is_ly:		ldrv	r1,'hffff		;
			bra		leapend			;			
not_ly:		xor		r1,r1			;						
leapend:	rts						; //

    ////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////
	// Interrupt vectors
	////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////
			/////////////////////////
			// Interrupt #1
hw_irq1:	uport	t8				;
			uport	f8				;
			rti						;
                                	
			/////////////////////////
			// Interrupt #2
hw_irq2:	uport	t9				;
hw_irq2_1:	uport	f9				;
			rti						;
			
			/////////////////////////
			// Interrupt #3
			// 1 mSec pulse timer
			// refresh 7-seg display
hw_irq3:	// an_cnt = e,d,b,7,e,d,b,7,......
			// dig = HH.MM
			// GPREG_00 = (x"0",an_cnt,dp,dig)
			// convert hex to dec or not!
refreshDis:	// normal display HHMM
			ldr		r5,digitdp		; // decimal point 0 to 4
			xor		r6,r6			; // clear dp		
			ldrv	r2,'h0800		; // last an count
			ldr		r1,an_cnt		; // current counter
			mvrr	r1,r3			; // save it
			and		r2,r1			; // test last count
			bra		z,ref7seg_2	;
			ldrv	r1,'h0100		; // initialize counter
			bra		ref7seg_3		;
ref7seg_2:	shl		l,r1			; // next count	
ref7seg_3:	str		r1,an_cnt		; // save it

			// switch on an_cnt
			bitv	r3,'h0100		; // check an=1
			bra		z,dig2			;
dig1:		cmprv	r5,1			; // decimal point?
			bra		ne,dig1_0		; // no
			ldrv	r6,'h0080		; // yes
dig1_0:		ldr		r4,digit1		;
			andv	r4,'h000f		; // low digit
			bra		outdig			; // display it
dig2:		bitv	r3,'h0200		; // check an=1
			bra		z,dig3			;
			cmprv	r5,2			; // decimal point?
			bra		ne,dig2_0		; // no
			ldrv	r6,'h0080		; // yes
dig2_0:		ldr		r4,digit1		;
			andv	r4,'h00f0		; // high digit
			shr4	r4				;
			bra		outdig			; // display it
dig3:		bitv	r3,'h0400		; // check an=1
			bra		z,dig4			;
			cmprv	r5,3			; // decimal point?
			bra		ne,dig3_0		; // no
			ldrv	r6,'h0080		; // yes
dig3_0:		ldr		r4,digit2		;
			andv	r4,'h000f		; // low digit
			bra		outdig			; // display it
dig4:		cmprv	r5,4			; // decimal point?
			bra		ne,dig4_0		; // no
			ldrv	r6,'h0080		; // yes
dig4_0:		ldr		r4,digit2		;
			andv	r4,'h00f0		; // high digit
			shr4	r4				;
outdig:		ldpv	p1,dig7seg_tab	; // convert
			andv	r4,'h000F		; // limit to 0-F
			ldpy	p1,r4			;
			mvpr	p1,r4			;
			or		r4,r3			; // r4=digit, r3=an
			or		r4,r6			; // add dp
			outp	r4,GPREG_00		;

			// timer 1 milisecond			
hw_irq3_0:	ldr		r1,tmr1msec		; // Basic 1 millisec tick
			or		r1,r1			;
			bra		z,hw_irq3_1		;
			dec		r1				;
			str		r1,tmr1msec		; // general purpouse timer
			bra		hw_irq3_2		;
hw_irq3_1:	uflag	tB				; // clear by someone, not used right now
hw_irq3_2:	rti						;
  
			/////////////////////////
			// Interrupt #4
			// RTC=Real Time Clock
			// used registers:
			// r1,r2,r3,r4,r5,r6,r7,r8,r9
hw_irq4:	ldr		r2,tmr1min		; // current minutes
			ldr		r3,tmr1hour		; // current hours
			ldr		r4,tmr1date		; // current days
			mvrr	r4,r7			; // save day/date		
			ldr		r5,tmr1month	; // current months
			ldr		r6,tmr1year		; // current year
			ldr		r1,tmr1sec		; // current seconds
			inc		r1				;
			mvrr	r1,ra			;
			andv	ra,'h000f		;
			cmprv	ra,'h000a		;
			bra		lt,hw_irq4_s1	;
			andv	r1,'hfff0		;
			addv	r1,'h0010		;
hw_irq4_s1:	cmprv	r1,'h0060		; // 1 minute
			bra		lt,hw_irq4_1	;
			xor		r1,r1			;
			inc		r2				;
			mvrr	r2,ra			;
			andv	ra,'h000f		;
			cmprv	ra,'h000a		;
			bra		lt,hw_irq4_u1	;
			andv	r2,'hfff0		;
			addv	r2,'h0010		;
hw_irq4_u1:	cmprv	r2,'h0060		; // 1 hour
			bra		lt,hw_irq4_2	;
			xor		r2,r2			;
			inc		r3				;
			mvrr	r3,ra			;
			andv	ra,'h000f		;
			cmprv	ra,'h000a		;
			bra		lt,hw_irq4_h1	;
			andv	r3,'hfff0		;
			addv	r3,'h0010		;
hw_irq4_h1:	cmprv	r3,'h0024		; // 1 day
			bra		lt,hw_irq4_3	;
			xor		r3,r3			;
			andv	r4,'h00ff		;
			andv	r7,'hff00		;
			shr4	r7				;
			shr4	r7				;
			inc		r7				;
			cmprv	r7,7			; // check for SUN
			bra		lt,hw_irq4_d1	;
			xor		r7,r7			; // back to MON
hw_irq4_d1:	shl4	r7				;
		 	shl4	r7				;
		 	inc		r4				; // 1 month
			mvrr	r4,ra			;
			andv	ra,'h000f		;
			cmprv	ra,'h000a		;
			bra		lt,hw_irq4_m1	;
			andv	r4,'hfff0		;
			addv	r4,'h0010		;
hw_irq4_m1:	jsr		monthchk		; // 1 month, check 28/29/30/31
			cmpr	r4,r8			; // return in r8 the max day of the month
			bra		le,hw_irq4_4	;
			ldrv	r4,1			;
			inc		r5				;
			mvrr	r5,ra			;
			andv	ra,'h000f		;
			cmprv	ra,'h000a		;
			bra		lt,hw_irq4_m2	;
			andv	r5,'hfff0		;
			addv	r5,'h0010		;
hw_irq4_m2:	cmprv	r5,'h0012		; // 1 year 1 to 12
			bra		le,hw_irq4_5	;
			ldrv	r5,1			; // initialize to January
			inc		r6				;
			mvrr	r5,ra			;
			andv	ra,'h000f		;
			cmprv	ra,'h000a		;
			bra		lt,hw_irq4_y1	;
			andv	r5,'hfff0		;
			addv	r5,'h0010		;
hw_irq4_y1:	str		r6,tmr1year	; 
hw_irq4_5:	str		r5,tmr1month	; 
hw_irq4_4:	or		r4,r7			;			
			str		r4,tmr1date		; 
hw_irq4_3:	str		r3,tmr1hour		; 
hw_irq4_2:	str		r2,tmr1min		; 
hw_irq4_1:	str		r1,tmr1sec		;
			uflag	tD				; // refresh 1 sec myappay / mtapp
			rti						;

			/////////////////////////
			// SWI example : swi sw_irq1;
sw_irq1:	// call subroutine
			rti						;  

   //////////////////////////////////////////////////////////////////////
   //////////////////////////////////////////////////////////////////////
   // Application routines
   //////////////////////////////////////////////////////////////////////
   // Don't overwrite dedicated pointers like:
   // p0,pA,pB,pD,pF
   //////////////////////////////////////////////////////////////////////
   
   // Here your test/application routine
   // apptab: list of myapps
   //
   // here to show temperature and voltages
   // also timers and clock, use apptab similar to sensors.
			// here fetch the apptab
			// and jump to subroutine
			//
myapp:		ldr		r1,myapp_val	;
			andv	r1,7			; // limit to 8 arn
			ldpv	p1,apptab		;
			ldpy	p1,r1			; // get arn
			jmpp	p1				; // execute arn
nothing:	rts						; // do nothing, return to caller

d7s_clock:	jmp		t2,d7s_clock2	;
d7s_clock1:	ldr		r2,tmr1min		;
			str		r2,digit1		;
			ldr		r2,tmr1hour		;
			str		r2,digit2		;
			bra		d7s_clock4			;
d7s_clock2:	ldr		r2,tmr1sec		;
			str		r2,digit1		;
			ldr		r2,tmr1min		;
			str		r2,digit2		;
d7s_clock4:	ldrv	r2,3			;
			str		r2,digitdp		; // deimal point = digit2
			rts						;

d7s_adc0:	// temperature C
			jsr		dis_xadc0		; // get new values
			ldrx	r2,p5,0			;
			// convert to decimal
			jsr		hex2dec			;
			shl4	r3				; // Centigrades
			orv		r3,'h000C		;
			ldrv	r4,2			; // decimal point
			jmp		d7s_adcx		;
			
d7s_adc1:	// temperature F
			jsr		dis_xadc1		; // get new values
			ldrx	r2,p5,1			;
			// convert to decimal
			jsr		hex2dec			;
			shl4	r3				;
			orv		r3,'h000F		; // Farenheit
			ldrv	r4,2			; // decimal point
			jmp		d7s_adcx		;
			
d7s_adc2:	// mili volts 
			jsr		dis_xadc2		; // get new values
			ldrx	r2,p5,2			;
			// convert to decimal
			jsr		hex2dec			;
			ldrv	r4,4			; // decimal point
			jmp		d7s_adcx		;
			
d7s_adc3:	// mili volts 
			jsr		dis_xadc3		; // get new values
			ldrx	r2,p5,3			;
			// convert to decimal
			jsr		hex2dec			;
			ldrv	r4,4			; // decimal point
			jmp		d7s_adcx		;
			
d7s_adc4:	// mili volts 
			jsr		dis_xadc4		; // get new values
			ldrx	r2,p5,4			;
			// convert to decimal
			jsr		hex2dec			;
			ldrv	r4,4			; // decimal point
d7s_adcx:	mvrr	r3,r2			;
			andv	r2,'h00ff		;
			str		r2,digit1		;
			mvrr	r3,r2			;
			shr4	r2				;
			shr4	r2				;
			str		r2,digit2		;
			ldrv	r2,2			;
			str		r4,digitdp		; // deimal point = digit1
			rts						;
			
			
   			// Read XADC for display only
   			// r1=base reg address, r3=number of regs to display,
   			// use: r1,r2,r3,p6,p7,c1
dis_xadc0: 	ldpv	p5,xadcreg		;
			ldrv	r5,'h0100		; // channel 1, address 0
			outp	r5,GPREG_01		; //   	        
			ldrv	r7,ADC_DELAY	; // wait
			jsr		delay			;
	        inp		r2,GPREG_09		; // degree C
			strx	r2,p5,0			;
	        rts                		;
         	
dis_xadc1: 	ldpv	p5,xadcreg		;
			ldrv	r5,'h0200		; // channel 2
			outp	r5,GPREG_01		; // adcmm channel
			ldrv	r7,ADC_DELAY	; // wait
			jsr		delay			;
	        inp		r2,GPREG_09		; // degree F
			strx	r2,p5,1			;
	        rts                		;
         	
dis_xadc2: 	ldpv	p5,xadcreg		;
			ldrv	r5,'h0301		; // channel 3, address 1
			outp	r5,GPREG_01		; // XADC address  	        
			ldrv	r7,ADC_DELAY	; // wait
			jsr		delay			;
	        inp		r2,GPREG_09		; // vccint mili-volts
			strx	r2,p5,2			;
         	rts                		;
         	
dis_xadc3: 	ldpv	p5,xadcreg		;
			ldrv	r5,'h0302		; // channel 3, address 2
			outp	r5,GPREG_01		; // XADC address  	        
			ldrv	r7,ADC_DELAY	; // wait
			jsr		delay			;
	        inp		r2,GPREG_09		; // vccaux mili-volts
			strx	r2,p5,3			;
         	rts                		;
         	
dis_xadc4: 	ldpv	p5,xadcreg		;
			ldrv	r5,'h0303		; // channel 3, address F
			outp	r5,GPREG_01		; // XADC address  	        
			ldrv	r7,ADC_DELAY	; // wait
			jsr		delay			;
	        inp		r2,GPREG_09		; // vaux6 mili-volts
			strx	r2,p5,4			;
         	rts                		;
         	
walking:	ldr		r1,pattern1		;
			ldr		r2,pattern2		;
			outp	r1,S1REG_1		;
			outp	r2,S1REG_0		;
			shl		r1				;
			shl		k,r2			;
			bitv	r2,'h80			;
			bra		z,walking1		;
			orv		r1,1			;
walking1:	str		r1,pattern1		;
			str		r2,pattern2		;
			rts						;
			
			//################################
			// Read and Print XADC and adcmm values
prn_xadc:	jsr		get_xadc0		;
			jsr		get_xadc1		;
			jsr		get_xadc2		;
			jsr		get_xadc3		;
			ldpv  	pC,line_m		; // separator
         	jsr   	tx_line			;
         	jsr		tx_prmt			; // CR-LF
			rts						;
			
get_xadc0:	ldpv	p5,xadcreg		;
			ldrv	r5,'h0000		; // channel 0, address 0
			outp	r5,GPREG_01		; //   	        
			ldrv	r7,ADC_DELAY	; // wait
			jsr		delay			;
	        inp		r2,GPREG_08		; // raw data
			jsr		dishex4			; // r2 contains the message pointer
			ldpv  	pC,adc0_m		; // message
         	jsr   	tx_line			;
         	jsr		tx_prmt			; // CR-LF
			ldrv	r5,'h0100		; // channel 1, address 0
			outp	r5,GPREG_01		; //   	        
	        inp		r2,GPREG_09		; // degree C
			strx	r2,p5,0			;
			jsr		dishex4			; // r2 contains the message pointer
			ldpv  	pC,adc1_m		; // message
         	jsr   	tx_line			;
         	jsr		tx_prmt			; // CR-LF
			ldrv	r5,'h0200		; // channel 2
			outp	r5,GPREG_01		; // adcmm channel
	        inp		r2,GPREG_09		; // degree F
			strx	r2,p5,1			;
			jsr		dishex4			; // r2 contains the message pointer
			ldpv  	pC,adc2_m		; // message
         	jsr   	tx_line			;
         	jsr		tx_prmt			; // CR-LF
         	jsr		tx_prmt			; // CR-LF gap 
	        rts                		;
         	
get_xadc1:	ldpv	p5,xadcreg		;
			ldrv	r5,'h0301		; // channel 3, address 1
			outp	r5,GPREG_01		; // XADC address  	        
			ldrv	r7,ADC_DELAY	; // wait
			jsr		delay			;
	        inp		r2,GPREG_08		; // raw data
			jsr		dishex4			; // r2 contains the message pointer
			ldpv  	pC,adc0_m		; // message
         	jsr   	tx_line			;
         	jsr		tx_prmt			; // CR-LF
	        inp		r2,GPREG_09		; // vccint mili-volts
			strx	r2,p5,2			;
			jsr		dishex4			; // r2 contains the message pointer
			ldpv  	pC,adc3_m		; // message
         	jsr   	tx_line			;
         	jsr		tx_prmt			; // CR-LF
          	jsr		tx_prmt			; // CR-LF
         	rts                		;
         	
get_xadc2:	ldpv	p5,xadcreg		;
			ldrv	r5,'h0302		; // channel 3, address 2
			outp	r5,GPREG_01		; // XADC address  	        
			ldrv	r7,ADC_DELAY	; // wait
			jsr		delay			;
	        inp		r2,GPREG_08		; // raw data
			jsr		dishex4			; // r2 contains the message pointer
			ldpv  	pC,adc0_m		; // message
         	jsr   	tx_line			;
         	jsr		tx_prmt			; // CR-LF
	        inp		r2,GPREG_09		; // vccaux mili-volts
			strx	r2,p5,3			;
			jsr		dishex4			; // r2 contains the message pointer
			ldpv  	pC,adc3_m		; // message
         	jsr   	tx_line			;
         	jsr		tx_prmt			; // CR-LF
          	jsr		tx_prmt			; // CR-LF
         	rts                		;
         	
get_xadc3:	ldpv	p5,xadcreg		;
			ldrv	r5,'h0303		; // channel 3, address 3
			outp	r5,GPREG_01		; // XADC address  	        
			ldrv	r7,ADC_DELAY	; // wait
			jsr		delay			;
	        inp		r2,GPREG_08		; // raw data
			jsr		dishex4			; // r2 contains the message pointer
			ldpv  	pC,adc0_m		; // message
         	jsr   	tx_line			;
         	jsr		tx_prmt			; // CR-LF
	        inp		r2,GPREG_09		; // vp/vn mili-volts
			strx	r2,p5,4			;
			jsr		dishex4			; // r2 contains the message pointer
			ldpv  	pC,adc4_m		; // message
         	jsr   	tx_line			;
         	jsr		tx_prmt			; // CR-LF
          	jsr		tx_prmt			; // CR-LF
         	rts                		;
         	
			// check leap year
lyear:		ldpv  	pC,decval4_m	; //
         	jsr   	tx_line			;
         	jsr   	asc2hex			; // return in r2
         	mvrr	r2,r1			;
         	jsr		dec2hex			;
		 	str		r3,leapyear		; // warning: leapyear=variable, leap_year=label subroutine
         	jsr   	tx_prmt			;
         	ldr		r1,leapyear		;
			jsr		leap_year		;
			or		r1,r1			;
			bra		z,lyear_n		;
         	ldpv	pC,yes_m      	; // display menu
			bra		lyear_e		;
lyear_n:	ldpv	pC,no_m	      	; // display menu
lyear_e:	jsr		tx_line        	;
	 		jsr		tx_prmt        	; 
			rts						;

			// ends Application code

   //////////////////////////////////////////////////////////////////////
   //////////////////////////////////////////////////////////////////////
   // System Constants and Menu Messages
   //////////////////////////////////////////////////////////////////////
   //////////////////////////////////////////////////////////////////////

version_m:		dt  " SW code version__ : 0503 2024 -v1.0";
hwversion_m:	dt  " HW code version__ : "; 
codelength_m:	dt  " Program/code ends : "; 
datalength_m:	dt  " RAM/data ends____ : "; 
bootlength_m:	dt  " Boot code starts_ : "; 
ipversion_m:	dt  " Opus1 ip version_ : "; 

yes_m:		dt  " YES"; 
no_m:		dt  " NO"; 
not_yet_m:	dt	" Not implemented yet";
done_m:		dt  " Done"; 
hex_m:		dt  " Hexadecimal : "; 

line_m:		dt  "-----------------------------------"; 
input_m:	dt  "-- Inputs --"; 
output_m:	dt  "-- Outputs --"; 

memof_m:	dt  " Internal Memory Access"; 
memon_m:	dt  " External Memory Access";
   
membyte_m:	dt  " Byte Memory Access"; 
memword_m:	dt  " Word Memory Access";
   
hexval2_m:	dt  " Enter hex value xx[RET] = ";
hexval4_m:	dt  " Enter hex value xxxx[RET] = ";
hexval8_m:	dt  " Enter hex value xxxx,yyyy[RET] = ";
decval4_m:	dt  " Enter decimal [RET] = ";
enbfile_m:	dt  " Ready to load program with L cmd";
loadfile_m:	dt  " Send .mem file";
         
treset_m:	dt  " Target Reset done, tap SPACE to start";
colon_m:	dt	": ";
promptx2:	dw  CR; // 0x0D
         	dw  LF; // 0x0A
prompt:		dw  CR; // 0x0D
promptlf:	dw  LF; // 0x0A
			dw  NULL; // terminator
			
promptcr:	dw  CR; // 0x0D
			dw  NULL; // terminator
			
adc0_m:		dt  " Raw data";
adc1_m:		dt  " Degree C";
adc2_m:		dt  " Degree F";
adc3_m:		dt  " vccint/vccaux";
adc4_m:		dt  " vp/vn";
				
// hex to binary for bit manipulation
h2btab:		dw  'h0001,'h0002,'h0004,'h0008 ;
	 		dw  'h0010,'h0020,'h0040,'h0080 ;
	 		dw  'h0100,'h0200,'h0400,'h0800 ;
	 		dw  'h1000,'h2000,'h4000,'h8000 ;

// Initialize Screen
 			 		
initx_m:	dw  ESC; // 0x0D
         	dt  "[8;60;90t";
			
fg_blk_m:	dw  ESC;
         	dt  "[30m";
fg_red_m:	dw  ESC;
         	dt  "[91m";
fg_grn_m:	dw  ESC;
         	dt  "[92m";
fg_yel_m:	dw  ESC;
         	dt  "[93m";
fg_blu_m:	dw  ESC;
         	dt  "[94m";
fg_mag_m:	dw  ESC;
         	dt  "[95m";
fg_cya_m:	dw  ESC;
         	dt  "[96m";
fg_wht_m:	dw  ESC;
         	dt  "[97m";
			
// Clear Screen
cls_m:		dw	ESC				; // VT100 escape sequence
			dt	"[2J"			; // Clear screen
// Cursor Home
chome_m:	dw	ESC				; // VT100 escape sequence
			dt	"[H"			; // Home
			
//							        p g f e  d c b a
dig7seg_tab:	dw	'h003F	; // 0  0 0 1 1  1 1 1 1
				dw	'h0006	; // 1  0 0 0 0  0 1 1 0
				dw	'h005B	; // 2  0 1 0 1  1 0 1 1
				dw	'h004F	; // 3  0 1 0 0  1 1 1 1
				dw	'h0066	; // 4  0 1 1 0  0 1 1 0
				dw	'h006D	; // 5  0 1 1 0  1 1 0 1
				dw	'h007D	; // 6  0 1 1 1  1 1 0 1
				dw	'h0007	; // 7  0 0 0 0  0 1 1 1 
				dw	'h007F	; // 8  0 1 1 1  1 1 1 1 
				dw	'h0067	; // 9  0 1 1 0  0 1 1 1
				dw	'h0077	; // a  0 1 1 1  0 1 1 1
				dw	'h007C	; // b  0 1 1 1  1 1 0 0
				dw	'h0039	; // c  0 0 1 1  1 0 0 1
				dw	'h005E	; // d  0 1 0 1  1 1 1 0
				dw	'h0079	; // e  0 1 1 1  1 0 0 1
				dw	'h0071	; // f  0 1 1 1  0 0 0 1
				
   //////////////////////////////////////////////////////////////////////
   // Menu Tables   
   //////////////////////////////////////////////////////////////////////
   // Field definitions:   

   // VALUE  :  input key or single value.
   // JCODE  :  "J" -> jump to next state.
   //           "S" -> save present state and jump to next state
   //           "R" -> restore last state to present state and jump into it.
   // ARADD  :  Action routine address
   // NXST   :  Next state address

   ///////////////////////////////
   // SESMA for UART state machine
   ///////////////////////////////
         //    VALUE PCODE  ARADD    NXST
		 // Main Menu
kpst00:  dw    "a"  ,"J" , d_appset, kpst40; //application setup
         dw    "s"  ,"J" , d_sysset, kpst30; //system setup
         dw    "d"  ,"J" , d_debugq, kpst20; //memory/register access
         dw    "v"  ,"J" , d_prgver, kpst00; //program version
         dw    "b"  ,"J" , d_help,   kpst00; //display the help notes
         dw    "h"  ,"J" , d_help_io,kpst00; //display the help notes
         dw    NULL ,"J" , d_menu,   kpst00; //d_menu
   
         // Debug Menu
kpst10:  dw    "A"  ,"J" , d_mema,   kpst10; //memory access mode
         dw    "B"  ,"J" , d_memb,   kpst10; //memory byte mode
         dw    "P"	,"J",  d_pagenum,kpst10; // set page SRAM
         dw    "d"  ,"J" , memdump,  kpst10; // memory display
         dw    "n"  ,"J" , memnext,  kpst10; // memory display
         dw    "f"  ,"J" , memfill,  kpst10; // memory fill
         dw    "l"  ,"J" , memlen,	 kpst10; // memory fill
         dw    "m"  ,"S" , s_bitop,  wpst01; //memory
         dw    "w"  ,"S" , s_bitop,  wpst01; //write register
         dw    "s"  ,"S" , s_bitop   wpst01; // set bit
         dw    "c"  ,"S" , s_bitop,  wpst01; // clear bit
         dw    "t"  ,"S" , s_bitop,  wpst01; // toggle bit
         dw    "i"  ,"S" , s_bitop,  wpst01; // pulse bit
         dw    "a"  ,"S" , s_bitop,  wpst01; // and reg with value
         dw    "o"  ,"S" , s_bitop,  wpst01; // or reg with value
         dw    "e"  ,"S" , s_bitop,  wpst01; // and reg with value
         dw    "b"  ,"J" , d_base,   kpst10; // base reg address 
         dw    "r"  ,"J" , d_aregs,  kpst10; //display all regs
         dw    "R"  ,"J",  d_regdump,kpst10; // display I/O regs
         dw    "I"  ,"J" , irq_set,  kpst10; //enable interrupts, disabled=0, enabled=1
         dw    "v"  ,"J" , vardump,  kpst10; // memory display
         dw    "h"  ,"J" , d_helpd,  kpst10; //display the help notes
         dw    "x"  ,"J" , d_menu,   kpst00; // return
         dw    "W"  ,"J" , d_pcode,  kpst10; // pcode set, make program RAM writable or not
         dw    "L"  ,"J" , jmp_boot, kpst10; //load program
         dw    " "  ,"J" , d_debug,  kpst10;
         dw    NULL ,"J" , d_nothing,kpst10;
         
         // Debug Menu
kpst20:  dw    "Y"  ,"J" , d_debug,   kpst10; //memory/register access
         dw    " "  ,"J" , d_menu,    kpst00;
         dw    NULL ,"J" , d_menu,    kpst00;
         
         // System Menu
kpst30:  dw     "t" ,"J", d_targetrst, kpst30; // target reset.
         dw     "Y" ,"J", setyear,     kpst30; // set RTC
         dw     "M" ,"J", setmonth,    kpst30; // set RTC
         dw     "D" ,"J", setdate,     kpst30; // set RTC
         dw     "H" ,"J", sethour,     kpst30; // set RTC
         dw     "U" ,"J", setmin,      kpst30; // set RTC
         dw     "S" ,"J", setsec,      kpst30; // set RTC
         dw     "L" ,"J",  lyear,      kpst30; // check leap year
         dw     "k" ,"J", d_rtcval,    kpst30; // read master clock
         dw     "c" ,"J", set_creg,    kpst30; // set R colums
         dw     "r" ,"J", set_rreg,    kpst30; // set R rows
         dw     "C" ,"J", set_cmem,    kpst30; // set R colums
         dw     "R" ,"J", set_rmem,    kpst30; // set R rows
         dw     "v" ,"J", set_varchk,  kpst30; // set debug variable rows
         dw     "h" ,"J" ,d_helps,     kpst30; //display the help notes
         dw    	"x" ,"J", d_menu,      kpst00; //return to main
         dw     NULL,"J", d_sysset,    kpst30; //
   
         // Application Menu
kpst40:  dw     "w" ,"J",  d_walking,   kpst40; //display the help notes
         dw     "s" ,"J",  d_switch,    kpst40; //display the help notes
         dw     "L" ,"J",  d_setled,    kpst40; //display the help notes
         dw     "p" ,"J",  prn_xadc,	kpst40; // print on xterm ADC values
         dw     "d" ,"J",  d_xadc,		kpst40; // display on 7seg ADC values
         dw    	"r" ,"J",  d_io_aregs,  kpst40; // display all regs
         dw     "H" ,"J",  d_rtcval,    kpst40; // read master clock
         dw     "M" ,"J",  d_rtcmode,   kpst40; // read master clock
         dw     "h" ,"J",  d_helpa,     kpst40; // display the help notes
         dw     "x" ,"J",  d_menu,   	kpst00; // return to main
         dw     NULL,"J",  d_appset, 	kpst40; //
   
   ///////////////////////////////
   // Table for Write registers
   ///////////////////////////////
   //    VALUE PCODE  ARADD    NXST
wpst00:  dw    CR   ,"R" , a_quit,   kpst00; //do nothing
         dw    "q"  ,"R" , a_quit,   kpst00; //do nothing
         dw    NULL ,"J" , a_regdat, wpst00; //display menu
   
wpst01:  dw    ","  ,"J" , a_setadd, wpst02; //set addr and wait for data
         dw    " "  ,"J" , a_setadd, wpst02; //set addr and wait for data
         dw    "-"  ,"J" , a_setadd, wpst03; //set addr and wait for -data
         dw    "n"  ,"J" , a_setadd, wpst03; //set addr and wait for -data
         dw    CR   ,"R" , a_getval, kpst00; //get current value
         dw    "q"  ,"R" , a_quit,   kpst00; //do nothing
         dw    NULL ,"J" , a_getadr, wpst01; //get 4 characters
   
wpst02:  dw    CR   ,"R" , a_wrval1, kpst00; //write reg and return
         dw    "q"  ,"R" , a_quit,   kpst00; //do nothing
         dw    NULL ,"J" , a_regdat, wpst02; //display menu
   
wpst03:  dw    CR   ,"R" , a_wrval2, kpst00; //write reg and return
         dw    "q"  ,"R" , a_quit,   kpst00; //do nothing
         dw    NULL ,"J" , a_regdat, wpst03; //display menu
   
   //////////////////////////////////////////////////////////////////////
   // Menu Messages
   // '|' character start a sequence of user define chars like '-'
   // Defined in tx_line subroutine
   //////////////////////////////////////////////////////////////////////
menu:    dt    "|MasterControl : Main Menu|"; 
         dt    " a = Applications";
         dt    " d = monitor/Debug"; 
         dt    " s = System setup";
         dt    " b = Main board layout"; 
         dt    " h = I/O  board layout"; 
         dt    " v = Version"; 
         dt    "|||"; 
         dw    ETX;// end of page 
         
debugq_m:dw    ESC;
         dt    "[91m"; // Light Red
         dt    "|Debug Menu|"; 
         dt    " This is for debugging only, experience with the tools is needed|";
         dt    " Any memory or internal register writing can cause problems_____|";
         dt    " and the system must be reseted using HW reset push button._____|";
         dt    " If you want to continue press :________________________________|";
         dw    ESC;
         dt    "[93;4m"; // Light Yellow, underline
         dt    " Y ";
         dw    ESC;
         dt    "[91;24m"; // Light Red
         dt    " any other key returns to main__________________________________|";
         dt    "||||";	
         dw    ETX;// end of page
	
   
debug_m: dt    "|Debug Menu|"; 
         dt    " A = memory Access mode"; 
         dt    " B = memory Byte   mode"; 
         dt    " P = external memory Page"; 
         dt    " m = Memory write/read"; 
         dt    " d = Memory dump"; 
         dt    " n = Next dump";
         dt    " f = fill memory"; 
         dt    " l = set length/increment"; 
         dt    ""; 
         dt    " w = Write/read register"; 
         dt    " s = Set reg bit"; 
         dt    " c = Clear reg bit"; 
         dt    " t = Toggle reg bit"; 
         dt    " i = Pulse reg bit"; 
         dt    " a = and"; 
         dt    " o = or"; 
         dt    " e = xor"; 
         dt    ""; 
         dt    " b = set Base Registers address"; 
         dt    " r = Read regs"; 
         dt    " R = Read I/O regs(0100-013F)"; 
         dt    ""; 
         dt    " v = Display variables";
         dt    " I = IRQ mask"; 
         dt    "||||";	
         dw    ESC;
         dt    "[91m"; // Light Red
         dt    "To download a .mem file set W=0";
         dt    " W = Protect 2, Unprotect 0";
         dt    " L = Load Program *.mem"; 
         dw    ESC;
         dt    "[97m"; // default white
         dt    ""; 
         dt    "||||";	
         dt    " h = HELP"; 
         dt    " x = exit";
         dt    "||||";	
         dw    ETX;// end of page
	
sysset_m:dt    "|System Setup|"; 
         dt    " Set Real Time Clock";
         dt    " Y = Year";
         dt    " M = Month";
         dt    " D = day/DATE";
         dt    " H = Hour , 24 hours format";
         dt    " U = minUte";
         dt    " S = Sec";
         dt    ""; 
         dt    " k = display master clocK ";
         dt    ""; 
         dt    " L = leap year check";
         dt    "___enter year in Decimal [RET]";
         dt    "___prints yes/no on xTerm"; 
         dt    "|"; 
         dt    " Set row and column register display"; 
         dt    " c = set reg columns"; 
         dt    " r = set reg rows___"; 
         dt    " C = set mem columns"; 
         dt    " R = set mem rows___"; 
         dt    "|"; 
         dt    " Set row variables display"; 
         dt    " v = set var rows"; 
         dt    "|"; 
         dt    " t = toggle Reset bit0 Reg7";
         dt    "|"; 
         dt    " h = HELP"; 
         dt    " x = exit";
         dt    "|||"; 
         dw    ETX;// end of page
   
appset_m:dt    "|Application|";
         dt    ""; 
         dt    " | Tests"; 
         dt    " w = walking pattern"; 
         dt    " s = SW to LEDs"; 
         dt    " L = write to LEDs"; 
         dt    ""; 
         dt    " | Print in Hex XADC";
         dt    " p = temp, vccint, vccaux, vp/vn"; 
         dt    ""; 
         dt    " | Display XADC";
         dt    " d = 0(*C) 1(*F), 2(vccint), 3(vccaux), 4(vp/vn)"; 
         dt    ""; 
         dt    " | Display Output/Input registers";
         dt    " |__LEDs/Swithces-Pbushbuttons ";
         dt    " r = Read 16 registers"; 
         dt    ""; 
         dt    " |"; 
         dt    " H = Display Hours:Minutes";
         dt    " M = Display Minutes:Seconds";
         dt    ""; 
         dt    " |"; 
         dt    " h = HELP"; 
         dt    " x = Exit";
         dt    "|||"; 
         dw    ETX;// end of page

   //////////////////////////////////////////////////////////////////////
   // Help Messages
   // Underscore character is used to fill with SPACE for formatting text
   // this is due to a limitation in my PERL program to convert assembler
   // code into binary hex .mem format (propietary, Gill's format)
   // One space is fine, more than one must be filled with underscore char
   // to get a good print out
   //////////////////////////////////////////////////////////////////////
help_m:  dt    "||| Main Board Layout |||"; 
         dt    " Alchitry Au with I/O board"; 
         dt    " Opus1-uC16 processor 16Kx16"; 
         dt    " version MWYY (Month Week Year)"; 
         dt    "|||||||"; 
         dt    ""; 
         dt    " From top to bottom_"; 
         dt    "__LED 1 : UART activity"; 
         dt    "__LED 2 : Program protection_ON"; 
         dt    "__LED 3 : Attempt to write on protected RAM"; 
         dt    "__LED 4 : Wrong OPCODE, big problem"; 
         dt    "__LED 5 : IRQ enabled and heartbeat_(1Sec)"; 
         dt    "__LED 6 : OFF"; 
         dt    "__LED 7 : OFF"; 
         dt    "__LED 8 : Main 100MHz clock LOCKED"; 
         dt    ""; 
         dt    "__PB____: Hardware Reset"; 
         dt    "|||||||"; 
         dt    "To see the assembly code of this program"; 
         dt    " open MasterControl.asm file"; 
         dt    ""; 
         dt    "|||||||"; 
         dt    " Space key will refresh the screen"; 
         dt    " Enter x to exit (previous menu)"; 
         dt    "|||||||"; 
         dw    ETX;// end of page 
         
help_io:  dt    "||| I/O Board Layout |||"; 
         dt    " I/O board LEDs/switches/push buttons"; 
         dt    ""; 
         dt    "______________*-------------*______________"; 
         dt    "______________* PB TOP/UP___*______________"; 
         dt    "______________*-------------*______________"; 
         dt    "*------------**-------------**------------*"; 
         dt    "* PB LEFT____** PB CENTER___** PB RIGHT___*"; 
         dt    "*------------**-------------**------------*"; 
         dt    "______________*-------------*______________"; 
         dt    "______________* PB BOT/DWN__*______________"; 
         dt    "______________*-------------*______________"; 
         dt    ""; 
         dt    "*---------**---------**---------*---------*"; 
         dt    "*__digit__**__digit__**__digit__*__digit__*";
         dt    "*____4____**____3____**____2____*____1____*";
         dt    "*---------**---------**---------*---------*"; 
         dt    ""; 
         dt    "*------------**-------------**------------*"; 
         dt    "*___L E D 3__**___L E D 2___**___L E D 1__*"; 
         dt    "*------------**-------------**------------*"; 
         dt    "_----bits----__----bits-----__----bits----_"; 
         dt    "_23........16__15..........8__7..........0_"; 
         dt    ""; 
         dt    ""; 
         dt    "*------------**-------------**------------*"; 
         dt    "* DIP SW 3___** DIP SW 2____** DIP SW 1___*"; 
         dt    "*------------**-------------**------------*"; 
         dt    "_----bits----__----bits-----__----bits----_"; 
         dt    "_23........16__15..........8__7..........0_"; 
         dt    ""; 
         dt    "|||||||"; 
         dt    "To see the assembly code of this program"; 
         dt    " open MasterControl.asm file"; 
         dt    ""; 
         dt    "|||||||"; 
         dt    " Space key will refresh the screen"; 
         dt    " Enter x to exit (previous menu)"; 
         dt    "|||||||"; 
         dw    ETX;// end of page 
         
helpa_m: dt    "| H E L P |"; 
         dt    "| Application menu"; 
         dt    " w = walking pattern LEDs";
         dt    " s = copy switches to LEDs";
         dt    ""; 
         dt    " p = prints on xTerm in Hexadecimal";
         dt    "___Raw data, Degree C and Degree F"; 
         dt    "___Raw data, vccint, vccaux and vp/vn"; 
         dt    ""; 
         dt    " d = displays on 7-seg in Decimal";
         dt    "___Degree C, Degree F"; 
         dt    "___vccint, vccaux and vp/vn"; 
         dt    "___0=C, 1=F, 2=vccint, 3=vccaux, 4=vp/vn";
         dt    "___push buttons: BTNL=C BTNU=Clock BTNR=F";
         dt    ""; 
         dt    "| Print/Display on xTerm/7-seg";
         dt    " H = Print/Display clock Hours:Minutes ";
         dt    " ____also pressing the button Up";
         dt    " M = Print/Display clock Minutes:Seconds";
         dt    " ____also pressing the button Down";
         dt    ""; 
         dt    " r = Read 16 Registers(x0100 to x010F)";
         dt    " reg x0100 TO x0107 = OUTPUTS"; 
         dt    " __0100 = __LED2-LED1"; 
         dt    " __0101 = __0000-LED3"; 
         dt    ""; 
         dt    " reg x0108 TO x010F = INPUTS"; 
         dt    " __0108 = __0000-DIPSW3"; 
         dt    " __0109 = DIPSW2-DIPSW1"; 
         dt    " __010A = __0000-BTNs__"; 
         dt    ""; 
         dt    "|||||||"; 
         dt    "Space key will refresh the screen"; 
         dt    "Enter x to exit (previous menu)"; 
         dt    "|||||||"; 
         dw    ETX;// end of page 
           
helps_m: dt    "| H E L P |"; 
         dt    " System setup"; 
         dt    " Prints on xTerm";
         dt    ""; 
         dt    " |Set RTC = Real Time Clock"; 
         dt    " Enter values in Decimal"; 
         dt    " if value is not entered, default to zero"; 
         dt    " For example: Y=2024, M=3, D=429,H=15, U=30"; 
         dt    "___S=0 by default if not entered"; 
         dt    "___U are minutes, Hours in 24H format"; 
         dt    "___D=0429 is :"; 
         dt    "___04 is the day of the week from 0(Mon) to 6(Sun)"; 
         dt    "___29 date of the Month"; 
         dt    ""; 
         dt    " |Read RTC = Real Time Clock"; 
         dt    " k = prints and displays clock"; 
         dt    "_____switch 8 defines display H:U or U:S"; 
         dt    "_____1st bank of the right, left switch"; 
         dt    ""; 
         dt    "Toggle Reset"; 
         dt    " R = toggle Reset Register GPREG_07 bit0";
         dt    "_____reset pulse is sent out to CPU and board";
         dt    ""; 
         dt    " |Set row and column for R and r commands"; 
         dt    "_____decimal number -1 of desired cols/rows "; 
         dt    " c = set column registers"; 
         dt    " r = set row ___registers___"; 
         dt    " C = set column memory"; 
         dt    " R = set rows __memory"; 
         dt    " |Set rows for variable dump command"; 
         dt    "_____decimal number -1 of desired rows"; 
         dt    " v = det debug row, column is fixed";
         dt    "|||||||"; 
         dt    "Space key will refresh the screen"; 
         dt    "Enter x to exit (previous menu)"; 
         dt    "|||||||"; 
         dw    ETX;// end of page 
           
helpd_m: dt    "| H E L P |"; 
         dt    "| Memory Commands"; 
         dt    " A = Memory access (toggle)";
         dt    "____internal or external memory access (toggle)";
         dt    "____board must support DRAM/SDRAM/SRAM";
         dt    " B = Memory byte mode (toggle)";
         dt    "____byte or word memory access (toggle)";
         dt    " m = Memory read/write: (MEM ADDR)";
		 dt    "___[m]addr[RET] read and set address"  ;
		 dt    "___[m]addr,val[RET] write value"  ;
         dt    " d = dump memory from address 0";
         dt    " n = next N memory rows from last address";
         dt    " f = fill memory with value + increment";
         dt    "____addr,value = aaaa,vvvv (comma or space)";
         dt    "____Enter Hex number: 1a3b,0055 [RET]";
         dt    " l = memory length and increment";
         dt    "____length,increment = llll,iiii (comma or space)";
         dt    "____aaaa,vvvv,llll,iiii mandatory 4 digits";
         dt    "____Enter Hex number: 1000,0002";
         dt    ""; 
         dt    "| Register Commands"; 
         dt    "| Enter numbers in Hexadecimal";
         dt    " b = set BASE ADDR";
         dt    " r = Read 16 Registers(BASE ADDR + 0 to F)";
         dt    " R = Read I/O Registers(0100-013F) defined at top level";
         dt    " w = Write Output Port/Register: (full 16 bits address)"; 
         dt    "____[w]addr[RET] read port"; 
         dt    "____[w]addr,val[RET] delimeter comma"; 
         dt    "____[w]addr val[RET] delimiter space"; 
         dt    "____[w]addrnval[RET] one's complement, delimiter n"; 
         dt    "____[w]addr-val[RET] two's complement, delimiter -"; 
         dt    ""; 
         dt    "| Bit manipulations"; 
         dt    "[s/c/t/i]regaddr,bit[RET] (bit=0 to F)"; 
         dt    "___Set reg bit: s100,a[RET] reg 0100 bit 10 (hex A)"; 
         dt    "___Clear reg bit: c0120,f[RET] reg 0120 bit 15 (hex F)"; 
         dt    "___Toggle reg bit: t6,8[RET] reg 0006 bit 8"; 
         dt    "___Pulse reg bit: p001f,0[RET] reg 001f bit 0"; 
         dt    "[a/o/e]  regaddr,mask[RET]"; 
         dt    "___a0100,0055, value of 0100 and 0055 hex"; 
         dt    "___o0120,ff00, value of 0120 or  FF00 hex"; 
         dt    "___e0130,55aa, value of 0130 xor 55AA hex"; 
         dt    ""; 
         dt    " I = Enable/Disable Interrupts, 0=disable, 1=enable"; 
         dt    "|||||||"; 
         dt    " Space key will refresh the screen"; 
         dt    " Enter x to exit (previous menu)"; 
         dt    "|||||||"; 
         dw    ETX;// end of page 
         
   //////////////////////////////////////////////////////////////////////
   // Application subroutines
   //////////////////////////////////////////////////////////////////////
apptab:		dw	d7s_adc0		; // xadc degree C
			dw	d7s_adc1		; // xadc degree F
			dw	d7s_adc2		; // xadc vccint
			dw	d7s_adc3		; // xadc vccaux
			dw	d7s_adc4		; // xadc vp/vn
			dw	d7s_clock		; // clock
			dw	walking			; // escape/exit
			dw	nothing			; // idle/do nothing
         
// mark the end of protected code         
zend_code:	 dw	zend_code;
         
   //////////////////////////////////////////////////////////////////////
   //
   // Work Area, Stack Area, Writable RAM
   //
   //////////////////////////////////////////////////////////////////////

memptr:	 	dw 0			; // holds the pointer memory address
memptrlast:	dw 0			; // holds previous pointer address
pattern1:	dw 1			; // for walking ones
an_cnt:		dw 'h0100		; // anode counter
digit1:		dw 0			; // 7 segment digit 1,2	
digit2:		dw 0			; // 7 segment digit 3,4
digitdp:	dw 0			; // decimal point: 1=digit1, 2=dig2,3=dig3,4=dig4, 0=no decimal point
hex1val:   	dw 0   			; // hex value

hex2val:   	dw 0   			; // hex value
cvalue1: 	dw 0			; // character value
cvalue2: 	dw 0			; // character value
inpchar: 	dw 0			; // usb/uart input character.
inpaddr: 	dw 0			; // address
outdata: 	dw 0			; // data
uartstat:	dw 0			; // UART status
pattern2:	dw 0			; // for walking ones
			
bitop:	 	dw "w"   		;
delimeter:	dw 0 			;
temp0:   	dw 0			; // temporary scratch pad.
memode:		dw 0			; // word/byte = 0/1, default word
memacc:		dw 0			; // internal/external = 0/1, default internal
memop:	 	dw 0			; // IRW,XRD,XWR,XRW (0,1,2,3) 
regptr:  	dw BASEREGIO	; // Base register address pointer
iregptr:  	dw IBASEREGIO	; // Base register address pointer

   //////////////////////////////////////////////////////////////////////
   // Application Variables
   //////////////////////////////////////////////////////////////////////
varchk:
buff_addr:	dw	tempvar1		; // default this address
buff_len:	dw	15				; // default 16
buff_addrx:	dw	0				;
buff_value:	dw	0				;
buff_inc:	dw	0				;
r_rows:		dw	3      			; //  4 rows to display    registers
r_cols:		dw	15     			; // 15 columns to display registers
			dw	0      			; //
			
tmr1msec:	dw	0				; // timer 1mS
tmr1value:	dw	100				; // timer recurrent value
irqmask:	dw	1				; // default irq 1
ssm_pst: 	dw	kpst00			; // present state
ssm_lst: 	dw	kpst00			; // last state (return state)
pjump:		dw	myapp			; // table jump, not used right now
m_rows:		dw	7      			; // 8 rows to display    memory
m_cols:		dw	7     			; // 8 columns to display memory

tmr1year:	dw	YEAR			; // yyyy : timer 12 M = 1Y
tmr1month:	dw	MONTH			; // 00mm : timer 28/29/30/31 D = 1M
tmr1date:	dw	DATE			; // ddDD : timer 24 H = 1D, dd = 0 to 6 (MON to SUN)
tmr1hour:	dw	HOUR			; // 00hh : timer 60 m = 1H
tmr1min:	dw	MINUTE			; // 00mm : timer 60 s = 1m
tmr1sec:	dw	SECONDS			; // 00ss : timer 1S
leapyear:	dw	YEAR			; // 
myapp_val:	dw	1				;

dbugrows:	dw	15				; // default 16 rows to display 			
xadcreg:	ds	8				; // current slave regs values
dbugptr:	ds	8				; // pE = dbugptr,variables for debugging
dbugptr1:	ds	8				; // p? = dbugptr,variables for debugging
dbugptr2:	ds	8				; // p? = dbugptr,variables for debugging
dec2hextab:	dw	1,10,100,1000,0,0,0,0;
cmdbuff:	ds	64				; // buffer

   //////////////////////////////////////////////////////////////////////
   // Temporary space for results of any operations
   //////////////////////////////////////////////////////////////////////
tempvar1:	ds	32				; //
tempvar2:	ds	32				; //

   //////////////////////////////////////////////////////////////////////
   // Stack area
   //////////////////////////////////////////////////////////////////////
stack:		ds STACK_LENGTH    	; // stack area

// mark the end of writable RAM area
zend_ram:	dw	stack			;

// From here to boot loader free RAM space
			
   //////////////////////////////////////////////////////////////////////
   //////////////////////////////////////////////////////////////////////
   // BOOT LOADER
   // Loads a program file into memory.
   // The program file is ASCII hex with extension .mem
   // The first value is the length of the program.
   // If the first character received is the ESC key
   // the boot loader aborts the download
   //////////////////////////////////////////////////////////////////////
   //////////////////////////////////////////////////////////////////////
   // Write program memory.
@BOOT_ADDR
zboot_addr:
         cli                    ; // clear interrupts
         nop					; // allow to clear any pending interrupts
         uport f4				; // IRQ OFF
boot_p:  uport f7               ; // clear port.
         ldrv  r1,"<"           ; // Load program memory from
         outpp r1,pA,0          ; // external text file.
boot_ch: inpp  r1,pB	        ; // read status reg
         andv  r1,RXDVLD        ; // mask data valid bit
         bra   z,boot_ch        ; // read again
         inpp  r1,pA	        ; // read data reg
         andv  r1,'h0FF         ; // mask upper bits.
         cmprv r1,"#"           ; // check for header :  #4000
         bra   e,boot_fh        ; // found header
         cmprv r1,ESC           ; // abort ?
         bra   ne,boot_ch       ; // no, keep reading
         jmp   end_boot         ; // exit requiered by user
boot_fh: uflag f7               ; // clear user flag.
         uport t7               ; // indicates found header
         // Start with program memory, the first 16 bit word is the
         // program length.
boot_p0: ldpv  p1,0             ;
boot_p1: ldcv c2,3              ; 
         xor   r2,r2            ; // clear result
boot_p2: shl4  r2               ; 
boot_p3: inpp  r1,pB	        ; // read status reg
         andv  r1,RXDVLD        ; // mask data valid bit
         bra   z,boot_p3        ; // read again
         inpp  r1,pA	        ; // read data reg
         andv  r1,'h0FF         ; // mask upper bits.
         subv  r1,'h030         ; // remove any unwanted char
         bra   s,boot_p3        ; // reset counters.
         cmprv r1,9             ;
         bra   ls,boot_p4       ;
         andv  r1,'h00F         ; // must be a-f
         addv  r1,9             ;
boot_p4: or    r2,r1            ;
         dcjnz c2,boot_p2       ;
	 	 nop					;
         jmp   t7,boot_p4b      ; // test flag
         mvrr  r2,ra            ; // program length.
         str   ra,prog_lng      ; // store program length.
         uflag t7               ; // start of program
         bra   boot_p0          ; 
   
boot_p4b:mvpr  p1,r1            ; // start taking data
         cmprv r1,boot_p        ;
         bra   hs,boot_p5       ; 
         strpi r2,p1            ; // store in program memory
         bra   boot_p6          ; 
boot_p5: ldrv  r0,"*"           ;
         bra   boot_p7          ;
boot_p6: ldrv  r0,"."           ; 
boot_p7: outpp r0,pA,0          ;
         dec   ra               ;
         bra   nz,boot_p1       ;
end_boot:stp   p1,prog_cnt      ; 
         ldrv  r0,"#"           ; 
         outpp r0,pA,0          ;
end_loop:ldrv  r1,0				; // Clear register value
	 	 uport f7               ; // clear port.
         jmp   reset_v          ;
   
         // Read program memory
boot_r:  ldr   rc,prog_lng      ;// read program length
         ldpv  p1,0             ;
boot_r1: ldcv c2,3              ; 
         ldrpi r2,p1            ;
boot_r2: shl   r,r2             ; 
         shl   r,r2             ; 
         shl   r,r2             ; 
         shl   r,r2             ; 
         mvrr  r2,r1            ; 
         andv  r1,'h00F         ;
         addv  r1,'h030         ;
         cmprv r1,'h039         ;
         bra   ls,boot_r3       ;
         addv  r1,'h027         ; 
boot_r3: inpp  r3,pB	        ; // read status
         andv  r3,TXFULL       	; // transmit full ?
         bra   nz,boot_r3       ; // yes, wait
         outpp r1,pA,0          ;
         dcjnz c2,boot_r2       ;
	 	 nop					;
boot_r4: inpp  r3,pB	        ; // read status
         andv  r3,TXFULL       ; // transmit full ?
         bra   nz,boot_r4       ; // yes, wait
         ldrv  r3,'h00A         ;
         outpp r3,pA,0          ; 
         dec   rc               ; // decrement counter
         bra   nz,boot_r1       ; 
         jmp   end_loop         ;
   
prog_lng:dw    0                ; // program length
prog_cnt:dw    0                ; // program counter

   
/////////////////// End of File //////////////////////////
