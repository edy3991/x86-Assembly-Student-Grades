/*
1° parte della funzione carica_file_reg

la funzione carica_file_reg scarica dallo stack il parametro che contiene il nome del file
e lo apre in lettura. se l'apertura va a buon fine, legge il codice dell'esame della prima
riga e lo salva in una variabile, successivamente legge le righe del file e per ogni riga 
legge la matricola e l'esito salvandole in altre variabili. infine carica sullo stack il nome della matricola e
chiama la funzione carica_file_anagrafica.

2° parte della funzione carica_file_reg

se la matricola non viene trovata nel file anagrafica, stampa un messaggio di errore.
se la matricola viene trovata, chiama la funzione carica_file_libretti
e carica sullo stack i seguenti parametri:
matricola_buffer, codice_crediti_esame_buffer e esiti_buffer.

*/


.section .data
    filename_ptr_fd_reg: .int 0
    errore_matricola_non_presente_p1: .asciz "La matricola "
    errore_matricola_non_presente_p1_len: .long . - errore_matricola_non_presente_p1
    errore_matricola_non_presente_p2: .asciz " non è presente\n"
    errore_matricola_non_presente_p2_len: .long . - errore_matricola_non_presente_p2
    flag_fine_file_reg: .long 0
    errore_apertura_file_reg: .asciz "Errore nell'apertura del file registri.\n"
    errore_apertura_file_reg_len: .long . - errore_apertura_file_reg

.section .bss
    fd_reg: .skip 4
    matricola_buffer: .skip 256
    codice_crediti_esame_buffer: .skip 256
    esiti_buffer: .skip 256
    buffer_lettura: .skip 1

.section .text
    .globl carica_file_reg
    .type carica_file_reg, @function

carica_file_reg:
    # prologo
    pushl %ebp			# per prassi si pusha ebp sullo stack così che poi venga recuperato
    movl %esp, %ebp		# ciò a cui punta esp, ora punta anche ebp
    

    # eax contiene il parametro (filename)
    movl 8(%ebp), %eax	# aggiungendo 8 si ottiene il parametro che abbiamo pushato prima della call. Se avessimo fatto 4, anziche 8, avrebbe recuperato il RETURN ADDRESS
    movl %eax, filename_ptr_fd_reg # spostiamo il nome del file in questa variabile

    # open del file registri in modalità lettura
    movl $5, %eax
    movl filename_ptr_fd_reg, %ebx
    movl $0, %ecx
    int $0x80

    # se l'apertura del file fallisce, allora va a _error_open_reg
    cmpl $0, %eax
    jl _error_open_reg

    movl %eax, fd_reg	# quando si apre un file, ad eax viene assegnato un intero che rappresenta il file descriptor, assegnamolo alla variabile fd_reg

    # per convenzione azzeriamo i registri esi e edi
    xorl %esi, %esi           	
    xorl %edi, %edi           	

# funzione che legge il codice dell'esame
codice_esame_read_loop:			
    movl $3, %eax             	# syscall read
    movl fd_reg, %ebx
    leal codice_crediti_esame_buffer(%esi), %ecx
    movl $1, %edx
    int $0x80

    cmpl $0, %eax
    jle close_and_exit_reg		# errore se non riesce a leggere il file

    movzbl (%ecx), %eax         # carica il byte letto in %al
    cmpl $':', %eax
    je crediti_esame            # se l'ultimo byte letto è ':', allora chiama la funzione che legge i crediti dell'esame

    incl %esi
    jmp codice_esame_read_loop

# funzione che legge i crediti dell'esame e li aggiunge nella variabile codice_crediti_esame_buffer dove si trova il codice dell'esame
crediti_esame:
    incl %esi
    movl $3, %eax             	# syscall read
    movl fd_reg, %ebx
    leal codice_crediti_esame_buffer(%esi), %ecx
    movl $1, %edx
    int $0x80

    movzbl (%ecx), %eax       # carica il byte letto in %al (azzerando il registro eax)
    cmpl $':', %eax           # se l'ultimo byte letto è ':', allora chiama la funzione che rimpiazza i due punti con un terminatore di stringa   
    je terminatore_crediti_esame_reg   
    jmp crediti_esame


# aggiunge un terminatore di stringa al buffer dei crediti dell'esame
terminatore_crediti_esame_reg:
    incl %esi
    movb $0, codice_crediti_esame_buffer(%esi) # aggiungo un terminatore di stringa (\0) al posto dei ':'
    jmp riga_successiva

# funzione che arriva a fine riga e si prepara per leggere la matricola
riga_successiva:

    xorl %esi, %esi           	
    xorl %edi, %edi      
    xorl %ecx, %ecx     	

    movl $3, %eax             	# syscall read
    movl fd_reg, %ebx
    leal buffer_lettura, %ecx
    movl $1, %edx
    int $0x80

    movzbl buffer_lettura, %eax
    cmpb $10, %al		        # 10 = \n
    je matricola_read_loop_reg	# appena trova '10' vai leggere la matricola
    jmp riga_successiva

