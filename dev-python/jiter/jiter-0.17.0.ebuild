# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_EXT=1
DISTUTILS_USE_PEP517=( maturin crates/jiter-python )
PYPI_VERIFY_REPO=https://github.com/pydantic/jiter
PYTHON_COMPAT=( python3_{11..14} )

RUST_MIN_VER="1.88.0"

inherit cargo distutils-r1 pypi

DESCRIPTION="Fast iterable JSON parser"
HOMEPAGE="
	https://github.com/pydantic/jiter
	https://pypi.org/project/jiter/
"
SRC_URI+=" https://www.inode64.com/dist/${P}-crates.tar.xz"

LICENSE="MIT"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 Apache-2.0-with-LLVM-exceptions MIT MPL-2.0 UoI-NCSA
	Unicode-3.0
"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

QA_FLAGS_IGNORED="usr/lib.*/py.*/site-packages/jiter/jiter.*.so"

# Tests pull dirty-equals (::guru-only); skip in fork.
RESTRICT="test"

src_unpack() {
	# Required for verify-provenance
	pypi_src_unpack
	cargo_src_unpack
}
