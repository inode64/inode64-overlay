# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
USE_RUBY="ruby30 ruby31 ruby32"

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
	    dev-ruby/actionpack
	    dev-ruby/activerecord
	    >=dev-ruby/bundler-1.7
	    dev-ruby/minitest
	    dev-ruby/mysql2
	    dev-ruby/vcard
	    dev-ruby/spreadsheet
	    >=dev-ruby/rake-10.0.0
	    <=dev-ruby/liquid-3.0.0
	    dev-ruby/rubyzip
"
