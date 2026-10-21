# Copyright 2024-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

USE_RUBY="ruby33 ruby34 ruby40"

RUBY_FAKEGEM_BINWRAP=""
RUBY_FAKEGEM_EXTRADOC="CHANGELOG.md README.md"
# Tests need running MySQL and PostgreSQL servers
RUBY_FAKEGEM_RECIPE_TEST="none"
RUBY_FAKEGEM_RECIPE_DOC="none"

inherit ruby-fakegem

DESCRIPTION="Advisory locking for ActiveRecord"
HOMEPAGE="https://github.com/ClosureTree/with_advisory_lock"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

ruby_add_rdepend ">=dev-ruby/activerecord-7.2:*"
