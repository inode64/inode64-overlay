# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit nodejs nodejs-mod systemd tmpfiles

DESCRIPTION="A visual tool for wiring the Internet of Things"
HOMEPAGE="https://nodered.org"
SRC_URI="https://github.com/${PN}/${PN}/archive/refs/tags/${PV}.tar.gz  -> ${P}.tar.gz
		https://www.inode64.com/dist/${P}-node_modules.tar.xz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	acct-user/node-red
	>=net-libs/nodejs-22.9[npm]
"

NODEJS_EXTRA_FILES="packages"

# @node-rs/bcrypt (napi-rs, Rust) is only shipped as a prebuilt binary, and
# modules using the prebuilds/ layout keep their linux-x64 binary (see below).
# https://github.com/inode64/inode64-overlay/issues/29
QA_PREBUILT="
	usr/lib*/node_modules/${PN}/node_modules/@node-rs/*/*.node
	usr/lib*/node_modules/${PN}/node_modules/*/prebuilds/linux-x64/*
"

src_install() {
	# Remove jsdoc-nr-template, prune use git to get the version
	rm -rf node_modules/jsdoc-nr-template/ || die
	sed -i -e '/jsdoc-nr-template/d' package.json || die

	# Drop prebuilt binaries for other platforms (android, darwin, ios, win32...)
	local dir
	while IFS= read -r -d '' dir; do
		rm -r "${dir}" || die
	done < <(find node_modules -mindepth 2 -maxdepth 2 -type d -path '*/prebuilds/*' \
		! -name 'linux-x64' -print0)

	nodejs-mod_src_install

	# The root package.json is the monorepo one, which declares no commands.
	local red="$(nodejs_modules)/packages/node_modules/${PN}/red.js"
	fperms +x "${red}"
	dosym -r "${red}" /usr/bin/${PN}

	dotmpfiles "${FILESDIR}"/node-red.conf

	doinitd "${FILESDIR}"/${PN}
	systemd_dounit "${FILESDIR}/${PN}.service"
}

pkg_postinst() {
	tmpfiles_process node-red.conf
}
