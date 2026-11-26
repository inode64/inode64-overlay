# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CHROMIUM_LANGS="
	af am ar bg bn ca cs da de el en-GB en-US es es-419 et fa fi fil fr gu he hi
	hr hu id it ja kn ko lt lv ml mr ms nb nl pl pt-BR pt-PT ro ru sk sl sr sv
	sw ta te th tr uk ur vi zh-CN zh-TW
"
inherit chromium-2 pax-utils

DESCRIPTION="Cross-platform desktop application framework (official binaries)"
HOMEPAGE="
	https://www.electronjs.org/
	https://github.com/electron/electron
"
SRC_URI="
	https://github.com/electron/electron/releases/download/v${PV}/electron-v${PV}-linux-x64.zip
		-> ${P}-linux-x64.zip
	https://artifacts.electronjs.org/headers/dist/v${PV}/node-v${PV}-headers.tar.gz
		-> ${P}-headers.tar.gz
"
S="${WORKDIR}"

# Electron itself is MIT; the rest covers the Chromium, Node.js and V8 it
# bundles (LICENSES.chromium.html in the release).
LICENSE="
	MIT
	Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD BSD-2 Base64 Boost-1.0
	CC-BY-3.0 CC-BY-4.0 Clear-BSD FFT2D FTL IJG ISC LGPL-2 LGPL-2.1 MPL-1.1
	MPL-2.0 Ms-PL PSF-2 SGI-B-2.0 SSLeay SunSoft Unicode-3.0 Unicode-DFS-2015
	Unlicense UoI-NCSA ZLIB libtiff openssl
"
SLOT="$(ver_cut 1)"
KEYWORDS="-* ~amd64"
RESTRICT="strip test"

# libsecret (safeStorage) and xdg-open (shell.openExternal) are loaded and run
# at run time, so they are not in NEEDED.
RDEPEND="
	app-accessibility/at-spi2-core:2
	app-crypt/libsecret
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa[gbm(+)]
	net-print/cups
	virtual/libudev
	x11-libs/gtk+:3
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-misc/xdg-utils
"
BDEPEND="app-arch/unzip"

QA_PREBUILT="opt/${PN}-${SLOT}/*"

pkg_setup() {
	chromium_suid_sandbox_check_kernel_config
}

src_unpack() {
	mkdir electron || die
	pushd electron >/dev/null || die
	unpack "${P}-linux-x64.zip"
	popd >/dev/null || die

	unpack "${P}-headers.tar.gz"
}

src_prepare() {
	default

	# LICENSE above records them; nothing reads the copies at run time.
	rm electron/LICENSE electron/LICENSES.chromium.html || die

	pushd electron/locales >/dev/null || die
	chromium_remove_language_paks
	popd >/dev/null || die
}

src_install() {
	local dir="/opt/${PN}-${SLOT}"

	insinto "${dir}"
	doins -r electron/.

	# doins drops the execute bits that the zip sets.
	local file
	for file in electron chrome-sandbox chrome_crashpad_handler \
		libEGL.so libffmpeg.so libGLESv2.so libvk_swiftshader.so libvulkan.so.1; do
		[[ -e electron/${file} ]] && fperms 0755 "${dir}/${file}"
	done
	# Without unprivileged user namespaces Chromium falls back to the setuid
	# sandbox; doins already installs it owned by root.
	fperms 4711 "${dir}/chrome-sandbox"
	pax-mark m "${ED}${dir}/electron"

	# node-gyp and @electron/rebuild take these as npm_config_nodedir to build
	# native addons against this Electron without downloading its headers.
	insinto "${dir}/node_headers"
	doins -r node_headers/.

	dosym -r "${dir}/electron" "/usr/bin/electron-${SLOT}"
}
