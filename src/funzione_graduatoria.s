
/*
Funzione che calcola la graduatoria degli studenti in base alla media ponderata degli esami sostenuti.
Inizia con l'apertura del file "libretti.txt", legge le matricole e gli esiti degli esami.
Calcola la media ponderata e la somma dei crediti, recupera il nome e cognome dello studente dal file anagrafica,
che è una funzione che viene usata in 2 contesti diversi ma con lo stesso scopo. Infine stampa la graduatoria su sdout.
*/

.extern nome_cognome_buffer_anagrafica

.section .data
    filename_ptr_fd_libretti: .asciz "data/libretti.txt"
    flag_fine_file: .long 0
    errore_apertura_file_libretti: .asciz "Errore nell'apertura del file libretti.\n"
    errore_apertura_file_libretti_len: .long . - errore_apertura_file_libretti
    errore_strano_matricola_non_presente: .asciz "Per qualche motivo strano la matricola non è presente nel file anagrafica\n"
    errore_strano_matricola_non_presente_len: .long . - errore_strano_matricola_non_presente
    errore_lettura_file_libretti: .asciz "Errore nella lettura del file libretti.\n"
    errore_lettura_file_libretti_len: .long . - errore_lettura_file_libretti

    somma_pesi_4: .long 18
    somma_crediti_x_studente: .long 0
    somma_esiti_ponderata_4: .long 0
    esito_ponderato_4: .long 0
    peso_esito_4: .long 0
    contatore_due_punti_4: .long 0
    decina_unita_4: .long 10
    media_ponderata_4: .long 0
    lunghezza_graduatoria_buffer: .long 0

.section .bss
    indice_graduatoria_buffer: .skip 4
    indice_riga_file_buffer: .skip 4
    fd_libretti: .skip 4
    matricola_buffer_libretti_menu_4: .skip 256
    esiti_buffer_reg: .skip 256
    codice_crediti_esame_buffer_reg: .skip 256
    riga_file_buffer_menu: .skip 1024
    graduatoria_buffer: .skip 4096
    buffer_itoa_somma_crediti_4: .skip 4
    buffer_itoa_media_pond_4: .skip 4

.section .text
    .globl funzione_graduatoria
    .type funzione_graduatoria, @function

funzione_graduatoria:
    # prologo
    pushl %ebp			# per prassi si pusha ebp sullo stack così che poi venga recuperato
    movl %esp, %ebp		# ciò a cui punta esp, ora punta anche ebp
    jmp apertura_libretti_4

# apertura del file libretti.txt in lettura
apertura_libretti_4:
    movl $0, indice_graduatoria_buffer # azzera l'indice del buffer graduatoria

    movl $5, %eax
    movl $filename_ptr_fd_libretti, %ebx
    movl $0, %ecx
    int $0x80

    # se l'apertura del file fallisce, allora va a _error_open_libretti
    cmpl $0, %eax
    jl _error_open_libretti

    # salviamo il file descriptor in fd_libretti
    movl %eax, fd_libretti
    xorl %esi, %esi            # azzeriamo esi per usarlo come indice
    xorl %edi, %edi            # azzeriamo edi per usarlo come indice

    xorl %eax, %eax            # azzeriamo eax per usarlo come indice

    jmp azzera_riga_file_buffer_menu

# funzione che azzera il buffer della riga del file
azzera_riga_file_buffer_menu:
    movb %al, riga_file_buffer_menu(%edi)
    incl %edi
    cmpl $1024, %edi
    jl azzera_riga_file_buffer_menu
    jmp loop_read_libretti_4

# funzione che legge il file libretti.txt
loop_read_libretti_4:
    # lettura del file libretti.txt
    movl $3, %eax                              # syscall read
    movl fd_libretti, %ebx                     # file descriptor del file libretti
    leal riga_file_buffer_menu(%esi), %ecx     # indirizzo del buffer dove leggere
    movl $1, %edx                              # dimensione del buffer
    int $0x80

    cmpl $0, %eax                              # se il numero di byte letti è 0, allora siamo alla fine del file
    je fine_file_libretti
    jl _error_read_libretti_4

    cmpl $'\n', (%ecx)                         # controlla se il primo byte letto è un newline
    je set_riga_libretti_4

    incl %esi
    jmp loop_read_libretti_4

