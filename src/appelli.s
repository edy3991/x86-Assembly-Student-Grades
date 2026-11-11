/*

SE IL MAIN RICEVE UN PARAMETRO, CARICA SULLO STACK IL PARAMETRO
E CHIAMA LA FUNZIONE carica_file_reg.
SE IL MAIN NON RICEVE PARAMETRI, STAMPA IL MENU.

*/


.section .data
    due_punti: .ascii ":"
    error_open_msg: .ascii "Errore: Impossibile aprire il file.\n"
    error_open_msg_len: .int . - error_open_msg
    exit_success: .ascii "Il file libretti.txt è stato aggiornato con successo.\n"
    exit_success_len: .int . - exit_success
    prompt_menu:
        .ascii "\n===== MENU =====\n1. Esci\n2. Vedi libretto studente\n3. Vedi esiti esame\n4. Vedi graduatoria\nScelta:"
    prompt_menu_len: .int . - prompt_menu
    matricola_non_valida: .ascii "Matricola non valida. Inserisci una matricola valida: \n"
    matricola_non_valida_len: .int . - matricola_non_valida
    opzione_non_valida: .ascii "Opzione non valida. Riprova.\n\n\n"
    opzione_non_valida_len: .int . - opzione_non_valida
    matricola_non_presente_anagrafica_menu: .ascii "Matricola non presente nel file anagrafica.\n"
    matricola_non_presente_anagrafica_menu_len: .int . - matricola_non_presente_anagrafica_menu
    codice_esame_non_valido_error: .ascii "Codice esame non valido. Inserisci un codice esame valido: \n"
    codice_esame_non_valido_error_len: .long . - codice_esame_non_valido_error
    inserisci_matricola: .ascii "Inserisci la matricola dello studente: "
    inserisci_matricola_len: .int . - inserisci_matricola
    inserisci_codice_esame: .ascii "Inserisci il codice dell'esame: "
    inserisci_codice_esame_len: .long . - inserisci_codice_esame
    codice_esame_buffer: .skip 4
    


.section .bss
    .lcomm matricola_stdin, 8
    scelta: .skip 4  

.section .text
    .align 4
        .global _start

_start:
	popl %ecx                    # argc in %ecx
    	popl %ebx                   # argv[0] (nome del programma) in %ebx - lo scartiamo per ora

	cmpl $2, %ecx				 # verifica che il numero di argomenti sia 2
	jl stampa_menu

	popl %ebx					 # argv[2] (parametro passato) in %ebx
	pushl %ebx
	call carica_file_reg
	addl $4, %esp				 # puliamo lo stack dopo la chiamata alla funzione
    jmp _exit_success

_exit_failure:

    movl $1, %eax                # syscall exit
    movl $1, %ebx                # Codice di uscita 1 (errore)
    int $0x80

stampa_menu:			 
    movl $4, %eax                # syscall write   
    movl $1, %ebx
    leal prompt_menu, %ecx       
    movl prompt_menu_len, %edx
    int $0x80                    # stamppa il menu

    movl $3, %eax                # syscall read
    movl $0, %ebx 
    movl $scelta, %ecx             
    movl $4, %edx                
    int $0x80                    # legge l'input dell'utente

    movzbl scelta, %eax          # carica il byte letto in %eax
    subl $48, %eax               # converte il byte ASCII in un numero (0-9)

    cmpb $1, %al                 # verifica se il byte è '1' (opzione 1)
    je opzione_1

    cmpb $2, %al                 # verifica se il byte è '2' (opzione 2)
    je opzione_2

    cmpb $3, %al                 # verifica se il byte è '3' (opzione 3)
    je opzione_3

    cmpb $4, %al
    je opzione_4

    jmp opzione_non_valida_error

opzione_1:
    # Opzione 1: Esci
    movl $1, %eax               # syscall exit
    movl $0, %ebx               # Codice di uscita 0 (successo)
    int $0x80

opzione_2:
    # Opzione 2: Vedi libretto studente
    movl $4, %eax               # syscall write
    movl $1, %ebx               # stdout
    leal inserisci_matricola, %ecx
    movl inserisci_matricola_len, %edx
    int $0x80

    movl $3, %eax               # syscall read
    movl $0, %ebx               # stdin
    leal matricola_stdin, %ecx
    movl $8, %edx               # dimensione del buffer
    int $0x80

    cmpl $8, %eax               # verifica se sono stati letti 8 byte
    jne matricola_non_valida_error

    pushl $matricola_stdin
    call carica_file_anagrafica_menu
    addl $4, %esp               # puliamo lo stack dopo la chiamata alla funzione
    cmpl $1, %edx               # verifica se la matricola è valida
    je opzione_2_libretti
    jmp matricola_non_presente_error

opzione_2_libretti:
    pushl $matricola_stdin
    call carica_file_libretti_menu
    addl $4, %esp

opzione_3:
    # Opzione 3: Vedi esiti esame
    movl $4, %eax               # syscall write
    movl $1, %ebx               # stdout
    leal inserisci_codice_esame, %ecx
    movl inserisci_codice_esame_len, %edx
    int $0x80

    movl $3, %eax               # syscall read
    movl $0, %ebx               # stdin
    leal codice_esame_buffer, %ecx
    movl $3, %edx               # dimensione del buffer
    int $0x80

    cmpl $3, %eax               # verifica se sono stati letti 8 byte
    jne codice_esame_non_valido

    pushl $codice_esame_buffer
    call gestisci_codice_esame
    addl $4, %esp               # puliamo lo stack dopo la chiamata alla funzione


opzione_4:
    call funzione_graduatoria

_exit_success:
    movl $4, %eax               # syscall write
    movl $1, %ebx               # stdout
    leal exit_success, %ecx
    movl exit_success_len, %edx
    int $0x80

    movl $1, %eax               # syscall exit
    movl $0, %ebx               # Codice di uscita 0 (successo)
    int $0x80

matricola_non_valida_error:
    movl $4, %eax               # syscall write
    movl $1, %ebx               # stdout
    leal matricola_non_valida, %ecx
    movl matricola_non_valida_len, %edx
    int $0x80

    jmp opzione_2

codice_esame_non_valido:
    movl $4, %eax               # syscall write
    movl $1, %ebx               # stdout
    leal codice_esame_non_valido_error, %ecx
    movl codice_esame_non_valido_error_len, %edx
    int $0x80

    jmp opzione_3

opzione_non_valida_error:
    movl $4, %eax               # syscall write
    movl $1, %ebx               # stdout
    movl $opzione_non_valida, %ecx
    movl opzione_non_valida_len, %edx
    int $0x80

    jmp stampa_menu

matricola_non_presente_error:

    movl $4, %eax               # syscall write
    movl $1, %ebx               # stdout
    leal matricola_non_presente_anagrafica_menu, %ecx
    movl matricola_non_presente_anagrafica_menu_len, %edx
    int $0x80

    jmp _exit_failure