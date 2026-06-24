# VNC desktop microVM (computer-use / GUI-agent envs)

A warm graphical desktop (`Xvfb` + `fluxbox` + `xterm`) served over **VNC**,
running inside a smolvm microVM. The point isn't the desktop — it's that you can
**fork a running desktop into a pixel-live clone in ~100 ms**, which makes
smolvm a compelling substrate for **computer-use / GUI-agent post-training**:
each RL episode gets an instant, isolated, warm desktop to reset to.

## Why a microVM (vs a container) for this
- **Isolation is the feature.** A computer-use agent takes arbitrary
  desktop/system actions — that's the training signal. In a microVM it can do
  anything inside and stay hardware-contained.
- **Fork = sub-150 ms env reset.** Boot a desktop once, freeze it as a *golden*
  base, then `machine fork` a fresh clone per episode (CoW memory + disks).
- **CoW memory sharing.** Clones share the golden's RAM pages, so N parallel
  desktops cost far less than N×.

## Run it

```bash
# 1. Create a machine whose persistent workload is the warm VNC desktop.
smolvm machine create --name desktop --smolfile Smolfile -p 5900:5900 \
    -- bash /work/desktop.sh

# 2. Start it as a fork base (memfd-backed RAM, control socket).
smolvm machine start --name desktop --forkable
#    init installs the desktop stack, then desktop.sh brings up Xvfb + x11vnc.

# 3. Connect a VNC client to localhost:5900  (RFB 003.008).

# 4. Per episode: fork an instant, pixel-live clone on a fresh port.
smolvm machine fork --golden desktop --name episode-1 -p 5901:5900
#    The golden freezes as the base; the clone is the live instance.
```

## Measured on Linux/KVM (the make-or-break experiment)

| What | Result |
| --- | --- |
| Desktop boots + serves VNC in a microVM | ✅ `RFB 003.008` on the forwarded port |
| `machine fork` of a *running* desktop → live VNC clone | ✅ X + x11vnc survived the CoW fork |
| Fork wall-time | **~100–140 ms** |
| 4 parallel clones from one golden | ✅ all live, each on its own port |
| RAM for 4 desktops | **~4 GB total** (CoW shares the golden's pages) |

So `env.reset()` becomes a ~120 ms fork to a warm, process-live desktop, with
many parallel envs from a single golden — the throughput profile RL post-training
wants.

## Notes / caveats
- **Fork is Linux/KVM only** (it CoW-maps guest RAM via `memfd`); on macOS/HVF
  use the desktop without fork-reset.
- `Xvfb` is software-rendered (no GPU needed). For accelerated rendering, run a
  real X on `--gpu` (virtio-gpu / Venus-Vulkan) — heavier and more finicky.
- This is a **local** PoC. Driving it at scale (remote VNC transport, fork-reset
  over the cloud API, fleet scheduling of goldens + clones, a gym-style harness)
  is the cloud work — see `docs` in the smolcloud repo.
- Once clones exist, do **not** restart the golden — it stays frozen as the base.
