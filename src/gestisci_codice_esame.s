/*
Questa funzione carica il file libretti.txt e calcola la media dei voti per un esame specifico.
Come prima cosa recupera il codice dell'esame passato come parametro sullo stack, 
poi apre il file libretti.txt, legge tutto il file una volta e lo carica in file_buffer_3.
Successivamente cerca il codice dell'esame nel file_buffer_3 andando a verificare se prima 
si trova un ' ' oppure un ';' che indicano l'inizio del codice. Poi viene confrontato il codice 
dell'esame con quello trovato nel file_buffer_3. Se il codice è uguale, allora si procede a leggere i voti
e memorizzarli in una variabile somma_voti_3 e il conteggio dei voti in contatore_media_aritmetica_3.
Se non lo trova semplicemente va avanti a leggere il file. Alla fine del file, se ha trovato almeno un voto,
calcola la media aritmetica dividendo somma_voti_3 per contatore_media_aritmetica_3. E poi stampa la media.
*/

.section .data
    no_voti_msg: .asciz "Purtroppo nessuno studente ha sostenuto l'esame.\n"
    no_voti_msg_len: .long . - no_voti_msg
    media_msg: .asciz "Media voti: "
    media_msg_len: .long . - media_msg
    filename_ptr_fd_libretti_3: .asciz "data/libretti.txt"
    error_open_msg_3: .asciz "Errore nell'apertura del file libretti.\n"
    error_open_msg_len_3: .long . - error_open_msg_3
    error_read_msg_3: .asciz "Errore nella lettura del file libretti.\n"
    error_read_msg_len_3: .long . - error_read_msg_3
    media_voti_studenti: .asciz "Media voti studenti: "
    media_voti_studenti_len: .long . - media_voti_studenti
    indice_file_buffer_3: .long 0
    lunghezza_file_buffer_3: .long 0

    contatore_media_aritmetica_3: .long 0
    somma_voti_3: .long 0
    media_aritmetica_3: .long 0
    decina_unita_3: .long 10    


.section .bss
    codice_esame_parametro: .skip 4
    file_buffer_3: .skip 1024
    fd_libretti_3: .skip 4
    codice_esame_file_buffer_3: .skip 4
    buffer_itoa_media_arit_3: .skip 4 # buffer per la conversione della media aritmetica in stringa



.section .text 
.global gestisci_codice_esame
.type gestisci_codice_esamer, @function
gestisci_codice_esame:

    pushl %ebp              # salvo il vecchio base pointer
    movl %esp, %ebp         # imposto il nuovo frame
 
    xorl %ebx, %ebx         

    movl 8(%ebp), %esi                  # %esi <- puntatore codice esame sullo stack
    movl $codice_esame_parametro, %edi  # %edi <- puntatore inizio codice_esame_parametro
    jmp copy_loop_codice_esame_stack

# funzione che copia il codice esame dallo stack in codice_esame_parametro
copy_loop_codice_esame_stack:
    movb (%esi), %al               # spostiamo il primo byte di esi in al
    movb %al, (%edi)               # ora copiamo al in edi che a sua volta lo salvera in esiti_buffer_reg
    cmpb $'\n', %al                   # confronta se è terminatore
    je set_codice_esame_parametro
    incl %esi                      # incrementiamo gli indici
    incl %edi                     
    jmp copy_loop_codice_esame_stack # ripartiamo dall'inizio

# funzione che ottimizza il codice esame copiato dallo stack in codice_esame_parametro
set_codice_esame_parametro:
    movb $0, (%edi)
    xorl %esi, %esi            # azzera l'indice della matricola
    xorl %edi, %edi          # azzera l'indice del buffer esiti
    jmp apertura_libretti_3

