/*
 Questa funzione apre il file libretti e si salva una riga alla volta,
 da quella riga si estrae la matricola e la si confronta. Se non è
 uguale allora si passa alla successiva, altrimenti, in un altra variabile
 'risultati_buffer', si salva tutto quello che si trova dopo la matricola,
 ovvero i risultati. Questi risultati a loro volta verranno processati
 in modo da calcolare la media aritmetica e la media ponderata.
*/
.extern nome_cognome_buffer_anagrafica


.section .data
    filename_ptr_fd_libretti: .asciz "data/libretti.txt"
    flag_studente_senza_esami: .long 0
    flag_fine_file: .long 0
    errore_apertura_file_libretti: .asciz "Errore nell'apertura del file libretti.\n"
    errore_apertura_file_libretti_len: .long . - errore_apertura_file_libretti
    media_arit_2: .asciz "Media aritmetica: "
    media_arit_len_2: .long . - media_arit_2
    media_pond_2: .asciz "Media ponderata: "
    media_pond_len_2: .long . - media_pond_2
    matricola_senza_esami_errore: .asciz "Questa matricola non ha sostenuto alcun esame\n"
    matricola_senza_esami_errore_len: .long . - matricola_senza_esami_errore
    nome_cognome_2: .asciz "\nStudente: "
    nome_cognome_len_2: .long . - nome_cognome_2
    risultati_2: .asciz "\nRisultati: "
    risultati_len_2: .long . - risultati_2

    lunghezza_nome_cognome_2: .long 0
    lunghezza_risultati_2: .long 0

    contatore_media_aritmetica_2: .long 0
    contatore_due_punti_2: .long 0 
    contatore_media_ponderata_2: .long 0
    somma_esiti_senza_peso_2: .long 0
    somma_esiti_ponderata_2: .long 0
    esito_ponderato_2: .long 0
    peso_esito_2: .long 0
    media_aritmetica_2: .long 0
    media_ponderata_2: .long 0
    decina_unita_2: .long 10
    somma_pesi_2: .long 18

.section .bss
    indice_file_buffer: .skip 4
    indice_riga_file_buffer: .skip 4
    fd_libretti: .skip 4
    matricola_buffer_libretti_menu: .skip 256
    matricola_buffer_libretti: .skip 256
    riga_file_buffer: .skip 1024
    risultati_buffer: .skip 1024
    buffer_itoa_media_arit_2: .skip 4
    buffer_itoa_media_pond_2: .skip 4

.section .text
    .globl carica_file_libretti_menu
    .type carica_file_libretti_menu, @function

# funzione che apre il file data/libretti.txt in lettura
carica_file_libretti_menu:
    # prologo
    pushl %ebp			# per prassi si pusha ebp sullo stack così che poi venga recuperato
    movl %esp, %ebp		# ciò a cui punta esp, ora punta anche ebp
    

    movl 8(%ebp), %esi	# facciamo puntare ad esi l'inizio della matricola pushata sullo stack
    movl $matricola_buffer_libretti_menu, %edi # facciamo puntare ad edi l'inzio di dove salvare la matricola
    
# funzione che copia la matricola letta da carica_file_reg in matricola_buffer_reg
copy_loop_matricola_libretti_reg_menu:

    movb (%esi), %al          # spostiamo il primo byte di esi in al
    movb %al, (%edi)          # ora copiamo al in edi che a sua volta lo salvera in matricola_buffer_reg
    cmpb $0, %al              # confronta se è terminatore
    je apertura_libretti_menu
    incl %esi                      # incrementiamo gli indici
    incl %edi                     
    jmp copy_loop_matricola_libretti_reg_menu # ripartiamo dall'inizio

apertura_libretti_menu:
    # open(filename, O_RDONLY)
    movl $0, indice_file_buffer # inizializziamo l'indice del file buffer a 0 (per sicurezza)

    movl $5, %eax
    movl $filename_ptr_fd_libretti, %ebx
    movl $0, %ecx
    int $0x80

    cmpl $0, %eax
    jl ._error_open_libretti

    movl %eax, fd_libretti	# quando si apre un file, ad eax viene assegnato un intero che rappresenta il file descriptor, assegnamolo alla variabile fd_reg

    # per convenzione azzeriamo i registri esi e edi
    xorl %esi, %esi           	
    xorl %edi, %edi           	
    xorl %eax, %eax   
    jmp .azzera_riga_file_buffer        	

