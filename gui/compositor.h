// FemboyOS Compositor Header
// C-based window compositor for kernel GUI

#ifndef COMPOSITOR_H
#define COMPOSITOR_H

// VGA constants
#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define VGA_MEMORY 0xB8000

// Window structure
typedef struct {
    int x, y;           // Position
    int width, height;  // Size
    char *title;        // Window title
    int active;         // Is window active
    unsigned char *buffer; // Window content buffer
} window_t;

// Compositor global state
typedef struct {
    window_t windows[16]; // Max 16 windows
    int window_count;
    int active_window;
} compositor_state_t;

// External functions
void compositor_init(void);
void compositor_render(void);
void compositor_handle_input(int key);

#endif // COMPOSITOR_H
