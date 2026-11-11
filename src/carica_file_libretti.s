/*

1° parte della funzione carica_file_libretti.s

Scarica dallo stack gli esiti, il codice e i crediti esame e la matricola e li copia
nei rispettivi buffer di registro.

2° parte della funzione carica_file_libretti.s

Apre il file data/libretti.txt in lettura 
e lo legge riga per riga. Se trova una riga con la matricola uguale a quella 
passata come parametro, aggiunge gli esiti e il codice crediti esame a 
quella riga. Poi continua a leggere il file fino alla fine cosi da 
caricare le matricole restanti nel file buffer. Una volta che ha finito di leggere il 
file, sovrascrive il file data/libretti.txt con il file buffer. Se arriva 
alla fine del file senza trovare la matricola, aggiunge la matricola a fine file.

*/


.section .data
    filename_ptr_fd_libretti: .asciz "data/libretti.txt"
    flag_aggiungi_matricola_fine_riga: .long 0
    flag_fine_file: .long 0
    errore_apertura_file_libretti: .asciz "Errore nell'apertura del file libretti.\n"
    errore_apertura_file_libretti_len: .long . - errore_apertura_file_libretti

.section .bss
    indice_file_buffer: .skip 4
    indice_riga_file_buffer: .skip 4
    fd_libretti: .skip 4
    matricola_buffer_libretti_reg: .skip 256
    matricola_buffer_libretti: .skip 256
    esiti_buffer_reg: .skip 256
    codice_crediti_esame_buffer_reg: .skip 256
    riga_file_buffer: .skip 1024
    file_buffer: .skip 4096

.section .text
    .globl carica_file_libretti
    .type carica_file_libretti, @function

carica_file_libretti:
    # prologo
    pushl %ebp			# per prassi si pusha ebp sullo stack così che poi venga recuperato
    movl %esp, %ebp		# ciò a cui punta esp, ora punta anche ebp
    
    # settiamo i registri per la copia degli esiti
    movl 8(%ebp), %esi	# facciamo puntare ad esi l'inizio degli esiti pushata sullo stack precedentemente
    movl $esiti_buffer_reg, %edi # facciamo puntare ad edi l'inzio di dove salvare gli esiti
    
# funzione che copia gli esiti letti da carica_file_reg in esiti_buffer_reg
copy_loop_esiti_buffer_reg:
    movb (%esi), %al               # spostiamo il primo byte di esi in al
    movb %al, (%edi)               # ora copiamo al in edi che a sua volta lo salvera in esiti_buffer_reg
    cmpb $0, %al                   # confronta se è terminatore
    je set_codice_crediti
    incl %esi                      # incrementiamo gli indici
    incl %edi                     
    jmp copy_loop_esiti_buffer_reg # ripartiamo dall'inizio

# settiamo i registri per la copia del codice crediti esame
set_codice_crediti:
    xorl %esi, %esi           	# azzeriamo l'indice della matricola
    xorl %edi, %edi           	# azzeriamo l'indice del contenuto
    movl 12(%ebp), %esi         # il contenuto si trova a 12(%ebp) (il terzo parametro passato alla funzione)
    movl $codice_crediti_esame_buffer_reg, %edi # facciamo puntare ad edi l'inzio di dove salvare codice_crediti_esame_buffer_reg
    jmp copy_loop_codice_crediti_esame_reg

# funzione che copia il codice crediti esame letto da carica_file_reg in codice_crediti_esame_buffer_reg
copy_loop_codice_crediti_esame_reg:
    movb (%esi), %al          # spostiamo il primo byte di esi in al
    movb %al, (%edi)          # ora copiamo al in edi che a sua volta lo salvera in matricola_buffer_reg
    cmpb $0, %al              # confronta se è terminatore
    je set_matricola
    incl %esi                 # incrementiamo gli indici
    incl %edi                     
    jmp copy_loop_codice_crediti_esame_reg # ripartiamo dall'inizio

