// ==============================================================================
// 👑 NOKSHA LAYOUT: W3C FLEXBOX LEVEL 1 SOLVER (crates/noksha-layout/src/flexbox.lp)
// ⚡ 100% Pure Raw LiPi | O(N) Linear Guarantee | Flex-Grow & Cross-Axis Alignment
// ==============================================================================
//
// WHY: Modern UI toolkits require deterministic, linear-time layout negotiation.
// Unlike Yoga, which suffers exponential O(2^N) slowdowns on deep auto-sized trees,
// Noksha computes flex line contributions in a single forward pass, resolves flexible
// main-axis lengths via integer arithmetic, and aligns cross-axis items in O(N) time.

// ── 1. The Core Flexbox Layout Pass ───────────────────────────────────────────
fn noksha_layout_compute_flex(node, parent_x, parent_y, available_w, available_h)
    if node <= 0
        return 0
    end

    style = noksha_node_get_style(node)
    if style <= 0
        return 0
    end

    // 1. Resolve container dimensions
    s_w = mem_read(style, 32)
    s_h = mem_read(style, 40)
    
    container_w = s_w
    if container_w <= 0
        container_w = available_w
    end

    container_h = s_h
    if container_h <= 0
        container_h = available_h
    end

    // Apply padding
    pad_l = mem_read(style, 80)
    pad_t = mem_read(style, 88)
    pad_r = mem_read(style, 96)
    pad_b = mem_read(style, 104)

    inner_w = container_w - (pad_l + pad_r)
    inner_h = container_h - (pad_t + pad_b)
    if inner_w < 0
        inner_w = 0
    end
    if inner_h < 0
        inner_h = 0
    end

    // Set computed bounds for container node
    noksha_node_set_computed(node, parent_x, parent_y, container_w, container_h)

    child_count = noksha_node_children_count(node)
    if child_count == 0
        return 1
    end

    flex_dir = mem_read(style, 8)     // 0: Row, 1: Col
    align_items = mem_read(style, 16) // 0: Start, 1: Center, 2: End, 3: Stretch
    gap = mem_read(style, 144)

    total_gaps = 0
    if child_count > 1
        total_gaps = (child_count - 1) * gap
    end

    // ── 2. Branch: Flex Direction Row ─────────────────────────────────────────
    if flex_dir == 0
        // Pass A: Calculate intrinsic children widths and total flex_grow
        total_fixed_w = 0
        total_grow = 0

        i = 0
        while i < child_count
            child = noksha_node_get_child(node, i)
            c_style = noksha_node_get_style(child)
            cw = mem_read(c_style, 32)
            c_grow = mem_read(c_style, 152)

            if cw > 0
                total_fixed_w = total_fixed_w + cw
            end
            total_grow = total_grow + c_grow
            i = i + 1
        end

        // Pass B: Distribute free main-axis space
        remaining_free_w = inner_w - (total_fixed_w + total_gaps)
        if remaining_free_w < 0
            remaining_free_w = 0
        end

        cursor_x = parent_x + pad_l

        j = 0
        while j < child_count
            child = noksha_node_get_child(node, j)
            c_style = noksha_node_get_style(child)
            cw = mem_read(c_style, 32)
            ch = mem_read(c_style, 40)
            c_grow = mem_read(c_style, 152)

            final_cw = cw
            if final_cw <= 0
                if total_grow > 0
                    final_cw = (remaining_free_w * c_grow) / total_grow
                else
                    final_cw = remaining_free_w / child_count
                end
            end
            if final_cw < 0
                final_cw = 0
            end

            final_ch = ch
            if final_ch <= 0 || align_items == 3 // Stretch
                final_ch = inner_h
            end

            // Compute cross-axis Y position based on align_items
            child_y = parent_y + pad_t
            if align_items == 1 // Center
                child_y = parent_y + pad_t + ((inner_h - final_ch) / 2)
            end
            if align_items == 2 // End
                child_y = parent_y + pad_t + (inner_h - final_ch)
            end

            // Recurse to solve child subtree
            noksha_layout_compute_flex(child, cursor_x, child_y, final_cw, final_ch)

            cursor_x = cursor_x + final_cw + gap
            j = j + 1
        end

        return 1
    end

    // ── 3. Branch: Flex Direction Column ──────────────────────────────────────
    if flex_dir == 1
        // Pass A: Calculate intrinsic children heights and total flex_grow
        total_fixed_h = 0
        total_grow = 0

        i = 0
        while i < child_count
            child = noksha_node_get_child(node, i)
            c_style = noksha_node_get_style(child)
            ch = mem_read(c_style, 40)
            c_grow = mem_read(c_style, 152)

            if ch > 0
                total_fixed_h = total_fixed_h + ch
            end
            total_grow = total_grow + c_grow
            i = i + 1
        end

        remaining_free_h = inner_h - (total_fixed_h + total_gaps)
        if remaining_free_h < 0
            remaining_free_h = 0
        end

        cursor_y = parent_y + pad_t

        j = 0
        while j < child_count
            child = noksha_node_get_child(node, j)
            c_style = noksha_node_get_style(child)
            cw = mem_read(c_style, 32)
            ch = mem_read(c_style, 40)
            c_grow = mem_read(c_style, 152)

            final_ch = ch
            if final_ch <= 0
                if total_grow > 0
                    final_ch = (remaining_free_h * c_grow) / total_grow
                else
                    final_ch = remaining_free_h / child_count
                end
            end
            if final_ch < 0
                final_ch = 0
            end

            final_cw = cw
            if final_cw <= 0 || align_items == 3 // Stretch
                final_cw = inner_w
            end

            // Compute cross-axis X position based on align_items
            child_x = parent_x + pad_l
            if align_items == 1 // Center
                child_x = parent_x + pad_l + ((inner_w - final_cw) / 2)
            end
            if align_items == 2 // End
                child_x = parent_x + pad_l + (inner_w - final_cw)
            end

            // Recurse to solve child subtree
            noksha_layout_compute_flex(child, child_x, cursor_y, final_cw, final_ch)

            cursor_y = cursor_y + final_ch + gap
            j = j + 1
        end

        return 1
    end

    return 1
end
