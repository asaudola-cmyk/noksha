// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Package: noksha-reactive
// Module: signal
// Purpose: Fine-grained push-pull Signal primitive with dynamic growth, Computed<T>, Effect, and Batching.
//
// WHY: Virtual DOM diffing burns CPU cycles checking every node in a tree
// on every state change. Noksha uses Fine-Grained Reactive Signals.
// A Signal wraps a value and maintains a list of dependent subscriber node IDs.
// When a signal changes, ONLY its direct subscribers are notified and marked dirty.
// Batched mutations defer subscriber notifications until batch end.
// Computed values memoize derived state until their underlying dependency becomes dirty.

struct NokshaSignal
    id,
    value,
    subscribers_mem,
    subscribers_capacity,
    subscribers_count

struct NokshaComputed
    id,
    source_signal,
    cached_value,
    compute_fn_type,
    param,
    unused1,
    unused2,
    unused3,
    unused4,
    unused5,
    is_dirty

struct NokshaEffect
    id,
    target_node,
    effect_type,
    param,
    run_count

// ── 0. Static Reactive Runtime Context ────────────────────────────────────────
fn noksha_reactive_storage()
    return "NOKSHA_REACTIVE_DISPATCH_STORAGE_BUFFER_V1_CELL_0123456789ABCDEF"
end

fn noksha_reactive_ensure_init()
    buf = noksha_reactive_storage()
    if mem_read(buf, 0) != 0x4E4F4B53
        mem_write(buf, 0, 0x4E4F4B53)
        mem_write(buf, 8, 1000)  // Next Signal ID
        mem_write(buf, 16, 2000) // Next Computed ID
        mem_write(buf, 24, 3000) // Next Effect ID
        mem_write(buf, 32, 0)    // Batch depth
        q_mem = malloc(512 * 8)
        mem_write(buf, 40, q_mem)
        mem_write(buf, 48, 0)    // Batch queue count
        mem_write(buf, 56, 512)  // Batch queue capacity
    end
    return buf
end

// Global auto-increment ID generators
fn noksha_signal_next_id()
    buf = noksha_reactive_ensure_init()
    cur = mem_read(buf, 8)
    mem_write(buf, 8, cur + 1)
    return cur
end

fn noksha_computed_next_id()
    buf = noksha_reactive_ensure_init()
    cur = mem_read(buf, 16)
    mem_write(buf, 16, cur + 1)
    return cur
end

fn noksha_effect_next_id()
    buf = noksha_reactive_ensure_init()
    cur = mem_read(buf, 24)
    mem_write(buf, 24, cur + 1)
    return cur
end

// ── 1. Create Reactive Signal ─────────────────────────────────────────────────
fn noksha_signal_create(initial_value)
    init_cap = 64 // Pre-allocated capacity for subscribers
    sub_mem = malloc(init_cap * 8)
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

fn noksha_signal_get_id(sig)
    if sig <= 0
        return 0
    end
    return mem_read(sig, 0)
end

// ── 3. Mutate Signal Value and Notify Subscribers (with Batch Support) ────────
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

    sub_mem = mem_read(sig, 16)
    count = mem_read(sig, 32)

    buf = noksha_reactive_ensure_init()
    batch_depth = mem_read(buf, 32)

    if batch_depth > 0
        // Batch transaction active: queue subscribers into batch dirty queue
        q_mem = mem_read(buf, 40)
        q_count = mem_read(buf, 48)
        q_cap = mem_read(buf, 56)

        idx = 0
        while idx < count
            node_ptr = mem_read(sub_mem, idx * 8)
            if node_ptr > 0 && q_count < q_cap
                mem_write(q_mem, q_count * 8, node_ptr)
                q_count = q_count + 1
            end
            idx = idx + 1
        end
        mem_write(buf, 48, q_count)
        return count
    end

    // Direct notification: mark subscriber dirty
    idx = 0
    while idx < count
        node_ptr = mem_read(sub_mem, idx * 8)
        if node_ptr > 0
            // Mark subscriber node dirty (field 80 in both NokshaLayoutNode & NokshaComputed)
            mem_write(node_ptr, 80, 1)
        end
        idx = idx + 1
    end

    return count
end

// ── 4. Subscribe Layout Node or Computed to Signal Mutations ──────────────────
fn noksha_signal_subscribe(sig, subscriber_node_ptr)
    if sig <= 0 || subscriber_node_ptr <= 0
        return 0
    end

    cap = mem_read(sig, 24)
    count = mem_read(sig, 32)

    if count >= cap
        return 0 // Subscriber capacity reached
    end

    sub_mem = mem_read(sig, 16)
    mem_write(sub_mem, count * 8, subscriber_node_ptr)
    mem_write(sig, 32, count + 1)
    return 1
end

