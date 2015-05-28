format ELF64 executable 3
entry start

include 'import64.inc'
interpreter '/lib64/ld-linux-x86-64.so.2' 

align 16
segment readable writeable

include "syscalls.inc"
include "libc.inc"
include "xproto.inc"
include "xcb.inc"

tmp rb 256

;dpy rq 1 ;rbp
;screen rq 1 ;r12
;xcb_drawable_t = uint32
;win rd 1 ;r14
root rd 1

;ev rq 1 ;xcb_generic_event_t, rbx
;geom rq 1 ;xcb_get_geometry_reply_t, r15
;pointer rq 1 ;xcb_query_pointer_reply_t, r13
values rd 3

segment readable executable 


start:

fcall xcb_connect, 0, 0
;mov [dpy], rax
mov rbp, rax
fcall xcb_connection_has_error, rbp
fcall xcb_get_setup, rbp
fcall xcb_setup_roots_iterator, rax
;mov [screen], rax
mov r12, rax
mov eax, dword [rax+xcb_screen_t.root] ;sizes ?
mov [root], eax

push XCB_GRAB_MODE_ASYNC
fcall xcb_grab_key, rbp, 1, ptr root, XCB_MOD_MASK_2, XCB_NO_SYMBOL, XCB_GRAB_MODE_ASYNC
add rsp, 8

push XCB_MOD_MASK_1
push 1
push XCB_NONE
mov eax, [root]
push rax
fcall xcb_grab_button, rbp, 0, ptr root, XCB_EVENT_MASK_BUTTON_PRESS or XCB_EVENT_MASK_BUTTON_RELEASE, XCB_GRAB_MODE_ASYNC, XCB_GRAB_MODE_ASYNC
add rsp, 8*4

push XCB_MOD_MASK_1
push 3
push XCB_NONE
mov eax, [root]
push rax
fcall xcb_grab_button, rbp, 0, ptr root, XCB_EVENT_MASK_BUTTON_PRESS or XCB_EVENT_MASK_BUTTON_RELEASE, XCB_GRAB_MODE_ASYNC, XCB_GRAB_MODE_ASYNC
add rsp, 8*4

fcall xcb_flush, rbp


;main loop
event_loop:
fcall xcb_wait_for_event, rbp
;mov [ev], rax
mov rbx, rax

mov al, [rbx+xcb_generic_event_t.response_type]
and al, not 0x80


cmp al, XCB_BUTTON_PRESS
jnz not_button_press
mov eax, [rbx+xcb_button_press_event_t.child]
;mov [win], eax
mov r14d, eax
mov [values], XCB_STACK_MODE_ABOVE
fcall xcb_configure_window, rbp, ptr rbx+xcb_button_press_event_t.child, \
                            XCB_CONFIG_WINDOW_STACK_MODE, values

cmp [rbx+xcb_button_press_event_t.detail], 1 ;mouse 1
jnz @f
mov [values+4*2], 1
push 1
push 1
push 0
fcall xcb_warp_pointer, rbp, XCB_NONE, ptr rbx+xcb_button_press_event_t.child, 0, 0, 0
add rsp, 8*3
jmp end_button_press
@@:

cmp [rbx+xcb_button_press_event_t.detail], 3 ;mouse 3
jnz @f
fcall xcb_get_geometry, rbp, ptr rbx+xcb_button_press_event_t.child
fcall xcb_get_geometry_reply, rbp, rax, 0
;mov [geom], rax
mov [values+4*2], 3
movzx rcx, [rax+xcb_get_geometry_reply_t.height]
push rcx
movzx rcx, [rax+xcb_get_geometry_reply_t.width]
push rcx
push 0
fcall xcb_warp_pointer, rbp, XCB_NONE, ptr rbx+xcb_button_press_event_t.child, 0, 0, 0
add rsp, 8*3
@@:
end_button_press:

push XCB_CURRENT_TIME
push XCB_NONE
mov eax, [root]
push rax
fcall xcb_grab_pointer, rbp, 0, ptr root, \
                        XCB_EVENT_MASK_BUTTON_RELEASE or XCB_EVENT_MASK_BUTTON_MOTION or XCB_EVENT_MASK_POINTER_MOTION_HINT, \
                        XCB_GRAB_MODE_ASYNC, XCB_GRAB_MODE_ASYNC
add rsp, 8*3
fcall xcb_flush, rbp
jmp event_loop
not_button_press:


cmp al, XCB_MOTION_NOTIFY
jnz not_motion_notify
fcall xcb_query_pointer, rbp, ptr root
fcall xcb_query_pointer_reply, rbp, rax, 0
;mov [pointer], rax
mov r13, rax

;move
cmp [values+4*2], 1 ;mouse 1 = move
jnz not_move
fcall xcb_get_geometry, rbp, r14
fcall xcb_get_geometry_reply, rbp, rax, 0
;mov [geom], rax
mov r15, rax
;mov r13, [pointer]
movzx ebx, word [r13+xcb_query_pointer_reply_t.root_x]
mov cx, word [r15+xcb_get_geometry_reply_t.width] ;SIGSEGFAULT?
;mov r12, [screen]
mov si, word [r12+xcb_screen_t.width_in_pixels]
mov dx, cx
add dx, bx
cmp dx, si
jng @f
sub si, cx
mov bx, si
@@:
mov [values], ebx
movzx ebx, word [r13+xcb_query_pointer_reply_t.root_y]
mov cx, word [r15+xcb_get_geometry_reply_t.height]
mov si, word [r12+xcb_screen_t.height_in_pixels]
mov dx, cx
add dx, bx
cmp dx, si
jng @f
sub si, cx
mov bx, si
@@:
mov [values+4], ebx
fcall xcb_configure_window, rbp, r14, \
                            XCB_CONFIG_WINDOW_X or XCB_CONFIG_WINDOW_Y, values
fcall xcb_flush, rbp
jmp event_loop
not_move:

;resize
cmp [values+4*2], 3 ;mouse 3 = resize
jnz not_resize
fcall xcb_get_geometry, rbp, r14
fcall xcb_get_geometry_reply, rbp, rax, 0
;mov [geom], rax
mov r15, rax
;mov r13, [pointer]
movzx ebx, word [r13+xcb_query_pointer_reply_t.root_x]
mov cx, word [r15+xcb_get_geometry_reply_t.x]
sub bx, cx
mov [values], ebx
movzx ebx, word [r13+xcb_query_pointer_reply_t.root_y]
mov cx, word [r15+xcb_get_geometry_reply_t.y]
sub bx, cx
mov [values+4], ebx
fcall xcb_configure_window, rbp, r14, \
                            XCB_CONFIG_WINDOW_WIDTH or XCB_CONFIG_WINDOW_HEIGHT, values
fcall xcb_flush, rbp
not_resize:
jmp event_loop
not_motion_notify:


cmp al, XCB_BUTTON_RELEASE
jnz not_button_release
fcall xcb_ungrab_pointer, rbp, XCB_CURRENT_TIME
fcall xcb_flush, rbp
not_button_release:

jmp event_loop

error:
;fcall printf, rsi
xor rdi, rdi ;return 0 anyway
mov rax, sys_exit
syscall