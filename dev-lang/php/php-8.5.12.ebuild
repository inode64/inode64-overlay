# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

WANT_AUTOMAKE="none"
POSTGRES_COMPAT=( {15..18} )
inherit flag-o-matic multilib multiprocessing postgres systemd toolchain-funcs

DESCRIPTION="The PHP language runtime engine"
HOMEPAGE="https://www.php.net/"
SRC_URI="https://www.php.net/distributions/${P}.tar.xz"

LICENSE="PHP-3.01
	BSD
	Zend-2.0
	bcmath? ( LGPL-2.1+ )
	fpm? ( BSD-2 )
	unicode? ( BSD-2 LGPL-2.1 )"

SLOT="$(ver_cut 1-2)"
KEYWORDS="~alpha amd64 ~arm arm64 ~hppa ~loong ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc x86 ~x64-macos"

# We can build the following SAPIs in the given order.
ALL_SAPIS=( embed cli cgi fpm apache2 phpdbg )

# Will populate this in src_configure() when USE is known.
ENABLED_SAPIS=()

# SAPIs and SAPI-specific USE flags (cli SAPI is default on).
IUSE="${IUSE}
	${ALL_SAPIS[@]/cli/+cli}
	threads"

IUSE="${IUSE} acl apparmor argon2 avif bcmath berkdb bzip2 calendar
	capstone cdb +ctype curl debug
	enchant exif ffi +fileinfo +filter
	+flatfile ftp gd gdbm gmp +iconv inifile
	intl iodbc ipv6 +jit jpeg ldap ldap-sasl libedit lmdb lto pgo
	mhash mssql mysql mysqli nls
	odbc +opcache-jit pcntl pdo +phar +posix postgres png
	qdbm readline selinux +session session-mm sharedmem
	+simplexml snmp soap sockets sodium spell sqlite ssl sysvipc
	systemd test test-full tidy +tokenizer tokyocabinet truetype
	unicode valgrind webp +xml xmlreader xmlwriter xpm xslt zip zlib"

# Without USE=readline or libedit, the interactive "php -a" CLI will hang.
REQUIRED_USE="
	|| ( cli cgi fpm apache2 embed phpdbg )
	cli? ( ^^ ( readline libedit ) )
	!cli? ( ?? ( readline libedit ) )
	gd? ( zlib )
	simplexml? ( xml )
	soap? ( xml )
	xmlreader? ( xml )
	xmlwriter? ( xml )
	xslt? ( xml )
	ldap-sasl? ( ldap )
	qdbm? ( !gdbm )
	session-mm? ( session !threads )
	mysql? ( || ( mysqli pdo ) )
	mssql? ( pdo )
	test? ( cli )
	pgo? ( cli )
	postgres? ( ${POSTGRES_REQ_USE} )
"

RESTRICT="!test? ( test )"

# The supported (that is, autodetected) versions of BDB are listed in
# the ./configure script. Other versions *work*, but we need to stick to
# the ones that can be detected to avoid a repeat of bug #564824.
#
# Require at least libcrypt-2-r1 so that on musl systems we pull in
# sys-libs/libxcrypt (i.e. cannot use the musl crypt implementation).
COMMON_DEPEND="
	app-eselect/eselect-php[apache2?,fpm?]
	dev-libs/libpcre2[jit?,unicode]
	dev-libs/uriparser
	>=virtual/libcrypt-2-r1:=
	fpm? ( acl? ( sys-apps/acl ) apparmor? ( sys-libs/libapparmor ) selinux? ( sys-libs/libselinux ) )
	apache2? ( www-servers/apache[apache2_modules_unixd(+),threads=] )
	argon2? ( app-crypt/argon2:= )
	berkdb? ( || (	sys-libs/db:5.3 sys-libs/db:4.8 ) )
	bzip2? ( app-arch/bzip2:0= )
	capstone? ( dev-libs/capstone )
	cdb? ( || ( dev-db/cdb dev-db/tinycdb ) )
	curl? ( net-misc/curl )
	enchant? ( app-text/enchant:2 )
	ffi? ( dev-libs/libffi:= )
	gd? (
		>=media-libs/gd-2.3.3-r4[avif?,jpeg?,png?,truetype?,webp?,xpm?]
	)
	gdbm? ( sys-libs/gdbm:0= )
	gmp? ( dev-libs/gmp:0= )
	iconv? ( virtual/libiconv )
	intl? ( dev-libs/icu:= )
	ldap? ( net-nds/openldap:= )
	ldap-sasl? ( dev-libs/cyrus-sasl )
	libedit? ( dev-libs/libedit )
	lmdb? ( dev-db/lmdb:= )
	mssql? ( dev-db/freetds[mssql] )
	nls? ( virtual/libintl )
	odbc? ( iodbc? ( dev-db/libiodbc ) !iodbc? ( dev-db/unixODBC ) )
	postgres? ( ${POSTGRES_DEP} )
	qdbm? ( dev-db/qdbm )
	readline? ( sys-libs/readline:0= )
	session-mm? ( dev-libs/mm )
	snmp? ( net-analyzer/net-snmp:= )
	sodium? ( dev-libs/libsodium:=[-minimal(-)] )
	spell? ( app-text/aspell )
	sqlite? ( dev-db/sqlite )
	ssl? ( dev-libs/openssl:0= )
	tidy? ( app-text/htmltidy )
	tokyocabinet? ( dev-db/tokyocabinet )
	truetype? ( media-libs/freetype )
	unicode? ( dev-libs/oniguruma:= )
	valgrind? ( dev-debug/valgrind )
	xml? ( >=dev-libs/libxml2-2.12.5:= )
	xslt? ( dev-libs/libxslt )
	zip? ( dev-libs/libzip:= )
	zlib? ( virtual/zlib:= )
