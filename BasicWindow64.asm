                                                ; Basic Window, 64 bit. V1.02
COLOR_WINDOW        EQU 5                       ; Constants
CS_BYTEALIGNWINDOW  EQU 2000h
CS_HREDRAW          EQU 2
CS_VREDRAW          EQU 1
CW_USEDEFAULT       EQU 80000000h
IDC_ARROW           EQU 7F00h
IDI_APPLICATION     EQU 7F00h
IMAGE_CURSOR        EQU 2
IMAGE_ICON          EQU 1
LR_SHARED           EQU 8000h
NULL                EQU 0
SW_SHOWNORMAL       EQU 1
WM_DESTROY          EQU 2
WS_EX_COMPOSITED    EQU 2000000h
WS_OVERLAPPEDWINDOW EQU 0CF0000h

WindowWidth         EQU 640
WindowHeight        EQU 480

extern CreateWindowExA                          ; Import external symbols
extern DefWindowProcA                           ; Windows API functions, not decorated
extern DispatchMessageA
extern ExitProcess
extern GetMessageA
extern GetModuleHandleA
extern IsDialogMessageA
extern LoadImageA
extern PostQuitMessage
extern RegisterClassExA
extern ShowWindow
extern TranslateMessage
extern UpdateWindow

global Start                                    ; Export symbols. The entry point

section .data                                   ; Initialized data segment
 WindowName  db "Basic Window 64", 0
 ClassName   db "Window", 0

section .bss                                    ; Uninitialized data segment
 alignb 8
 hInstance resq 1

section .text                                   ; Code segment
Start:
 sub   RSP, 8                                   ; Align stack pointer to 16 bytes

 sub   RSP, 32                                  ; 32 bytes of shadow space
 xor   ECX, ECX
 call  GetModuleHandleA
 mov   qword [REL hInstance], RAX
 add   RSP, 32                                  ; Remove the 32 bytes

 call  WinMain

.Exit:
 xor   ECX, ECX
 call  ExitProcess

WinMain:
 push  RBP                                      ; Set up a stack frame
 mov   RBP, RSP
 sub   RSP, 136 + 8                             ; 136 bytes for local variables. 136 is not
                                                ; a multiple of 16 (for Windows API functions),
                                                ; the + 8 takes care of this.

%define wc                 RBP - 136            ; WNDCLASSEX structure, 80 bytes
%define wc.cbSize          RBP - 136            ; 4 bytes. Start on an 8 byte boundary
%define wc.style           RBP - 132            ; 4 bytes
%define wc.lpfnWndProc     RBP - 128            ; 8 bytes
%define wc.cbClsExtra      RBP - 120            ; 4 bytes
%define wc.cbWndExtra      RBP - 116            ; 4 bytes
%define wc.hInstance       RBP - 112            ; 8 bytes
%define wc.hIcon           RBP - 104            ; 8 bytes
%define wc.hCursor         RBP - 96             ; 8 bytes
%define wc.hbrBackground   RBP - 88             ; 8 bytes
%define wc.lpszMenuName    RBP - 80             ; 8 bytes
%define wc.lpszClassName   RBP - 72             ; 8 bytes
%define wc.hIconSm         RBP - 64             ; 8 bytes. End on an 8 byte boundary

%define msg                RBP - 56             ; MSG structure, 48 bytes
%define msg.hwnd           RBP - 56             ; 8 bytes. Start on an 8 byte boundary
%define msg.message        RBP - 48             ; 4 bytes
%define msg.Padding1       RBP - 44             ; 4 bytes. Natural alignment padding
%define msg.wParam         RBP - 40             ; 8 bytes
%define msg.lParam         RBP - 32             ; 8 bytes
%define msg.time           RBP - 24             ; 4 bytes
%define msg.py.x           RBP - 20             ; 4 bytes
%define msg.pt.y           RBP - 16             ; 4 bytes
%define msg.Padding2       RBP - 12             ; 4 bytes. Structure length padding

