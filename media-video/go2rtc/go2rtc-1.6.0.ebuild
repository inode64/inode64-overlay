# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module systemd

DESCRIPTION="Ultimate camera streaming application"
HOMEPAGE="https://syncthing.net"
SRC_URI="https://github.com/AlexxIT/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://raw.githubusercontent.com/inode64/inode64-overlay/main/dist/${P}-vendor.tar.xz
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="media-video/ffmpeg[encode,x264,x265,opus]
"

DOCS=( README.md )

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
	go run build.go test || die "test failed"
}

src_install() {
    default

    insinto /usr/bin
    dobin go2rtc

    insinto /etc/go2rtc
    doins "${FILESDIR}/go2rtc.yaml"
    newinitd "${FILESDIR}/go2rtc.initd" go2rtc
}