# funzione che gestisce la fine della riga del file libretti.txt
set_riga_libretti_4:
    # processa la riga letta
    incl %esi
    movb $0, riga_file_buffer_menu(%esi)         # termina la riga con un null byte
    xorl %esi, %esi
    xorl %edi, %edi

    movl $riga_file_buffer_menu, %esi            # puntatore al buffer della riga
    movl $matricola_buffer_libretti_menu_4, %edi # puntatore al buffer della matricola

    jmp copy_matricola_riga_libretti_4

# funzione che copia la matricola dalla riga del file libretti.txt al buffer matricola_buffer_libretti_menu_4
copy_matricola_riga_libretti_4:
    # processa la riga corrente
    movb (%esi), %al # carica il primo byte della riga
    movb %al, (%edi)
    cmpb $' ', %al
    je fine_copy_matricola

    incl %esi 
    incl %edi
    jmp copy_matricola_riga_libretti_4

# fine della copia della matricola
fine_copy_matricola:
    movb $0, (%edi) # termina la matricola con un null byte

    xorl %edi, %edi # azzera edi per usarlo come indice del buffer

    jmp leggi_esiti_4

# funzione che legge gli esiti degli esami dalla riga del file libretti.txt, i crediti vengono gestiti successivamente
leggi_esiti_4:

    movb (%esi), %al                   # prendi un byte da risultati_buffer
    incl %esi                          # incrementa l'indice di risultati_buffer
    
    cmpb $':', %al                     # confronta se è ':'
    je verifica_peso_4                 # se lo è, significa che potrebbe esserci il peso dell'esito
    jmp leggi_esiti_4

# funzione che verifica se la variabile peso_esito_2 è stata settata
verifica_peso_4:

    cmpl $0, peso_esito_4              # se la variabile è 0, allora non è stata settata e bisogna darle un valore
    jne verifica_due_punti_4

    movzbl (%esi), %eax                # carica il byte successivo in %eax
    cmpl $'6', %eax                    # si confronta se il contenuto di esi è 6
    je imposta_peso_6_4
    jne imposta_peso_12_4 

# funzione che imposta 6 se il carattere è 6
imposta_peso_6_4:
    movl $6, peso_esito_4

    movl somma_crediti_x_studente, %eax
    movl peso_esito_4, %ebx
    addl %ebx, %eax                     # somma il peso dell'esito ai crediti totali dello studente
    movl %eax, somma_crediti_x_studente # aggiorna la somma dei crediti dello studente    

    jmp verifica_due_punti_4

# funzione che imposta 12 se il carattere è diverso da 6 (sarà sempre o 6 o 1)
imposta_peso_12_4:
    movl $12, peso_esito_4

    movl somma_crediti_x_studente, %eax
    movl peso_esito_4, %ebx
    addl %ebx, %eax                     # somma il peso dell'esito ai crediti totali dello studente
    movl %eax, somma_crediti_x_studente # aggiorna la somma dei crediti dello studente    

    jmp verifica_due_punti_4


# una volta impostato il peso bisogna far capire al programma se si tratta del peso o dell'esito
verifica_due_punti_4:

    movl contatore_due_punti_4, %edx
    incl %edx
    movl %edx, contatore_due_punti_4   # si incrementa il contatore di quanti ':' sono stati letti

    cmpl $2, %edx                      # la seconda volta che legge i ':' sarà sicuramente il voto ottenuto per quell'esame
    je salva_esito_4
    jne leggi_esiti_4

