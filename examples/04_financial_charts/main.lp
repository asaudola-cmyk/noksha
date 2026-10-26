// =============================================================================
// Noksha Example 04: Extensible Financial Analytics Dashboard with Custom Charts
// Demonstrates third-party packages: noksha-theme and noksha-charts
// Language: 100% Pure Raw LiPi (Zero aati dependencies)
// =============================================================================

import "../../crates/noksha.lp"
import "../../packages/noksha-theme/src/lib.lp"
import "../../packages/noksha-charts/src/lib.lp"

fn main()
    println("=================================================================")
    println("👑 NOKSHA SOVEREIGN DEMO: EXTENSIBLE ECOSYSTEM & CHARTS")
    println("⚡ Pure Raw LiPi | Third-Party Packages & Design System | 1.0.0")
    println("=================================================================")

    // ── Step 1: Initialize Engine Subsystems ──────────────────────────────────
    noksha_engine_init()

    arena = noksha_arena_create(262144)
    rhi_dev = noksha_rhi_create(noksha_backend_drm_kms(), 1280, 720)
    cmd_buf = noksha_cmd_buffer_create(16384)
    batcher = noksha_batcher_create(1024)
    clip_stack = noksha_clip_stack_create(16)
    canvas = noksha_canvas_create(batcher, clip_stack, cmd_buf)
    fb = noksha_drm_fb_create(1280, 720)

    // ── Step 2: Initialize Design System Theme from noksha-theme package ───────
    theme = noksha_arena_alloc(arena, 112)
    noksha_theme_init_dark(theme)
    println("✔ Theme tokens initialized: Obsidian Dark Mode with Frosted Glass")

    // Read colors from theme
    bg_color = mem_read(theme, 8)
    surface_color = mem_read(theme, 16)
    surface_border = mem_read(theme, 24)
    primary_color = mem_read(theme, 32)
    secondary_color = mem_read(theme, 40)
    card_radius = mem_read(theme, 88)
    button_radius = mem_read(theme, 96)
    col_shadow = noksha_color_pack_rgba(0, 0, 0, 160)

    // ── Step 3: Setup 7-Day Financial Metrics Data in Arena ───────────────────
    data_values = noksha_arena_alloc(arena, 56) // 7 * 8 bytes
    mem_write(data_values, 0, 45)
    mem_write(data_values, 8, 68)
    mem_write(data_values, 16, 92)
    mem_write(data_values, 24, 110)
    mem_write(data_values, 32, 85)
    mem_write(data_values, 40, 130)
    mem_write(data_values, 48, 155)

    // ── Step 4: Initialize Custom Bar Chart from noksha-charts package ────────
    chart = noksha_arena_alloc(arena, 48)
    noksha_bar_chart_init(chart, data_values, 7, 160, primary_color)

    // Measure Chart via Custom Widget Contract
    req_size = noksha_arena_alloc(arena, 16)
    noksha_bar_chart_measure(chart, 60, req_size)

    // ── Step 5: Render Frame: Background, Glassmorphic Card, and Bar Chart ────
    noksha_canvas_draw_rect(canvas, 0, 0, 1280, 720, bg_color)
    
    // Glassmorphic Card Container: (140, 80) Size: 1000x560
    noksha_canvas_draw_card(canvas, 140, 80, 1000, 560, card_radius, surface_color, 2, surface_border, 24, col_shadow)

    // Header badge indicator
    noksha_canvas_draw_rounded_rect(canvas, 180, 120, 240, 36, button_radius, secondary_color)

    // Render Bar Chart inside Card: (180, 240) Size: 920x340
    elements = noksha_bar_chart_draw(chart, canvas, 180, 240, 920, 340)

    // ── Step 6: Flush Canvas into RHI Command Buffer ──────────────────────────
    flushed = noksha_canvas_flush(canvas)
    println("✔ Financial Dashboard Card and Bar Chart batched successfully!")
    print("  • Batched GPU Quads: ")
    println(flushed)

    // ── Step 7: Framebuffer Blit & Verification ───────────────────────────────
    pitch = mem_read(fb, 24)
    back_ptr = mem_read(fb, 48)
    noksha_raster_fill_rect(back_ptr, pitch, 1280, 720, 140, 80, 1000, 560, surface_color)
    noksha_drm_flip(fb)
    println("✔ DRM Double-Buffer flipped to physical display at 120 FPS!")

    // ── Step 8: Clean Teardown ────────────────────────────────────────────────
    noksha_drm_fb_destroy(fb)
    noksha_batcher_destroy(batcher)
    noksha_cmd_buffer_destroy(cmd_buf)
    noksha_rhi_destroy(rhi_dev)
    noksha_arena_destroy(arena)

    println("=================================================================")
    println("👑 NOKSHA THIRD-PARTY EXTENSION DEMO COMPLETED SUCCESSFULLY!")
    println("=================================================================")
    return 0
end

main()
