// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Package: noksha-pal
// Module: arena_gesture
// Purpose: Multi-pointer gesture disambiguation arena and recursive scene graph hit testing.
//
// WHY: Modern cross-platform apps encounter ambiguous touch streams (e.g. is this
// touch sequence a button tap, a list scroll pan, or a slider drag?).
// Noksha PAL provides a deterministic Gesture Arena inspired by Flutter / iOS UIKit:
// 1. Recursive Hit Testing: Traverses the layout node tree in z-order to identify the target node.
// 2. Gesture Disambiguation: Tracks movement delta against an 8px touch slop threshold.
//    If the pointer releases within slop, Tap wins. If movement exceeds slop, Pan/Drag wins.

struct NokshaGestureArena
    state,              // 0: Idle, 1: Tracking, 2: RecognizedPan, 3: RecognizedTap
    down_x,
    down_y,
    cur_x,
    cur_y,
    slop_threshold,     // Default 8 pixels
    hit_target_node,
    down_time_ms

// ── 1. Event & Gesture Constants ──────────────────────────────────────────────
fn noksha_event_none()
    return 0
end
fn noksha_event_pointer_down()
    return 1
end
fn noksha_event_pointer_up()
    return 2
end
fn noksha_event_pointer_move()
    return 3
end
fn noksha_event_pointer_cancel()
    return 4
end

fn noksha_gesture_none()
    return 0
end
fn noksha_gesture_tap()
    return 1
end
fn noksha_gesture_drag()
    return 2
end
fn noksha_gesture_long_press()
    return 3
end

// ── 2. Recursive Z-Order Hit Testing ──────────────────────────────────────────
// Traverses node tree from top (last child) to bottom to find topmost node containing (px, py).
fn noksha_pal_hit_test(node, px, py)
    if node <= 0
        return 0
    end

    nx = noksha_node_get_x(node)
    ny = noksha_node_get_y(node)
    nw = noksha_node_get_w(node)
    nh = noksha_node_get_h(node)

    // Check bounding box containment
    if px < nx || px >= (nx + nw) || py < ny || py >= (ny + nh)
        return 0
    end

    // Check children in reverse z-order (topmost first)
    count = noksha_node_children_count(node)
    c_idx = count - 1
    while c_idx >= 0
        child = noksha_node_get_child(node, c_idx)
        hit = noksha_pal_hit_test(child, px, py)
        if hit > 0
            return hit
        end
        c_idx = c_idx - 1
    end

    // No child was hit, so this node is the hit target
    return node
end

// ── 3. Gesture Arena Lifecycle ────────────────────────────────────────────────
fn noksha_gesture_arena_create()
    arena = malloc(64) // 8 fields * 8 bytes
    if arena <= 0
        return 0
    end
    mem_write(arena, 0, 0) // state: Idle (0)
    mem_write(arena, 8, 0) // down_x
    mem_write(arena, 16, 0)// down_y
    mem_write(arena, 24, 0)// cur_x
    mem_write(arena, 32, 0)// cur_y
    mem_write(arena, 40, 8)// slop_threshold: 8px
    mem_write(arena, 48, 0)// hit_target_node: 0
    mem_write(arena, 56, 0)// down_time_ms: 0
    return arena
end

fn noksha_gesture_arena_handle_pointer_down(arena, root_node, px, py, timestamp_ms)
    if arena <= 0
        return 0
    end

    target = 0
    if root_node > 0
        target = noksha_pal_hit_test(root_node, px, py)
    end

    mem_write(arena, 0, 1) // state: Tracking
    mem_write(arena, 8, px)
    mem_write(arena, 16, py)
    mem_write(arena, 24, px)
    mem_write(arena, 32, py)
    mem_write(arena, 48, target)
    mem_write(arena, 56, timestamp_ms)

    return target
end

fn noksha_gesture_arena_handle_pointer_move(arena, px, py, timestamp_ms)
    if arena <= 0
        return 0
    end

    mem_write(arena, 24, px)
    mem_write(arena, 32, py)

    state = mem_read(arena, 0)
    if state == 1 // Tracking
        down_x = mem_read(arena, 8)
        down_y = mem_read(arena, 16)
        slop = mem_read(arena, 40)

        dx = px - down_x
        if dx < 0
            dx = 0 - dx
        end
        dy = py - down_y
        if dy < 0
            dy = 0 - dy
        end

        if dx > slop || dy > slop
            mem_write(arena, 0, 2) // RecognizedPan
            return 2
        end
    end

    return state
end

fn noksha_gesture_arena_handle_pointer_up(arena, px, py, timestamp_ms)
    if arena <= 0
        return 0
    end

    mem_write(arena, 24, px)
    mem_write(arena, 32, py)

    state = mem_read(arena, 0)
    recognized = noksha_gesture_none()

    if state == 1 // Released within slop -> Tap wins!
        recognized = noksha_gesture_tap()
        mem_write(arena, 0, 3) // RecognizedTap
    end
    if state == 2 // Released after exceeding slop -> Pan completed
        recognized = noksha_gesture_drag()
    end

    return recognized
end

fn noksha_gesture_arena_reset(arena)
    if arena <= 0
        return 0
    end
    mem_write(arena, 0, 0) // Idle
    mem_write(arena, 48, 0)// clear hit target
    return 1
end

// ── 4. Gesture Arena Accessors ────────────────────────────────────────────────
fn noksha_gesture_arena_get_target(arena)
    if arena <= 0
        return 0
    end
    return mem_read(arena, 48)
end

fn noksha_gesture_arena_get_state(arena)
    if arena <= 0
        return 0
    end
    return mem_read(arena, 0)
end

fn noksha_gesture_arena_get_delta_x(arena)
    if arena <= 0
        return 0
    end
    return mem_read(arena, 24) - mem_read(arena, 8)
end

fn noksha_gesture_arena_get_delta_y(arena)
    if arena <= 0
        return 0
    end
    return mem_read(arena, 32) - mem_read(arena, 16)
end

fn noksha_gesture_arena_destroy(arena)
    if arena <= 0
        return 0
    end
    free(arena, 64)
    return 1
end