%define hWnd               RBP - 8              ; 8 bytes

 mov   dword [wc.cbSize], 80                    ; [RBP - 136]
 mov   dword [wc.style], CS_HREDRAW | CS_VREDRAW | CS_BYTEALIGNWINDOW  ; [RBP - 132]
 lea   RAX, [REL WndProc]
 mov   qword [wc.lpfnWndProc], RAX              ; [RBP - 128]
 mov   dword [wc.cbClsExtra], NULL              ; [RBP - 120]
 mov   dword [wc.cbWndExtra], NULL              ; [RBP - 116]
 mov   RAX, qword [REL hInstance]               ; Global
 mov   qword [wc.hInstance], RAX                ; [RBP - 112]

 sub   RSP, 32 + 16                             ; Shadow space + 2 parameters
 xor   ECX, ECX
 mov   EDX, IDI_APPLICATION
 mov   R8D, IMAGE_ICON
 xor   R9D, R9D
 mov   qword [RSP + 4 * 8], NULL
 mov   qword [RSP + 5 * 8], LR_SHARED
 call  LoadImageA                               ; Large program icon
 mov   qword [wc.hIcon], RAX                    ; [RBP - 104]
 add   RSP, 48                                  ; Remove the 48 bytes

 sub   RSP, 32 + 16                             ; Shadow space + 2 parameters
 xor   ECX, ECX
 mov   EDX, IDC_ARROW
 mov   R8D, IMAGE_CURSOR
 xor   R9D, R9D
 mov   qword [RSP + 4 * 8], NULL
 mov   qword [RSP + 5 * 8], LR_SHARED
 call  LoadImageA                               ; Cursor
 mov   qword [wc.hCursor], RAX                  ; [RBP - 96]
 add   RSP, 48                                  ; Remove the 48 bytes

 mov   qword [wc.hbrBackground], COLOR_WINDOW + 1  ; [RBP - 88]
 mov   qword [wc.lpszMenuName], NULL            ; [RBP - 80]
 lea   RAX, [REL ClassName]
 mov   qword [wc.lpszClassName], RAX            ; [RBP - 72]

 sub   RSP, 32 + 16                             ; Shadow space + 2 parameters
 xor   ECX, ECX
 mov   EDX, IDI_APPLICATION
 mov   R8D, IMAGE_ICON
 xor   R9D, R9D
 mov   qword [RSP + 4 * 8], NULL
 mov   qword [RSP + 5 * 8], LR_SHARED
 call  LoadImageA                               ; Small program icon
 mov   qword [wc.hIconSm], RAX                  ; [RBP - 64]
 add   RSP, 48                                  ; Remove the 48 bytes

 sub   RSP, 32                                  ; 32 bytes of shadow space
 lea   RCX, [wc]                                ; [RBP - 136]
 call  RegisterClassExA
 add   RSP, 32                                  ; Remove the 32 bytes

 sub   RSP, 32 + 64                             ; Shadow space + 8 parameters
 mov   ECX, WS_EX_COMPOSITED
 lea   RDX, [REL ClassName]                     ; Global
 lea   R8, [REL WindowName]                     ; Global
 mov   R9D, WS_OVERLAPPEDWINDOW
 mov   dword [RSP + 4 * 8], CW_USEDEFAULT
 mov   dword [RSP + 5 * 8], CW_USEDEFAULT
 mov   dword [RSP + 6 * 8], WindowWidth
 mov   dword [RSP + 7 * 8], WindowHeight
 mov   qword [RSP + 8 * 8], NULL
 mov   qword [RSP + 9 * 8], NULL
 mov   RAX, qword [REL hInstance]               ; Global
 mov   qword [RSP + 10 * 8], RAX
 mov   qword [RSP + 11 * 8], NULL
 call  CreateWindowExA
 mov   qword [hWnd], RAX                        ; [RBP - 8]
 add   RSP, 96                                  ; Remove the 96 bytes

 sub   RSP, 32                                  ; 32 bytes of shadow space
 mov   RCX, qword [hWnd]                        ; [RBP - 8]
 mov   EDX, SW_SHOWNORMAL
 call  ShowWindow
 add   RSP, 32                                  ; Remove the 32 bytes

 sub   RSP, 32                                  ; 32 bytes of shadow space
 mov   RCX, qword [hWnd]                        ; [RBP - 8]
 call  UpdateWindow
 add   RSP, 32                                  ; Remove the 32 bytes

.MessageLoop:
 sub   RSP, 32                                  ; 32 bytes of shadow space
 lea   RCX, [msg]                               ; [RBP - 56]
 xor   EDX, EDX
 xor   R8D, R8D
 xor   R9D, R9D
 call  GetMessageA
 add   RSP, 32                                  ; Remove the 32 bytes
 cmp   RAX, 0
 je    .Done

 sub   RSP, 32                                  ; 32 bytes of shadow space
 mov   RCX, qword [hWnd]                        ; [RBP - 8]
 lea   RDX, [msg]                               ; [RBP - 56]
 call  IsDialogMessageA                         ; For keyboard strokes
 add   RSP, 32                                  ; Remove the 32 bytes
 cmp   RAX, 0
 jne   .MessageLoop                             ; Skip TranslateMessage and DispatchMessageA

 sub   RSP, 32                                  ; 32 bytes of shadow space
 lea   RCX, [msg]                               ; [RBP - 56]
 call  TranslateMessage
 add   RSP, 32                                  ; Remove the 32 bytes

 sub   RSP, 32                                  ; 32 bytes of shadow space
 lea   RCX, [msg]                               ; [RBP - 56]
 call  DispatchMessageA
 add   RSP, 32                                  ; Remove the 32 bytes
 jmp   .MessageLoop

.Done:
 mov   RSP, RBP                                 ; Remove the stack frame
 pop   RBP
 xor   EAX, EAX
 ret

WndProc:
 push  RBP                                      ; Set up a stack frame
 mov   RBP, RSP

%define hWnd   RBP + 16                         ; Location of the shadow space setup by
%define uMsg   RBP + 24                         ; the calling function
%define wParam RBP + 32
%define lParam RBP + 40

 mov   qword [hWnd], RCX                        ; Free up RCX RDX R8 R9 by spilling the
 mov   qword [uMsg], RDX                        ; 4 passed parameters to the shadow space
 mov   qword [wParam], R8                       ; We can now access these parameters by name
 mov   qword [lParam], R9

 cmp   qword [uMsg], WM_DESTROY                 ; [RBP + 24]
 je    WMDESTROY

DefaultMessage:
 sub   RSP, 32                                  ; 32 bytes of shadow space
 mov   RCX, qword [hWnd]                        ; [RBP + 16]
 mov   RDX, qword [uMsg]                        ; [RBP + 24]
 mov   R8, qword [wParam]                       ; [RBP + 32]
 mov   R9, qword [lParam]                       ; [RBP + 40]
 call  DefWindowProcA
 add   RSP, 32                                  ; Remove the 32 bytes

 mov   RSP, RBP                                 ; Remove the stack frame
 pop   RBP
 ret

WMDESTROY:
 sub   RSP, 32                                  ; 32 bytes of shadow space
 xor   ECX, ECX
 call  PostQuitMessage
 add   RSP, 32                                  ; Remove the 32 bytes

 xor   EAX, EAX                                 ; WM_DESTROY has been processed, return 0
 mov   RSP, RBP                                 ; Remove the stack frame
 pop   RBP
 ret