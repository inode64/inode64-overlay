# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit check-reqs

PKG_NAME="DaVinci_Resolve_Studio_${PV}_Linux"
PKG_HOME="/opt/resolve"
PKG_MOUNT="squashfs-root"

KEYWORDS="~amd64"
DESCRIPTION="Professional A/V post-production software suite from Blackmagic Design"
HOMEPAGE="https://www.blackmagicdesign.com/support/family/davinci-resolve-and-fusion"
SRC_URI="${PKG_NAME}.zip"
RESTRICT="mirror strip"

DEPEND="
		virtual/libcrypt
"
RDEPEND="${DEPEND}"

LICENSE=""
SLOT="0"
IUSE=""

QA_PREBUILT=""

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

src_install() {
	cd ${PKG_MOUNT}
	insinto "${PKG_HOME}"
	doins -r {bin,BlackmagicRAWPlayer,BlackmagicRAWSpeedTest,Control,'DaVinci Control Panels Setup',Fusion,graphics,libs,LUT,Onboarding,plugins,UI_Resource}

	diropts -m 0777
	keepdir "${PKG_HOME}/"{.license,easyDCP,Fairlight,logs}

	fperms +x "${PKG_HOME}/BlackmagicRAWPlayer/BlackmagicRAWPlayer"
	fperms +x "${PKG_HOME}/BlackmagicRAWSpeedTest/BlackmagicRAWSpeedTest"
	fperms +x "${PKG_HOME}/DaVinci Control Panels Setup/DaVinci Control Panels Setup"
	fperms +x "${PKG_HOME}"/LUT/{GenLut,GenOutputLut}
	fperms +x "${PKG_HOME}/Onboarding/DaVinci_Resolve_Welcome"
	fperms +x "${PKG_HOME}/Onboarding/libexec/QtWebEngineProcess"

	fperms +x "${PKG_HOME}"/bin/{BMDPanelFirmware,DaVinciPanelDaemon,DaVinciRemoteAdvPanel.sh,DaVinciRemotePanel.sh,OFXLoader,ShowDpxHeader,TestIO,VstScanner,bmdpaneld,libusb-1.0.so.0.1.0,resolve,run_bmdpaneld}

	find -iname *.so*| while read file; do
		fperms +x "${PKG_HOME}/${file}"
	done

	dodoc docs/{DaVinci_Resolve_Manual.pdf,ReadMe.html,Welcome.txt}
	dodoc 'Technical Documentation'/{'DaVinci Remote Panel.txt','User Configuration folders and customization.txt'}

	keepdir "/var/BlackmagicDesign/DaVinci Resolve"
}