# settiamo i registri per la copia della matricola
set_matricola:
    xorl %esi, %esi           	              # azzeriamo l'indice della matricola
    xorl %edi, %edi           	              # azzeriamo l'indice del contenuto
    movl 16(%ebp), %esi                       # il contenuto si trova a 16(%ebp) (il quarto parametro passato alla funzione)
    movl $matricola_buffer_libretti_reg, %edi # facciamo puntare ad edi l'inzio di dove salvare la matricola
    jmp copy_loop_matricola_libretti_reg

# funzione che copia la matricola letta da carica_file_reg in matricola_buffer_libretti_reg
copy_loop_matricola_libretti_reg:
    movb (%esi), %al          # spostiamo il primo byte di esi in al
    movb %al, (%edi)          # ora copiamo al in edi che a sua volta lo salvera in matricola_buffer_libretti_reg
    cmpb $0, %al              # confronta se è terminatore
    je apertura_libretti
    incl %esi                      # incrementiamo gli indici
    incl %edi                     
    jmp copy_loop_matricola_libretti_reg # ripartiamo dall'inizio

# funzione che apre il file data/libretti.txt in lettura
apertura_libretti:
    # open(filename, O_RDONLY)
    movl $0, indice_file_buffer # inizializziamo l'indice del file buffer a 0 (per sicurezza)

    movl $5, %eax
    movl $filename_ptr_fd_libretti, %ebx
    movl $0, %ecx
    int $0x80

    cmpl $0, %eax
    jl _error_open_libretti

    movl %eax, fd_libretti	# quando si apre un file, ad eax viene assegnato un intero che rappresenta il file descriptor, assegnamolo alla variabile fd_reg

    # per convenzione azzeriamo i registri esi e edi
    xorl %esi, %esi           	
    xorl %edi, %edi           	
    xorl %eax, %eax   
    jmp azzera_riga_file_buffer        	

# funzione che azzera la variabile riga_file_buffer così da non avere dati spazzatura
azzera_riga_file_buffer:
    movb %al, riga_file_buffer(%edi)
    incl %edi
    cmpl $1024, %edi
    jl azzera_file_buffer
    jmp set_azzera_file_buffer

set_azzera_file_buffer:
    xorl %eax, %eax
    xorl %edi, %edi
    jmp azzera_file_buffer

# funzione che azzera il file_buffer cosi da non avere dati spazzatura
azzera_file_buffer:
    movb %al, file_buffer(%edi)
    incl %edi
    cmpl $4096, %edi
    jl azzera_file_buffer
    jmp set_copy_file_buffer

set_copy_file_buffer:
    # azzeriamo l'indice della riga corrente
    xorl %eax, %eax
    xorl %esi, %esi           	
    jmp copy_file_buffer

# funzione che legge il file data/libretti.txt riga per riga
copy_file_buffer:
    movl $3, %eax               # syscall read
    movl fd_libretti, %ebx
    leal riga_file_buffer(%esi), %ecx
    movl $1, %edx 
    int $0x80

    cmpl $0, %eax               # se il numero di byte letti è 0, allora abbiamo raggiunto la fine del file (EOF)
    je set_flag_fine_file     
    jl _error_open_libretti     # errore se non riesce a leggere il file

    
    cmpb $0, (%ecx)
    je set_flag_fine_file       # se il byte letto è '\0', è un file malformato o finito

    movzbl (%ecx), %eax

    cmpb $'\n', %al
    je fine_riga_trovata

    incl %esi
    jmp copy_file_buffer

# funzione che gestisce il caso in cui troviamo il flag di fine file
set_flag_fine_file:
    # controlliamo se il flag di fine file è stato impostato
    movl $1, %eax
    movl %eax, flag_fine_file   # impostiamo il flag di fine file a 1

    xorl %esi, %esi           	# azzeriamo l'indice della matricola
    xorl %edi, %edi           	# azzeriamo l'indice del conten

    cmpb $0, flag_aggiungi_matricola_fine_riga
    jne close_and_exit_libretti_and_riapri # se il flag di aggiunta matricola a fine riga è 0, allora chiudiamo il file e ritorniamo al chiamante
    je set_matricola_fine_file # altrimenti, aggiungiamo la matricola a fine file

