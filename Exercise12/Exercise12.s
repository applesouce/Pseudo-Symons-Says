			TTL Exercise 10 
;****************************************************************
;Descriptive comment header goes here.
;(What does the program do?)
;Name:  Andrew Saridakis
;Date:  
;Class:  CMPE-250
;Section: L3, Wednseday, 5:00-7:00
;---------------------------------------------------------------
;Keil Template for KL05
;R. W. Melton
;September 13, 2020
;****************************************************************
;Assembler directives
            THUMB
            OPT    64  ;Turn on listing macro expansions
;****************************************************************
;Include files
            GET  MKL05Z4.s     ;Included by start.s
            OPT  1   ;Turn on listing
;****************************************************************
;****************************************************************
;EQUates
;---------------------------------------------------------------
;NVIC_ICER
;31-00:CLRENA=masks for HW IRQ sources;
;             read:   0 = unmasked;   1 = masked
;             write:  0 = no effect;  1 = mask
;22:PIT IRQ mask
;12:UART0 IRQ mask
NVIC_ICER_PIT_MASK    EQU  PIT_IRQ_MASK
NVIC_ICER_UART0_MASK  EQU  UART0_IRQ_MASK
;---------------------------------------------------------------
;NVIC_ICPR
;31-00:CLRPEND=pending status for HW IRQ sources;
;             read:   0 = not pending;  1 = pending
;             write:  0 = no effect;
;                     1 = change status to not pending
;22:PIT IRQ pending status
;12:UART0 IRQ pending status
NVIC_ICPR_PIT_MASK    EQU  PIT_IRQ_MASK
NVIC_ICPR_UART0_MASK  EQU  UART0_IRQ_MASK
;---------------------------------------------------------------
;NVIC_IPR0-NVIC_IPR7
;2-bit priority:  00 = highest; 11 = lowest
;--PIT--------------------
PIT_IRQ_PRIORITY    EQU  0
NVIC_IPR_PIT_MASK   EQU  (3 << PIT_PRI_POS)
NVIC_IPR_PIT_PRI_0  EQU  (PIT_IRQ_PRIORITY << PIT_PRI_POS)
;--UART0--------------------
UART0_IRQ_PRIORITY    EQU  3
NVIC_IPR_UART0_MASK   EQU (3 << UART0_PRI_POS)
NVIC_IPR_UART0_PRI_3  EQU (UART0_IRQ_PRIORITY << UART0_PRI_POS)
;---------------------------------------------------------------
;NVIC_ISER
;31-00:SETENA=masks for HW IRQ sources;
;             read:   0 = masked;     1 = unmasked
;             write:  0 = no effect;  1 = unmask
;22:PIT IRQ mask
;12:UART0 IRQ mask
NVIC_ISER_PIT_MASK    EQU  PIT_IRQ_MASK
NVIC_ISER_UART0_MASK  EQU  UART0_IRQ_MASK
;---------------------------------------------------------------
;PIT_LDVALn:  PIT load value register n
;31-00:TSV=timer start value (period in clock cycles - 1)
;Clock ticks for 0.01 s at ~24 MHz count rate
;0.01 s * ~24,000,000 Hz = ~240,000
;TSV = ~240,000 - 1
;Clock ticks for 0.01 s at 23,986,176 Hz count rate
;0.01 s * 23,986,176 Hz = 239,862
;TSV = 239,862 - 1
PIT_LDVAL_10ms  EQU  239861
;---------------------------------------------------------------
;PIT_MCR:  PIT module control register
;1-->    0:FRZ=freeze (continue'/stop in debug mode)
;0-->    1:MDIS=module disable (PIT section)
;               RTI timer not affected
;               must be enabled before any other PIT setup
PIT_MCR_EN_FRZ  EQU  PIT_MCR_FRZ_MASK
;---------------------------------------------------------------
;PIT_TCTRL:  timer control register
;0-->   2:CHN=chain mode (enable)
;1-->   1:TIE=timer interrupt enable
;1-->   0:TEN=timer enable
PIT_TCTRL_CH_IE  EQU  (PIT_TCTRL_TEN_MASK :OR: PIT_TCTRL_TIE_MASK)
;---------------------------------------------------------------
;PORTx_PCRn (Port x pin control register n [for pin n])
;___->10-08:Pin mux control (select 0 to 8)
;Use provided PORT_PCR_MUX_SELECT_2_MASK
;---------------------------------------------------------------
;Port B
PORT_PCR_SET_PTB2_UART0_RX  EQU  (PORT_PCR_ISF_MASK :OR: \
                                  PORT_PCR_MUX_SELECT_2_MASK)
PORT_PCR_SET_PTB1_UART0_TX  EQU  (PORT_PCR_ISF_MASK :OR: \
                                  PORT_PCR_MUX_SELECT_2_MASK)
;---------------------------------------------------------------
;SIM_SCGC4
;1->10:UART0 clock gate control (enabled)
;Use provided SIM_SCGC4_UART0_MASK
;---------------------------------------------------------------
;SIM_SCGC5
;1->09:Port A clock gate control (enabled)
;Use provided SIM_SCGC5_PORTA_MASK
;---------------------------------------------------------------
;SIM_SCGC6
;1->23:PIT clock gate control (enabled)
;Use provided SIM_SCGC6_PIT_MASK
;---------------------------------------------------------------
;SIM_SOPT2
;01=27-26:UART0SRC=UART0 clock source select (MCGFLLCLK)
;---------------------------------------------------------------
SIM_SOPT2_UART0SRC_MCGFLLCLK  EQU  \
                                 (1 << SIM_SOPT2_UART0SRC_SHIFT)
;---------------------------------------------------------------
;SIM_SOPT5
; 0->   16:UART0 open drain enable (disabled)
; 0->   02:UART0 receive data select (UART0_RX)
;00->01-00:UART0 transmit data select source (UART0_TX)
SIM_SOPT5_UART0_EXTERN_MASK_CLEAR  EQU  \
                               (SIM_SOPT5_UART0ODE_MASK :OR: \
                                SIM_SOPT5_UART0RXSRC_MASK :OR: \
                                SIM_SOPT5_UART0TXSRC_MASK)
;---------------------------------------------------------------
;UART0_BDH
;    0->  7:LIN break detect IE (disabled)
;    0->  6:RxD input active edge IE (disabled)
;    0->  5:Stop bit number select (1)
;00001->4-0:SBR[12:0] (UART0CLK / [9600 * (OSR + 1)]) 
;UART0CLK is MCGPLLCLK/2
;MCGPLLCLK is 96 MHz
;MCGPLLCLK/2 is 48 MHz
;SBR = 48 MHz / (9600 * 16) = 312.5 --> 312 = 0x138
UART0_BDH_9600  EQU  0x01
;---------------------------------------------------------------
;UART0_BDL
;26->7-0:SBR[7:0] (UART0CLK / [9600 * (OSR + 1)])
;UART0CLK is MCGPLLCLK/2
;MCGPLLCLK is 96 MHz
;MCGPLLCLK/2 is 48 MHz
;SBR = 48 MHz / (9600 * 16) = 312.5 --> 312 = 0x138
UART0_BDL_9600  EQU  0x38
;---------------------------------------------------------------
;UART0_C1
;0-->7:LOOPS=loops select (normal)
;0-->6:DOZEEN=doze enable (disabled)
;0-->5:RSRC=receiver source select (internal--no effect LOOPS=0)
;0-->4:M=9- or 8-bit mode select 
;        (1 start, 8 data [lsb first], 1 stop)
;0-->3:WAKE=receiver wakeup method select (idle)
;0-->2:IDLE=idle line type select (idle begins after start bit)
;0-->1:PE=parity enable (disabled)
;0-->0:PT=parity type (even parity--no effect PE=0)
UART0_C1_8N1  EQU  0x00
;---------------------------------------------------------------
;UART0_C2
;0-->7:TIE=transmit IE for TDRE (disabled)
;0-->6:TCIE=transmission complete IE for TC (disabled)
;0-->5:RIE=receiver IE for RDRF (disabled)
;0-->4:ILIE=idle line IE for IDLE (disabled)
;1-->3:TE=transmitter enable (enabled)
;1-->2:RE=receiver enable (enabled)
;0-->1:RWU=receiver wakeup control (normal)
;0-->0:SBK=send break (disabled, normal)
UART0_C2_T_R    EQU  (UART0_C2_TE_MASK :OR: UART0_C2_RE_MASK)
UART0_C2_T_RI   EQU  (UART0_C2_RIE_MASK :OR: UART0_C2_T_R)
UART0_C2_TI_RI  EQU  (UART0_C2_TIE_MASK :OR: UART0_C2_T_RI)
;---------------------------------------------------------------
;UART0_C3
;0-->7:R8T9=9th data bit for receiver (not used M=0)
;           10th data bit for transmitter (not used M10=0)
;0-->6:R9T8=9th data bit for transmitter (not used M=0)
;           10th data bit for receiver (not used M10=0)
;0-->5:TXDIR=UART_TX pin direction in single-wire mode
;            (no effect LOOPS=0)
;0-->4:TXINV=transmit data inversion (not inverted)
;0-->3:ORIE=overrun IE for OR (disabled)
;0-->2:NEIE=noise error IE for NF (disabled)
;0-->1:FEIE=framing error IE for FE (disabled)
;0-->0:PEIE=parity error IE for PF (disabled)
UART0_C3_NO_TXINV  EQU  0x00
;---------------------------------------------------------------
;UART0_C4
;    0-->  7:MAEN1=match address mode enable 1 (disabled)
;    0-->  6:MAEN2=match address mode enable 2 (disabled)
;    0-->  5:M10=10-bit mode select (not selected)
;01111-->4-0:OSR=over sampling ratio (16)
;               = 1 + OSR for 3 <= OSR <= 31
;               = 16 for 0 <= OSR <= 2 (invalid values)
UART0_C4_OSR_16           EQU  0x0F
UART0_C4_NO_MATCH_OSR_16  EQU  UART0_C4_OSR_16
;---------------------------------------------------------------
;UART0_C5
;  0-->  7:TDMAE=transmitter DMA enable (disabled)
;  0-->  6:Reserved; read-only; always 0
;  0-->  5:RDMAE=receiver full DMA enable (disabled)
;000-->4-2:Reserved; read-only; always 0
;  0-->  1:BOTHEDGE=both edge sampling (rising edge only)
;  0-->  0:RESYNCDIS=resynchronization disable (enabled)
UART0_C5_NO_DMA_SSR_SYNC  EQU  0x00
;---------------------------------------------------------------
;UART0_S1
;0-->7:TDRE=transmit data register empty flag; read-only
;0-->6:TC=transmission complete flag; read-only
;0-->5:RDRF=receive data register full flag; read-only
;1-->4:IDLE=idle line flag; write 1 to clear (clear)
;1-->3:OR=receiver overrun flag; write 1 to clear (clear)
;1-->2:NF=noise flag; write 1 to clear (clear)
;1-->1:FE=framing error flag; write 1 to clear (clear)
;1-->0:PF=parity error flag; write 1 to clear (clear)
UART0_S1_CLEAR_FLAGS  EQU  (UART0_S1_IDLE_MASK :OR: \
                            UART0_S1_OR_MASK :OR: \
                            UART0_S1_NF_MASK :OR: \
                            UART0_S1_FE_MASK :OR: \
                            UART0_S1_PF_MASK)
;---------------------------------------------------------------
;UART0_S2
;1-->7:LBKDIF=LIN break detect interrupt flag (clear)
;             write 1 to clear
;1-->6:RXEDGIF=RxD pin active edge interrupt flag (clear)
;              write 1 to clear
;0-->5:(reserved); read-only; always 0
;0-->4:RXINV=receive data inversion (disabled)
;0-->3:RWUID=receive wake-up idle detect
;0-->2:BRK13=break character generation length (10)
;0-->1:LBKDE=LIN break detect enable (disabled)
;0-->0:RAF=receiver active flag; read-only
UART0_S2_NO_RXINV_BRK10_NO_LBKDETECT_CLEAR_FLAGS  EQU  \
        (UART0_S2_LBKDIF_MASK :OR: UART0_S2_RXEDGIF_MASK)
;---------------------------------------------------------------
; Useful Equates for LED
POS_RED EQU 8
POS_GREEN EQU 9
POS_BLUE EQU 10
PORTB_LED_RED_MASK EQU (1 << POS_RED)
PORTB_LED_GREEN_MASK EQU (1 << POS_GREEN)
PORTB_LED_BLUE_MASK EQU (1 << POS_BLUE)
PORTB_LEDS_MASK EQU (PORTB_LED_RED_MASK :OR: \
PORTB_LED_GREEN_MASK :OR: \
PORTB_LED_BLUE_MASK)

; Useful Equates for Port Connection to LED
;Port B Pin 8: Red LED
PORT_PCR_SET_PTB8_GPIO EQU (PORT_PCR_ISF_MASK :OR: \
PORT_PCR_MUX_SELECT_1_MASK)
;Port B Pin 9: Green LED
PORT_PCR_SET_PTB9_GPIO EQU (PORT_PCR_ISF_MASK :OR: \
PORT_PCR_MUX_SELECT_1_MASK)
;Port B Pin 10: Blue LED
PORT_PCR_SET_PTB10_GPIO EQU (PORT_PCR_ISF_MASK :OR: \
PORT_PCR_MUX_SELECT_1_MASK)

; Queue management record field offsets
IN_PTR      EQU   0
OUT_PTR     EQU   4
BUF_STRT    EQU   8
BUF_PAST    EQU   12
BUF_SIZE    EQU   16
NUM_ENQD    EQU   17
; Queue structure sizes
Q_BUF_SZ    EQU   4      ; Queue contents
Q_REC_SZ    EQU   18     ; Queue management record

PASSWORD_LENGTH  EQU  10
MAX_STRING  EQU   79     ; Used for past Methods 
	
; Game Stuff
MSecondsOfTime EQU 1100  ; Used as the start time: THEN decremented by 1 seconds
;Program
;Linker requires Reset_Handler
            AREA    MyCode,CODE,READONLY
            ENTRY
            EXPORT  Reset_Handler
            IMPORT  Startup
Reset_Handler  PROC  {}
main
;---------------------------------------------------------------
;Mask interrupts
            CPSID   I
;KL05 system startup with 48-MHz system clock
            BL      Startup
;---------------------------------------------------------------
;>>>>> begin main program code <<<<<
RunItAgain
             MOVS R7, #0    ; Used later to calculate the score
            MOVS R1,#0
			; Intialize the RunStopWatch bit to zero
			LDR R0,=stop_Watch
			STRB R1,[R0,#0]
			; Intialize the Count to Zero
			LDR R0, =count
			STR R1,[R0,#0]
			
			BL Init_PIT_IRQ 
			CPSIE	I
            BL Init_UART0_IRQ
			BL LEDConfiguration
			LDR  R0, =Instructions
			MOVS R1, #150
			BL PutStringSB
			BL StartTimer       
			BL GetChar          ; Gets the character from the user
			BL StopTimer        ; Used to make the Pseudo Random Number
			BL RandomSeed       ; R2 = seed(x) seed1, or seed2 or ...
			BL PutChar          ; Prints the character from the user
			MOVS R0, #0x0D      ; (CR) moves cursor to new line
			BL PutChar          
			MOVS R0, #0x0A      ; (LF)line feed to terminal screen
			BL PutChar
			; TURNS OFF ALL THE INTIAL COLORS
			BL TurnOffRed
			BL TurnOffGreen
			BL TurnOffBlue
			
;KEEPCHECKING	
;			; TESTING THE GET CHAR
;			MOVS R3, #0
;			LDR  R5, =MSecondsOfTime
;			LDR R5,[R5,#0]
;			
;			BL StartTimer
;			BL GetCharTime
;			BL StopTimer
;			CMP R6, #0
;			BGT  skipppppp
;			MOVS R0, #'@'
;			BL PutChar
;			LDR R0, =count
;			LDR R0,[R0,#0]
;			BL PutNumU
;skipppppp
;            B KEEPCHECKING

			; For the loop this body two things are happening 
			; * The Timer
			; * And the Enqueue 
			; The timer is used to time out how long it took the user to enter a value
			; And the Enqueue function is to Enqueue a charcter that has been typed by the use
			;   --- Side note: The Character should later
            ;be dequeued using the modified getChar from lab 10
		
			MOVS  R3, #0
			LDR   R5, =MSecondsOfTime
KeepAsking
			LDRB R4,[R2, R3]     ; Loads the Next Prompt
			ADDS R3, #1
			; LOADS THE COLOR
			CMP R4, #'r'      ; Check of the user want to dequeue then print d and the character Dequeued
			BEQ RedColor
			CMP R4, #'g'
			BEQ GreenColor    
			CMP R4, #'b'      
			BEQ BlueColor
            CMP R4, #'w'      ; Print the the queue?s current InPointer, OutPointer, and NumberEnqueued
			BEQ WhiteColor   		
			B WrongPrompt
RedColor
            BL ToggleRed
			B prompt
GreenColor
            BL ToggleGreen
			B prompt
BlueColor
            BL ToggleBlue
			B prompt
WhiteColor
			BL ToggleWhite
			
prompt       
            MOVS R0, #0x0D      ; (CR) moves cursor to new line
			BL PutChar          
			MOVS R0, #0x0A      ; (LF)line feed to terminal screen
			BL PutChar
			MOVS R0, #">"   ; Intial Prompt
			BL PutChar
			BL StartTimer
		    BL GetCharTime
			MOVS R1, R0        ; Save
			BL StopTimer
			CMP R6, #1
			BEQ FAILEDTIMER
			; Takes the input and converts to lower case
			; checks the input with R4
			; Prints approperiate message
			
			MOVS R0,R1        ; Save a copy
			CMP  R0, #'a'     ; Checks it's lowercase a
			BHS  UppertoLwr2  ; Determines whether to change or not
            SUBS R0, R0, #'A' ; Always works to change any UpperCase to Lower case
            ADDS R0,R0,  #'a'
UppertoLwr2 CMP R0, #'r'      ; Check of the user want to dequeue then print d and the character Dequeued
			BEQ RedPrompt
			CMP R0, #'g'
			BEQ GreenPrompt    
			CMP R0, #'b'      
			BEQ BluePrompt
            CMP R0, #'w'      ; Print the the queue?s current InPointer, OutPointer, and NumberEnqueued
			BEQ WhitePrompt   		
			B WrongPrompt
KeepAsking1                      ; Used to loop back to the begining 
           B KeepAsking
RedPrompt                        ; Print the Red Right Prompt
            MOVS R0, R1
			CMP  R4, R0
			BNE WrongPrompt
			BL PutChar
			MOVS R1, #100
			LDR R0, =RightRed
			BL PutStringSB
			BL ToggleRed
			B score
GreenPrompt
            MOVS R0, R1
			CMP  R4, R0
			BNE WrongPrompt
			BL PutChar
			MOVS R1, #100
			LDR R0, =RightGreen
			BL PutStringSB
			BL ToggleGreen
			B score
BluePrompt
            MOVS R0, R1
			CMP  R4, R0
			BNE WrongPrompt
			BL PutChar
			MOVS R1, #100
			LDR R0, =RightBlue
			BL PutStringSB
			BL ToggleBlue
			B score
WhitePrompt
            MOVS R0, R1
			CMP  R4, R0
			BNE WrongPrompt
			BL PutChar
			MOVS R1, #MAX_STRING
			LDR R0, =RightWhite
			BL PutStringSB
			BL ToggleWhite
			B score
WrongPrompt
            MOVS R0, R1               ; Prints the wrong prompt
			BL PutChar
			MOVS R1, #MAX_STRING
			LDR R0, =Wrong
			BL PutStringSB
			BL TurnOffRed
			BL TurnOffGreen
			BL TurnOffBlue
			MOVS R6, #1
			B score
FAILEDTIMER 
            ; Print failed timer 
            CMP R4, #'r'      ; Check of the user want to dequeue then print d and the character Dequeued
			BEQ RedColorWrong
			CMP R4, #'g'
			BEQ GreenColorWrong 
			CMP R4, #'b'      
			BEQ BlueColorWrong
            CMP R4, #'w'      ; Print the the queue?s current InPointer, OutPointer, and NumberEnqueued
			BEQ WhiteColorWrong   		
			B WrongPrompt
RedColorWrong
            BL ToggleRed
			MOVS R1, #MAX_STRING
			LDR R0, =WrongRed
			BL PutStringSB
			B score
GreenColorWrong
            BL ToggleGreen
			MOVS R1, #MAX_STRING
			LDR R0, =WrongGreen
			BL PutStringSB
			B score
BlueColorWrong
            BL ToggleBlue
			MOVS R1, #MAX_STRING
			LDR R0, =WrongBlue
			BL PutStringSB
			B score
WhiteColorWrong
			BL ToggleWhite
            MOVS R1, #MAX_STRING
			LDR R0, =WrongWhite
			BL PutStringSB
			
score
            CMP R6, #1
			BEQ NoPoints
            ADDS R7, #10 ; Adds a hundred if it's correct
			; USUALY you dont want to change R6 but now you can do it
			
NoPoints
			SUBS R5, #100       ; Subtract one second
			CMP R3, #9
            BLE KeepAsking1
			
			; Print the Score
			MOVS R0, #0x0D      ; (CR) moves cursor to new line
			BL PutChar          
			MOVS R0, #0x0A      ; (LF)line feed to terminal screen
			BL PutChar
			MOVS R1, #MAX_STRING
			LDR  R0, =scores
		    BL PutStringSB
            MOVS R0,R7
			
			BL PutNumU
			
			MOVS R0, #0x0D      ; (CR) moves cursor to new line
			BL PutChar          
			MOVS R0, #0x0A      ; (LF)line feed to terminal screen
			BL PutChar 
			MOVS R0, #0x0D      ; (CR) moves cursor to new line
			BL PutChar          
			MOVS R0, #0x0A      ; (LF)line feed to terminal screen
			BL PutChar 
			MOVS R0, #0x0D      ; (CR) moves cursor to new line
			BL PutChar          
			MOVS R0, #0x0A      ; (LF)line feed to terminal screen
			BL PutChar 
			
            B RunItAgain
;>>>>>   end main program code <<<<<
            B       .
            ENDP
		    ALIGN
			LTORG	
;>>>>> begin subroutine code <<<<<

StartTimer   PROC {R0-R14}
;**********************************************************
; StartTimer
;**********************************************************	
	        PUSH {R0-R1}
            MOVS R1,#0        ;Setting Count =0
            LDR  R0,=count
			STR  R1,[R0,#0]
            MOVS R1,#1        ;Setting stop_Watch = 1
			LDR  R0,=stop_Watch
			STRB R1,[R0,#0]
			POP {R0-R1}
			BX LR
	        ENDP

StopTimer    PROC {R0-R14}
;**********************************************************
; Stop The Timer
; All other registers remain unchanged on return
;**********************************************************	
	        PUSH {R0-R1}
            MOVS R1,#0        ;Setting stop_Watch = 0
			LDR  R0,=stop_Watch
			STRB R1,[R0,#0]
			POP {R0-R1}
			BX LR
            ENDP 

RandomSeed PROC {R0-R14}
;**********************************************************
; Using the time it took the User to input time
; Input: count variable
; Output: R2 - 1, 2 or 3
; Modify: APSR
; All other registers remain unchanged on return
;**********************************************************		
    PUSH{R0-R1}
	LDR R0, =count
	LDR R0, [R0,#0]          ;Loads the count of the 
	; IF the time is 0-1 seconds the number is 1 (0< t <= 1)
	CMP R0, #100
	BGT SkipFirstIf
	LDR R2, =seed1
	B endRandomSeed
SkipFirstIf
    ; IF the time is 1-3 seconds the number is 2 (1< t <= 2)
    CMP R0, #200
	BGT SkipSecondIf
	LDR R2, =seed2 
    B endRandomSeed	
SkipSecondIf	
	;; IF the time is 3-5 seconds the number is 3 (3 < t )
	LDR R2, =seed3 
endRandomSeed	; END
	POP{R0-R1}
    BX LR
    ENDP
		
LEDConfiguration PROC {R0-R14}
;**********************************************************
; Using the time it took the User to input time
; Input: R2
; Output: R0 - 1, 2 or 3
; Modify: APSR
; All other registers remain unchanged on return
;**********************************************************	
   PUSH{R0-R7}
   ; Configuration of Pin Connection to LEDs
   LDR R0,=PORTB_BASE
   ;Select PORT B Pin 8 for GPIO to red LED
   LDR R1,=PORT_PCR_SET_PTB8_GPIO
   STR R1,[R0,#PORTB_PCR8_OFFSET]
   ;Select PORT B Pin 9 for GPIO to green LED
   LDR R1,=PORT_PCR_SET_PTB9_GPIO
   STR R1,[R0,#PORTB_PCR9_OFFSET]
   ;Select PORT B Pin 10 for GPIO to blue LED
   LDR R1,=PORT_PCR_SET_PTB10_GPIO
   STR R1,[R0,#PORTB_PCR10_OFFSET]
   ;Port Data Direction Register
   LDR R0,=FGPIOB_BASE
   LDR R1,=PORTB_LEDS_MASK
   STR R1,[R0,#GPIO_PDDR_OFFSET]
   POP {R0-R7}
   BX LR  
   ENDP
	    
ToggleWhite PROC {R0-R14}
;**********************************************************
; Toggle White LED
;**********************************************************	
   PUSH{R0-R7, LR}	
   BL ToggleRed
   BL ToggleGreen
   BL ToggleBlue
   POP {R0-R7, PC}
   BX LR
   ENDP
ToggleRed PROC {R0-R14}
;**********************************************************
; Toggle Red LED
;**********************************************************	
   PUSH{R0-R7}
   LDR R0,=FGPIOB_BASE
   ;Turn on red LED
   LDR R1,=PORTB_LED_RED_MASK
   STR R1,[R0,#GPIO_PTOR_OFFSET]
   POP {R0-R7}
   BX LR  
   ENDP
ToggleGreen PROC {R0-R14}
;**********************************************************
; Toggle Green LED
;**********************************************************	
   PUSH{R0-R7}
   LDR R0,=FGPIOB_BASE
   ;Turn on red LED
   LDR R1,=PORTB_LED_GREEN_MASK
   STR R1,[R0,#GPIO_PTOR_OFFSET]
   POP {R0-R7}
   BX LR  
   ENDP
ToggleBlue  PROC {R0-R14}
;**********************************************************
; Toggle Blue LED
;**********************************************************	
   PUSH{R0-R7}
   LDR R0,=FGPIOB_BASE
   ;Toggle red LED
   LDR R1,=PORTB_LED_BLUE_MASK
   STR R1,[R0,#GPIO_PTOR_OFFSET]
   POP {R0-R7}
   BX LR  
   ENDP
	   
TurnOnRed PROC {R0-R14}
;**********************************************************
; TURNS ON RED LED
;**********************************************************	
   PUSH{R0-R7}
   LDR R0,=FGPIOB_BASE
   ;Turn on red LED
   LDR R1,=PORTB_LED_RED_MASK
   STR R1,[R0,#GPIO_PCOR_OFFSET]
   POP {R0-R7}
   BX LR  
   ENDP
TurnOffRed PROC {R0-R14}
;**********************************************************
; TURN OFF RED LED
;**********************************************************	
  PUSH{R0-R7}
  LDR R0,=FGPIOB_BASE
  ;Turn off red LED
  LDR R1,=PORTB_LED_RED_MASK
  STR R1,[R0,#GPIO_PSOR_OFFSET]
  POP {R0-R7}
   BX LR  
   ENDP
TurnOnGreen PROC {R0-R14}
;**********************************************************
; TURN OFF RED LED
;**********************************************************	
   PUSH{R0-R7}
   LDR R0,=FGPIOB_BASE
   ;Turn on green LED
   LDR R1,=PORTB_LED_GREEN_MASK
   STR R1,[R0,#GPIO_PCOR_OFFSET]
   POP {R0-R7}
   BX LR  
   ENDP
	   
TurnOffGreen PROC {R0-R14}
;**********************************************************
; TURN OFF RED LED
;**********************************************************	
  PUSH{R0-R7}
  LDR R0,=FGPIOB_BASE
  ;Turn off green LED
  LDR R1,=PORTB_LED_GREEN_MASK
  STR R1,[R0,#GPIO_PSOR_OFFSET]
  POP {R0-R7}
   BX LR  
   ENDP
	   
TurnOnBlue PROC {R0-R14}
;**********************************************************
; TURN OFF RED LED
;**********************************************************	
  PUSH{R0-R7}
  LDR R0,=FGPIOB_BASE
  ;Turn on blue LED
  LDR R1,=PORTB_LED_BLUE_MASK
  STR R1,[R0,#GPIO_PCOR_OFFSET]
  POP {R0-R7}
  BX LR  
  ENDP
TurnOffBlue PROC {R0-R14}
;**********************************************************
; TURN OFF RED LED
;**********************************************************	
  PUSH{R0-R7}
  LDR R0,=FGPIOB_BASE
  ;Turn off blue LED
  LDR R1,=PORTB_LED_BLUE_MASK
  STR R1,[R0,#GPIO_PSOR_OFFSET]
  POP {R0-R7}
   BX LR  
   ENDP

PIT_ISR     PROC {R0-R14}
;**********************************************************
; Pit isr
; Input: N/A 
; Output: N/A
; Modify: APSR
; All other registers remain unchanged on return
;**********************************************************	
             CPSID   I
			 LDR R0 , =stop_Watch      ; loads the address of the stop watch
			 LDRB R0,[R0,#0]           ; Loads the bit value of stop watch
			 CMP R0,#0                 ; 1 being enabled, 0 being disabled
			 BEQ StopWatchDisabled
			 LDR R0, =count
			 LDR R1,[R0,#0]
			 ADDS R1,#1
			 STR R1,[R0,#0]
StopWatchDisabled			 
             LDR R0, =PIT_TFLG0
			 LDR R1,=PIT_TFLG_TIF_MASK
			 STR R1,[R0,#0]
			 CPSIE   I
			 BX LR
             ENDP


Init_PIT_IRQ    PROC {R0-R14}
;**********************************************************
; Intualize the KL05 PIT Module Clock
; Input: N/A 
; Output: N/A
; Modify: APSR
; All other registers remain unchanged on return
;**********************************************************	
            PUSH{R0-R3}
			;Set SIM_SCGC6 for PIT Clock Enabled
            LDR R0,=SIM_SCGC6
            LDR R1,=SIM_SCGC6_PIT_MASK
            LDR R2,[R0,#0] ;current SIM_SCGC6 value
            ORRS R2,R2,R1  ;only PIT bit set
            STR R2,[R0,#0] ;update SIM_SCGC6
			; Enable Pit Module Control Register  (Manipulates the MDIS)
			
            ;Disable PIT timer 0
            LDR R0, =PIT_CH0_BASE
            LDR R1, =PIT_TCTRL_TEN_MASK
            LDR R2, [R0,#PIT_TCTRL_OFFSET]
            BICS R2,R2,R1
            STR R2,[R0,#PIT_TCTRL_OFFSET]
			
            ;KL05 NVIC Configuration
			; Disable PIT timer 0 
            LDR R0,=PIT_IPR
            LDR R1,=NVIC_IPR_PIT_MASK
            ;LDR R2,=NVIC_IPR_PIT_PR0_0
            LDR R3,[R0,#0]
            BICS R3,R3,R1
            ;ORRS R3,R3,R2
            STR R3,[R0,#0]
            ;Clear any pending PIT interrupts 
            LDR R0,=NVIC_ICPR
            LDR R1,=NVIC_ICPR_PIT_MASK
            STR R1,[R0,#0]
            ;Unmask PIT interrupts
            LDR R0,=NVIC_ISER
            LDR R1,=NVIC_ISER_PIT_MASK
            STR R1,[R0,#0]
            
			; Manpulating the Pit Timer
            LDR R0,=PIT_BASE
            LDR R1,=PIT_MCR_EN_FRZ
            STR R1,[R0,#PIT_MCR_OFFSET]
            ;Set PIT timer 0 peR0od for 0.01 s
            LDR R0,=PIT_CH0_BASE
            LDR R1,=PIT_LDVAL_10ms
            STR R1,[R0,#PIT_LDVAL_OFFSET]
            ;Enable PIT timer 0 interrupt
            LDR R1,=PIT_TCTRL_CH_IE
            STR R1,[R0,#PIT_TCTRL_OFFSET]
			POP{R0-R3}
			BX LR
			ENDP
PutNumU       PROC     {R0-R14}
;*****************************************************************
; Prints out the unsigned word value of R0
; And read it out to the terminal 
; Input: R0 - the word value
; Ouput: 
; Modify: APSR
;*****************************************************************
            PUSH{R0-R3, LR}  
            LDR R2,=0x1FFFFC00 ; Bass address to store value
			MOVS R3, #0        ; Index counter
LoopTillZe  
            MOVS R1,R0         ; Swaps the Quotent and Remander to continue division
			MOVS R0,#10
            BL DIVU
			STRB R1, [R2,R3]   ; Used to store the remainders
			ADDS R3, #4        ; Increments the counter
            CMP R0, #0
			BNE LoopTillZe
			                   ;Used to print the value of the 
LoopPrint	SUBS R3, #4        
			LDRB R0,[R2,R3]
			ADDS R0, #0x000000030       ; to convert into ascii hex repesentation of that number
			BL PutChar
			CMP R3, #0
			BNE LoopPrint
            POP{R0-R3, PC}
            ENDP	
DIVU 		PROC	{R2-R14}
;*****************************************************************
; Use unsigned division of R1 / R0
; Return R0 as the quotient and R1 as remainder
; Input: R0, R1
; Ouput: R0, R1
;*****************************************************************
	push	{R2-R4}
	MOVS 	R2,#0              ;R2 IS TEMP QUOTIENT
;***********************Check if DIVIDEND or Divisor = 0*********************
	CMP     R0,#0                   ; Checks if Divisor equals zero
	BEQ     hop
	CMP		R1,#0					; Checks for if Dividend =0
	BEQ 	endLoop					; IF Dividend does equal zero then we move to
	B 		startLoop	
hop
	MRS 	R3, APSR			;SETING THE C FLAG
	MOVS 	R4, #0x20			          
	LSLS 	R4,R4, #24
	ORRS 	R3,R3,R4
	MSR  	APSR, R3			;SETTING THE C FLAG
	B 		endLoop2
;***********************Main Division Loop************************
startLoop
	CMP 	R1, R0      ;Checks for Dividend >= Divisor
	BLO 	endLoop
	SUBS 	R1,R1,R0   ; Dividend = Dividend - Divisor
	ADDS  	R2,R2,#1  ; Quotient = Quotient + 1
	B 		startLoop
endLoop
							;NO need to do Remainder = Dividend since R1 = Dividend and remainder
	MOVS 	R0, R2          ;SETS THE TEMP QUOTIENT to PERM QUOTIENT
	MRS  	R3, APSR   		;CLEAR THE C FLAG
	MOVS 	R4,#0x20
	LSLS 	R4,R4,#24
	BICS 	R3,R3,R4
	MSR  	APSR, R3
endLoop2					;This is only used if the Divisor = 0
	pop		{R2-R4}
	BX 		LR
	ENDP			
PutNumHex     PROC {R1-R14}
;**********************************************************
; Print to the terminal screen the Hexadecimal Representation
; Of the Unsigned Value in R0
; Input: R0:  The unsigned word value 
; Output: N/A Terminal display
; Modify: APSR
; All other registers remain unchanged on return
;**********************************************************
            PUSH {R0-R5,LR}
			
			MOVS R2, R0            ; Hold the value
			MOVS R3, #0            ; Counter
			MOVS R5, R0            ; Constant Hex value
			MOVS R4, #28           ; Intial Shift amount
			
again1		MOVS R2,R5             ; restart R2
			LSRS R2,R2,R4          ; Shift Value by 28-n
			SUBS R4,R4,#4 
			LDR R1,=0x0000000F     ; Load the Register with mask
			
			
            MOVS R0,R2             ; Hold to Value to use R0 as an input
   		    ANDS R0,R0,R1          ; AND THE VALUES 
			CMP R0, #10            ; Checks before adding '0' s ascii value
			BHS	convert
			ADDS R0,R0,#'0'        ; Change the Hex value intp ASCII
			B 	skip
convert
			SUBS R0,R0,#10
			ADDS R0,R0,#'A'
skip    	BL  PutChar            ; PRINT
			ADDS R3,R3,#1          ; Increments the counter
			CMP R3,#8              ; LOOP 
			BLO again1             ; checks if the 
			
			POP {R0-R5,PC}
            BX LR
            ENDP

Dequeue     PROC {R1-R14}
;**********************************************************
;If the queue (whose queue record structure?s address is in R1) is not empty, dequeues
;a character from the queue to R0 and reports success by returning with the C flag
;cleared, (i.e., 0); otherwise only reports failure by returning with the C flag set, (i.e., 1).
; Input: R1: Address of queue record structure
; Output: R0: Character dequeued
; PSR C flag: Success(0) or Failure (1)
; Modify: R0; APSR
; All other registers remain unchanged on return
;**********************************************************
           PUSH {R1-R5}
		   LDR  R2,[R1,#OUT_PTR]       ; location of the out pointer
		   LDRB R3,[R1,#NUM_ENQD]      ; Number Enqueued
		   LDR  R4,[R1,#BUF_PAST]      ; Buffer Past
		   LDR  R5,[R1,#BUF_STRT]      ; Buffer Start
		   CMP  R3,#0                  ; Num Enqueued greater than one
		   BLS  Else2
		   LDRB R0,[R2,#0]             ; get the item at OutPointer and
		   ;Store into R0 to be outputed
		   SUBS R3,R3,#1               ; decrement the Number enueued
		   STRB R3,[R1,#NUM_ENQD]      ;
		   ADDS R2,R2,#1               ; Increment OutPointer
		   STR  R2,[R1,#OUT_PTR]       ; Storing the New OutPointer
		   CMP  R2,R4                  ; OutPointer >= Buffer Past
		   BLO  dontAdjust2            ; adjust OutPointer
		   MOVS R2, R5
		   STRB R2,[R1,#OUT_PTR]       ; Set the Out pointer = Buffer Start
dontAdjust2		
            MRS  	R3, APSR   		   ;CLEAR THE C FLAG
	        MOVS 	R4,#0x20
	        LSLS 	R4,R4,#24
	        BICS 	R3,R3,R4
	        MSR  	APSR, R3           ;CLEAR THE C FLAG
			B fin2
		   
Else2      
            MRS 	R3, APSR			;SETING THE C FLAG
	        MOVS 	R4, #0x20			          
	        LSLS 	R4,R4, #24
	        ORRS 	R3,R3,R4
	        MSR  	APSR, R3			;SETTING THE C FLAG
fin2
		   POP {R1-R5}
		   BX LR
		   ENDP

Init_UART0_IRQ   PROC   {R0-R14}
;*****************************************************************
; This Program will initialize the UART to be used in for PutChar and GetChar
; Input: 
; Ouput:
;*****************************************************************
				 PUSH	{R1-R3,LR}
				 LDR R0,=TxQueue
                 LDR R1,=TxQueueRecord
                 MOVS R2,#80
				 BL InitQueue
				 
				 LDR R0,=RxQueue
                 LDR R1,=RxQueueRecord
                 MOVS R2,#80
				 BL InitQueue
				 
				 LDR 	R1,=SIM_SOPT2
				 LDR 	R2,=SIM_SOPT2_UART0SRC_MASK
				 LDR 	R3,[R1,#0]
				 BICS 	R3,R3,R2
				 LDR 	R2,=SIM_SOPT2_UART0SRC_MCGFLLCLK
				 ORRS 	R3,R3,R2
				 STR 	R3,[R1,#0]
				 LDR 	R1,=SIM_SOPT5
				 LDR 	R2,=SIM_SOPT5_UART0_EXTERN_MASK_CLEAR
				 LDR 	R3,[R1,#0]
				 BICS 	R3,R3,R2
				 STR 	R3,[R1,#0]
				 LDR 	R1,=SIM_SCGC4
				 LDR 	R2,=SIM_SCGC4_UART0_MASK
				 LDR 	R3,[R1,#0]
				 ORRS 	R3,R3,R2
				 STR 	R3,[R1,#0]
				 LDR 	R1,=SIM_SCGC5
				 LDR 	R2,=SIM_SCGC5_PORTB_MASK
				 LDR 	R3,[R1,#0]
				 ORRS 	R3,R3,R2
				 STR 	R3,[R1,#0]
				 LDR 	R1,=PORTB_PCR2
				 LDR 	R2,=PORT_PCR_SET_PTB2_UART0_RX
				 STR 	R2,[R1,#0]
				 LDR 	R1,=PORTB_PCR1
				 LDR 	R2,=PORT_PCR_SET_PTB1_UART0_TX
				 STR 	R2,[R1,#0]
				 LDR 	R1,=UART0_BASE
				 MOVS 	R2,#UART0_C2_T_R
				 LDRB 	R3,[R1,#UART0_C2_OFFSET]
				 BICS 	R3,R3,R2
				 STRB 	R3,[R1,#UART0_C2_OFFSET]
				 
				 ; Intialize the NVIC for UART0 Polling 
				 ;Set UART0 IRQ priority
                 LDR R0,=UART0_IPR
                 LDR R1,=NVIC_IPR_UART0_MASK
                 LDR R2,=NVIC_IPR_UART0_PRI_3
                 LDR R3,[R0,#0]
                 BICS R3,R3,R1
                 ORRS R3,R3,R2
                 STR R3,[R0,#0]
                 ;Clear any pending UART0 interrupts
                 LDR R0,=NVIC_ICPR
                 LDR R1,=NVIC_ICPR_UART0_MASK
                 STR R1,[R0,#0]
				 ;Unmask UART0 interrupts
                 LDR R0,=NVIC_ISER
                 LDR R1,=NVIC_ISER_UART0_MASK
                 STR R1,[R0,#0]
				 
				 LDR    R1, =UART0_BASE
				 MOVS 	R2,#UART0_BDH_9600
				 STRB 	R2,[R1,#UART0_BDH_OFFSET]
				 MOVS 	R2,#UART0_BDL_9600
				 STRB 	R2,[R1,#UART0_BDL_OFFSET]
				 MOVS 	R2,#UART0_C1_8N1
				 STRB 	R2,[R1,#UART0_C1_OFFSET]
				 MOVS 	R2,#UART0_C3_NO_TXINV
				 STRB 	R2,[R1,#UART0_C3_OFFSET]
				 MOVS 	R2,#UART0_C4_NO_MATCH_OSR_16
				 STRB 	R2,[R1,#UART0_C4_OFFSET]
				 MOVS 	R2,#UART0_C5_NO_DMA_SSR_SYNC
				 STRB 	R2,[R1,#UART0_C5_OFFSET]
				 MOVS 	R2,#UART0_S1_CLEAR_FLAGS
				 STRB 	R2,[R1,#UART0_S1_OFFSET]
				 MOVS 	R2,#UART0_S2_NO_RXINV_BRK10_NO_LBKDETECT_CLEAR_FLAGS
				 STRB 	R2,[R1,#UART0_S2_OFFSET]
				 MOVS 	R2,#UART0_C2_T_R
				 STRB 	R2,[R1,#UART0_C2_OFFSET] 
				 ; Enable receive interrupt
				
				 ;UART0->C2 = UART0_C2_T_RI;  /* enable UART0 */
				 MOVS 	R2,#UART0_C2_T_RI
				 STRB 	R2,[R1,#UART0_C2_OFFSET]
				 POP	{R1-R3,PC}  
				 BX		LR
				 ENDP
InitQueue   PROC   {R0-R14}
;****************************************************************
;Initializes the queue record structure at the address in R1 for the empty
;queue buffer at the address in R0 of size given in R2, (i.e., character capacity).
;Input: R0 = Buffer  R1 = QRecord R2 = SIZE
;Output: N/A
;Modify: 
;****************************************************************
            PUSH {R0-R2}
			;LDR R0,=QBuffer
            ;LDR R1,=QRecord
            STR R0,[R1,#IN_PTR]
            STR R0,[R1,#OUT_PTR]
            STR R0,[R1,#BUF_STRT]
            ;MOVS R2,#Q_BUF_SZ
            ADDS R0,R0,R2
            STR R0,[R1,#BUF_PAST]
            STRB R2,[R1,#BUF_SIZE]
            MOVS R0,#0
            STRB R0,[R1,#NUM_ENQD]
			POP  {R0-R2}
			BX LR
           	ENDP
				
GetChar    PROC		{R1-R14}
;*****************************************************************
; This Program will read a single character from the terminal keyboard into R0
; Input: from Terminal Screen
; Ouput: R0 
;*****************************************************************			
          PUSH	{R1-R3, LR}							
		  LDR R1, =RxQueueRecord
GetAgain1
          CPSID I
		  BL Dequeue
		  CPSIE I
		  BCS GetAgain1
		  POP		{R1-R3, PC}
		  ENDP
				
		
GetCharTime    PROC		{R1-R14}    
;*****************************************************************
; This Program will read a single character from the terminal keyboard into R0
; Input: from Terminal Screen and R5 
; Ouput: R0, R6
;*****************************************************************			
          PUSH	{R1-R5,R7, LR}							
          MOVS  R6, #0
		  LDR   R4, =count						
		  LDR   R1, =RxQueueRecord
GetAgain2
          CPSID I
		  BL Dequeue
		  CPSIE I
		  BCS GetAgain2
		  LDR   R7,[R4,#0]
          CMP   R5, R7             ;USED TO CHECK THE TIME
		  BLS   STOP
		  B skipppp
STOP
          MOVS  R6,#1
skipppp
		  POP		{R1-R5, R7, PC}
		  BX		LR
		  ENDP
			  
Enqueue    PROC {R0-R14}
;**********************************************************
;If the queue (whose queue record structure?s address is in R1) is not full, enqueues the
;character from R0 to the queue and reports success by returning with the C flag
;cleared, (i.e., 0); otherwise only reports failure by returning with the C flag set, (i.e., 1).
; Input: R0: Character to enqueue
; R1: Address of queue record structure
; Output: PSR C flag: Success(0) or Failure (1)
; Modify: APSR
; All other registers remain unchanged on return
;**********************************************************
            PUSH  {R0-R6}
			; R1 is the base value to where 
			LDR R2, =Q_BUF_SZ
			LDRB R3,[R1,#NUM_ENQD]     ; Number Enqueued
			LDR R4, [R1,#IN_PTR]       ; value for the InPointer
			LDR R5, [R1,#BUF_PAST]     ; Value for Buffer Past
			CMP R2,R3                  ; Ensures that Number enqueued is
			; makes sure Buf Size > Num
			BLS  Else1
			STRB R0, [R4,#0]           ; Loads the Char into the In pointer's value
			ADDS R3,R3,#1              ; Increment the NumberEnqued
			STRB R3, [R1, #NUM_ENQD]   ;
			ADDS R4,R4,#1              ; Increment the In Pointer
			STR  R4, [R1,#IN_PTR]      ;
			CMP  R4,R5                 ; InPointer >= BufferPast (unsigned)
			BLT  dontAdjust            ; Adjust  if ^
			LDR  R6, [R1,#BUF_STRT]    ;
		    STR  R6, [R1,#IN_PTR]      ; Set the InPointer back to the start of the Queue
			MOVS R4, R6
dontAdjust                             ; \/ Clear C flag to indicate sucess
            MRS  	R3, APSR   		   ;CLEAR THE C FLAG
	        MOVS 	R4,#0x20
	        LSLS 	R4,R4,#24
	        BICS 	R3,R3,R4
	        MSR  	APSR, R3           ; CLEAR THE C FLAG
			B fin                      ; Branches to skip the ELSE statement
Else1                                  ; QUEUE is Full
            MRS 	R3, APSR		   ; SETING THE C FLAG
	        MOVS 	R4, #0x20			          
	        LSLS 	R4,R4, #24
	        ORRS 	R3,R3,R4
	        MSR  	APSR, R3		   ; SETTING THE C FLAG
fin
            POP  {R0-R6}
			BX   LR
			ENDP
  
PutChar    PROC		{R1-R14}
;*****************************************************************
; This Program will Display the single character from R0 to the terminal screen
; Input: R0
; Ouput: Digital on the screen
;*****************************************************************			
          PUSH	{R1-R3, LR}		
		  LDR R1, =TxQueueRecord
GetAgain
          CPSID I
		  BL Enqueue
		  CPSIE I
		  BCS GetAgain
		  LDR R1,  =UART0_BASE
		  MOVS R2, #UART0_C2_TI_RI
          STRB R2, [R1,#UART0_C2_OFFSET]		  
		  POP  {R1-R3, PC}
		  ENDP   
GetStringSB     PROC     {R1-R14}
;*****************************************************************
; With R0 as the address to the string in memory, this subroutine will take user input and 
; Store it up to R1-1 Length of Characters Until the user presses enter, then afterwards it will return
; the address of the string
; Input: R0, R1, R5  R5 is the TIME
; Ouput: R0
; Modify: R0, PSR
;*****************************************************************	            
            PUSH {R0-R4,LR}
			MOVS R2,R0            ; Move the base index of the string to R2
			MOVS R3, #0           ; the counter to insure we don't go Past R1-1 or MAX_STRING -1 
 			MOVS R4, #0x0D          ; Stores the enter key
			SUBS R1, #1           ; to insure that MAX_STRING-1 is the limit
Loop        BL GetChar            ;Gets the Character from the user
            CMP R4, R0            ;Checks if the user pressed "enter"
			BEQ ENDTHIS
            CMP R1, R3            ; Checks if too many characters are typed
			BLS StopStoringChar  
			STRB R0,[R2,R3]       ; Stores given character from the user(R0) into the address of the string
			BL PutChar            ; Puts the Character on    
			ADDS R3,R3,#1         ; Increments 
StopStoringChar B Loop
ENDTHIS                           ; After this the program, in main should continues to ask the user for the next instruction 
            MOVS R4, #0        ; This sets the null at the end of a string, so when reading the string the other subrotine will stop      
            STRB R4,[R2,R3]
            POP {R0-R4,PC}
            BX LR
			ENDP
				
PutStringSB     PROC     {R0-R14}
;*****************************************************************
; With R0 as the address to the string in memory, this subroutine will take the string stored in R0
; And read it out to the terminal until it read a null pointer
; Input: R0, R1
; Ouput: R0
; Modify: R0, PSR
;*****************************************************************	            	
           PUSH {R0-R5, LR}
		   MOVS R4, R0          ; Store the base address of the string
		   MOVS  R2, #0          ; Used to check if null	 
           MOVS R3, #0          ; Intializing the Counter	
           MOVS R5, #'&'        ; Used to check	&	   
readLoop   LDRB R0,[R4,R3]      ; Checks if the next variable is NULL
		   CMP R0, R2           ; ^
		   BEQ StopReading
		   CMP R0, R5
		   BEQ StopReading      ; Stops reading if it's &
		   BL   PutChar         ; Print into the terminal the Character from [R2, R3] 
		   ADDS R3,R3, #1       ; Increments the Pointer
		   B readLoop
StopReading
		   POP {R0-R5, PC}
           BX LR
           ENDP

			
UART0_ISR   PROC   {R0-R14}
;*****************************************************************
; This Program will initialize the UART to be used in for PutChar and GetChar
; Input: 
; Ouput:
;*****************************************************************
; R0 output for Dequeue
; R1 input for Dequeue
; R2 UART0_BASE 
; R3 Value of C2 
; R4 Value of S1
; R5 TIE mask , TDRE mask , UART0_C2_T_RI, & RDRF MASK

        CPSID I       							; MAsk other interrupts
		PUSH {R4-R6,LR}
		LDR  R2, =UART0_BASE    				; like in the IRQ
		LDRB  R4,[R2,#UART0_S1_OFFSET]
		MOVS R5, #UART0_C2_TIE_MASK
		LDRB R3,[R2,#UART0_C2_OFFSET]       	; Load TIE to check if TIE is = 1 in UART0_C2									
		TST  R3,R5           					;IF (TIE = 1) if TIE is set
		BEQ nextIF             					   ; TIE is the 	7th bit counting 7- 0  
		
		MOVS R5, #UART0_S1_TDRE_MASK
		;LDR  R2, =UART0_BASE
		;LDRB R4,[R2,#UART0_S1_OFFSET]							    
		TST  R4,R5                                  ;IF (TDRE = 1)      ;TDRE = 1 in UART0_S1
	    BEQ nextIF
		
		LDR R1,=TxQueueRecord
		BL Dequeue		      
		BCS elseCauseFailedDequeue      ; IF dequeue is Succesfl (c = 0)
		;LDR  R2, =UART0_BASE
		STRB R0,[R2,#UART0_D_OFFSET] 			; Write Charcter to UART0_D ; Tx Data Reg
	    B nextIF
		
elseCauseFailedDequeue 							       ;ELSE
		MOVS R5,#UART0_C2_T_RI   				       ;Disable TxInterrupt 
		;LDR  R2, =UART0_BASE banana work
		STRB R5,[R2,#UART0_C2_OFFSET]
nextIF 										; if (RxInterrupt) then ;RDRF = 1 in UART0_S1
        MOVS  R5, #UART0_S1_RDRF_MASK
		;LDR  R2, =UART0_BASE
		;LDRB  R4,[R2,#UART0_S1_OFFSET]
		TST   R4, R5                 
        BEQ   dontEnqueue
		;LDR  R2, =UART0_BASE
		LDRB  R0,[R2,#UART0_D_OFFSET] 			; Read the Character from UART_D 
		LDR   R1, =RxQueueRecord
		BL    Enqueue
dontEnqueue
		CPSIE I        							; Un mask other interrupts
		POP {R4-R6,PC}
		ENDP
;>>>>>   end subroutine code <<<<<
            ALIGN
;****************************************************************
;Vector Table Mapped to Address 0 at Reset
;Linker requires __Vectors to be exported
            AREA    RESET, DATA, READONLY
            EXPORT  __Vectors
            EXPORT  __Vectors_End
            EXPORT  __Vectors_Size
            IMPORT  __initial_sp
            IMPORT  Dummy_Handler
            IMPORT  HardFault_Handler
__Vectors 
                                      ;ARM core vectors
            DCD    __initial_sp       ;00:end of stack
            DCD    Reset_Handler      ;01:reset vector
            DCD    Dummy_Handler      ;02:NMI
            DCD    HardFault_Handler  ;03:hard fault
            DCD    Dummy_Handler      ;04:(reserved)
            DCD    Dummy_Handler      ;05:(reserved)
            DCD    Dummy_Handler      ;06:(reserved)
            DCD    Dummy_Handler      ;07:(reserved)
            DCD    Dummy_Handler      ;08:(reserved)
            DCD    Dummy_Handler      ;09:(reserved)
            DCD    Dummy_Handler      ;10:(reserved)
            DCD    Dummy_Handler      ;11:SVCall (supervisor call)
            DCD    Dummy_Handler      ;12:(reserved)
            DCD    Dummy_Handler      ;13:(reserved)
            DCD    Dummy_Handler      ;14:PendSV (PendableSrvReq)
                                      ;   pendable request 
                                      ;   for system service)
            DCD    Dummy_Handler      ;15:SysTick (system tick timer)
            DCD    Dummy_Handler      ;16:DMA channel 0 transfer 
                                      ;   complete/error
            DCD    Dummy_Handler      ;17:DMA channel 1 transfer
                                      ;   complete/error
            DCD    Dummy_Handler      ;18:DMA channel 2 transfer
                                      ;   complete/error
            DCD    Dummy_Handler      ;19:DMA channel 3 transfer
                                      ;   complete/error
            DCD    Dummy_Handler      ;20:(reserved)
            DCD    Dummy_Handler      ;21:FTFA command complete/
                                      ;   read collision
            DCD    Dummy_Handler      ;22:low-voltage detect;
                                      ;   low-voltage warning
            DCD    Dummy_Handler      ;23:low leakage wakeup
            DCD    Dummy_Handler      ;24:I2C0
            DCD    Dummy_Handler      ;25:(reserved)
            DCD    Dummy_Handler      ;26:SPI0
            DCD    Dummy_Handler      ;27:(reserved)
            DCD    UART0_ISR      ;28:UART0 (status; error)
            DCD    Dummy_Handler      ;29:(reserved)
            DCD    Dummy_Handler      ;30:(reserved)
            DCD    Dummy_Handler      ;31:ADC0
            DCD    Dummy_Handler      ;32:CMP0
            DCD    Dummy_Handler      ;33:TPM0
            DCD    Dummy_Handler      ;34:TPM1
            DCD    Dummy_Handler      ;35:(reserved)
            DCD    Dummy_Handler      ;36:RTC (alarm)
            DCD    Dummy_Handler      ;37:RTC (seconds)
            DCD    PIT_ISR            ;38:PIT
            DCD    Dummy_Handler      ;39:(reserved)
            DCD    Dummy_Handler      ;40:(reserved)
            DCD    Dummy_Handler      ;41:DAC0
            DCD    Dummy_Handler      ;42:TSI0
            DCD    Dummy_Handler      ;43:MCG
            DCD    Dummy_Handler      ;44:LPTMR0
            DCD    Dummy_Handler      ;45:(reserved)
            DCD    Dummy_Handler      ;46:PORTA
            DCD    Dummy_Handler      ;47:PORTB
__Vectors_End
__Vectors_Size  EQU     __Vectors_End - __Vectors
            ALIGN
;****************************************************************
;Constants
            AREA    MyConst,DATA,READONLY
;>>>>> begin constants here <<<<<
Instructions DCB "Type the First Letter Of the Color\r\nYou see on the KL05 Board's LED:\r\nPress Any Key to Start> \0"
RightGreen DCB ": Correct--color was Green\0"
RightBlue DCB  ": Correct--color was Blue\0"
RightRed DCB   ": Correct--color was Red\0"
RightWhite DCB ": Correct--color was White\0"

WrongGreen DCB "X: Out of time--color was Green\0"
WrongBlue DCB  "X: Out of time--color was Blue\0"
WrongRed DCB   "X: Out of time--color was Red\0"
WrongWhite DCB "X: Out of time--color was White\0"

Wrong DCB "Wrong\0"
scores DCB "Score: \0"
seed1 DCB "rwgbrgrwgb"
seed2 DCB "bgbgbgrbgb"
seed3 DCB "wgbwbgrgbw"

;>>>>>   end constants here <<<<<
            ALIGN
;****************************************************************
;Variables
            AREA    MyData,DATA,READWRITE
;>>>>> begin variables here <<<<<
; Queue Structure
stop_Watch SPACE 1      ; a one byte value that indicates on or off
	     ALIGN
count      SPACE 4      ; a word value that holds the number o f
	     ALIGN
userVal  SPACE   4
	     ALIGN
QBuffer  SPACE Q_BUF_SZ ; Queue Content
	     ALIGN
QRecord  SPACE Q_REC_SZ ; Queue Management record
	     ALIGN
RxQueue  SPACE 80
		 ALIGN
RxQueueRecord  SPACE Q_REC_SZ
		 ALIGN
TxQueue  SPACE 80 
		 ALIGN
TxQueueRecord  SPACE Q_REC_SZ
		 ALIGN
;>>>>>   end variables here <<<<<
            ALIGN
            END