# funzione che azzera la variabile riga_file_buffer così da non avere dati spazzatura
.azzera_riga_file_buffer:

    movb %al, riga_file_buffer(%edi)
    incl %edi
    cmpl $1024, %edi
    jl .azzera_riga_file_buffer
    jmp set_copy_file_buffer_2

# funzione che azzera i registri e si prepara a leggere il file data/libretti.txt riga per riga
set_copy_file_buffer_2:
    # azzeriamo l'indice della riga corrente
    xorl %eax, %eax
    xorl %esi, %esi           	
    jmp .copy_file_buffer

# funzione che legge il file data/libretti.txt riga per riga
.copy_file_buffer:
    movl $3, %eax               # syscall read
    movl fd_libretti, %ebx
    leal riga_file_buffer(%esi), %ecx
    movl $1, %edx 
    int $0x80

    cmpl $0, %eax               # se il numero di byte letti è 0, allora abbiamo raggiunto la fine del file (EOF)
    je matricola_senza_esami        
    jl ._error_open_libretti    # errore se non riesce a leggere il file

    movzbl (%ecx), %eax         # carica il byte contenuto in %ecx in %eax. Quest'ultimo verrà prima azzerato e poi riempito col byte letto

    cmpb $'\n', %al
    je .fine_riga_trovata

    incl %esi
    jmp .copy_file_buffer

# funzione che gestisce il caso in cui troviamo una riga completa
.fine_riga_trovata:
    incl %esi
    movb $0, riga_file_buffer(%esi)    # aggiungiamo un terminatore di stringa (\0) al buffer della riga corrente
    xorl %esi, %esi           	       # azzera l'indice della matricola
    xorl %edi, %edi           	       # azzera l'indice del contenuto
    jmp .copy_matricola_file_buffer_loop

# funzione che copia la matricola da riga_file_buffer al buffer delle matricole
.copy_matricola_file_buffer_loop:
    movb riga_file_buffer(%esi), %al     # prendi un byte da riga_buffer_file
    movb %al, matricola_buffer_libretti(%edi)
    cmpb $' ', %al                       # finché non trovi lo spazio ' '
    je .rimozione_spazio_libretti
    incl %esi
    incl %edi
    jmp .copy_matricola_file_buffer_loop

# rimuove lo spazio dalla matricola
.rimozione_spazio_libretti:
    movl %esi, indice_riga_file_buffer
    movb $0, matricola_buffer_libretti(%edi) # aggiungo un terminatore di stringa (\0) al posto dello spazio ' '

    movl $matricola_buffer_libretti_menu, %esi            # primo buffer
    movl $matricola_buffer_libretti, %edi                 # secondo buffer

# funzione che confronta le matricole lette da carica_file_reg e quelle lette da libretti
.confronto_matricole_loop_libretti:
    movb (%esi), %al                  
    movb (%edi), %bl                  
    cmpb %al, %bl
    jne .diverse_libretti                     

    cmpb $0, %al
    je .uguali_libretti                        

    incl %esi
    incl %edi
    jmp .confronto_matricole_loop_libretti

### GESTIONE DEL CASO IN CUI TROVA UNA MATRICOLA DIVERSA
.diverse_libretti:
    # azzeriamo i seguenti registri
    xorl %eax, %eax
    xorl %ebx, %ebx        
    xorl %ecx, %ecx 	
    xorl %edi, %edi
    xorl %esi, %esi           	    
    jmp .azzera_riga_file_buffer # se le matricole sono diverse, continuiamo a leggere il file

### GESTIONE DEL CASO IN CUI TROVA UNA MATRICOLA UGUALE
.uguali_libretti:
    xorl %esi, %esi           	            # azzeriamo l'indice del contenuto
    xorl %edi, %edi
    movl $1, %edx                           # settiamo il flag per non aggiungere la matricola a fine riga  
    movl indice_riga_file_buffer, %ecx      # ripristiniamo l'indice della riga corrente                        
    movl $riga_file_buffer, %esi            # facciamo puntare ad edi dallo ' ' della riga cosi da salvare il codice e crediti dell'esame e gli esiti
    addl %ecx, %esi
    movl $risultati_buffer, %edi                      
    jmp copy_risultati_2                    # se è uguale a \n, allora abbiamo trovato una riga completa

