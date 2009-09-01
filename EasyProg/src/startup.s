;
; EasyFlash - startup.s - Start-up code for stand-alone cartridges (acme)
;
; (c) 2009 Thomas 'skoe' Giesel
;
; This software is provided 'as-is', without any express or implied
; warranty.  In no event will the authors be held liable for any damages
; arising from the use of this software.
;
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
;
; 1. The origin of this software must not be misrepresented; you must not
;    claim that you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation would be
;    appreciated but is not required.
; 2. Altered source versions must be plainly marked as such, and must not be
;    misrepresented as being the original software.
; 3. This notice may not be removed or altered from any source distribution.

; This code runs in Ultimax mode after reset, so this memory becomes
; visible at $E000..$FFFF first and must contain a reset vector

* = $ff00

EASYFLASH_BANK    = $DE00
EASYFLASH_CONTROL = $DE02
EASYFLASH_LED     = $80
EASYFLASH_16K     = $07
EASYFLASH_KILL    = $04

DELAY_COUNTER     = $0200

; must be in the area $0000 to $0FFF
SCREEN_MEM        = $0400
START_MEM         = $0400
SPRITE_RAM        = $0600

; In Ultimax mode we see the sprites there:
SPRITE_ROM        = $F800

startBank:
        ; this must be the 1st byte in this code, so it's easy to patch it from outside
        !byte 0

startConfig:
        ; this must be the 2nd byte in this code, so it's easy to patch it from outside
        !byte 0

startUpCode:
        !pseudopc START_MEM {
            ; === this is copied to the START_MEM, does some inits ===
            ; === scans the keyboard and kills the cartridge or    ===
            ; === starts the main cartridge                        ===
            lda #EASYFLASH_16K | EASYFLASH_LED
            sta EASYFLASH_CONTROL

            ; set color ram to black
            lda #0
            ldx #251
colorClear:
            sta $d7ff, x
            sta $d7ff + 250, x
            sta $d7ff + 500, x
            sta $d7ff + 750, x
            dex
            bne colorClear

            ; init VIC
            ldx #$2f
vicInit:
            lda vicData, x
            sta $d000, x
            dex
            bpl vicInit

            ; set sprite pointers
            ldx #SPRITE_RAM / 64
            stx SCREEN_MEM + 1016 + 0
            inx
            stx SCREEN_MEM + 1016 + 1
            inx
            stx SCREEN_MEM + 1016 + 2
            inx
            stx SCREEN_MEM + 1016 + 3
            inx
            stx SCREEN_MEM + 1016 + 4
            inx
            stx SCREEN_MEM + 1016 + 5
            inx
            stx SCREEN_MEM + 1016 + 6
            inx
            stx SCREEN_MEM + 1016 + 7

            ; Prepare the CIA to scan the keyboard
            lda #$7f
            sta $dc00   ; pull down row 7 (DPA)

            ldx #$ff
            stx $dc02   ; DDRA $ff = output (X is still $ff from copy loop)
            inx
            stx $dc03   ; DDRB $00 = input

            ; x is 0 here
checkAgain:
            ; Read the keys pressed on this row
            lda $dc01   ; read coloumns (DPB)

            ; Check if one of the magic kill keys was pressed
            and #$e0    ; only leave "Run/Stop", "Q" and "C="
            cmp #$e0
            bne kill    ; branch if one of these keys is pressed

            dec EASYFLASH_16K
            bne checkAgain
            dex
            bne checkAgain
startCart:
            ; start the cartridge code on the right bank
patchStartBank = * + 1
            lda #0      ; start bank will be put here
            sta EASYFLASH_BANK
patchStartConfig = * + 1
            lda #0      ; start config will be put here
            !byte $2c   ; skip next instruction
kill:
            lda #EASYFLASH_KILL
reset:
            sta EASYFLASH_CONTROL

            ; Restore CIA registers to the state after (hard) reset
            lda #0
            sta $dc02   ; DDRA input again
            sta $dc00   ; Now row pulled down

            jmp ($fffc) ; reset

vicData:
            !byte 0, 50, 24, 50, 48, 50, 72, 50  ; D000..D00F Sprite X/Y
            !byte 37, 50, 20, 231, 44, 231, 0, 0
            !byte $1f, $9B, $37, 0, 0            ; D010 Sprite X MSBs..D014
            !byte $7f                            ; D015 Sprite Enable
            !byte 8, 0                           ; D017
            !byte $14, $0F, 0, 0, 0, 0, 0, 0     ; D018..D01F
            !byte 0, 0, 0, 0, 0, 0, 0            ; D020..D026
            !byte 1, 1, 1, 1, 8, 12, 5, 0        ; D027..D02E Sprite Colors
        }
startUpEnd:

; ============================================================================
coldStart:
        ; === the reset vector points here ===
        sei
        ldx #$ff
        txs
        cld

        lda #8
        sta $d016       ; Enable VIC (e.g. RAM refresh)

        ; Wait to make sure RESET is deasserted on all chips and write
        ; to RAM to make sure it started up correctly (=> RAM datasheets)
startWait:
        sta $0100, x
        dex
        bne startWait

        ; copy the final start-up code to RAM
        ; we simply copy 256 bytes, that's fast enough and simple
        ; and we copy 512 bytes from SPRITE_ROM to SRPITE_RAM
        ldx #0
copyLoop:
        lda startUpCode, x
        sta START_MEM, x
        lda SPRITE_ROM, x
        sta SPRITE_RAM, x
        lda SPRITE_ROM + 0x100, x
        sta SPRITE_RAM + 0x100, x
        dex
        bne copyLoop
        lda startConfig
        sta patchStartConfig
        lda startBank
        sta patchStartBank

        jmp START_MEM

        ; fill it up to $FFFA to put the vectors there
        !align $ffff, $fffa, $ff

        !word reti        ; NMI
        !word coldStart   ; RESET

        ; we don't need the IRQ vector and can put RTI here to save space :)
reti:
        rti
        !byte 0xff
