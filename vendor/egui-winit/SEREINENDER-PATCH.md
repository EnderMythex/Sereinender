# Window-drag repaints

Source: GitHub `emilk/egui`, commit `4821fc54ae083ac516e137a61e70550330e55169`, path `crates/egui-winit` (`egui-winit` 0.36.2, MIT OR Apache-2.0). Retains upstream source, manifest provenance (`Cargo.toml.orig`) and both license files.

The manifest is de-workspaced (explicit versions from the egui workspace root) and its `egui` dependency points at the same git revision as the Sereinender workspace so Cargo unifies it into one crate. The drag changes in `src/lib.rs` apply on Windows and Linux (raw motion on every platform):

- `State::on_window_event`: on every platform except macOS (where eframe already handles `Moved` for live resize), a new arm replaces the immediate `WindowEvent::Moved(_)` repaint with a delayed 500 ms repaint, so a final placement/monitor sample occurs even without subsequent client input.
- `State::on_mouse_motion`: raw `DeviceEvent::MouseMotion` is no longer forwarded as `egui::Event::MouseMoved` and never requests a repaint. Sereinender reads neither that event nor `PointerState::motion`; `Response::drag_motion` falls back to pointer deltas.

Why (Windows): dragging the custom title strip enters the OS modal move loop. Every `WM_WINDOWPOSCHANGED` became a repaint, and raw input kept arriving during the loop: each motion event requested a repaint, and any frame that received the forwarded events requested the next one (`InputState::wants_repaint_after`). The loop dispatches `WM_PAINT` synchronously, so the full UI pass ran and the `PresentMode::Fifo` present blocked on vsync before the loop could advance — the window moved at most once per refresh and trailed the cursor. Moving a window leaves its contents unchanged, so neither repaint was needed; with either change alone the drag stays paced at the refresh rate. Sereinender's workspace `Cargo.lock` controls resolution.

Why (Linux): the custom header bar hands the drag to the window manager (`_NET_WM_MOVERESIZE` on X11, `xdg_toplevel.move` on Wayland). On X11 every `ConfigureNotify` became a `Moved` repaint, and raw XInput2 / relative-pointer motion kept arriving while the cursor stayed inside the moving window. The window manager swallows the release, so egui-winit also kept a button marked down and forwarded raw motion from anywhere on screen until the next click. Each of those repaints ran the full UI pass, the rounded-corner pass and a `Fifo` present, competing with the compositor for every step of the drag.

Upstream tracks the symptom as [emilk/egui#3953](https://github.com/emilk/egui/issues/3953) (open, no fix). Remove this patch when an upstream egui release stops repainting on window moves and raw motion during OS drags, or at the next egui bump if upstream adopts an equivalent change.

Review follow-up also treats empty clipboard text as absent so image paste can fall back, and logs image-copy success only on success. Other platform input behavior is inherited from the pinned upstream revision, including the macOS latest-scroll-event momentum heuristic; event-specific momentum correlation is outside this Windows drag patch.
