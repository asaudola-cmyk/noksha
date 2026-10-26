// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Package: noksha
// Module: root
// Purpose: Master entry point aggregating all Noksha engine subsystems.
//
// Noksha is a zero-dependency, silicon-to-web universal UI/UX engine written in
// 100% pure raw LiPi. It unifies bare-metal Linux DRM/KMS, Linux Wayland/X11,
// Windows DirectX 12, Apple Metal 3 (macOS & iOS), Android NDK, and WebAssembly.

include "crates/noksha-core/src/lib.lp"
include "crates/noksha-rhi/src/lib.lp"
include "crates/noksha-canvas/src/lib.lp"
include "crates/noksha-layout/src/lib.lp"
include "crates/noksha-text/src/lib.lp"
include "crates/noksha-reactive/src/lib.lp"
include "crates/noksha-ui/src/lib.lp"
include "crates/noksha-pal/src/lib.lp"

// Master initialization of all Noksha engine subsystems
fn noksha_engine_init()
    noksha_core_init()
    noksha_rhi_init()
    noksha_canvas_init()
    noksha_layout_init()
    noksha_text_init()
    noksha_reactive_init()
    noksha_ui_init()
    noksha_pal_init()
    return 1
end
