
#ifndef MEMCFG_H
#define MEMCFG_H

#if 1
#define EF_MENU_CHAR_BASED
#define EF_MENU_NO_KERNAL

#define P_VIC_BASE      ((uint8_t*)0x0000)
#define P_GFX_BITMAP    ((uint8_t*)0x2000)
#define P_GFX_COLOR     ((uint8_t*)0x0400)
//#define P_WND_SPRITES   ((uint8_t*)0x4800)

#else

#define P_VIC_BASE      ((uint8_t*)0x4000)
#define P_GFX_COLOR     ((uint8_t*)0x5C00)
#define P_GFX_BITMAP    ((uint8_t*)0x6000)
//#define P_WND_SPRITES   ((uint8_t*)0x6800)

#endif

#define P_SPR_PTRS      (GFX_COLOR + 0x3f8)

#endif