# funzione che salva l'esito dell'esame, lo moltiplica per il peso e lo somma alla somma degli esiti ponderati
salva_esito_4:

    movb (%esi), %al
    
    cmpb $';', %al                     # se si raggiunge il ';' abbiamo letto il primo voto
    je incrementa_contatore_4

    cmpb $'\n', %al                    # se si raggiunge il '\n' abbiamo letto tutti i voti
    je incrementa_contatore_finale_4

    
    subb $'0', %al                          # convertiamo il numero letto con atoi
    movzbl %al, %eax                        # lo spostiamo nel registro %eax
    imull decina_unita_4, %eax              # lo moltiplichiamo per 10 se è la prima cifra, altrimenti per 1 se è la seconda cifra letta

    movl esito_ponderato_4, %ecx           
    addl %eax, %ecx 
    movl %ecx, esito_ponderato_4            # il risultato lo spostiamo anche in esito_ponderato_4 

    movl decina_unita_4, %eax
    movl $10, %ebx                          # aggiungiamo in %ebx 10 cosi da dividerlo con decina_unita_4 che al secondo giro rappresenterà le unità
    xorl %edx, %edx                         # azzeriamo %edx per poter eseguire una divisione
    divl %ebx                               # divisione tra %eax e %ebx
    movl %eax, decina_unita_4               # spostiamo il risultato in decina_unita_4

    incl %esi                               # incrementiamo %esi cosi da leggere il carattere successivo
    jmp salva_esito_4

# funzione che incrementa il contatore di quante volte è stato letto un voto, che sarà il divisore
incrementa_contatore_4:

    incl %esi
    movl $0, contatore_due_punti_4              # azzeriamo il contatore dei ':'

    movl $10, decina_unita_4                    # ripristiniamo il valore 10 a decina_unita_2 per i voti successivi

    movl esito_ponderato_4, %eax
    movl peso_esito_4, %ebx
    imull %ebx, %eax                            # moltiplicazione del voto per il suo peso

    movl somma_esiti_ponderata_4, %ecx
    addl %eax, %ecx
    movl %ecx, somma_esiti_ponderata_4          # aggiorniamo la somma finale degli esiti ponderati

    movl $0, %eax
    movl %eax, peso_esito_4                     # facciamo ritornare al peso dell'esito il valore 0
    movl %eax, esito_ponderato_4                # facciamo ritornare a 0 il voto calcolato in precedenza

    xorl %eax, %eax                             # azzeriamo il registro %eax cosicche non ci sia spazzatura
    xorl %ecx, %ecx

    jmp leggi_esiti_4

# si aggiornano le variabili per il calcolo della media ponderata e si azzerano quelle che non servono più
incrementa_contatore_finale_4:                  # ultima volta che viene incrementato il contatore della media aritmetica

    movl esito_ponderato_4, %eax
    movl peso_esito_4, %ebx
    imull %ebx, %eax                            # moltiplicazione del voto per il suo peso

    movl somma_esiti_ponderata_4, %ecx
    addl %eax, %ecx
    movl %ecx, somma_esiti_ponderata_4          # aggiorniamo la somma finale degli esiti ponderati

    movl $0, %eax
    movl %eax, peso_esito_4                     # facciamo ritornare al peso dell'esito il valore 0
    movl %eax, esito_ponderato_4                # facciamo ritornare a 0 il voto calcolato in precedenza
    movl %eax, contatore_due_punti_4            # azzeriamo il contatore dei ':'
    movl $10, decina_unita_4                    # ripristiniamo il valore 10 a decina_unita_2 per i voti successivi

    jmp conteggio_media_ponderata_4

# funzione che calcola la media ponderata degli esiti degli esami
conteggio_media_ponderata_4:

    movl somma_esiti_ponderata_4, %eax
    movl somma_pesi_4, %ebx

    cmpl $0, %ebx
    je _error_read_libretti_4                   # se i crediti totali sono 0, allora non si può calcolare la media

    xorl %edx, %edx                             # azzeriamo %edx per poter eseguire una divisione
    divl %ebx                                   # divisione tra somma degli esiti ponderati e i crediti totali

    movl %eax, media_ponderata_4                # salviamo il risultato della media ponderata in media_ponderata_4

    jmp itoa_media_ponderata_4                   # riparte a leggere il file libretti.txt

