// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Package: noksha-text
// Module: shaper
// Purpose: UTF-8 complex text shaper with comprehensive Bengali Virama conjunct substitution and pre-base vowel reordering.
//
// WHY: In complex scripts such as Bengali, characters cannot be placed sequentially
// using simple ASCII advance tables. A complex text shaper must perform:
// 1. GSUB (Glyph Substitution): Identifies Virama (্) sequences, looks up multi-consonant
//    conjunct tables, consumes C1+Hasanta+C2 (+C3) completely, and synthesizes distinct glyph IDs.
// 2. Pre-Base Reordering: Shifts left-attaching vowels (ই-কার ি U+09BF, এ-কার ে U+09C7, ঐ-কার ৈ U+09C8)
//    to precede their consonant/conjunct cluster in visual X coordinates.
// 3. Coordinate Generation: Produces positioned glyph quads for GPU instanced rendering.

struct NokshaShapedGlyph
    glyph_id,
    x_pos,
    y_pos,
    width,
    height

struct NokshaGlyphRun
    glyphs_mem,
    capacity,
    glyph_count,
    total_advance_x

// ── 1. Create Glyph Run Container ─────────────────────────────────────────────
fn noksha_glyph_run_create(capacity)
    cap = capacity
    if cap <= 0
        cap = 256
    end

    // Each shaped glyph takes 40 bytes (5 fields * 8 bytes)
    mem_size = cap * 40
    glyphs_mem = malloc(mem_size)
    if glyphs_mem <= 0
        return 0
    end

    run = malloc(32)
    mem_write(run, 0, glyphs_mem)
    mem_write(run, 8, cap)
    mem_write(run, 16, 0) // count = 0
    mem_write(run, 24, 0) // total_advance = 0

    return run
end

fn noksha_glyph_run_count(run)
    if run <= 0
        return 0
    end
    return mem_read(run, 16)
end

fn noksha_glyph_run_advance(run)
    if run <= 0
        return 0
    end
    return mem_read(run, 24)
end

fn noksha_glyph_run_get_glyph_id(run, index)
    if run <= 0
        return 0
    end
    count = mem_read(run, 16)
    if index < 0 || index >= count
        return 0
    end
    glyphs_mem = mem_read(run, 0)
    return mem_read(glyphs_mem + (index * 40), 0)
end

fn noksha_glyph_run_get_x(run, index)
    if run <= 0
        return 0
    end
    glyphs_mem = mem_read(run, 0)
    return mem_read(glyphs_mem + (index * 40), 8)
end

fn noksha_glyph_run_get_y(run, index)
    if run <= 0
        return 0
    end
    glyphs_mem = mem_read(run, 0)
    return mem_read(glyphs_mem + (index * 40), 16)
end

// ── 2. UTF-8 Parser Helpers ───────────────────────────────────────────────────
fn noksha_utf8_step(text_str, str_len, i)
    if i >= str_len
        return 0
    end
    b0 = mem_read_byte(text_str, i)
    if b0 < 128
        return 1
    end
    if b0 >= 192 && b0 < 224
        return 2
    end
    if b0 >= 224 && b0 < 240
        return 3
    end
    if b0 >= 240
        return 4
    end
    return 1
end

fn noksha_utf8_codepoint(text_str, str_len, i)
    if i >= str_len
        return 0
    end
    b0 = mem_read_byte(text_str, i)
    if b0 < 128
        return b0
    end
    if b0 >= 192 && b0 < 224 && (i + 1) < str_len
        b1 = mem_read_byte(text_str, i + 1)
        return ((b0 & 31) * 64) + (b1 & 63)
    end
    if b0 >= 224 && b0 < 240 && (i + 2) < str_len
        b1 = mem_read_byte(text_str, i + 1)
        b2 = mem_read_byte(text_str, i + 2)
        return ((b0 & 15) * 4096) + ((b1 & 63) * 64) + (b2 & 63)
    end
    if b0 >= 240 && (i + 3) < str_len
        b1 = mem_read_byte(text_str, i + 1)
        b2 = mem_read_byte(text_str, i + 2)
        b3 = mem_read_byte(text_str, i + 3)
        return ((b0 & 7) * 262144) + ((b1 & 63) * 4096) + ((b2 & 63) * 64) + (b3 & 63)
    end
    return b0
