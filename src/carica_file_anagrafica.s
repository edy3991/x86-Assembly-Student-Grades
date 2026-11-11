/*

Questa funzione scarica dallo stack il parametro che contiene la matricola
letta da carica_file_reg e la salva in matricola_buffer_anagrafica.
successivamente apre il file data/anagrafica.txt in lettura e per ogni riga
confronta la matricola letta con quella passata come parametro.
se il file anagrafica esiste e contiene la matricola, la funzione
ritorna 1 e permette a carica_file_reg di continuare l'esecuzione.
se arriva a leggere il terminatore di stringa senza trovare la matricola,
allora ritorna 0 e carica_file_reg stampa un messaggio di errore.

*/

.section .data
    filename_ptr_fd_anagrafica: .asciz "data/anagrafica.txt"
    errore_apertura_file_anagrafica: .asciz "Errore nell'apertura del file registri.\n"
    errore_apertura_file_anagrafica_len: .long . - errore_apertura_file_anagrafica

.section .bss
    fd_anagrafica: .skip 4
    matricola_buffer_anagrafica: .skip 256
    matricola_buffer_reg: .skip 256
    buffer_lettura_anagrafica: .skip 1

.section .text
    .globl carica_file_anagrafica
    .type carica_file_anagrafica, @function

carica_file_anagrafica: 
    # prologo
    pushl %ebp			# per prassi si pusha ebp sullo stack così che poi venga recuperato
    movl %esp, %ebp		# ciò a cui punta esp, ora punta anche ebp
    

    movl 8(%ebp), %esi	# facciamo puntare ad esi l'inizio della matricola pushata sullo stack
    movl $matricola_buffer_reg, %edi # facciamo puntare ad edi l'inzio di dove salvare la matricola
    
# funzione che copia la matricola letta da carica_file_reg in matricola_buffer_reg
copy_loop_matricola_anagrafica_reg:

    movb (%esi), %al          # spostiamo il primo byte di esi in al
    movb %al, (%edi)          # ora copiamo al in edi che a sua volta lo salvera in matricola_buffer_reg
    cmpb $0, %al              # confronta se è terminatore
    je apertura_anagrafica
    incl %esi                      # incrementiamo gli indici
    incl %edi                     
    jmp copy_loop_matricola_anagrafica_reg # ripartiamo dall'inizio

# funzione che apre il file anagrafica.txt in lettura
apertura_anagrafica: # open(filename, O_RDONLY)
    
    movl $5, %eax
    movl $filename_ptr_fd_anagrafica, %ebx
    movl $0, %ecx
    int $0x80

    cmpl $0, %eax
    jl _error_open_anagrafica

    movl %eax, fd_anagrafica	# quando si apre un file, ad eax viene assegnato un intero che rappresenta il file descriptor, assegnamolo alla variabile fd_reg
    jmp azzeramento_anagrafica # partiamo a leggere la matricola

# funzione che azzera i registri e si prepara a leggere la prima matricola del file anagrafica
azzeramento_anagrafica:

    xorl %esi, %esi           	# indice matricola
    xorl %edi, %edi           	# indice contenuto
    jmp matricola_read_anagrafica_loop # riparte a leggere la matricola

# funzione che legge la matricola dal file anagrafica
matricola_read_anagrafica_loop:		# funzione che legge la matricola

    movl $3, %eax             # syscall read
    movl fd_anagrafica, %ebx
    leal matricola_buffer_anagrafica(%esi), %ecx
    movl $1, %edx
    int $0x80

    cmpl $0, %eax
    je matricola_non_presente_anagrafica
    jl close_and_exit_anagrafica

    movzbl (%ecx), %eax       # carica il byte letto in %al

    cmpl $':', %eax           # se l'ultimo byte letto è ':', allora chiama la funzione che rimuove i due punti dalla matricola
    je rimozione_due_punti_anagrafica

    incl %esi
    jmp matricola_read_anagrafica_loop

# funzione che rimuove i due punti dalla matricola aggiungendo un terminatore di stringa (\0) e poi setta i registri esi ed edi
# in modo che puntino all'inizio delle matricole da confrontare, una letta da carica_file_reg e l'altra letta da anagrafica(questa funzione)
rimozione_due_punti_anagrafica:

    movb $0, matricola_buffer_anagrafica(%esi) # aggiungo un terminatore di stringa (\0) al posto dei ':'

    # facciamo puntare ad esi ed edi l'inizio delle rispettive matricole
    movl $matricola_buffer_reg, %esi      # primo buffer
    movl $matricola_buffer_anagrafica, %edi # secondo buffer
    jmp confronto_matricole_loop_anagrafica # partiamo a confrontare le matricole

# funzione che confronta le matricole lette da carica_file_reg e anagrafica
confronto_matricole_loop_anagrafica:

    movb (%esi), %al                  # confrontiamo byte per byte le matricole
    movb (%edi), %bl                  
    cmpb %al, %bl                     
    jne diverse_anagrafica            # se sono diverse anche solo di un byte, allora le matricole sono diverse         

    cmpb $0, %al                      # se abbiamo raggiunto il terminatore di stringa, le matricole sono uguali   
    je uguali_anagrafica                        

    incl %esi
    incl %edi
    jmp confronto_matricole_loop_anagrafica

# funzione che gestisce il caso in cui le matricole sono diverse
# azzera i registri e riparte a leggere la matricola dal file anagrafica raggiungendo la fine della riga
diverse_anagrafica:
    # azzeriamo i seguenti registri
    xorl %eax, %eax
    xorl %esi, %esi           	
    xorl %edi, %edi           
    jmp fine_riga_anagrafica # riparte a leggere la matricola

# funzione che gestisce il caso in cui si raggiunge la fine della riga
fine_riga_anagrafica:
 
    movl $3, %eax                        # syscall read
    movl fd_anagrafica, %ebx
    leal buffer_lettura_anagrafica(%esi), %ecx
    movl $1, %edx
    int $0x80

    cmpl $0, %eax
    je matricola_non_presente_anagrafica

    movzbl (%ecx), %eax                    # carica il byte letto in %al

    cmpl $10, %eax
    je azzeramento_anagrafica    # se è uguale a \n allora chiama la funzione che apre anagrafica

    jmp fine_riga_anagrafica             # riparte a leggere la matricola

# funzione che gestisce il caso in cui le matricole sono uguali
# ritorna 1 (caricandolo in edx) e permette a carica_file_reg di continuare l'esecuzione
uguali_anagrafica:		
    movl $1, %edx
    jmp close_and_exit_anagrafica                                 # ritorna al chiamante e da il 'permesso' di scrivere su libretti

# funzione che gestisce il caso in cui la matricola non è presente nell'anagrafica
# ritorna 0 (caricandolo in edx) e permette a carica_file_reg di stampare un messaggio di errore
matricola_non_presente_anagrafica:			
    movl $0, %edx
    jmp close_and_exit_anagrafica                                 # ritorna al chiamante e da messaggio di errore

# funzione che chiude il file anagrafica e ritorna al chiamante
close_and_exit_anagrafica:
    movl $6, %eax
    movl fd_anagrafica, %ebx
    int $0x80

    movl %ebp, %esp
    popl %ebp
    ret

# funzione che gestisce l'errore di apertura del file anagrafica
_error_open_anagrafica:
    movl $4, %eax
    movl $1, %ebx
    leal errore_apertura_file_anagrafica, %ecx      # stampa il messaggio di errore
    movl errore_apertura_file_anagrafica_len, %edx
    int $0x80

    movl $1, %eax
    movl $1, %ebx
    int $0x80
    


