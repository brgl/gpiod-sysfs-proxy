# TODO: move into README.md under testing heading


Then run:


# TODO: remove mkdir and cd ???
```bash
kas-container build tests/yocto/gpiod-sysfs-proxy-tests.yml
```

That should produce:

# TODO: Wrong path
```bash
build/tmp/deploy/images/qemux86-64/core-image-minimal-qemux86-64.rootfs.ext4
```

Start a kas shell:

```bash
kas-container --runtime-args "-v $PWD:/mnt:ro" shell tests/yocto/gpiod-sysfs-proxy-tests.yml
```

Boot the image in QEMU:

```bash
runqemu qemux86-64 core-image-minimal nographic slirp snapshot \
  qemuparams="-virtfs local,path=/mnt,mount_tag=hostshare,security_model=none,id=hostshare"
```

Once the VM boots, log in as `root` with an empty password, then run:

```bash
mount -t 9p -o trans=virtio,version=9p2000.L hostshare /mnt


#root@qemux86-64:/usr/lib/gpiod-sysfs-proxy/ptest/tests# cp /mnt/gpiod-sysfs-proxy /usr/bin/gpiod-sysfs-proxy
#systemctl restart gpiod-sysfs-proxy
#root@qemux86-64:/usr/lib/gpiod-sysfs-proxy/ptest/tests# ./gpio-sysfs-compat-tests -v


# root@qemux86-64:/usr/lib/gpiod-sysfs-proxy/ptest/tests# ./gpio-sysfs-compat-tests -v
# ptest-runner gpiod-sysfs-proxy



# TODO: didn't try this
# modprobe configfs
# modprobe gpio-sim
# modprobe gpio-mockup
```

# TODO: didn't try this
#For an interactive shell over SSH instead of the QEMU console, keep `slirp` and add host forwarding:

#```bash
#runqemu qemux86-64 core-image-minimal nographic slirp \
#  qemuparams="-m 2048 -smp 4 -netdev user,id=net0,hostfwd=tcp::2222-:22"
#```
#Then from another terminal:
#
#```bash
#ssh -p 2222 root@localhost
#ptest-runner gpiod-sysfs-proxy
#```