# funzione che converte la media ponderata in stringa per la stampa (itoa)
itoa_media_ponderata_4:
    movl media_ponderata_4, %eax        # media aritmetica a due cifre (es: 25)
    movl %eax, %ecx          # salvo copia per dopo

    movl $10, %ebx
    xorl %edx, %edx          # azzera edx per la divisione
    divl %ebx                # eax / 10 → eax = decina, edx = unità

    addb $'0', %al           # %al = cifra decine in ASCII
    movb %al, buffer_itoa_media_pond_4

    movl %ecx, %eax          # riprendi numero intero
    xorl %edx, %edx
    divl %ebx                # %edx = unità
    addb $'0', %dl           # %dl = cifra unità in ASCII
    movb %dl, buffer_itoa_media_pond_4+1

    movb $' ', buffer_itoa_media_pond_4+2  # terminatore \0
    jmp itoa_somma_crediti_x_studente_4    # chiudiamo il file cosi stampiamo ciò che ci serve

# funzione che converte la somma dei crediti in stringa per la stampa (itoa)
itoa_somma_crediti_x_studente_4:
    movl somma_crediti_x_studente, %eax  # somma dei crediti a due cifre (es: 25)
    movl %eax, %ecx          # salvo copia per dopo

    movl $10, %ebx
    xorl %edx, %edx          # azzera edx per la divisione
    divl %ebx                # eax / 10 → eax = decina, edx = unità

    addb $'0', %al           # %al = cifra decine in ASCII
    movb %al, buffer_itoa_somma_crediti_4

    movl %ecx, %eax          # riprendi numero intero
    xorl %edx, %edx
    divl %ebx                # %edx = unità
    addb $'0', %dl           # %dl = cifra unità in ASCII
    movb %dl, buffer_itoa_somma_crediti_4+1

    movb $'\n', buffer_itoa_somma_crediti_4+2  # terminatore \0
    jmp recupero_nome_cognome

# funzione che recupera il nome e cognome dello studente dalla matricola
recupero_nome_cognome:
    # recupero del nome e cognome dello studente
    pushl $matricola_buffer_libretti_menu_4  # salviamo la matricola nello stack
    call carica_file_anagrafica_menu # chiama la funzione che carica il file anagrafica
    addl $4, %esp                    # puliamo lo stack

    cmpl $1, %edx                    # verifica se la matricola è valida
    je set_x_salvare_matricola_graduatoria_buffer # se non è valida, allora va a stampare

    movl $4, %eax               # syscall write
    movl $1, %ebx               # stdout
    leal errore_strano_matricola_non_presente, %ecx
    movl errore_strano_matricola_non_presente_len, %edx
    int $0x80

# funzione che si prepara a salvare la matricola, il nome, il cognome e la media ponderata nel buffer graduatoria
set_x_salvare_matricola_graduatoria_buffer:
    # salvataggio della matricola e della media ponderata nel buffer graduatoria
    xorl %esi, %esi            # azzera l'indice della matricola
    xorl %edi, %edi            # azzera l'indice del buffer graduatoria

    movl $matricola_buffer_libretti_menu_4, %esi # puntatore alla matricola

    movl indice_graduatoria_buffer, %edx         # azzera l'indice del buffer graduatoria
    movl $graduatoria_buffer, %edi               # puntatore al buffer graduatoria
    addl %edx, %edi                              # sposta l'indice del buffer graduatoria

    jmp salva_matricola_graduatoria_buffer

# funzione che salva effettivamente la matricola nel buffer graduatoria
salva_matricola_graduatoria_buffer:
    movb (%esi), %al                                 # carica il primo byte della matricola
    cmpb $0, %al                                     # verifica se il byte è 0 (null terminator)
    je set_x_salvare_nome_cognome_graduatoria_buffer # se è 0, allora

    movb %al, (%edi)                                 # salva il byte nel buffer graduatoria
    incl %esi                                        # incrementa l'indice della matricola
    incl %edi                                        # incrementa l'indice del buffer graduatoria
    jmp salva_matricola_graduatoria_buffer

