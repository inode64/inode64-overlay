# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="8"

inherit rpm

# Upstream is still using strange version numbers
MY_PV="00${PV}.0000.0000"
MY_P="${PN}-${MY_PV}"
DESCRIPTION="MegaRAID StorCLI (successor of the MegaCLI)"
HOMEPAGE="https://www.broadcom.com/support/download-search?dk=storcli"
SRC_URI="https://docs.broadcom.com/docs-and-downloads/raid-controllers/raid-controllers-common-files/${MY_PV}_Unified_StorCLI-PUL.zip -> ${P}.zip"

LICENSE="Avago LSI BSD"
SLOT="0/${PV:0:4}"
KEYWORDS="-* amd64"
IUSE=""

BDEPEND="app-arch/unzip"
RDEPEND=""
DEPEND=""

S="${WORKDIR}"

QA_PRESTRIPPED="/opt/MegaRAID/storcli/storcli64"

src_unpack() {
	default
	rpm_unpack ./Linux/${MY_P}-1.noarch.rpm
}

src_install() {
	exeinto /opt/MegaRAID/storcli
	doexe opt/MegaRAID/storcli/storcli64

	dosym ../../opt/MegaRAID/storcli/storcli64 /usr/sbin/storcli
	dosym ../../opt/MegaRAID/storcli/storcli64 /usr/sbin/storcli64
}
