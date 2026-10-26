// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Package: noksha-canvas
// Module: clip_stack
// Purpose: Hierarchical hardware scissor clipping stack.
//
// WHY: Deeply nested scroll areas, modal dialogs, and rounded containers require
// restricted rendering boundaries (clipping). In traditional engines, nested clips
// cause expensive offscreen render target allocations. Noksha uses an in-place
// Scissor Box Intersection Stack: pushing a child clip intersects it with the parent clip,
// ensuring strictly monotonic scissor shrinkage. Popping restores the parent scissor box.

struct NokshaClipStack
    stack_mem,
    capacity,
    depth           // Number of active clips on stack

// ── 1. Create Scissor Clip Stack ──────────────────────────────────────────────
fn noksha_clip_stack_create(max_depth)
    cap = max_depth
    if cap <= 0
        cap = 64 // Default up to 64 nested clipping levels
    end

    // Each clip level stores a 32-byte NokshaRect (x, y, w, h)
    total_bytes = cap * 32
    stack_mem = malloc(total_bytes)
    if stack_mem <= 0
        return 0
    end

    // Base default clip at depth 0: Fullscreen (0, 0, 65535, 65535)
    mem_write(stack_mem, 0, 0)
    mem_write(stack_mem, 8, 0)
    mem_write(stack_mem, 16, 65535)
    mem_write(stack_mem, 24, 65535)

    cs = malloc(24)
    mem_write(cs, 0, stack_mem)
    mem_write(cs, 8, cap)
    mem_write(cs, 16, 1) // Initial depth = 1 (default fullscreen clip)

    return cs
end

// ── 2. Push Nested Scissor Clip ───────────────────────────────────────────────
// Intersects the new clip (x, y, w, h) with the current top of the stack
fn noksha_clip_stack_push(cs, x, y, width, height)
    if cs <= 0
        return 0
    end

    stack_mem = mem_read(cs, 0)
    cap = mem_read(cs, 8)
    depth = mem_read(cs, 16)

    if depth >= cap
        return 0 // Stack overflow
    end

    // Read parent clip at depth - 1
    parent_base = stack_mem + ((depth - 1) * 32)
    px = mem_read(parent_base, 0)
    py = mem_read(parent_base, 8)
    pw = mem_read(parent_base, 16)
    ph = mem_read(parent_base, 24)

    // Compute intersection of [px, py, pw, ph] and [x, y, width, height]
    x1 = px
    if x > x1
        x1 = x
    end

    y1 = py
    if y > y1
        y1 = y
    end

    x2 = px + pw
    if (x + width) < x2
        x2 = x + width
    end

    y2 = py + ph
    if (y + height) < y2
        y2 = y + height
    end

    child_w = x2 - x1
    child_h = y2 - y1
    if child_w < 0
        child_w = 0
    end
    if child_h < 0
        child_h = 0
    end

    // Store in new depth slot
    child_base = stack_mem + (depth * 32)
    mem_write(child_base, 0, x1)
    mem_write(child_base, 8, y1)
    mem_write(child_base, 16, child_w)
    mem_write(child_base, 24, child_h)

    mem_write(cs, 16, depth + 1)
    return 1
end

// ── 3. Pop Scissor Clip ───────────────────────────────────────────────────────
fn noksha_clip_stack_pop(cs)
    if cs <= 0
        return 0
    end

    depth = mem_read(cs, 16)
    if depth <= 1
        // Cannot pop the base fullscreen clip
        return 0
    end

    mem_write(cs, 16, depth - 1)
    return 1
end

// ── 4. Query Current Active Clip Bounds ────────────────────────────────────────
fn noksha_clip_stack_top_x(cs)
    if cs <= 0
        return 0
    end
    stack_mem = mem_read(cs, 0)
    depth = mem_read(cs, 16)
    base = stack_mem + ((depth - 1) * 32)
    return mem_read(base, 0)
end

fn noksha_clip_stack_top_y(cs)
    if cs <= 0
        return 0
    end
    stack_mem = mem_read(cs, 0)
    depth = mem_read(cs, 16)
    base = stack_mem + ((depth - 1) * 32)
    return mem_read(base, 8)
end

fn noksha_clip_stack_top_w(cs)
    if cs <= 0
        return 0
    end
    stack_mem = mem_read(cs, 0)
    depth = mem_read(cs, 16)
    base = stack_mem + ((depth - 1) * 32)
    return mem_read(base, 16)
end

fn noksha_clip_stack_top_h(cs)
    if cs <= 0
        return 0
    end
    stack_mem = mem_read(cs, 0)
    depth = mem_read(cs, 16)
    base = stack_mem + ((depth - 1) * 32)
    return mem_read(base, 24)
end

fn noksha_clip_stack_destroy(cs)
    if cs <= 0
        return 0
    end
    stack_mem = mem_read(cs, 0)
    cap = mem_read(cs, 8)
    if stack_mem > 0
        free(stack_mem, cap * 32)
    end
    free(cs, 24)
    return 1
end
