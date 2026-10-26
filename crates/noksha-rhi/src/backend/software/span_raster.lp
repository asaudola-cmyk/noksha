// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Package: noksha-rhi
// Module: backend/software/span_raster
// Purpose: High-throughput CPU horizontal scanline rasterizer with Porter-Duff alpha blending.
//
// WHY: In environments with missing, disabled, or broken GPU drivers (headless servers,
// CI containers, older microcontrollers, fallback modes), Noksha must not fail.
// This module provides a high-throughput CPU span rasterizer that draws horizontal
// pixel lines (spans) directly into any memory buffer with clipping, Porter-Duff Source-Over
// alpha blending, and analytical rounded rectangle anti-clipping.

// ── 0. Integer Square Root Helper for Analytical Corner Clipping ──────────────
fn noksha_math_isqrt(n)
    if n <= 0
        return 0
    end
    if n < 4
        return 1
    end
    x0 = n / 2
    x1 = (x0 + (n / x0)) / 2
    while x1 < x0
        x0 = x1
        x1 = (x0 + (n / x0)) / 2
    end
    return x0
end

// ── 1. Porter-Duff Source-Over Alpha Blending for ARGB32 Framebuffers ─────────
fn noksha_blend_argb_over(fg, bg)
    fg_a = (fg / 16777216) % 256
    if fg_a == 255
        // Fully opaque foreground completely covers background
        return fg
    end
    if fg_a == 0
        // Fully transparent foreground reveals background unmodified
        return bg
    end

    fg_r = (fg / 65536) % 256
    fg_g = (fg / 256) % 256
    fg_b = fg % 256

    bg_a = (bg / 16777216) % 256
    bg_r = (bg / 65536) % 256
    bg_g = (bg / 256) % 256
    bg_b = bg % 256

    inv_a = 255 - fg_a

    out_r = ((fg_r * fg_a) + (bg_r * inv_a)) / 255
    out_g = ((fg_g * fg_a) + (bg_g * inv_a)) / 255
    out_b = ((fg_b * fg_a) + (bg_b * inv_a)) / 255
    out_a = fg_a + ((bg_a * inv_a) / 255)
    if out_a > 255
        out_a = 255
    end

    return (out_a * 16777216) + (out_r * 65536) + (out_g * 256) + out_b
end

// ── 2. Draw Horizontal Pixel Span with Alpha Blending ─────────────────────────
// Fills scanline y from x1 to x2 (inclusive) with a 32-bit ARGB color
fn noksha_raster_span(target_buf, pitch, buf_w, buf_h, y, x1, x2, argb_color)
    if target_buf <= 0 || y < 0 || y >= buf_h
        return 0
    end

    fg_a = (argb_color / 16777216) % 256
    if fg_a == 0
        return 0 // Completely transparent, no-op
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

    // Fast-path: Fully opaque color (alpha == 255)
    if fg_a == 255
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

        // Trailing odd pixel
        if cur_x <= end_x
            px_offset = row_byte_offset + (cur_x * 4)
            mem_write_u32(target_buf, px_offset, argb_color)
        end

        return count
    end

    // Blended path: Semi-transparent color (1 <= alpha < 255)
    cur_x = start_x
    while cur_x <= end_x
        px_offset = row_byte_offset + (cur_x * 4)
        bg_pixel = mem_read_u32(target_buf, px_offset)
        blended = noksha_blend_argb_over(argb_color, bg_pixel)
        mem_write_u32(target_buf, px_offset, blended)
        cur_x = cur_x + 1
    end

    return count
end

// ── 3. Fill Solid Rectangle via Scanline Iteration ────────────────────────────
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

// ── 4. Fill Rounded Rectangle with Corner Radius ──────────────────────────────
fn noksha_raster_fill_rounded_rect(target_buf, pitch, buf_w, buf_h, rx, ry, rw, rh, radius, argb_color)
    if target_buf <= 0 || rw <= 0 || rh <= 0
        return 0
    end

    rad = radius
    max_rad = rw / 2
    if rh / 2 < max_rad
        max_rad = rh / 2
    end
    if rad > max_rad
        rad = max_rad
    end
    if rad <= 0
        return noksha_raster_fill_rect(target_buf, pitch, buf_w, buf_h, rx, ry, rw, rh, argb_color)
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

    rad_sq = rad * rad
    curr_y = y1
    total_pixels = 0

    while curr_y <= y2
        inset = 0
        // Top rounded region
        if curr_y < (ry + rad)
            dy = (ry + rad) - curr_y
            dy_sq = dy * dy
            if dy_sq < rad_sq
                dx = noksha_math_isqrt(rad_sq - dy_sq)
                inset = rad - dx
            end
        end
        // Bottom rounded region
        if curr_y >= (ry + rh - rad)
            dy = curr_y - (ry + rh - rad - 1)
            dy_sq = dy * dy
            if dy_sq < rad_sq
                dx = noksha_math_isqrt(rad_sq - dy_sq)
                inset = rad - dx
            end
        end

        x1 = rx + inset
        x2 = (rx + rw - 1) - inset
        if x2 >= x1
            pixels = noksha_raster_span(target_buf, pitch, buf_w, buf_h, curr_y, x1, x2, argb_color)
            total_pixels = total_pixels + pixels
        end

        curr_y = curr_y + 1
    end

    return total_pixels
end

// ── 5. Draw Hollow Rectangle Border with Boundary Safety ──────────────────────
fn noksha_raster_stroke_rect(target_buf, pitch, buf_w, buf_h, rx, ry, rw, rh, border_width, argb_color)
    if target_buf <= 0 || rw <= 0 || rh <= 0 || border_width <= 0
        return 0
    end

    bw = border_width
    // If dimensions cannot accommodate borders without inversion, fill solid
    if rw <= (bw * 2) || rh <= (bw * 2)
        return noksha_raster_fill_rect(target_buf, pitch, buf_w, buf_h, rx, ry, rw, rh, argb_color)
    end

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
