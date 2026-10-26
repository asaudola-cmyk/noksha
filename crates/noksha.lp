// ==============================================================================
// 👑 NOKSHA UNIVERSAL SOVEREIGN ENGINE: MASTER ENTRY POINT (crates/noksha.lp)
// ⚡ 100% Pure Raw LiPi | Silicon-to-Web Declarative UI/UX Engine
// ==============================================================================
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

// Master initialization of all Noksha engine subsystems
fn noksha_engine_init()
    noksha_core_init()
    noksha_rhi_init()
    noksha_canvas_init()
    noksha_layout_init()
    noksha_text_init()
    noksha_reactive_init()
    noksha_ui_init()
    return 1
end
