
all:	main.hex

install:	main.hex
	pk2cmd -P PIC12f683 -F $< -M -R
clean:
	rm -f *.as *.cof *.d *.hex *.hxl *.lst *.p1 *.pre *.sdb *.sym *.map *.rlf startup.* funclist

main.hex:	main.asm
	xc8 -P --CHIP=12f683 -M$(<:.asm=.map) --RUNTIME=no_startup $<

