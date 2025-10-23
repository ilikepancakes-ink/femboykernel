// FemboyOS Compositor Implementation
// C-based window compositor

#include "compositor.h"

// Global compositor state
static compositor_state_t compositor;

// VGA memory pointer
static volatile unsigned short *vga_buffer = (volatile unsigned short *)VGA_MEMORY;

// Clear screen
static void clear_screen() {
    int i;
    for (i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++) {
        vga_buffer[i] = 0x0F20; // White space on black
    }
}

// Put character at position
static void put_char(int x, int y, char c, unsigned char color) {
    if (x >= 0 && x < VGA_WIDTH && y >= 0 && y < VGA_HEIGHT) {
        vga_buffer[y * VGA_WIDTH + x] = (color << 8) | c;
    }
}

// Draw string
static void draw_string(int x, int y, const char *str, unsigned char color) {
    int i = 0;
    while (str[i] && x + i < VGA_WIDTH) {
        put_char(x + i, y, str[i], color);
        i++;
    }
}

// Initialize compositor
void compositor_init(void) {
    clear_screen();
    compositor.window_count = 0;
    compositor.active_window = -1;

    // Draw welcome message
    draw_string(10, 5, "Welcome to C-Based Compositor!", 0x0A); // Green
    draw_string(10, 7, "Press ESC to return to CLI.", 0x0C);     // Red
}

// Render compositor (stub for now)
void compositor_render(void) {
    // Basic render: just refresh the screen message
    draw_string(10, 8, "Rendering frame...", 0x0E); // Yellow
}

// Handle input (stub)
void compositor_handle_input(int key) {
    // For now, just check for ESC
    if (key == 27) { // ESC key
        draw_string(10, 10, "ESC pressed - exiting compositor", 0x04); // Red
    }
}
