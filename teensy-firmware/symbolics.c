/* Symbolics keyboard adapter, based on Teensy keyboard example */

/* Keyboard example for Teensy USB Development Board
 * http://www.pjrc.com/teensy/usb_keyboard.html
 * Copyright (c) 2008 PJRC.COM, LLC
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#undef DEBUG

#include <avr/io.h>
#include <avr/pgmspace.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <string.h>
#if defined(DEBUG)
#include "debug.h"
#else
#include "usb_keyboard.h"
#endif

#define CPU_PRESCALE(n)	(CLKPR = 0x80, CLKPR = (n))

#define NUM_KEY_LEFT_CTRL   0
#define NUM_KEY_LEFT_SHIFT  1
#define NUM_KEY_LEFT_ALT    2
#define NUM_KEY_LEFT_GUI    3
#define NUM_KEY_RIGHT_CTRL  4
#define NUM_KEY_RIGHT_SHIFT 5
#define NUM_KEY_RIGHT_ALT   6
#define NUM_KEY_RIGHT_GUI   7

#include "keymap.inc"

// D4: data in (with pull-up enabled)
// D5: clock output (active low)
// D6: clear output (active low)

#define MASK_DIN 0x10
#define MASK_CLOCK 0x20
#define MASK_CLEAR 0x40

void
init_keyboard_interface(void)
{
  DDRD = MASK_CLOCK | MASK_CLEAR;
  PORTD = MASK_CLOCK | MASK_CLEAR | MASK_DIN;
}

void
poll_keyboard(uint8_t* state)
{
    PORTD &= ~MASK_CLEAR;
    _delay_us(10);
    PORTD |= MASK_CLEAR;
    _delay_us(100);
    for (int i = 0; i < 16; i++) {
      uint8_t buf = 0;
      for (int j = 0; j < 8; j++) {
        buf >>= 1;
        PORTD &= ~MASK_CLOCK;
        _delay_us(10);
        PORTD |= MASK_CLOCK;
        _delay_us(40);
        if (!(PIND & MASK_DIN)) {
          buf |= 0x80;
        }
      }
      state[i] = buf;
    }
}

void
send_keys(uint8_t* state)
{
  uint8_t key_index = 0;
  uint8_t map_index = 0;

  keyboard_modifier_keys = 0;
  memset(keyboard_keys, 0, sizeof keyboard_keys);

  for (int i = 0; i < 16; i++) {
    uint8_t buf = state[i];
    for (int j = 0; j < 8; j++) {
      uint8_t mapped = pgm_read_byte(&keymap[map_index++]);
      uint8_t pressed = (buf & 1);
#if defined(DEBUG)
      if (pressed) {
        print("key ");
        phex(map_index - 1);
        print(" pressed, mapped to ");
        phex(mapped);
        print("\n");
      }
#endif
      if (pressed && mapped) {
        if (mapped & 0x80) {
          keyboard_modifier_keys |= 1 << (mapped & 0x7F);
        } else {
          if (key_index < sizeof keyboard_keys) {
            keyboard_keys[key_index++] = mapped;
          }
        }
      }
      buf >>= 1;
    }
  }

#if !defined(DEBUG)
  usb_keyboard_send();
#endif
}

int
main(void)
{
  static uint8_t state[16];
  static uint8_t prev_state[16];

  // set for 16 MHz clock
  CPU_PRESCALE(0);

  init_keyboard_interface();

  // Initialize the USB, and then wait for the host to set configuration.
  // If the Teensy is powered without a PC connected to the USB port,
  // this will wait forever.
  usb_init();
  while (!usb_configured()) /* wait */ ;

  // Wait for the PC's operating system to load drivers
  // and do whatever it does to actually be ready for input
  _delay_ms(3000);

  memset(prev_state, 0, sizeof prev_state);
  while (1) {
    poll_keyboard(state);
    if (memcmp(state, prev_state, sizeof state)) {
      send_keys(state);
      memcpy(prev_state, state, sizeof state);
    }
    _delay_ms(10);
  }
}

