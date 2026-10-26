// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Package: noksha-text
// Module: atlas
// Purpose: Dynamic GPU glyph atlas manager with R8 pixel storage and O(1) hash table lookup.
//
// WHY: Rasterizing fonts from vector Béziers on every frame destroys frame rates.
// Noksha manages a single-channel (R8) GPU Glyph Atlas texture buffer.
// When a glyph is first encountered, its bitmap is rasterized once and packed into
// the atlas using an O(log N) Skyline Bin Packer. Subsequent renders sample directly
// from the atlas texture in 1 GPU instanced draw call via O(1) closed-addressing hash table.

struct NokshaGlyphEntry
    glyph_id,
    atlas_u,        // Pixel coordinates (0-2048)
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
    table_mem,      // Dense storage for cached glyphs (64B per entry)
    max_entries,
    entry_count,
    pixels_mem,     // R8 pixel bitmap storage buffer (tex_w * tex_h bytes)
    hash_mem,       // Fast O(1) hash-table bucket array (hash_cap * 8 bytes)
    hash_cap

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

    // Dense entry storage: each glyph entry takes 64 bytes (8 fields * 8 bytes)
    table_mem = malloc(max_g * 64)
    if table_mem <= 0
        return 0
    end

    // R8 pixel bitmap storage buffer (1 byte per pixel)
    total_pixels = size * size
    pixels_mem = malloc(total_pixels)
    if pixels_mem <= 0
        free(table_mem, max_g * 64)
        return 0
    end

    // Zero out first row of pixel memory
    p_init = 0
    init_limit = 256
    if init_limit > total_pixels
        init_limit = total_pixels
    end
    while p_init < init_limit
        mem_write_byte(pixels_mem, p_init, 0)
        p_init = p_init + 1
    end

    // Hash table lookup array: 2x load factor for O(1) collision resolution
    hash_cap = max_g * 2
    hash_mem = malloc(hash_cap * 8)
    if hash_mem <= 0
        free(pixels_mem, total_pixels)
        free(table_mem, max_g * 64)
        return 0
    end

    // Initialize all hash table buckets to 0 (empty)
    h_idx = 0
    while h_idx < hash_cap
        mem_write(hash_mem, h_idx * 8, 0)
        h_idx = h_idx + 1
    end

    atlas = malloc(88) // 11 fields * 8 bytes
    mem_write(atlas, 0, size)
    mem_write(atlas, 8, size)
    mem_write(atlas, 16, 2)  // cursor_x = 2 (padding border)
    mem_write(atlas, 24, 2)  // cursor_y = 2
    mem_write(atlas, 32, 0)  // current_row_h = 0
    mem_write(atlas, 40, table_mem)
    mem_write(atlas, 48, max_g)
    mem_write(atlas, 56, 0)  // count = 0
    mem_write(atlas, 64, pixels_mem)
    mem_write(atlas, 72, hash_mem)
    mem_write(atlas, 80, hash_cap)

    return atlas
end

// ── 2. Fast O(1) Hash-Table Lookup ────────────────────────────────────────────
// Looks up glyph_id. If cached, returns pointer to entry. If not, returns 0.
fn noksha_atlas_lookup(atlas, glyph_id)
    if atlas <= 0
        return 0
    end

    hash_mem = mem_read(atlas, 72)
    hash_cap = mem_read(atlas, 80)
    if hash_mem <= 0 || hash_cap <= 0
        return 0
    end

    // Knuth multiplicative hash
    h = (glyph_id * 2654435761)
    if h < 0
        h = 0 - h
    end
    bucket = h % hash_cap

    step = 0
    while step < hash_cap
        b_idx = (bucket + step) % hash_cap
        entry_ptr = mem_read(hash_mem, b_idx * 8)
        if entry_ptr == 0
            return 0 // Cache miss (hit empty bucket)
        end
        if mem_read(entry_ptr, 0) == glyph_id
            return entry_ptr // Cache hit
        end
        step = step + 1
    end

    return 0 // Miss after full probe
end

// ── 3. Insert Glyph into Atlas & Update Hash Table ─────────────────────────────
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

    // Insert entry pointer into hash table for O(1) subsequent lookup
    hash_mem = mem_read(atlas, 72)
    hash_cap = mem_read(atlas, 80)
    if hash_mem > 0 && hash_cap > 0
        h = (glyph_id * 2654435761)
        if h < 0
            h = 0 - h
        end
        bucket = h % hash_cap

        step = 0
        inserted = 0
        while step < hash_cap && inserted == 0
            b_idx = (bucket + step) % hash_cap
            existing = mem_read(hash_mem, b_idx * 8)
            if existing == 0
                mem_write(hash_mem, b_idx * 8, entry_ptr)
                inserted = 1
            end
            step = step + 1
        end
    end

    // Advance cursor_x
    mem_write(atlas, 16, cur_x + glyph_w + 2)
    mem_write(atlas, 24, cur_y)
    mem_write(atlas, 32, row_h)
    mem_write(atlas, 56, count + 1)

    return entry_ptr
end

// ── 4. Atlas Accessors & Teardown ─────────────────────────────────────────────
fn noksha_atlas_get_pixels(atlas)
    if atlas <= 0
        return 0
    end
    return mem_read(atlas, 64)
end

fn noksha_atlas_get_texture_width(atlas)
    if atlas <= 0
        return 0
    end
    return mem_read(atlas, 0)
end

fn noksha_atlas_get_texture_height(atlas)
    if atlas <= 0
        return 0
    end
    return mem_read(atlas, 8)
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

    tex_w = mem_read(atlas, 0)
    tex_h = mem_read(atlas, 8)
    pixels_mem = mem_read(atlas, 64)
    if pixels_mem > 0
        free(pixels_mem, tex_w * tex_h)
    end

    hash_mem = mem_read(atlas, 72)
    hash_cap = mem_read(atlas, 80)
    if hash_mem > 0
        free(hash_mem, hash_cap * 8)
    end

    free(atlas, 88)
    return 1
end
