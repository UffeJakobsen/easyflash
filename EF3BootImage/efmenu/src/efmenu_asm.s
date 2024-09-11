;
; (c) 2010 Thomas Giesel
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
;
; Thomas Giesel skoe@directbox.com
;

.include "c64.inc"
.include "memcfg.inc"

.importzp   ptr1, ptr2, ptr3, ptr4
.importzp   tmp1, tmp2, tmp3, tmp4
.import     popa

EASYFLASH_16K        = $07
EASYFLASH_KILL       = $04

MODE_EF_NO_RESET     = $01

; I/O address used to select the bank
EASYFLASH_IO_BANK    = $de00

; I/O address used to select the slot
EASYFLASH_IO_SLOT    = $de01

; I/O address for enabling memory configuration, /GAME and /EXROM states
EASYFLASH_IO_CONTROL = $de02

; I/O address to set the KERNAL bank
EASYFLASH3_IO_KERNAL_BANK   = $de0e

; I/O address to set the cartridge mode
EASYFLASH3_IO_MODE          = $de0f

.code

; =============================================================================
;
; Set the EF slot.
;
; void __fastcall__ set_slot(uint8_t slot)
;
; in:
;       slot    slot to be set
; out:
;       -
;
.export _set_slot
_set_slot:
        sta EASYFLASH_IO_SLOT
        rts

; =============================================================================
;
; Set the EF bank.
;
; void __fastcall__ set_bank(uint8_t bank)
;
; in:
;       bank    bank to be set
; out:
;       -
;
.export _set_bank
_set_bank:
        sta EASYFLASH_IO_BANK
        rts

; =============================================================================
;
; Set the EF ROM bank and change to the given cartridge mode.
;
; void __fastcall__ set_bank_change_mode(uint8_t bank, uint8_t mode)
;
; in:
;       bank    bank to be set
;       mode    cartridge mode to be set
; out:
;       Never returns
;
.export _set_bank_change_mode
_set_bank_change_mode:
        sta tmp2    ; 2nd argument
        jsr popa    ; 1st argument
        sta tmp1

        sei
        ldx #sbcm_codeEnd - sbcm_code
sbcm_copy:
        ; copy code on stack
        lda sbcm_code, x
        sta $0100, x
        dex
        bpl sbcm_copy
        jmp $0100

sbcm_code:
.org $0100
        ; the following code will be run at $0100
        lda tmp1
        sta EASYFLASH_IO_BANK
        sta EASYFLASH3_IO_KERNAL_BANK

        lda tmp2
        sta EASYFLASH3_IO_MODE
        ; we don't pass here normally
sbcm_wait:
        dec $d020
        jmp sbcm_wait
.reloc
sbcm_codeEnd:


; =============================================================================
;
; Set the EF ROM bank, copy 16k to 0x0801 and run that program by jumping to
; 0x080d.
;
; The program in flash contains two byte start address, we copy them to
; $07ff to get a faster copy loop.
;
;
; void __fastcall__ start_program(uint8_t bank);
;
; in:
;       bank    bank to be set
; out:
;       Never returns
;
.export _start_program
_start_program:
        pha
        lda #MODE_EF_NO_RESET
        sta EASYFLASH3_IO_MODE          ; hides the mode register
        lda #0
        sta $d011                       ; disable VIC-II output
        lda #EASYFLASH_16K
        sta EASYFLASH_IO_CONTROL
        ldx #$00
:
        lda start_program_code,x
        sta $c000,x
        dex
        bne :-
        pla
        sta start_program_bank

        lda #<$07ff
        sta ptr1
        lda #>$07ff                     ; 2 bytes more = start address
        sta ptr1 + 1                    ; ptr1 = target

        lda #<$8000
        sta ptr2
        lda #>$8000
        sta ptr2 + 1                    ; ptr2 = source

        jmp $c000

start_program_code:
.org $c000
        sei
        ldx #32 * 4                     ; number of blocks to copy
        ldy #0
start_program_bank = * + 1
@loop:
        lda #0
        sta EASYFLASH_IO_BANK
@copy:
@i1:
        lda (ptr2), y
        sta (ptr1), y
        iny
        lda (ptr2), y
        sta (ptr1), y
        iny
        lda (ptr2), y
        sta (ptr1), y
        iny
        lda (ptr2), y
        sta (ptr1), y
        iny
        bne @copy
        inc ptr1 + 1                    ; inc high byte of target
        inc ptr2 + 1
        lda ptr2 + 1
        cmp #$c0                        ; wrap $c000 => $8000
        bne @noBankInc
        inc start_program_bank          ; next bank
        lda #$80
        sta ptr2 + 1