# funzione che apre il file libretti.txt in lettura
apertura_libretti_3:
    # open(filename, O_RDONLY)
    movl $5, %eax
    movl $filename_ptr_fd_libretti_3, %ebx
    movl $0, %ecx
    int $0x80

    # se l'apertura del file fallisce, allora va a _error_open_libretti
    cmpl $0, %eax
    jl _error_open_libretti_3

    # salviamo il file descriptor in fd_libretti
    movl %eax, fd_libretti_3
    xorl %eax, %eax            

    jmp leggi_file_libretti_3

# funzione che legge il file libretti.txt totalmente
leggi_file_libretti_3:
    # read(fd_libretti, file_buffer_3, 1024)
    movl $3, %eax                      # syscall read
    movl fd_libretti_3, %ebx
    leal file_buffer_3, %ecx
    movl $1024, %edx                   # dimensione del buffer
    int $0x80

    # se la lettura fallisce, allora va a _error_open_libretti
    cmpl $0, %eax
    jl _error_read_libretti_3
    # je fine lettura del file

    movl %eax, lunghezza_file_buffer_3 # salva il numero di byte letti in lunghezza_file_buffer_3

    jmp set_trova_codice_esame_3

# funzione che imposta i registri per la ricerca del codice esame nel file_buffer_3
set_trova_codice_esame_3:
    movl indice_file_buffer_3, %esi     # %ebx <- indice del file_buffer_3
    xorl %edi, %edi                     # azzera l'indice del codice esame
    movl lunghezza_file_buffer_3, %edx  # %edx <- lunghezza del buffer
    jmp trova_codice_esame_3

# funzione che cerca l'inizio del codice dell'esame nel file_buffer_3
trova_codice_esame_3:
    cmpb $' ', file_buffer_3(%esi)  # cerca il primo spazio
    je salva_codice_esame_3_1

    cmpb $';', file_buffer_3(%esi)  # cerca il primo ';'
    je salva_codice_esame_3_1

    cmpl %esi, %edx  # verifica se siamo alla fine del buffer
    je conteggio_media_aritmetica_3

    incl %esi                        # incrementa l'indice del buffer
    jmp trova_codice_esame_3

# funzione che incrementa l'indice del buffer cosi da non leggere lo spazio o il ';' trovato
salva_codice_esame_3_1:
    incl %esi
    jmp salva_codice_esame_3_2

# funzione che salva il codice esame trovato in codice_esame_file_buffer_3
salva_codice_esame_3_2:
    # salva il codice esame trovato in codice_esame_parametro
    movb file_buffer_3(%esi), %al                 
    movb %al, codice_esame_file_buffer_3(%edi)  # salva il byte corrente in codice_esame_parametro   

    cmpb $':', %al                 # verifica se il byte è ':'
    je termina_codice_esame_3

    incl %esi                      # incrementa l'indice del buffer
    incl %edi                      # incrementa l'indice del codice esame
    jmp salva_codice_esame_3_2

# funzione che termina il codice esame e prepara per il confronto dei 2 codici
termina_codice_esame_3:
    movb $0, codice_esame_file_buffer_3(%edi)  # aggiungi terminatore di stringa

    leal file_buffer_3(%esi), %eax
    subl $file_buffer_3, %eax  # calcola l'offset corrente nel buffer
    movl %eax, indice_file_buffer_3  # salva l'offset corrente in indice_file_buffer_3

    xorl %esi, %esi            # azzera l'indice della riga corrente
    xorl %edi, %edi            # azzera l'indice del buffer esiti
    jmp set_confronto_codice_esame_3

# funzione che setta i registri per il confronto del codice esame
set_confronto_codice_esame_3:
    movl $codice_esame_parametro, %esi
    movl $codice_esame_file_buffer_3, %edi

    jmp confronto_codice_esame_3

# funzione che confronta il codice esame trovato nel file con quello passato come parametro
confronto_codice_esame_3:
    movb (%esi), %al
    movb (%edi), %bl

    cmpb %bl, %al              # confronta i byte
    jne diversi_codice_esame_3

    cmpb $0, %al              # verifica se abbiamo raggiunto il terminatore di stringa
    je uguali_codice_esame_3


    incl %esi
    incl %edi
    jmp confronto_codice_esame_3

