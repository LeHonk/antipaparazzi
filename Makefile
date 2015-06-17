include $(wildcard *.deps)

all:	main.hex

install:	main.hex
	pk2cmd -P PIC12f683 -F $< -M -R
clean:
	rm -f *.as *.cof *.d *.hex *.hxl *.lst *.p1 *.pre *.sdb *.sym *.map *.rlf startup.* funclist
	rm -f *.cod *.o

%.o:		%.asm
	gpasm -c $<

%.hex:		%.o
	gplink -m -o $@ $<

%.stl:		%.scad
	openscad -m make -o $@ -d $@.deps $<
