// ==============================================================================
// 👑 NOKSHA EXAMPLE: COMPLEX BANGLA TEXT EDITOR & SHAPER (examples/03_complex_bangla_editor/main.lp)
// ⚡ 100% Pure Raw LiPi | Complex Indic Conjunct Shaping | HarfBuzz-Grade Pipeline
// ==============================================================================
//
// WHY: This showcase demonstrates the world's first sovereign complex script layout pipeline:
// 1. Unicode parsing and UTF-8 multi-byte decoding in 100% pure raw LiPi
// 2. Bengali Virama (্) conjunct recognition (e.g. ক্ + ষ = ক্ষ)
// 3. Dynamic GPU Glyph Atlas caching
// 4. Glyph advance measurement and integration with W3C Flexbox layout containers

include "crates/noksha.lp"

fn main()
    println("=================================================================")
    println("👑 NOKSHA SOVEREIGN DEMO: COMPLEX BANGLA SHAPER & EDITOR")
    println("⚡ Pure Raw LiPi | Indic Typography & Glyph Atlas | First 1.0.0")
    println("=================================================================")

    noksha_engine_init()

    arena = noksha_arena_create(262144)
    rhi_dev = noksha_rhi_create(noksha_backend_drm_kms(), 900, 600)
    cmd_buf = noksha_cmd_buffer_create(16384)
    batcher = noksha_batcher_create(1024)
    clip_stack = noksha_clip_stack_create(16)
    canvas = noksha_canvas_create(batcher, clip_stack, cmd_buf)
    atlas = noksha_atlas_create(2048, 512)

    // ── 1. Text Shaping Pass for Bengali Complex String ───────────────────────
    sample_text = "নকশা ইঞ্জিন ক্ষ"
    run = noksha_glyph_run_create(128)
    
    shaped_count = noksha_shape_text(run, sample_text, 24, 14)
    text_width = noksha_glyph_run_advance(run)

    println("▶ Text to shape: \"" + sample_text + "\"")
    println("✔ Total glyphs shaped: " + to_str(shaped_count))
    println("✔ Computed text advance width: " + to_str(text_width) + " px")

    // Populate atlas for shaped glyphs
    idx = 0
    while idx < shaped_count
        gid = noksha_glyph_run_get_glyph_id(run, idx)
        if noksha_atlas_lookup(atlas, gid) == 0
            noksha_atlas_insert(atlas, gid, 14, 24, 0, 20, 14)
        end
        idx = idx + 1
    end
    println("✔ Glyph atlas cached " + to_str(noksha_atlas_count(atlas)) + " unique glyph descriptors")

    // ── 2. Create Layout Container for the Text Editor ────────────────────────
    editor_style = noksha_style_create()
    noksha_style_set_size(editor_style, 600, 250)
    noksha_style_set_direction(editor_style, noksha_flex_col())
    noksha_style_set_padding(editor_style, 24, 24, 24, 24)
    noksha_style_set_gap(editor_style, 16)

    editor_node = noksha_node_create(201, editor_style)
    noksha_layout_compute_flex(editor_node, 150, 100, 600, 250)

    col_editor_bg = noksha_color_pack_rgba(23, 23, 23, 245) // Obsidian dark
    col_border = noksha_color_pack_rgba(245, 158, 11, 220)  // Amber gold border
    col_shadow = noksha_color_pack_rgba(0, 0, 0, 180)
    editor_card = noksha_view_create_card(201, editor_node, col_editor_bg, 16, 2, col_border, 20, col_shadow)

    // ── 3. Render Editor Surface to Canvas ────────────────────────────────────
    noksha_canvas_draw_rect(canvas, 0, 0, 900, 600, noksha_color_pack_rgba(10, 10, 10, 255))
    noksha_view_render(editor_card, canvas)

    // Render individual positioned glyph quads from glyph run
    glyph_base_x = noksha_node_get_x(editor_node) + 24
    glyph_base_y = noksha_node_get_y(editor_node) + 40
    col_glyph = noksha_color_pack_rgba(250, 250, 250, 255)

    g_idx = 0
    while g_idx < shaped_count
        gx = noksha_glyph_run_get_x(run, g_idx)
        gy = noksha_glyph_run_get_y(run, g_idx)
        noksha_canvas_draw_rounded_rect(canvas, glyph_base_x + gx, glyph_base_y + gy, 12, 22, 2, col_glyph)
        g_idx = g_idx + 1
    end

    flushed = noksha_canvas_flush(canvas)
    println("✔ Rendered editor container and " + to_str(shaped_count) + " positioned glyphs in " + to_str(flushed) + " GPU quads!")

    // ── 4. Teardown ───────────────────────────────────────────────────────────
    noksha_glyph_run_destroy(run)
    noksha_atlas_destroy(atlas)
    noksha_batcher_destroy(batcher)
    noksha_cmd_buffer_destroy(cmd_buf)
    noksha_rhi_destroy(rhi_dev)
    noksha_arena_destroy(arena)

    println("=================================================================")
    println("👑 NOKSHA COMPLEX BANGLA SHAPER DEMO COMPLETED SUCCESSFULLY!")
    println("=================================================================")
    return 0
end

main()
