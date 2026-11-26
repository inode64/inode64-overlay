# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PHP_EXT_NAME="apcu"
PHP_EXT_INI="yes"
PHP_EXT_ZENDEXT="no"
DOCS=( NOTICE README.md TECHNOTES.txt TODO )
USE_PHP="php5-6"

inherit php-ext-pecl-r3

DESCRIPTION="Stripped down version of APC supporting only user cache"
LICENSE="PHP-3.01"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
IUSE="+mmap"

LOCKS="pthreadmutex pthreadrw spinlock"

LUSE=""
for l in ${LOCKS}; do
	LUSE+="lock-${l} "
done

IUSE+=" ${LUSE/lock-pthreadrw/+lock-pthreadrw}"

REQUIRED_USE="^^ ( ${LUSE} )"

# PHP5 branch commits 3a34c956 and 20a56cd0 are left out on purpose: they
# disable the CLI cache with zend_alter_ini_entry() in MINIT, whose startup
# allocations are freed before the first request, corrupting memory in every
# CLI run with apc.enable_cli=0. The 5.x branch reverted them in 78e515b.
PATCHES=(
	"${FILESDIR}/fbec873118715249f072b32ddd08e5014176cfe2.patch"
	"${FILESDIR}/4314aad7e505c45d1fb7cdd01c9a6e1d766d29fc.patch"
	"${FILESDIR}/6209f405a35f31b1f76f128c530f6874677031f4.patch"
	"${FILESDIR}/f289c2dd31247a4e0433eff061ae53afb49fc99a.patch"
	"${FILESDIR}/${PN}-4.0.11-gcc14-c23.patch"
	# Backports from the 5.x branch, rebased on the patches above
	"${FILESDIR}/${PN}-4.0.11-update-bailout.patch"
	"${FILESDIR}/${PN}-4.0.11-insert-lock-recursion.patch"
	"${FILESDIR}/${PN}-4.0.11-serialize-lock.patch"
	"${FILESDIR}/${PN}-4.0.11-iterator-search-leak.patch"
	"${FILESDIR}/${PN}-4.0.11-expunge-contiguous-block.patch"
	"${FILESDIR}/${PN}-4.0.11-apc-php-timeout-sort.patch"
	"${FILESDIR}/${PN}-4.0.11-iterator-unlocked-unserialize.patch"
	# Not fixed upstream yet; also prepared for the 5.x branch
	"${FILESDIR}/${PN}-4.0.11-iterator-deleted-list.patch"
)

pkg_setup() {
	export SED="${BROOT}/bin/sed"
}

src_configure() {
	local PHP_EXT_ECONF_ARGS=(
		--enable-apcu
		$(use_enable mmap apcu-mmap)
		$(use_enable lock-pthreadrw apcu-rwlocks)
		$(use_enable lock-spinlock apcu-spinlocks)
	)

	php-ext-source-r3_src_configure
}

src_install() {
	php-ext-pecl-r3_src_install

	insinto /usr/share/php/apcu
	doins apc.php
}

pkg_postinst() {
	elog "The apc.php file shipped with this release of pecl-apcu was"
	elog "installed into ${EPREFIX}/usr/share/php/apcu/."
}
