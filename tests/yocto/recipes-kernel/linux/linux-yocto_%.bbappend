FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:qemux86-64 = " file://kernel-9pfs.cfg"
