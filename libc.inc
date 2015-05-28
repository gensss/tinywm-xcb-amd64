needed 'libc.so.6', 'libxcb.so.1'

import \
\
printf, \
\
xcb_connect, xcb_connection_has_error, xcb_get_setup, xcb_setup_roots_iterator, \
xcb_flush, xcb_wait_for_event, \
xcb_configure_window, xcb_get_geometry, xcb_get_geometry_reply, \
xcb_grab_key, xcb_grab_button, \
xcb_grab_pointer, xcb_ungrab_pointer, xcb_warp_pointer, \
xcb_query_pointer, xcb_query_pointer_reply



macro fcall routine, op1, op2, op3, op4, op5, op6 {
local counter
if op6 eq
else if op6 eqtype rax+3
lea r9, [op6]
else
mov r9, op6
end if

if op5 eq
else if op5 eqtype rax+3
lea r8, [op5]
else
mov r8, op5
end if

if op4 eq
else if op4 eqtype rax+3
lea rcx, [op4]
else
mov rcx, op4
end if

if op3 eq
else if op3 eqtype rax+3
lea rdx, [op3]
else if op3 eqtype [0]
mov edx, op3
else
mov rdx, op3
end if

if op2 eq
else if op2 eq rsi
else if op2 eqtype rax+3
lea rsi, [op2]
else if op2 eqtype [0]
mov esi, op2
else
mov rsi, op2
end if

if op1 eq
else if op1 eqtype rax+3
lea rdi, [op1]
else
mov rdi, op1
end if

call [routine]
}
