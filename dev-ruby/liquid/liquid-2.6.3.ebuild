# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
USE_RUBY="ruby31 ruby32 ruby33 ruby34"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_EXTRADOC="History.md README.md"

inherit ruby-fakegem

DESCRIPTION="Template engine for Ruby"
HOMEPAGE="https://shopify.github.io/liquid/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"

ruby_add_bdepend "test? ( >=dev-ruby/test-unit-2.5.1-r1 )"

each_ruby_test() {
	ruby-ng_testrb-2 -Ilib:test test/liquid/*_test.rb
}
