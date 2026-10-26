// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Package: noksha-core
// Module: math/vec2
// Purpose: 2D vector and coordinate arithmetic.
//
// WHY: 2D vector transformations are in the hottest path of UI layout negotiation,
// hit-testing, mouse pointer tracking, and physics-driven spring animations.
// Noksha represents 2D vectors as contiguous 16-byte structs (x: 8 bytes, y: 8 bytes)
// that can be allocated directly in the per-frame bump arena or returned by value.

struct NokshaVec2
    x,
    y

// ── 1. Vector Constructor ─────────────────────────────────────────────────────
// Allocates a 16-byte vector on the heap or arena
fn noksha_vec2_new(x, y)
    v = malloc(16)
    mem_write(v, 0, x)
    mem_write(v, 8, y)
    return v
end

// Sets values on an existing vector pointer (zero allocation)
fn noksha_vec2_set(v, x, y)
    if v <= 0
        return 0
    end
    mem_write(v, 0, x)
    mem_write(v, 8, y)
    return v
end

fn noksha_vec2_get_x(v)
    if v <= 0
        return 0
    end
    return mem_read(v, 0)
end

fn noksha_vec2_get_y(v)
    if v <= 0
        return 0
    end
    return mem_read(v, 8)
end

// ── 2. Vector Arithmetic Operations ───────────────────────────────────────────
fn noksha_vec2_add(out_v, a, b)
    if out_v <= 0 || a <= 0 || b <= 0
        return 0
    end
    ax = mem_read(a, 0)
    ay = mem_read(a, 8)
    bx = mem_read(b, 0)
    by = mem_read(b, 8)
    mem_write(out_v, 0, ax + bx)
    mem_write(out_v, 8, ay + by)
    return out_v
end

fn noksha_vec2_sub(out_v, a, b)
    if out_v <= 0 || a <= 0 || b <= 0
        return 0
    end
    ax = mem_read(a, 0)
    ay = mem_read(a, 8)
    bx = mem_read(b, 0)
    by = mem_read(b, 8)
    mem_write(out_v, 0, ax - bx)
    mem_write(out_v, 8, ay - by)
    return out_v
end

fn noksha_vec2_scale(out_v, v, scalar)
    if out_v <= 0 || v <= 0
        return 0
    end
    vx = mem_read(v, 0)
    vy = mem_read(v, 8)
    mem_write(out_v, 0, vx * scalar)
    mem_write(out_v, 8, vy * scalar)
    return out_v
end

// ── 3. Geometric Metric Operations ────────────────────────────────────────────
fn noksha_vec2_dot(a, b)
    if a <= 0 || b <= 0
        return 0
    end
    ax = mem_read(a, 0)
    ay = mem_read(a, 8)
    bx = mem_read(b, 0)
    by = mem_read(b, 8)
    return (ax * bx) + (ay * by)
end

fn noksha_vec2_length_sq(v)
    if v <= 0
        return 0
    end
    vx = mem_read(v, 0)
    vy = mem_read(v, 8)
    return (vx * vx) + (vy * vy)
end

fn noksha_vec2_distance_sq(a, b)
    if a <= 0 || b <= 0
        return 0
    end
    dx = mem_read(a, 0) - mem_read(b, 0)
    dy = mem_read(a, 8) - mem_read(b, 8)
    return (dx * dx) + (dy * dy)
end

fn noksha_vec2_destroy(v)
    if v > 0
        free(v, 16)
    end
    return 1
end