# funzione che gestisce il caso in cui troviamo una riga completa
fine_riga_trovata:
    incl %esi
    movb $0, riga_file_buffer(%esi)    # aggiungiamo un terminatore di stringa (\0) al buffer della riga corrente
    movl %esi, indice_riga_file_buffer # salviamo l'indice della riga corrente
    xorl %esi, %esi           	       # azzera l'indice della matricola
    xorl %edi, %edi           	       # azzera l'indice del contenuto
    jmp copy_matricola_file_buffer_loop

# funzione che copia la matricola da riga_file_buffer al buffer delle matricole
copy_matricola_file_buffer_loop:
    movb riga_file_buffer(%esi), %al     # prendi un byte da riga_buffer_file
    movb %al, matricola_buffer_libretti(%edi)
    cmpb $' ', %al                       # finché non trovi lo spazio ' '
    je rimozione_spazio_libretti
    incl %esi
    incl %edi
    jmp copy_matricola_file_buffer_loop

rimozione_spazio_libretti:
    movb $0, matricola_buffer_libretti(%edi) # aggiungo un terminatore di stringa (\0) al posto dello spazio ' '

    movl $matricola_buffer_libretti_reg, %esi            # primo buffer
    movl $matricola_buffer_libretti, %edi                # secondo buffer

# funzione che confronta le matricole lette da carica_file_reg e quelle lette da libretti
confronto_matricole_loop_libretti:
    movb (%esi), %al                  
    movb (%edi), %bl                  
    cmpb %al, %bl
    jne diverse_libretti                     

    cmpb $0, %al
    je uguali_libretti                        

    incl %esi
    incl %edi
    jmp confronto_matricole_loop_libretti

### GESTIONE DEL CASO IN CUI TROVA UNA MATRICOLA DIVERSA
diverse_libretti:
    # azzeriamo i seguenti registri
    xorl %eax, %eax
    xorl %ebx, %ebx        
    xorl %ecx, %ecx 	
    xorl %edi, %edi
    xorl %esi, %esi           	    
    jmp set_salva_file_buffer_diverse # se le matricole sono diverse, continuiamo a leggere il file

# funzione che setta i registri per il salvataggio del file buffer
set_salva_file_buffer_diverse:
    movl $riga_file_buffer, %esi
    movl indice_file_buffer, %ecx     # ripristiniamo l'indice della riga corrente
    movl $file_buffer, %edi
    addl %ecx, %edi
    jmp salva_file_buffer

### GESTIONE DEL CASO IN CUI TROVA UNA MATRICOLA UGUALE
uguali_libretti:
    xorl %edi, %edi           	            # azzeriamo l'indice del contenuto
    movl $1, %edx                           # settiamo il flag per non aggiungere la matricola a fine riga  
    movl %edx, flag_aggiungi_matricola_fine_riga
    movl indice_riga_file_buffer, %ecx      # ripristiniamo l'indice della riga corrente                        
    movl $riga_file_buffer, %edi            # facciamo puntare ad edi la fine della riga dove salvare il codice crediti esame e gli esiti
    addl %ecx, %edi                      
    jmp set_fine_riga                       # se è uguale a \n, allora abbiamo trovato una riga completa

# funzione che setta i registri per il salvataggio del file buffer
set_fine_riga:
    decl %edi                                       # decrementa l'indice di file_buffer per non sovrascrivere il terminatore di stringa
    cmpb $10, (%edi)                                
    jne aggiungi_codice_crediti_fine_riga           # se non è un terminatore di riga, allora aggiungiamo il codice crediti esame e gli esiti
    movb $';', (%edi)                               # aggiungiamo il ';' come separatore tra matricola e codice crediti esame
    xorl %esi, %esi 
    movl $codice_crediti_esame_buffer_reg, %esi     # facciamo puntare ad esi l'inzio da dove salvare il codice_crediti_esame_buffer_reg
    jmp aggiungi_codice_crediti_fine_riga                      