"

IDEPEND="app-eselect/eselect-php[apache2?,fpm?]"

RDEPEND="${COMMON_DEPEND}
	virtual/mta
	fpm? (
		selinux? ( sec-policy/selinux-phpfpm )
		systemd? ( sys-apps/systemd ) )"

# Bison isn't actually needed when building from a release tarball
# However, the configure script will warn if it's absent or if you
# have an incompatible version installed. See bug 593278.
DEPEND="${COMMON_DEPEND}
	app-arch/xz-utils
	sys-devel/bison"

BDEPEND="virtual/pkgconfig"

PATCHES=(
	"${FILESDIR}/php-set-fpm-test-executable.patch"
	"${FILESDIR}/php-8.3.31-ipv6-printing-test-fix.patch"
	"${FILESDIR}/php-8.5-musl-pathconf.patch"
)

PHP_MV="$(ver_cut 1)"

# ARM/Windows functions (bug 923335)
QA_CONFIG_IMPL_DECL_SKIP=(
	__crc32d
	_controlfp
	_controlfp_s
)

# Functions from alternate iconv implementations (bug 925268)
QA_CONFIG_IMPL_DECL_SKIP+=(
	iconv_ccs_init
	cstoccsid
)

php_install_ini() {
	local phpsapi="${1}"

	# work out where we are installing the ini file
	php_set_ini_dir "${phpsapi}"

	# Always install the production INI file, bug 611214.
	local phpinisrc="php.ini-production-${phpsapi}"
	cp php.ini-production "${phpinisrc}" || die

	# Set the include path to point to where we want to find PEAR
	# packages
	local sed_src='^;include_path = ".:/php.*'
	local include_path="."
	include_path+=":${EPREFIX}/usr/share/php${PHP_MV}"
	include_path+=":${EPREFIX}/usr/share/php"
	local sed_dst="include_path = \"${include_path}\""
	sed -e "s|${sed_src}|${sed_dst}|" -i "${phpinisrc}" || die

	insinto "${PHP_INI_DIR#"${EPREFIX}"}"
	newins "${phpinisrc}" php.ini

	elog "Installing php.ini for ${phpsapi} into ${PHP_INI_DIR#"${EPREFIX}"}"
	elog

	dodir "${PHP_EXT_INI_DIR#"${EPREFIX}"}"
	dodir "${PHP_EXT_INI_DIR_ACTIVE#"${EPREFIX}"}"

	# SAPI-specific handling
	if [[ "${sapi}" == "fpm" ]] ; then
		einfo "Installing FPM config files php-fpm.conf and www.conf"
		insinto "${PHP_INI_DIR#"${EPREFIX}"}"
		doins sapi/fpm/php-fpm.conf
		insinto "${PHP_INI_DIR#"${EPREFIX}"}/fpm.d"
		doins sapi/fpm/www.conf
	fi

	dodoc php.ini-{development,production}
}

php_set_ini_dir() {
	PHP_INI_DIR="${EPREFIX}/etc/php/${1}-php${SLOT}"
	PHP_EXT_INI_DIR="${PHP_INI_DIR}/ext"
	PHP_EXT_INI_DIR_ACTIVE="${PHP_INI_DIR}/ext-active"
}

pkg_setup() {
	use postgres && postgres_pkg_setup

	if [[ ${MERGE_TYPE} != binary ]] && use pgo ; then
		# Training executes the newly built CLI on the build machine.
		tc-is-cross-compiler && die "USE=pgo requires a native build"
		# LLVM merges the profile of every training process into one shared
		# .profraw, and halfway through the test suite it ends up corrupt
		# ("Invalid profile data to merge"); every later test then fails.
		if ! tc-is-gcc ; then
			ewarn "USE=pgo is only supported with GCC; building without a profile."
		fi
	fi
}

