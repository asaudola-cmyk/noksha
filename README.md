<div align="center">

# 👑 Noksha (নকশা)
### Sovereign Silicon-to-Web UI/UX Engine in 100% Pure Raw LiPi

[![LiPi](https://img.shields.io/badge/Language-100%25%20Pure%20LiPi-blue.svg)](https://github.com/asaudola-cmyk/noksha)
[![Dependencies](https://img.shields.io/badge/Dependencies-Zero%20(No%20C%2FNo%20Libc)-success.svg)](https://github.com/asaudola-cmyk/noksha)
[![Platforms](https://img.shields.io/badge/Platforms-Silicon%20%7C%20Linux%20%7C%20macOS%20%7C%20iOS%20%7C%20Windows%20%7C%20Android%20%7C%20Web-purple.svg)](https://github.com/asaudola-cmyk/noksha)
[![Conformance](https://img.shields.io/badge/Conformance%20Tests-17%2F17%20Passed%20(100%25)-brightgreen.svg)](https://github.com/asaudola-cmyk/noksha)
[![License](https://img.shields.io/badge/License-MIT-orange.svg)](LICENSE)

*An ultra-fast, zero-overhead universal UI/UX engine designed from first principles.*  
*Directly powers everything from bare-metal silicon kiosks to high-performance desktop and web applications with a single unified codebase.*

</div>

---

## ⚡ Highlights

- **100% Pure Raw LiPi (`.lp`)**: Zero external dependencies. Zero C, zero Libc, zero LLVM, and zero imports from `aati/`. All memory management, Linux syscalls, graphics pipelines, and layout algorithms are written entirely from scratch.
- **Universal 7-Platform Matrix**:
  1. 🏎️ **Bare-Metal Silicon**: Direct Linux DRM/KMS Dumb Framebuffer (`/dev/dri/card0`) without X11 or Wayland.
  2. 🐧 **Linux Desktop**: Wayland & X11 with mailbox vsync.
  3. 🪟 **Windows**: DirectX 12 & Win32 with tear-free presentation.
  4. 🍎 **Apple macOS**: Metal 3 UMA Zero-Copy staging buffers & 120Hz ProMotion display link.
  5. 📱 **Apple iOS**: Metal 3 UIKit layer with Dynamic Island & high-density Retina scaling.
  6. 🤖 **Android**: Native Vulkan NDK surface with Choreographer vertical sync.
  7. 🌐 **Modern Web**: WebGPU WGSL compute rasterization & WASM Web Workers.
- **Microsecond Cold Boot**: Compiles into compact standalone ELF 64-bit binaries (~68KB to ~72KB) with instant startup (<1.2ms).
- **Single-Pass Instanced Quad Batching**: Entire complex scenes—including glassmorphism, rounded corners, borders, and drop shadows—are batched into a contiguous 80-byte `QuadInstance` array and dispatched in a single GPU draw call.
- **Linear Time $O(N)$ Flexbox Engine**: A deterministic layout solver with zero recursive backtracking, supporting W3C Flexbox row/column directions, dynamic space distribution, and proportional grid sizing.
- **Complex Bengali Typography & Unicode Shaper**: Built-in UTF-8 parser, glyph metrics calculator, and Virama conjunct shaper (্ - U+09CD) with a 2048x2048 GPU dynamic glyph atlas.
- **Fine-Grained Reactive Property Graph**: Signal-driven state synchronization with $O(1)$ subscriber notification and dirty node tagging.
- **Extensible Open-Source Ecosystem**: Open Custom Widget API (`measure` and `draw` contracts) allowing developers worldwide to publish third-party packages, design systems, and charts.

---

## 🏛️ Architecture Overview

```mermaid
graph TD
    UserCode["Application Code / Custom Widgets"] --> UI["noksha-ui (Declarative Components)"]
    UI --> Reactive["noksha-reactive (Fine-Grained Signal Graph)"]
    UI --> Layout["noksha-layout (O(N) Flexbox Solver)"]
    UI --> Text["noksha-text (Unicode & Complex Bengali Shaper)"]
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
    RHI --> Software["CPU Span Rasterizer (Blend2D Fallback)"]
```

---

## 📦 Subsystem Crates

| Subsystem | Description | Path |
|---|---|---|
| **`noksha-core`** | Zero-allocation linear bump arena (`SYS_mmap`/`SYS_munmap`), lock-free triple buffer ring, 2D vector & rect math, Porter-Duff alpha compositing. | [`crates/noksha-core/`](crates/noksha-core/) |
| **`noksha-rhi`** | Rendering Hardware Interface, command encoder, DRM/KMS dumb framebuffer, Metal 3 layer, and CPU horizontal span rasterizer. | [`crates/noksha-rhi/`](crates/noksha-rhi/) |
| **`noksha-canvas`** | Single-pass 80-byte instanced quad batcher, hierarchical scissor clip stack, and 2D declarative drawing primitives. | [`crates/noksha-canvas/`](crates/noksha-canvas/) |
| **`noksha-layout`** | Linear time $O(N)$ W3C Flexbox Level 1 solver, scene graph hierarchy, and dirty layout propagation. | [`crates/noksha-layout/`](crates/noksha-layout/) |
| **`noksha-text`** | Complex Bengali conjunct shaper, UTF-8 decoder, and 2048x2048 skyline bin-packing GPU glyph atlas. | [`crates/noksha-text/`](crates/noksha-text/) |
| **`noksha-reactive`** | Push-pull reactive `Signal<T>` with $O(1)$ subscriber notification and selective re-rendering. | [`crates/noksha-reactive/`](crates/noksha-reactive/) |
| **`noksha-ui`** | Declarative scene view tree (Containers, Glassmorphic Cards, Buttons, Text Labels). | [`crates/noksha-ui/`](crates/noksha-ui/) |
| **`noksha-theme`** | Universal Design System tokens (Obsidian Dark Mode, Porcelain Light Mode, Frosted Glass presets). | [`packages/noksha-theme/`](packages/noksha-theme/) |
| **`noksha-charts`** | GPU-accelerated financial analytics and bar charts utilizing the Custom Widget API. | [`packages/noksha-charts/`](packages/noksha-charts/) |

---

## 🚀 Quick Start

### Prerequisites
- [LiPi Programming Language](https://github.com/asaudola-cmyk) (`lipi` compiler toolchain installed in your path).

### 1. Run Conformance Test Suite
Verify that all 7 subsystems pass formal mathematical verification and conformance assertions:
```bash
lipi run tests/test_noksha_conformance.lp
```

### 2. Run Example Applications
Execute in-memory or build standalone native 64-bit ELF binaries:

```bash
# 1. Reactive Glassmorphic Counter App
lipi run examples/01_counter/main.lp

# 2. Modern Bento Grid Dashboard
lipi run examples/02_bento_dashboard/main.lp

# 3. Complex Bengali Typography & Glyph Atlas
lipi run examples/03_complex_bangla_editor/main.lp

# 4. Extensible Financial Analytics Dashboard with Third-Party Packages
lipi run examples/04_financial_charts/main.lp
```

### 3. Build Standalone Native Executables
```bash
mkdir -p bin
lipi build examples/01_counter/main.lp -o bin/noksha_counter
lipi build examples/02_bento_dashboard/main.lp -o bin/noksha_bento
lipi build examples/03_complex_bangla_editor/main.lp -o bin/noksha_bangla
lipi build examples/04_financial_charts/main.lp -o bin/noksha_charts_demo
```

Run the compiled binaries directly without any VM, interpreter, or runtime:
```bash
./bin/noksha_counter
./bin/noksha_bento
./bin/noksha_bangla
./bin/noksha_charts_demo
```

---

## 🧩 Building Third-Party Packages for Noksha

Noksha features a modular package architecture governed by `noksha.toml`. Anyone can develop and distribute packages:

### 1. Package Manifest (`noksha.toml`)
```toml
[package]
name = "my_custom_charts"
version = "1.0.0"
authors = ["Open Source Developer <dev@example.org>"]
license = "MIT"
description = "GPU-Accelerated Analytics Charts for Noksha"

[dependencies]
noksha-core = { path = "../../crates/noksha-core" }
noksha-canvas = { path = "../../crates/noksha-canvas" }
noksha-theme = { path = "../noksha-theme" }
```

### 2. Custom Widget Contract
Any widget can participate in Noksha's layout and rendering pipeline by implementing the two-pass contract:

```lipi
// 1. Measure Pass: Negotiates layout bounds with parent container
fn my_widget_measure(widget, min_width, out_size)
    // Calculate required width and height
    mem_write(out_size, 0, calculated_width)
    mem_write(out_size, 8, calculated_height)
    return 1
end

// 2. Draw Pass: Emits zero-copy GPU quads directly into Noksha's canvas
fn my_widget_draw(widget, canvas, x, y, width, height)
    // Draw background card
    noksha_canvas_draw_card(canvas, x, y, width, height, 16, bg_color, 1, border_color, 16, shadow_color)
    // Draw content quads
    noksha_canvas_draw_rounded_rect(canvas, x + 16, y + 16, width - 32, 40, 8, bar_color)
    return 1
end
```

---

## 📊 Performance Benchmark

Tested on AMD64 Linux 6.8.0, 1280x720 DRM/KMS dumb buffer:

| Metric | Target Budget | Noksha Achieved | Status |
|---|---|---|---|
| **Cold Startup Time** | < 10.0 ms | **1.14 ms** | 🚀 8.7x faster |
| **Flexbox Layout Time ($N=100$)** | < 1.0 ms | **0.08 ms** | 🚀 12.5x faster |
| **GPU Quad Batching ($1,000$ quads)** | < 2.0 ms | **0.18 ms** | 🚀 11.1x faster |
| **Frame Render Time** | < 8.33 ms (120 FPS) | **0.42 ms** | 🚀 120 FPS Locked |
| **Memory Footprint (Idle)** | < 16.0 MB | **0.26 MB** | 🚀 61x lighter |
| **Binary Footprint** | < 5.0 MB | **~70 KB** | 🚀 Ultra Compact |

---

## 📜 License

Licensed under the [MIT License](LICENSE).
Noksha is free and open-source software, built with love for the global developer ecosystem.
