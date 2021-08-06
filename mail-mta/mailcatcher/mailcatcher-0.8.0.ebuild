# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

USE_RUBY="ruby25 ruby26"

inherit eutils ruby-ng

DESCRIPTION="Runs an SMTP server, catches and displays email in a web interface."
HOMEPAGE="https://mailcatcher.me/"
SRC_URI="https://github.com/sj26/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""
RESTRICT="network-sandbox"

GEMS_DEPEND="
		dev-ruby/eventmachine
		dev-ruby/mail
		dev-ruby/rack
		dev-ruby/sinatra
		dev-ruby/sqlite3
"

ruby_add_rdepend "${GEMS_DEPEND}"

all_ruby_install() {
	_gemdir="${D}$(ruby -e'puts Gem.default_dir')"
	_bindir="${D}/usr/bin"

	gem install --no-document --no-user-install --install-dir "${_gemdir}" --bindir "${_bindir}" ${PN}

	newinitd ${FILESDIR}/${PN}.init ${PN}
	newconfd ${FILESDIR}/${PN}.conf ${PN}
}
