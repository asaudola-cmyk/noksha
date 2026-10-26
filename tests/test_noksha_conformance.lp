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

    // Section 1: noksha-core (Arena, Ring, Math, Color)
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

    // ── Test Section 2: noksha-rhi (Command Buffers & DRM) ────────────────────
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

    // ── Test Section 3: noksha-canvas (Batcher & Clip Stack) ──────────────────
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

    // ── Test Section 4: noksha-layout (W3C Flexbox Level 1) ───────────────────
    println("\n[Section 4] noksha-layout")

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

    // ── Test Section 5: noksha-text & Shaper ──────────────────────────────────
    println("\n[Section 5] noksha-text")

    atlas = noksha_atlas_create(1024, 256)
    noksha_atlas_insert(atlas, 77, 10, 16, 0, 14, 12)
    total_tests = total_tests + 1
    if assert_true(noksha_atlas_lookup(atlas, 77) > 0, "Atlas glyph lookup returns valid entry") == 1
        passed_tests = passed_tests + 1
    end

    run = noksha_glyph_run_create(64)
    sc = noksha_shape_text(run, "LiPi", 16, 10)
    total_tests = total_tests + 1
    if assert_eq_int(sc, 4, "Shaped 4 glyphs for 'LiPi'") == 1
        passed_tests = passed_tests + 1
    end

    // ── Test Section 6: noksha-reactive (Signals) ─────────────────────────────
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

    // ── Cleanup ───────────────────────────────────────────────────────────────
    noksha_glyph_run_destroy(run)
    noksha_atlas_destroy(atlas)
    noksha_drm_fb_destroy(fb)
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
