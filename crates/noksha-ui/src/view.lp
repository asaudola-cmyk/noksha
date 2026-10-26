// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Package: noksha-ui
// Module: view
// Purpose: Declarative UI component tree rendering cards, containers, buttons, and text.
//
// WHY: Modern frontend architectures require composing clean, declarative UI components
// (cards, containers, buttons, labels) that automatically bind their visual representation
// to the computed flexbox layout without manual coordinate math.
// Noksha View connects the Layout Node with the Canvas2D batcher to render complex
// glassmorphic cards, buttons, and text in single-pass GPU batches.

struct NokshaView
    id,
    layout_node,
    view_type,          // 1: Container, 2: Card, 3: Button, 4: Text
    bg_color,
    border_color,
    corner_radius,
    border_width,
    shadow_blur,
    shadow_color,
    text_content,
    text_color,
    font_size,
    children_capacity,
    children_count,
    children_arr,       // Pointer to array of child view pointers (8B each)
    parent_view

// ── 1. Component Constructors ─────────────────────────────────────────────────
fn noksha_view_create_container(id, layout_node, bg_color)
    v = malloc(128) // 16 fields * 8 bytes
    mem_write(v, 0, id)
    mem_write(v, 8, layout_node)
    mem_write(v, 16, 1) // Type: Container
    mem_write(v, 24, bg_color)
    mem_write(v, 32, 0) // border_color = 0
    mem_write(v, 40, 0) // corner_radius = 0
    mem_write(v, 48, 0) // border_width = 0
    mem_write(v, 56, 0) // shadow_blur = 0
    mem_write(v, 64, 0) // shadow_color = 0
    mem_write(v, 72, 0) // text_content = 0
    mem_write(v, 80, 0) // text_color = 0
    mem_write(v, 88, 16)// default font_size = 16

    init_cap = 8
    child_mem = malloc(init_cap * 8)
    mem_write(v, 96, init_cap)
    mem_write(v, 104, 0)
    mem_write(v, 112, child_mem)
    mem_write(v, 120, 0)
    return v
end

fn noksha_view_create_card(id, layout_node, bg_color, corner_radius, border_width, border_color, shadow_blur, shadow_color)
    v = malloc(128)
    mem_write(v, 0, id)
    mem_write(v, 8, layout_node)
    mem_write(v, 16, 2) // Type: Card
    mem_write(v, 24, bg_color)
    mem_write(v, 32, border_color)
    mem_write(v, 40, corner_radius)
    mem_write(v, 48, border_width)
    mem_write(v, 56, shadow_blur)
    mem_write(v, 64, shadow_color)
    mem_write(v, 72, 0)
    mem_write(v, 80, 0)
    mem_write(v, 88, 16)

    init_cap = 8
    child_mem = malloc(init_cap * 8)
    mem_write(v, 96, init_cap)
    mem_write(v, 104, 0)
    mem_write(v, 112, child_mem)
    mem_write(v, 120, 0)
    return v
end

fn noksha_view_create_button(id, layout_node, text_str, bg_color, corner_radius, text_color)
    v = malloc(128)
    mem_write(v, 0, id)
    mem_write(v, 8, layout_node)
    mem_write(v, 16, 3) // Type: Button
    mem_write(v, 24, bg_color)
    mem_write(v, 32, 0) // default border_color
    mem_write(v, 40, corner_radius)
    mem_write(v, 48, 1) // default border_width = 1
    mem_write(v, 56, 0)
    mem_write(v, 64, 0)
    mem_write(v, 72, text_str)
    mem_write(v, 80, text_color)
    mem_write(v, 88, 14)

    init_cap = 8
    child_mem = malloc(init_cap * 8)
    mem_write(v, 96, init_cap)
    mem_write(v, 104, 0)
    mem_write(v, 112, child_mem)
    mem_write(v, 120, 0)
    return v
end

fn noksha_view_create_text(id, layout_node, text_str, font_size, text_color)
    v = malloc(128)
    mem_write(v, 0, id)
    mem_write(v, 8, layout_node)
    mem_write(v, 16, 4) // Type: Text
    mem_write(v, 24, 0) // bg_color = 0
    mem_write(v, 32, 0)
    mem_write(v, 40, 0)
    mem_write(v, 48, 0)
    mem_write(v, 56, 0)
    mem_write(v, 64, 0)
    mem_write(v, 72, text_str)
    mem_write(v, 80, text_color)
    mem_write(v, 88, font_size)

    init_cap = 8
    child_mem = malloc(init_cap * 8)
    mem_write(v, 96, init_cap)
    mem_write(v, 104, 0)
    mem_write(v, 112, child_mem)
    mem_write(v, 120, 0)
    return v
end

// ── 2. View Hierarchy Methods ─────────────────────────────────────────────────
fn noksha_view_grow_children(v)
    if v <= 0
        return 0
    end
    cap = mem_read(v, 96)
    count = mem_read(v, 104)
    arr = mem_read(v, 112)

    new_cap = cap * 2
    new_arr = malloc(new_cap * 8)
    if new_arr <= 0
        return 0
    end

    c_idx = 0
    while c_idx < count
        mem_write(new_arr, c_idx * 8, mem_read(arr, c_idx * 8))
        c_idx = c_idx + 1
    end

    free(arr, cap * 8)
    mem_write(v, 96, new_cap)
    mem_write(v, 112, new_arr)
    return new_arr
