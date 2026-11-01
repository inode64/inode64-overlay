# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit nodejs nodejs-pack

DESCRIPTION="Superset of JavaScript with optional static typing, classes and interfaces"
HOMEPAGE="https://www.typescriptlang.org/
	https://github.com/microsoft/TypeScript/"
# Since 7.0 the compiler is a native binary published as a per-platform npm
# package, which npm can only pull as an optional dependency over the network.
NATIVE_PN="${PN}-linux-x64"
SRC_URI="
	https://registry.npmjs.org/${PN}/-/${P}.tgz
	https://registry.npmjs.org/@${PN}/${NATIVE_PN}/-/${NATIVE_PN}-${PV}.tgz
"

S="${WORKDIR}"/package
LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="net-libs/nodejs"

src_unpack() {
	# Both tarballs unpack to package/
	unpack "${NATIVE_PN}-${PV}.tgz"
	mv package native || die
	unpack "${P}.tgz"
}

src_install() {
	nodejs-pack_src_install

	local native_dir
	native_dir="$(nodejs_modules)/node_modules/@${PN}/${NATIVE_PN}"
	insinto "${native_dir}"
	doins -r "${WORKDIR}"/native/.
	fperms +x "${native_dir}"/lib/tsc
}
