// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Package: noksha-reactive
// Module: lib
// Purpose: Reactive state management library aggregator.
include "crates/noksha-reactive/src/signal.lp"

fn noksha_reactive_init()
    noksha_reactive_ensure_init()
    return 1
end
