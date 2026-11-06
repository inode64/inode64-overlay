# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )

inherit autotools systemd python-r1

DESCRIPTION="A high-performance caching HTTP reverse proxy"
HOMEPAGE="https://vinyl-cache.org/"
SRC_URI="https://vinyl-cache.org/downloads/${P}.tgz"

LICENSE="BSD-2 GPL-2"
SLOT="0/9"
KEYWORDS="amd64"
IUSE="jit selinux static-libs unwind"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

# configure takes libedit before readline, so readline is never linked
COMMON_DEPEND="
	dev-libs/libedit
	dev-libs/libpcre2[jit?]
	sys-libs/ncurses:=
	unwind? ( sys-libs/libunwind:= )
"
# vinyld compiles the VCL at run time with the C compiler of @system.
RDEPEND="
	${PYTHON_DEPS}
	${COMMON_DEPEND}
	acct-user/vinyl
	selinux? ( sec-policy/selinux-varnishd )
"
# fowners in src_install needs the account at build time.
DEPEND="
	${COMMON_DEPEND}
	acct-user/vinyl
"
# rst2man comes from dev-python/docutils, which sphinx pulls in
BDEPEND="
	${PYTHON_DEPS}
	dev-python/sphinx
"

# Upstream acknowledge that a small number of tests fail sporadically, including on their
# test boxes. We SKIP problematic tests here.  Check https://vinyl-cache.org/vtest/
SKIP_TESTS=(
	"u00021.vtc" # Commit: 83d9fbb2961c
	"r02686.vtc" # Bug: 880627
	"r02990.vtc" # Bug: 880627
	"u00008.vtc" # Bug: 880627
	"u00009.vtc" # Bug: 880627
	"t02014.vtc" # Bug: 964041
	"r03996.vtc" # Bug: 982112
)

src_prepare() {
	default

	# Fix python shebangs for python-exec[-native-symlinks], #909330
	# skip vmodtool, as that gets installed by python_replicate_script later
	local shebangs=($(grep -rl "#!/usr/bin/env python3"|grep -v vmodtool || die))
	python_setup
	python_fix_shebang -q ${shebangs[*]}

	# SKIP unreliable tests
	local t
	for t in ${SKIP_TESTS[*]}; do
		sed -i -e '/^vtest.*$/a feature cmd false' bin/vinyltest/tests/${t} || die
	done

	# Remove -Werror bug #528354
	sed -i -e 's/-Werror\([^=]\)/\1/g' configure.ac || die

	# Upstream doesn't put vinyl.m4 in the m4/ directory
	# We link because the Makefiles look for the file in
	# the original location
	ln -sf ../vinyl.m4 m4/vinyl.m4 || die

	eautoreconf
}

src_configure() {
	local myeconfargs=(
		--with-contrib
		$(use_enable static-libs static)
		$(use_enable jit pcre2-jit)
		$(use_with unwind)
		--without-jemalloc
		--with-statedir="/var/lib/${PN}"
	)
	econf "${myeconfargs[@]}"
}

src_install() {
	emake DESTDIR="${D}" install

	python_replicate_script "${D}/usr/share/vinyl-cache/vmodtool.py"

	# From https://code.vinyl-cache.org/vinyl-cache/pkg-vinyl-cache
	# (systemd/vinylreload, 27c9130); the reload of both init systems.
	dosbin "${FILESDIR}"/vinylreload

	newinitd "${FILESDIR}"/vinyllog.initd-r1 vinyllog
	newconfd "${FILESDIR}"/vinyllog.confd-r1 vinyllog

	newinitd "${FILESDIR}"/vinylncsa.initd-r1 vinylncsa
	newconfd "${FILESDIR}"/vinylncsa.confd-r1 vinylncsa

	newinitd "${FILESDIR}"/vinyld.initd-r1 vinyld
	newconfd "${FILESDIR}"/vinyld.confd-r1 vinyld

	insinto /etc/logrotate.d/
	newins "${FILESDIR}/vinyld.logrotate-r1" vinyld

	diropts -m750

	keepdir /var/lib/vinyl-cache
	keepdir /var/log/vinyl-cache

	systemd_newunit "${FILESDIR}"/vinyld.service-r1 vinyld.service
	systemd_dounit "${FILESDIR}"/vinylncsa.service

	insinto /etc/vinyl-cache/
	doins vmod/vmod_*.vcc
	doins etc/example.vcl

	dodoc README.md
	dodoc doc/changes.rst

	fowners root:vinyl /etc/vinyl-cache/
	fowners vinyl:vinyl /var/lib/vinyl-cache/
	fperms 0750 /var/lib/vinyl-cache/ /etc/vinyl-cache/

	find "${ED}" -name "*.la" -delete || die
}

pkg_postinst() {
	if [[ ! -e ${EROOT}/etc/vinyl-cache/default.vcl ]]; then
		elog "vinyld loads /etc/vinyl-cache/default.vcl; start from"
		elog "/etc/vinyl-cache/example.vcl."
	fi
	if [[ -d ${EROOT}/var/log/vinyl ]]; then
		ewarn "Earlier versions wrote the vinylncsa and vinyllog logs to /var/log/vinyl"
		ewarn "but installed /var/log/vinyl-cache.  The defaults and logrotate now use"
		ewarn "/var/log/vinyl-cache only: change the -w paths in /etc/conf.d/vinylncsa*"
		ewarn "and /etc/conf.d/vinyllog*, and move the old logs."
	fi
}
