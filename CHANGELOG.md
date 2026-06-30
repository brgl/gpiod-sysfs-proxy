<!-- SPDX-License-Identifier: CC0-1.0 -->
<!-- SPDX-FileCopyrightText: 2026 Qualcomm Technologies, Inc. and/or its subsidiaries -->

# Changelog

All notable changes to this project will be documented in this file.

The format is loosely based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [v1.0.0]

### Added

- systemd template unit and overlay mount units for mounting the proxy
  filesystem on systems with the sysfs GPIO interface disabled
- `-V`/`--version` command-line option
- Expand command-line help text; compatible with help2man

### Changed

- Migrate FUSE backend from fuse-python to pyfuse3

### Internal

- Add CLAUDE.md codebase documentation for Claude Code
- Make licensing info compatible with the REUSE specification
