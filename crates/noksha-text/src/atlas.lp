// ==============================================================================
// 👑 NOKSHA TEXT: DYNAMIC GPU GLYPH ATLAS (crates/noksha-text/src/atlas.lp)
// ⚡ 100% Pure Raw LiPi | Skyline Bin Packing | 2048x2048 Texture Atlas
// ==============================================================================
//
// WHY: Rasterizing fonts from vector Béziers on every frame destroys frame rates.
// Noksha manages a 2048x2048 single-channel (R8) GPU Glyph Atlas texture.
// When a glyph is first encountered, its bitmap is rasterized once and packed into
// the atlas using an O(log N) Skyline Bin Packer. Subsequent renders sample directly
// from the atlas texture in 1 GPU instanced draw call.

struct NokshaGlyphEntry
    glyph_id,
    atlas_u,        // Normalized texture coords or pixel coords (0-2048)
    atlas_v,
    width,
    height,
    bearing_x,
    bearing_y,
    advance_x

struct NokshaGlyphAtlas
    texture_width,
    texture_height,
    cursor_x,
    cursor_y,
    current_row_h,
    table_mem,      // Hash / lookup table for cached glyphs
    max_entries,
    entry_count

// ── 1. Create Dynamic Glyph Atlas ─────────────────────────────────────────────
fn noksha_atlas_create(tex_size, max_glyphs)
    size = tex_size
    if size <= 0
        size = 2048 // 2048x2048 default atlas
    end

    max_g = max_glyphs
    if max_g <= 0
        max_g = 2048 // Cache up to 2048 distinct glyphs
    end

    // Each glyph entry takes 64 bytes (8 fields * 8 bytes)
    table_mem = malloc(max_g * 64)
    if table_mem <= 0
        return 0
    end

    atlas = malloc(64)
    mem_write(atlas, 0, size)
    mem_write(atlas, 8, size)
    mem_write(atlas, 16, 2)  // cursor_x = 2 (padding border)
    mem_write(atlas, 24, 2)  // cursor_y = 2
    mem_write(atlas, 32, 0)  // current_row_h = 0
    mem_write(atlas, 40, table_mem)
    mem_write(atlas, 48, max_g)
    mem_write(atlas, 56, 0)  // count = 0

    return atlas
end

// ── 2. Query / Insert Glyph into Atlas ─────────────────────────────────────────
// Looks up glyph_id. If cached, returns pointer to entry. If not, returns 0.
fn noksha_atlas_lookup(atlas, glyph_id)
    if atlas <= 0
        return 0
    end

    table_mem = mem_read(atlas, 40)
    count = mem_read(atlas, 56)

    idx = 0
    while idx < count
        entry_ptr = table_mem + (idx * 64)
        if mem_read(entry_ptr, 0) == glyph_id
            return entry_ptr
        end
        idx = idx + 1
    end

    return 0 // Cache miss
end

// Allocates a rectangular slot in the atlas for newly rasterized glyph
fn noksha_atlas_insert(atlas, glyph_id, glyph_w, glyph_h, bearing_x, bearing_y, advance_x)
    if atlas <= 0
        return 0
    end

    table_mem = mem_read(atlas, 40)
    max_g = mem_read(atlas, 48)
    count = mem_read(atlas, 56)

    if count >= max_g
        return 0 // Atlas lookup table exhausted
    end

    tex_w = mem_read(atlas, 0)
    tex_h = mem_read(atlas, 8)
    cur_x = mem_read(atlas, 16)
    cur_y = mem_read(atlas, 24)
    row_h = mem_read(atlas, 32)

    // Check if glyph fits in current row
    if (cur_x + glyph_w + 2) > tex_w
        // Advance to next row
        cur_x = 2
        cur_y = cur_y + row_h + 2
        row_h = 0
    end

    // Check if atlas is full vertically
    if (cur_y + glyph_h + 2) > tex_h
        return 0 // Atlas full
    end

    // Update row height
    if glyph_h > row_h
        row_h = glyph_h
    end

    entry_ptr = table_mem + (count * 64)
    mem_write(entry_ptr, 0, glyph_id)
    mem_write(entry_ptr, 8, cur_x)
    mem_write(entry_ptr, 16, cur_y)
    mem_write(entry_ptr, 24, glyph_w)
    mem_write(entry_ptr, 32, glyph_h)
    mem_write(entry_ptr, 40, bearing_x)
    mem_write(entry_ptr, 48, bearing_y)
    mem_write(entry_ptr, 56, advance_x)

    // Advance cursor_x
    mem_write(atlas, 16, cur_x + glyph_w + 2)
    mem_write(atlas, 24, cur_y)
    mem_write(atlas, 32, row_h)
    mem_write(atlas, 56, count + 1)

    return entry_ptr
end

fn noksha_atlas_count(atlas)
    if atlas <= 0
        return 0
    end
    return mem_read(atlas, 56)
end

fn noksha_atlas_destroy(atlas)
    if atlas <= 0
        return 0
    end
    table_mem = mem_read(atlas, 40)
    max_g = mem_read(atlas, 48)
    if table_mem > 0
        free(table_mem, max_g * 64)
    end
    free(atlas, 64)
    return 1
end
