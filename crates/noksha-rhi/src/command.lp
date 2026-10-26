// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Package: noksha-rhi
// Module: command
// Purpose: Sequential command buffer encoder for draw calls and render passes.
//
// WHY: Modern graphics drivers (Vulkan, Metal 3, DirectX 12) decouple command recording
// from execution. Noksha records render passes into a linear bump-allocated command stream:
// [Opcode: 8B] [Arg0: 8B] [Arg1: 8B] [Arg2: 8B] [Arg3: 8B]...
// At frame completion, the entire command buffer is submitted to the active backend
// (GPU hardware queue or Software SIMD rasterizer) in a single synchronous/asynchronous pass.

struct NokshaCommandBuffer
    buffer_ptr,
    capacity,
    cursor,
    command_count

// ── 1. Command Opcode Enumeration ─────────────────────────────────────────────
fn noksha_cmd_set_viewport()
    return 1
end

fn noksha_cmd_set_scissor()
    return 2
end

fn noksha_cmd_clear()
    return 3
end

fn noksha_cmd_draw_instanced_quads()
    return 4
end

fn noksha_cmd_present()
    return 5
end

// ── 2. Command Buffer Lifecycle ───────────────────────────────────────────────
fn noksha_cmd_buffer_create(capacity_bytes)
    cap = capacity_bytes
    if cap <= 0
        cap = 262144 // 256KB default command buffer
    end

    buf_mem = malloc(cap)
    if buf_mem <= 0
        return 0
    end

    cmd_buf = malloc(32)
    mem_write(cmd_buf, 0, buf_mem)
    mem_write(cmd_buf, 8, cap)
    mem_write(cmd_buf, 16, 0) // cursor
    mem_write(cmd_buf, 24, 0) // command_count

    return cmd_buf
end

fn noksha_cmd_buffer_reset(cmd_buf)
    if cmd_buf <= 0
        return 0
    end
    mem_write(cmd_buf, 16, 0) // cursor = 0
    mem_write(cmd_buf, 24, 0) // count = 0
    return 1
end

fn noksha_cmd_buffer_count(cmd_buf)
    if cmd_buf <= 0
        return 0
    end
    return mem_read(cmd_buf, 24)
end

// ── 3. Command Encoders ────────────────────────────────────────────────────────
// Encodes: [CMD_SET_VIEWPORT: 1] [width] [height]
fn noksha_cmd_encode_viewport(cmd_buf, width, height)
    if cmd_buf <= 0
        return 0
    end
    buf = mem_read(cmd_buf, 0)
    cap = mem_read(cmd_buf, 8)
    cur = mem_read(cmd_buf, 16)

    if cur + 24 > cap
        return 0
    end

    mem_write(buf, cur, noksha_cmd_set_viewport())
    mem_write(buf, cur + 8, width)
    mem_write(buf, cur + 16, height)

    mem_write(cmd_buf, 16, cur + 24)
    mem_write(cmd_buf, 24, mem_read(cmd_buf, 24) + 1)
    return 1
end

// Encodes: [CMD_SET_SCISSOR: 2] [x] [y] [width] [height]
fn noksha_cmd_encode_scissor(cmd_buf, x, y, width, height)
    if cmd_buf <= 0
        return 0
    end
    buf = mem_read(cmd_buf, 0)
    cap = mem_read(cmd_buf, 8)
    cur = mem_read(cmd_buf, 16)

    if cur + 40 > cap
        return 0
    end

    mem_write(buf, cur, noksha_cmd_set_scissor())
    mem_write(buf, cur + 8, x)
    mem_write(buf, cur + 16, y)
    mem_write(buf, cur + 24, width)
    mem_write(buf, cur + 32, height)

    mem_write(cmd_buf, 16, cur + 40)
    mem_write(cmd_buf, 24, mem_read(cmd_buf, 24) + 1)
    return 1
end

// Encodes: [CMD_CLEAR: 3] [packed_color]
fn noksha_cmd_encode_clear(cmd_buf, packed_color)
    if cmd_buf <= 0
        return 0
    end
    buf = mem_read(cmd_buf, 0)
    cap = mem_read(cmd_buf, 8)
    cur = mem_read(cmd_buf, 16)

    if cur + 16 > cap
        return 0
    end

    mem_write(buf, cur, noksha_cmd_clear())
    mem_write(buf, cur + 8, packed_color)

    mem_write(cmd_buf, 16, cur + 16)
    mem_write(cmd_buf, 24, mem_read(cmd_buf, 24) + 1)
    return 1
end

// Encodes: [CMD_DRAW_INSTANCED_QUADS: 4] [instance_buffer_ptr] [quad_count]
fn noksha_cmd_encode_draw_quads(cmd_buf, instance_buffer_ptr, quad_count)
    if cmd_buf <= 0
        return 0
    end
    buf = mem_read(cmd_buf, 0)
    cap = mem_read(cmd_buf, 8)
    cur = mem_read(cmd_buf, 16)

    if cur + 24 > cap
        return 0
    end

    mem_write(buf, cur, noksha_cmd_draw_instanced_quads())
    mem_write(buf, cur + 8, instance_buffer_ptr)
    mem_write(buf, cur + 16, quad_count)

    mem_write(cmd_buf, 16, cur + 24)
    mem_write(cmd_buf, 24, mem_read(cmd_buf, 24) + 1)
    return 1
end

// Encodes: [CMD_PRESENT: 5]
fn noksha_cmd_encode_present(cmd_buf)
    if cmd_buf <= 0
        return 0
    end
    buf = mem_read(cmd_buf, 0)
    cap = mem_read(cmd_buf, 8)
    cur = mem_read(cmd_buf, 16)

    if cur + 8 > cap
        return 0
    end

    mem_write(buf, cur, noksha_cmd_present())

    mem_write(cmd_buf, 16, cur + 8)
    mem_write(cmd_buf, 24, mem_read(cmd_buf, 24) + 1)
    return 1
end

fn noksha_cmd_buffer_destroy(cmd_buf)
    if cmd_buf <= 0
        return 0
    end
    buf = mem_read(cmd_buf, 0)
    cap = mem_read(cmd_buf, 8)
    if buf > 0
        free(buf, cap)
    end
    free(cmd_buf, 32)
    return 1
end
