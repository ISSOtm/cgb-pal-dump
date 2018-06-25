
all: cgb_pal_dump.gbc


%.o: %.asm
	rgbasm -h -p 0 -o $@ $^

%.gbc: %.o
	rgblink -t -p 0 -o $@ $^
	rgbfix -Cv -m 0x13 -r 2 -p 0 $@
