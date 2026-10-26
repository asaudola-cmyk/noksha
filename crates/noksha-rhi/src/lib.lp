// ==============================================================================
// 👑 NOKSHA RHI: ROOT AGGREGATOR MODULE (crates/noksha-rhi/src/lib.lp)
// ⚡ 100% Pure Raw LiPi | Render Hardware Interface & Backend Pipeline
// ==============================================================================

include "crates/noksha-rhi/src/rhi.lp"
include "crates/noksha-rhi/src/command.lp"
include "crates/noksha-rhi/src/backend/drm_kms/dumb_buffer.lp"
include "crates/noksha-rhi/src/backend/metal/mtl_layer.lp"
include "crates/noksha-rhi/src/backend/software/span_raster.lp"

fn noksha_rhi_init()
    return 1
end
