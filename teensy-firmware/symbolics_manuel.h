#ifndef SYMBOLICS_H__
#define SYMBOLICS_H__

void symbolics_init(void);
void symbolics_read_kbd(void);
void symbolics_to_usb(void);

#define SYMBOLICS_RSUPER  0x00
#define SYMBOLICS_RCTRL   0x01
#define SYMBOLICS_LMETA   0x02
#define SYMBOLICS_LHYPER  0x03
#define SYMBOLICS_LSUPER  0x08
#define SYMBOLICS_LCTRL   0x17
#define SYMBOLICS_LSHIFT  0x24
#define SYMBOLICS_LSYMBOL 0x09
#define SYMBOLICS_RHYPER  0x14
#define SYMBOLICS_RMETA   0x15
#define SYMBOLICS_RSHIFT  0x1A
#define SYMBOLICS_RSYMBOL 0x2E

#endif /* SYMBOLICS_H__ */
