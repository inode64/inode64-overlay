# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module systemd tmpfiles

DESCRIPTION="Self-hosted control plane for the Nebula mesh VPN"
HOMEPAGE="https://github.com/forgekeep/nebula-mesh"

SRC_URI="https://github.com/forgekeep/nebula-mesh/archive/v${PV}.tar.gz -> ${P}.tar.gz
    https://www.inode64.com/dist/${P}-vendor.tar.xz
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+agent mgmt"
REQUIRED_USE="|| ( agent mgmt )"

RDEPEND="
	mgmt? (
		acct-group/nebula-mgmt
		acct-user/nebula-mgmt
	)
	agent? ( net-vpn/nebula )
"

src_prepare() {
	default

	sed -i -e 's|/usr/local/bin/|/usr/bin/|g' deploy/systemd/nebula-{agent,mgmt}.service || die
}

src_compile() {
	if use agent; then
		ego build -trimpath -ldflags "-s -w" -o nebula-agent ./cmd/nebula-agent || die
	fi
	if use mgmt; then
		ego build -trimpath -ldflags "-s -w" -o nebula-mgmt ./cmd/nebula-mgmt || die
	fi
}

src_test() {
	ego test ./... || die "test failed"
}

src_install() {
	dodoc README.md CHANGELOG.md

	if use agent; then
		dobin nebula-agent

		insopts -m0600
		insinto /etc/nebula-agent
		doins configs/agent.example.yml
		fperms 0700 /etc/nebula-agent

		newinitd "${FILESDIR}/nebula-agent.initd" nebula-agent
		newconfd "${FILESDIR}/nebula-agent.confd" nebula-agent
		systemd_dounit deploy/systemd/nebula-agent.service
	fi

	if use mgmt; then
		dobin nebula-mgmt

		insopts -m0600
		insinto /etc/nebula-mgmt
		doins configs/server.example.yml
		fperms 0700 /etc/nebula-mgmt
		fowners -R nebula-mgmt:nebula-mgmt /etc/nebula-mgmt

		dotmpfiles "${FILESDIR}/nebula-mgmt.tmpfiles.conf"

		newinitd "${FILESDIR}/nebula-mgmt.initd" nebula-mgmt
		newconfd "${FILESDIR}/nebula-mgmt.confd" nebula-mgmt
		systemd_dounit deploy/systemd/nebula-mgmt.service
	fi
}

pkg_postinst() {
	if use agent; then
		elog "Copy /etc/nebula-agent/agent.example.yml to /etc/nebula-agent/agent.yml"
		elog "and adjust it before starting the nebula-agent service."
	fi
	if use mgmt; then
		elog "Copy /etc/nebula-mgmt/server.example.yml to /etc/nebula-mgmt/server.yml"
		elog "and adjust it before starting the nebula-mgmt service."
	fi
}

pkg_postinst() {
	tmpfiles_process nebula-mgmt.tmpfiles.conf
}
