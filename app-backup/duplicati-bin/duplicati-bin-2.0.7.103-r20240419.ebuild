# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit tmpfiles systemd

MY_PN="duplicati"
MY_BUILDTYPE="$(echo ${PR}|/bin/awk -F'_' '{print $2}')"
MY_BASE_PV="${PV}_${MY_BUILDTYPE:-canary}_${PR:1:4}-${PR:5:2}-${PR:7:2}"

DESCRIPTION="A backup client that securely stores encrypted, incremental, compressed backups."
HOMEPAGE="https://duplicati.com/"
SRC_URI="https://github.com/${MY_PN}/${MY_PN}/releases/download/v${PV}-${MY_BASE_PV}/${MY_PN}-${MY_BASE_PV}.zip"
S="${WORKDIR}"
LICENSE="LGPL-2"

SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="gtk"

RDEPEND=">=dev-lang/mono-5.10"
DEPEND="gtk? ( dev-dotnet/gtk-sharp:2 )"
BDEPEND="app-arch/unzip"

src_install() {
	rm -rf {OSX ICONS,OSXTrayHost,SQLite,alphavss,runtimes,win-tools,win-x64,win-x86,x64,x86} || die
	rm {Duplicati.Service.exe,Duplicati.Service.exe.config,Duplicati.WindowsService.exe,Duplicati.WindowsService.exe.config} || die
	rm *.dylib || die
	rm run-script-example.bat || die
	rm utility-scripts/DuplicatiVerify.ps1 || die

	dodir /opt/duplicati
	cp -R . "${ED}/opt/duplicati" || die

	dotmpfiles "${FILESDIR}/duplicati.tmpfiles.conf"
	systemd_dounit "${FILESDIR}/duplicati.service"
}

pkg_postinst() {
	tmpfiles_process duplicati.tmpfiles.conf
}
