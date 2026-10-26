// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Package: noksha-rhi
// Module: rhi
// Purpose: Hardware rendering interface and backend abstraction.
//
// WHY: Cross-platform rendering often incurs heavy abstraction penalties (e.g. dynamic
// virtual dispatch, shader transpilation overhead). Noksha's RHI provides a compact,
// integer-indexed hardware abstraction representing device state, swapchain dimensions,
// active backends (Vulkan, Metal 3, D3D12, WebGPU, DRM/KMS Dumb Framebuffer, Software SIMD).
// All hardware commands are recorded into contiguous memory command buffers.

struct NokshaRhiDevice
    backend_type,       // 0: Software, 1: DRM/KMS, 2: Vulkan, 3: Metal, 4: D3D12, 5: WebGPU
    viewport_width,
    viewport_height,
    clear_color_packed,
    active_framebuffer,
    frame_counter,
    is_headless

// ── 1. Backend Type Constants ─────────────────────────────────────────────────
fn noksha_backend_software()
    return 0
end

fn noksha_backend_drm_kms()
    return 1
end

fn noksha_backend_vulkan()
    return 2
end

fn noksha_backend_metal()
    return 3
end

fn noksha_backend_d3d12()
    return 4
end

fn noksha_backend_webgpu()
    return 5
end

// ── 2. RHI Device Initialization ──────────────────────────────────────────────
fn noksha_rhi_create(backend_type, width, height)
    dev = malloc(56) // 7 fields * 8 bytes
    if dev <= 0
        return 0
    end

    mem_write(dev, 0, backend_type)
    mem_write(dev, 8, width)
    mem_write(dev, 16, height)
    mem_write(dev, 24, 4278190080) // Default clear color: Opaque Black (0xFF000000)
    mem_write(dev, 32, 0)          // active_framebuffer
    mem_write(dev, 40, 0)          // frame_counter
    mem_write(dev, 48, 0)          // is_headless = 0

    return dev
end

fn noksha_rhi_set_viewport(dev, width, height)
    if dev <= 0
        return 0
    end
    mem_write(dev, 8, width)
    mem_write(dev, 16, height)
    return 1
end

fn noksha_rhi_set_clear_color(dev, packed_color)
    if dev <= 0
        return 0
    end
    mem_write(dev, 24, packed_color)
    return 1
end

fn noksha_rhi_get_width(dev)
    if dev <= 0
        return 0
    end
    return mem_read(dev, 8)
end

fn noksha_rhi_get_height(dev)
    if dev <= 0
        return 0
    end
    return mem_read(dev, 16)
end

fn noksha_rhi_get_backend(dev)
    if dev <= 0
        return 0
    end
    return mem_read(dev, 0)
end

fn noksha_rhi_frame_count(dev)
    if dev <= 0
        return 0
    end
    return mem_read(dev, 40)
end

fn noksha_rhi_destroy(dev)
    if dev > 0
        free(dev, 56)
    end
    return 1
end
