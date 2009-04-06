/*
  symbolics.c - keyboard routines for symbolics keyboard
*/

#include "types.h"
#include "config.h"
#include "debug.h"

#include "cpu.h"
#include "board.h"
#include "console.h"

#include "symbolics.h"
#include "usb.h"

#define SYMBOLICS_PORT PORTC
#define SYMBOLICS_DDR  DDRC
#define SYMBOLICS_PIN  PINC

#define SYMBOLICS_CLR_PIN      0
#define SYMBOLICS_CLK_PIN      1
#define SYMBOLICS_DATA_PIN     2
#define SYMBOLICS_LED_CAPS_PIN 3
#define SYMBOLICS_LED_MODE_PIN 4

#define SYMBOLICS_SET_CLR   (sbi(SYMBOLICS_PORT, SYMBOLICS_CLR_PIN))
#define SYMBOLICS_CLEAR_CLR (cbi(SYMBOLICS_PORT, SYMBOLICS_CLR_PIN))
#define SYMBOLICS_SET_CLK   (sbi(SYMBOLICS_PORT, SYMBOLICS_CLK_PIN))
#define SYMBOLICS_CLEAR_CLK (cbi(SYMBOLICS_PORT, SYMBOLICS_CLK_PIN))

#define SYMBOLICS_LED_CAPS_SET (cbi(SYMBOLICS_PORT, SYMBOLICS_LED_CAPS_PIN))
#define SYMBOLICS_LED_CAPS_CLEAR (sbi(SYMBOLICS_PORT, SYMBOLICS_LED_CAPS_PIN))
#define SYMBOLICS_LED_MODE_SET (cbi(SYMBOLICS_PORT, SYMBOLICS_LED_MODE_PIN))
#define SYMBOLICS_LED_MODE_CLEAR (sbi(SYMBOLICS_PORT, SYMBOLICS_LED_MODE_PIN))


static inline void symbolics_clk_pulse(void) {
  SYMBOLICS_CLEAR_CLK;
  SYMBOLICS_SET_CLK;
}

static inline void symbolics_clr_pulse(void) {
  SYMBOLICS_CLEAR_CLR;
  SYMBOLICS_SET_CLR;
}

void symbolics_init(void) {
  sbi(SYMBOLICS_PORT, SYMBOLICS_DATA_PIN);
  SYMBOLICS_DDR = BV(SYMBOLICS_CLR_PIN) | BV(SYMBOLICS_CLK_PIN) |
    BV(SYMBOLICS_LED_CAPS_PIN) | BV(SYMBOLICS_LED_MODE_PIN);
  SYMBOLICS_LED_CAPS_SET;
  cpu_delay(CPU_SEC(1));
  SYMBOLICS_LED_CAPS_CLEAR;
  SYMBOLICS_LED_MODE_CLEAR;
}

u08_t kbd_buf[16];
u08_t cur_buf = 0;

void symbolics_read_kbd(void) {
  SYMBOLICS_LED_CAPS_SET;
  cpu_delay(CPU_MILLISEC(20));
  SYMBOLICS_LED_CAPS_CLEAR;

  symbolics_clr_pulse();

  int i;
  for (i = 0; i < 16; i++) {
    kbd_buf[i] = 0;

    u08_t j;
    for (j = 0; j < 8; j++) {
      symbolics_clk_pulse();
      if (SYMBOLICS_PIN & BV(SYMBOLICS_DATA_PIN))
	kbd_buf[i] |= (1 << j);
    }
  }
}

/*
  USB modifiers:
*/

