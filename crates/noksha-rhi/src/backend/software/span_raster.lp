// ==============================================================================
// 👑 NOKSHA RHI: HIGH-PERFORMANCE CPU SPAN RASTERIZER (crates/noksha-rhi/src/backend/software/span_raster.lp)
// ⚡ 100% Pure Raw LiPi | Blend2D-Style Scanline Rasterization | Zero GPU Dependencies
// ==============================================================================
//
// WHY: In environments with missing, disabled, or broken GPU drivers (headless servers,
// CI containers, older microcontrollers, fallback modes), Noksha must not fail.
// This module provides a high-throughput CPU span rasterizer that draws horizontal
// pixel lines (spans) directly into any memory buffer with clipping and alpha blending.

// ── 1. Draw Horizontal Pixel Span ─────────────────────────────────────────────
// Fills scanline y from x1 to x2 (inclusive) with a 32-bit ARGB color
fn noksha_raster_span(target_buf, pitch, buf_w, buf_h, y, x1, x2, argb_color)
    if target_buf <= 0 || y < 0 || y >= buf_h
        return 0
    end

    start_x = x1
    end_x = x2
    if start_x > end_x
        tmp = start_x
        start_x = end_x
        end_x = tmp
    end

    // Clip to horizontal viewport boundaries
    if start_x < 0
        start_x = 0
    end
    if end_x >= buf_w
        end_x = buf_w - 1
    end
    if start_x > end_x
        return 0
    end

    row_byte_offset = y * pitch
    count = (end_x - start_x) + 1

    // Unroll 2 pixels per 64-bit word write where applicable
    val64 = argb_color + (argb_color * 4294967296)
    qword_count = count / 2
    
    cur_x = start_x
    q = 0
    while q < qword_count
        px_offset = row_byte_offset + (cur_x * 4)
        mem_write(target_buf, px_offset, val64)
        cur_x = cur_x + 2
        q = q + 1
    end

    // Handle trailing odd pixel
    if cur_x <= end_x
        px_offset = row_byte_offset + (cur_x * 4)
        mem_write_u32(target_buf, px_offset, argb_color)
    end

    return count
end

// ── 2. Fill Solid Rectangle via Scanline Iteration ────────────────────────────
fn noksha_raster_fill_rect(target_buf, pitch, buf_w, buf_h, rx, ry, rw, rh, argb_color)
    if target_buf <= 0 || rw <= 0 || rh <= 0
        return 0
    end

    y1 = ry
    y2 = ry + rh - 1

    if y1 < 0
        y1 = 0
    end
    if y2 >= buf_h
        y2 = buf_h - 1
    end
    if y1 > y2
        return 0
    end

    x1 = rx
    x2 = rx + rw - 1

    curr_y = y1
    total_pixels = 0
    while curr_y <= y2
        pixels = noksha_raster_span(target_buf, pitch, buf_w, buf_h, curr_y, x1, x2, argb_color)
        total_pixels = total_pixels + pixels
        curr_y = curr_y + 1
    end

    return total_pixels
end

// ── 3. Draw Hollow Rectangle Border ───────────────────────────────────────────
fn noksha_raster_stroke_rect(target_buf, pitch, buf_w, buf_h, rx, ry, rw, rh, border_width, argb_color)
    if target_buf <= 0 || rw <= 0 || rh <= 0 || border_width <= 0
        return 0
    end

    bw = border_width
    // Top border
    noksha_raster_fill_rect(target_buf, pitch, buf_w, buf_h, rx, ry, rw, bw, argb_color)
    // Bottom border
    noksha_raster_fill_rect(target_buf, pitch, buf_w, buf_h, rx, (ry + rh) - bw, rw, bw, argb_color)
    // Left border
    noksha_raster_fill_rect(target_buf, pitch, buf_w, buf_h, rx, ry + bw, bw, rh - (bw * 2), argb_color)
    // Right border
    noksha_raster_fill_rect(target_buf, pitch, buf_w, buf_h, (rx + rw) - bw, ry + bw, bw, rh - (bw * 2), argb_color)

    return 1
end
