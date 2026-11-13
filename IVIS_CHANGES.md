# IVIS integration changes

This is an additive integration over the supplied Reia source tree.

### Preserved
- Existing Reia Godot client/server structure.
- Existing ECS, combat, inventory, network and map systems.
- Existing maps, UI, assets and plugins.
- Existing Rust source and Git LFS tracking.

### Added
- `godot/ivis/` mobile-first playable layer.
- IVIS third-person controller and SpringArm camera.
- Reia GLB runtime loading with a fallback character if the LFS binary is unavailable.
- Touch joystick, photo mode, zoom, world switching and achievement controls.
- Four lightweight world regions with inactive-world processing disabled.
- Adaptive 3D render scale based on sustained FPS.
- IVIS branding and Android package/export metadata.
- `ivis-android.yml` GitHub Actions workflow.
