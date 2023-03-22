; ******************************************************************************

section	.data

; -----
;  Define standard constants.

TRUE		equ	1
FALSE		equ	0

EXIT_SUCCESS	equ	0			; Successful operation

STDIN		equ	0			; standard input
STDOUT		equ	1			; standard output
STDERR		equ	2			; standard error

SYS_read	equ	0			; system call code for read
SYS_write	equ	1			; system call code for write
SYS_open	equ	2			; system call code for file open
SYS_close	equ	3			; system call code for file close
SYS_fork	equ	57			; system call code for fork
SYS_exit	equ	60			; system call code for terminate
SYS_creat	equ	85			; system call code for file open/create
SYS_time	equ	201			; system call code for get time

LF		equ	10
SPACE		equ	" "
NULL		equ	0
ESC		equ	27

; -----
;  Define program specific constants.

MIN		equ	0
MAX		equ	100000

BUFFSIZE	equ	50			; 50 chars including NULL
; -----
; ******************************************************************************

section	.text

;  External statements for C++ functions.

extern	prtPrompt
extern	errInvalidNum
extern	errTooHigh
extern	errTooLong
; -----------------------------------------------------------------------------
;  Read an ASCII quaternary number from the user

;  Return codes:
;	TRUE / FALSE

; -----
;  Call:
;	status = readQuatNum(&numberRead);

;  Arguments Passed:
;	1) numberRead, addr - rdi

;  Returns:
;	number read (via reference)
;	TRUE / FALSE
global readQuatNum
readQuatNum:
    ; Function Prologue 
    push rbp 
    mov rbp, rsp ; Setting stack's base pointer 

    push rdi ; Pushing argument onto the stack 
    push rbx 
    push r12 
    push r13 

    sub rsp, BUFFSIZE ; Allocating space in stack for the BUFFER 
    sub rsp, 1 ; Allocating local byte variable to store each digit read in by STDIN 

prompt: 
    ; Calling C++ function to print prompt for user 
    call prtPrompt
    mov r8d, 0 
    mov r10, 0 ; r10: Temporary register that will store the index of each char in the buffer
    ; r12: Keeps track of HOW MANY chars in buffer will be used in conversion
    ; since user is allowed to put leading spaces 
    mov r12, 0

quatNumRead: 
    ; System service call to retrieve input from the user 
    mov rax, SYS_read
    mov rdi, STDIN
    lea rsi, [rsp] ; Store the char into the local byte variable 
    mov rdx, 1 ; Read the string in one char at a time 
    syscall 
    mov al, byte [rsp]

    ; If al contains LF, then all of user input is in the buffer, so 
    ; stop reading the input 
	cmp al, LF 
	je numReadDone 

    ; If r10 is equal to BUFFSIZE, then stop adding to the buffer and 
    ; continue looping until user hits return (r10 should be max BUFFSIZE - 1)
    cmp r10, BUFFSIZE 
    je quatNumRead 

    ; Move value from local into buffer 
    mov byte[rsp+1+r10], al 

    ; r10 : Register used to keep track of length of the buffer 
    inc r10 
    ; If user inputted a space, do not increment register that holds 
    ; how many digits are in the number (since spaces in between numbers
    ; is allowed)
    cmp al, ' '
    je quatNumRead 

    inc r12 
    ; Continue looping through quatNumRead until user inputs LF
    jmp quatNumRead 

numReadDone:  
    ; Moving NULL as the last char in the buffer to signify the end of input/don't have to clear out
    ; the buffer each time a user inputs invalid data 
    mov byte [rsp+1+r10], NULL 
    
    ; If r10 is equal to 0, then user inputted a return which means they are done inputting 
    cmp r10, 0 
    je noMoreInput 

    ; If r10 is equal to BUFFSIZE, then user inputted too many characters, so output error message
    cmp r10, BUFFSIZE 
    je tooLong 

    mov r11, r10 ; r11 : Storing how many times to loop through quatNumConv 
    dec r12 ; Decreasing r12 once, so it matches the index for each char in the buffer 

    mov r10, 0  ; Resetting r10 back to 0

