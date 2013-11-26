
@Tenzin Ngodup ECE 371 Project1
@portland state university
@11/23/2012
@PROJECT 2


@Creating an INterrupt Procedure for Servicing a Button Push 
@Button service is on PIN GPIO<73> and LED is on pin GPIO<63> 

.text
.global _start
_start:
@initialize

.EQU GPLR0, 0x40E00000
.EQU GPLR2, 0x40E00008
.EQU GPDR2, 0x40E00014
.EQU GPSR2, 0x40E00020
.EQU GPCR2, 0x40E0002C
.EQU GPER2, 0x40E00038
.EQU GAFR2_L, 0x40E00064
	LDR R0,=GPLR0       @ set up for GPLR2 on R0
	LDR R1,=GPDR2       @set up for GPDR2 on R1
	LDR R2,=GPSR2       @set up for GPSR2 on R2
	LDR R3,=GPCR2      @set up for GPCR2 on R3
	LDR R5,=GAFR2_L    @set up for GAFR2_L on R5 

@clearing alternate function of GPIO<73> and GPIO<67> to 00	
	LDR R8,=0xFFF3FF3F 	@WORD TO CLEAR the pin 67 and 73 for alternate function 
	LDR R6,[R5]            @READ GAFR2_L TO GET CURRENT VALUE 
 	AND R8,R8,R6           @MODIFY SET BIT 7-6 TO PROGRAM GPIO 67 and BIT 19-18 to program GPIO 73
 	STR R8,[R5]             @WRITE BACK TO GAFR2_L
@Clearing GPIO<67> output 
        LDR R7,=0x8             @ to clear pin 67 for GPCR for output
	STR R7,[R3]             @ to clear GPCR2 at pin 67

@enabling to set GPIO<73> to input and GPIO<67> to output 	
	LDR R6,[R1]                @gets the GPDR2
	ORR R6,R6,R7               @Set 1 to bit 4 to program GPIO 67 for output 
	BIC R6,R6,#0x200 	   @Set 0 bit 10 to make GPIO 73 for input
	
	STR R6,[R1]             
@enabling the rising edge on GPIO<73> 	 
	LDR R4,=GPER2       
	LDR R1,[R4]        @Load value of R4 on R1   
	MOV R2,#0x200      @Value to mask on GPER2  
	ORR R1,R1,R2        @Masking GPER2 to set 1 on GPIO<73> 
	STR R1,[R4]       @store the value back to GRER2         


@initialize interrupt controller
@Default value of IRQfor ICLR BIT 10 is desired value, so send no word
@Default value of DIM bit in ICCR is desired value, no word send
	LDR R0, = 0x40D00004     @Loading the value of Mask(ICMR) register
	LDR R1,[R0]               @Reading the current value of Register
	Mov R2,#0x400         @Loading value to unmask bit 10 to GPIO 82:2
	ORR R1,R1,R2          @SET Bit 10 to unmask IM10 
	STR R1,[R0]          @Write word back to ICMR Register
@HOOK IRQ procedure address and installing our int_handler address
	MOV R1,#0x18         @LOAD IRQ interrupt vector address 0x18
	LDR R2,[R1]          @Read instr from interrupt vector table at 0x18
	LDR R3,=0xFFF       @contruct mask 
	AND R2,R2,R3        @Mask all but offset part of instruction 
	ADD R2,R2,#0x20     @built absoulute address of IRQ procedure in literal POOL

	LDR R3,[R2]                   @read BTLDR IRQ Address from literal pool 
	STR R3,BTLDR_IRQ_ADDRESS      @save BTLDR IRQ address to use in IRQ_DIRECTOR 
	LDR R0,=INT_DIRECTOR       @LOAD ABSOLUTE address of our interrupt director 
	STR R0,[R2]            @store this address in literal pool      
@Make sure interrupt on processor enabled by clearing bit 7 in cpsr
	MRS R3,CPSR              @COPY CPSR to R3 
	BIC R3,R3,#0x80          @CLEAR bit 7(IRQ Enable bit)
	MSR CPSR_c,R3             @write back to lowest 8 bits of CPSR 

LOOP:	NOP                  @wait for interrupt here ( simulation for the main program)
	B  LOOP

INT_DIRECTOR:                              @chain button interrupt procedure 
	STMFD SP!,{R0-R3,LR}           @Calling stack to use in the procedure 
	LDR R0,= 0x40D00000           @point to at IRQ pending register(ICIP) 
	LDR R1,[R0]                   @Read the ICIP register 
	TST R1,#0x400    @Check if GPIO 119:2 IRQ interrupt on is<10> asserted
	BEQ PASSON           @no,must be other interrupt, pass on to system interrupt 
	
PASSSON:
	LDR R0,=0x40E00050     @ checking status of GEDR2 for rising edge at pin 73
	LDR R1,[R0]             @ load the value on to R1 
	TST R1,#0x200          @if the bit 9 = 1(GPIO75) meaning the button is inserted 
	BNE BUTTON_SVC          @if true branch off to BUTTON_SVC else return to main loop 
	
	LDMFD SP!,{R0-R3,LR}       @popping all the stack, restore the registers
	LDR PC,BTLDR_IRQ_ADDRESS    @go to boot loader IRQ. 

BUTTON_SVC:
	MOV R1,#0x200         @value to clear bit 9 on GEDR2 
	STR R1,[R0]             @this will reset bit 9 on ICPR and ICIP 
	LDR R2,= 0x40E00020   @LOAD P0INTER TO GPSR2
	LDR R3,= 0x40E0002C  @LOAD PoINTER TO GPCR2
  	LDR R7,= 0x40E00008  @LOAD PINTER TO GPLR2
	LDR R4,[R7]          @ load the value to R4             
	TST R4,#0x8          @check the status of GPLR2 
	BNE OFF              @IF it is ON go to OFF 
	BEQ ON              @if it is OFF go to ON 
	
ON:	
	LDR R4, =0x00000008      @Load the value to set the bit 3 to 1 or GPIO<67> to 0 
	STR R4,[R2]              @Store the value back to GPSR2 
	LDMFD SP!,{R0-R3,LR}    @ recall all the registers 
	SUBS PC,LR,#4              @return back to the wait loop 

OFF:	
	LDR R4, =0x00000008      @Load the value to set the bit 3 to 1 or GPIO<67> to 0 
	STR R4,[R3]              @Store the value back to GPCR2 
	LDMFD SP!,{R0-R3,LR}      @ recall all the registers 
	SUBS PC,LR,#4              @ return back to the wait loop 


BTLDR_IRQ_ADDRESS: .word 0x0          @space to load the bootloader IRQ 



.data

.end


.end
