
all:	main.hex

install:	main.hex
	pk2cmd -P PIC12f683 -F $< -M
clean:
	rm *.as *.cof *.d *.hex *.hxl *.lst *.p1 *.pre *.sdb *.sym startup.* funclist

main.hex:	main.c
	xc8 --CHIP=12f683 $<

