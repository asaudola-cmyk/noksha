// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Package: noksha-theme
// Module: tokens
// Purpose: Design system color tokens and theme presets.
import "../../crates/noksha-core/src/lib.lp"

struct NokshaTheme
    is_dark,
    bg_color,
    surface_color,
    surface_border,
    primary_color,
    secondary_color,
    accent_color,
    success_color,
    danger_color,
    text_primary,
    text_muted,
    card_radius,
    button_radius,
    border_width

// 1. In-place Initializers for Arena Allocation
fn noksha_theme_init_dark(t)
    if t <= 0
        return 0
    end
    mem_write(t, 0, 1)                                            // is_dark: 1
    mem_write(t, 8, noksha_color_rgba(11, 15, 25, 255))           // bg_color: #0B0F19
    mem_write(t, 16, noksha_color_rgba(30, 41, 59, 192))         // surface_color: #1E293B (75% alpha)
    mem_write(t, 24, noksha_color_rgba(51, 65, 85, 150))         // surface_border: #334155 (60% alpha)
    mem_write(t, 32, noksha_color_rgba(99, 102, 241, 255))       // primary_color: #6366F1 (Electric Indigo)
    mem_write(t, 40, noksha_color_rgba(6, 182, 212, 255))        // secondary_color: #06B6D4 (Cyan)
    mem_write(t, 48, noksha_color_rgba(245, 158, 11, 255))       // accent_color: #F59E0B (Amber)
    mem_write(t, 56, noksha_color_rgba(16, 185, 129, 255))       // success_color: #10B981 (Emerald)
    mem_write(t, 64, noksha_color_rgba(244, 63, 94, 255))        // danger_color: #F43F5E (Rose)
    mem_write(t, 72, noksha_color_rgba(248, 250, 252, 255))      // text_primary: #F8FAFC
    mem_write(t, 80, noksha_color_rgba(148, 163, 184, 255))      // text_muted: #94A3B8
    mem_write(t, 88, 16)                                          // card_radius: 16px
    mem_write(t, 96, 10)                                          // button_radius: 10px
    mem_write(t, 104, 1)                                          // border_width: 1px
    return t
end

fn noksha_theme_init_light(t)
    if t <= 0
        return 0
    end
    mem_write(t, 0, 0)                                            // is_dark: 0
    mem_write(t, 8, noksha_color_rgba(248, 250, 252, 255))       // bg_color: #F8FAFC
    mem_write(t, 16, noksha_color_rgba(255, 255, 255, 220))      // surface_color: #FFFFFF (85% alpha)
    mem_write(t, 24, noksha_color_rgba(226, 232, 240, 200))      // surface_border: #E2E8F0
    mem_write(t, 32, noksha_color_rgba(79, 70, 229, 255))        // primary_color: #4F46E5
    mem_write(t, 40, noksha_color_rgba(37, 99, 235, 255))        // secondary_color: #2563EB
    mem_write(t, 48, noksha_color_rgba(217, 119, 6, 255))        // accent_color: #D97706
    mem_write(t, 56, noksha_color_rgba(5, 150, 105, 255))        // success_color: #059669
    mem_write(t, 64, noksha_color_rgba(225, 29, 72, 255))        // danger_color: #E11D48
    mem_write(t, 72, noksha_color_rgba(15, 23, 42, 255))         // text_primary: #0F172A
    mem_write(t, 80, noksha_color_rgba(100, 116, 139, 255))      // text_muted: #64748B
    mem_write(t, 88, 16)                                          // card_radius: 16px
    mem_write(t, 96, 10)                                          // button_radius: 10px
    mem_write(t, 104, 1)                                          // border_width: 1px
    return t
end

// 2. Standalone Heap Allocators
fn noksha_theme_create_dark()
    t = malloc(112)
    return noksha_theme_init_dark(t)
end

fn noksha_theme_create_light()
    t = malloc(112)
    return noksha_theme_init_light(t)
end

fn noksha_theme_destroy(t)
    if t > 0
        free(t, 112)
    end
    return 1
end