@noBankInc:
        dex
        bne @loop

        lda #EASYFLASH_KILL
        sta EASYFLASH_IO_CONTROL

        jsr $ff84   ; Initialise I/O
        jsr $ff8a   ; Restore Kernal Vectors
        jsr $ff81   ; Initialize screen editor

        jmp $080d
.reloc

; =============================================================================
;
; Wait until no key is pressed.
;
; void wait_for_no_key(void)
;
; in:
;       -
; out:
;       -
;
.export _wait_for_no_key
_wait_for_no_key:
        ; Prepare the CIA to scan the keyboard
        sei
        ldx #$00
        stx $dc00       ; Port A: pull down all rows
        stx $dc03       ; DDRB $00 = input
        dex
        stx $dc02       ; DDRA $ff = output
wfnk:
        lda $dc01
        cmp #$ff        ; still a key pressed?
        bne wfnk
        cli
        rts

; =============================================================================
;
; uint8_t
;
; in:
;       -
; out:
;       -
;

.export _get_key
_get_key:
        ; Prepare the CIA to scan the keyboard
        sei
        ldx #$ff
        stx $dc02       ; DDRA $ff = output
        inx
        stx $dc03       ; DDRB $00 = input
sfr:
        lda #$00
        sta $dc00       ; Port A: pull down all rows
wfk:
        lda $dc01
        cmp #$ff        ; is a key pressed?
        beq ok

        ldx #$00
sfc1:   lda bitmap_inv,x
        sta $dc00
        ldy $dc01
        cpy #$ff
        bne sfc2
        inx
        cpx #$08
        bne sfc1
        beq nok

sfc2:
        txa
        asl
        asl
        asl
        tax

        tya
        eor #$ff
shr1:
        cmp #$00
        beq nok
        inx
        lsr
        bcc shr1

        dex
        lda keytab_unshifted,x
        cmp #$01        ; continue if we found left shift
        beq nxt1
        cmp #$02        ; continue if we found right shift
        beq nxt1
        jmp ok

nxt1:   inx
        jmp shr1

nok:    lda #$ff
ok:     cli
        rts

;bitmap:
;        .byte $01, $02, $04, $08, $10, $20, $40, $80

bitmap_inv:
        .byte $ff-1, $ff-2, $ff-4, $ff-8, $ff-16, $ff-32, $ff-64, $ff-128

tax
lsr
lsr
lsr
lsr
and #$0f
cmp #$0a
cmp *+3
clc
adc #$07
clc
adc #$30
sta $0400+40+0
txa
and #$0f
cmp *+3
clc
adc #$07
clc
adc #$30
sta $0400+40+1
rts


keytab_unshifted:
	.byte $14,$0D,$1D,$88,$85,$86,$87,$11 ; row 0
	.byte $33,$57,$41,$34,$5A,$53,$45,$01 ; row 1
	.byte $35,$52,$44,$36,$43,$46,$54,$58 ; row 2
	.byte $37,$59,$47,$38,$42,$48,$55,$56 ; row 3
	.byte $39,$49,$4A,$30,$4D,$4B,$4F,$4E ; row 4
	.byte $2B,$50,$4C,$2D,$2E,$3A,$40,$2C ; row 5
	.byte $5C,$2A,$3B,$13,$02,$3D,$5E,$2F ; row 6
	.byte $31,$5F,$05,$32,$20,$03,$51,$04 ; row 7

keytab_shifted:
	.byte $94,$8D,$9D,$8C,$89,$8A,$8B,$91
	.byte $23,$D7,$C1,$24,$DA,$D3,$C5,$01
	.byte $25,$D2,$C4,$26,$C3,$C6,$D4,$D8
	.byte $27,$D9,$C7,$28,$C2,$C8,$D5,$D6
	.byte $29,$C9,$CA,$30,$CD,$CB,$CF,$CE
	.byte $DB,$D0,$CC,$DD,$3E,$5B,$BA,$3C
	.byte $A9,$C0,$5D,$93,$01,$3D,$DE,$3F
	.byte $21,$5F,$04,$22,$A0,$02,$D1,$83


; =============================================================================
;
; Return 0 if we're on a C64, other values for a C128.
;
; uint8_t is_c128(void);
;
; in:
;       -
; out:
;       -
;
.export _is_c128
_is_c128:
        ldx $d030
        inx
        txa
        rts

; =============================================================================
;
; Return 0 if Shift is not pressed, != 0 otherwise.
;
; uint8_t shift_pressed(void);
;
; in:
;       -
; out:
;       -
;
.export _shift_pressed
_shift_pressed:
        lda $028d
        and #1
        tax
        rts
