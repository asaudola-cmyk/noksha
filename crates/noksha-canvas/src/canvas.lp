// ==============================================================================
// 👑 NOKSHA CANVAS: 2D VECTOR DRAWING ENGINE (crates/noksha-canvas/src/canvas.lp)
// ⚡ 100% Pure Raw LiPi | Declarative Visual Primitives | Zero Driver Overhead
// ==============================================================================
//
// WHY: Modern UI toolkits require high-level visual drawing abstractions (rectangles,
// cards with glassmorphic borders and drop shadows, buttons, circular avatars).
// Noksha Canvas coordinates the Quad Batcher and the Scissor Clip Stack to emit
// zero-overhead instanced draw streams directly into the RHI command buffer.

struct NokshaCanvas
    batcher,
    clip_stack,
    cmd_buf,
    quad_count

// ── 1. Initialize 2D Canvas Context ───────────────────────────────────────────
fn noksha_canvas_create(batcher, clip_stack, cmd_buf)
    canvas = malloc(32) // 4 fields * 8 bytes
    mem_write(canvas, 0, batcher)
    mem_write(canvas, 8, clip_stack)
    mem_write(canvas, 16, cmd_buf)
    mem_write(canvas, 24, 0) // quad_count
    return canvas
end

// ── 2. Clipping Operations ────────────────────────────────────────────────────
fn noksha_canvas_push_clip(canvas, x, y, width, height)
    if canvas <= 0
        return 0
    end
    cs = mem_read(canvas, 8)
    batcher = mem_read(canvas, 0)

    noksha_clip_stack_push(cs, x, y, width, height)
    cx = noksha_clip_stack_top_x(cs)
    cy = noksha_clip_stack_top_y(cs)
    cw = noksha_clip_stack_top_w(cs)
    ch = noksha_clip_stack_top_h(cs)

    noksha_batcher_set_clip(batcher, cx, cy, cw, ch)
    return 1
end

fn noksha_canvas_pop_clip(canvas)
    if canvas <= 0
        return 0
    end
    cs = mem_read(canvas, 8)
    batcher = mem_read(canvas, 0)

    noksha_clip_stack_pop(cs)
    cx = noksha_clip_stack_top_x(cs)
    cy = noksha_clip_stack_top_y(cs)
    cw = noksha_clip_stack_top_w(cs)
    ch = noksha_clip_stack_top_h(cs)

    noksha_batcher_set_clip(batcher, cx, cy, cw, ch)
    return 1
end

// ── 3. High-Level Visual Drawing Primitives ───────────────────────────────────
// Draws a flat solid rectangle
fn noksha_canvas_draw_rect(canvas, x, y, width, height, fill_color)
    if canvas <= 0
        return 0
    end
    batcher = mem_read(canvas, 0)
    noksha_batcher_push_quad(batcher, x, y, width, height, fill_color, 0, 0, 0, 0, 0)
    mem_write(canvas, 24, mem_read(canvas, 24) + 1)
    return 1
end

// Draws a rounded rectangle with corner radius
fn noksha_canvas_draw_rounded_rect(canvas, x, y, width, height, radius, fill_color)
    if canvas <= 0
        return 0
    end
    batcher = mem_read(canvas, 0)
    noksha_batcher_push_quad(batcher, x, y, width, height, fill_color, 0, radius, 0, 0, 0)
    mem_write(canvas, 24, mem_read(canvas, 24) + 1)
    return 1
end

// Draws an interactive button with rounded corners and border
fn noksha_canvas_draw_button(canvas, x, y, width, height, radius, fill_color, border_width, border_color)
    if canvas <= 0
        return 0
    end
    batcher = mem_read(canvas, 0)
    noksha_batcher_push_quad(batcher, x, y, width, height, fill_color, border_color, radius, border_width, 0, 0)
    mem_write(canvas, 24, mem_read(canvas, 24) + 1)
    return 1
end

// Draws a full modern card primitive (with SDF rounded corners, border, and drop shadow)
fn noksha_canvas_draw_card(canvas, x, y, width, height, radius, fill_color, border_width, border_color, shadow_blur, shadow_color)
    if canvas <= 0
        return 0
    end
    batcher = mem_read(canvas, 0)
    noksha_batcher_push_quad(batcher, x, y, width, height, fill_color, border_color, radius, border_width, shadow_blur, shadow_color)
    mem_write(canvas, 24, mem_read(canvas, 24) + 1)
    return 1
end

// ── 4. Flush Batched Quads to RHI Command Buffer ──────────────────────────────
fn noksha_canvas_flush(canvas)
    if canvas <= 0
        return 0
    end
    batcher = mem_read(canvas, 0)
    cmd_buf = mem_read(canvas, 16)

    q_count = noksha_batcher_count(batcher)
    if q_count > 0
        buf_ptr = noksha_batcher_buffer_ptr(batcher)
        // Submit all quads in 1 single command
        noksha_cmd_encode_draw_quads(cmd_buf, buf_ptr, q_count)
        noksha_batcher_reset(batcher)
        mem_write(canvas, 24, 0)
    end

    return q_count
end

fn noksha_canvas_destroy(canvas)
    if canvas > 0
        free(canvas, 32)
    end
    return 1
end