src_prepare() {
	default

	# In src_configure() we make several copies of the source tree, so
	# it is extra worthwhile to delete the unused bundled copies of
	# these libraries.
	rm -r ext/gd/libgd ext/uri/uriparser ext/pcre/pcre2lib || die

	# In php-8.x, the FPM pool configuration files have been split off
	# of the main config. By default the pool config files go in
	# e.g. /etc/php-fpm.d, which isn't slotted. So here we move the
	# include directory to a subdirectory "fpm.d" of $PHP_INI_DIR. Later
	# we'll install the pool configuration file "www.conf" there.
	php_set_ini_dir fpm
	sed -i "s~^include=.*$~include=${PHP_INI_DIR}/fpm.d/*.conf~" \
		sapi/fpm/php-fpm.conf.in \
		|| die 'failed to move the include directory in php-fpm.conf'

	# The ./configure script creates this symlink, but we run the tests
	# in ${S} rather than in a SAPI-specicific copy where ./configure
	# was run. Easiest thing to do is recreate it under ${S}. Only
	# relevant for USE=nls on musl.
	ln -s en_US.UTF-8 ext/gettext/tests/locale/en_US || die

	# fails in a network sandbox,
	#
	#   https://github.com/php/php-src/issues/11662
	#
	rm ext/sockets/tests/bug63000.phpt || die

	# Tests ignoring the "-n" flag we pass to run-tests.php,
	#
	#   https://github.com/php/php-src/pull/11669
	#
	rm ext/standard/tests/file/bug60120.phpt \
	   ext/standard/tests/general_functions/proc_open_null.phpt \
	   ext/standard/tests/general_functions/proc_open_redirect.phpt \
	   ext/standard/tests/general_functions/proc_open_sockets1.phpt \
	   ext/standard/tests/general_functions/proc_open_sockets2.phpt \
	   ext/standard/tests/general_functions/proc_open_sockets3.phpt \
	   ext/standard/tests/ini_info/php_ini_loaded_file.phpt \
	   sapi/cli/tests/016.phpt \
	   sapi/cli/tests/023.phpt \
	   sapi/cli/tests/bug65275.phpt \
	   sapi/cli/tests/bug74600.phpt \
	   sapi/cli/tests/bug78323.phpt \
	   || die

	# Most tests failing with an external libgd have been fixed,
	# but there are a few stragglers:
	#
	#  * https://github.com/php/php-src/issues/11252
	#
	rm ext/gd/tests/bug43073.phpt \
	   ext/gd/tests/bug48732.phpt \
	   ext/gd/tests/bug48732-mb.phpt \
	   ext/gd/tests/bug48801.phpt \
	   ext/gd/tests/bug48801-mb.phpt \
	   ext/gd/tests/bug53504.phpt \
	   ext/gd/tests/bug65148.phpt \
	   ext/gd/tests/bug73272.phpt \
	   || die

	# Test requires USE=cdb, so we have to skip it when
	# the cdb USE flag is unset
	#
	#  * https://github.com/php/php-src/issues/19706
	#
	if ! use cdb; then
		rm ext/dba/tests/gh19706.phpt
	fi

	local virt=$(systemd-detect-virt 2>/dev/null)
	if [[ ${virt} == systemd-nspawn ]]; then
		# If we are in a container where certain system calls can fail
		# by design, don't test their PHP wrappers (bug 977402).
		einfo "systemd-nspawn detected, skipping fsync/nice tests"
		rm ext/standard/tests/file/fdatasync.phpt \
			ext/standard/tests/file/fsync.phpt \
			ext/standard/tests/general_functions/proc_nice_basic.phpt \
			|| die
	fi
}

