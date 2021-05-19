/*
 * Copyright © 2007,2008 Red Hat, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Soft-
 * ware"), to deal in the Software without restriction, including without
 * limitation the rights to use, copy, modify, merge, publish, distribute,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, provided that the above copyright
 * notice(s) and this permission notice appear in all copies of the Soft-
 * ware and that both the above copyright notice(s) and this permission
 * notice appear in supporting documentation.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABIL-
 * ITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF THIRD PARTY
 * RIGHTS. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR HOLDERS INCLUDED IN
 * THIS NOTICE BE LIABLE FOR ANY CLAIM, OR ANY SPECIAL INDIRECT OR CONSE-
 * QUENTIAL DAMAGES, OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE,
 * DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
 * TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFOR-
 * MANCE OF THIS SOFTWARE.
 *
 * Except as contained in this notice, the name of a copyright holder shall
 * not be used in advertising or otherwise to promote the sale, use or
 * other dealings in this Software without prior written authorization of
 * the copyright holder.
 *
 * Authors:
 *   Kristian Høgsberg (krh@redhat.com)
 */

#ifndef _DRI2_H_
#define _DRI2_H_

#include <X11/Xmd.h>
#include <X11/Xproto.h>
#include <X11/extensions/Xfixes.h>
#include <X11/extensions/extutil.h>
#include <X11/extensions/dri2tokens.h>
#include <drm.h>

typedef struct
{
   unsigned int attachment;
   unsigned int names[3];    /* unused entries set to zero.. non-planar formats only use names[0] */
   unsigned int pitch[3];    /* unused entries set to zero.. non-planar formats only use pitch[0] */
   unsigned int cpp;
   unsigned int flags;
} DRI2Buffer;

typedef struct
{
	Bool (*WireToEvent)(Display *dpy, XExtDisplayInfo *info, XEvent *event, xEvent *wire);
	Status (*EventToWire)(Display *dpy, XExtDisplayInfo *info, XEvent *event, xEvent *wire);
	int (*Error)(Display *dpy, xError *err, XExtCodes *codes, int *ret_code);
} DRI2EventOps;

/* Call this once per display to register event handling code.. if needed */
extern Bool
DRI2InitDisplay(Display * display, const DRI2EventOps * ops);

extern Bool
DRI2QueryExtension(Display * display, int *eventBase, int *errorBase);

extern Bool
DRI2QueryVersion(Display * display, int *major, int *minor);

extern Bool
DRI2Connect(Display * dpy, XID window,
		int driverType, char **driverName, char **deviceName);

extern Bool
DRI2Authenticate(Display * display, XID window, drm_magic_t magic);

extern void
DRI2CreateDrawable(Display * display, XID drawable);

extern void
DRI2DestroyDrawable(Display * display, XID handle);

extern DRI2Buffer*
DRI2GetBuffers(Display * dpy, XID drawable,
               int *width, int *height,
               unsigned int *attachments, int count,
               int *outCount);

/**
 * \note
 * This function is only supported with DRI2 version 1.1 or later.
 */
extern DRI2Buffer*
DRI2GetBuffersWithFormat(Display * dpy, XID drawable,
                         int *width, int *height,
                         unsigned int *attachments,
                         int count, int *outCount);

extern void
DRI2CopyRegion(Display * dpy, XID drawable,
               XserverRegion region,
               CARD32 dest, CARD32 src);

extern void
DRI2SwapBuffers(Display *dpy, XID drawable, CARD64 target_msc, CARD64 divisor,
		CARD64 remainder, CARD64 *count);

extern Bool
DRI2GetMSC(Display *dpy, XID drawable, CARD64 *ust, CARD64 *msc, CARD64 *sbc);

extern Bool
DRI2WaitMSC(Display *dpy, XID drawable, CARD64 target_msc, CARD64 divisor,
	    CARD64 remainder, CARD64 *ust, CARD64 *msc, CARD64 *sbc);

extern Bool
DRI2WaitSBC(Display *dpy, XID drawable, CARD64 target_sbc, CARD64 *ust,
	    CARD64 *msc, CARD64 *sbc);

extern void
DRI2SwapInterval(Display *dpy, XID drawable, int interval);

#endif