# se sono diversi, allora azzera i registri
diversi_codice_esame_3:
    # azzera i registri e riparte a leggere il codice esame dal file libretti
    xorl %eax, %eax
    xorl %edi, %edi
    jmp azzera_codice_esame_file_buffer

# funzione che azzera il buffer del codice esame e si prepara a leggere il prossimo codice esame
azzera_codice_esame_file_buffer:
    movb %al, codice_esame_file_buffer_3(%edi)
    incl %edi
    cmpl $4, %edi
    jl azzera_codice_esame_file_buffer
    jmp set_trova_codice_esame_3

# funzione che gestisce il caso in cui il codice esame è uguale a quello passato come parametro
uguali_codice_esame_3:
    #movl byte_letti_file_buffer_3, %edi  # aggiorna il conteggio dei byte letti
    movl indice_file_buffer_3, %esi  # aggiorna l'indice del buffer
    incl %esi
    jmp loop_media_aritmetica_3

# funzione che non prende in considerazione i crediti dell'esame e quindi deve skipparli
loop_media_aritmetica_3:
    # calcola la media aritmetica dei voti per il codice esame trovato
    movb file_buffer_3(%esi), %al   # carica il primo byte della riga corrente
    incl %esi
    cmpb $':', %al                  # verifica se è il terminatore dei crediti
    je salva_esito_3
    jmp loop_media_aritmetica_3

# funzione che salva gli esiti dell'esame nella variabile somma_voti_3
salva_esito_3:
    movb file_buffer_3(%esi), %al
    
    cmpb $';', %al                          # se si raggiunge il ';' abbiamo letto il primo voto
    je incrementa_contatore_3

    cmpb $'\n', %al                         # se si raggiunge il '\n' abbiamo letto tutti i voti
    je incrementa_contatore_3

    
    subb $'0', %al                          # convertiamo il numero letto con atoi
    movzbl %al, %eax                        # lo spostiamo nel registro %eax
    imull decina_unita_3, %eax              # lo moltiplichiamo per 10 se è la prima cifra, altrimenti per 1 se è la seconda cifra letta
    xorl %edx, %edx                         # azzeriamo %edx per poter eseguire una divisione
    movl somma_voti_3, %ecx                 # spostiamo il contenuto di somma_esiti_senza_peso_2 in %ecx
    addl %eax, %ecx                         # facciamo la somma di %eax, che rappresenta o la decina o l'unita, con il contenuto di %ecx
    movl %ecx, somma_voti_3                 # il risultato lo spostiamo in somma_esiti_senza_peso_2

    movl decina_unita_3, %eax
    movl $10, %ebx                          # aggiungiamo in %ebx 10 cosi da dividerlo con decina_unita_2 che al secondo giro rappresenterà le unità
    divl %ebx                               # divisione tra %eax e %ebx
    movl %eax, decina_unita_3               # spostiamo il risultato in decina_unita_2

    incl %esi                               # incrementiamo %esi cosi da leggere il carattere successivo del file_buffer_3
    #incl %edi                              # incrementiamo %edi che tiene conto di quanti byte abbiamo letto
    jmp salva_esito_3
    
# funzione che incrementa il contatore di quante volte è stato letto un voto, che sarà il divisore
incrementa_contatore_3:

    movl contatore_media_aritmetica_3, %eax
    incl %eax
    movl %eax, contatore_media_aritmetica_3     # incremento di 1 ogni volta che leggo il voto

    incl %esi

    movl $10, %eax
    movl %eax, decina_unita_3                   # ripristiniamo il valore 10 a decina_unita_3 per i voti successivi

    movl %esi, indice_file_buffer_3             # aggiorniamo il conteggio dei byte letti

    xorl %eax, %eax                             # azzeriamo il registro %eax cosicche non ci sia spazzatura
    xorl %ecx, %ecx

    jmp set_trova_codice_esame_3

