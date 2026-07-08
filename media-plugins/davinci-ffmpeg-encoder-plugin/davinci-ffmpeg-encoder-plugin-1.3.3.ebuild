# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake optfeature

MY_PN="ffmpeg_encoder_plugin"

DESCRIPTION="FFmpeg Encoder Plugin for DaVinci Resolve Studio"
HOMEPAGE="https://github.com/EdvinNilsson/ffmpeg_encoder_plugin"
SRC_URI="https://github.com/EdvinNilsson/ffmpeg_encoder_plugin/archive/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${MY_PN}-${PV}"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="media-video/ffmpeg[x264,x265,svt-av1]"
RDEPEND="${DEPEND}"

src_install() {
	exeinto "/opt/resolve/IOPlugins/${MY_PN}.dvcp.bundle/Contents/Linux-x86-64"
	doexe "${BUILD_DIR}/${MY_PN}.dvcp"
}

pkg_postinst() {
	optfeature "NVENC hardware encoding" media-video/ffmpeg[nvenc]
	optfeature "VA-API hardware encoding" media-video/ffmpeg[vaapi]
}
