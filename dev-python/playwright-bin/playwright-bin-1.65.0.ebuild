# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=standalone
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

MY_PN=${PN//-bin/}

DESCRIPTION="Automate Chromium, Firefox and WebKit browsers with a single API"
HOMEPAGE="https://github.com/Microsoft/playwright-python"

SRC_URI="
	amd64? ( $(pypi_wheel_url "${MY_PN}" "${PV}" py3 none-manylinux1_x86_64) )
	arm64? ( $(pypi_wheel_url "${MY_PN}" "${PV}" py3 none-manylinux_2_17_aarch64.manylinux2014_aarch64) )
"
S="${WORKDIR}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="-* amd64"

# The sync and async APIs also import pyee (>=13,<15), which neither ::gentoo nor
# this overlay package yet, so only the CLI works until it is added here.
RDEPEND="dev-python/greenlet[${PYTHON_USEDEP}]"

RESTRICT="test"

QA_PREBUILT="usr/lib/python*/site-packages/playwright/driver/node"

src_unpack() {
	# Installing the wheel itself keeps the executable bit of the bundled node
	# and generates the playwright entry point.
	:
}

python_compile() {
	distutils_wheel_install "${BUILD_DIR}/install" "${DISTDIR}/${A}"
}