# prepara a salvare il nome e cognome dello studente nel buffer graduatoria
set_x_salvare_nome_cognome_graduatoria_buffer:
    xorl %esi, %esi                                  # azzera l'indice della matricola

    movb $' ', (%edi)                                # aggiunge uno ' ' per rendere il buffer graduatoria più leggibile

    movl $nome_cognome_buffer_anagrafica, %esi       # puntatore al nome e cognome
    jmp salva_nome_cognome_graduatoria_buffer        # ripete il processo fino a trovare il null terminator

# salva il nome e cognome dello studente nel buffer graduatoria
salva_nome_cognome_graduatoria_buffer:
    movb (%esi), %al                                 # carica il primo byte della matricola
    cmpb $0, %al                                     # verifica se il byte è 0 (null terminator)
    je set_x_salvare_media_ponderata_graduatoria_buffer # se è 0, allora

    incl %edi                                        # incrementa l'indice del buffer graduatoria
    incl %esi                                        # incrementa l'indice della matricola
    movb %al, (%edi)                                 # salva il byte nel buffer graduatoria
    jmp salva_nome_cognome_graduatoria_buffer

# prepara a salvare la media ponderata nel buffer graduatoria
set_x_salvare_media_ponderata_graduatoria_buffer:
    # salvataggio della media ponderata nel buffer graduatoria
    xorl %esi, %esi                             # azzera l'indice della matricola

    incl %edi                                   # incrementa l'indice del buffer graduatoria
    movb $' ', (%edi)                           # aggiunge una '|' tra la media ponderata e la somma dei crediti per fare capire che è un campo diverso
    incl %edi                                   # incrementa l'indice del buffer graduatoria
    movb $'M', (%edi) 
    incl %edi                                   # incrementa l'indice del buffer graduatoria
    movb $'P', (%edi)
    incl %edi                                   # incrementa l'indice del buffer graduatoria
    movb $':', (%edi)
    incl %edi                                   # incrementa l'indice del buffer graduatoria
    movb $' ', (%edi) 

    movl $buffer_itoa_media_pond_4, %esi                            # carica la media ponderata in %eax
    jmp salva_media_ponderata_graduatoria_buffer                    # riparte a leggere il file libretti.txt

# salva effettivamente la media ponderata nel buffer graduatoria
salva_media_ponderata_graduatoria_buffer:
    movl (%esi), %eax                    # carica il primo byte della media ponderata
    cmpb $0, %al                         # verifica se il byte è 0 (null terminator)
    je set_x_salvare_somma_credito       # se è 0, allora

    incl %esi                            # incrementa l'indice della matricola
    incl %edi                            # incrementa l'indice del buffer graduatoria
    movb %al, (%edi)                     # salva il byte nel buffer graduatoria
    jmp salva_media_ponderata_graduatoria_buffer

# prepara a salvare la somma dei crediti nel buffer graduatoria
set_x_salvare_somma_credito:
    # salvataggio della somma dei crediti nel buffer graduatoria
    xorl %esi, %esi                             # azzera l'indice della matricola

    incl %edi                                   # incrementa l'indice del buffer graduatoria
    movb $'|', (%edi)                           # aggiunge una '|' tra la media ponderata e la somma dei crediti per fare capire che è un campo diverso

    movl $buffer_itoa_somma_crediti_4, %esi        # carica la somma dei crediti in %eax
    jmp salva_somma_credito_graduatoria_buffer     # riparte a leggere il file libretti.txt

# salva effettivamente la somma dei crediti nel buffer graduatoria
salva_somma_credito_graduatoria_buffer:
    movl (%esi), %eax                    # carica il primo byte della somma dei crediti
    movb %al, (%edi)                     # salva il byte nel buffer graduatoria
    cmpb $0, %al                         # verifica se il byte è 0 (null terminator)
    je salva_graduatoria_buffer # se è 0, allora

    incl %esi                            # incrementa l'indice della matricola
    incl %edi                            # incrementa l'indice del buffer graduatoria
    jmp salva_somma_credito_graduatoria_buffer

