# IVIS

IVIS is the mobile-first game layer being developed on top of the existing Reia Godot project.

## What was added
- IVIS branded application metadata and Android export identity.
- A dedicated playable `godot/ivis/IVISWorld.tscn` scene.
- Third-person camera + spring-arm zoom.
- Reia GLB character loading with a lightweight fallback when Git LFS assets are not present.
- Touch joystick and mobile action buttons.
- Four lightweight world regions with active-world-only simulation.
- Adaptive 3D resolution based on sustained FPS.
- Photo Mode foundation.
- Persistent achievements and world progress.
- Existing Reia title screen and systems remain in the repository.

## Important
The large Reia character binary is tracked by Git LFS upstream. The ZIP of the source repository contains the LFS pointer unless the binary has been fetched separately. Run `git lfs pull` after cloning when you have access to the LFS object.

IVIS additions are layered on the Reia codebase; upstream license and attribution files are intentionally preserved.
