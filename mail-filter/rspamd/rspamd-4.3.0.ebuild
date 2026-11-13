# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

LUA_COMPAT=( lua5-{3..4} luajit )
PYTHON_COMPAT=( python3_{12..15} )

inherit cmake flag-o-matic lua-single optfeature pax-utils python-any-r1 systemd tmpfiles

if [[ ${PV} == *9999 ]] ; then
	EGIT_REPO_URI="https://github.com/rspamd/rspamd.git"
	inherit git-r3
else
	SRC_URI="https://github.com/rspamd/rspamd/archive/${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~arm64 ~x86"
fi

DESCRIPTION="Rapid spam filtering system"
HOMEPAGE="
	https://rspamd.com
	https://github.com/rspamd/rspamd
"

LICENSE="Apache-2.0 Boost-1.0 BSD BSD-1 BSD-2 CC0-1.0 LGPL-3 MIT public-domain unicode ZLIB"
SLOT="0"
IUSE="blas +hyperscan jemalloc +jit selinux test"
RESTRICT="!test? ( test )"

# A part of tests use ffi luajit extension
REQUIRED_USE="${LUA_REQUIRED_USE}
	test? ( lua_single_target_luajit )"

RDEPEND="
	${LUA_DEPS}
	$(lua_gen_cond_dep '
		dev-lua/LuaBitOp[${LUA_USEDEP}]
		dev-lua/lua-argparse[${LUA_USEDEP}]
	')
	acct-group/rspamd
	acct-user/rspamd
	app-arch/libarchive:=
	app-arch/zstd:=
	dev-db/sqlite:3
	dev-libs/glib:2
	dev-libs/icu:=
	dev-libs/libpcre2:=[jit=]
	dev-libs/libsodium:=
	dev-libs/openssl:0=[-bindist(-)]
	dev-libs/snowball-stemmer:=
	virtual/zlib:=
	blas? (
		virtual/blas
		virtual/lapack
	)
	hyperscan? ( dev-libs/vectorscan:= )
	jemalloc? ( dev-libs/jemalloc:= )
	selinux? ( sec-policy/selinux-spamassassin )
"
DEPEND="
	${RDEPEND}
	dev-cpp/doctest
	>=dev-libs/xxhash-0.8.0
"
# test/functional/util/hyperscan_cache_recovery.py, added only with hyperscan
BDEPEND="
	dev-lang/perl
	dev-util/ragel
	virtual/pkgconfig
	test? ( hyperscan? ( ${PYTHON_DEPS} ) )
"

PATCHES=(
	"${FILESDIR}/${PN}-3.12-cmake-lua-version.patch"
	"${FILESDIR}/${PN}-4.2-unbundle-lua.patch"
	"${FILESDIR}/${PN}-3.12-unbundle-snowball.patch"
)

pkg_setup() {
	lua-single_pkg_setup
	use test && use hyperscan && python-any-r1_pkg_setup
}

src_prepare() {
	cmake_src_prepare

	rm -vrf contrib/{doctest,lua-{argparse,bit},snowball,xxhash,zstd} || die

	> cmake/Toolset.cmake || die #827550

	# After= alone does not pull network-online.target into the boot
	sed -i -e 's/User=_rspamd/User=rspamd/g' \
		-e '/^After=/a Wants=network-online.target' \
		rspamd.service \
		|| die
}

src_configure() {
	local mycmakeargs=(
		-DCONFDIR=/etc/rspamd
		-DRUNDIR=/var/run/rspamd
		-DDBDIR=/var/lib/rspamd
		-DLOGDIR=/var/log/rspamd
		-DLIBDIR="/usr/$(get_libdir)/rspamd"

		-DSYSTEM_DOCTEST=ON
		-DSYSTEM_XXHASH=ON
		-DSYSTEM_ZSTD=ON

		# For bundled https://github.com/bombela/backward-cpp
		# Bundled backward library uses execinfo.h in current setting, which is
		# available in glibc, but not in musl. Let's enable it for glibc only.
		-DENABLE_BACKWARD=$(usex elibc_glibc ON OFF) # bug 917643

		-DENABLE_BLAS=$(usex blas ON OFF)
		-DENABLE_HYPERSCAN=$(usex hyperscan ON OFF)
		# Since 4.1.4 upstream links one shared jemalloc per process and pins
		# it against --as-needed (cmake/Jemalloc.cmake), the cause of bug 810337
		-DENABLE_JEMALLOC=$(usex jemalloc ON OFF)
		-DENABLE_LUAJIT=$(usex lua_single_target_luajit ON OFF)
		-DENABLE_PCRE2=ON

		-DBUILD_TESTING=$(usex test ON OFF)
	)
	# Only contrib/backward-cpp reads it: passing it without backward makes
	# CMake warn that the variable is unused (bug 920173)
	use elibc_glibc && mycmakeargs+=( -DSTACK_DETAILS_AUTO_DETECT=OFF )

	# test/ is always built. With clang >= 22 the system doctest >= 2.5 names
	# its anonymous symbols after __LINE__, and the suites that
	# test/rspamd_cxx_unit.cxx includes collide on the same lines
	append-cppflags -DDOCTEST_COUNTER=__COUNTER__

	cmake_src_configure
}

src_test() {
	# These variables ensure tests use Lua scripts from this package rather
	# than the installed version. However, rspamd always first attempts to load
	# from /etc/rspamd/lua, with no method to override this behavior.
	LUA_PATH="${S}/contrib/lua-?/?.lua;$(lua_get_lmod_dir)/?.lua" \
	LUALIBDIR="${S}/lualib" \
	RULESDIR="${S}/lualib" \
	cmake_src_test
}

src_install() {
	cmake_src_install

	newconfd "${FILESDIR}"/rspamd.conf rspamd
	newinitd "${FILESDIR}/rspamd-r8.init" rspamd
	systemd_newunit rspamd.service rspamd.service

	newtmpfiles "${FILESDIR}"/${PN}.tmpfile ${PN}.conf

	# Remove mprotect for JIT support
	if use lua_single_target_luajit; then
		pax-mark m "${ED}"/usr/bin/rspamd-* "${ED}"/usr/bin/rspamadm-*
	fi

	insinto /etc/logrotate.d
	newins "${FILESDIR}"/rspamd-r2.logrotate rspamd

	# DKIM keys, Bayes and fuzzy databases, and logs with mail addresses
	diropts -m0750 -o rspamd -g rspamd
	keepdir /var/{lib,log}/rspamd
}

pkg_postinst() {
	tmpfiles_process "${PN}.conf"

	optfeature "the rspamd_stats and mapstats log tools" dev-lang/perl

	# bug 968855
	if ! use lua_single_target_luajit; then
		elog "Upstream develops and tests rspamd mainly with LuaJIT. If a plugin"
		elog "fails with PUC Lua, set LUA_SINGLE_TARGET=\"luajit\" for ${CATEGORY}/${PN}."
	fi
}