# funzione che salva il buffer graduatoria e lo prepara per la scrittura su stdout
salva_graduatoria_buffer:

    movl %edi, %ecx
    subl $graduatoria_buffer, %ecx               # calcola offset relativo
    movl %ecx, indice_graduatoria_buffer         # salva l’indice reale (non l’indirizzo)

    # scrittura del buffer graduatoria su stdout
    xorl %edi, %edi            # azzera l'indice del buffer graduatoria
    xorl %esi, %esi            # azzera l'indice del buffer graduatoria

    movl %edi, somma_crediti_x_studente # azzera la somma dei crediti dello studente
    movl %edi, somma_esiti_ponderata_4  # azzera la somma degli esiti ponderati
    jmp azzera_riga_file_buffer_menu

# funzione stampa il buffer graduatoria
fine_file_libretti:
    
    movl lunghezza_graduatoria_buffer, %eax
    cmpl $0, %eax
    je set_calcola_lunghezza_graduatoria_buffer          # se la lunghezza del buffer gradu

    movl $4, %eax               # syscall write
    movl $1, %ebx               # stdout
    leal graduatoria_buffer, %ecx
    movl lunghezza_graduatoria_buffer, %edx              # lunghezza del buffer graduatoria
    int $0x80

    jmp chiusura_file_libretti

# prepara i registri per calcolare la lunghezza del buffer graduatoria
set_calcola_lunghezza_graduatoria_buffer:
    # calcola la lunghezza del buffer graduatoria
    xorl %eax, %eax                # azzera %eax
    xorl %ecx, %ecx                # azzera %ecx
    xorl %edi, %edi                # azzera %edi

    movl $graduatoria_buffer, %edi # puntatore al buffer graduatoria
    movl %edi, %ecx
    jmp calcola_lunghezza_graduatoria_loop

# calcola effettivamente la lunghezza del buffer graduatoria
calcola_lunghezza_graduatoria_loop:
    movb (%edi), %al                      # carica il byte corrente del buffer graduatoria

    cmpb $0, %al                          # verifica se il byte è 0 (null terminator)
    je fine_calcolo_lunghezza_graduatoria # se è 0, allora siamo alla fine del buffer graduatoria

    incl %edi                             # incrementa l'indice del buffer graduatoria
    jmp calcola_lunghezza_graduatoria_loop

# fine del calcolo della lunghezza del buffer graduatoria
fine_calcolo_lunghezza_graduatoria:
    subl %ecx, %edi                         # calcola la lunghezza del buffer graduatoria
    movl %edi, lunghezza_graduatoria_buffer # salva la lunghezza del buffer graduatoria
    jmp fine_file_libretti

# funzione che chiude il file libretti.txt
chiusura_file_libretti:
    # chiusura del file libretti.txt
    movl $6, %eax                  # syscall close
    movl fd_libretti, %ebx
    int $0x80

    cmpl $0, %eax                  # verifica se la chiusura del file è andata a buon fine
    jl _exit_failure

    movl $1, %eax                  # syscall exit
    movl $0, %ebx                  # Codice di uscita 0 (successo)
    int $0x80


# funzione che gestisce l'errore di lettura del file libretti.txt
_error_read_libretti_4:
    movl $4, %eax               # syscall write
    movl $2, %ebx               # stderr
    movl $errore_lettura_file_libretti, %ecx	
    movl errore_lettura_file_libretti_len, %edx
    int $0x80
    jmp _exit_failure

# esce dal programma in caso di errore
_exit_failure:
    movl $1, %eax               # syscall exit
    movl $1, %ebx               # Codice di uscita 1 (errore)
    int $0x80   

# funzione che gestisce l'errore di apertura del file libretti.txt
_error_open_libretti:
    movl $4, %eax               # syscall write
    movl $2, %ebx               # stderr
    movl $errore_apertura_file_libretti, %ecx	
    movl errore_apertura_file_libretti_len, %edx
    int $0x80

    jmp _exit_failure
