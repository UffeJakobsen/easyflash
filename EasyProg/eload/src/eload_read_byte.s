


.include "kernal.i"

.import eload_ctr
.import eload_recv

.bss

; points to the function to read bytes
eload_read_byte_fn:
        .res 2

; the first byte of a file is read upon open already, it is buffered here
.export eload_buffered_byte
eload_buffered_byte:
        .res 1

.code

; =============================================================================
;
; Read a byte from the file.
; int eload_read_byte(void);
;
; parameters:
;       -
;
; return:
;       result in AX (A = low), 0 = okay, -1 = error
;
; =============================================================================
.export _eload_read_byte
_eload_read_byte:
        jmp (eload_read_byte_fn)

; =============================================================================
;
; Set eload_read_byte_fn. Used internally only.
;
; parameters:
;       pointer to function in AX (A = low)
;
; return:
;       -
; =============================================================================
.export eload_set_read_byte_fn
eload_set_read_byte_fn:
        sta eload_read_byte_fn
        stx eload_read_byte_fn + 1
        rts

; =============================================================================
;
; Implementation for eload_read_byte. Used internally only.
; This version returns the buffered byte and redirects further calls to
; read_byte_kernal.
;
; =============================================================================
.export eload_read_byte_from_buffer
eload_read_byte_from_buffer:
        lda #<eload_read_byte_kernal
        ldx #>eload_read_byte_kernal
        jsr eload_set_read_byte_fn

        lda eload_buffered_byte
        ldx #0
        rts

; =============================================================================
;
; Implementation for eload_read_byte. Used internally only.
; This version reads the byte from the serial bus using ACPTR.
; TALK must have been sent already.
;
; =============================================================================
.export eload_read_byte_kernal
eload_read_byte_kernal:
        jsr ACPTR
        ldx ST
        beq @rts
        lda #$ff
        tax
@rts:
        rts


; =============================================================================
;
; Implementation for eload_read_byte. Used internally only.
; Use the fast protocol to read a byte from the bus.
;
; =============================================================================
.export eload_read_byte_fast
eload_read_byte_fast:
        lda eload_ctr
        beq @nextblock
@return:
        dec eload_ctr
        jsr eload_recv
        ldx #0
        rts
@nextblock:
        jsr eload_recv
        beq @eof
        sta eload_ctr
        cmp #$ff        ; error flag
        bne @return
@eof:
        lda #$ff
        tax
        rts