src_configure() {
	# Loop through the list of all SAPIs, and consult the user's USE
	# flags to build the list of enabled ones. This avoids having to
	# loop and check over and over again.
	local sapi
	for sapi in "${ALL_SAPIS[@]}" ; do
		use "${sapi}" && ENABLED_SAPIS+=( "${sapi}" )
	done

	addpredict /usr/share/snmp/mibs/.index #nowarn
	addpredict /var/lib/net-snmp/mib_indexes #nowarn

	# PHP relies on IEEE NaN/Inf semantics, including timeout validation.
	replace-flags -Ofast -O3
	filter-flags -ffast-math -ffinite-math-only

	# https://bugs.gentoo.org/866683, https://bugs.gentoo.org/913527
	# Keep GCC's VM global register variables outside LTO after econf.
	if use lto; then
		if ! is-flagq '-flto*'; then
			if tc-is-clang; then
				append-flags -flto=thin
			else
				append-flags -flto=auto
			fi
		fi
		if tc-is-clang ; then
			# Bundled libtool drops -flto and -fuse-ld from the link of shared
			# modules, and without -flto Clang does not load the LTO plugin that
			# ld.bfd needs. Keep both in the compiler commands.
			local linkflags="$(get-flag '-flto*') -Wno-unused-command-line-argument" ldflag
			for ldflag in ${LDFLAGS} ; do
				[[ ${ldflag} == -fuse-ld=* ]] && linkflags+=" ${ldflag}"
			done
			export CC="$(tc-getCC) ${linkflags}"
			export CXX="$(tc-getCXX) ${linkflags}"
			# Only the LTO flag: test-flag-CCLD adds -Werror, and Clang merely warns
			# about GCC flags that a real build would accept.
			test-flag-CCLD "$(get-flag '-flto*')" \
				|| die "USE=lto needs a Clang LTO linker selected in CC or LDFLAGS (e.g. -fuse-ld=lld)"
		fi
	else
		filter-lto
	fi

	PHP_DESTDIR="${EPREFIX}/usr/$(get_libdir)/php${SLOT}"

	# Don't allow ./configure to detect and use an existing version
	# of PHP; this can lead to all sorts of weird unpredictability
	# as in bug 900210.
	export ac_cv_prog_PHP=""

	# The php-fpm config file wants localstatedir to be ${EPREFIX}/var
	# and not the Gentoo default ${EPREFIX}/var/lib. See bug 572002. We
	# use --sbindir=$bindir for backwards compatibility: in the past we
	# installed php-fpm to $bindir by hand, but now the upstream build
	# system puts it in $sbindir. If nothing else, eselect-php expects
	# it in $bindir.
	local our_conf=(
		--prefix="${PHP_DESTDIR}"
		--datadir="${PHP_DESTDIR}/share"
		--sbindir="${PHP_DESTDIR}/bin"
		--mandir="${PHP_DESTDIR}/man"
		--infodir="${PHP_DESTDIR}/info"
		--libdir="${PHP_DESTDIR}/lib"
		--with-libdir="$(get_libdir)"
		--localstatedir="${EPREFIX}/var"
		--without-pear
		--without-valgrind
		--with-external-libcrypt
		$(use_enable threads zts)
	)

	# The slotted man/info pages will be missed by the default list of
	# docompress paths.
	docompress "${PHP_DESTDIR}/man" "${PHP_DESTDIR}/info"

	our_conf+=(
		$(use_with apparmor fpm-apparmor)
		$(use_with argon2 password-argon2 "${EPREFIX}/usr")
		$(use_enable bcmath)
		$(use_with bzip2 bz2 "${EPREFIX}/usr")
		$(use_enable calendar)
		$(use_with capstone)
		$(use_enable ctype)
		$(use_with curl)
		$(use_enable xml dom)
		$(use_with enchant)
		$(use_enable exif)
		$(use_with ffi)
		$(use_enable fileinfo)
		$(use_enable filter)
		$(use_enable ftp)
		$(use_with nls gettext "${EPREFIX}/usr")
		$(use_with gmp gmp "${EPREFIX}/usr")
		$(use_with mhash mhash "${EPREFIX}/usr")
		$(use_with iconv iconv \
			$(use elibc_glibc || use elibc_musl || echo "${EPREFIX}/usr"))
		$(use_enable intl)
		$(use_enable ipv6)
		$(use_with xml libxml)
		$(use_enable unicode mbstring)
		$(use_with ssl openssl)
		$(use_enable pcntl)
		$(use_enable phar)
		$(use_enable pdo)
		$(use_enable opcache-jit)
		$(use_with postgres pgsql "$("${PG_CONFIG:-true}" --bindir)/..")
		$(use_enable posix)
		$(use_with selinux fpm-selinux)
		$(use_enable simplexml)
		$(use_enable sharedmem shmop)
		$(use_with snmp snmp "${EPREFIX}/usr")
		$(use_enable soap)
		$(use_enable sockets)
		$(use_with sodium)
		$(use_with sqlite sqlite3)
		$(use_enable sysvipc sysvmsg)
		$(use_enable sysvipc sysvsem)
		$(use_enable sysvipc sysvshm)
		$(use_with tidy tidy "${EPREFIX}/usr")
		$(use_enable tokenizer)
		$(use_enable xml)
		$(use_enable xmlreader)
		$(use_enable xmlwriter)
		$(use_with xslt xsl)
		$(use_with zip)
		$(use_with zlib zlib "${EPREFIX}/usr")
		$(use_enable debug)
		$(use_with valgrind)
	)

	# Override autoconf cache variables for libcrypt. The algorithms
	# otherwise cannot be detected when cross-compiling (bug 931884),
	# and on musl systems, AC_SEARCH_LIBS misses that -lcrypt is needed
	# to use the intended libcrypt (rather than the built in musl crypt
	# functions whose headers have been deleted -- this is a Gentooism).
	our_conf+=(
		ac_cv_crypt_blowfish=yes
		ac_cv_crypt_des=yes
		ac_cv_crypt_ext_des=yes
		ac_cv_crypt_md5=yes
		ac_cv_crypt_sha512=yes
		ac_cv_crypt_sha256=yes
		ac_cv_search_crypt='-lcrypt'
		ac_cv_search_crypt_r='-lcrypt'
	)

	if use posix; then
		# Avoid needing to patch/eautoreconf to enable these functions
		# on musl. They are perfectly POSIX-compliant, and of course
		# glibc has them too. Obsolete when
		#
		#   https://github.com/php/php-src/pull/22717
		#
		# is merged.
		append-cppflags -DHAVE_PATHCONF=1 -DHAVE_FPATHCONF=1
	fi

	# DBA support
	if use cdb || use berkdb || use flatfile || use gdbm || use inifile \
		|| use qdbm || use lmdb || use tokyocabinet ; then
		our_conf+=( "--enable-dba" )
	fi

	# DBA drivers support
	our_conf+=(
		$(use_with cdb)
		$(use_with berkdb db4 "${EPREFIX}/usr")
		$(use_enable flatfile)
		$(use_with gdbm gdbm "${EPREFIX}/usr")
		$(use_enable inifile)
		$(use_with qdbm qdbm "${EPREFIX}/usr")
		$(use_with tokyocabinet tcadb "${EPREFIX}/usr")
		$(use_with lmdb lmdb "${EPREFIX}/usr")
	)

	# Use the system copy of GD. The autoconf cache variable overrides
	# allow cross-compilation to proceed since the corresponding
	# features cannot be detected by running a program.
	our_conf+=(
		$(use_enable gd gd)
		$(use_with gd external-gd)
		php_cv_lib_gd_gdImageCreateFromAvif=$(usex avif)
		php_cv_lib_gd_gdImageCreateFromBmp=yes
		php_cv_lib_gd_gdImageCreateFromJpeg=$(usex jpeg)
		php_cv_lib_gd_gdImageCreateFromPng=$(usex png)
		php_cv_lib_gd_gdImageCreateFromTga=yes
		php_cv_lib_gd_gdImageCreateFromWebp=$(usex webp)
		php_cv_lib_gd_gdImageCreateFromXpm=$(usex xpm)
	)

	# LDAP support
	if use ldap ; then
		our_conf+=(
			$(use_with ldap ldap "${EPREFIX}/usr")
			$(use_with ldap-sasl)
		)
	fi

	# MySQL support
	our_conf+=( $(use_with mysqli) )

	local mysqlsock="${EPREFIX}/var/run/mysqld/mysqld.sock"
	if use mysql || use mysqli ; then
		our_conf+=( $(use_with mysql mysql-sock "${mysqlsock}") )
	fi

	# ODBC support
	if use odbc && use iodbc ; then
		# Obtain the correct -l and -I flags for the actual build from
		# pkg-config. We use the "generic" library type to avoid the
		# (wrong) hard-coded include dir for iodbc.
		#
		# We set the pdo_odbc_def_incdir variable because the
		# ./configure script checks for the headers using "test -f" and
		# ignores your CFLAGS... and pdo_odbc_def_libdir prevents the
		# build system from appending a nonsense -L flag.
		local iodbc_ldflags=$($(tc-getPKG_CONFIG) --libs libiodbc)
		local iodbc_cflags=$($(tc-getPKG_CONFIG) --cflags libiodbc)
		our_conf+=(
			pdo_odbc_def_libdir="${EPREFIX}/usr/$(get_libdir)"
			pdo_odbc_def_incdir="${EPREFIX}/usr/include/iodbc"
			--without-unixODBC
			--with-iodbc
			$(use_with pdo pdo-odbc "generic,,iodbc,${iodbc_ldlags},${iodbc_cflags}")
		)
	elif use odbc ; then
		our_conf+=(
			--with-unixODBC="${EPREFIX}/usr"
			--without-iodbc
			$(use_with pdo pdo-odbc "unixODBC,${EPREFIX}/usr")
		)
	else
		our_conf+=(
			--without-unixODBC
			--without-iodbc
			--without-pdo-odbc
		)
	fi

	# PDO support, sqlite is the only one enabled by default.
	our_conf+=( --without-pdo-sqlite )
	if use pdo ; then
		our_conf+=(
			$(use_with mssql pdo-dblib "${EPREFIX}/usr")
			$(use_with mysql pdo-mysql "mysqlnd")
			$(use_with postgres pdo-pgsql)
			$(use_with sqlite pdo-sqlite)
		)
	fi

	# readline/libedit support
	our_conf+=(
		$(use_with readline readline "${EPREFIX}/usr")
		$(use_with libedit)
	)

	# Session support
	if use session ; then
		our_conf+=( $(use_with session-mm mm "${EPREFIX}/usr") )
	else
		our_conf+=( $(use_enable session) )
	fi

	# Use pic for shared modules such as apache2's mod_php
	our_conf+=( --with-pic )

	# we use the system copy of pcre
	# --with-external-pcre affects ext/pcre
	our_conf+=(
		--with-external-pcre
		$(use_with jit pcre-jit)
	)

	# The URI extension is new in PHP 8.5, and always available. We
	# insist that it use the system copy of dev-libs/uriparser.
	our_conf+=(
		--with-external-uriparser
	)

	# Catch CFLAGS problems
	# Fixes bug #14067.
	# Changed order to run it in reverse for bug #32022 and #12021.
	replace-cpu-flags "k6*" "i586"

	# Cache the ./configure test results between SAPIs.
	our_conf+=( --cache-file="${T}/config.cache" )

	# Support user-passed configuration parameters
	our_conf+=( ${EXTRA_ECONF:-} )

	# Support the Apache2 extras, they must be set globally for all
	# SAPIs to work correctly, especially for external PHP extensions

	# Create separate build trees for each enabled SAPI. The upstream
	# build system doesn't do this, but we have to do it to use a
	# different php.ini for each SAPI (see --with-config-file-path and
	# --with-config-file-scan-dir below). The path winds up define'd
	# in main/build-defs.h which is included in main/php.h which is
	# included by basically everything; so, avoiding a rebuild after
	# changing it is not an easy job.
	#
	# The upstream build system also does not support building the
	# apache2 and embed SAPIs at the same time, presumably because they
	# both produce a libphp.so.
	local one_sapi
	local sapi
	mkdir "${WORKDIR}/sapis-build" || die
	for one_sapi in "${ENABLED_SAPIS[@]}" ; do
		php_set_ini_dir "${one_sapi}"

		# The BUILD_DIR variable is used to determine where to output
		# the files that autotools creates. This was all originally
		# based on the autotools-utils eclass.
		BUILD_DIR="${WORKDIR}/sapis-build/${one_sapi}"
		cp -a "${S}" "${BUILD_DIR}" || die

		local sapi_conf=(
			--with-config-file-path="${PHP_INI_DIR}"
			--with-config-file-scan-dir="${PHP_EXT_INI_DIR_ACTIVE}"
		)

		# We loop through *all* SAPIs here because we want to
		# --disable-foo any SAPIs that aren't enabled.
		for sapi in "${ALL_SAPIS[@]}" ; do
			case "$sapi" in
				cli|cgi|embed|fpm|phpdbg)
					if [[ "${one_sapi}" == "${sapi}" ]] ; then
						sapi_conf+=( "--enable-${sapi}" )
						if [[ "fpm" == "${sapi}" ]] ; then
							sapi_conf+=(
								$(use_with acl fpm-acl)
								$(use_with systemd fpm-systemd)
							)
						fi
					else
						sapi_conf+=( "--disable-${sapi}" )
					fi
					;;

				apache2)
					if [[ "${one_sapi}" == "${sapi}" ]] ; then
						sapi_conf+=( --with-apxs2="${EPREFIX}/usr/bin/apxs" )
					else
						sapi_conf+=( --without-apxs2 )
					fi
					;;
			esac
		done

		# Construct the $myeconfargs array by concatenating $our_conf
		# (the common args) and $sapi_conf (the SAPI-specific args).
		local myeconfargs=( "${our_conf[@]}" )
		myeconfargs+=( "${sapi_conf[@]}" )

		pushd "${BUILD_DIR}" > /dev/null || die
		einfo "Running econf in ${BUILD_DIR}"
		econf "${myeconfargs[@]}"
		if tc-is-gcc ; then
			if use lto ; then
				php_file_flags -fno-lto Zend/zend_execute.c
				# JIT may be disabled by USE, architecture or configure itself.
				if grep -q '^ext/opcache/jit/zend_jit_vm_helpers\.lo:' Makefile ; then
					php_file_flags -fno-lto ext/opcache/jit/zend_jit_vm_helpers.c
				fi
			fi
			if use pgo ; then
				php_file_flags "$(php_vm_flags)" Zend/zend_execute.c
				php_relative_paths
			fi
		elif use lto && grep -q '^ext/mbstring/libmbfl/filters/mbfilter_utf16\.lo:' Makefile ; then
			# ThinLTO (LLVM 23) crashes in computeDeadSymbols on the ifuncs of
			# this file, which only exist when AVX2 is not native to -march.
			php_file_flags -fno-lto ext/mbstring/libmbfl/filters/mbfilter_utf16.c
		fi
		popd > /dev/null || die
	done
}

