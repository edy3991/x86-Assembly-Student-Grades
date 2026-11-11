/*
Questa funzione scarica dallo stack il parametro che contiene la matricola
letta da carica_file_reg e la salva in matricola_buffer_anagrafica.
successivamente apre il file data/anagrafica.txt in lettura e per ogni riga
confronta la matricola letta con quella passata come parametro.
Se il file anagrafica esiste e contiene la matricola, la funzione
ritorna 1 e permette a carica_file_reg di continuare l'esecuzione.
se arriva a leggere il terminatore di stringa senza trovare la matricola,
allora ritorna 0 e carica_file_reg stampa un messaggio di errore.
*/




.section .data
    filename_ptr_fd_anagrafica_menu: .asciz "data/anagrafica.txt"
    errore_apertura_file_anagrafica_menu: .asciz "Errore nell'apertura del file registri.\n"
    errore_apertura_file_anagrafica_len_menu: .long . - errore_apertura_file_anagrafica_menu

.section .bss
    .lcomm fd_anagrafica_menu, 4
    .lcomm riga_buffer_anagrafica, 256
    .lcomm matricola_buffer_anagrafica_menu, 256
    .lcomm matricola_buffer_reg_menu, 256

    .globl nome_cognome_buffer_anagrafica
    .lcomm nome_cognome_buffer_anagrafica, 256

    .lcomm flag_fine_file_anagrafica_menu, 4

.section .text
    .globl carica_file_anagrafica_menu
    .type carica_file_anagrafica_menu, @function

carica_file_anagrafica_menu: 
    # prologo
    pushl %ebp			# per prassi si pusha ebp sullo stack così che poi venga recuperato
    movl %esp, %ebp		# ciò a cui punta esp, ora punta anche ebp

    xorl %esi, %esi           	# azzeriamo l'indice della matricola
    xorl %edi, %edi           	# azzeriamo l'indice del buffer
    

    movl 8(%ebp), %esi	                  # facciamo puntare ad esi l'inizio della matricola pushata sullo stack
    movl $matricola_buffer_reg_menu, %edi # facciamo puntare ad edi l'inzio di dove salvare la matricola
    
# funzione che copia la matricola letta da carica_file_reg in matricola_buffer_reg
copy_loop_matricola_anagrafica_reg_menu:

    movb (%esi), %al          # spostiamo il primo byte di esi in al
    movb %al, (%edi)          # ora copiamo al in edi che a sua volta lo salvera in matricola_buffer_reg
    cmpb $0, %al              # confronta se è terminatore
    je apertura_anagrafica_menu
    incl %esi                                   # incrementiamo gli indici
    incl %edi                     
    jmp copy_loop_matricola_anagrafica_reg_menu # ripartiamo dall'inizio

# funzione che apre il file anagrafica.txt in lettura
apertura_anagrafica_menu: # open(filename, O_RDONLY)
    
    movl $5, %eax
    movl $filename_ptr_fd_anagrafica_menu, %ebx
    movl $0, %ecx
    int $0x80

    cmpl $0, %eax
    jl _error_open_anagrafica_menu

    movl %eax, fd_anagrafica_menu	# quando si apre un file, ad eax viene assegnato un intero che rappresenta il file descriptor, assegnamolo alla variabile fd_reg
    jmp azzeramento_anagrafica_menu # partiamo a leggere la matricola

# funzione che azzera i registri e si prepara a leggere la prima matricola del file anagrafica
azzeramento_anagrafica_menu:

    xorl %esi, %esi           	# indice matricola
    xorl %edi, %edi           	# indice contenuto
    jmp riga_read_anagrafica_loop # riparte a leggere la matricola

# funzione che legge la matricola dal file anagrafica
riga_read_anagrafica_loop:		# funzione che legge la matricola

    movl $3, %eax               # syscall read
    movl fd_anagrafica_menu, %ebx
    leal riga_buffer_anagrafica(%esi), %ecx
    movl $1, %edx
    int $0x80

    cmpl $0, %eax
    je matricola_non_presente_anagrafica_menu # se non riesce a leggere il file, allora chiude e ritorna al chiamante
    jl close_and_exit_anagrafica_menu

    movzbl (%ecx), %eax        # carica il byte letto in %al

    cmpl $'\n', %eax           # se l'ultimo byte letto è ':', allora chiama la funzione che rimuove i due punti dalla matricola
    je fine_riga_anagrafica_menu

    incl %esi
    jmp riga_read_anagrafica_loop