# funzione che setta i registri per il salvataggio del file buffer
copy_risultati_2:

    movb (%esi), %al                   # prendi un byte da riga_file_buffer
    movb %al, (%edi)
    
    cmpb $'\n', %al                    # confronta se è terminatore
    je set_leggi_esiti_2

    incl %esi                          # incrementa l'indice di riga_file_buffer
    incl %edi
    jne copy_risultati_2

# funzione che si prepara a calcolare la media aritmetica
set_leggi_esiti_2:

    incl %edi
    movb $0, (%edi)

    xorl %edi, %edi
    xorl %esi, %esi

    movl $risultati_buffer, %esi       # facciamo puntare ad esi l'inizio dei risultati
    jmp leggi_esiti_2

# funzione che legge fino ai ':'
leggi_esiti_2:

    movb (%esi), %al                   # prendi un byte da risultati_buffer
    incl %esi                          # incrementa l'indice di risultati_buffer
    
    cmpb $':', %al                     # confronta se è ':'
    je verifica_peso_2                 # se lo è, significa che potrebbe esserci il peso dell'esito
    jmp leggi_esiti_2

# funzione che verifica se la variabile peso_esito_2 è stata settata
verifica_peso_2:

    cmpl $0, peso_esito_2              # se la variabile è 0, allora non è stata settata e bisogna darle un valore
    jne verifica_due_punti_2

    cmpb $'6', (%esi)                    # si confronta se il contenuto di esi è 6
    je imposta_peso_6_2
    jne imposta_peso_12_2 

# funzione che imposta 6 se il carattere è 6
imposta_peso_6_2:
    movl $6, peso_esito_2
    jmp verifica_due_punti_2

# funzione che imposta 12 se il carattere è diverso da 6 (sarà sempre o 6 o 1)
imposta_peso_12_2:
    movl $12, peso_esito_2
    jmp verifica_due_punti_2

# una volta impostato il peso, bisogna far capire al programma se si tratta del peso o dell'esito
verifica_due_punti_2:

    movl contatore_due_punti_2, %eax
    incl %eax
    movl %eax, contatore_due_punti_2   # si incrementa il contatore di quanti ':' sono stati letti

    cmpl $2, %eax                      # la seconda volta che legge i ':' sarà sicuramente il voto ottenuto per quell'esame
    je salva_esito_2
    jne leggi_esiti_2

# salva l'esito letto in somma_esiti_senza_peso_2 e somma_esiti_ponderata_2
# questa funzione gestisce sia la somma degli esiti senza peso (media aritmetica) sia la somma degli esiti ponderati (media ponderata)
salva_esito_2:

    movb (%esi), %al
    
    cmpb $';', %al                          # se si raggiunge il ';' abbiamo letto il primo voto
    je incrementa_contatore_2

    cmpb $'\n', %al                         # se si raggiunge il '\n' abbiamo letto tutti i voti
    je incrementa_contatore_finale_2

    
    subb $'0', %al                          # convertiamo il numero letto con atoi
    movzbl %al, %eax                        # lo spostiamo nel registro %eax
    imull decina_unita_2, %eax              # lo moltiplichiamo per 10 se è la prima cifra, altrimenti per 1 se è la seconda cifra letta
    xorl %edx, %edx                         # azzeriamo %edx per poter eseguire una divisione
    movl somma_esiti_senza_peso_2, %ecx     # spostiamo il contenuto di somma_esiti_senza_peso_2 in %ecx
    addl %eax, %ecx                         # facciamo la somma di %eax, che rappresenta o la decina o l'unita, con il contenuto di %ecx
    movl %ecx, somma_esiti_senza_peso_2     # il risultato lo spostiamo in somma_esiti_senza_peso_2

    movl esito_ponderato_2, %ecx           
    addl %eax, %ecx 
    movl %ecx, esito_ponderato_2            # il risultato lo spostiamo anche in esito_ponderato_2 

    movl decina_unita_2, %eax
    movl $10, %ebx                          # aggiungiamo in %ebx 10 cosi da dividerlo con decina_unita_2 che al secondo giro rappresenterà le unità
    divl %ebx                               # divisione tra %eax e %ebx
    movl %eax, decina_unita_2               # spostiamo il risultato in decina_unita_2



    incl %esi                               # incrementiamo %esi cosi da leggere il carattere successivo
    jmp salva_esito_2
    
