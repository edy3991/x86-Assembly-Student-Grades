AS_FLAGS = --32 
DEBUG = -gstabs
LD_FLAGS = -m elf_i386

all: bin/appelli

bin/appelli: obj/appelli.o obj/carica_file_reg.o obj/carica_file_anagrafica_menu.o obj/carica_file_libretti_menu.o obj/funzione_graduatoria.o obj/carica_file_libretti.o obj/carica_file_anagrafica.o obj/gestisci_codice_esame.o
	ld $(LD_FLAGS)  obj/appelli.o obj/carica_file_reg.o obj/carica_file_anagrafica.o obj/carica_file_libretti.o obj/carica_file_anagrafica_menu.o obj/carica_file_libretti_menu.o obj/funzione_graduatoria.o obj/gestisci_codice_esame.o -o bin/appelli

obj/appelli.o: src/appelli.s
	as $(AS_FLAGS) $(DEBUG) src/appelli.s -o obj/appelli.o
	
obj/carica_file_reg.o: src/carica_file_reg.s
	as $(AS_FLAGS) $(DEBUG) src/carica_file_reg.s -o obj/carica_file_reg.o
	
obj/carica_file_anagrafica.o: src/carica_file_anagrafica.s
	as $(AS_FLAGS) $(DEBUG) src/carica_file_anagrafica.s -o obj/carica_file_anagrafica.o
	
obj/carica_file_anagrafica_menu.o: src/carica_file_anagrafica_menu.s
	as $(AS_FLAGS) $(DEBUG) src/carica_file_anagrafica_menu.s -o obj/carica_file_anagrafica_menu.o
	
obj/carica_file_libretti_menu.o: src/carica_file_libretti_menu.s
	as $(AS_FLAGS) $(DEBUG) src/carica_file_libretti_menu.s -o obj/carica_file_libretti_menu.o	
	
obj/carica_file_libretti.o: src/carica_file_libretti.s
	as $(AS_FLAGS) $(DEBUG) src/carica_file_libretti.s -o obj/carica_file_libretti.o
	
obj/funzione_graduatoria.o: src/funzione_graduatoria.s
	as $(AS_FLAGS) $(DEBUG) src/funzione_graduatoria.s -o obj/funzione_graduatoria.o
	
obj/gestisci_codice_esame.o: src/gestisci_codice_esame.s
	as $(AS_FLAGS) $(DEBUG) src/gestisci_codice_esame.s -o obj/gestisci_codice_esame.o

clean:
	rm -f obj/*.o bin/appelli
