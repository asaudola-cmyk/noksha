// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Package: tests
// Module: test_noksha_conformance
// Purpose: Automated verification suite covering all core subsystems.

include "crates/noksha.lp"

fn assert_true(cond, msg)
    if cond == 0
        println("  FAIL: " + msg)
        return 0
    end
    println("  PASS: " + msg)
    return 1
end

fn assert_eq_int(actual, expected, msg)
    if actual != expected
        println("  FAIL: " + msg + " (expected " + to_str(expected) + ", got " + to_str(actual) + ")")
        return 0
    end
    println("  PASS: " + msg + " (" + to_str(actual) + " == " + to_str(expected) + ")")
    return 1
end

fn main()
    println("Noksha Conformance Test Suite (v1.0.0)")
    println("--------------------------------------")

    total_tests = 0
    passed_tests = 0

    noksha_engine_init()

    // ── Section 1: noksha-core (Arena, Ring, Math, Color) ─────────────────────
    println("\n[Section 1] noksha-core")

    // 1.1 Arena
    arena = noksha_arena_create(65536)
    p1 = noksha_arena_alloc(arena, 48)
    p2 = noksha_arena_alloc_aligned(arena, 64, 32)
    mem_write(p1, 0, 88888)
    
    total_tests = total_tests + 1
    if assert_eq_int(mem_read(p1, 0), 88888, "Arena memory readback matches written word") == 1
        passed_tests = passed_tests + 1
    end

    total_tests = total_tests + 1
    if assert_true(p2 % 32 == 0, "Arena custom 32-byte alignment enforced") == 1
        passed_tests = passed_tests + 1
    end

    noksha_arena_reset(arena)
    total_tests = total_tests + 1
    if assert_eq_int(noksha_arena_used(arena), 0, "Arena O(1) reset clears usage to 0") == 1
        passed_tests = passed_tests + 1
    end

    // 1.2 Ring Buffer
    ring = noksha_ring_create(16384)
    r1 = noksha_ring_alloc(ring, 128)
    noksha_ring_advance(ring)
    total_tests = total_tests + 1
    if assert_eq_int(noksha_ring_frame_index(ring), 1, "Ring buffer advances frame index") == 1
        passed_tests = passed_tests + 1
    end

    // 1.3 Rect Intersection
    ra = noksha_rect_new(10, 10, 100, 100)
    rb = noksha_rect_new(50, 50, 100, 100)
    r_out = noksha_rect_new(0, 0, 0, 0)
    intersects = noksha_rect_intersect(r_out, ra, rb)

    total_tests = total_tests + 1
    if assert_eq_int(intersects, 1, "Rect intersection detected") == 1
        passed_tests = passed_tests + 1
    end

    total_tests = total_tests + 1
    if assert_eq_int(noksha_rect_get_width(r_out), 60, "Intersected width is 60px") == 1
        passed_tests = passed_tests + 1
    end

    // 1.4 Color Lerp
    c_red = noksha_color_pack_rgba(255, 0, 0, 255)
    c_blue = noksha_color_pack_rgba(0, 0, 255, 255)
    c_mid = noksha_color_lerp(c_red, c_blue, 50)
    total_tests = total_tests + 1
    if assert_true(c_mid > 0, "Color lerp interpolation computed") == 1
        passed_tests = passed_tests + 1
    end

    // ── Section 2: noksha-rhi (Command Buffers & DRM) ─────────────────────────
    println("\n[Section 2] noksha-rhi")

    cmd_buf = noksha_cmd_buffer_create(8192)
    noksha_cmd_encode_viewport(cmd_buf, 1920, 1080)
    noksha_cmd_encode_scissor(cmd_buf, 0, 0, 800, 600)
    noksha_cmd_encode_clear(cmd_buf, 4278190080)
    noksha_cmd_encode_present(cmd_buf)

    total_tests = total_tests + 1
    if assert_eq_int(noksha_cmd_buffer_count(cmd_buf), 4, "Encoded 4 RHI commands") == 1
        passed_tests = passed_tests + 1
    end

    fb = noksha_drm_fb_create(200, 200)
    noksha_drm_draw_pixel(fb, 50, 50, 4294967295)
    total_tests = total_tests + 1
    if assert_eq_int(noksha_drm_read_pixel(fb, 50, 50), 4294967295, "DRM pixel readback verified") == 1
        passed_tests = passed_tests + 1
    end

    // ── Section 3: noksha-canvas (Batcher & Clip Stack) ───────────────────────
    println("\n[Section 3] noksha-canvas")

    batcher = noksha_batcher_create(512)
    clip_stack = noksha_clip_stack_create(16)
    canvas = noksha_canvas_create(batcher, clip_stack, cmd_buf)

    noksha_canvas_draw_rect(canvas, 10, 10, 100, 50, 4280000000)
    noksha_canvas_draw_button(canvas, 20, 80, 120, 40, 8, 4290000000, 1, 4294967295)
    total_tests = total_tests + 1
    if assert_eq_int(noksha_batcher_count(batcher), 2, "Batcher aggregated 2 quads") == 1
        passed_tests = passed_tests + 1
    end

    flushed = noksha_canvas_flush(canvas)
    total_tests = total_tests + 1
    if assert_eq_int(flushed, 2, "Canvas flushed 2 quads in 1 pass") == 1
        passed_tests = passed_tests + 1
    end

    // ── Section 4: noksha-layout (W3C Flexbox Level 1) ────────────────────────
    println("\n[Section 4] noksha-layout")

    // 4.1 Equal flex grow
    parent_style = noksha_style_create()
    noksha_style_set_size(parent_style, 600, 400)
    noksha_style_set_direction(parent_style, noksha_flex_row())
    noksha_style_set_gap(parent_style, 20)

    p_node = noksha_node_create(10, parent_style)

    item1_style = noksha_style_create()
    noksha_style_set_size(item1_style, -1, 400)
    noksha_style_set_flex_grow(item1_style, 1)
    n_item1 = noksha_node_create(11, item1_style)
    noksha_node_add_child(p_node, n_item1)

    item2_style = noksha_style_create()
    noksha_style_set_size(item2_style, -1, 400)
    noksha_style_set_flex_grow(item2_style, 1)
    n_item2 = noksha_node_create(12, item2_style)
    noksha_node_add_child(p_node, n_item2)

    noksha_layout_compute_flex(p_node, 0, 0, 600, 400)

    w1 = noksha_node_get_w(n_item1)
    w2 = noksha_node_get_w(n_item2)
    // 600 - 20 (gap) = 580 / 2 = 290px each
    total_tests = total_tests + 1
    if assert_eq_int(w1, 290, "Flex Item 1 equal proportional width (290px)") == 1
        passed_tests = passed_tests + 1
    end

    total_tests = total_tests + 1
    if assert_eq_int(w2, 290, "Flex Item 2 equal proportional width (290px)") == 1
        passed_tests = passed_tests + 1
    end

    // 4.2 Flex-grow with base size (flex-basis preserved when growing)
    // Container 600px. Item A: base 100px, grow 1. Item B: base 100px, grow 1. Gap 0.
    // Free space = 600 - 200 = 400. Each grows by (400 * 1)/2 = 200. Final = 100 + 200 = 300px.
    p_basis_style = noksha_style_create()
    noksha_style_set_size(p_basis_style, 600, 100)
    noksha_style_set_direction(p_basis_style, noksha_flex_row())
    p_basis_node = noksha_node_create(20, p_basis_style)

    c_b1_style = noksha_style_create()
    noksha_style_set_size(c_b1_style, 100, 100)
    noksha_style_set_flex_grow(c_b1_style, 1)
    n_b1 = noksha_node_create(21, c_b1_style)
    noksha_node_add_child(p_basis_node, n_b1)

    c_b2_style = noksha_style_create()
    noksha_style_set_size(c_b2_style, 100, 100)
    noksha_style_set_flex_grow(c_b2_style, 1)
    n_b2 = noksha_node_create(22, c_b2_style)
    noksha_node_add_child(p_basis_node, n_b2)

    noksha_layout_compute_flex(p_basis_node, 0, 0, 600, 100)
    total_tests = total_tests + 1
    if assert_eq_int(noksha_node_get_w(n_b1), 300, "Flex-grow preserves base size (100 + 200 = 300px)") == 1
        passed_tests = passed_tests + 1
    end

    // 4.3 Free space distribution among auto-sized children when total_grow == 0
    // Container 600px, 3 auto items (cw = -1, grow = 0) -> 600 / 3 = 200px each
    p_auto_style = noksha_style_create()
    noksha_style_set_size(p_auto_style, 600, 100)
    noksha_style_set_direction(p_auto_style, noksha_flex_row())
    p_auto_node = noksha_node_create(30, p_auto_style)

    a1_style = noksha_style_create()
    noksha_style_set_size(a1_style, -1, 100)
    n_a1 = noksha_node_create(31, a1_style)
    noksha_node_add_child(p_auto_node, n_a1)

    a2_style = noksha_style_create()
    noksha_style_set_size(a2_style, -1, 100)
    n_a2 = noksha_node_create(32, a2_style)
    noksha_node_add_child(p_auto_node, n_a2)

    a3_style = noksha_style_create()
    noksha_style_set_size(a3_style, -1, 100)
    n_a3 = noksha_node_create(33, a3_style)
    noksha_node_add_child(p_auto_node, n_a3)

    noksha_layout_compute_flex(p_auto_node, 0, 0, 600, 100)
    total_tests = total_tests + 1
    if assert_eq_int(noksha_node_get_w(n_a1), 200, "Auto-sized item distributes free space (600/3 = 200px)") == 1
        passed_tests = passed_tests + 1
    end

    // 4.4 Justify Content: SpaceBetween
    // Container 500px, two 100px items: item1 x=0, item2 x=400 (500-100)
    p_jc_style = noksha_style_create()
    noksha_style_set_size(p_jc_style, 500, 100)
    noksha_style_set_direction(p_jc_style, noksha_flex_row())
    noksha_style_set_justify_content(p_jc_style, noksha_justify_space_between())
    p_jc_node = noksha_node_create(40, p_jc_style)

    jc1_style = noksha_style_create()
    noksha_style_set_size(jc1_style, 100, 100)
    n_jc1 = noksha_node_create(41, jc1_style)
    noksha_node_add_child(p_jc_node, n_jc1)

    jc2_style = noksha_style_create()
    noksha_style_set_size(jc2_style, 100, 100)
    n_jc2 = noksha_node_create(42, jc2_style)
    noksha_node_add_child(p_jc_node, n_jc2)

    noksha_layout_compute_flex(p_jc_node, 0, 0, 500, 100)
    total_tests = total_tests + 1
    if assert_eq_int(noksha_node_get_x(n_jc2), 400, "Justify Content SpaceBetween aligns last item at 400px") == 1
        passed_tests = passed_tests + 1
    end

    // 4.5 Margins: mar_l shifts child positioning
    p_mar_style = noksha_style_create()
    noksha_style_set_size(p_mar_style, 300, 100)
    p_mar_node = noksha_node_create(50, p_mar_style)

    c_mar_style = noksha_style_create()
    noksha_style_set_size(c_mar_style, 80, 80)
    noksha_style_set_margin(c_mar_style, 25, 10, 0, 0)
    n_mar = noksha_node_create(51, c_mar_style)
    noksha_node_add_child(p_mar_node, n_mar)

    noksha_layout_compute_flex(p_mar_node, 0, 0, 300, 100)
    total_tests = total_tests + 1
    if assert_eq_int(noksha_node_get_x(n_mar), 25, "Margin left 25px applied to child layout coordinate") == 1
        passed_tests = passed_tests + 1
    end

    // ── Section 5: noksha-text & Shaper ───────────────────────────────────────
    println("\n[Section 5] noksha-text")

    atlas = noksha_atlas_create(1024, 256)
    noksha_atlas_insert(atlas, 77, 10, 16, 0, 14, 12)
    total_tests = total_tests + 1
    if assert_true(noksha_atlas_lookup(atlas, 77) > 0, "Atlas glyph lookup returns valid entry") == 1
        passed_tests = passed_tests + 1
    end

    // 5.2 Atlas R8 pixel buffer allocated
    total_tests = total_tests + 1
    if assert_true(noksha_atlas_get_pixels(atlas) > 0, "Atlas R8 pixel bitmap storage buffer allocated") == 1
        passed_tests = passed_tests + 1
    end

    // 5.3 ASCII text shaping
    run = noksha_glyph_run_create(64)
    sc = noksha_shape_text(run, "LiPi", 16, 10)
    total_tests = total_tests + 1
    if assert_eq_int(sc, 4, "Shaped 4 glyphs for 'LiPi'") == 1
        passed_tests = passed_tests + 1
    end

    // 5.4 Bengali conjunct table lookup
    total_tests = total_tests + 1
    if assert_eq_int(noksha_bengali_conjunct_lookup(2453, 2487), 1001, "Bengali conjunct lookup: ক্+ষ = ক্ষ (1001)") == 1
        passed_tests = passed_tests + 1
    end

    total_tests = total_tests + 1
    if assert_eq_int(noksha_bengali_conjunct_lookup(2460, 2462), 1002, "Bengali conjunct lookup: জ্+ঞ = জ্ঞ (1002)") == 1
        passed_tests = passed_tests + 1
    end

    total_tests = total_tests + 1
    if assert_eq_int(noksha_bengali_conjunct_lookup(2468, 2480), 1013, "Bengali conjunct lookup: ত্+র = ত্র (1013)") == 1
        passed_tests = passed_tests + 1
    end

    // 5.5 Full consumption of C1 + Hasanta + C2 in "ক্ষ" (single glyph)
    b_run = noksha_glyph_run_create(64)
    bsc = noksha_shape_text(b_run, "ক্ষ", 24, 14)
    total_tests = total_tests + 1
    if assert_eq_int(bsc, 1, "Bengali 'ক্ষ' consumes C1+Hasanta+C2 into 1 shaped glyph") == 1
        passed_tests = passed_tests + 1
    end
    total_tests = total_tests + 1
    if assert_eq_int(noksha_glyph_run_get_glyph_id(b_run, 0), 1001, "'ক্ষ' shaped glyph ID is 1001") == 1
        passed_tests = passed_tests + 1
    end

    // 5.6 Pre-base vowel reordering in "কি"
    // "কি" = ক (2453) + ি (2495). Visual order: ি (2495) at x=0, ক (2453) at x>0
    ki_run = noksha_glyph_run_create(64)
    kisc = noksha_shape_text(ki_run, "কি", 24, 14)
    total_tests = total_tests + 1
    if assert_eq_int(kisc, 2, "Shaped 2 glyphs for 'কি'") == 1
        passed_tests = passed_tests + 1
    end
    total_tests = total_tests + 1
    if assert_eq_int(noksha_glyph_run_get_glyph_id(ki_run, 0), 2495, "Pre-base vowel 'ি' reordered to index 0 (x=0)") == 1
        passed_tests = passed_tests + 1
    end
    total_tests = total_tests + 1
    if assert_eq_int(noksha_glyph_run_get_glyph_id(ki_run, 1), 2453, "Consonant 'ক' positioned after pre-base vowel") == 1
        passed_tests = passed_tests + 1
    end

    // ── Section 6: noksha-reactive (Signals, Computed, Effect, Batch) ─────────
    println("\n[Section 6] noksha-reactive")

    sig = noksha_signal_create(100)
    total_tests = total_tests + 1
    if assert_eq_int(noksha_signal_get(sig), 100, "Signal initial value is 100") == 1
        passed_tests = passed_tests + 1
    end

    // Subscribe item1 node to signal
    noksha_signal_subscribe(sig, n_item1)
    noksha_signal_set(sig, 200)
    total_tests = total_tests + 1
    if assert_eq_int(noksha_signal_get(sig), 200, "Signal value mutated to 200") == 1
        passed_tests = passed_tests + 1
    end

    // 6.2 Auto-incrementing signal ID
    sig2 = noksha_signal_create(500)
    total_tests = total_tests + 1
    if assert_true(noksha_signal_get_id(sig2) > noksha_signal_get_id(sig), "Auto-incrementing signal IDs assigned") == 1
        passed_tests = passed_tests + 1
    end

    // 6.3 Signal unsubscribe
    sub_count_before = noksha_signal_subscribers_count(sig)
    noksha_signal_unsubscribe(sig, n_item1)
    sub_count_after = noksha_signal_subscribers_count(sig)
    total_tests = total_tests + 1
    if assert_eq_int(sub_count_after, sub_count_before - 1, "Unsubscribed node from signal (count decremented)") == 1
        passed_tests = passed_tests + 1
    end

    // 6.4 Computed<T> with lazy memoization and dirty tracking
    comp_sig = noksha_signal_create(50)
    // Compute fn type 1: Double source value (50 * 2 = 100)
    comp = noksha_computed_create(comp_sig, 1, 0)
    total_tests = total_tests + 1
    if assert_eq_int(noksha_computed_get(comp), 100, "Computed initial evaluated value (50 * 2 = 100)") == 1
        passed_tests = passed_tests + 1
    end

    // Mutate source signal -> marks computed dirty -> evaluates 75 * 2 = 150
    noksha_signal_set(comp_sig, 75)
    total_tests = total_tests + 1
    if assert_eq_int(noksha_computed_get(comp), 150, "Computed re-evaluates dirty value (75 * 2 = 150)") == 1
        passed_tests = passed_tests + 1
    end

    // 6.5 Effect creation and dispatch
    eff_node = noksha_node_create(60, item1_style)
    eff = noksha_effect_create(eff_node, 1, 0)
    noksha_effect_dispatch(eff)
    total_tests = total_tests + 1
    if assert_eq_int(noksha_effect_get_run_count(eff), 1, "Effect dispatched and run count incremented to 1") == 1
        passed_tests = passed_tests + 1
    end

    // 6.6 Batch transaction: deferring subscriber notification until batch end
    batch_sig = noksha_signal_create(10)
    batch_node = noksha_node_create(61, item1_style)
    mem_write(batch_node, 80, 0) // clear dirty
    noksha_signal_subscribe(batch_sig, batch_node)

    noksha_batch_start()
    noksha_signal_set(batch_sig, 20)
    // During batch, batch_node should remain clean (0)
    total_tests = total_tests + 1
    if assert_eq_int(mem_read(batch_node, 80), 0, "Batch active: subscriber dirty notification deferred") == 1
        passed_tests = passed_tests + 1
    end

    noksha_batch_end()
    // After batch ends, batch_node should now be marked dirty (1)
    total_tests = total_tests + 1
    if assert_eq_int(mem_read(batch_node, 80), 1, "Batch ended: queued subscriber flushed and marked dirty") == 1
        passed_tests = passed_tests + 1
    end

    // ── Section 7: noksha-ui (View Tree Hierarchy & Text View) ────────────────
    println("\n[Section 7] noksha-ui")

    // 7.1 Text view creation
    text_v = noksha_view_create_text(701, n_item1, "Noksha UI", 16, 4294967295)
    total_tests = total_tests + 1
    if assert_true(text_v > 0, "Created Text view component (view_type 4)") == 1
        passed_tests = passed_tests + 1
    end

    // 7.2 View tree child hierarchy
    card_v = noksha_view_create_card(700, p_node, 4280000000, 8, 1, 4294967295, 0, 0)
    noksha_view_add_child(card_v, text_v)
    total_tests = total_tests + 1
    if assert_eq_int(noksha_view_children_count(card_v), 1, "Added text child to card view (children_count == 1)") == 1
        passed_tests = passed_tests + 1
    end
    total_tests = total_tests + 1
    if assert_eq_int(noksha_view_get_child(card_v, 0), text_v, "Retrieved child view pointer matches text view") == 1
        passed_tests = passed_tests + 1
    end

    // 7.3 View tree recursive render
    ui_cmd = noksha_cmd_buffer_create(4096)
    ui_batcher = noksha_batcher_create(256)
    ui_clips = noksha_clip_stack_create(16)
    ui_canvas = noksha_canvas_create(ui_batcher, ui_clips, ui_cmd)

    noksha_view_render_tree(card_v, ui_canvas)
    total_tests = total_tests + 1
    if assert_true(noksha_batcher_count(ui_batcher) > 0, "noksha_view_render_tree recursively batched quads to canvas") == 1
        passed_tests = passed_tests + 1
    end

    // ── Section 8: noksha-pal (Hit Testing & Gesture Arena) ───────────────────
    println("\n[Section 8] noksha-pal")

    // 8.1 Hit testing
    // n_mar is at x=25, y=0, size 80x80
    hit_node = noksha_pal_hit_test(p_mar_node, 35, 15)
    total_tests = total_tests + 1
    if assert_eq_int(hit_node, n_mar, "noksha_pal_hit_test resolved topmost child node under (35, 15)") == 1
        passed_tests = passed_tests + 1
    end

    // 8.2 Gesture arena: tap recognition (pointer down + up within slop)
    g_arena = noksha_gesture_arena_create()
    noksha_gesture_arena_handle_pointer_down(g_arena, p_mar_node, 35, 15, 1000)
    tap_res = noksha_gesture_arena_handle_pointer_up(g_arena, 36, 16, 1050)
    total_tests = total_tests + 1
    if assert_eq_int(tap_res, noksha_gesture_tap(), "Gesture arena recognized Tap (motion <= 8px slop)") == 1
        passed_tests = passed_tests + 1
    end

    // 8.3 Gesture arena: drag/pan recognition (pointer movement > 8px slop)
    noksha_gesture_arena_reset(g_arena)
    noksha_gesture_arena_handle_pointer_down(g_arena, p_mar_node, 35, 15, 2000)
    noksha_gesture_arena_handle_pointer_move(g_arena, 60, 45, 2050) // dx = 25px > 8px slop
    drag_res = noksha_gesture_arena_handle_pointer_up(g_arena, 60, 45, 2100)
    total_tests = total_tests + 1
    if assert_eq_int(drag_res, noksha_gesture_drag(), "Gesture arena recognized Drag/Pan (motion > 8px slop)") == 1
        passed_tests = passed_tests + 1
    end

    // ── Cleanup ───────────────────────────────────────────────────────────────
    noksha_gesture_arena_destroy(g_arena)
    noksha_canvas_destroy(ui_canvas)
    noksha_clip_stack_destroy(ui_clips)
    noksha_batcher_destroy(ui_batcher)
    noksha_cmd_buffer_destroy(ui_cmd)
    noksha_view_destroy(text_v)
    noksha_view_destroy(card_v)
    noksha_node_destroy(batch_node)
    noksha_signal_destroy(batch_sig)
    noksha_effect_destroy(eff)
    noksha_node_destroy(eff_node)
    noksha_computed_destroy(comp)
    noksha_signal_destroy(comp_sig)
    noksha_signal_destroy(sig2)
    noksha_signal_destroy(sig)
    noksha_glyph_run_destroy(ki_run)
    noksha_glyph_run_destroy(b_run)
    noksha_glyph_run_destroy(run)
    noksha_atlas_destroy(atlas)
    noksha_node_destroy(n_mar)
    noksha_style_destroy(c_mar_style)
    noksha_node_destroy(p_mar_node)
    noksha_style_destroy(p_mar_style)
    noksha_node_destroy(n_jc2)
    noksha_style_destroy(jc2_style)
    noksha_node_destroy(n_jc1)
    noksha_style_destroy(jc1_style)
    noksha_node_destroy(p_jc_node)
    noksha_style_destroy(p_jc_style)
    noksha_node_destroy(n_a3)
    noksha_style_destroy(a3_style)
    noksha_node_destroy(n_a2)
    noksha_style_destroy(a2_style)
    noksha_node_destroy(n_a1)
    noksha_style_destroy(a1_style)
    noksha_node_destroy(p_auto_node)
    noksha_style_destroy(p_auto_style)
    noksha_node_destroy(n_b2)
    noksha_style_destroy(c_b2_style)
    noksha_node_destroy(n_b1)
    noksha_style_destroy(c_b1_style)
    noksha_node_destroy(p_basis_node)
    noksha_style_destroy(p_basis_style)
    noksha_node_destroy(n_item2)
    noksha_style_destroy(item2_style)
    noksha_node_destroy(n_item1)
    noksha_style_destroy(item1_style)
    noksha_node_destroy(p_node)
    noksha_style_destroy(parent_style)
    noksha_rect_destroy(r_out)
    noksha_rect_destroy(rb)
    noksha_rect_destroy(ra)
    noksha_drm_fb_destroy(fb)
    noksha_canvas_destroy(canvas)
    noksha_clip_stack_destroy(clip_stack)
    noksha_batcher_destroy(batcher)
    noksha_cmd_buffer_destroy(cmd_buf)
    noksha_ring_destroy(ring)
    noksha_arena_destroy(arena)

    println("--------------------------------------")
    println("Summary: " + to_str(passed_tests) + " / " + to_str(total_tests) + " tests passed (" + to_str((passed_tests * 100) / total_tests) + "% success rate)")
    println("--------------------------------------")

    if passed_tests == total_tests
        return 0
    end
    return 1
end

main()
