#ifndef __FIR_H__
#define __FIR_H__

// fir reg address
#define reg_user_tap0	(*(volatile uint32_t*)0x30000080)
#define reg_user_tap1	(*(volatile uint32_t*)0x30000084)
#define reg_user_tap2	(*(volatile uint32_t*)0x30000088)
#define reg_user_tap3	(*(volatile uint32_t*)0x3000008C)
#define reg_user_tap4	(*(volatile uint32_t*)0x30000090)
#define reg_user_tap5	(*(volatile uint32_t*)0x30000094)
#define reg_user_tap6	(*(volatile uint32_t*)0x30000098)
#define reg_user_tap7	(*(volatile uint32_t*)0x3000009C)
#define reg_user_tap8	(*(volatile uint32_t*)0x300000A0)
#define reg_user_tap9	(*(volatile uint32_t*)0x300000A4)
#define reg_user_tap10	(*(volatile uint32_t*)0x300000A8)
#define reg_user_x	(*(volatile uint32_t*)0x300000C0)
#define reg_user_y	(*(volatile uint32_t*)0x300000C8)
#define reg_user_config	(*(volatile uint32_t*)0x30000000)
#define reg_user_len	(*(volatile uint32_t*)0x30000010)

#define N 11
extern int taps[N];

int fir();

#endif 

