// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Package: noksha-core
// Module: lib
// Purpose: Core foundation library aggregator.
include "crates/noksha-core/src/memory/arena.lp"
include "crates/noksha-core/src/memory/ring.lp"
include "crates/noksha-core/src/math/vec2.lp"
include "crates/noksha-core/src/math/rect.lp"
include "crates/noksha-core/src/math/color.lp"

// Core initialization and subsystem verification
fn noksha_core_init()
    return 1
end
