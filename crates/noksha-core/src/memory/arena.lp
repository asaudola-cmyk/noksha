// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Package: noksha-core
// Module: memory/arena
// Purpose: Linear bump allocator for deterministic per-frame memory allocations.
//
// WHY: Traditional malloc/free causes severe heap fragmentation, cache invalidation,
// and unpredictable latency spikes. Noksha requires deterministic, zero-cost per-frame
// allocations. This Arena requests a large page-aligned contiguous memory block once from
// the kernel and allocates sub-blocks using an ultra-fast O(1) bump pointer.
// At the end of each frame, the entire arena resets in O(1) by setting offset to 0.

struct NokshaArena
    base_ptr,
    capacity,
    offset,
    alloc_count,
    peak_used

// ── 0. Primitive 32-bit Word Accessors ────────────────────────────────────────
fn mem_write_u32(addr, offset, val)
    v = val
    mem_write_byte(addr, offset, v % 256)
    mem_write_byte(addr, offset + 1, (v / 256) % 256)
    mem_write_byte(addr, offset + 2, (v / 65536) % 256)
    mem_write_byte(addr, offset + 3, (v / 16777216) % 256)
    return val
end

fn mem_read_u32(addr, offset)
    b0 = mem_read_byte(addr, offset)
    b1 = mem_read_byte(addr, offset + 1)
    b2 = mem_read_byte(addr, offset + 2)
    b3 = mem_read_byte(addr, offset + 3)
    return b0 + (b1 * 256) + (b2 * 65536) + (b3 * 16777216)
end

// Heap memory deallocation via Linux SYS_munmap (syscall 11)
fn free(addr, size)
    if addr <= 0 || size <= 0
        return 0
    end
    return syscall(11, addr, size, 0, 0, 0, 0)
end

// ── 1. Create a Linear Bump Arena via direct Linux mmap ───────────────────────
// prot = PROT_READ (1) | PROT_WRITE (2) = 3
// flags = MAP_PRIVATE (2) | MAP_ANONYMOUS (32) = 34
fn noksha_arena_create(capacity_bytes)
    cap = capacity_bytes
    if cap <= 0
        cap = 4194304 // Default 4MB arena
    end

    // Align capacity to 4KB page boundary
    page_rem = cap % 4096
    if page_rem != 0
        cap = cap + (4096 - page_rem)
    end

    // Direct kernel syscall 9 (SYS_mmap)
    raw_ptr = syscall(9, 0, cap, 3, 34, -1, 0)
    if raw_ptr <= 0
        return 0
    end

    // Allocate arena descriptor (40 bytes: base, capacity, offset, alloc_count, peak_used)
    arena = malloc(40)
    if arena <= 0
        syscall(11, raw_ptr, cap, 0, 0, 0, 0)
        return 0
    end

    mem_write(arena, 0, raw_ptr)
    mem_write(arena, 8, cap)
    mem_write(arena, 16, 0) // offset
    mem_write(arena, 24, 0) // alloc_count
    mem_write(arena, 32, 0) // peak_used

    return arena
end

// ── 2. Allocate 8-byte Aligned Memory Chunk from Arena ────────────────────────
fn noksha_arena_alloc(arena, size_bytes)
    if arena <= 0
        return 0
    end

    base_ptr = mem_read(arena, 0)
    cap = mem_read(arena, 8)
    curr_offset = mem_read(arena, 16)
    count = mem_read(arena, 24)
    peak = mem_read(arena, 32)

    // Enforce 8-byte alignment: ((size + 7) / 8) * 8
    aligned_size = ((size_bytes + 7) / 8) * 8

    if curr_offset + aligned_size > cap
        // Arena capacity exhausted (Out of Scratch Memory)
        return 0
    end

    allocated_addr = base_ptr + curr_offset
    new_offset = curr_offset + aligned_size

    mem_write(arena, 16, new_offset)
    mem_write(arena, 24, count + 1)

    if new_offset > peak
        mem_write(arena, 32, new_offset)
    end

    return allocated_addr
end

// ── 3. Allocate with Custom Alignment (e.g. 16, 32 for SIMD, 64 for Cacheline) ─
fn noksha_arena_alloc_aligned(arena, size_bytes, alignment)
    if arena <= 0
        return 0
    end

    base_ptr = mem_read(arena, 0)
    cap = mem_read(arena, 8)
    curr_offset = mem_read(arena, 16)
    count = mem_read(arena, 24)
    peak = mem_read(arena, 32)

    align = alignment
    if align < 8
        align = 8
    end

    curr_addr = base_ptr + curr_offset
    rem = curr_addr % align
    pad = 0
    if rem > 0
        pad = align - rem
    end

    aligned_size = ((size_bytes + 7) / 8) * 8
    total_needed = pad + aligned_size

    if curr_offset + total_needed > cap
        return 0
    end

    allocated_addr = curr_addr + pad
    new_offset = curr_offset + total_needed

    mem_write(arena, 16, new_offset)
    mem_write(arena, 24, count + 1)

    if new_offset > peak
        mem_write(arena, 32, new_offset)
    end

    return allocated_addr
end

// ── 4. O(1) Instant Arena Reset ──────────────────────────────────────────────
// Resets the allocation head to zero without touching virtual memory mapping
fn noksha_arena_reset(arena)
    if arena <= 0
        return 0
    end
    mem_write(arena, 16, 0) // offset = 0
    mem_write(arena, 24, 0) // alloc_count = 0
    return 1
end

// ── 5. Free Entire Arena and Return Memory to Kernel ──────────────────────────
fn noksha_arena_destroy(arena)
    if arena <= 0
        return 0
    end
    base_ptr = mem_read(arena, 0)
    cap = mem_read(arena, 8)

    if base_ptr > 0 && cap > 0
        syscall(11, base_ptr, cap, 0, 0, 0, 0) // SYS_munmap
    end

    free(arena, 40)
    return 1
end

// ── 6. Telemetry & Memory Introspection ───────────────────────────────────────
fn noksha_arena_used(arena)
    if arena <= 0
        return 0
    end
    return mem_read(arena, 16)
end

fn noksha_arena_capacity(arena)
    if arena <= 0
        return 0
    end
    return mem_read(arena, 8)
end

fn noksha_arena_peak(arena)
    if arena <= 0
        return 0
    end
    return mem_read(arena, 32)
end

fn noksha_arena_count(arena)
    if arena <= 0
        return 0
    end
    return mem_read(arena, 24)
end