end

// ── 3. Bengali Conjunct Table ──────────────────────────────────────────────────
fn noksha_bengali_conjunct_lookup(c1, c2)
    // ক্ + ষ (2453, 2487) -> ক্ষ
    if c1 == 2453 && c2 == 2487
        return 1001
    end
    // জ্ + ঞ (2460, 2462) -> জ্ঞ
    if c1 == 2460 && c2 == 2462
        return 1002
    end
    // ক্ + ত (2453, 2468) -> ক্ত
    if c1 == 2453 && c2 == 2468
        return 1003
    end
    // ক্ + ক (2453, 2453) -> ক্ক
    if c1 == 2453 && c2 == 2453
        return 1004
    end
    // ঙ্ + ক (2457, 2453) -> ঙ্ক
    if c1 == 2457 && c2 == 2453
        return 1005
    end
    // ঙ্ + গ (2457, 2455) -> ঙ্গ
    if c1 == 2457 && c2 == 2455
        return 1006
    end
    // চ্ + ছ (2458, 2459) -> চ্ছ
    if c1 == 2458 && c2 == 2459
        return 1007
    end
    // ঞ্ + চ (2462, 2458) -> ঞ্চ
    if c1 == 2462 && c2 == 2458
        return 1008
    end
    // ঞ্ + জ (2462, 2460) -> ঞ্জ
    if c1 == 2462 && c2 == 2460
        return 1009
    end
    // ট্ + ট (2463, 2463) -> ট্ট
    if c1 == 2463 && c2 == 2463
        return 1010
    end
    // ত্ + ত (2468, 2468) -> ত্ত
    if c1 == 2468 && c2 == 2468
        return 1011
    end
    // ত্ + থ (2468, 2469) -> ত্থ
    if c1 == 2468 && c2 == 2469
        return 1012
    end
    // ত্ + র (2468, 2480) -> ত্র
    if c1 == 2468 && c2 == 2480
        return 1013
    end
    // ন্ + ত (2472, 2468) -> ন্ত
    if c1 == 2472 && c2 == 2468
        return 1014
    end
    // ন্ + দ (2472, 2470) -> ন্দ
    if c1 == 2472 && c2 == 2470
        return 1015
    end
    // ন্ + ধ (2472, 2471) -> ন্ধ
    if c1 == 2472 && c2 == 2471
        return 1016
    end
    // ম্ + প (2478, 2474) -> ম্প
    if c1 == 2478 && c2 == 2474
        return 1017
    end
    // ম্ + ব (2478, 2476) -> ম্ব
    if c1 == 2478 && c2 == 2476
        return 1018
    end
    // ব্ + দ (2476, 2470) -> ব্দ
    if c1 == 2476 && c2 == 2470
        return 1019
    end
    // শ্ + চ (2486, 2458) -> শ্চ
    if c1 == 2486 && c2 == 2458
        return 1020
    end
    // ষ্ + ট (2487, 2463) -> ষ্ট
    if c1 == 2487 && c2 == 2463
        return 1021
    end
    // ষ্ + ঠ (2487, 2464) -> ষ্ঠ
    if c1 == 2487 && c2 == 2464
        return 1022
    end
    // ষ্ + ণ (2487, 2467) -> ষ্ণ
    if c1 == 2487 && c2 == 2467
        return 1023
    end
    // স্ + ত (2488, 2468) -> স্ত
    if c1 == 2488 && c2 == 2468
        return 1024
    end
    // স্ + থ (2488, 2469) -> স্থ
    if c1 == 2488 && c2 == 2469
        return 1025
    end
    // হ্ + ন (2489, 2472) -> হ্ন
    if c1 == 2489 && c2 == 2472
        return 1026
    end
    // হ্ + ম (2489, 2478) -> হ্ম
    if c1 == 2489 && c2 == 2478
        return 1027
    end
    // ন্ + ন (2472, 2472) -> ন্ন
    if c1 == 2472 && c2 == 2472
        return 1028
    end
    // প্ + র (2474, 2480) -> প্র
    if c1 == 2474 && c2 == 2480
        return 1029
    end
    // ক্ + র (2453, 2480) -> ক্র
    if c1 == 2453 && c2 == 2480
        return 1030
    end
    // ব্ + র (2476, 2480) -> ব্র
    if c1 == 2476 && c2 == 2480
        return 1031
    end
    // গ্ + র (2455, 2480) -> গ্র
    if c1 == 2455 && c2 == 2480
        return 1032
    end
    // দ্ + র (2470, 2480) -> দ্র
    if c1 == 2470 && c2 == 2480
        return 1033
    end
    // শ্ + র (2486, 2480) -> শ্র
    if c1 == 2486 && c2 == 2480
        return 1034
    end
    // ন্ + ড (2472, 2465) -> ন্ড
    if c1 == 2472 && c2 == 2465
        return 1035
    end
    // ল্ + ক (2482, 2453) -> ল্ক
    if c1 == 2482 && c2 == 2453
        return 1036
    end
    // ল্ + গ (2482, 2455) -> ল্গ
    if c1 == 2482 && c2 == 2455
        return 1037
    end
    // ল্ + প (2482, 2474) -> ল্প
    if c1 == 2482 && c2 == 2474
        return 1038
    end
    // ল্ + ল (2482, 2482) -> ল্ল
    if c1 == 2482 && c2 == 2482
        return 1039
    end

    // Distinct generic conjunct glyph ID for unlisted sequence
    return 40000 + ((c1 & 255) * 128) + (c2 & 127)