# funzione che rimuove i due punti dalla matricola aggiungendo un terminatore di stringa (\0) e prepa i registri esi ed edi
fine_riga_anagrafica_menu:

    incl %esi
    movb $0, riga_buffer_anagrafica(%esi) # aggiungo un terminatore di stringa (\0) dopo '\n'

    xorl %esi, %esi           	# azzeriamo i registri per la lettura della matricola
    xorl %edi, %edi           	# azzeriamo i registri per la lettura della matricola
    movl $riga_buffer_anagrafica, %esi
    movl $matricola_buffer_anagrafica_menu, %edi # facciamo puntare ad edi l'inzio di dove salvare la matricola
    jmp copy_loop_matricola_anagrafica_menu      # riparte a copiare la matricola letta da riga_read_anagrafica_loop in matricola_buffer_reg_menu
   
# copia la matricola letta da riga_read_anagrafica_loop in matricola_buffer_reg_menu
copy_loop_matricola_anagrafica_menu:

    movb (%esi), %al                        # spostiamo il primo byte di esi in al
    movb %al, (%edi)                        # ora copiamo al in edi che a sua volta lo salvera in matricola_buffer_reg
    cmpb $':', %al                          # confronta se è terminatore
    je rimozione_due_punti_anagrafica_menu  # se è ':', allora chiama la funzione che rimuove i due punti dalla matricola
    incl %esi                               # incrementiamo gli indici
    incl %edi                     
    jmp copy_loop_matricola_anagrafica_menu # ripartiamo dall'inizio

# funzione che rimuove i due punti dalla matricola aggiungendo un terminatore di stringa (\0)
rimozione_due_punti_anagrafica_menu:

    movb $0, (%edi) # aggiungo un terminatore di stringa (\0) al posto dei ':'
    incl %esi       # incrementiamo l'indice della riga

    xorl %edi, %edi           	               # azzeriamo il registro edi
    movl $nome_cognome_buffer_anagrafica, %edi # secondo buffer
    jmp copy_loop_nome_cognome_anagrafica_menu # partiamo a confrontare le matricole

# funzione che copia il nome e cognome dello studente dalla riga letta in nome_cognome_buffer_anagrafica
copy_loop_nome_cognome_anagrafica_menu:

    movb (%esi), %al          # spostiamo il primo byte di esi in al
    movb %al, (%edi)          # ora copiamo al in edi che a sua volta lo salvera in nome_cognome_buffer_anagrafica

    cmpb $'\n', %al           # se l'ultimo byte letto è '\n', allora chiama la funzione che apre anagrafica
    je rimozione_a_capo_anagrafica_menu

    incl %esi                                  # incrementiamo gli indici
    incl %edi                     
    jmp copy_loop_nome_cognome_anagrafica_menu # ripartiamo dall'inizio

# rimuove il carattere di a capo dalla fine della riga e termina la stringa
rimozione_a_capo_anagrafica_menu:

    movb $0, (%edi) # aggiungo un terminatore di stringa (\0) al posto del '\n'

    xorl %esi, %esi           	# azzeriamo i registri per la lettura della matricola
    xorl %edi, %edi           	# azzeriamo i registri per la lettura della matricola

    movl $matricola_buffer_reg_menu, %esi        # facciamo puntare ad esi l'inizio della matricola letta da stdin
    movl $matricola_buffer_anagrafica_menu, %edi # facciamo puntare ad edi la matricola del file anagrafica

    jmp confronto_matricole_loop_anagrafica_menu # parte a confrontare le matricole

# funzione che confronta le matricole lette da carica_file_reg e anagrafica
confronto_matricole_loop_anagrafica_menu:

    movb (%esi), %al                  
    movb (%edi), %bl                  
    cmpb %al, %bl                     # confrontiamo byte per byte le matricole
    jne diverse_anagrafica_menu       # se cambiano anche solo un byte, allora le matricole sono diverse    

    cmpb $0, %al                      # se abbiamo raggiunto il terminatore di stringa, le matricole sono uguali   
    je uguali_anagrafica_menu                        

    incl %esi
    incl %edi
    jmp confronto_matricole_loop_anagrafica_menu

