// ==============================================================================
// 👑 NOKSHA LAYOUT: STYLE DEFINITIONS (crates/noksha-layout/src/style.lp)
// ⚡ 100% Pure Raw LiPi | W3C Flexbox Level 1 & CSS Grid | Zero Dependencies
// ==============================================================================
//
// WHY: Declarative layouts require structured style specifications for flex directions,
// cross-axis alignment, spacing, padding, margins, and dimension constraints.
// Memory Layout of NokshaStyle (160 bytes = 20 * 8B):
// [0]: display,        [8]: flex_direction,  [16]: align_items,    [24]: justify_content
// [32]: width,         [40]: height,         [48]: min_w,          [56]: min_h
// [64]: max_w,         [72]: max_h,          [80]: pad_l,          [88]: pad_t
// [96]: pad_r,         [104]: pad_b,         [112]: mar_l,         [120]: mar_t
// [128]: mar_r,        [136]: mar_b,         [144]: gap,           [152]: flex_grow

struct NokshaStyle
    display,
    flex_direction,
    align_items,
    justify_content,
    width,
    height,
    min_w,
    min_h,
    max_w,
    max_h,
    pad_l,
    pad_t,
    pad_r,
    pad_b,
    mar_l,
    mar_t,
    mar_r,
    mar_b,
    gap,
    flex_grow

// ── 1. Style Constants ────────────────────────────────────────────────────────
// Display
fn noksha_display_flex()
    return 0
end
fn noksha_display_grid()
    return 1
end
fn noksha_display_none()
    return 2
end

// FlexDirection
fn noksha_flex_row()
    return 0
end
fn noksha_flex_col()
    return 1
end

// AlignItems
fn noksha_align_start()
    return 0
end
fn noksha_align_center()
    return 1
end
fn noksha_align_end()
    return 2
end
fn noksha_align_stretch()
    return 3
end

// JustifyContent
fn noksha_justify_start()
    return 0
end
fn noksha_justify_center()
    return 1
end
fn noksha_justify_end()
    return 2
end
fn noksha_justify_space_between()
    return 3
end

// Auto dimension sentinel value: -1 means "auto / intrinsic sizing"
fn noksha_auto_size()
    return -1
end

// ── 2. Create Default Style ───────────────────────────────────────────────────
fn noksha_style_create()
    s = malloc(160) // 20 * 8 bytes
    if s <= 0
        return 0
    end

    mem_write(s, 0, noksha_display_flex())
    mem_write(s, 8, noksha_flex_row())
    mem_write(s, 16, noksha_align_stretch())
    mem_write(s, 24, noksha_justify_start())
    mem_write(s, 32, -1)   // width: auto
    mem_write(s, 40, -1)   // height: auto
    mem_write(s, 48, 0)    // min_w: 0
    mem_write(s, 56, 0)    // min_h: 0
    mem_write(s, 64, 65535)// max_w: 65535
    mem_write(s, 72, 65535)// max_h: 65535
    mem_write(s, 80, 0)    // pad_l
    mem_write(s, 88, 0)    // pad_t
    mem_write(s, 96, 0)    // pad_r
    mem_write(s, 104, 0)   // pad_b
    mem_write(s, 112, 0)   // mar_l
    mem_write(s, 120, 0)   // mar_t
    mem_write(s, 128, 0)   // mar_r
    mem_write(s, 136, 0)   // mar_b
    mem_write(s, 144, 0)   // gap: 0
    mem_write(s, 152, 0)   // flex_grow: 0

    return s
end

fn noksha_style_set_size(s, width, height)
    if s <= 0
        return 0
    end
    mem_write(s, 32, width)
    mem_write(s, 40, height)
    return s
end

fn noksha_style_set_padding(s, l, t, r, b)
    if s <= 0
        return 0
    end
    mem_write(s, 80, l)
    mem_write(s, 88, t)
    mem_write(s, 96, r)
    mem_write(s, 104, b)
    return s
end

fn noksha_style_set_direction(s, flex_dir)
    if s <= 0
        return 0
    end
    mem_write(s, 8, flex_dir)
    return s
end

fn noksha_style_set_alignment(s, align, justify)
    if s <= 0
        return 0
    end
    mem_write(s, 16, align)
    mem_write(s, 24, justify)
    return s
end

fn noksha_style_set_gap(s, gap_px)
    if s <= 0
        return 0
    end
    mem_write(s, 144, gap_px)
    return s
end

fn noksha_style_set_flex_grow(s, grow)
    if s <= 0
        return 0
    end
    mem_write(s, 152, grow)
    return s
end

fn noksha_style_destroy(s)
    if s > 0
        free(s, 160)
    end
    return 1
end