# funzione che legge la matricola dal file registri
matricola_read_loop_reg:		# funzione che legge la matricola

    movl $3, %eax             # syscall read
    movl fd_reg, %ebx
    leal matricola_buffer(%esi), %ecx
    movl $1, %edx
    int $0x80

    cmpl $0, %eax
    jle close_and_exit_reg    # errore se non riesce a leggere il file

    movzbl (%ecx), %eax       # carica il byte letto in %al
    cmpl $':', %eax
    je rimozione_due_punti    # se l'ultimo byte letto è ':', allora chiama la funzione che rimpiazza i due punti con un terminatore di stringa

    incl %esi
    jmp matricola_read_loop_reg

# rimuove i due punti dalla matricola e aggiunge un terminatore di stringa (\0)
rimozione_due_punti:
    movb $0, matricola_buffer(%esi) # aggiungo un terminatore di stringa (\0) al posto dei ':'
    xorl %edi, %edi           	    # azzera l'indice del contenuto
    movb $':', esiti_buffer(%edi)   # inizializza il buffer degli esiti con un ':'
    incl %edi                       # incrementa l'indice del contenuto per il prossimo byte
    jmp esiti_read_loop

# funzione che legge gli esiti dal file registri e li salva nel buffer esiti_buffer
esiti_read_loop:
    movl $3, %eax             # syscall read
    movl fd_reg, %ebx
    leal esiti_buffer(%edi), %ecx
    movl $1, %edx
    int $0x80
    
    movzbl (%ecx), %eax       # carica il byte letto in %al
    
    cmpl $0, %eax
    je set_flag_fine_file_reg # errore se non riesce a leggere il file o raggiunge la fine del file
    jl close_and_exit_reg
    
    cmpl $10, %eax	          # se è uguale a \n allora chiama la funzione che apre anagrafica
    je funz_anagrafica
    
    incl %edi
    jmp esiti_read_loop

set_flag_fine_file_reg:
    movl $1, %edx
    movl %edx, flag_fine_file_reg # setta il flag che indica la fine del file 
    jmp funz_anagrafica
    
# funzione che pusha la matricola sullo stack e chiama la funzione carica_file_anagrafica per verificare se la matricola è presente nell'anagrafica
funz_anagrafica:		
    pushl $matricola_buffer
    call carica_file_anagrafica
    addl $4, %esp      		# pulisci lo stack da matricola buffer
    
    cmpl $1, %edx           # verifica se la matricola è presente, se lo è, allora va a funz_libretti
    je funz_libretti
    
    cmpl $0, %edx           # verifica se la matricola non è presente, se lo è, allora va a msg_err_matricola_non_presente
    je msg_err_matricola_non_presente
    

# funzione che pusha la matricola, il codice e i crediti dell'esame e gli esiti sullo stack e chiama la funzione carica_file_libretti
funz_libretti:
    pushl $matricola_buffer
    pushl $codice_crediti_esame_buffer
    pushl $esiti_buffer
    call carica_file_libretti
    addl $12, %esp      		# pulisci lo stack da matricola buffer, codice, crediti e esiti buffer
    xorl %esi, %esi           	# azzera l'indice della matricola

    movl flag_fine_file_reg, %edx # controlla se il flag di fine file è stato settato
    cmpl $1, %edx
    je close_and_exit_reg	# se il flag è 1, allora chiude il

    jmp set_per_prossima_matricola

# funzione che azzera i registri e si prepara a leggere la prossima matricola
set_per_prossima_matricola:
    # azzeriamo i seguenti registri
    xorl %eax, %eax
    xorl %edi, %edi           	# azzera l'indice del contenuto
    xorl %ecx, %ecx           	# azzera l'indice del buffer di lettura
    xorl %esi, %esi           	# azzera l'indice della matricola
    jmp matricola_read_loop_reg

# funzione che stampa 3 messaggi di errore concatenati se la matricola non è presente
msg_err_matricola_non_presente:
    movl $4, %eax
    movl $1, %ebx
    leal errore_matricola_non_presente_p1, %ecx
    movl errore_matricola_non_presente_p1_len, %edx
    int $0x80

    movl $4, %eax
    movl $1, %ebx
    movl $matricola_buffer, %ecx
    movl $8, %edx
    int $0x80


    movl $4, %eax
    movl $1, %ebx
    leal errore_matricola_non_presente_p2, %ecx
    movl errore_matricola_non_presente_p2_len, %edx
    int $0x80

    movl $1, %eax               # syscall exit
    movl $1, %ebx               # Codice di uscita 1 (errore)
    int $0x80

# funzione che chiude il file e ritorna al chiamante
close_and_exit_reg:
    movl $6, %eax
    movl fd_reg, %ebx
    int $0x80

    movl %ebp, %esp  # ripristina lo stack pointer
    popl %ebp
    ret

# funzione che gestisce l'errore di apertura del file registri
_error_open_reg:

    movl $4, %eax
    movl $1, %ebx
    leal errore_apertura_file_reg, %ecx
    movl errore_apertura_file_reg_len, %edx
    int $0x80
    
    # se l'apertura del file fallisce, allora termina il programma con codice di errore 1
    movl $1, %eax
    movl $1, %ebx
    int $0x80
    


