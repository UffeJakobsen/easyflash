
    .importzp       sp, sreg, regsave
    .importzp       ptr1, ptr2, ptr3, ptr4
    .importzp       tmp1, tmp2, tmp3, tmp4

    .import         popax

    .import eload_send
    .import eload_recv
    .import _eload_prepare_drive

gcr_overflow_size = 69


; =============================================================================
;
; void __fastcall__ eload_write_sector(unsigned ts, uint8_t* block);
;
; =============================================================================
.export _eload_write_sector
_eload_write_sector:
        sta block_tmp
        stx block_tmp + 1       ; Save buffer

        jsr popax
        stx trk_tmp             ; track
        sta sec_tmp             ; sector

        php                     ; to backup the interrupt flag
        sei

        lda #1                  ; command: write sector
        sta job
        lda #<job
        ldx #>job
        ldy #3
        jsr eload_send

        ; this will go to the GCR overflow buffer $1bb
        lda block_tmp
        ldx block_tmp + 1
        ldy #gcr_overflow_size
        jsr eload_send

        ; this will go to the main buffer
        ldx block_tmp + 1
        clc
        lda block_tmp
        adc #gcr_overflow_size
        bcc :+
        inx
:
        iny                     ; Y = 0xff => 0 = 256 bytes
        jsr eload_send

        plp                     ; to restore the interrupt flag
        rts

.bss
; keep the order of these three bytes
job:
        .res 1
trk_tmp:
        .res 1
sec_tmp:
        .res 1
block_tmp:
        .res 2
