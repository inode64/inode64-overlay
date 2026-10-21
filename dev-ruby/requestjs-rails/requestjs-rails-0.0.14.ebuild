# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

USE_RUBY="ruby32 ruby33 ruby34 ruby40"

RUBY_FAKEGEM_BINWRAP=""
RUBY_FAKEGEM_EXTRADOC="README.md"
RUBY_FAKEGEM_EXTRAINSTALL="app config"
# The gem does not ship any tests
RUBY_FAKEGEM_RECIPE_TEST="none"

inherit ruby-fakegem

DESCRIPTION="Rails integration for the @rails/request.js Fetch API wrapper"
HOMEPAGE="https://github.com/marcelolx/requestjs-rails"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

ruby_add_rdepend ">=dev-ruby/railties-7.1.0:*"