# Append flags ($1) to the compile rule of each listed source file, after
# CFLAGS and PROF_FLAGS so that they take precedence.
php_file_flags() {
	local flags=${1} f
	shift
	for f in "$@" ; do
		sed -i -e "s# -c ${BUILD_DIR}/${f} # ${flags} -c ${BUILD_DIR}/${f} #" Makefile || die
		grep -qF -- " ${flags} -c ${BUILD_DIR}/${f} " Makefile \
			|| die "Makefile fixup failed for ${f}"
	done
}

# Compile with source and include paths relative to the SAPI tree. GCC and
# Clang key the profile of every static function on its source path, so with
# the absolute paths of upstream's Makefile the profile trained in the cli
# tree matched none of them in the other trees: php-cgi and php-fpm lost
# most of the PGO gain. Only compile rules change; make still runs from the
# top of the tree, where the relative paths resolve.
php_relative_paths() {
	sed -i \
		-e "/--mode=compile/s#${BUILD_DIR}/##g" \
		-e "/--mode=compile/s#-I${BUILD_DIR}\( \|\$\)#-I.\1#g" \
		-e "/^\(EXTRA_\)\?INCLUDES =/s#${BUILD_DIR}/##g" \
		-e "/^\(EXTRA_\)\?INCLUDES =/s#-I${BUILD_DIR}\( \|\$\)#-I.\1#g" \
		Makefile || die
	! grep -- "--mode=compile" Makefile | grep -qF -- "${BUILD_DIR}" \
		|| die "Makefile still compiles with absolute paths"
}

