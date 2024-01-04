# freebsd-ports-nix

Experimental fork of the basis of `sysutils/nix`, [freebsd-ports-nix](https://github.com/0mp/freebsd-ports-nix).
There is no bootstrap stage for FreeBSD at the moment, but Nix itself builds. Sort of.

## Usage
1. Install this port's dependencies: `pkg install -y < ./dependencies.txt`
2. Manually install `$RAPIDCHECK_SOURCE/extras/gtest/include/rapidcheck/gtest.h` into `/usr/local/include/rapidcheck/` by copying from its source. (This header not being included should be reported upstream... with due time, hopefully.)
3. `sudo make install`
