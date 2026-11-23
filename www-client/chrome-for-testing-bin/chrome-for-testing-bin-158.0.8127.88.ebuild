# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PN=${PN%-bin}

DESCRIPTION="Chrome build for browser automation (Playwright, Puppeteer, Selenium)"
HOMEPAGE="https://googlechromelabs.github.io/chrome-for-testing/"
SRC_URI="https://storage.googleapis.com/chrome-for-testing-public/${PV}/linux64/chrome-linux64.zip -> ${P}-linux64.zip"
S="${WORKDIR}/chrome-linux64"

LICENSE="google-chrome"
SLOT="0"
KEYWORDS="-* amd64"
RESTRICT="bindist mirror strip"

# What chrome and the libraries next to it link against (scanelf -RBF '%F %n').
# No gtk: it is only dlopen()ed for the headed UI, and this is meant for
# headless use on servers.
RDEPEND="
	app-accessibility/at-spi2-core:2
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa[opengl]
	net-print/cups
	virtual/libudev
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango
"
BDEPEND="app-arch/unzip"

QA_PREBUILT="opt/${MY_PN}/*"

src_install() {
	# cp keeps the executable bits of chrome and its helpers.
	dodir /opt/${MY_PN}
	cp -a . "${ED}/opt/${MY_PN}/" || die
	dosym -r /opt/${MY_PN}/chrome /usr/bin/${MY_PN}
}
