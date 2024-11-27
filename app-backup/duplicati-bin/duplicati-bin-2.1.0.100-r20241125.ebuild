# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit tmpfiles systemd

MY_PN="duplicati"
MY_BUILDTYPE="$(echo ${PR}|/bin/awk -F'_' '{print $2}')"
MY_BASE_PV="${PV}_${MY_BUILDTYPE:-canary}_${PR:1:4}-${PR:5:2}-${PR:7:2}"
MY_NAME="${MY_PN}-${MY_BASE_PV}-linux-x64-gui"

DESCRIPTION="A backup client that securely stores encrypted, incremental, compressed backups."
HOMEPAGE="https://duplicati.com/"
SRC_URI="https://github.com/${MY_PN}/${MY_PN}/releases/download/v${MY_BASE_PV}/${MY_NAME}.zip"

S="${WORKDIR}/${MY_NAME}"
LICENSE="LGPL-2"

SLOT="0"
KEYWORDS="~amd64 ~x86"

BDEPEND="app-arch/unzip"

src_install() {
	find "${D}" -name '*.map' -delete || die

	dodir /opt/duplicati
	cp -R . "${ED}/opt/duplicati" || die

	dotmpfiles "${FILESDIR}/duplicati.tmpfiles.conf"
	systemd_newunit "${FILESDIR}/duplicati-r1.service" duplicati.service
}

pkg_postinst() {
	tmpfiles_process duplicati.tmpfiles.conf
}