# funzione che calcola effettivamente la media
conteggio_media_aritmetica_3:

    cmpl $0, somma_voti_3
    je esame_non_sostenuto_3

    movl somma_voti_3, %eax
    movl contatore_media_aritmetica_3, %ebx
    xorl %edx, %edx
    divl %ebx
    movl %eax, media_aritmetica_3               # salviamo il risultato dentro la variabile media_aritmetica_3

    jmp itoa_media_aritmetica_3                 # chiudiamo il file cosi stampiamo ciò che ci serve

# funzione che converte la media aritmetica in stringa per la stampa (itoa)
itoa_media_aritmetica_3:
    movl media_aritmetica_3, %eax               # media aritmetica a due cifre (es: 25)
    movl %eax, %ecx          # salvo copia per dopo

    movl $10, %ebx
    xorl %edx, %edx          # azzera edx per la divisione
    divl %ebx                # eax / 10 → eax = decina, edx = unità

    addb $'0', %al           # %al = cifra decine in ASCII
    movb %al, buffer_itoa_media_arit_3

    movl %ecx, %eax          # riprendi numero intero
    xorl %edx, %edx
    divl %ebx                # %edx = unità
    addb $'0', %dl           # %dl = cifra unità in ASCII
    movb %dl, buffer_itoa_media_arit_3+1

    movb $'\n', buffer_itoa_media_arit_3+2      # terminatore \0
    jmp chiusura_file_libretti_3                # chiudiamo il file cosi stampiamo ciò che ci serve

# funzione che chiude il file libretti
chiusura_file_libretti_3:

    movl $6, %eax              
    movl fd_libretti_3, %ebx
    int $0x80

    jmp stampa_media_aritmetica_3   

# funzione che stampa la media aritmetica dei voti degli studenti per l'esame specificato
stampa_media_aritmetica_3:
    # chiude il file libretti e ritorna al chiamante
    movl $4, %eax               # syscall write
    movl $1, %ebx               # stdout
    leal media_voti_studenti, %ecx
    movl media_voti_studenti_len, %edx
    int $0x80

    movl $4, %eax               # syscall write
    movl $1, %ebx               # stdout
    leal buffer_itoa_media_arit_3, %ecx
    movl $4, %edx               # lunghezza della stringa (2 cifre + terminatore)
    int $0x80

    movl $1, %eax               # syscall exit
    movl $0, %ebx               # Codice di uscita 0 (successo)
    int $0x80

# stampa un messaggio se nessuno studente ha sostenuto l'esame
esame_non_sostenuto_3:
    movl $4, %eax               # syscall write
    movl $1, %ebx               # stdout
    leal no_voti_msg, %ecx
    movl no_voti_msg_len, %edx
    int $0x80

    movl $1, %eax               # syscall exit
    movl $0, %ebx               # Codice di uscita 0 (successo)
    int $0x80

# funzione che gestisce l'errore di lettura del file libretti
_error_read_libretti_3:
    movl $4, %eax               # syscall write
    movl $2, %ebx               # stderr
    leal error_read_msg_3, %ecx	
    movl error_read_msg_len_3, %edx
    int $0x80
    jmp _exit_failure_3

# funzione che gestisce l'errore di apertura del file libretti
_error_open_libretti_3:
    movl $4, %eax               # syscall write
    movl $2, %ebx               # stderr
    leal error_open_msg_3, %ecx	
    movl error_open_msg_len_3, %edx
    int $0x80
    jmp _exit_failure_3

# funzione che gestisce l'uscita in caso di errore
_exit_failure_3:
    movl $1, %eax               # syscall exit
    movl $1, %ebx               # Codice di uscita 1 (errore)
    int $0x80
