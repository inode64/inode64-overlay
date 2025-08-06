# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit bash-completion-r1 git-r3

DESCRIPTION="Dependency Manager for PHP"
HOMEPAGE="https://github.com/composer/composer"
SRC_URI="https://raw.githubusercontent.com/inode64/inode64-overlay/main/dist/${P}-vendor.tar.xz"

EGIT_REPO_URI="https://github.com/${PN}/${PN}"
EGIT_COMMIT="b4e6bff2db7ce756ddb77ecee958a0f41f42bd9d"
EGIT_BRANCH="2.8"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
IUSE="doc"
DOCS="CHANGELOG.md README.md"

src_unpack() {
	git-r3_src_unpack
	unpack ${P}-vendor.tar.xz
}

src_compile() {
	php --define memory_limit=-1 -d phar.readonly=Off bin/compile || die
	mv composer.phar composer
	chmod +x composer
	./composer completion bash > completion.bash || die
}

src_test() {
	if has usersandbox ${FEATURES} || has network-sandbox ${FEATURES}; then
		ewarn "Some tests may fail with FEATURES=usersandbox or"
		ewarn "FEATURES=network-sandbox; Skipping tests because"
		ewarn "test suite would hang forever in such environments!"
		return 0;
	fi

	mkdir integration-test
	cd integration-test

	../composer init \
		--no-interaction \
		--type=project \
		--name='gentoo/test' \
		--description='Composer Test Project' \
		--license='GPL-3.0-or-later' \
		--require='symfony/console:*' || die
	../composer update --no-interaction --no-progress --prefer-dist || die
	../composer validate --no-interaction || die
}

src_install() {
	dobin "${PN}"
	newbashcomp completion.bash composer
	if use doc; then
		dodoc -r doc
	fi
}
