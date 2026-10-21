# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

USE_RUBY="ruby32 ruby33 ruby34 ruby40"

# rougify is provided by dev-ruby/rouge:4
RUBY_FAKEGEM_BINWRAP=""
# The gem does not ship any tests
RUBY_FAKEGEM_RECIPE_TEST="none"

inherit ruby-fakegem

DESCRIPTION="A pure-ruby colorizer based on pygments"
HOMEPAGE="https://github.com/rouge-ruby/rouge"

LICENSE="BSD-2 MIT"
SLOT="$(ver_cut 1)"
KEYWORDS="~amd64"

ruby_add_rdepend ">=dev-ruby/strscan-3.1:3"