# funzione che incrementa il contatore di quante volte è stato letto un voto, che sarà il divisore
incrementa_contatore_2:

    movl contatore_media_aritmetica_2, %eax
    incl %eax
    movl %eax, contatore_media_aritmetica_2     # incremento di 1 ogni volta che leggo il voto

    incl %esi
    movl $0, %eax
    movl %eax, contatore_due_punti_2            # azzeriamo il contatore dei ':'

    movl $10, %eax
    movl %eax, decina_unita_2                   # ripristiniamo il valore 10 a decina_unita_2 per i voti successivi

    movl esito_ponderato_2, %eax
    movl peso_esito_2, %ebx
    imull %ebx, %eax                            # moltiplicazione del voto per il suo peso

    movl somma_esiti_ponderata_2, %ecx
    addl %eax, %ecx
    movl %ecx, somma_esiti_ponderata_2          # aggiorniamo la somma finale degli esiti ponderati

    movl $0, %eax
    movl %eax, peso_esito_2                     # facciamo ritornare al peso dell'esito il valore 0
    movl %eax, esito_ponderato_2                # facciamo ritornare a 0 il voto calcolato in precedenza

    xorl %eax, %eax                             # azzeriamo il registro %eax cosicche non ci sia spazzatura
    xorl %ecx, %ecx

    jmp leggi_esiti_2

# funzione che incrementa il contatore per l'ultima volta
incrementa_contatore_finale_2:                  # ultima volta che viene incrementato il contatore della media aritmetica

    movl contatore_media_aritmetica_2, %eax
    incl %eax
    movl %eax, contatore_media_aritmetica_2

    movl esito_ponderato_2, %eax
    movl peso_esito_2, %ebx
    imull %ebx, %eax                            # moltiplicazione del voto per il suo peso

    movl somma_esiti_ponderata_2, %ecx
    addl %eax, %ecx
    movl %ecx, somma_esiti_ponderata_2          # aggiorniamo la somma finale degli esiti ponderati

    jmp conteggio_media_aritmetica_2

# funzione che calcola effettivamente la media
conteggio_media_aritmetica_2:

    movl somma_esiti_senza_peso_2, %eax
    movl contatore_media_aritmetica_2, %ebx
    xorl %edx, %edx
    divl %ebx
    movl %eax, media_aritmetica_2               # spostiamo il risultato dentro la variabile media_aritmetica_2

    jmp itoa_media_aritmetica_2                 # chiudiamo il file cosi stampiamo ciò che ci serve

# funzione che converte la media aritmetica in stringa
itoa_media_aritmetica_2:
    movl media_aritmetica_2, %eax           # media aritmetica a due cifre (es: 25)
    movl %eax, %ecx                         # salvo copia per dopo

    movl $10, %ebx
    xorl %edx, %edx                         # azzera edx per la divisione
    divl %ebx                               # eax / 10 → eax = decina, edx = unità

    addb $'0', %al                          # %al = cifra decine in ASCII
    movb %al, buffer_itoa_media_arit_2

    movl %ecx, %eax                         # riprendi numero intero
    xorl %edx, %edx
    divl %ebx                               # %edx = unità
    addb $'0', %dl                          # %dl = cifra unità in ASCII
    movb %dl, buffer_itoa_media_arit_2+1

    movb $'\n', buffer_itoa_media_arit_2+2  # terminatore \0
    jmp conteggio_media_ponderata_2         # chiudiamo il file cosi stampiamo ciò che ci serve

# funzione che calcola la media ponderata
conteggio_media_ponderata_2:
    movl somma_esiti_ponderata_2, %eax
    movl somma_pesi_2, %ebx
    xorl %edx, %edx
    divl %ebx
    movl %eax, media_ponderata_2

    jmp itoa_media_ponderata_2

# funzione che converte la media ponderata in stringa
itoa_media_ponderata_2:
    movl media_ponderata_2, %eax        # media aritmetica a due cifre (es: 25)
    movl %eax, %ecx                     # salvo copia per dopo

    movl $10, %ebx
    xorl %edx, %edx                     # azzera edx per la divisione
    divl %ebx                           # eax / 10 → eax = decina, edx = unità

    addb $'0', %al                      # %al = cifra decine in ASCII
    movb %al, buffer_itoa_media_pond_2

    movl %ecx, %eax                     # riprendi numero intero
    xorl %edx, %edx
    divl %ebx                           # %edx = unità
    addb $'0', %dl                      # %dl = cifra unità in ASCII
    movb %dl, buffer_itoa_media_pond_2+1

    movb $'\n', buffer_itoa_media_pond_2+2  # terminatore \0
    jmp .close_and_exit_libretti            # chiudiamo il file cosi stampiamo ciò che ci serve