end

// ── 4. Complex Text Shaping Pass ──────────────────────────────────────────────
// Analyzes input string characters, handles multi-consonant conjuncts, reorders
// pre-base vowels (ি, ে, ৈ) before their consonant cluster, and computes positioned glyphs.
fn noksha_shape_text(run, text_str, font_size, default_char_w)
    if run <= 0 || text_str == 0
        return 0
    end

    glyphs_mem = mem_read(run, 0)
    cap = mem_read(run, 8)

    str_len = length(text_str)
    if str_len == 0
        return 0
    end

    char_w = default_char_w
    if char_w <= 0
        char_w = (font_size * 6) / 10
    end
    char_h = font_size

    cursor_x = 0
    count = 0
    i = 0
    prev_is_consonant = 0

    while i < str_len && count < cap
        cp1 = noksha_utf8_codepoint(text_str, str_len, i)
        step1 = noksha_utf8_step(text_str, str_len, i)

        if step1 <= 0
            step1 = 1
        end

        // Check for Bengali Pre-Base Vowel Signs:
        // Hrasva I-kar U+09BF (2495), E-kar U+09C7 (2503), AI-kar U+09C8 (2504)
        is_pre_base_vowel = 0
        if cp1 == 2495 || cp1 == 2503 || cp1 == 2504
            is_pre_base_vowel = 1
        end

        if is_pre_base_vowel == 1 && prev_is_consonant == 1 && count > 0
            // Reorder: Shift the preceding consonant cluster to the right,
            // placing the pre-base vowel at the cluster's original X position.
            prev_idx = count - 1
            cluster_ptr = glyphs_mem + (prev_idx * 40)
            c_glyph_id = mem_read(cluster_ptr, 0)
            c_x = mem_read(cluster_ptr, 8)
            c_y = mem_read(cluster_ptr, 16)
            c_adv = mem_read(cluster_ptr, 24)
            c_h = mem_read(cluster_ptr, 32)

            v_adv = (char_w * 9) / 10
            if v_adv <= 0
                v_adv = char_w
            end

            // Rewrite previous entry to become the pre-base vowel at c_x
            mem_write(cluster_ptr, 0, cp1)
            mem_write(cluster_ptr, 8, c_x)
            mem_write(cluster_ptr, 16, 0)
            mem_write(cluster_ptr, 24, v_adv)
            mem_write(cluster_ptr, 32, char_h)

            // Append the consonant cluster after the vowel at (c_x + v_adv)
            entry_ptr = glyphs_mem + (count * 40)
            mem_write(entry_ptr, 0, c_glyph_id)
            mem_write(entry_ptr, 8, c_x + v_adv)
            mem_write(entry_ptr, 16, c_y)
            mem_write(entry_ptr, 24, c_adv)
            mem_write(entry_ptr, 32, c_h)

            cursor_x = c_x + v_adv + c_adv
            count = count + 1
            prev_is_consonant = 0
            i = i + step1
        else
            // Check if cp1 is a consonant followed by Hasanta U+09CD (2509)
            is_conjunct = 0
            conjunct_glyph = 0
            total_bytes = step1

            if (i + step1) < str_len
                cp_h = noksha_utf8_codepoint(text_str, str_len, i + step1)
                if cp_h == 2509 // Hasanta / Virama
                    step_h = noksha_utf8_step(text_str, str_len, i + step1)
                    if (i + step1 + step_h) < str_len
                        cp2 = noksha_utf8_codepoint(text_str, str_len, i + step1 + step_h)
                        step2 = noksha_utf8_step(text_str, str_len, i + step1 + step_h)

                        // Check for 3-consonant conjunct: C1 + H + C2 + H + C3
                        is_3_conjunct = 0
                        offset3 = i + step1 + step_h + step2
                        if offset3 < str_len
                            cp_h2 = noksha_utf8_codepoint(text_str, str_len, offset3)
                            if cp_h2 == 2509
                                step_h2 = noksha_utf8_step(text_str, str_len, offset3)
                                if (offset3 + step_h2) < str_len
                                    cp3 = noksha_utf8_codepoint(text_str, str_len, offset3 + step_h2)
                                    step3 = noksha_utf8_step(text_str, str_len, offset3 + step_h2)

                                    if cp1 == 2488 && cp2 == 2468 && cp3 == 2480 // স্ত্র
                                        conjunct_glyph = 1040
                                        is_3_conjunct = 1
                                    end
                                    if cp1 == 2487 && cp2 == 2463 && cp3 == 2480 // ষ্ট্র
                                        conjunct_glyph = 1041
                                        is_3_conjunct = 1
                                    end
                                    if cp1 == 2453 && cp2 == 2487 && cp3 == 2478 // ক্ষ্ম
                                        conjunct_glyph = 1042
                                        is_3_conjunct = 1
                                    end

                                    if is_3_conjunct == 1
                                        is_conjunct = 1
                                        total_bytes = step1 + step_h + step2 + step_h2 + step3
                                    end
                                end
                            end
                        end

                        if is_conjunct == 0
                            // 2-consonant conjunct: C1 + Hasanta + C2
                            conjunct_glyph = noksha_bengali_conjunct_lookup(cp1, cp2)
                            is_conjunct = 1
                            total_bytes = step1 + step_h + step2
                        end
                    end
                end
            end

            entry_ptr = glyphs_mem + (count * 40)
            glyph_id = cp1
            adv = char_w

            if is_conjunct == 1
                glyph_id = conjunct_glyph
                adv = (char_w * 13) / 10 // Slightly wider advance for conjunct
                prev_is_consonant = 1
            else
                // Track if cp1 is a consonant (U+0995 to U+09B9 or U+09DC to U+09DF)
                if (cp1 >= 2453 && cp1 <= 2489) || (cp1 >= 2524 && cp1 <= 2527)
                    prev_is_consonant = 1
                else
                    prev_is_consonant = 0
                end
            end

            mem_write(entry_ptr, 0, glyph_id)
            mem_write(entry_ptr, 8, cursor_x)
            mem_write(entry_ptr, 16, 0)
            mem_write(entry_ptr, 24, adv)
            mem_write(entry_ptr, 32, char_h)

            cursor_x = cursor_x + adv
            count = count + 1
            i = i + total_bytes
        end
    end

    mem_write(run, 16, count)
    mem_write(run, 24, cursor_x)
    return count
end

fn noksha_glyph_run_destroy(run)
    if run <= 0
        return 0
    end
    glyphs_mem = mem_read(run, 0)
    cap = mem_read(run, 8)
    if glyphs_mem > 0
        free(glyphs_mem, cap * 40)
    end
    free(run, 32)
    return 1
end
