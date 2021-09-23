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
		=dev-ruby/eventmachine-1.0.9.1
		dev-ruby/mail
		dev-ruby/tilt
		dev-ruby/sqlite3
		=www-servers/thin-1.5.1
"

ruby_add_rdepend "${GEMS_DEPEND}"

all_ruby_install() {
	_gemdir="${D}$(ruby -e'puts Gem.default_dir')"
	_bindir="${D}/usr/bin"

	gem install --no-document --no-user-install --minimal-deps --install-dir "${_gemdir}" --bindir "${_bindir}" ${PN}

	# delete already installed packages
	rm ${D}/usr/bin/rackup
	rm ${D}/usr/bin/thin
	rm ${D}/usr/bin/tilt

	rm -rf ${_gemdir}/extensions
	rm -rf ${_gemdir}/gems/eventmachine*
	rm -rf ${_gemdir}/gems/mail*
	rm -rf ${_gemdir}/gems/sqlite*
	rm -rf ${_gemdir}/gems/thin*
	rm -rf ${_gemdir}/gems/tilt*
	rm -rf ${_gemdir}/specifications/eventmachine*
	rm -rf ${_gemdir}/specifications/mail*
	rm -rf ${_gemdir}/specifications/sqlite3*
	rm -rf ${_gemdir}/specifications/thin*
	rm -rf ${_gemdir}/specifications/tilt*

	newinitd ${FILESDIR}/${PN}.init ${PN}
	newconfd ${FILESDIR}/${PN}.conf ${PN}
}

src_prepare() {
	cd ./all/${P}
	pwd


	sed -i -e '/"mail"/d' mailcatcher.gemspec
	sed -i -e '/"eventmachine"/d' mailcatcher.gemspec
	sed -i -e '/"sqlite3"/d' mailcatcher.gemspec
	sed -i -e '/"thin"/d' mailcatcher.gemspec

	eapply_user
	default
}