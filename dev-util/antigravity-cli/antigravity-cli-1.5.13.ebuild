# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Google Antigravity terminal agent (prebuilt binary)"
HOMEPAGE="
	https://antigravity.google/product/antigravity-cli
	https://github.com/google-antigravity/antigravity-cli
"
# Same files as the storage.googleapis.com URLs of upstream's install.sh
# manifest, without the per-build ID those carry after the version.
SRC_URI="
	amd64? (
		https://github.com/google-antigravity/antigravity-cli/releases/download/${PV}/agy_cli_linux_x64.tar.gz
			-> ${P}-amd64.tar.gz
	)
	arm64? (
		https://github.com/google-antigravity/antigravity-cli/releases/download/${PV}/agy_cli_linux_arm64.tar.gz
			-> ${P}-arm64.tar.gz
	)
"
S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
RESTRICT="bindist mirror strip"

RDEPEND="sys-libs/glibc"

QA_PREBUILT="opt/${PN}/antigravity"

src_test() {
	local version
	version=$(./antigravity --version) || die
	[[ ${version} == "${PV}" ]] || die "the binary reports ${version}, not ${PV}"
}

src_install() {
	exeinto /opt/${PN}
	doexe antigravity

	# When it can write to its own directory, as root can here, agy replaces
	# itself with the latest release and leaves an agy.*.old copy behind.
	# The variable has to come from a wrapper: /etc/env.d only reaches login
	# shells, not services or cron.
	newbin - agy <<-EOF
		#!/bin/sh
		export AGY_CLI_DISABLE_AUTO_UPDATE=true
		exec "${EPREFIX}/opt/${PN}/antigravity" "\$@"
	EOF
}