quatNumConv:
    ; Move character stored in BUFFER into al 
    mov al, byte [rsp+1+r10]
    ; If current char is LF, then the end of the buffer has been reached, so 
    ; conversion is complete 
    cmp al, NULL  
    je convDone 
    ; If al contains a char below the value of 0 (48 decimal), then an invalid number
    ; might have been entered, so check if it's true
    cmp al, '0'
    jb frontSpaceCheck 
    ; If al contains a char above the value of 3 (51 decimal), then an invalid number
    ; was entered 
    cmp al, '3'
    ja invalidNum 
    ; Eax/Ebx : Registers used for multiplication 
    mov eax, 1 
    mov ebx, 4 
    mov r13, r12 ; r13 : Register that keep tracks of how many times to loop through mulFour
mulFourLoop:
    ; If r13 equals 0, then stop multiplying by 4 
    cmp r13, 0
    je addNum 
    ; Multiply A register by 4 as many times as needed 
    mul ebx 
    ; Decrease r13 each time loop is complete 
    dec r13
    jmp mulFourLoop
addNum: 
    ; Move A register value into ebx 
    mov ebx, eax 
    movzx eax, byte[rsp+1+r10] ; Move char into A register and subtract 48 to get int equivalent
    sub eax, 48    
    mul ebx ; Multiply A by ebx to get properly converted value
    add r8d, eax ; Add to running total 
    dec r12
mulFourInc: 
    ; Decrease overall loop counter
    dec r11 
    ; Increase the index register 
    inc r10 
    ; Jump to start of conversion loop until LF is reached in the buffer 
    jmp quatNumConv 

convDone: 
    ; No error message for MIN was provided, so not checking 
    ; If converted number is above the maximum value, then output error message 
    ; and reprompt the user 
    cmp r8d, MAX
    ja tooHigh
    ; If reached this point, then valid number was inputted/able to be converted
    ; so return true 
    mov eax, TRUE 
    jmp funcDone  

frontSpaceCheck: 
    ; If al does not equal space char (32 decimal), then output error message
    cmp al, ' ' 
    jne invalidNum 
    ; If r8 is equal to 0, then a leading space was entered, so jump to mulFourInc
    ; and ignore the leading space
    cmp r8d, 0
    je mulFourInc
    ; If r8 is storing a value though, then output error message 

invalidNum:
    ; Output invalid num error message from main C++ file 
    call errInvalidNum  
    jmp prompt 

tooLong:
    ; Output that number inputted was too long from main C++ file
    call errTooLong 
    jmp prompt 

tooHigh: 
    ; Output that number is too big from main C++ file 
    call errTooHigh
    jmp prompt 

noMoreInput:
    ; Setting eax to false, so function will stop being called by C++ main
    mov eax, FALSE 
funcDone:
    ; Function Epilogue 
    ; Clean out the buffer and restore values to preserved registers 
    add rsp, 1 
    add rsp, BUFFSIZE 
    pop r13 
    pop r12 
    pop rbx 

    ; Pop passed argument and move r8's value into it's memory location
    pop rdi 
    mov dword[rdi], r8d
    pop rbp 

    ret 
; **********************************************************************************
;  Insertion Sort Algorithm:

; -----
;	insertionSort(array Arr) {
;		for i = 1 to length-1 do {
;			value := Arr[i];
;			j = i - 1;
;			while ((j ≥ 0) and (Arr[j] > value)) {
;				Arr[j+1] = Arr[j];
;				j = j - 1;
;			};
;			Arr[j+1] = value;
;		};
;	};

; -----
;  HLL Call:
;	call insertionSort(list, len)

;  Arguments Passed:
;	1) list, addr - rdi
;	2) length, value - rsi

;  Returns:
;	sorted list (list passed by reference)
global insertionSort
insertionSort: 

	; Function Prologue
	push rbp
	mov rbp, rsp 
	push rbx 
	
	; ecx : Loop counter for the for loop
	; r10 : Holds the ith index (which is the next number in the array)
	; r11 : Holds the jth index (the number before the ith index)
	mov ecx, 1
	mov r10, 1
	mov r11, 0

; For loop that will go through each value in the array and sort the numbers
; in ascending order
; Condition will be i = 1 to length -1 
forLoop:
	; eax : Will store the ith value of the array
	; value = arr[i]
	mov eax, dword [rdi+(r10*4)]
	
	; ebx : Will the store jth value of the array
	; Represents j = i - 1 
	mov ebx, dword [rdi+(r11*4)]
