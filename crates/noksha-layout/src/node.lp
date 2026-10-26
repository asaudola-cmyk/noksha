// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Package: noksha-layout
// Module: node
// Purpose: Hierarchical scene graph layout node representation.
//
// WHY: In modern retained UI engines, scene hierarchy is represented by parent-child
// node trees. Each node stores its styling constraints and memoizes its computed
// spatial dimensions (computed_x, computed_y, computed_w, computed_h) to prevent
// redundant recalculations across animation frames.

struct NokshaLayoutNode
    id,
    style_ptr,
    children_capacity,
    children_count,
    children_arr,       // Pointer to array of child node pointers (8B each)
    computed_x,
    computed_y,
    computed_w,
    computed_h,
    parent_ptr,
    is_dirty

// ── 1. Create Layout Node ─────────────────────────────────────────────────────
fn noksha_node_create(node_id, style_ptr)
    init_cap = 16 // Initial child capacity
    child_mem = malloc(init_cap * 8)
    if child_mem <= 0
        return 0
    end

    node = malloc(88) // 11 fields * 8 bytes
    mem_write(node, 0, node_id)
    mem_write(node, 8, style_ptr)
    mem_write(node, 16, init_cap)
    mem_write(node, 24, 0) // count = 0
    mem_write(node, 32, child_mem)
    mem_write(node, 40, 0) // computed_x = 0
    mem_write(node, 48, 0) // computed_y = 0
    mem_write(node, 56, 0) // computed_w = 0
    mem_write(node, 64, 0) // computed_h = 0
    mem_write(node, 72, 0) // parent_ptr = 0
    mem_write(node, 80, 1) // is_dirty = 1

    return node
end

// ── 2. Add Child to Layout Node ───────────────────────────────────────────────
fn noksha_node_add_child(parent, child)
    if parent <= 0 || child <= 0
        return 0
    end

    cap = mem_read(parent, 16)
    count = mem_read(parent, 24)
    child_arr = mem_read(parent, 32)

    if count >= cap
        // Grow child array capacity by 2x
        new_cap = cap * 2
        new_arr = malloc(new_cap * 8)
        
        // Copy existing child pointers
        c_idx = 0
        while c_idx < count
            mem_write(new_arr, c_idx * 8, mem_read(child_arr, c_idx * 8))
            c_idx = c_idx + 1
        end

        free(child_arr, cap * 8)
        mem_write(parent, 16, new_cap)
        mem_write(parent, 32, new_arr)
        child_arr = new_arr
    end

    // Store child pointer
    mem_write(child_arr, count * 8, child)
    mem_write(parent, 24, count + 1)

    // Set parent pointer on child
    mem_write(child, 72, parent)

    // Mark parent dirty
    mem_write(parent, 80, 1)
    return 1
end

// ── 3. Query Node Hierarchy and Computed Dimensions ───────────────────────────
fn noksha_node_get_child(node, index)
    if node <= 0
        return 0
    end
    count = mem_read(node, 24)
    if index < 0 || index >= count
        return 0
    end
    child_arr = mem_read(node, 32)
    return mem_read(child_arr, index * 8)
end

fn noksha_node_children_count(node)
    if node <= 0
        return 0
    end
    return mem_read(node, 24)
end

fn noksha_node_get_style(node)
    if node <= 0
        return 0
    end
    return mem_read(node, 8)
end

fn noksha_node_set_computed(node, x, y, width, height)
    if node <= 0
        return 0
    end
    mem_write(node, 40, x)
    mem_write(node, 48, y)
    mem_write(node, 56, width)
    mem_write(node, 64, height)
    mem_write(node, 80, 0) // is_dirty = 0
    return 1
end

fn noksha_node_get_x(node)
    if node <= 0
        return 0
    end
    return mem_read(node, 40)
end

fn noksha_node_get_y(node)
    if node <= 0
        return 0
    end
    return mem_read(node, 48)
end

fn noksha_node_get_w(node)
    if node <= 0
        return 0
    end
    return mem_read(node, 56)
end

fn noksha_node_get_h(node)
    if node <= 0
        return 0
    end
    return mem_read(node, 64)
end

fn noksha_node_destroy(node)
    if node <= 0
        return 0
    end
    cap = mem_read(node, 16)
    child_arr = mem_read(node, 32)
    if child_arr > 0
        free(child_arr, cap * 8)
    end
    free(node, 88)
    return 1
end