# funzione che gestisce il caso in cui le matricole sono diverse
# azzera i registri e riparte a leggere la matricola dal file anagrafica raggiungendo la fine della riga
diverse_anagrafica_menu:
    # azzeriamo i seguenti registri
    xorl %eax, %eax
    xorl %esi, %esi           	
    xorl %edi, %edi           
    jmp check_fine_file_anagrafica_menu # riparte a leggere la matricola

# funzione che gestisce il caso in cui si raggiunge la fine della riga
check_fine_file_anagrafica_menu:

    cmpl $1, flag_fine_file_anagrafica_menu   # controlla se siamo alla fine del file anagrafica
    je matricola_non_presente_anagrafica_menu # se siamo alla fine del file anagrafica, allora la matricola non è presente

    xorl %eax, %eax           	
    xorl %esi, %esi           	
    xorl %edi, %edi           	
    jmp azzeramento_riga_anagrafica_menu      

# azzeramento della riga letta dal file anagrafica
azzeramento_riga_anagrafica_menu:

    movb %al, riga_buffer_anagrafica(%edi)
    incl %edi
    cmpl $256, %edi
    je set_azzeramento_matricola_anagrafica_menu # se non abbiamo raggiunto la fine della riga, allora continua a leggere
    jmp azzeramento_riga_anagrafica_menu
 
# funzione che azzera i registri e si prepara ad azzerare la matricola
set_azzeramento_matricola_anagrafica_menu:

    xorl %esi, %esi           	# azzeriamo i registri per la lettura della matricola
    xorl %edi, %edi           	# azzeriamo i registri per la lettura della matricola
    jmp azzeramento_matricola_anagrafica_menu # riparte a leggere la matricola

# funzione che azzera la matricola letta dal file anagrafica
azzeramento_matricola_anagrafica_menu:

    movb %al, matricola_buffer_anagrafica_menu(%edi)
    incl %edi
    cmpl $256, %edi
    je set_azzeramento_nome_cognome_anagrafica_menu
    jmp azzeramento_matricola_anagrafica_menu

# funzione che azzera i registri e si prepara ad azzerare il nome e cognome
set_azzeramento_nome_cognome_anagrafica_menu:

    xorl %esi, %esi           	# azzeriamo i registri per la lettura della matricola
    xorl %edi, %edi           	# azzeriamo i registri per la lettura della matricola
    jmp azzeramento_nome_cognome_anagrafica_menu # riparte a leggere la matricola

# funzione che azzera il nome e cognome dello studente
azzeramento_nome_cognome_anagrafica_menu:   

    movb %al, nome_cognome_buffer_anagrafica(%edi)
    incl %edi
    cmpl $256, %edi
    je riga_read_anagrafica_loop
    jmp azzeramento_nome_cognome_anagrafica_menu


# funzione che gestisce il caso in cui le matricole sono uguali
# ritorna 1 (caricandolo in edx) e permette a carica_file_reg di continuare l'esecuzione
uguali_anagrafica_menu:		
    movl $1, %edx
    jmp close_and_exit_anagrafica_menu   # ritorna al chiamante e da il 'permesso' di scrivere su libretti

# funzione che gestisce il caso in cui la matricola non è presente nell'anagrafica
# ritorna 0 (caricandolo in edx) e permette a carica_file_reg di stampare un messaggio di errore
matricola_non_presente_anagrafica_menu:			
    movl $0, %edx
    jmp close_and_exit_anagrafica_menu   # ritorna al chiamante e da messaggio di errore

# funzione che chiude il file anagrafica e ritorna al chiamante
close_and_exit_anagrafica_menu:
    movl $6, %eax
    movl fd_anagrafica_menu, %ebx
    int $0x80

    movl %ebp, %esp
    popl %ebp
    ret

# funzione che gestisce l'errore di apertura del file anagrafica
_error_open_anagrafica_menu:
    movl $4, %eax
    movl $1, %ebx
    leal errore_apertura_file_anagrafica_menu, %ecx      # stampa il messaggio di errore
    movl errore_apertura_file_anagrafica_len_menu, %edx
    int $0x80

    movl $1, %eax
    movl $1, %ebx
    int $0x80
    


