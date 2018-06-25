
INCLUDE "hardware.inc"


; 2 bytes/color * 4 colors/palette * 8 palettes = 64 ($40) bytes
; $2000 bytes of SRAM / $40 bytes/palette = $80 palettes, minus 1 for the 64 bytes of "header"

CGRAM_SIZE = 2 * 4 * 8


SECTION "Header", ROM0[$100]

EntryPoint:
    di
    ld c, a
    jr Start

    ds $150 - $104


Start:
    ldh a, [rLY]
    cp SCRN_Y
    jr c, Start
    xor a
    ldh [rLCDC], a

    ldh [rSCX], a
    ldh [rSCY], a

    ldh [rIF], a
    ldh [rIE], a


    ; Copy font
    ld hl, $9000
.blankTiles
    xor a
    ld [hli], a
    ld a, h
    cp $92
    jr nz, .blankTiles

    ld de, Font
.copyFont
    ld a, [de]
    ld [hli], a
    inc de
    ld a, h
    cp $98
    jr nz, .copyFont

.blankScreen
    xor a
    ld [hli], a
    ld a, h
    cp $9C
    jr nz, .blankScreen


    ; Check console type
    ld a, c
    cp $11
    jr z, .consoleOK
    ld de, CGBOnlyStr
    ld hl, $98C1
.copyCGBOnlyStr
    ld a, [de]
    ld [hli], a
    inc de
    and a
    jr nz, .copyCGBOnlyStr
    ; Display it
    ld a, $E4
    ldh [rBGP], a
    ld a, LCDCF_ON | LCDCF_WINOFF | LCDCF_BG8800 | LCDCF_BG9800 | LCDCF_OBJOFF | LCDCF_BGON
    ldh [rLCDC], a
.DMGlock
    halt
    jr .DMGlock


.consoleOK

    ld a, CART_RAM_ENABLE
    ld [rRAMG], a
    xor a
    ld [rRAMB], a


    ; Check if A is being held
    ld a, $10 ; Select buttons
    ldh [rP1], a
REPT 6
    ldh a, [rP1]
ENDR
    rra
    jr nc, .reset ; If held (zero), forcefully reset

    ; Check if SRAM has been inited
    ld hl, _SRAM
    ld de, SRAMPattern
.compare
    ld a, [de]
    cp [hl]
    jr nz, .init
    inc de
    inc hl
    and a
    jr nz, .compare
    ld a, [hl]
    inc a
    cp $7F
    jr nc, .SRAMFull
    jr .getPtr

.reset
    ld de, ResetStr
    ld hl, $98A2
.copyResetStr
    ld a, [de]
    ld [hli], a
    inc de
    and a
    jr nz, .copyResetStr

    ld hl, _SRAM
    ld de, SRAMPattern
    ; Copy rest of pattern
.init
    ld a, [de]
    ld [hli], a
    inc de
    and a
    jr nz, .init

    xor a
.getPtr
    ld [hli], a
    ld e, a ; Save for later
    ; Multiply by CGRAM_SIZE ($40)
    ld c, 0
    srl a
    rr c
    rra ; Carry clear
    rr c
    ld b, a
    add hl, bc ; Add to base ptr


    ld bc, LOW(rOCPD)
.loop
    ld a, b
    cp CGRAM_SIZE
    jr nc, .done
    ldh [rOCPS], a
    ld a, [$ff00+c]
    ld [hli], a
    inc b
    jr .loop


.SRAMFull
    ld de, SRAMFullStr
    ld hl, $98C1
    jr .copyDoneStr


.done
    ld hl, $98C0
    ld a, e
    inc a
    cp 100
    jr c, .no100
    ld [hl], "1"
    sub 100
.no100
    inc hl
    ld d, "0" - 1
.getDigit
    inc d
    sub 10
    jr nc, .getDigit
    add 10 + "0"

    ld [hl], d
    inc hl
    ld [hli], a

    ld de, DoneStr
.copyDoneStr
    ld a, [de]
    ld [hli], a
    inc de
    and a
    jr nz, .copyDoneStr

    ; Re-lock SRAM
    xor a
    ld [rRAMG], a

    ld de, PressAStr
    ld hl, $9901
.copyPressAStr
    ld a, [de]
    ld [hli], a
    inc de
    and a
    jr nz, .copyPressAStr

    ld a, $84
    ldh [rBCPS], a
    xor a
    ldh [rBCPD], a
    ldh [rBCPD], a

    ld a, LCDCF_ON | LCDCF_WINOFF | LCDCF_BG8800 | LCDCF_BG9800 | LCDCF_OBJOFF | LCDCF_BGON
    ldh [rLCDC], a