; Nested while loop that will move the number backwards in a list until it's
; sorted correctly
; Condition will be when j ≥ 0 AND arr[j] > value
whileLoop:
	; If r11 is below 0, then first condition of while loop is not met 
	; so do not execute (j will not be greater/equal to 0)
	cmp r11, 0
	jl skipSort
	; If value in ebx is below value in eax, then second condition of
	; while loop is not met so don't execute (arr[j] is not less than arr[i])
	cmp ebx, eax 
	jb skipSort
	; Arr[j+1] = Arr[j];
	; Moving the larger value into ith index and then moving smaller value into jth index 
	; Have to manually move values into array to prevent values from being overwritten
	mov dword [rdi+(r11*4)], eax
	mov dword [rdi+(r11*4)+4], ebx 
	; Decreases the jth index (j = j - 1)
	dec r11
	; Move the jth value into eax now 
	mov ebx, dword[rdi+(r11*4)]
	jmp whileLoop
skipSort:
	; Make r11 equal to r10 (new jth index)
	mov r11, r10
	; Add one to r10 to make a new ith index 
	inc r10
	inc ecx 
	; If ecx is not equal to array's length, then continue looping
	cmp ecx, esi
	jne forLoop

	; Function Epilogue 
	pop rbx 
	pop rbp 

	ret
; --------------------------------------------------------
;  Find statistical information for a list of integers:
;	minimum, median, maximum, sum, and average

;  Note, for an odd number of items, the median value is defined as
;  the middle value.  For an even number of values, it is the integer
;  average of the two middle values.

;  This function must call the lstAvergae() function
;  to get the average.

;  Note, assumes the list is already sorted.

; -----
;  Call:
;	call lstStats(list, len, sum, ave, min, max, med)

;  Arguments Passed:
;	1) list, addr - rdi
;	2) length, value - rsi
;	3) sum, addr - rdx
;	4) average, addr - rcx
;	5) minimum, addr - r8
;	6) maximum, addr - r9
;	7) median, addr - stack, rbp+16

;  Returns:
;	minimum, median, maximum, sum, and average
;		via pass-by-reference
global lstStats
lstStats:

	; Function Prologue 
	push rbp 
	mov rbp, rsp 
	push r12 
	push r13 
	push r14 
	push r15 

	; Finding the min and storing into r8
	mov r11d, dword [rdi]
	mov dword [r8], r11d 

	; Finding the max and storing into r9
	mov r11d, dword [rdi+(rsi-1)*4]
	mov dword [r9], r11d	

	mov r12, rdi 
	mov r13d, esi 
	mov r14, rdx 
	mov r15, rcx 

	; Calling lstSum to get sum
	call lstSum
	mov dword [r14], eax 

	; Calling lstMedian to get average 
	call lstAverage
	mov dword [r15], eax

	; Calling lstMedian to get median value 
    call lstMedian 
    mov r11, qword [rbp+16]
	mov dword [r11], eax  

	; Function Epilogue 
	pop r15 
	pop r14 
	pop r13 
	pop r12 
	pop rbp 

	ret
; --------------------------------------------------------
;  Function to calculate the median of a sorted list.

; -----
;  Call:
;	ans = lstMedian(lst, len)

;  Arguments Passed:
;	1) list, address - rdi
;	2) length, value - rsi

;  Returns:
;	median (in eax)
global lstMedian
lstMedian: 

	; Function Prologue 
	push rbx 
	push r12 
	; Taking the length and dividing it by 2 
	mov rax, rsi
	cqo 
	mov rbx, 2 
	idiv rbx 
	; If there's a remainder of 1 in rdx, then find the estimated
	; odd-numbered list median 
	cmp rdx, 1
	je oddMedian
	; If not, then find the estimated even-numbered list median 
	; Take the two middle values and divide by 2 
	mov r12d, dword [rdi+(rax*4)]
	add r12d, dword [rdi+(rax-1)*4]
	mov eax, r12d 
	cdq 
	idiv ebx 
	jmp medFound
oddMedian:
	; Median will be middle value in the list 
	mov ebx, dword [rdi+(rax*4)]
	mov eax, ebx 
medFound:
	; Function Epilogue 
	pop r12 
	pop rbx 
	; Return median in eax 
	ret
; --------------------------------------------------------
;  Function to calculate the estimated median of
;  an unsorted list.

; -----
;  Call:
;	ans = lstEstMedian(lst, len)

;  Arguments Passed:
;	1) list, address - rdi
;	1) length, value - rsi

