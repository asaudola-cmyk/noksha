// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Example: Reactive Counter Application
// Demonstrates fine-grained Signal state, Flexbox layout, and canvas quad batching.

include "crates/noksha.lp"

fn main()
    println("Noksha Example: Reactive Counter (v1.0.0)")
    println("-----------------------------------------")

    // Step 1: Initialize Engine Subsystems
    noksha_engine_init()

    arena = noksha_arena_create(262144) // 256KB per-frame scratch arena
    rhi_dev = noksha_rhi_create(noksha_backend_drm_kms(), 800, 600)
    cmd_buf = noksha_cmd_buffer_create(16384)
    batcher = noksha_batcher_create(1024)
    clip_stack = noksha_clip_stack_create(16)
    canvas = noksha_canvas_create(batcher, clip_stack, cmd_buf)
    fb = noksha_drm_fb_create(800, 600)

    // Step 2: Reactive State Setup
    count_signal = noksha_signal_create(0)
    println("[state] Initial count: " + to_str(noksha_signal_get(count_signal)))

    // Step 3: Construct Declarative UI Scene Tree
    // Root Screen Container (Flex Column, 800x600, Center Aligned)
    root_style = noksha_style_create()
    noksha_style_set_size(root_style, 800, 600)
    noksha_style_set_direction(root_style, noksha_flex_col())
    noksha_style_set_alignment(root_style, noksha_align_center(), noksha_justify_center())
    noksha_style_set_padding(root_style, 40, 40, 40, 40)
    noksha_style_set_gap(root_style, 24)

    root_node = noksha_node_create(1, root_style)

    // Main Card (420x300, SDF Rounded Rect)
    card_style = noksha_style_create()
    noksha_style_set_size(card_style, 420, 300)
    noksha_style_set_direction(card_style, noksha_flex_col())
    noksha_style_set_alignment(card_style, noksha_align_center(), noksha_justify_center())
    noksha_style_set_padding(card_style, 24, 24, 24, 24)
    noksha_style_set_gap(card_style, 20)

    card_node = noksha_node_create(2, card_style)
    noksha_node_add_child(root_node, card_node)

    // Card View Component (Dark Slate Blue + Border + Drop Shadow)
    col_card_bg = noksha_color_pack_rgba(30, 41, 59, 230)
    col_card_border = noksha_color_pack_rgba(71, 85, 105, 255)
    col_shadow = noksha_color_pack_rgba(0, 0, 0, 160)
    card_view = noksha_view_create_card(2, card_node, col_card_bg, 16, 2, col_card_border, 24, col_shadow)

    // Increment Button Component (200x50, Emerald Green)
    btn_style = noksha_style_create()
    noksha_style_set_size(btn_style, 200, 50)
    btn_node = noksha_node_create(3, btn_style)
    noksha_node_add_child(card_node, btn_node)

    col_btn_bg = noksha_color_pack_rgba(16, 185, 129, 255)
    col_btn_text = noksha_color_pack_rgba(255, 255, 255, 255)
    btn_view = noksha_view_create_button(3, btn_node, "Click to Increment", col_btn_bg, 10, col_btn_text)

    // Subscribe Button to Signal Mutations
    noksha_signal_subscribe(count_signal, btn_node)

    // Step 4: Layout Computation Pass (O(N) Linear Time)
    noksha_layout_compute_flex(root_node, 0, 0, 800, 600)

    card_x = noksha_node_get_x(card_node)
    card_y = noksha_node_get_y(card_node)
    card_w = noksha_node_get_w(card_node)
    card_h = noksha_node_get_h(card_node)
    println("[layout] Card: x=" + to_str(card_x) + " y=" + to_str(card_y) + " size=" + to_str(card_w) + "x" + to_str(card_h))

    btn_x = noksha_node_get_x(btn_node)
    btn_y = noksha_node_get_y(btn_node)
    println("[layout] Button: x=" + to_str(btn_x) + " y=" + to_str(btn_y))

    // Step 5: Render Frame 0
    col_screen_bg = noksha_color_pack_rgba(15, 23, 42, 255)
    noksha_canvas_draw_rect(canvas, 0, 0, 800, 600, col_screen_bg)
    noksha_view_render(card_view, canvas)
    noksha_view_render(btn_view, canvas)

    flushed_0 = noksha_canvas_flush(canvas)
    println("[render] Frame 0: " + to_str(flushed_0) + " quads batched")

    // Step 6: Simulate Reactive Click Event (count = 1)
    println("[event] Click: incrementing counter")
    curr_c = noksha_signal_get(count_signal)
    noksha_signal_set(count_signal, curr_c + 1)
    println("[state] Count updated: " + to_str(noksha_signal_get(count_signal)))

    // Render Frame 1
    noksha_view_render(card_view, canvas)
    noksha_view_render(btn_view, canvas)
    flushed_1 = noksha_canvas_flush(canvas)
    println("[render] Frame 1: " + to_str(flushed_1) + " quads batched")

    // Step 7: Framebuffer Blit & Presentation
    pitch = mem_read(fb, 24)
    back_ptr = mem_read(fb, 48)
    noksha_raster_fill_rect(back_ptr, pitch, 800, 600, card_x, card_y, card_w, card_h, col_card_bg)
    noksha_drm_flip(fb)
    println("[drm] Framebuffer presented to display")

    // Step 8: Clean Teardown
    noksha_drm_fb_destroy(fb)
    noksha_batcher_destroy(batcher)
    noksha_cmd_buffer_destroy(cmd_buf)
    noksha_rhi_destroy(rhi_dev)
    noksha_arena_destroy(arena)

    println("-----------------------------------------")
    println("Counter example completed successfully.")
    return 0
end

main()