end

fn noksha_view_add_child(parent, child)
    if parent <= 0 || child <= 0
        return 0
    end

    cap = mem_read(parent, 96)
    count = mem_read(parent, 104)

    if count >= cap
        noksha_view_grow_children(parent)
    end

    arr = mem_read(parent, 112)
    mem_write(arr, count * 8, child)
    mem_write(parent, 104, count + 1)
    mem_write(child, 120, parent)
    return 1
end

fn noksha_view_children_count(view)
    if view <= 0
        return 0
    end
    return mem_read(view, 104)
end

fn noksha_view_get_child(view, index)
    if view <= 0
        return 0
    end
    count = mem_read(view, 104)
    if index < 0 || index >= count
        return 0
    end
    arr = mem_read(view, 112)
    return mem_read(arr, index * 8)
end

// ── 3. Render Pipeline ────────────────────────────────────────────────────────
// Reads computed layout coordinates and records draw commands into Canvas batcher
fn noksha_view_render(view, canvas)
    if view <= 0 || canvas <= 0
        return 0
    end

    node = mem_read(view, 8)
    if node <= 0
        return 0
    end

    vx = noksha_node_get_x(node)
    vy = noksha_node_get_y(node)
    vw = noksha_node_get_w(node)
    vh = noksha_node_get_h(node)

    v_type = mem_read(view, 16)
    bg_col = mem_read(view, 24)
    border_col = mem_read(view, 32)
    radius = mem_read(view, 40)
    border_w = mem_read(view, 48)
    shadow_b = mem_read(view, 56)
    shadow_c = mem_read(view, 64)

    // Render Container
    if v_type == 1 && bg_col > 0
        noksha_canvas_draw_rect(canvas, vx, vy, vw, vh, bg_col)
    end

    // Render Card (Glassmorphic SDF rounded rect + border + shadow)
    if v_type == 2
        noksha_canvas_draw_card(canvas, vx, vy, vw, vh, radius, bg_col, border_w, border_col, shadow_b, shadow_c)
    end

    // Render Button (Button background + shaped label text)
    if v_type == 3
        noksha_canvas_draw_button(canvas, vx, vy, vw, vh, radius, bg_col, border_w, border_col)
        text_str = mem_read(view, 72)
        text_col = mem_read(view, 80)
        f_size = mem_read(view, 88)
        if text_str != 0
            s_len = length(text_str)
            if s_len > 0
                run = noksha_glyph_run_create(s_len * 2)
                char_w = (f_size * 6) / 10
                if char_w <= 0
                    char_w = 8
                end
                sc = noksha_shape_text(run, text_str, f_size, char_w)
                total_w = noksha_glyph_run_advance(run)

                // Center label inside button
                label_x = vx
                if vw > total_w
                    label_x = vx + ((vw - total_w) / 2)
                end
                label_y = vy
                if vh > f_size
                    label_y = vy + ((vh - f_size) / 2)
                end

                g_idx = 0
                while g_idx < sc
                    gx = noksha_glyph_run_get_x(run, g_idx)
                    gy = noksha_glyph_run_get_y(run, g_idx)
                    noksha_canvas_draw_rect(canvas, label_x + gx, label_y + gy, char_w, f_size, text_col)
                    g_idx = g_idx + 1
                end
                noksha_glyph_run_destroy(run)
            end
        end
    end

    // Render Text View
    if v_type == 4
        text_str = mem_read(view, 72)
        text_col = mem_read(view, 80)
        f_size = mem_read(view, 88)
        if text_str != 0
            s_len = length(text_str)
            if s_len > 0
                run = noksha_glyph_run_create(s_len * 2)
                char_w = (f_size * 6) / 10
                if char_w <= 0
                    char_w = 8
                end
                sc = noksha_shape_text(run, text_str, f_size, char_w)
                g_idx = 0
                while g_idx < sc
                    gx = noksha_glyph_run_get_x(run, g_idx)
                    gy = noksha_glyph_run_get_y(run, g_idx)
                    noksha_canvas_draw_rect(canvas, vx + gx, vy + gy, char_w, f_size, text_col)
                    g_idx = g_idx + 1
                end
                noksha_glyph_run_destroy(run)
            end
        end
    end

    return 1
end

// ── 4. Recursive View Tree Renderer ───────────────────────────────────────────
fn noksha_view_render_tree(view, canvas)
    if view <= 0 || canvas <= 0
        return 0
    end

    // 1. Render self
    noksha_view_render(view, canvas)

    // 2. Recursively render all children in order
    child_count = noksha_view_children_count(view)
    c_idx = 0
    while c_idx < child_count
        child_v = noksha_view_get_child(view, c_idx)
        if child_v > 0
            noksha_view_render_tree(child_v, canvas)
        end
        c_idx = c_idx + 1
    end

    return 1
end

fn noksha_view_destroy(v)
    if v <= 0
        return 0
    end
    arr = mem_read(v, 112)
    cap = mem_read(v, 96)
    if arr > 0
        free(arr, cap * 8)
    end
    free(v, 128)
    return 1
end
