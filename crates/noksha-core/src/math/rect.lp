// ==============================================================================
// 👑 NOKSHA CORE: 2D BOUNDING RECTANGLE GEOMETRY (crates/noksha-core/src/math/rect.lp)
// ⚡ 100% Pure Raw LiPi | Scissor Clipping | Hit-Testing & Layout Bounding
// ==============================================================================
//
// WHY: In UI rendering, 95% of spatial queries involve axis-aligned bounding boxes (AABBs).
// Rectangles are required for:
// 1. Hardware scissor box clipping (clamping draw areas without stencil passes)
// 2. Hit-testing pointer/touch coordinates against button and card boundaries
// 3. Flexbox/Grid measure and layout position resolution
// Memory Layout: 32 bytes (x: 8, y: 8, width: 8, height: 8)

struct NokshaRect
    x,
    y,
    width,
    height

// ── 1. Rectangle Constructor & Field Accessors ────────────────────────────────
fn noksha_rect_new(x, y, width, height)
    r = malloc(32)
    mem_write(r, 0, x)
    mem_write(r, 8, y)
    mem_write(r, 16, width)
    mem_write(r, 24, height)
    return r
end

fn noksha_rect_set(r, x, y, width, height)
    if r <= 0
        return 0
    end
    mem_write(r, 0, x)
    mem_write(r, 8, y)
    mem_write(r, 16, width)
    mem_write(r, 24, height)
    return r
end

fn noksha_rect_get_x(r)
    if r <= 0
        return 0
    end
    return mem_read(r, 0)
end

fn noksha_rect_get_y(r)
    if r <= 0
        return 0
    end
    return mem_read(r, 8)
end

fn noksha_rect_get_width(r)
    if r <= 0
        return 0
    end
    return mem_read(r, 16)
end

fn noksha_rect_get_height(r)
    if r <= 0
        return 0
    end
    return mem_read(r, 24)
end

// ── 2. Spatial Hit-Testing & Query Operations ─────────────────────────────────
// Checks if point (px, py) is contained inside rectangle r
fn noksha_rect_contains_point(r, px, py)
    if r <= 0
        return 0
    end
    rx = mem_read(r, 0)
    ry = mem_read(r, 8)
    rw = mem_read(r, 16)
    rh = mem_read(r, 24)

    if px >= rx && px <= (rx + rw) && py >= ry && py <= (ry + rh)
        return 1
    end
    return 0
end

// Checks if rectangle a overlaps/intersects with rectangle b
fn noksha_rect_intersects(a, b)
    if a <= 0 || b <= 0
        return 0
    end
    ax = mem_read(a, 0)
    ay = mem_read(a, 8)
    aw = mem_read(a, 16)
    ah = mem_read(a, 24)

    bx = mem_read(b, 0)
    by = mem_read(b, 8)
    bw = mem_read(b, 16)
    bh = mem_read(b, 24)

    if ax + aw <= bx || bx + bw <= ax || ay + ah <= by || by + bh <= ay
        return 0
    end
    return 1
end

// Computes the geometric intersection of rectangles a and b into out_r
// Returns 1 if valid intersection exists, 0 if disjoint
fn noksha_rect_intersect(out_r, a, b)
    if out_r <= 0 || a <= 0 || b <= 0
        return 0
    end

    ax = mem_read(a, 0)
    ay = mem_read(a, 8)
    aw = mem_read(a, 16)
    ah = mem_read(a, 24)

    bx = mem_read(b, 0)
    by = mem_read(b, 8)
    bw = mem_read(b, 16)
    bh = mem_read(b, 24)

    x1 = ax
    if bx > x1
        x1 = bx
    end

    y1 = ay
    if by > y1
        y1 = by
    end

    x2 = ax + aw
    if (bx + bw) < x2
        x2 = bx + bw
    end

    y2 = ay + ah
    if (by + bh) < y2
        y2 = by + bh
    end

    if x2 > x1 && y2 > y1
        mem_write(out_r, 0, x1)
        mem_write(out_r, 8, y1)
        mem_write(out_r, 16, x2 - x1)
        mem_write(out_r, 24, y2 - y1)
        return 1
    end

    // No intersection: zero out result
    mem_write(out_r, 0, 0)
    mem_write(out_r, 8, 0)
    mem_write(out_r, 16, 0)
    mem_write(out_r, 24, 0)
    return 0
end

// Shrinks or expands rectangle by horizontal (dx) and vertical (dy) insets
fn noksha_rect_inset(out_r, r, dx, dy)
    if out_r <= 0 || r <= 0
        return 0
    end
    rx = mem_read(r, 0)
    ry = mem_read(r, 8)
    rw = mem_read(r, 16)
    rh = mem_read(r, 24)

    new_w = rw - (dx * 2)
    new_h = rh - (dy * 2)
    if new_w < 0
        new_w = 0
    end
    if new_h < 0
        new_h = 0
    end

    mem_write(out_r, 0, rx + dx)
    mem_write(out_r, 8, ry + dy)
    mem_write(out_r, 16, new_w)
    mem_write(out_r, 24, new_h)
    return out_r
end

fn noksha_rect_destroy(r)
    if r > 0
        free(r, 32)
    end
    return 1
end
