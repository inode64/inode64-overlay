# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic go-module systemd tmpfiles

DESCRIPTION="Argo Tunnel client, written in GoLang"
HOMEPAGE="https://github.com/cloudflare/cloudflared"
SRC_URI="https://github.com/cloudflare/cloudflared/archive/${PV}.tar.gz -> ${P}.tar.gz
	https://raw.githubusercontent.com/inode64/inode64-overlay/main/dist/${P}-vendor.tar.xz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"

src_configure() {
	filter-lto

	export CGO_ENABLED=1
	export CGO_CFLAGS="${CFLAGS}"
	export CGO_CPPFLAGS="${CPPFLAGS}"
	export CGO_CXXFLAGS="${CXXFLAGS}"
	export CGO_LDFLAGS="${LDFLAGS}"

	default
}

src_compile() {
	local ld_flags="-s -w -X 'main.Version=${PV}' -X 'main.BuildTime=$(date -u '+%Y-%m-%d-%H%M UTC')'"

	ego build -trimpath -ldflags "${ld_flags}" -o "bin/${PN}" ./cmd/${PN} || die
}

src_test() {
	ego test ./... || die "test failed"
}

src_install() {
	dobin bin/*

	diropts -m0600
	insinto /etc/cloudflared
	newins "${FILESDIR}"/config.yml config-example.yml
	newinitd "${FILESDIR}"/cloudflared.initd cloudflared
	newconfd "${FILESDIR}"/cloudflared.confd cloudflared
	systemd_newunit "${FILESDIR}"/cloudflared.service cloudflared@.service

	dotmpfiles "${FILESDIR}/${PN}.tmpfiles.conf"
}

pkg_postinst() {
	tmpfiles_process ${PN}.tmpfiles.conf

	einfo "Please note that Cloudflared uses a custom version of GO that does not support the QUIC protocol."
	einfo "Instead, you should configure the tunnel to use protocol: http2 in your settings"
	einfo
	einfo "This message clearly communicates the information about the custom GO version and provides the alternative configuration option."
	einfo "https://github.com/cloudflare/go"
}
