# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

USE_RUBY="ruby32 ruby33 ruby34 ruby40"

RUBY_FAKEGEM_BINWRAP=""
RUBY_FAKEGEM_EXTRADOC="README.md"
RUBY_FAKEGEM_EXTRAINSTALL="rails"
# Tests require dev-ruby/i18n-spec, not packaged
RUBY_FAKEGEM_RECIPE_TEST="none"

inherit ruby-fakegem

DESCRIPTION="Translations for doorkeeper rubygem"
HOMEPAGE="https://github.com/doorkeeper-gem/doorkeeper-i18n"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

ruby_add_rdepend ">=dev-ruby/doorkeeper-5.2"
