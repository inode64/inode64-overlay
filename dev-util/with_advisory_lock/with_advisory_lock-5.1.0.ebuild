# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
USE_RUBY="ruby31 ruby32 ruby33"

RUBY_FAKEGEM_EXTRADOC="README.md CHANGELOG.md"

inherit ruby-fakegem

DESCRIPTION="Advisory locking for ActiveRecord"
HOMEPAGE="https://github.com/ClosureTree/with_advisory_lock
	    https://rubygems.org/gems/with_advisory_lock"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

ruby_add_rdepend "
	|| ( dev-ruby/activerecord[mysql] dev-ruby/activerecord[postgres] )
	dev-ruby/zeitwerk
"
