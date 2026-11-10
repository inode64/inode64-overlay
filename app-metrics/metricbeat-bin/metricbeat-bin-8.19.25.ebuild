# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

MY_PN="metricbeat"
MY_P="${MY_PN}-${PV}-linux-x86_64"
DESCRIPTION="Lightweight shipper for metrics"
HOMEPAGE="https://www.elastic.co/es/beats/metricbeat"
SRC_URI="https://artifacts.elastic.co/downloads/beats/${MY_PN}/${MY_P}.tar.gz"

S="${WORKDIR}/${MY_P}"
LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="-* ~amd64"
RESTRICT="strip"

DOCS=( NOTICE.txt README.md )

src_install() {
	dobin ${MY_PN}
	einstalldocs

	insinto /etc/${MY_PN}
	doins fields.yml
	doins ${MY_PN}.yml
	doins ${MY_PN}.reference.yml
	doins -r modules.d

	dodir /usr/share/${MY_PN}
	cp -r module "${ED}"/usr/share/${MY_PN} || die
	cp -r kibana "${ED}"/usr/share/${MY_PN} || die

	newconfd "${FILESDIR}/${MY_PN}.confd" ${MY_PN}
	# The data and log directories belong to the user set in conf.d: the init
	# script creates them with checkpath and the unit with StateDirectory and
	# LogsDirectory. A tmpfiles entry would hand them back to root.
	newinitd "${FILESDIR}/${MY_PN}.initd" ${MY_PN}
	systemd_dounit "${FILESDIR}/${MY_PN}.service"
}
