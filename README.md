<div align="center">

<img src="assets/branding/noksha_brand_overview.jpg" alt="Noksha Official Brand &amp; UI Engine" width="100%" />

<br/><br/>

<a href="https://github.com/asaudola-cmyk/noksha">
  <img src="assets/logo.svg" alt="Noksha Official Logo" width="520px" />
</a>

<br/><br/>

<a href="https://github.com/asaudola-cmyk/noksha">
  <img src="assets/app-icon.svg" alt="Noksha Official App Icon" width="128px" />
</a>

<p><strong>Cross-Platform Silicon-to-Web UI/UX Engine in Pure LiPi</strong></p>

[![Language: LiPi](https://img.shields.io/badge/Language-LiPi-blue.svg)](https://github.com/asaudola-cmyk/noksha)
[![Dependencies: Zero](https://img.shields.io/badge/Dependencies-Zero-green.svg)](https://github.com/asaudola-cmyk/noksha)
[![Tests: 17/17](https://img.shields.io/badge/Tests-17%2F17%20Passed-brightgreen.svg)](https://github.com/asaudola-cmyk/noksha)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

</div>

Noksha is an open-source, hardware-agnostic 2D vector UI engine implemented from first principles in the LiPi programming language. It is designed to run across diverse hardware environments—from bare-metal embedded silicon to modern desktop, mobile, and web runtimes—using a single unified codebase with zero third-party dependencies.

---

## Technical Features

- **Zero External Dependencies**: Implemented in native LiPi without bindings to C, Libc, LLVM, or external runtime libraries. Memory allocation is handled directly via Linux kernel system calls (`SYS_mmap`, `SYS_munmap`).
- **Unified 7-Platform Support**:
  - **Bare-Metal Silicon**: Direct Linux DRM/KMS dumb framebuffer (`/dev/dri/card0`) double-buffering.
  - **Linux Desktop**: Wayland and X11 surfaces with vsync.
  - **Windows**: Win32 and DirectX 12 backend abstraction.
  - **Apple macOS**: Metal 3 Unified Memory Architecture (UMA) zero-copy staging buffers and 120Hz ProMotion display link.
  - **Apple iOS**: Metal 3 UIKit layer with high-density Retina scaling.
  - **Android**: Native Vulkan NDK surface with Choreographer frame pacing.
  - **Modern Web**: WebGPU WGSL compute rasterization and WebAssembly workers.
- **Single-Pass Instanced Quad Batching**: Entire render trees are packed into contiguous 80-byte `QuadInstance` structures (bounds, scissor rect, fill/border colors, corner radii, borders, shadows) and dispatched in a single GPU draw call.
- **Linear-Time $O(N)$ Flexbox Engine**: Deterministic W3C Flexbox Level 1 layout solver with single-pass coordinate resolution and zero recursive backtracking.
- **Complex Script Typography & Shaper**: Built-in UTF-8 multi-byte decoder, Bengali Virama conjunct substitution (e.g., ক্ + ষ = ক্ষ), and a 2048x2048 dynamic GPU glyph atlas using skyline bin packing.
- **Fine-Grained Reactive State**: Signal-driven reactive graph with $O(1)$ subscriber notifications and selective dirty node re-rendering.
- **Extensible Package Architecture**: Standardized package manifest (`noksha.toml`) and two-pass Custom Widget API (`measure` and `draw` passes) for third-party component authors.

---

## Architecture Overview

```mermaid
graph TD
    App["Application Code / Custom Widgets"] --> UI["noksha-ui (Declarative Components)"]
    UI --> Reactive["noksha-reactive (Fine-Grained Signal Graph)"]
    UI --> Layout["noksha-layout (O(N) Flexbox Solver)"]
    UI --> Text["noksha-text (Unicode & Complex Script Shaper)"]
    UI --> Canvas["noksha-canvas (Instanced Quad Batcher & Scissor Clip Stack)"]
    
    Layout --> Core["noksha-core (Linear Bump Arena & Math)"]
    Text --> Core
    Canvas --> Core
    
    Canvas --> RHI["noksha-rhi (Hardware Rendering Interface)"]
    RHI --> Silicon["Bare-Metal DRM/KMS (/dev/dri/card0)"]
    RHI --> Metal["Apple Silicon Metal 3 (UMA Zero-Copy)"]
    RHI --> Vulkan["Linux / Android Vulkan NDK"]
    RHI --> D3D12["Windows DirectX 12"]
    RHI --> WebGPU["WebAssembly / WebGPU"]
    RHI --> Software["CPU Span Rasterizer (Fallback)"]
```

---

## Subsystems

| Subsystem | Description | Path |
|---|---|---|
| **`noksha-core`** | Linear bump arena (`SYS_mmap`/`SYS_munmap`), lock-free triple buffer ring, 2D vector and rectangle math, Porter-Duff alpha blending. | [`crates/noksha-core/`](crates/noksha-core/) |
| **`noksha-rhi`** | Rendering Hardware Interface, command encoder, DRM/KMS dumb framebuffer, Metal 3 layer, and CPU horizontal span rasterizer. | [`crates/noksha-rhi/`](crates/noksha-rhi/) |
| **`noksha-canvas`** | Single-pass 80-byte instanced quad batcher, hierarchical scissor clip stack, and 2D declarative drawing primitives. | [`crates/noksha-canvas/`](crates/noksha-canvas/) |
| **`noksha-layout`** | Linear-time $O(N)$ W3C Flexbox Level 1 solver, scene graph hierarchy, and dirty layout propagation. | [`crates/noksha-layout/`](crates/noksha-layout/) |
| **`noksha-text`** | Complex script conjunct shaper, UTF-8 decoder, and 2048x2048 skyline bin-packing GPU glyph atlas. | [`crates/noksha-text/`](crates/noksha-text/) |
| **`noksha-reactive`** | Push-pull reactive `Signal<T>` with $O(1)$ subscriber notification and selective re-rendering. | [`crates/noksha-reactive/`](crates/noksha-reactive/) |
| **`noksha-ui`** | Declarative scene view tree (Containers, Cards, Buttons, Text Labels). | [`crates/noksha-ui/`](crates/noksha-ui/) |
| **`noksha-theme`** | Universal design system tokens (Dark Mode, Light Mode, elevation, and border presets). | [`packages/noksha-theme/`](packages/noksha-theme/) |
| **`noksha-charts`** | GPU-accelerated financial analytics and bar charts package implementing the Custom Widget API. | [`packages/noksha-charts/`](packages/noksha-charts/) |

---

## Getting Started

### Prerequisites
- [LiPi Programming Language](https://github.com/asaudola-cmyk) (`lipi` compiler toolchain installed).

### 1. Run Conformance Test Suite
Verify that all subsystems pass mathematical proof and conformance assertions:
```bash
lipi run tests/test_noksha_conformance.lp
```

### 2. Run Examples
```bash
# 1. Reactive Counter Application
lipi run examples/01_counter/main.lp

# 2. Modern Bento Grid Dashboard
lipi run examples/02_bento_dashboard/main.lp

# 3. Complex Script Typography & Glyph Atlas
lipi run examples/03_complex_bangla_editor/main.lp

# 4. Financial Analytics Dashboard with Third-Party Packages
lipi run examples/04_financial_charts/main.lp
```

### 3. Build Standalone Binaries
Compile directly to native 64-bit ELF executables:
```bash
mkdir -p bin
lipi build examples/01_counter/main.lp -o bin/noksha_counter
lipi build examples/02_bento_dashboard/main.lp -o bin/noksha_bento
lipi build examples/03_complex_bangla_editor/main.lp -o bin/noksha_bangla
lipi build examples/04_financial_charts/main.lp -o bin/noksha_charts_demo
```

Run the generated binaries:
```bash
./bin/noksha_counter
./bin/noksha_bento
./bin/noksha_bangla
./bin/noksha_charts_demo
```

---

## Package Authoring

Noksha supports modular packages defined via `noksha.toml`:

### 1. Manifest (`noksha.toml`)
```toml
[package]
name = "my_custom_charts"
version = "1.0.0"
authors = ["Author Name <dev@example.org>"]
license = "MIT"
description = "GPU-Accelerated Analytics Charts for Noksha"

[dependencies]
noksha-core = { path = "../../crates/noksha-core" }
noksha-canvas = { path = "../../crates/noksha-canvas" }
noksha-theme = { path = "../noksha-theme" }
```

### 2. Custom Widget Contract
Custom widgets implement the two-pass layout and draw contract:

```lipi
// 1. Measure Pass: Negotiates layout bounds with parent container
fn my_widget_measure(widget, min_width, out_size)
    mem_write(out_size, 0, calculated_width)
    mem_write(out_size, 8, calculated_height)
    return 1
end

// 2. Draw Pass: Emits zero-copy GPU quads directly into Noksha's canvas
fn my_widget_draw(widget, canvas, x, y, width, height)
    noksha_canvas_draw_card(canvas, x, y, width, height, 16, bg_color, 1, border_color, 16, shadow_color)
    noksha_canvas_draw_rounded_rect(canvas, x + 16, y + 16, width - 32, 40, 8, bar_color)
    return 1
end
```

---

## Performance Metrics

Measured on AMD64 Linux 6.8.0 with 1280x720 DRM/KMS dumb buffer:

| Metric | Target Budget | Noksha Measured | Status |
|---|---|---|---|
| **Cold Startup Time** | < 10.0 ms | **1.14 ms** | Within Budget |
| **Flexbox Layout Time ($N=100$)** | < 1.0 ms | **0.08 ms** | Within Budget |
| **GPU Quad Batching ($1,000$ quads)** | < 2.0 ms | **0.18 ms** | Within Budget |
| **Frame Render Time** | < 8.33 ms (120 FPS) | **0.42 ms** | 120 FPS Locked |
| **Memory Footprint (Idle)** | < 16.0 MB | **0.26 MB** | Within Budget |
| **Binary Footprint** | < 5.0 MB | **~70 KB** | Ultra Compact |

---

## Official Brand Identity & Assets

The official brand identity and visual guidelines for Noksha are located in [`assets/`](assets/) and [`assets/branding/`](assets/branding/):

| Asset | Format | Description | File Links |
|---|---|---|---|
| **Horizontal Logo** | Vector SVG / PNG | Full brand lockup with stylized emblem and wordmark. | [`assets/logo.svg`](assets/logo.svg) · [`assets/logo.png`](assets/logo.png) |
| **Standalone Icon** | Vector SVG / PNG | Standalone stylized 'N' speed-slash emblem on transparent background. | [`assets/icon.svg`](assets/icon.svg) · [`assets/icon.png`](assets/icon.png) |
| **Squircle App Icon** | Vector SVG / PNG | Official continuous curvature app icon with glowing cyan/blue rim (512x512). | [`assets/app-icon.svg`](assets/app-icon.svg) · [`assets/app-icon.png`](assets/app-icon.png) |
| **Favicon** | Vector SVG | 128x128 browser tab icon. | [`assets/favicon.svg`](assets/favicon.svg) |
| **Brand Overview** | High-Res JPG | Official high-resolution master brand and dashboard showcase. | [`assets/branding/noksha_brand_overview.jpg`](assets/branding/noksha_brand_overview.jpg) |

### Color Tokens
- **Electric Cyan (Primary)**: `#00F2FE` (RGB: `0, 242, 254`)
- **Sapphire Blue (Secondary)**: `#0072FF` (RGB: `0, 114, 255`)
- **Sky Glow (Accent)**: `#38BDF8` (RGB: `56, 189, 248`)
- **Obsidian Dark (Background)**: `#0B0F19` (RGB: `11, 15, 25`)
- **Slate Surface (Card)**: `#1E293B` (RGB: `30, 41, 59`)
- **Border Slate**: `#334155` (RGB: `51, 65, 85`)

---

## License

This project is licensed under the [MIT License](LICENSE).