# funzione che aggiunge il codice crediti esame e gli esiti a fine riga
aggiungi_codice_crediti_fine_riga:
    movb (%esi), %al                   # prendi un byte da codice_crediti_esame_buffer_reg
    cmpb $0, %al                       # confronta se è terminatore
    je set_codice_crediti_fine_riga
    incl %edi                          # incrementa l'indice di riga_file_buffer
    movb %al, (%edi)                   # copia il byte in riga_file_buffer
    incl %esi                          # incrementa l'indice di codice_crediti_esame_buffer_reg
    jmp aggiungi_codice_crediti_fine_riga

set_codice_crediti_fine_riga:
    xorl %esi, %esi                    # azzeriamo l'indice
    movl $esiti_buffer_reg, %esi       # facciamo puntare ad esi l'inzio da dove salvare gli esiti

# funzione che aggiunge gli esiti a fine riga
aggiungi_esiti_fine_riga:
    movb (%esi), %al                   # prendi un byte da esiti_buffer_reg
    movb %al, (%edi)                   # copia il byte in riga_file_buffer
    cmpb $0, %al                       # confronta se è terminatore
    je set_salva_file_buffer_uguali
    incl %edi                          # incrementa l'indice di riga_file_buffer
    incl %esi                          # incrementa l'indice di esiti_buffer_reg
    jmp aggiungi_esiti_fine_riga

# funzione che setta i registri per il salvataggio del file buffer
set_salva_file_buffer_uguali:
    xorl %esi, %esi       
    xorl %edi, %edi                  

    movl $riga_file_buffer, %esi
    movl indice_file_buffer, %ecx      # ripristiniamo l'indice della riga corrente
    movl $file_buffer, %edi
    addl %ecx, %edi
    jmp salva_file_buffer

### SALVATAGGIO DEL FILE BUFFER E RESET
salva_file_buffer:
    movb (%esi), %al     # prendi un byte da riga_buffer_file
    movb %al, (%edi)     # ora copiamo al in edi ovvero in file_buffer
    cmpb $0, %al         # confronta se è terminatore 
    je reset
    incl %esi
    incl %edi
    jmp salva_file_buffer

# funzione che resetta i registri e prepara il buffer per la prossima riga da leggere
reset:

    xorl %eax, %eax                       # azzeriamo eax per sicurezza
    xorl %esi, %esi                       # azzeriamo edi per sicurezza

    movl %edi, %ecx
    subl $file_buffer, %ecx               # calcola offset relativo
    movl %ecx, indice_file_buffer         # salva l’indice reale (non l’indirizzo)
    
    movl flag_fine_file, %eax
    cmpl $1, %eax
    je close_and_exit_libretti_and_riapri # se il flag di fine file è stato impostato, chiudiamo il file e usciamo
    
    jmp copy_file_buffer                  # ripartiamo a leggere il file da dove eravamo rimasti



### GESTIONE DEL CASO IN CUI NON TROVA UNA MATRICOLA UGUALE
set_matricola_fine_file:
    # aggiungiamo la matricola a fine file 
    xorl %esi, %esi           	                # azzeriamo l'indice della matricola
    xorl %edi, %edi           	                # azzeriamo l'indice del contenuto
    movl $matricola_buffer_libretti_reg, %esi   # ripristiniamo l'indice della riga corrente                

    movl indice_file_buffer, %ebx               # ripristiniamo l'indice del file buffer
    movl $file_buffer, %edi
    addl %ebx, %edi                             # aggiungiamo l'indice del file buffer al buffer

    jmp aggiungi_matricola_fine_file_buffer

aggiungi_matricola_fine_file_buffer:
    movb (%esi), %al                   # prendi un byte da matricola_buffer_libretti_reg
    movb %al, (%edi)                   # copia il byte in file_buffer
    cmpb $0, %al                       # confronta se è terminatore
    je set_codice_crediti_fine_file
    incl %edi                          # incrementa l'indice di file_buffer
    incl %esi                          # incrementa l'indice di matricola_buffer_libretti_reg
    jmp aggiungi_matricola_fine_file_buffer

