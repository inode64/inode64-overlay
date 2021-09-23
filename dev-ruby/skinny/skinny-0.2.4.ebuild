# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
USE_RUBY="ruby25 ruby26 ruby27"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_DOCDIR=""
RUBY_FAKEGEM_EXTRADOC="README.md"

inherit ruby-fakegem

DESCRIPTION="Simple, upgradable Thin WebSockets."
HOMEPAGE="https://github.com/sj26/skinny"
LICENSE="MIT"

SLOT="0"
KEYWORDS="~amd64"
IUSE=""

ruby_add_rdepend "
	dev-ruby/eventmachine
	>=www-server/thin-1.5 <www-server/thin-1.7
"