# zend_execute.c holds the VM executor, whose hot and cold handlers are
# already laid out by hand. GCC's profile feedback and -O3 both make it
# slower (bench.php -10 % and -6 % on a 7600X), so with USE=pgo it gets
# -O2 and no profile while the rest of PHP keeps both.
php_vm_flags() {
	local flags="-fno-profile-use"
	is-flagq '-O3' && flags="-O2 ${flags}"
	echo "${flags}"
}

# Print PROF_FLAGS for the upstream build system (GCC only): $1 is gen or
# use, $2 the SAPI build tree. GCC profiles are keyed by object path, so they
# are stored relative to the tree and the cli profile is reused by every SAPI.
php_pgo_flags() {
	local pgo_dir="${T}/pgo"
	if [[ ${1} == gen ]] ; then
		echo "-fprofile-generate=${pgo_dir} -fprofile-prefix-path=${2}"
	else
		echo "-fprofile-use=${pgo_dir} -fprofile-prefix-path=${2} -fprofile-correction -Wno-missing-profile -Wno-error=coverage-mismatch"
	fi
}

# Training run: the whole test suite with opcache on, which is how the
# binary runs in production. On a Ryzen 7600X it trained WordPress, Symfony
# and Joomla a little better than a 13-directory slice of it (+1.5 % against
# about 0 %); profiles from the applications themselves gave +4-6 %, but an
# ebuild cannot ship them.
php_pgo_train() {
	local dir="${WORKDIR}/sapis-build/cli" passed failed

	pushd "${dir}" > /dev/null || die
	einfo "Training the PGO profile"
	# As in src_test, one -n is for the runner and the other for every test:
	# the binary already points at the live php.ini, whose extensions belong
	# to the installed PHP. Opcache is built in since 8.5.
	# File-cache tests must not skip with RLIMIT_FSIZE still limiting gcov writes.
	TEST_PHP_EXECUTABLE="${dir}/sapi/cli/php" TEST_PHP_EXTRA_ARGS="-n" \
	SKIP_SLOW_TESTS=1 SKIP_IO_CAPTURE_TESTS=1 SKIP_PERF_SENSITIVE=1 NO_INTERACTION=1 \
		"${dir}/sapi/cli/php" -n run-tests.php -n --offline -q -x --no-progress \
		-j"$(makeopts_jobs)" -d "session.save_path=${T}" \
		-d opcache.enable_cli=1 -d opcache.jit=disable -d opcache.jit_buffer_size=0 \
		> "${T}/pgo-train.log" 2>&1
	passed=$(sed -n 's/^Tests passed *: *\([0-9]*\).*/\1/p' "${T}/pgo-train.log")
	failed=$(sed -n 's/^Tests failed *: *\([0-9]*\).*/\1/p' "${T}/pgo-train.log")
	popd > /dev/null || die

	# A few failures are harmless (only the execution profile is kept), but a
	# mostly failing run means the profile describes the wrong code paths and
	# can make PHP slower than no profile. Building without it beats failing
	# the merge on every host that has USE=pgo.
	if [[ -z ${passed} || -z ${failed} ]] || (( failed * 20 >= passed )) ; then
		ewarn "PGO training failed (${passed:-0} tests passed, ${failed:-?} failed):"
		ewarn "building without a profile, see ${T}/pgo-train.log"
		return 1
	fi
	einfo "PGO training: ${passed} tests passed, ${failed} failed"
}

