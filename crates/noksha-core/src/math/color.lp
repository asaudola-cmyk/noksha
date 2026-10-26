// ==============================================================================
// 👑 NOKSHA CORE: COLOR REPRESENTATION & BLENDING (crates/noksha-core/src/math/color.lp)
// ⚡ 100% Pure Raw LiPi | Porter-Duff Alpha Compositing | Packed RGBA & ARGB
// ==============================================================================
//
// WHY: Modern UI graphics pipelines require color representations that can both:
// 1. Pack into single 32-bit integers for hardware framebuffers and vertex buffers
// 2. Perform accurate linear-space alpha blending (Porter-Duff Over) without clipping artifacts
// 3. Support dynamic theming, opacity transitions, and glassmorphic blurs

struct NokshaColor
    r,
    g,
    b,
    a

// ── 1. Color Constructors ─────────────────────────────────────────────────────
// Allocates a 32-byte Color struct (r: 8, g: 8, b: 8, a: 8, values 0-255)
fn noksha_color_new(r, g, b, a)
    c = malloc(32)
    mem_write(c, 0, r & 255)
    mem_write(c, 8, g & 255)
    mem_write(c, 16, b & 255)
    mem_write(c, 24, a & 255)
    return c
end

// Packs 4 channels (0-255) into a 32-bit integer (RGBA: A in high byte, B in low byte)
fn noksha_color_pack_rgba(r, g, b, a)
    r_val = r & 255
    g_val = g & 255
    b_val = b & 255
    a_val = a & 255
    return (a_val * 16777216) + (b_val * 65536) + (g_val * 256) + r_val
end

// Packs into ARGB standard for direct Linux DRM/KMS Dumb Framebuffer
fn noksha_color_pack_argb(r, g, b, a)
    r_val = r & 255
    g_val = g & 255
    b_val = b & 255
    a_val = a & 255
    return (a_val * 16777216) + (r_val * 65536) + (g_val * 256) + b_val
end

// Convenient aliases for packing color channels
fn noksha_color_rgba(r, g, b, a)
    return noksha_color_pack_rgba(r, g, b, a)
end

fn noksha_color_argb(r, g, b, a)
    return noksha_color_pack_argb(r, g, b, a)
end

// Unpacks 32-bit RGBA into a Color struct
fn noksha_color_unpack_rgba(out_c, packed_val)
    if out_c <= 0
        return 0
    end
    r = packed_val % 256
    g = (packed_val / 256) % 256
    b = (packed_val / 65536) % 256
    a = (packed_val / 16777216) % 256

    mem_write(out_c, 0, r)
    mem_write(out_c, 8, g)
    mem_write(out_c, 16, b)
    mem_write(out_c, 24, a)
    return out_c
end

// ── 2. Color Modification & Transition Operations ─────────────────────────────
// Returns a new packed color with overridden alpha value (0-255)
fn noksha_color_with_alpha(packed_val, new_alpha)
    rgb = packed_val & 16777215 // Clear upper 8 bits
    a_val = new_alpha & 255
    return (a_val * 16777216) + rgb
end

// Linear interpolation between two packed colors: factor from 0 to 100
fn noksha_color_lerp(c1_packed, c2_packed, factor_percent)
    f = factor_percent
    if f < 0
        f = 0
    end
    if f > 100
        f = 100
    end
    inv_f = 100 - f

    r1 = c1_packed % 256
    g1 = (c1_packed / 256) % 256
    b1 = (c1_packed / 65536) % 256
    a1 = (c1_packed / 16777216) % 256

    r2 = c2_packed % 256
    g2 = (c2_packed / 256) % 256
    b2 = (c2_packed / 65536) % 256
    a2 = (c2_packed / 16777216) % 256

    r_out = ((r1 * inv_f) + (r2 * f)) / 100
    g_out = ((g1 * inv_f) + (g2 * f)) / 100
    b_out = ((b1 * inv_f) + (b2 * f)) / 100
    a_out = ((a1 * inv_f) + (a2 * f)) / 100

    return noksha_color_pack_rgba(r_out, g_out, b_out, a_out)
end

// Porter-Duff Source-Over Alpha Blending
// Blends foreground color over background color: out = fg + bg * (1 - fg_alpha)
fn noksha_color_blend_over(fg_packed, bg_packed)
    fg_a = (fg_packed / 16777216) % 256
    if fg_a == 255
        // Fully opaque foreground completely covers background
        return fg_packed
    end
    if fg_a == 0
        // Fully transparent foreground reveals background unmodified
        return bg_packed
    end

    fg_r = fg_packed % 256
    fg_g = (fg_packed / 256) % 256
    fg_b = (fg_packed / 65536) % 256

    bg_r = bg_packed % 256
    bg_g = (bg_packed / 256) % 256
    bg_b = (bg_packed / 65536) % 256
    bg_a = (bg_packed / 16777216) % 256

    inv_a = 255 - fg_a

    out_r = (fg_r * fg_a + bg_r * inv_a) / 255
    out_g = (fg_g * fg_a + bg_g * inv_a) / 255
    out_b = (fg_b * fg_a + bg_b * inv_a) / 255
    out_a = fg_a + (bg_a * inv_a) / 255

    return noksha_color_pack_rgba(out_r, out_g, out_b, out_a)
end

fn noksha_color_destroy(c)
    if c > 0
        free(c, 32)
    end
    return 1
end
