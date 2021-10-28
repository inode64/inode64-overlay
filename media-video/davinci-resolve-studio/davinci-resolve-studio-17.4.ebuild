# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit check-reqs desktop udev xdg

PKG_NAME="DaVinci_Resolve_Studio_${PV}_Linux"
PKG_HOME="/opt/resolve"
PKG_MOUNT="squashfs-root"

LIBS_SYM="
		libapr-1.so
		libaprutil-1.so
		libcdt.so
		libcgraph.so
		libcrypto.so.1.1
		libcurl.so
		libglut.so.3
		libgvc.so
		libpathplan.so
		libsoxr.so
		libssl.so.1.1
		libtbbmalloc.so.2
		libtbbmalloc_proxy.so.2
		libxcb-icccm.so.4
		libxcb-image.so.0
		libxcb-keysyms.so.1
		libxcb-randr.so.0
		libxcb-render-util.so.0
		libxcb-render.so.0
		libxcb-shape.so.0
		libxcb-shm.so.0
		libxcb-sync.so.1
		libxcb-util.so.1
		libxcb-xfixes.so.0
		libxcb-xinerama.so.0
		libxcb-xinput.so.0
		libxcb-xkb.so.1
		libxcb.so.1
		libxdot.so
		libxmlsec1-openssl.so
		libxmlsec1.so
		graphviz/libgvplugin_core.so.6.0.0
		graphviz/libgvplugin_dot_layout.so.6
"

KEYWORDS="~amd64"
DESCRIPTION="Professional A/V post-production software suite from Blackmagic Design"
HOMEPAGE="https://www.blackmagicdesign.com/support/family/davinci-resolve-and-fusion"
SRC_URI="${PKG_NAME}.zip"
RESTRICT="mirror strip"
IUSE="bundled-libs nvidia amdgpu"

DEPEND="
		amdgpu? ( dev-libs/amdgpu-pro-opencl )
		app-arch/brotli
		app-arch/lz4
		app-arch/zstd
		app-crypt/argon2
		app-crypt/libmd
		dev-libs/fribidi
		dev-libs/glib
		dev-libs/icu
		dev-libs/json-c
		dev-libs/libbsd
		dev-libs/libgpg-error
		dev-libs/libltdl
		dev-libs/libunistring
		dev-libs/nspr
		dev-libs/nss
		dev-libs/ocl-icd
		gnome-base/librsvg
		media-gfx/graphite2
		media-libs/alsa-lib
		media-libs/flac
		media-libs/harfbuzz
		media-libs/libogg
		media-libs/libsndfile
		media-libs/libvorbis
		media-libs/opus
		media-sound/pulseaudio
		net-dns/libidn2
		net-libs/libasyncns
		net-libs/nghttp2
		nvidia? ( x11-drivers/nvidia-drivers )
		sys-apps/dbus
		virtual/libcrypt
		virtual/opengl
		x11-libs/libX11
		x11-libs/libxcb
		x11-libs/libXext
		x11-libs/libXfixes
		x11-libs/libXrender
		x11-libs/libXtst
		!bundled-libs? (
				dev-cpp/tbb
				dev-libs/apr
				dev-libs/xmlsec
				media-gfx/graphviz[qt5]
				media-libs/freeglut
				media-libs/soxr
				net-misc/curl
		)
"
RDEPEND="${DEPEND}"

LICENSE="Blackmagic"
SLOT="0"

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

src_prepare() {
	default
	cd ${PKG_MOUNT}

	sed -i -e "s|RESOLVE_INSTALL_LOCATION|${PKG_HOME}|g" share/*.desktop share/*.directory

	# Remove 32bits apps
	rm LUT/GenOutputLut \
		LUT/GenLut || die

	if use !bundled-libs; then
		rm bin/libusb* || die
		for _lib in ${LIBS_SYM}; do
			rm libs/${_lib} || die
		done
		rm -rf libs/pkgconfig || die
	fi
}

src_install() {
	cd ${PKG_MOUNT}

	insinto "${PKG_HOME}"
	doins -r {bin,BlackmagicRAWPlayer,BlackmagicRAWSpeedTest,Control,'DaVinci Control Panels Setup',Fusion,graphics,libs,LUT,Onboarding,plugins,UI_Resource}

	insinto "${PKG_HOME}"/share
	doins share/{default-config.dat,default_cm_config.bin,log-conf.xml}

	fperms +x "${PKG_HOME}/BlackmagicRAWPlayer/BlackmagicRAWPlayer"
	fperms +x "${PKG_HOME}/BlackmagicRAWSpeedTest/BlackmagicRAWSpeedTest"
	fperms +x "${PKG_HOME}/DaVinci Control Panels Setup/DaVinci Control Panels Setup"
	fperms +x "${PKG_HOME}/Onboarding/DaVinci_Resolve_Welcome"
	fperms +x "${PKG_HOME}/Onboarding/libexec/QtWebEngineProcess"

	fperms +x "${PKG_HOME}"/bin/{BMDPanelFirmware,DaVinciPanelDaemon,DaVinciRemoteAdvPanel.sh,DaVinciRemotePanel.sh,OFXLoader,ShowDpxHeader,TestIO,VstScanner,bmdpaneld,resolve,run_bmdpaneld}
	if use bundled-libs; then
		fperms +x "${PKG_HOME}"/bin/{libusb-1.0.so.0.1.0}
	fi

	#find -iname *.so* | while read file; do
	#	fperms +x "${PKG_HOME}/${file}"
	#done

	dodoc docs/{DaVinci_Resolve_Manual.pdf,ReadMe.html,Welcome.txt}
	dodoc 'Technical Documentation'/{'DaVinci Remote Panel.txt','User Configuration folders and customization.txt'}

	insinto "$(get_udevdir)"/rules.d
	doins share/etc/udev/rules.d/*.rules

	newmenu share/DaVinciControlPanelsSetup.desktop com.blackmagicdesign.resolve-Panels.desktop
	newmenu share/DaVinciResolve.desktop com.blackmagicdesign.resolve.desktop
	newmenu share/DaVinciResolveCaptureLogs.desktop com.blackmagicdesign.resolve-CaptureLogs.desktop
	newmenu share/blackmagicraw-player.desktop com.blackmagicdesign.rawplayer.desktop
	newmenu share/blackmagicraw-speedtest.desktop com.blackmagicdesign.rawspeedtest.desktop

	newmenu "${FILESDIR}"/defaults.list com.blackmagicdesign.list

	insinto /usr/share/desktop-directories
	doins share/*.directory

	insinto /etc/xdg/menus
	doins share/*.menu

	insinto /usr/share/mime/packages/
	doins share/{blackmagicraw.xml,resolve.xml}

	diropts -m 0777
	keepdir "${PKG_HOME}/"{.license,easyDCP,Fairlight,logs}
	keepdir "/var/BlackmagicDesign/DaVinci Resolve"

	if use !bundled-libs; then
		dosym -r /usr/$(get_libdir)/libusb-1.0.so.0.1.0 ${PKG_HOME}/bin/libusb-1.0.so.0.1.0
		for _lib in ${LIBS_SYM}; do
			dosym -r /usr/$(get_libdir)/${_lib} ${PKG_HOME}/libs/${_lib}
		done
	fi
}

pkg_preinst() {
	xdg_pkg_preinst
}

pkg_postinst() {
	udev_reload
	xdg_pkg_postinst
}

pkg_postrm() {
	xdg_pkg_postrm
}
