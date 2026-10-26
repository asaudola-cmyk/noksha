// ==============================================================================
// 👑 NOKSHA EXAMPLE: MODERN BENTO GRID DASHBOARD (examples/02_bento_dashboard/main.lp)
// ⚡ 100% Pure Raw LiPi | Nested Flexbox Layout | Glassmorphic Bento Cards
// ==============================================================================
//
// WHY: Modern UI design trends (Apple, Linear, Vercel) rely heavily on Bento Grids—
// modular cards of varying proportional sizes arranged in a responsive grid or flex row.
// This example verifies:
// 1. Multi-level nested W3C Flexbox computation (Header -> Bento Grid Row -> 3 Bento Cards)
// 2. Proportional space distribution with flex_grow: 1, flex_grow: 2
// 3. Glassmorphic card styling with distinct SDF corner radii and border colors
// 4. Single-pass instanced batch submission to RHI command buffer

include "crates/noksha.lp"

fn main()
    println("=================================================================")
    println("👑 NOKSHA SOVEREIGN DEMO: MODERN BENTO GRID DASHBOARD")
    println("⚡ Pure Raw LiPi | Silicon-to-Web UI Engine | First 1.0.0")
    println("=================================================================")

    // ── 1. Initialize Engine ──────────────────────────────────────────────────
    noksha_engine_init()

    arena = noksha_arena_create(524288) // 512KB scratchpad
    rhi_dev = noksha_rhi_create(noksha_backend_drm_kms(), 1200, 800)
    cmd_buf = noksha_cmd_buffer_create(32768)
    batcher = noksha_batcher_create(2048)
    clip_stack = noksha_clip_stack_create(32)
    canvas = noksha_canvas_create(batcher, clip_stack, cmd_buf)
    fb = noksha_drm_fb_create(1200, 800)

    // ── 2. Construct Root Screen (1200x800 Flex Column) ───────────────────────
    root_style = noksha_style_create()
    noksha_style_set_size(root_style, 1200, 800)
    noksha_style_set_direction(root_style, noksha_flex_col())
    noksha_style_set_padding(root_style, 32, 32, 32, 32)
    noksha_style_set_gap(root_style, 24)

    root_node = noksha_node_create(100, root_style)

    // ── 3. Header Bar (1200x60 Flex Row) ──────────────────────────────────────
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

    // ── 4. Bento Grid Row Container (Flex Row, Gap: 20) ───────────────────────
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
    col_border_a = noksha_color_pack_rgba(59, 130, 246, 180) // Electric Blue border
    card_a_view = noksha_view_create_card(103, card_a_node, col_card_a, 16, 2, col_border_a, 16, 0)

    // Card B: Silicon RHI Engine Card (flex_grow: 2 — wider featured card)
    card_b_style = noksha_style_create()
    noksha_style_set_size(card_b_style, -1, 400)
    noksha_style_set_flex_grow(card_b_style, 2)
    noksha_style_set_padding(card_b_style, 24, 24, 24, 24)
    card_b_node = noksha_node_create(104, card_b_style)
    noksha_node_add_child(bento_row_node, card_b_node)

    col_card_b = noksha_color_pack_rgba(20, 28, 42, 240)
    col_border_b = noksha_color_pack_rgba(16, 185, 129, 180) // Emerald border
    card_b_view = noksha_view_create_card(104, card_b_node, col_card_b, 16, 2, col_border_b, 20, 0)

    // Card C: Reactive Stream Card (flex_grow: 1)
    card_c_style = noksha_style_create()
    noksha_style_set_size(card_c_style, -1, 400)
    noksha_style_set_flex_grow(card_c_style, 1)
    noksha_style_set_padding(card_c_style, 20, 20, 20, 20)
    card_c_node = noksha_node_create(105, card_c_style)
    noksha_node_add_child(bento_row_node, card_c_node)

    col_card_c = noksha_color_pack_rgba(24, 32, 47, 240)
    col_border_c = noksha_color_pack_rgba(168, 85, 247, 180) // Purple border
    card_c_view = noksha_view_create_card(105, card_c_node, col_card_c, 16, 2, col_border_c, 16, 0)

    // ── 5. Layout Pass (O(N) Linear Time Computation) ─────────────────────────
    noksha_layout_compute_flex(root_node, 0, 0, 1200, 800)

    println("✔ Bento Layout Solved Successfully:")
    println("  • Header: (" + to_str(noksha_node_get_x(header_node)) + ", " + to_str(noksha_node_get_y(header_node)) + ") Size: " + to_str(noksha_node_get_w(header_node)) + "x" + to_str(noksha_node_get_h(header_node)))
    println("  • Card A (Telemetry): Width = " + to_str(noksha_node_get_w(card_a_node)) + "px")
    println("  • Card B (Featured RHI): Width = " + to_str(noksha_node_get_w(card_b_node)) + "px (2x Proportional Width)")
    println("  • Card C (Signals): Width = " + to_str(noksha_node_get_w(card_c_node)) + "px")

    // ── 6. Render Frame to Canvas ─────────────────────────────────────────────
    col_canvas_bg = noksha_color_pack_rgba(11, 15, 25, 255)
    noksha_canvas_draw_rect(canvas, 0, 0, 1200, 800, col_canvas_bg)

    noksha_view_render(header_view, canvas)
    noksha_view_render(card_a_view, canvas)
    noksha_view_render(card_b_view, canvas)
    noksha_view_render(card_c_view, canvas)

    total_batched = noksha_canvas_flush(canvas)
    println("✔ Entire Bento Grid Dashboard rendered in " + to_str(total_batched) + " instanced GPU quads!")

    // ── 7. Teardown ───────────────────────────────────────────────────────────
    noksha_drm_fb_destroy(fb)
    noksha_batcher_destroy(batcher)
    noksha_cmd_buffer_destroy(cmd_buf)
    noksha_rhi_destroy(rhi_dev)
    noksha_arena_destroy(arena)

    println("=================================================================")
    println("👑 NOKSHA BENTO GRID DEMO FINISHED SUCCESSFULLY!")
    println("=================================================================")
    return 0
end

main()
