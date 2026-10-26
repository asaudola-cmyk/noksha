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
    font_size

// ── 1. Component Constructors ─────────────────────────────────────────────────
fn noksha_view_create_container(id, layout_node, bg_color)
    v = malloc(96) // 12 fields * 8 bytes
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
    return v
end

fn noksha_view_create_card(id, layout_node, bg_color, corner_radius, border_width, border_color, shadow_blur, shadow_color)
    v = malloc(96)
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
    return v
end

fn noksha_view_create_button(id, layout_node, text_str, bg_color, corner_radius, text_color)
    v = malloc(96)
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
    return v
end

// ── 2. Recursive Render Pipeline ──────────────────────────────────────────────
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

    // Render Button
    if v_type == 3
        noksha_canvas_draw_button(canvas, vx, vy, vw, vh, radius, bg_col, border_w, border_col)
    end

    return 1
end

fn noksha_view_destroy(v)
    if v > 0
        free(v, 96)
    end
    return 1
end