src_compile() {
	# snmp seems to run during src_compile, too (bug #324739)
	addpredict /usr/share/snmp/mibs/.index #nowarn
	addpredict /var/lib/net-snmp/mib_indexes #nowarn

	local profiled=
	if use pgo && tc-is-gcc ; then
		local cli_dir="${WORKDIR}/sapis-build/cli"
		emake -C "${cli_dir}" PROF_FLAGS="$(php_pgo_flags gen "${cli_dir}")"
		php_pgo_train && profiled=1
		emake -C "${cli_dir}" prof-clean
	fi

	local sapi dir
	for sapi in "${ENABLED_SAPIS[@]}" ; do
		dir="${WORKDIR}/sapis-build/${sapi}"
		if [[ ${profiled} ]] ; then
			emake -C "${dir}" PROF_FLAGS="$(php_pgo_flags use "${dir}")"
		else
			emake -C "${dir}"
		fi
	done
}

src_install() {
	# see bug #324739 for what happens when we don't have that
	addpredict /usr/share/snmp/mibs/.index #nowarn

	# The current SAPI name as we loop through them.
	local sapi

	for sapi in "${ENABLED_SAPIS[@]}" ; do
		# Grab the first SAPI that got built, and install common
		# (SAPI-independent) targets from there.
		cd "${WORKDIR}/sapis-build/${sapi}" || die
		emake INSTALL_ROOT="${D}" install-build install-programs
		break
	done

	# Where we'll put the versioned php scripts
	keepdir "/usr/share/php${PHP_MV}"

	for sapi in "${ENABLED_SAPIS[@]}" ; do
		einfo "Installing SAPI: ${sapi}"
		cd "${WORKDIR}/sapis-build/${sapi}" || die
		php_install_ini "${sapi}"

		# Required in each iteration because php_install_ini() resets it.
		local dest="${PHP_DESTDIR#"${EPREFIX}"}"
		into "${dest}"

		# The headers target includes SAPI-specific headers, so we
		# need to install them for each SAPI even though most of
		# the headers are repeated.
		emake INSTALL_ROOT="${D}" install-headers

		case "${sapi}" in
			apache2)
				# We're intentionally not using emake install-sapi as
				# libtool may cause unnecessary relink failures (bug
				# #351266)
				insinto "${PHP_DESTDIR#"${EPREFIX}"}/apache2/"
				newins ".libs/libphp$(get_libname)" \
					   "libphp${PHP_MV}$(get_libname)"
				keepdir "/usr/$(get_libdir)/apache2/modules"
				;;
			embed)
				dolib.so "libs/libphp$(get_libname)"
				;;
			cli)
				emake INSTALL_ROOT="${D}" install-cli
				dosym "..${dest#/usr}/bin/php" "/usr/bin/php${SLOT}"

				# Install the "phar" archive utility.
				if use phar ; then
					emake INSTALL_ROOT="${D}" install-pharcmd
					dosym "..${dest#/usr}/bin/phar" \
						  "/usr/bin/phar${SLOT}"
				fi
				;;
			cgi)
				emake INSTALL_ROOT="${D}" install-cgi
				dosym "..${dest#/usr}/bin/php-cgi" \
					  "/usr/bin/php-cgi${SLOT}"
				;;
			fpm)
				emake INSTALL_ROOT="${D}" install-fpm
				dosym "..${dest#/usr}/bin/php-fpm" \
					  "/usr/bin/php-fpm${SLOT}"
				;;
			phpdbg)
				emake INSTALL_ROOT="${D}" install-phpdbg
				dosym "..${dest#/usr}/bin/phpdbg" \
					  "/usr/bin/phpdbg${SLOT}"
				;;
			*)
				die "unhandled sapi in src_install"
				;;
		esac
	done

	# Install env.d files
	newenvd "${FILESDIR}/20php5-envd" "20php${SLOT}"
	sed -e "s|/lib/|/$(get_libdir)/|g" -i "${ED}/etc/env.d/20php${SLOT}" || die
	sed -e "s|php5|php${SLOT}|g" -i "${ED}/etc/env.d/20php${SLOT}" || die

	# set php-config variable correctly (bug #278439)
	local sapi_list="${ENABLED_SAPIS[@]}"
	sapi_list="${sapi_list/apache2/apache2handler}"
	sed -e "s:^\(php_sapis=\)\".*\"$:\1\"${sapi_list}\":" -i \
		"${ED}/usr/$(get_libdir)/php${SLOT}/bin/php-config" || die

	if use fpm ; then
		if use systemd; then
			systemd_newunit "${FILESDIR}/php-fpm_at.service" \
							"php-fpm@${SLOT}.service"
		else
			systemd_newunit "${FILESDIR}/php-fpm_at-simple.service" \
							"php-fpm@${SLOT}.service"
		fi
	fi

	# Delete empty /var/run and /var/log directories.
	# See bug #977105
	if use fpm || use phpdbg ; then
		rmdir "${D}/var/log" "${D}/var/run" || die
	fi
}

