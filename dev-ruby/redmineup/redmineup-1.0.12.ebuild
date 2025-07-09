# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
USE_RUBY="ruby31 ruby32 ruby33 ruby34"

RUBY_FAKEGEM_EXTRADOC="README.md doc/CHANGELOG"
RUBY_FAKEGEM_EXTRAINSTALL="config"

inherit ruby-fakegem

DESCRIPTION="Common libraries for RedmineCRM plugins for Redmine"
HOMEPAGE="https://www.redminecrm.com/
	https://rubygems.org/gems/redmine_crm/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

ruby_add_rdepend "
	    dev-ruby/rails
	    >=dev-ruby/rake-10.0.0
	    =dev-ruby/liquid-4.0.4
	    dev-ruby/rubyzip
"
