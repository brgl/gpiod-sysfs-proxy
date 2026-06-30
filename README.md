<!-- SPDX-License-Identifier: MIT -->
<!-- SPDX-FileCopyrightText: 2024 Bartosz Golaszewski <bartosz.golaszewski@linaro.org> -->

# gpiod-sysfs-proxy

[libgpiod](https://git.kernel.org/pub/scm/libs/libgpiod/libgpiod.git/)-based
compatibility layer for the linux GPIO sysfs interface.

It uses [FUSE](https://www.kernel.org/doc/html/v6.3/filesystems/fuse.html)
(Filesystem in User Space) in order to expose a filesystem that can be mounted
over `/sys/class/gpio` to simulate the kernel interface.

## Running

Running the script with a mountpoint parameter will mount the simulated gpio
class directory and then exit. The script can also be run with `-f` or `-d`
switches for foreground or debug operation respectively.

The recommended command-line mount options to use are:

```
gpiod-sysfs-proxy <mountpoint> -o allow_other -o default_permissions
```

This allows non-root users to access the filesystem and enables permission
checks by the kernel.

For a complete list of available command-line options, please run:

```
gpiod-sysfs-proxy --help
```

## Integration

### systemd

The package installs a systemd template unit:

```
gpiod-sysfs-proxy@.service
```

No instance is enabled by default. The instance name is the
systemd-escaped mountpoint. To expose the compatibility filesystem at
`/run/gpio`:

```
systemctl enable --now gpiod-sysfs-proxy@run-gpio.service
```

or, to mount over `/sys/class/gpio` (only works when that directory already
exists, i.e. the kernel sysfs GPIO interface is enabled):

```
systemctl enable --now gpiod-sysfs-proxy@sys-class-gpio.service
```

You can generate the escaped instance name for any path with:

```
systemd-escape --path /run/gpio
systemd-escape --path /sys/class/gpio
```

The `sys-class-gpio` instance also works on a kernel where sysfs GPIO support
is disabled (so `/sys/class/gpio` does not exist): an instance-specific drop-in
pulls in the bundled `run-gpio-sys.mount` and `sys-class.mount` units, which
overlay the missing `gpio` directory onto `/sys/class` before the proxy starts
and tear it back down when the instance is stopped. Nothing else enables those
mounts, and they are skipped when `/sys/class/gpio` already exists. See the
[Non-existent `/sys/class/gpio`](#non-existent-sysclassgpio) caveat below for
the underlying mechanism.

## Caveats

Due to how FUSE works, there are certain limitations to the level of
compatibility we can assure as well as some other issues the user may need
to have to work around.

### Non-existent `/sys/class/gpio`

If the GPIO sysfs interface is disabled in Kconfig, the `/sys/class/gpio`
directory will not exist and the user-space can't create directories inside
of sysfs. There are two solutions: either the user can use a different
mountpount or - for full backward compatibility - they can use overlayfs on
top of `/sys/class` providing the missing `gpio` directory.

Example:

```
mkdir -p /run/gpio/sys /run/gpio/class/gpio /run/gpio/work
mount -t sysfs sysfs /run/gpio/sys
mount -t overlay overlay -o lowerdir=/run/gpio/sys/class,upperdir=/run/gpio/class,workdir=/run/gpio/work,ro
gpiod-sysfs-proxy /sys/class/gpio <options>
```

### Links in `/sys/class/gpio`

The kernel sysfs interface at `/sys/class/gpio` contains links to directories
living elsewhere (specifically: under the relevant device entries) in sysfs.
For obvious reasons we cannot replicate that so, instead we expose actual
directories representing GPIO chips and exported GPIO lines.

### Polling of the `value` attribute

We currently don't support multiple users polling the `value` attribute at
once. Also: unlike the kernel interface, reading from `value` will not block
after the value has been read once.

### Static GPIO base number

Some legacy GPIO drivers hard-code the base GPIO number. We don't yet support
it but it's planned as a future extension in the form of an argument that will
allow to associate a hard-coded base with a GPIO chip by its label.

## Similar projects

* [sysfs-gpio-shim](https://github.com/info-beamer/sysfs-gpio-shim), written in
C. Officially only supports Raspberry Pi.


## Testing

To test this project, you need to build a test image first using OpenEmbedded.

Install `kas` using the [upstream instructions](https://kas.readthedocs.io/en/latest/userguide/getting-started.html).

Install other tools required, for instance on debian:
```
sudo apt install

TODO
```

Then build the image:
```
kas-container build tests/yocto/gpiod-sysfs-proxy-tests.yml
```