# funzione che stampa la media aritmetica
stampa_media_aritmetica_2:
    movl $4, %eax
    movl $1, %ebx
    leal media_arit_2, %ecx
    movl media_arit_len_2, %edx
    int $0x80

    movl $4, %eax
    movl $1, %ebx
    leal buffer_itoa_media_arit_2, %ecx
    movl $3, %edx
    int $0x80

    jmp stampa_media_ponderata_2

# funzione che stampa la media ponderata e poi esce
stampa_media_ponderata_2:

    movl $4, %eax
    movl $1, %ebx
    leal media_pond_2, %ecx
    movl media_pond_len_2, %edx
    int $0x80

    movl $4, %eax
    movl $1, %ebx
    leal buffer_itoa_media_pond_2, %ecx
    movl $3, %edx
    int $0x80

    movl $1, %eax
    movl $0, %ebx
    int $0x80

# funzione che prende in considerazione se la matricola non ha sostenuto alcun esame ma è presente in anagrafica e poi esce
matricola_senza_esami:
    movl $4, %eax
    movl $1, %ebx
    leal matricola_senza_esami_errore, %ecx
    movl matricola_senza_esami_errore_len, %edx
    int $0x80

    movl $1, %eax
    movl $1, %ebx
    int $0x80
# funzione che si prepara a calcolare la lunghezza del nome e cognome
calcola_lunghezza_nome_cognome_2:
    xorl %eax, %eax            
    xorl %ecx, %ecx
    xorl %esi, %esi
    leal nome_cognome_buffer_anagrafica, %esi

# funzione che calcola la lunghezza del nome e cognome
loop_lunghezza_nome_cognome_2:
    movb (%esi), %al     # leggi il byte corrente

    cmpb $0, %al               # è \0?
    je calcola_lunghezza_risultati_2         # se sì, termina

    incl %esi

    movl lunghezza_nome_cognome_2, %ecx
    incl %ecx                  # altrimenti aumenta contatore
    movl %ecx, lunghezza_nome_cognome_2
    jmp loop_lunghezza_nome_cognome_2

# funzione che si prepara a calcolare la lunghezza dei risultati
calcola_lunghezza_risultati_2:
    xorl %eax, %eax            
    xorl %ecx, %ecx
    xorl %esi, %esi
    leal risultati_buffer, %esi

# funzione che calcola la lunghezza dei risultati
loop_lunghezza_risultati_2:
    movb (%esi), %al     # leggi il byte corrente

    cmpb $0, %al               # è \0?
    je stampa_nome_cognome_2         # se sì, termina

    incl %esi

    movl lunghezza_risultati_2, %ecx
    incl %ecx                  # altrimenti aumenta contatore
    movl %ecx, lunghezza_risultati_2
    jmp loop_lunghezza_risultati_2

# funzione che stampa il nome e cognome dello studente
stampa_nome_cognome_2:
    movl $4, %eax
    movl $1, %ebx
    leal nome_cognome_2, %ecx
    movl nome_cognome_len_2, %edx
    int $0x80

    movl $4, %eax
    movl $1, %ebx
    leal nome_cognome_buffer_anagrafica, %ecx
    movl lunghezza_nome_cognome_2, %edx
    int $0x80

    jmp stampa_risultati

# funzione che stampa i risultati dello studente
stampa_risultati:
    movl $4, %eax
    movl $1, %ebx
    leal risultati_2, %ecx
    movl risultati_len_2, %edx
    int $0x80

    movl $4, %eax
    movl $1, %ebx
    leal risultati_buffer, %ecx
    movl lunghezza_risultati_2, %edx
    int $0x80
    
    jmp stampa_media_aritmetica_2

# funzione che chiude il file e ritorna al chiamante
.close_and_exit_libretti:
    movl $6, %eax
    movl fd_libretti, %ebx
    int $0x80

    jmp calcola_lunghezza_nome_cognome_2

# funzione che gestisce l'errore di apertura del file libretti
._error_open_libretti:
    movl $4, %eax
    movl $1, %ebx
    leal errore_apertura_file_libretti, %ecx      # stampa il messaggio di errore
    movl errore_apertura_file_libretti_len, %edx
    int $0x80

    movl $1, %eax
    movl $1, %ebx
    int $0x80
