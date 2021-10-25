# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit check-reqs

PKG_NAME="DaVinci_Resolve_Studio_${PV}_Linux"
PKG_HOME="/opt/resolve/${PN}"
PKG_MOUNT="squashfs-root"

KEYWORDS="~amd64"
DESCRIPTION="Professional A/V post-production software suite from Blackmagic Design. Studio edition"
HOMEPAGE="https://www.blackmagicdesign.com/support/family/davinci-resolve-and-fusion"
SRC_URI="${PKG_NAME}.zip"
RESTRICT="mirror"

LICENSE=""
SLOT="17"
IUSE=""

DOCS=(
	${PKG_MOUNT}/docs/PDaVinci_Resolve_Manual.pdf
	${PKG_MOUNT}/docs/ReadMe.html ${PKG_MOUNT}/docs/Welcome.txt
	"${PKG_MOUNT}/Technical Documentation/DaVinci Remote Panel.txt"
	"${PKG_MOUNT}/Technical Documentation/User Configuration folders and customization.txt"
)

S="${WORKDIR}"

pkg_pretend() {
	CHECKREQS_DISK_BUILD="13G"

	check-reqs_pkg_pretend
}
pkg_setup() {
	CHECKREQS_DISK_BUILD="13G"

	check-reqs_pkg_pretend
}

src_unpack() {
	default
	./${PKG_NAME}.run --appimage-extract
}
