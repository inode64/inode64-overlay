# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_EXT=1
DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..15} )
PYTHON_REQ_USE="threads(+)"

inherit distutils-r1 pypi

DESCRIPTION="Cryptographic library for Python (Cryptodome namespace)"
HOMEPAGE="
	https://www.pycryptodome.org/
	https://github.com/Legrandin/pycryptodome/
	https://pypi.org/project/pycryptodomex/
"
# The sdist lacks the test vectors, without them most of SelfTest is skipped.
# Upstream tags pycryptodomex releases v${PV}x; since pycryptodome moved to
# 4.x, newer 3.x releases have no v${PV} tag.
SRC_URI+="
	test? (
		https://github.com/Legrandin/pycryptodome/archive/v${PV}x.tar.gz
			-> ${P}.gh.tar.gz
	)
"

LICENSE="BSD-2 Unlicense"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"
RESTRICT="!test? ( test )"

DEPEND="
	dev-libs/gmp:=
	>=dev-libs/libtomcrypt-1.18.2-r1:=
"
RDEPEND="${DEPEND}"

DOCS=( README.rst )

# As in dev-python/pycryptodome-3.24.1: DES, 3DES and Salsa20 link the
# system libtomcrypt instead of the copy in src/libtom.
PATCHES=(
	"${FILESDIR}/pycryptodome-3.10.1-system-libtomcrypt.patch"
)

python_prepare_all() {
	rm -r src/libtom || die

	distutils-r1_python_prepare_all
}

python_test() {
	local -x PYTHONPATH="${BUILD_DIR}/install$(python_get_sitedir):${WORKDIR}/pycryptodome-${PV}x/test_vectors"
	"${EPYTHON}" - <<-EOF || die
		import sys
		from Cryptodome import SelfTest
		SelfTest.run(verbosity=2, stream=sys.stdout)
	EOF
}