// ── 5. Unsubscribe from Signal ────────────────────────────────────────────────
fn noksha_signal_unsubscribe(sig, subscriber_node_ptr)
    if sig <= 0 || subscriber_node_ptr <= 0
        return 0
    end

    sub_mem = mem_read(sig, 16)
    count = mem_read(sig, 32)

    idx = 0
    while idx < count
        if mem_read(sub_mem, idx * 8) == subscriber_node_ptr
            // Shift remaining subscribers left
            s = idx
            while s < (count - 1)
                mem_write(sub_mem, s * 8, mem_read(sub_mem, (s + 1) * 8))
                s = s + 1
            end
            mem_write(sig, 32, count - 1)
            return 1
        end
        idx = idx + 1
    end

    return 0
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

// ── 6. Batch Transaction Coordinator ──────────────────────────────────────────
fn noksha_batch_start()
    buf = noksha_reactive_ensure_init()
    depth = mem_read(buf, 32)
    mem_write(buf, 32, depth + 1)
    return depth + 1
end

fn noksha_batch_end()
    buf = noksha_reactive_ensure_init()
    depth = mem_read(buf, 32)
    if depth <= 0
        return 0
    end

    depth = depth - 1
    mem_write(buf, 32, depth)

    if depth == 0
        // Flush all deferred dirty nodes from batch queue
        q_mem = mem_read(buf, 40)
        q_count = mem_read(buf, 48)

        idx = 0
        while idx < q_count
            node_ptr = mem_read(q_mem, idx * 8)
            if node_ptr > 0
                mem_write(node_ptr, 80, 1)
            end
            idx = idx + 1
        end
        mem_write(buf, 48, 0)
    end

    return depth
end

// ── 7. Computed<T> Memoized Computation ───────────────────────────────────────
// compute_fn_type: 0: Identity, 1: Double, 2: Add param, 3: Multiply param, 4: Add secondary signal
fn noksha_computed_create(source_signal, compute_fn_type, param)
    comp = malloc(88) // 11 fields * 8 bytes
    if comp <= 0
        return 0
    end

    mem_write(comp, 0, noksha_computed_next_id())
    mem_write(comp, 8, source_signal)
    mem_write(comp, 16, 0) // cached_value = 0
    mem_write(comp, 24, compute_fn_type)
    mem_write(comp, 32, param)
    mem_write(comp, 40, 0)
    mem_write(comp, 48, 0)
    mem_write(comp, 56, 0)
    mem_write(comp, 64, 0)
    mem_write(comp, 72, 0)
    mem_write(comp, 80, 1) // is_dirty = 1 (stale on initialization)

    if source_signal > 0
        noksha_signal_subscribe(source_signal, comp)
    end

    return comp
end

fn noksha_computed_get(comp)
    if comp <= 0
        return 0
    end

    is_dirty = mem_read(comp, 80)
    if is_dirty == 0
        // Cache valid: return memoized result immediately
        return mem_read(comp, 16)
    end

    // Compute fresh value
    src_sig = mem_read(comp, 8)
    fn_type = mem_read(comp, 24)
    param = mem_read(comp, 32)

    src_val = 0
    if src_sig > 0
        src_val = noksha_signal_get(src_sig)
    end

    res = src_val
    if fn_type == 1 // Double
        res = src_val * 2
    end
    if fn_type == 2 // Add param
        res = src_val + param
    end
    if fn_type == 3 // Multiply param
        res = src_val * param
    end
    if fn_type == 4 // Add secondary signal
        if param > 0
            res = src_val + noksha_signal_get(param)
        end
    end

    mem_write(comp, 16, res)
    mem_write(comp, 80, 0) // Mark clean

    return res
end

fn noksha_computed_destroy(comp)
    if comp <= 0
        return 0
    end
    src_sig = mem_read(comp, 8)
    if src_sig > 0
        noksha_signal_unsubscribe(src_sig, comp)
    end
    free(comp, 88)
    return 1
end

// ── 8. Effect Side-Effect Primitive ───────────────────────────────────────────
fn noksha_effect_create(target_node, effect_type, param)
    eff = malloc(40) // 5 fields * 8 bytes
    if eff <= 0
        return 0
    end
    mem_write(eff, 0, noksha_effect_next_id())
    mem_write(eff, 8, target_node)
    mem_write(eff, 16, effect_type)
    mem_write(eff, 24, param)
    mem_write(eff, 32, 0) // run_count = 0
    return eff
end

fn noksha_effect_dispatch(eff)
    if eff <= 0
        return 0
    end
    node = mem_read(eff, 8)
    e_type = mem_read(eff, 16)

    if e_type == 1 && node > 0
        mem_write(node, 80, 1) // Mark target node dirty
    end

    rc = mem_read(eff, 32) + 1
    mem_write(eff, 32, rc)
    return rc
end

fn noksha_effect_get_run_count(eff)
    if eff <= 0
        return 0
    end
    return mem_read(eff, 32)
end

fn noksha_effect_destroy(eff)
    if eff <= 0
        return 0
    end
    free(eff, 40)
    return 1
end
