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

LICENSE="BSD-2 Unlicense"
SLOT="0"
KEYWORDS="-* ~amd64"

DEPEND="dev-libs/gmp:="
RDEPEND="${DEPEND}"

DOCS=( README.rst )

python_test() {
	local -x PYTHONPATH="${BUILD_DIR}/install$(python_get_sitedir)"
	"${EPYTHON}" - <<-EOF || die
		import sys
		from Cryptodome import SelfTest
		SelfTest.run(verbosity=2, stream=sys.stdout)
	EOF
}
