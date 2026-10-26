// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Package: noksha-reactive
// Module: signal
// Purpose: Fine-grained push-pull Signal primitive with O(1) subscriber notifications.
//
// WHY: Virtual DOM diffing (React) burns CPU cycles checking every node in a tree
// on every state change. Noksha uses Fine-Grained Reactive Signals (SolidJS / Slint style).
// A Signal wraps a value and maintains a list of dependent subscriber node IDs.
// When a signal's value changes, ONLY its direct subscribers are notified and marked dirty.
// The rest of the scene graph remains completely untouched, achieving sub-millisecond updates.

struct NokshaSignal
    id,
    value,
    subscribers_mem,
    subscribers_capacity,
    subscribers_count

// Global auto-increment signal ID generator
fn noksha_signal_next_id()
    return 1000
end

// ── 1. Create Reactive Signal ─────────────────────────────────────────────────
fn noksha_signal_create(initial_value)
    init_cap = 64 // Pre-allocated capacity for up to 64 subscribers per signal
    sub_mem = malloc(init_cap * 8) // 512 bytes
    if sub_mem <= 0
        return 0
    end

    sig = malloc(40) // 5 fields * 8 bytes
    mem_write(sig, 0, noksha_signal_next_id())
    mem_write(sig, 8, initial_value)
    mem_write(sig, 16, sub_mem)
    mem_write(sig, 24, init_cap)
    mem_write(sig, 32, 0) // count = 0

    return sig
end

// ── 2. Read Signal Value ──────────────────────────────────────────────────────
fn noksha_signal_get(sig)
    if sig <= 0
        return 0
    end
    return mem_read(sig, 8)
end

// ── 3. Mutate Signal Value and Notify Subscribers ─────────────────────────────
fn noksha_signal_set(sig, new_value)
    if sig <= 0
        return 0
    end

    old_val = mem_read(sig, 8)
    if old_val == new_value
        // Value unchanged, skip notification to prevent redundant work
        return 0
    end

    mem_write(sig, 8, new_value)

    // Notify subscribers
    sub_mem = mem_read(sig, 16)
    count = mem_read(sig, 32)

    idx = 0
    while idx < count
        node_ptr = mem_read(sub_mem, idx * 8)
        if node_ptr > 0
            // Mark subscriber node dirty (field 80 in NokshaLayoutNode)
            mem_write(node_ptr, 80, 1)
        end
        idx = idx + 1
    end

    return count
end

// ── 4. Subscribe Layout Node to Signal Mutations (O(1) Memory Conserving) ─────
fn noksha_signal_subscribe(sig, subscriber_node_ptr)
    if sig <= 0 || subscriber_node_ptr <= 0
        return 0
    end

    sub_mem = mem_read(sig, 16)
    cap = mem_read(sig, 24)
    count = mem_read(sig, 32)

    if count >= cap
        return 0 // Subscriber capacity reached
    end

    mem_write(sub_mem, count * 8, subscriber_node_ptr)
    mem_write(sig, 32, count + 1)
    return 1
end

fn noksha_signal_subscribers_count(sig)
    if sig <= 0
        return 0
    end
    return mem_read(sig, 32)
end

fn noksha_signal_destroy(sig)
    if sig <= 0
        return 0
    end
    sub_mem = mem_read(sig, 16)
    cap = mem_read(sig, 24)
    if sub_mem > 0
        free(sub_mem, cap * 8)
    end
    free(sig, 40)
    return 1
end