;  Returns:
;	est median (in eax)
global lstEstMedian
lstEstMedian: 

	; Function Prologue 
	push rbx 
	; First, adding the first/last values into ebx 
	mov ebx, dword [rdi]
	add ebx, dword [rdi+(rsi-1)*4]
	; Next, checking to see if the list is even or odd 
	mov eax, esi 
	cdq 
	mov ecx, 2
	idiv ecx 
	; If the remainder in edx is 1, then list is odd 
	; so find odd estimated median 
	cmp edx, 1 
	je oddMed
	; If it isn't odd, then find even estimated median
	; Add the middle value/middle value - 1 to ebx 
	add ebx, dword [rdi+(rax*4)]
	add ebx, dword [rdi+(rax*4)-4]
	; Divide value by 4 to get estimated even median
	mov eax, ebx 
	cdq 
	mov ebx, 4
	idiv ebx 
	jmp medDone
oddMed:
	; Add middle value to ebx 
	add ebx, dword [rdi+(rax*4)]
	; Divide value by 3 to get estimated odd median
	mov eax, ebx 
	cdq 
	mov ebx, 3
	idiv ebx
medDone:
	; Function Epilogue 
	pop rbx 
	; Return median in eax 
	ret
; --------------------------------------------------------
;  Function to calculate the sum of a list.

; -----
;  Call:
;	ans = lstSum(lst, len)

;  Arguments Passed:
;	1) list, address - rdi
;	1) length, value - rsi

;  Returns:
;	sum (in eax)
global lstSum
lstSum: 

	; r11: Loop counter 
	mov r11, 0
	mov eax, 0
sumLoop: 
	add eax, dword [rdi+(r11*4)]
	inc r11
	; If r11 does not equal the length of rsi, then 
	; continue looping 
	cmp r11, rsi 
	jne sumLoop
	; Return sum in eax 
	ret

; --------------------------------------------------------
;  Function to calculate the average of a list.

; -----
;  Call:
;	ans = lstAverage(lst, len)

;  Arguments Passed:
;	1) list, address - rdi
;	1) length, value - rsi

;  Returns:
;	average (in eax)
global lstAverage
lstAverage: 
	
	; Function Prologue 
	push r12 
	push r13 

	mov eax, 0
	mov r12, rdi 
	mov r13d, esi 
	; Calling lstSum to get the sum of the array 
	call lstSum 
	; Divide eax by the length of the list to get the average
	cdq 
	idiv r13d 
	; Function Epilogue 
	pop r13 
	pop r12
	; Return the average in eax  
	ret 

; --------------------------------------------------------
;  Function to calculate the kurtosis statisic.

; -----
;  Call:
;  kStat = lstKurtosis(list, len, ave)

;  Arguments Passed:
;	1) list, address - rdi
;	2) len, value - esi
;	3) ave, value - edx

;  Returns:
;	kurtosis statistic (in rax)
global lstKurtosis
lstKurtosis: 

	; Function prologue 
	push rbx 
	push r13
	push r14 

	; r10: Loop counter 
	mov r10, 0 
	mov r11d, edx 
	mov rbx, 0

; First, finding the value of the divisor 
botLoop:
	; Subtracting the average from the current value 
	mov eax, dword [rdi+(r10*4)]
	sub eax, r11d 
	cdqe 
	; Squaring the value 
	imul rax 
	; Adding value to a running total 
	add rbx, rax 
	inc r10
	; If r10 does not equal rsi, continue looping until each
	; value has been accounted for in the array
	cmp r10, rsi
	jne botLoop 
	; If rbx equals 0, answer will be 0, so don't bother finding
	; the dividend 
	cmp rbx, 0
	je skip

	mov r10, 0
	mov r14, 0
; Next, finding the value of the dividend and performing the division 
topLoop:
	; Subtracting the average from the current value 
	mov eax, dword [rdi+(r10*4)]
	sub eax, r11d  
	cdqe 
	; Now, have to multiply the value by itself 3 times (val^4)
	mov r13, rax 
	imul r13
	imul r13
	imul r13  
	; Add value to a running total 
	add r14, rax 
	inc r10
	; If r10 does not equal rsi, continue looping until each value accounted for
	cmp r10, rsi
	jne topLoop 
	; Now divide the divisor by the dividend 
	mov rax, r14
	cqo
	idiv rbx 
	jmp retVal 
skip:
	; Move 0 to rax to show kurtosis gives you a value of 0
	mov rax, 0 
retVal:
	; Function epilogue 
	pop r14
	pop r13 
	pop rbx 
	; Returning kurtosis value in rax 
	ret

; ********************************************************************************

