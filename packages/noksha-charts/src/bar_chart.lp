// =============================================================================
// Noksha Charts: Custom High-Performance GPU Bar Chart Widget
// Package: noksha-charts
// Language: 100% Pure Raw LiPi (Zero aati dependencies)
// =============================================================================

import "../../crates/noksha-core/src/lib.lp"
import "../../crates/noksha-canvas/src/lib.lp"

struct NokshaBarChart
    data_values,
    data_count,
    max_value,
    bar_color,
    baseline_color,
    gap

// In-place initializer for Arena-allocated memory
fn noksha_bar_chart_init(c, values, count, max_val, color)
    if c <= 0 || values <= 0 || count <= 0
        return 0
    end

    mem_write(c, 0, values)
    mem_write(c, 8, count)
    if max_val <= 0
        mem_write(c, 16, 100)
    else
        mem_write(c, 16, max_val)
    end
    mem_write(c, 24, color)
    mem_write(c, 32, noksha_color_rgba(71, 85, 105, 120))
    mem_write(c, 40, 8) // default 8px gap
    return c
end

// Standalone Heap Allocator
fn noksha_bar_chart_create(values, count, max_val, color)
    if values <= 0 || count <= 0
        return 0
    end

    c = malloc(48)
    return noksha_bar_chart_init(c, values, count, max_val, color)
end

// Measure pass: Negotiates minimum dimensions with layout system
fn noksha_bar_chart_measure(chart, min_bar_w, out_size)
    if chart <= 0 || out_size <= 0
        return 0
    end

    count = mem_read(chart, 8)
    gap = mem_read(chart, 40)
    total_w = (count * min_bar_w) + ((count - 1) * gap) + 32
    total_h = 200

    mem_write(out_size, 0, total_w)
    mem_write(out_size, 8, total_h)
    return 1
end

// Draw pass: Emits batched GPU quads into Noksha's canvas
fn noksha_bar_chart_draw(chart, canvas, x, y, w, h)
    if chart <= 0 || canvas <= 0 || w <= 0 || h <= 0
        return 0
    end

    baseline_color = mem_read(chart, 32)
    bar_color = mem_read(chart, 24)
    count = mem_read(chart, 8)
    gap = mem_read(chart, 40)
    max_val = mem_read(chart, 16)
    values = mem_read(chart, 0)

    // 1. Draw chart baseline axis
    baseline_y = y + h - 16
    noksha_canvas_draw_rect(canvas, x, baseline_y, w, 2, baseline_color)

    if count <= 0
        return 1
    end

    // 2. Compute bar widths
    total_gap = (count - 1) * gap
    usable_w = w - 32
    if usable_w <= total_gap
        return 1
    end
    bar_w = (usable_w - total_gap) / count
    max_chart_h = h - 36

    // 3. Batch render each bar
    i = 0
    curr_x = x + 16
    while i < count
        val = mem_read(values, i * 8)
        
        // Normalize bar height
        bar_h = (val * max_chart_h) / max_val
        if bar_h < 4
            bar_h = 4
        end

        bar_y = baseline_y - bar_h

        // Render rounded bar with top corner curvature
        noksha_canvas_draw_rounded_rect(canvas, curr_x, bar_y, bar_w, bar_h, 4, bar_color)

        curr_x = curr_x + bar_w + gap
        i = i + 1
    end

    return count + 1
end

fn noksha_bar_chart_destroy(chart)
    if chart > 0
        free(chart, 48)
    end
    return 1
end
