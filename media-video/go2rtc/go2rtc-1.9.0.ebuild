# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module systemd tmpfiles

DESCRIPTION="Ultimate camera streaming application"
HOMEPAGE="https://github.com/AlexxIT/go2rtc"
SRC_URI="https://github.com/AlexxIT/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://raw.githubusercontent.com/inode64/inode64-overlay/main/dist/${P}-vendor.tar.xz
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	acct-group/go2rtc
	acct-user/go2rtc
	media-video/ffmpeg[encode,x264,x265,opus]
"

DOCS=(README.md)

src_configure() {
	export CGO_ENABLED=1
	export CGO_CFLAGS="${CFLAGS}"
	export CGO_CPPFLAGS="${CPPFLAGS}"
	export CGO_CXXFLAGS="${CXXFLAGS}"
	export CGO_LDFLAGS="${LDFLAGS}"

	default
}

src_compile() {
	local mygoargs=(
		-asmflags "-trimpath=${S}"
		-gcflags "-trimpath=${S}"
	)

	ego build "${mygoargs[@]}"
}

src_test() {
	ego test || die "test failed"
}

src_install() {
	default

	insinto /usr/bin
	dobin go2rtc

	insinto /etc/logrotate.d
	newins "${FILESDIR}/go2rtc.logrotate" go2rtc

	insinto /etc/${PN}
	doins "${FILESDIR}/go2rtc.yaml"
	fowners -R go2rtc:go2rtc /etc/${PN}

	newinitd "${FILESDIR}/go2rtc.initd" go2rtc
	dotmpfiles "${FILESDIR}"/${PN}.conf

	systemd_newunit "${FILESDIR}/${PN}.service" "${PN}@.service"
}

pkg_postinst() {
	tmpfiles_process go2rtc.conf
}
