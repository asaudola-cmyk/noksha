// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Package: noksha-layout
// Module: flexbox
// Purpose: Linear-time O(N) W3C Flexbox Level 1 layout solver.
//
// WHY: Modern UI toolkits require deterministic, linear-time layout negotiation.
// Unlike Yoga, which suffers exponential O(2^N) slowdowns on deep auto-sized trees,
// Noksha computes flex line contributions in a single forward pass, resolves flexible
// main-axis lengths via integer arithmetic, supports full margin boxes and justify-content
// alignments (Start, Center, End, SpaceBetween, SpaceAround, SpaceEvenly), and aligns cross-axis
// items in O(N) time with robust unconstrained boundary resolution.

// ── 1. The Core Flexbox Layout Pass ───────────────────────────────────────────
fn noksha_layout_compute_flex(node, parent_x, parent_y, available_w, available_h)
    if node <= 0
        return 0
    end

    style = noksha_node_get_style(node)
    if style <= 0
        return 0
    end

    child_count = noksha_node_children_count(node)
    flex_dir = mem_read(style, 8)     // 0: Row, 1: Col
    align_items = mem_read(style, 16) // 0: Start, 1: Center, 2: End, 3: Stretch
    justify_content = mem_read(style, 24) // 0: Start, 1: Center, 2: End, 3: Between, 4: Around, 5: Evenly
    s_w = mem_read(style, 32)
    s_h = mem_read(style, 40)
    pad_l = mem_read(style, 80)
    pad_t = mem_read(style, 88)
    pad_r = mem_read(style, 96)
    pad_b = mem_read(style, 104)
    gap = mem_read(style, 144)

    total_gaps = 0
    if child_count > 1
        total_gaps = (child_count - 1) * gap
    end

    // ── 2. Branch: Flex Direction Row ─────────────────────────────────────────
    if flex_dir == 0
        // Pass A: Calculate intrinsic children widths, margins, cross sizes, and total flex_grow
        total_fixed_w = 0
        total_grow = 0
        auto_count = 0
        max_child_cross_h = 0

        i = 0
        while i < child_count
            child = noksha_node_get_child(node, i)
            c_style = noksha_node_get_style(child)
            cw = mem_read(c_style, 32)
            ch = mem_read(c_style, 40)
            c_grow = mem_read(c_style, 152)
            c_ml = mem_read(c_style, 112)
            c_mt = mem_read(c_style, 120)
            c_mr = mem_read(c_style, 128)
            c_mb = mem_read(c_style, 136)

            base_w = 0
            if cw > 0
                base_w = cw
            else
                auto_count = auto_count + 1
            end
            total_fixed_w = total_fixed_w + base_w + c_ml + c_mr
            total_grow = total_grow + c_grow

            base_h = 0
            if ch > 0
                base_h = ch
            end
            item_cross = base_h + c_mt + c_mb
            if item_cross > max_child_cross_h
                max_child_cross_h = item_cross
            end

            i = i + 1
        end

        parent_ptr = mem_read(node, 72)

        // Resolve container dimensions
        if parent_ptr > 0 && available_w > 0
            container_w = available_w
        else
            container_w = s_w
            if container_w <= 0
                if available_w > 0
                    container_w = available_w
                else
                    container_w = total_fixed_w + total_gaps + pad_l + pad_r
                end
            end
        end

        if parent_ptr > 0 && available_h > 0
            container_h = available_h
        else
            container_h = s_h
            if container_h <= 0
                if available_h > 0
                    container_h = available_h
                else
                    container_h = max_child_cross_h + pad_t + pad_b
                end
            end
        end

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

        if child_count == 0
            return 1
        end

        // Pass B: Distribute free main-axis space
        remaining_free_w = inner_w - (total_fixed_w + total_gaps)
        if remaining_free_w < 0
            remaining_free_w = 0
        end

        // Determine leftover space for justify_content
        rem_space = 0
        if total_grow == 0 && auto_count == 0
            rem_space = remaining_free_w
        end

        offset_start = 0
        extra_gap = 0
        if rem_space > 0
            if justify_content == 1 // Center
                offset_start = rem_space / 2
            end
            if justify_content == 2 // End
                offset_start = rem_space
            end
            if justify_content == 3 // SpaceBetween
                if child_count > 1
                    extra_gap = rem_space / (child_count - 1)
                end
            end
            if justify_content == 4 // SpaceAround
                if child_count > 0
                    unit = rem_space / (child_count * 2)
                    offset_start = unit
                    extra_gap = unit * 2
                end
            end
            if justify_content == 5 // SpaceEvenly
                if child_count > 0
                    unit = rem_space / (child_count + 1)
                    offset_start = unit
                    extra_gap = unit
                end
            end
        end

        cursor_x = parent_x + pad_l + offset_start

        j = 0
        while j < child_count
            child = noksha_node_get_child(node, j)
            c_style = noksha_node_get_style(child)
            cw = mem_read(c_style, 32)
            ch = mem_read(c_style, 40)
            c_grow = mem_read(c_style, 152)
            c_ml = mem_read(c_style, 112)
            c_mt = mem_read(c_style, 120)
            c_mr = mem_read(c_style, 128)
            c_mb = mem_read(c_style, 136)

            base_w = 0
            if cw > 0
                base_w = cw
            end

            final_cw = base_w
            if total_grow > 0
                if c_grow > 0
                    final_cw = base_w + ((remaining_free_w * c_grow) / total_grow)
                end
            else
                if cw <= 0 && auto_count > 0
                    final_cw = remaining_free_w / auto_count
                end
            end
            if final_cw < 0
                final_cw = 0
            end

            final_ch = ch
            if final_ch <= 0 || align_items == 3 // Stretch
                avail_h = inner_h - (c_mt + c_mb)
                if avail_h < 0
                    avail_h = 0
                end
                final_ch = avail_h
            end

            // Compute cross-axis Y position based on align_items and margins
            free_cross = inner_h - (final_ch + c_mt + c_mb)
            if free_cross < 0
                free_cross = 0
            end

            child_y = parent_y + pad_t + c_mt
            if align_items == 1 // Center
                child_y = parent_y + pad_t + c_mt + (free_cross / 2)
            end
            if align_items == 2 // End
                child_y = parent_y + pad_t + c_mt + free_cross
            end

            child_x = cursor_x + c_ml

            // Recurse to solve child subtree
            noksha_layout_compute_flex(child, child_x, child_y, final_cw, final_ch)

            cursor_x = child_x + final_cw + c_mr + gap + extra_gap
            j = j + 1
        end

        return 1
    end

    // ── 3. Branch: Flex Direction Column ──────────────────────────────────────
    if flex_dir == 1
        // Pass A: Calculate intrinsic children heights, margins, cross sizes, and total flex_grow
        total_fixed_h = 0
        total_grow = 0
        auto_count = 0
        max_child_cross_w = 0

        i = 0
        while i < child_count
            child = noksha_node_get_child(node, i)
            c_style = noksha_node_get_style(child)
            cw = mem_read(c_style, 32)
            ch = mem_read(c_style, 40)
            c_grow = mem_read(c_style, 152)
            c_ml = mem_read(c_style, 112)
            c_mt = mem_read(c_style, 120)
            c_mr = mem_read(c_style, 128)
            c_mb = mem_read(c_style, 136)

            base_h = 0
            if ch > 0
                base_h = ch
            else
                auto_count = auto_count + 1
            end
            total_fixed_h = total_fixed_h + base_h + c_mt + c_mb
            total_grow = total_grow + c_grow

            base_w = 0
            if cw > 0
                base_w = cw
            end
            item_cross = base_w + c_ml + c_mr
            if item_cross > max_child_cross_w
                max_child_cross_w = item_cross
            end

            i = i + 1
        end

        parent_ptr = mem_read(node, 72)

        // Resolve container dimensions
        if parent_ptr > 0 && available_w > 0
            container_w = available_w
        else
            container_w = s_w
            if container_w <= 0
                if available_w > 0
                    container_w = available_w
                else
                    container_w = max_child_cross_w + pad_l + pad_r
                end
            end
        end

        if parent_ptr > 0 && available_h > 0
            container_h = available_h
        else
            container_h = s_h
            if container_h <= 0
                if available_h > 0
                    container_h = available_h
                else
                    container_h = total_fixed_h + total_gaps + pad_t + pad_b
                end
            end
        end

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

        if child_count == 0
            return 1
        end

        // Pass B: Distribute free main-axis space
        remaining_free_h = inner_h - (total_fixed_h + total_gaps)
        if remaining_free_h < 0
            remaining_free_h = 0
        end

        // Determine leftover space for justify_content
        rem_space = 0
        if total_grow == 0 && auto_count == 0
            rem_space = remaining_free_h
        end

        offset_start = 0
        extra_gap = 0
        if rem_space > 0
            if justify_content == 1 // Center
                offset_start = rem_space / 2
            end
            if justify_content == 2 // End
                offset_start = rem_space
            end
            if justify_content == 3 // SpaceBetween
                if child_count > 1
                    extra_gap = rem_space / (child_count - 1)
                end
            end
            if justify_content == 4 // SpaceAround
                if child_count > 0
                    unit = rem_space / (child_count * 2)
                    offset_start = unit
                    extra_gap = unit * 2
                end
            end
            if justify_content == 5 // SpaceEvenly
                if child_count > 0
                    unit = rem_space / (child_count + 1)
                    offset_start = unit
                    extra_gap = unit
                end
            end
        end

        cursor_y = parent_y + pad_t + offset_start

        j = 0
        while j < child_count
            child = noksha_node_get_child(node, j)
            c_style = noksha_node_get_style(child)
            cw = mem_read(c_style, 32)
            ch = mem_read(c_style, 40)
            c_grow = mem_read(c_style, 152)
            c_ml = mem_read(c_style, 112)
            c_mt = mem_read(c_style, 120)
            c_mr = mem_read(c_style, 128)
            c_mb = mem_read(c_style, 136)

            base_h = 0
            if ch > 0
                base_h = ch
            end

            final_ch = base_h
            if total_grow > 0
                if c_grow > 0
                    final_ch = base_h + ((remaining_free_h * c_grow) / total_grow)
                end
            else
                if ch <= 0 && auto_count > 0
                    final_ch = remaining_free_h / auto_count
                end
            end
            if final_ch < 0
                final_ch = 0
            end

            final_cw = cw
            if final_cw <= 0 || align_items == 3 // Stretch
                avail_w = inner_w - (c_ml + c_mr)
                if avail_w < 0
                    avail_w = 0
                end
                final_cw = avail_w
            end

            // Compute cross-axis X position based on align_items and margins
            free_cross = inner_w - (final_cw + c_ml + c_mr)
            if free_cross < 0
                free_cross = 0
            end

            child_x = parent_x + pad_l + c_ml
            if align_items == 1 // Center
                child_x = parent_x + pad_l + c_ml + (free_cross / 2)
            end
            if align_items == 2 // End
                child_x = parent_x + pad_l + c_ml + free_cross
            end

            child_y = cursor_y + c_mt

            // Recurse to solve child subtree
            noksha_layout_compute_flex(child, child_x, child_y, final_cw, final_ch)

            cursor_y = child_y + final_ch + c_mb + gap + extra_gap
            j = j + 1
        end

        return 1
    end

    return 1
end