src_test() {
	local TEST_PHP_EXECUTABLE="${WORKDIR}/sapis-build/cli/sapi/cli/php"

	# Sometimes when the sub-php launches a sub-sub-php, it uses these.
	# Without an "-n" in all instances, the *live* php.ini can be loaded,
	# pulling in *live* zend extensions. And those can be incompatible
	# with the thing we just built.
	export TEST_PHP_EXTRA_ARGS="-n"

	if [[ -x "${WORKDIR}/sapis-build/cgi/sapi/cgi/php-cgi" ]] ; then
		local TEST_PHP_CGI_EXECUTABLE="${WORKDIR}/sapis-build/cgi/sapi/cgi/php-cgi"
		export TEST_PHP_CGI_EXECUTABLE
	fi

	if [[ -x "${WORKDIR}/sapis-build/fpm/sapi/fpm/php-fpm" ]] ; then
		local TEST_PHP_FPM_EXECUTABLE="${WORKDIR}/sapis-build/fpm/sapi/fpm/php-fpm"
		export TEST_PHP_FPM_EXECUTABLE
	fi

	if [[ -x "${WORKDIR}/sapis-build/phpdbg/sapi/phpdbg/phpdbg" ]] ; then
		local TEST_PHPDBG_EXECUTABLE="${WORKDIR}/sapis-build/phpdbg/sapi/phpdbg/phpdbg"
		export TEST_PHPDBG_EXECUTABLE
	fi

	# The IO capture tests need to be disabled because they fail when
	# std{in,out,err} are redirected (as they are within portage).
	#
	# One -n applies to the top-level "php", while the other applies
	# to any sub-php that get invoked by the test runner.
	#
	# When running slower tests, we increase the timeout to allow
	# for e.g. bug 977243.
	SKIP_SLOW_TESTS=$(usex test-full 0 1) SKIP_IO_CAPTURE_TESTS=1 SKIP_PERF_SENSITIVE=1 REPORT_EXIT_STATUS=1 \
		"${TEST_PHP_EXECUTABLE}" -n \
		"${WORKDIR}/sapis-build/cli/run-tests.php" --offline -n -q --show-diff \
		$(usex test-full "--set-timeout 300" "") \
		-d "session.save_path=${T}" \
		|| die "tests failed"
}

pkg_postinst() {
	# Output some general info to the user
	if use apache2 ; then
		elog
		elog "To enable PHP in apache, you will need to add \"-D PHP\" to"
		elog "your apache2 command. OpenRC users can append that string to"
		elog "APACHE2_OPTS in /etc/conf.d/apache2."
		elog
		elog "The apache module configuration file 70_mod_php.conf is"
		elog "provided (and maintained) by eselect-php."
		elog
	fi

	# Create the symlinks for php
	local m
	for m in "${ENABLED_SAPIS[@]}" ; do
		[[ ${m} == 'embed' ]] && continue;

		local ci=$(eselect php show $m)
		if [[ -z $ci ]]; then
			eselect php set $m php${SLOT} || die
			einfo "Switched ${m} to use php:${SLOT}"
			einfo
		elif [[ $ci != "php${SLOT}" ]] ; then
			elog "To switch $m to use php:${SLOT}, run"
			elog "    eselect php set $m php${SLOT}"
			elog
		fi
	done

	# Remove dead symlinks for SAPIs that were just disabled. For
	# example, if the user has the cgi SAPI enabled, then he has an
	# eselect-php symlink for it. If he later reinstalls PHP with
	# USE="-cgi", that symlink will break. This call to eselect is
	# supposed to remove that dead link per bug 572436.
	eselect php cleanup || die

	if ! has "php${SLOT/./-}" ${PHP_TARGETS}; then
	   elog "To build extensions for this version of PHP, you will need to"
	   elog "add php${SLOT/./-} to your PHP_TARGETS USE_EXPAND variable."
	   elog
	fi

	# Warn about the removal of PHP_INI_VERSION if the user has it set.
	if [[ -n "${PHP_INI_VERSION}" ]]; then
		ewarn 'The PHP_INI_VERSION variable has been phased out. You may'
		ewarn 'remove it from your configuration at your convenience. See'
		ewarn
		ewarn '  https://bugs.gentoo.org/611214'
		ewarn
		ewarn 'for more information.'
	fi

	elog "For details on how version slotting works, please see"
	elog "the wiki:"
	elog
	elog "  https://wiki.gentoo.org/wiki/PHP"
	elog
}

pkg_postrm() {
	# This serves two purposes. First, if we have just removed the last
	# installed version of PHP, then this will remove any dead symlinks
	# belonging to eselect-php. Second, if a user upgrades slots from
	# (say) 5.6 to 7.0 and depcleans the old slot, then this will update
	# his existing symlinks to point to the new 7.0 installation. The
	# latter is bug 432962.
	#
	# Note: the eselect-php package may not be installed at this point,
	# so we can't die() if this command fails.
	eselect php cleanup
}
