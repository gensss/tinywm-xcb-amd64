/* offsetof example */
#include <stdio.h>      /* printf */
#include <stddef.h>     /* offsetof */
#include <xcb/xcb.h>


int main ()
{
  printf ("offsetof(struct foo,data) is %d\n",(int)offsetof(xcb_screen_iterator_t,data));
  printf ("offsetof(struct foo,rem) is %d\n",(int)offsetof(xcb_screen_iterator_t,rem));
  printf ("offsetof(struct foo,index) is %d\n",(int)offsetof(xcb_screen_iterator_t,index));
	printf("%d", XCB_NONE);
  
  return 0;
}