.lock
    halt
    jr .lock


; Data

SRAMPattern:
    db "CGB PALETTE DUMPER BY ISSOtm/Eldred Habert. SRAM INTEGRITY OK!", 0


CGBOnlyStr:
    db "RUN THIS ON GBC/GBA", 0


SRAMFullStr:
    db "CANNOT DUMP ANYMORE", 0


ResetStr:
    db "RESET SUCCESSFUL", 0

DoneStr:
    db " INSTANCES DUMPED", 0

PressAStr::
    db "HOLD A DURING BOOT "
    db "            "
    db "      TO RESET", 0



Font:
    dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000 ; Space

    ; Symbols 1
    dw $8000, $8000, $8000, $8000, $8000, $0000, $8000, $0000
    dw $0000, $6C00, $6C00, $4800, $0000, $0000, $0000, $0000
    dw $4800, $FC00, $4800, $4800, $4800, $FC00, $4800, $0000
    dw $1000, $7C00, $9000, $7800, $1400, $F800, $1000, $0000
    dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000 ; %, empty slot for now
    dw $6000, $9000, $5000, $6000, $9400, $9800, $6C00, $0000
    dw $0000, $3800, $3800, $0800, $1000, $0000, $0000, $0000
    dw $1800, $2000, $2000, $2000, $2000, $2000, $1800, $0000
    dw $1800, $0400, $0400, $0400, $0400, $0400, $1800, $0000
    dw $0000, $1000, $5400, $3800, $5400, $1000, $0000, $0000
    dw $0000, $1000, $1000, $7C00, $1000, $1000, $0000, $0000
    dw $0000, $0000, $0000, $0000, $3000, $3000, $6000, $0000
    dw $0000, $0000, $0000, $7C00, $0000, $0000, $0000, $0000
    dw $0000, $0000, $0000, $0000, $0000, $6000, $6000, $0000
    dw $0000, $0400, $0800, $1000, $2000, $4000, $8000, $0000
    dw $3000, $5800, $CC00, $CC00, $CC00, $6800, $3000, $0000
    dw $3000, $7000, $F000, $3000, $3000, $3000, $FC00, $0000
    dw $7800, $CC00, $1800, $3000, $6000, $C000, $FC00, $0000
    dw $7800, $8C00, $0C00, $3800, $0C00, $8C00, $7800, $0000
    dw $3800, $5800, $9800, $FC00, $1800, $1800, $1800, $0000
    dw $FC00, $C000, $C000, $7800, $0C00, $CC00, $7800, $0000
    dw $7800, $CC00, $C000, $F800, $CC00, $CC00, $7800, $0000
    dw $FC00, $0C00, $0C00, $1800, $1800, $3000, $3000, $0000
    dw $7800, $CC00, $CC00, $7800, $CC00, $CC00, $7800, $0000
    dw $7800, $CC00, $CC00, $7C00, $0C00, $CC00, $7800, $0000
    dw $0000, $C000, $C000, $0000, $C000, $C000, $0000, $0000
    dw $0000, $C000, $C000, $0000, $C000, $4000, $8000, $0000
    dw $0400, $1800, $6000, $8000, $6000, $1800, $0400, $0000
    dw $0000, $0000, $FC00, $0000, $FC00, $0000, $0000, $0000
    dw $8000, $6000, $1800, $0400, $1800, $6000, $8000, $0000
    dw $7800, $CC00, $1800, $3000, $2000, $0000, $2000, $0000
    dw $0000, $2000, $7000, $F800, $F800, $F800, $0000, $0000 ; "Up" arrow, not ASCII but otherwise unused :P

    ; Uppercase
    dw $3000, $4800, $8400, $8400, $FC00, $8400, $8400, $0000
    dw $F800, $8400, $8400, $F800, $8400, $8400, $F800, $0000
    dw $3C00, $4000, $8000, $8000, $8000, $4000, $3C00, $0000
    dw $F000, $8800, $8400, $8400, $8400, $8800, $F000, $0000
    dw $FC00, $8000, $8000, $FC00, $8000, $8000, $FC00, $0000
    dw $FC00, $8000, $8000, $FC00, $8000, $8000, $8000, $0000
    dw $7C00, $8000, $8000, $BC00, $8400, $8400, $7800, $0000
    dw $8400, $8400, $8400, $FC00, $8400, $8400, $8400, $0000
    dw $7C00, $1000, $1000, $1000, $1000, $1000, $7C00, $0000
    dw $0400, $0400, $0400, $0400, $0400, $0400, $F800, $0000
    dw $8400, $8800, $9000, $A000, $E000, $9000, $8C00, $0000
    dw $8000, $8000, $8000, $8000, $8000, $8000, $FC00, $0000
    dw $8400, $CC00, $B400, $8400, $8400, $8400, $8400, $0000
    dw $8400, $C400, $A400, $9400, $8C00, $8400, $8400, $0000
    dw $7800, $8400, $8400, $8400, $8400, $8400, $7800, $0000
    dw $F800, $8400, $8400, $F800, $8000, $8000, $8000, $0000
    dw $7800, $8400, $8400, $8400, $A400, $9800, $6C00, $0000
    dw $F800, $8400, $8400, $F800, $9000, $8800, $8400, $0000
    dw $7C00, $8000, $8000, $7800, $0400, $8400, $7800, $0000
    dw $7C00, $1000, $1000, $1000, $1000, $1000, $1000, $0000
    dw $8400, $8400, $8400, $8400, $8400, $8400, $7800, $0000
    dw $8400, $8400, $8400, $8400, $8400, $4800, $3000, $0000
    dw $8400, $8400, $8400, $8400, $B400, $CC00, $8400, $0000
    dw $8400, $8400, $4800, $3000, $4800, $8400, $8400, $0000
    dw $4400, $4400, $4400, $2800, $1000, $1000, $1000, $0000
    dw $FC00, $0400, $0800, $1000, $2000, $4000, $FC00, $0000

    ; Symbols 2
    dw $3800, $2000, $2000, $2000, $2000, $2000, $3800, $0000
    dw $0000, $8000, $4000, $2000, $1000, $0800, $0400, $0000
    dw $1C00, $0400, $0400, $0400, $0400, $0400, $1C00, $0000
    dw $1000, $2800, $0000, $0000, $0000, $0000, $0000, $0000
    dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $FF00
    dw $C000, $6000, $0000, $0000, $0000, $0000, $0000, $0000

    ; Lowercase
    dw $0000, $0000, $7800, $0400, $7C00, $8400, $7800, $0000
    dw $8000, $8000, $8000, $F800, $8400, $8400, $7800, $0000
    dw $0000, $0000, $7C00, $8000, $8000, $8000, $7C00, $0000
    dw $0400, $0400, $0400, $7C00, $8400, $8400, $7800, $0000
    dw $0000, $0000, $7800, $8400, $F800, $8000, $7C00, $0000
    dw $0000, $3C00, $4000, $FC00, $4000, $4000, $4000, $0000
    dw $0000, $0000, $7800, $8400, $7C00, $0400, $F800, $0000
    dw $8000, $8000, $F800, $8400, $8400, $8400, $8400, $0000
    dw $0000, $1000, $0000, $1000, $1000, $1000, $1000, $0000
    dw $0000, $1000, $0000, $1000, $1000, $1000, $E000, $0000
    dw $8000, $8000, $8400, $9800, $E000, $9800, $8400, $0000
    dw $1000, $1000, $1000, $1000, $1000, $1000, $1000, $0000
    dw $0000, $0000, $6800, $9400, $9400, $9400, $9400, $0000
    dw $0000, $0000, $7800, $8400, $8400, $8400, $8400, $0000
    dw $0000, $0000, $7800, $8400, $8400, $8400, $7800, $0000
    dw $0000, $0000, $7800, $8400, $8400, $F800, $8000, $0000
    dw $0000, $0000, $7800, $8400, $8400, $7C00, $0400, $0000
    dw $0000, $0000, $BC00, $C000, $8000, $8000, $8000, $0000
    dw $0000, $0000, $7C00, $8000, $7800, $0400, $F800, $0000
    dw $0000, $4000, $F800, $4000, $4000, $4000, $3C00, $0000
    dw $0000, $0000, $8400, $8400, $8400, $8400, $7800, $0000
    dw $0000, $0000, $8400, $8400, $4800, $4800, $3000, $0000
    dw $0000, $0000, $8400, $8400, $8400, $A400, $5800, $0000
    dw $0000, $0000, $8C00, $5000, $2000, $5000, $8C00, $0000
    dw $0000, $0000, $8400, $8400, $7C00, $0400, $F800, $0000
    dw $0000, $0000, $FC00, $0800, $3000, $4000, $FC00, $0000

    ; Symbols 3
    dw $1800, $2000, $2000, $4000, $2000, $2000, $1800, $0000
    dw $1000, $1000, $1000, $1000, $1000, $1000, $1000, $0000
    dw $3000, $0800, $0800, $0400, $0800, $0800, $3000, $0000
    dw $0000, $0000, $4800, $A800, $9000, $0000, $0000, $0000

    dw $C000, $E000, $F000, $F800, $F000, $E000, $C000, $0000 ; Left arrow
