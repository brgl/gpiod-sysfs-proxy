# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## Project overview

`gpiod-sysfs-proxy` is a single-file Python FUSE daemon that emulates the
Linux kernel GPIO sysfs interface (`/sys/class/gpio`) using the modern
`libgpiod` character device API. It mounts a virtual filesystem over
`/sys/class/gpio` so legacy applications that use the deprecated sysfs
interface continue to work on kernels where sysfs GPIO support is disabled.

## Installation and running

```bash
# Install (editable)
pip install -e .

# Mount (recommended options)
gpiod-sysfs-proxy <mountpoint> -o allow_other -o default_permissions

# Foreground / debug
gpiod-sysfs-proxy <mountpoint> -f
gpiod-sysfs-proxy <mountpoint> -d
```

There is no test suite. The script must run as root (or with appropriate
capabilities) to mount FUSE filesystems.

## Architecture

The entire implementation lives in a single script: `gpiod-sysfs-proxy`.

### Virtual filesystem tree

The filesystem is built from a hierarchy of `Entry` subclasses that map
directly to sysfs nodes:

- `Entry` — base class; default implementations raise the appropriate FUSE
  errno
  - `Directory` — holds a `children` dict; `lookup`/`readdir` delegate to it
    - `Root` — the filesystem root; owns `RangeManager`, `EventThread`, and
      the udev observer; creates `Gpiochip` entries on hotplug
    - `Gpiochip` — `/gpiochipN` directory; wraps a `gpiod.Chip`; creates
      `Gpio` entries on `export`
    - `Gpio` — `/gpioN` directory; wraps a `gpiod.LineRequest`; owns
      `direction`, `edge`, `active_low`, `value` attributes
  - `Attribute` — base for regular files
    - `ConstRoAttr` — read-only file returning a fixed string
    - `RwAttr` — read-write file; subclasses implement `do_write`
      - `RwAttrWithVal` — `RwAttr` with an in-memory value; base for
        `DirectionAttr`, `EdgeAttr`, `ActiveLowAttr`, `ValueAttr`
      - `ExportBase` / `Export` / `Unexport` — write-only files that
        export/unexport GPIO lines
      - `UeventAttr` — accepts uevent-style write commands, validated by
        regex
  - `Link` — symlink to a path in the real sysfs

### FUSE operations layer

`GpioSysfsOperations(pyfuse3.Operations)` is the pyfuse3 entry point. It
maintains two maps:

- `_inode_map`: inode → `Entry`; populated lazily via `_register_tree` on
  `lookup`/`readdir`
- `_fh_map`: file-handle → `Entry`; allocated in `open`, freed in `release`

It runs under `trio` (async): `trio.run(pyfuse3.main)`.

### GPIO base number allocation

`RangeManager` allocates non-overlapping integer ranges for GPIO chip base
numbers, starting at 512. When a chip is added via udev it gets
`get_new_base(num_lines)`; when removed, `free_range(base)` reclaims the
slot.

### Edge event / poll support

`EventThread` is a background `threading.Thread` that uses `select()` to
watch the file descriptor of each active `gpiod.LineRequest`. When an edge
event arrives it calls `ValueAttr.notify_poll()`, which triggers the FUSE
poll handle so userspace `POLLPRI` behaves like the kernel sysfs interface.

### Hotplug

`Root._setup_udev()` creates a `pyudev.MonitorObserver` filtering on the
`gpio` subsystem. `add` events call `_add_chip`; `remove` events call
`_remove_chip` (which also cleans up any exported `Gpio` children of the
removed chip).
