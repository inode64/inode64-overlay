# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )

inherit python-single-r1

DESCRIPTION="Command line administration tool for RabbitMQ"
HOMEPAGE="http://www.rabbitmq.com/management-cli.html"
SRC_URI="https://raw.githubusercontent.com/rabbitmq/rabbitmq-server/v$(ver_cut 1-2).x/deps/rabbitmq_management/bin/${PN} -> ${PN}.v${PV}"

SLOT="0"
LICENSE="MPL-2.0"
KEYWORDS="~amd64"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"
RDEPEND="
	dev-lang/python[ssl]
	${PYTHON_DEPS}
"
DEPEND="${RDEPEND}"

src_unpack() {
	mkdir "${S}"
}

src_install() {
	newbin "${DISTDIR}"/${PN}.v${PV} rabbitmqadmin
}
