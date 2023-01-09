# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-mod

DESCRIPTION="The kernel module component of VDO which provides pools of deduplicated and/or compressed block storage."
HOMEPAGE="https://github.com/dm-vdo/kvdo"
SRC_URI="https://github.com/dm-vdo/kvdo/archive/${PV}.tar.gz -> ${P}.tar.gz"
S=${WORKDIR}/kvdo-${PV}

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND="dev-libs/elfutils"

CONFIG_CHECK="LZ4_COMPRESS LZ4_DECOMPRESS"

pkg_pretend() {
	linux-mod_pkg_setup
}

pkg_setup() {
	linux-mod_pkg_setup
}

src_compile() {
    emake -C /usr/src/linux M=`pwd`
}

src_install() {
    emake -C /usr/src/linux M=`pwd` modules_install
}