u08_t sym2usb[128] = {
  /* 0x00 */
  0, 0, /* RSUPER, RCTRL */
  0, 0, /* LMETA, LHYPER */
  0, 0, /* CAPS LOCK, LOCAL */
  0, 0,

  0, 0, /* LSUPER, LSYMBOL */
  0, 0, /* SELECT,  */
  0, 0, 
  0, 0, /* MODE, SCROLL */
  
/* 0x10 */
  0, 0, 
  0, 0, /* , END */
  0, 0, /* RHYPER, RMETA */
  USB_KBD_SPACE, 0, /* SPACE, LCTRL */

  0, 0,  /* , RREPEAT */
  0,         USB_KBD_DOT, /* RSHIFT, . */
  USB_KBD_M, USB_KBD_B, 
  USB_KBD_C, USB_KBD_Z,

  /* 0x20 */
  USB_KBD_COMMA, USB_KBD_N, 
  USB_KBD_V,     USB_KBD_X, 
  0, 0, /* LSHIFT, */
  0, 0,

  USB_KBD_S, 0, /* ', RUBOUT */
  0, 0,
  0, 0,  /* , HELP */
  0,               USB_KBD_SLASH, /* RSYMBOL, / */
  
  /* 0x30 */
  0, 0, 
  0,               USB_KBD_ENTER,  /* COMPLETE, ENTER */
  USB_KBD_SEMICLN, USB_KBD_K, 
  USB_KBD_H,       USB_KBD_F,

  USB_KBD_APSTRPH, USB_KBD_L, 
  USB_KBD_J,   USB_KBD_G, 
  USB_KBD_D,   USB_KBD_A, 
  0, 0,

  /* 0x40 */
  USB_KBD_Y, USB_KBD_R, 
  USB_KBD_W, 0, /* W, FUNCTION */
  0, 0, 
  0, 0,
  
  USB_KBD_TAB, 0, 
  0, 0, 
  0,         USB_KBD_RBRCK, /* PAGE, [ */
  USB_KBD_P, USB_KBD_I,
  
  /* 0x50 */
  0,             USB_KBD_BSP, 
  USB_KBD_LBRCK, USB_KBD_O, 
  USB_KBD_U,     USB_KBD_T, 
  USB_KBD_E,     USB_KBD_Q,
  
  USB_KBD_0,         USB_KBD_8, 
  USB_KBD_6, USB_KBD_4,
  USB_KBD_2, 0,  /* 2, : */
  0, 0,
  
  /* 0x60 */
  USB_KBD_5,               USB_KBD_3, 
  USB_KBD_1,       0, 
  0, 0, 
  USB_KBD_BCKSLSH, USB_KBD_EQUAL,
  
  0, 0, 
  0, 0,  /* , PIPE */
  USB_KBD_BCKTCK, USB_KBD_DASH, 
  USB_KBD_9,      USB_KBD_7,
  
  /* 0x70 */
  0, 0, /* RESUME, SUSPEND */
  0, 0, /* CLEARINPUT, TRIANGLE */
  0, 0, /* CIRCLE, SQUARE */
  0, 0, /* REFRESH, ESCAPE */
  
  0, 0, 
  0, 0, 
  0, 0, 
  0, 0,
};

void symbolics_to_usb(void) {
  u08_t keys = 0;
  u08_t i;
  /* clear usb keyboard buffer */
  for (i = 0; i < 8; i++)
    usb_kbd_data[i] = 0;

  for (i = 0; i < 16; i++) {
    u08_t j;
    for (j = 0; j < 8; j++) {
      if (!(kbd_buf[i] & BV(7 - j))) {
	u08_t keycode = i * 8 + j;
	if (sym2usb[keycode] != 0) {
	  if (keys >= 6) {
	    PRINTF_APP("Too many keys pressed\n");
	    int k;
	    for (k = 2; k < 8; k++)
	      usb_kbd_data[k] = USB_KBD_PHANTOM;
	    return;
	  }

	  //	  PRINTF_APP("%d: key nr. %x pressed: %d\n", keys, keycode, sym2usb[keycode]);

	  usb_kbd_data[keys + 2] = sym2usb[keycode];
	  keys++;
	} else {
	  switch (i * 8 + j) {
	  case SYMBOLICS_RCTRL:
	    usb_kbd_data[0] |= USB_KBD_RCTRL;
	    break;
	  case SYMBOLICS_LCTRL:
	    usb_kbd_data[0] |= USB_KBD_LCTRL;
	    break;

	  case SYMBOLICS_RMETA:
	    usb_kbd_data[0] |= USB_KBD_RALT;
	    break;
	  case SYMBOLICS_LMETA:
	    usb_kbd_data[0] |= USB_KBD_LALT;
	    break;

	  case SYMBOLICS_RSHIFT:
	    usb_kbd_data[0] |= USB_KBD_RSHFT;
	    break;
	  case SYMBOLICS_LSHIFT:
	    usb_kbd_data[0] |= USB_KBD_LSHFT;
	    break;

	  case SYMBOLICS_RSUPER:
	    usb_kbd_data[0] |= USB_KBD_RWIN;
	    break;
	  case SYMBOLICS_LSUPER:
	    usb_kbd_data[0] |= USB_KBD_LWIN;
	    break;

	  default:
	    PRINTF_APP("Unknown key: %x\n", i * 8 + j);
	    break;
	  }
	}
      }
    }
  }
}
