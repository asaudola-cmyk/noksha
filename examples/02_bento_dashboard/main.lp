// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Example: Modern Bento Grid Dashboard
// Demonstrates multi-level nested Flexbox layout, proportional space distribution (flex_grow),
// and single-pass instanced quad batching.

include "crates/noksha.lp"

fn main()
    println("Noksha Example: Bento Grid Dashboard (v1.0.0)")
    println("----------------------------------------------")

    // Step 1: Initialize Engine
    noksha_engine_init()

    arena = noksha_arena_create(524288) // 512KB scratchpad
    rhi_dev = noksha_rhi_create(noksha_backend_drm_kms(), 1200, 800)
    cmd_buf = noksha_cmd_buffer_create(32768)
    batcher = noksha_batcher_create(2048)
    clip_stack = noksha_clip_stack_create(32)
    canvas = noksha_canvas_create(batcher, clip_stack, cmd_buf)
    fb = noksha_drm_fb_create(1200, 800)

    // Step 2: Construct Root Screen (1200x800 Flex Column)
    root_style = noksha_style_create()
    noksha_style_set_size(root_style, 1200, 800)
    noksha_style_set_direction(root_style, noksha_flex_col())
    noksha_style_set_padding(root_style, 32, 32, 32, 32)
    noksha_style_set_gap(root_style, 24)

    root_node = noksha_node_create(100, root_style)

    // Step 3: Header Bar (1200x60 Flex Row)
    header_style = noksha_style_create()
    noksha_style_set_size(header_style, -1, 60)
    noksha_style_set_direction(header_style, noksha_flex_row())
    noksha_style_set_alignment(header_style, noksha_align_center(), noksha_justify_start())
    noksha_style_set_padding(header_style, 16, 12, 16, 12)
    noksha_style_set_gap(header_style, 16)

    header_node = noksha_node_create(101, header_style)
    noksha_node_add_child(root_node, header_node)

    col_header_bg = noksha_color_pack_rgba(30, 41, 59, 200)
    col_header_border = noksha_color_pack_rgba(71, 85, 105, 255)
    header_view = noksha_view_create_card(101, header_node, col_header_bg, 12, 1, col_header_border, 10, 0)

    // Step 4: Bento Grid Row Container (Flex Row, Gap: 20)
    bento_row_style = noksha_style_create()
    noksha_style_set_size(bento_row_style, -1, 400) // 400px height, auto width
    noksha_style_set_direction(bento_row_style, noksha_flex_row())
    noksha_style_set_gap(bento_row_style, 20)
    noksha_style_set_flex_grow(bento_row_style, 1)

    bento_row_node = noksha_node_create(102, bento_row_style)
    noksha_node_add_child(root_node, bento_row_node)

    // Card A: System Telemetry Card (flex_grow: 1)
    card_a_style = noksha_style_create()
    noksha_style_set_size(card_a_style, -1, 400)
    noksha_style_set_flex_grow(card_a_style, 1)
    noksha_style_set_padding(card_a_style, 20, 20, 20, 20)
    card_a_node = noksha_node_create(103, card_a_style)
    noksha_node_add_child(bento_row_node, card_a_node)

    col_card_a = noksha_color_pack_rgba(24, 32, 47, 240)
    col_border_a = noksha_color_pack_rgba(59, 130, 246, 180)
    card_a_view = noksha_view_create_card(103, card_a_node, col_card_a, 16, 2, col_border_a, 16, 0)

    // Card B: Featured Engine Card (flex_grow: 2)
    card_b_style = noksha_style_create()
    noksha_style_set_size(card_b_style, -1, 400)
    noksha_style_set_flex_grow(card_b_style, 2)
    noksha_style_set_padding(card_b_style, 24, 24, 24, 24)
    card_b_node = noksha_node_create(104, card_b_style)
    noksha_node_add_child(bento_row_node, card_b_node)

    col_card_b = noksha_color_pack_rgba(20, 28, 42, 240)
    col_border_b = noksha_color_pack_rgba(16, 185, 129, 180)
    card_b_view = noksha_view_create_card(104, card_b_node, col_card_b, 16, 2, col_border_b, 20, 0)

    // Card C: Reactive Stream Card (flex_grow: 1)
    card_c_style = noksha_style_create()
    noksha_style_set_size(card_c_style, -1, 400)
    noksha_style_set_flex_grow(card_c_style, 1)
    noksha_style_set_padding(card_c_style, 20, 20, 20, 20)
    card_c_node = noksha_node_create(105, card_c_style)
    noksha_node_add_child(bento_row_node, card_c_node)

    col_card_c = noksha_color_pack_rgba(24, 32, 47, 240)
    col_border_c = noksha_color_pack_rgba(168, 85, 247, 180)
    card_c_view = noksha_view_create_card(105, card_c_node, col_card_c, 16, 2, col_border_c, 16, 0)

    // Step 5: Layout Pass (O(N) Linear Time Computation)
    noksha_layout_compute_flex(root_node, 0, 0, 1200, 800)

    println("[layout] Solved flexbox layout:")
    println("  header: (" + to_str(noksha_node_get_x(header_node)) + ", " + to_str(noksha_node_get_y(header_node)) + ") size=" + to_str(noksha_node_get_w(header_node)) + "x" + to_str(noksha_node_get_h(header_node)))
    println("  card_a (telemetry): width=" + to_str(noksha_node_get_w(card_a_node)) + "px")
    println("  card_b (featured):  width=" + to_str(noksha_node_get_w(card_b_node)) + "px (2x flex)")
    println("  card_c (signals):   width=" + to_str(noksha_node_get_w(card_c_node)) + "px")

    // Step 6: Render Frame to Canvas
    col_canvas_bg = noksha_color_pack_rgba(11, 15, 25, 255)
    noksha_canvas_draw_rect(canvas, 0, 0, 1200, 800, col_canvas_bg)

    noksha_view_render(header_view, canvas)
    noksha_view_render(card_a_view, canvas)
    noksha_view_render(card_b_view, canvas)
    noksha_view_render(card_c_view, canvas)

    total_batched = noksha_canvas_flush(canvas)
    println("[render] Batched " + to_str(total_batched) + " quads in single pass")

    // Step 7: Teardown
    noksha_drm_fb_destroy(fb)
    noksha_batcher_destroy(batcher)
    noksha_cmd_buffer_destroy(cmd_buf)
    noksha_rhi_destroy(rhi_dev)
    noksha_arena_destroy(arena)

    println("----------------------------------------------")
    println("Bento Grid dashboard completed successfully.")
    return 0
end

main()
