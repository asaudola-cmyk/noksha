// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Package: noksha-pal
// Module: lib
// Purpose: Platform Abstraction Layer (PAL), input event system, and gesture arena.
//
// WHY: Bare-metal DRM, Wayland, Windows Win32, and macOS Cocoa all generate platform-native
// raw input events. Noksha PAL normalizes them into unified PointerEvents and passes them
// through the gesture arena to disambiguate user interactions.

include "crates/noksha-pal/src/arena_gesture.lp"

fn noksha_pal_init()
    return 1
end
