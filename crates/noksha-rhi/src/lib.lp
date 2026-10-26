// Copyright (c) 2026 Noksha Authors. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.
//
// Package: noksha-rhi
// Module: lib
// Purpose: Rendering hardware interface library aggregator.
include "crates/noksha-rhi/src/rhi.lp"
include "crates/noksha-rhi/src/command.lp"
include "crates/noksha-rhi/src/backend/drm_kms/dumb_buffer.lp"
include "crates/noksha-rhi/src/backend/metal/mtl_layer.lp"
include "crates/noksha-rhi/src/backend/software/span_raster.lp"

fn noksha_rhi_init()
    return 1
end
