# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3 optfeature shell-completion

DESCRIPTION="Dependency Manager for PHP"
HOMEPAGE="https://github.com/composer/composer"
SRC_URI="https://www.inode64.com/dist/${P}-vendor.tar.xz"

EGIT_REPO_URI="https://github.com/${PN}/${PN}"
EGIT_COMMIT="e4a580d4d41edb0eb5a470f441c9780ba49df75f"
EGIT_BRANCH="main"

LICENSE="MIT"
# Dependent licenses
LICENSE+=" BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
IUSE="doc"
DOCS=( CHANGELOG.md README.md )

RDEPEND="
	app-arch/unzip
	>=dev-lang/php-7.2.5:*[cli,filter,iconv,phar,ssl]
"
BDEPEND="${RDEPEND}"

src_unpack() {
	git-r3_src_unpack
	if has ${P}-vendor.tar.xz ${A}; then
		unpack ${P}-vendor.tar.xz
	fi
}

src_compile() {
	php --define memory_limit=-1 -d phar.readonly=Off bin/compile || die
	mv composer.phar composer || die
	chmod +x composer || die
	./composer completion bash > completion.bash || die
}

src_test() {
	if has usersandbox ${FEATURES} || has network-sandbox ${FEATURES}; then
		ewarn "Some tests may fail with FEATURES=usersandbox or"
		ewarn "FEATURES=network-sandbox; Skipping tests because"
		ewarn "test suite would hang forever in such environments!"
		return 0;
	fi

	mkdir integration-test || die
	cd integration-test || die

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
	einstalldocs
	if use doc; then
		dodoc -r doc
	fi
}

pkg_postinst() {
	optfeature "HTTP downloads through curl instead of PHP streams" "dev-lang/php[curl]"
	optfeature "extracting ZIP archives without unzip or 7z" "dev-lang/php[zip]"
	optfeature "gzip compressed HTTP requests" "dev-lang/php[zlib]"
	optfeature "Git repositories" dev-vcs/git
	optfeature "Subversion repositories" dev-vcs/subversion
	optfeature "Mercurial repositories" dev-vcs/mercurial
	optfeature "Fossil repositories" dev-vcs/fossil
}
