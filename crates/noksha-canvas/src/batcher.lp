// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Package: noksha-canvas
// Module: batcher
// Purpose: Single-pass instanced quad batcher with full visual attribute persistence.
//
// WHY: In modern high-throughput rendering engines, all rectangular visual primitives
// (cards, buttons, containers, panels) are packed into contiguous instanced vertex/attribute
// buffers dispatched in a single GPU draw call.
// To guarantee zero data loss, Noksha packs each visual element into a 112-byte QuadInstance
// containing 14 64-bit words:
//
// QuadInstance Memory Layout (112 bytes = 14 * 8B):
// [0]: bounds_x,        [8]: bounds_y,        [16]: bounds_w,      [24]: bounds_h
// [32]: clip_x,         [40]: clip_y,         [48]: clip_w,        [56]: clip_h
// [64]: fill_color,     [72]: border_color,   [80]: corner_radius, [88]: border_width
// [96]: shadow_blur,    [104]: shadow_color

struct NokshaBatcher
    instances_ptr,
    max_instances,
    instance_count,
    active_clip_x,
    active_clip_y,
    active_clip_w,
    active_clip_h

// ── 1. Create Instanced Batcher ───────────────────────────────────────────────
fn noksha_batcher_create(max_instances_capacity)
    max_count = max_instances_capacity
    if max_count <= 0
        max_count = 16384 // Default up to 16,384 quads per batch (1.8MB)
    end

    total_bytes = max_count * 112
    inst_mem = malloc(total_bytes)
    if inst_mem <= 0
        return 0
    end

    batcher = malloc(56) // 7 fields * 8 bytes
    mem_write(batcher, 0, inst_mem)
    mem_write(batcher, 8, max_count)
    mem_write(batcher, 16, 0) // count = 0
    mem_write(batcher, 24, 0) // default clip_x = 0
    mem_write(batcher, 32, 0) // default clip_y = 0
    mem_write(batcher, 40, 1920) // default clip_w = 1920
    mem_write(batcher, 48, 1080) // default clip_h = 1080

    return batcher
end

// ── 2. Set Active Scissor Clipping Box for Subsequent Quads ───────────────────
fn noksha_batcher_set_clip(batcher, x, y, width, height)
    if batcher <= 0
        return 0
    end
    mem_write(batcher, 24, x)
    mem_write(batcher, 32, y)
    mem_write(batcher, 40, width)
    mem_write(batcher, 48, height)
    return 1
end

// ── 3. Append Quad Instance to Contiguous Batch Buffer ────────────────────────
// Serializes all 14 visual parameters into contiguous memory with zero truncation
fn noksha_batcher_push_quad(batcher, x, y, w, h, fill_color, border_color, corner_radius, border_width, shadow_blur, shadow_color)
    if batcher <= 0
        return 0
    end

    inst_mem = mem_read(batcher, 0)
    max_count = mem_read(batcher, 8)
    count = mem_read(batcher, 16)

    if count >= max_count
        // Batch buffer full
        return 0
    end

    clip_x = mem_read(batcher, 24)
    clip_y = mem_read(batcher, 32)
    clip_w = mem_read(batcher, 40)
    clip_h = mem_read(batcher, 48)

    // Calculate base offset for this quad: count * 112 bytes
    base = inst_mem + (count * 112)

    mem_write(base, 0, x)
    mem_write(base, 8, y)
    mem_write(base, 16, w)
    mem_write(base, 24, h)
    mem_write(base, 32, clip_x)
    mem_write(base, 40, clip_y)
    mem_write(base, 48, clip_w)
    mem_write(base, 56, clip_h)
    mem_write(base, 64, fill_color)
    mem_write(base, 72, border_color)
    mem_write(base, 80, corner_radius)
    mem_write(base, 88, border_width)
    mem_write(base, 96, shadow_blur)
    mem_write(base, 104, shadow_color)

    mem_write(batcher, 16, count + 1)
    return 1
end

// ── 4. Query Batch State & Element Accessors ──────────────────────────────────
fn noksha_batcher_count(batcher)
    if batcher <= 0
        return 0
    end
    return mem_read(batcher, 16)
end

fn noksha_batcher_buffer_ptr(batcher)
    if batcher <= 0
        return 0
    end
    return mem_read(batcher, 0)
end

fn noksha_batcher_get_bounds_x(batcher, index)
    if batcher <= 0 || index < 0 || index >= mem_read(batcher, 16)
        return 0
    end
    return mem_read(mem_read(batcher, 0) + (index * 112), 0)
end

fn noksha_batcher_get_bounds_y(batcher, index)
    if batcher <= 0 || index < 0 || index >= mem_read(batcher, 16)
        return 0
    end
    return mem_read(mem_read(batcher, 0) + (index * 112), 8)
end

fn noksha_batcher_get_bounds_w(batcher, index)
    if batcher <= 0 || index < 0 || index >= mem_read(batcher, 16)
        return 0
    end
    return mem_read(mem_read(batcher, 0) + (index * 112), 16)
end

fn noksha_batcher_get_bounds_h(batcher, index)
    if batcher <= 0 || index < 0 || index >= mem_read(batcher, 16)
        return 0
    end
    return mem_read(mem_read(batcher, 0) + (index * 112), 24)
end

fn noksha_batcher_get_corner_radius(batcher, index)
    if batcher <= 0 || index < 0 || index >= mem_read(batcher, 16)
        return 0
    end
    return mem_read(mem_read(batcher, 0) + (index * 112), 80)
end

fn noksha_batcher_get_border_width(batcher, index)
    if batcher <= 0 || index < 0 || index >= mem_read(batcher, 16)
        return 0
    end
    return mem_read(mem_read(batcher, 0) + (index * 112), 88)
end

fn noksha_batcher_get_shadow_blur(batcher, index)
    if batcher <= 0 || index < 0 || index >= mem_read(batcher, 16)
        return 0
    end
    return mem_read(mem_read(batcher, 0) + (index * 112), 96)
end

fn noksha_batcher_get_shadow_color(batcher, index)
    if batcher <= 0 || index < 0 || index >= mem_read(batcher, 16)
        return 0
    end
    return mem_read(mem_read(batcher, 0) + (index * 112), 104)
end

// Resets batch count to zero for next frame without reallocating
fn noksha_batcher_reset(batcher)
    if batcher <= 0
        return 0
    end
    mem_write(batcher, 16, 0)
    return 1
end

fn noksha_batcher_destroy(batcher)
    if batcher <= 0
        return 0
    end
    inst_mem = mem_read(batcher, 0)
    max_count = mem_read(batcher, 8)
    if inst_mem > 0
        free(inst_mem, max_count * 112)
    end
    free(batcher, 56)
    return 1
end
