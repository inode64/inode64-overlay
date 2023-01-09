# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

MY_PN="metricbeat"
MY_P="${MY_PN}-${PV}-linux-x86_64"
DESCRIPTION="Lightweight shipper for metrics"
HOMEPAGE="https://www.elastic.co/es/beats/metricbeat"
SRC_URI="https://artifacts.elastic.co/downloads/beats/${MY_PN}/${MY_P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

DEPEND=""
DOCS="NOTICE.txt README.md"

S="${WORKDIR}/${MY_P}"

src_compile() {
	default
}

src_install() {
	dobin ${MY_PN}

	insinto /etc/${MY_PN}
	doins fields.yml
	doins ${MY_PN}.yml
	doins ${MY_PN}.reference.yml
	doins -r modules.d

	dodir /usr/share/${MY_PN}
	cp -r module "${ED}"/usr/share/${MY_PN}
	cp -r kibana "${ED}"/usr/share/${MY_PN}

	keepdir /var/lib/${MY_PN}
	keepdir /var/log/${MY_PN}

	newconfd "${FILESDIR}/${MY_PN}.confd" ${MY_PN}
	newinitd "${FILESDIR}/${MY_PN}.initd" ${MY_PN}
	systemd_dounit "${FILESDIR}/${MY_PN}.service"
}