set_codice_crediti_fine_file:
    xorl %esi, %esi                    # azzeriamo l'indice
    movl $codice_crediti_esame_buffer_reg, %esi            # facciamo puntare ad edi l'inzio da dove salvare il codice_crediti_esame_buffer_reg
    movb $' ', (%edi)                  # primo buffer che si dovrà scrivere nel file_buffer. Ricorda che %edi -> codice_crediti_esame_buffer_reg
    incl %edi                          # incrementa l'indice di file_buffer
    jmp aggiungi_codice_crediti_fine_file

aggiungi_codice_crediti_fine_file:
    movb (%esi), %al                   # prendi un byte da matricola_buffer_libretti_reg
    movb %al, (%edi)                   # copia il byte in file_buffer
    cmpb $0, %al                       # confronta se è terminatore
    je set_esiti_fine_file
    incl %edi                          # incrementa l'indice di file_buffer
    incl %esi                          # incrementa l'indice di matricola_buffer_libretti_reg
    jmp aggiungi_codice_crediti_fine_file

set_esiti_fine_file:
    xorl %esi, %esi                    # azzeriamo l'indice
    movl $esiti_buffer_reg, %esi       # facciamo puntare ad edi l'inzio da dove salvare gli esiti
    incl %esi                          # incrementa l'indice di esiti_buffer_reg cosi da skippare i ':'
    jmp aggiungi_esiti_fine_file
    
aggiungi_esiti_fine_file:
    movb (%esi), %al                   # prendi un byte da matricola_buffer_libretti_reg
    movb %al, (%edi)                   # copia il byte in file_buffer
    cmpb $0, %al                       # confronta se è terminatore
    je salva_indice_finale
    incl %edi                          # incrementa l'indice di file_buffer
    incl %esi                          # incrementa l'indice di matricola_buffer_libretti_reg
    jmp aggiungi_esiti_fine_file


salva_indice_finale:

    movl %edi, %ecx
    subl $file_buffer, %ecx               # calcola offset relativo
    movl %ecx, indice_file_buffer         # salva l’indice reale (non l’indirizzo)

    jmp close_and_exit_libretti_and_riapri # chiude il file e ritorna al chiamante



# funzione che chiude il file in modalità lettura e chiama la funzione che lo apre in modalità scrittura
close_and_exit_libretti_and_riapri:
    movl $6, %eax
    movl fd_libretti, %ebx
    int $0x80

    jmp sovrascrittura_file_libretti

# funzione che sovrascrive il file data/libretti.txt con il file buffer
sovrascrittura_file_libretti:

    movl $5, %eax                          # syscall open
    movl $filename_ptr_fd_libretti, %ebx
    movl $1, %ecx                          # O_WRONLY
    int $0x80

    movl $4, %eax                          # syscall write
    movl fd_libretti, %ebx
    movl $file_buffer, %ecx
    movl indice_file_buffer, %edx          # indice_file_buffer contiene la lunghezza del file buffer
    int $0x80

    jmp close_and_exit_libretti            # jumpa alla funzione che chiude il file e ritorna al chiamante

# funzione che chiude il file e ritorna al chiamante
close_and_exit_libretti:

    movl $0, flag_fine_file                    # resetta il flag di fine file a 0
    movl $0, flag_aggiungi_matricola_fine_riga # resetta il flag di aggiunta matricola a fine riga a 0

    movl $6, %eax
    movl fd_libretti, %ebx
    int $0x80

    movl %ebp, %esp
    popl %ebp
    ret

# funzione che gestisce l'errore di apertura del file libretti
_error_open_libretti:
    movl $4, %eax
    movl $1, %ebx
    leal errore_apertura_file_libretti, %ecx      # stampa il messaggio di errore
    movl errore_apertura_file_libretti_len, %edx
    int $0x80

    movl $1, %eax
    movl $1, %ebx
    int $0x80
