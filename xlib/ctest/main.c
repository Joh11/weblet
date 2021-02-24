// Written by Ch. Tronche (http://tronche.lri.fr:8000/)
// Copyright by the author. This is unmaintained, no-warranty free software. 
// Please use freely. It is appreciated (but by no means mandatory) to
// acknowledge the author's contribution. Thank you.
// Started on Thu Jun 26 23:29:03 1997

//
// Xlib tutorial: 2nd program
// Make a window appear on the screen and draw a line inside.
// If you don't understand this program, go to
// http://tronche.lri.fr:8000/gui/x/xlib-tutorial/2nd-program-anatomy.html
//

#include <X11/Xlib.h> // Every Xlib program must include this
#include <assert.h>   // I include this to test return values the lazy way
#include <unistd.h>   // So we got the profile for 10 seconds
#include <stdio.h>

#define NIL (0)       // A name for the void pointer

int main()
{
    const int screen = 0;
    const int x = 200;
    const int y = 100;

    int ret = 0;
    
    // Open the display
    Display *dpy = XOpenDisplay(NIL);
    assert(dpy);

    sleep(3);
    printf("Moving mouse to ...\n");

    // Moving the mouse
    
    Window screen_root = RootWindow(dpy, screen);
    ret = XWarpPointer(dpy, None, screen_root, 0, 0, 0, 0, x, y);
    XFlush(dpy);

    if(ret != 0)
	printf("Failed !\n");

    return 0;
}
