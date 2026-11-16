# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CONFIG_CHECK="~ADVISE_SYSCALLS"
PYTHON_COMPAT=( python3_{12..14} )
PYTHON_REQ_USE="threads(+)"
RUST_OPTIONAL=1
RUST_MIN_VER="1.86.0"

inherit check-reqs flag-o-matic linux-info ninja-utils pax-utils
inherit python-any-r1 rust toolchain-funcs xdg-utils

DESCRIPTION="A JavaScript runtime built on Chrome's V8 JavaScript engine"
HOMEPAGE="https://nodejs.org/"
SRC_URI="https://nodejs.org/dist/v${PV}/node-v${PV}.tar.xz"
S="${WORKDIR}/node-v${PV}"

LICENSE="Apache-1.1 Apache-2.0 BlueOak-1.0.0 BSD BSD-2 MIT npm? ( Artistic-2 )"
# One slot per major, each in its own prefix, so several can be installed at
# once; app-eselect/eselect-nodejs owns the unversioned node, npm and npx.
SLOT="$(ver_cut 1)"
KEYWORDS=""

IUSE="cpu_flags_x86_sse2 debug doc +icu +inspector lto +npm pax-kernel +snapshot +ssl system-icu +system-ssl test temporal"
REQUIRED_USE="inspector? ( icu ssl )
	npm? ( ssl )
	system-icu? ( icu )
	system-ssl? ( ssl )
	temporal? ( icu !system-icu )
	x86? ( cpu_flags_x86_sse2 )"

RESTRICT="!test? ( test )"

COMMON_DEPEND=">=app-arch/brotli-1.2.1:=
	dev-db/sqlite:3
	>=dev-cpp/ada-4.0.0:=
	>=dev-cpp/simdutf-9.2.1-r1:=[atomic-base64(+)]
	>=dev-libs/libuv-1.52.1:=
	>=dev-libs/simdjson-5.0.3:=
	>=net-dns/c-ares-1.34.9:=
	>=net-libs/nghttp2-1.70.0:=
	>=net-libs/nghttp3-1.18.0:=
	virtual/zlib:=
	system-icu? ( >=dev-libs/icu-78:= )
	ssl? (
		system-ssl? (
			>=net-libs/ngtcp2-1.25.0:=
			>=dev-libs/openssl-3.5.9:0=
		)
		!system-ssl? ( >=net-libs/ngtcp2-1.25.0:=[-gnutls] )
	)
	!ssl? ( >=net-libs/ngtcp2-1.25.0:= )
	|| (
		sys-devel/gcc:*
		llvm-runtimes/libatomic-stub
	)"
BDEPEND="${PYTHON_DEPS}
	app-alternatives/ninja
	pax-kernel? ( sys-apps/elfix )
	sys-apps/coreutils
	temporal? ( ${RUST_DEPEND} )
	test? ( net-misc/curl app-arch/unzip )
	virtual/pkgconfig"
DEPEND="${COMMON_DEPEND}"
# The unslotted ::gentoo package installs the paths eselect-nodejs manages,
# so it has to be removed by hand first. A weak blocker would remove it after
# pkg_postinst, and with FEATURES=unmerge-orphans that removal deletes the
# links eselect-nodejs has just created.
RDEPEND="${COMMON_DEPEND}
	app-eselect/eselect-nodejs
	!!net-libs/nodejs:0"
# pkg_postinst runs it.
IDEPEND="app-eselect/eselect-nodejs"

# These are measured on a loong machine with -ggdb on, and only checked
# if debugging flags are present in CFLAGS.
#
# The final link consumed a little more than 7GiB alone, so 8GiB is the lower
# limit for memory usage. Disk usage was 19.1GiB for the build directory and
# 1.2GiB for the installed image, so we leave some room for architectures with
# fatter binaries and set the disk requirement to 22GiB.
CHECKREQS_MEMORY="8G"
CHECKREQS_DISK_BUILD="22G"

PATCHES=(
	"${FILESDIR}"/${PN}-26.12.0-v8-climits.patch
	"${FILESDIR}"/${PN}-26.11.1-add-missing-funcational-inc.patch
	"${FILESDIR}"/${PN}-26.10.0-x86-SSE2-fix.patch
	"${FILESDIR}"/${PN}-26.10.0-simdutf-use-system-header.patch
	"${FILESDIR}"/${PN}-26.11.1-include-EACCES-in-mkdir-test.patch
)

pkg_pretend() {
	if [[ ${MERGE_TYPE} != "binary" ]]; then
		if is-flagq "-g*" && ! is-flagq "-g*0" ; then
			einfo "Checking for sufficient disk space and memory to build ${PN} with debugging CFLAGS"
			check-reqs_pkg_pretend
		fi
	fi
}

pkg_setup() {
	python-any-r1_pkg_setup
	linux-info_pkg_setup
	# https://github.com/nodejs/node/issues/62676 - Can't build Temporal with system ICU.
	if use system-icu; then
		ewarn "The ES2026 'Temporal' datetime feature/object is not available when using system-icu."
		ewarn "Please consider whether this is desirable for your use case."
		ewarn "https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal"
	fi

	use temporal && rust_pkg_setup

	# get_libdir is not allowed in global scope.
	NODE_PREFIX="/usr/$(get_libdir)/node-${SLOT}"
}

src_prepare() {
	tc-export AR CC CXX PKG_CONFIG
	export V=1
	export BUILDTYPE=Release

	# fix compilation on Darwin
	# https://code.google.com/p/gyp/issues/detail?id=260
	sed -i -e '/append("-arch")/{N;d;}' tools/gyp/pylib/gyp/xcode_emulation.py || die

	# No libdir seds from ::gentoo: in a prefix of its own, lib/ collides
	# with nothing, and install.py and npm's global root must change together.

	# Avoid writing a depfile, not useful
	sed -i -e "/DEPFLAGS =/d" tools/gyp/pylib/gyp/generator/make.py || die

	sed -i -e "/'-O3'/d" common.gypi node.gypi || die

	# debug builds. change install path, remove optimisations and override buildtype
	if use debug; then
		sed -i -e "s|out/Release/|out/Debug/|g" tools/install.py || die
		BUILDTYPE=Debug
	fi

	# We need to disable mprotect on two files when it builds Bug 694100.
	use pax-kernel &&
		PATCHES+=( "${FILESDIR}"/${PN}-24.1.0-paxmarking.patch )

	use ppc64 &&
		PATCHES+=(	"${FILESDIR}/${PN}-24.11.1-restore-ppc64be.patch" )

	default
}

src_configure() {
	xdg_environment_reset

	# LTO compiler flags are handled by configure.py itself
	filter-lto
	# The warnings are *so* noisy and make build.logs massive
	append-cxxflags $(test-flags-CXX -Wno-template-id-cdtor)
	# https://bugs.gentoo.org/931514
	use arm64 && append-flags $(test-flags-CXX -mbranch-protection=none)

	# Highway compilation error on riscv
	# See: https://bugs.gentoo.org/983938
	#
	# Upstream Highway fixed the issue, but V8 has not picked up a Highway
	# version that includes it, so Node still hits the old headers.
	# this workaround will stop Highway from compiling RVV, and stop the host
	# compiler from emitting RVV in non-V8 code. V8 can still emit RVV at runtime
	# on machines that have it.
	#
	# Additionally, force the EMU128 (128-bit scalar emulation) for boards
	# without RVV (VisionFive V2 / JH7110).
	# This will ensure V8's FixedTag<..., 16> in the JSON stringifier is legal.
	use riscv && append-cxxflags -DHWY_DISABLED_TARGETS=HWY_RVV -DHWY_BROKEN_EMU128=0

	local myconf=(
		--ninja
		--shared-ada
		--shared-brotli
		--shared-cares
		--shared-libuv
		--shared-nghttp2
		--shared-nghttp3
		--shared-ngtcp2
		--shared-simdjson
		--shared-simdutf
		--shared-sqlite
		--shared-zlib
	)
	use debug && myconf+=( --debug )
	use lto && myconf+=( --enable-lto )
	if use system-icu; then
		# No Temporal support: https://github.com/nodejs/node/issues/62676
		myconf+=( --with-intl=system-icu )
	elif use icu; then
		# Full embedded ICU (Temporal works)
		myconf+=( --with-intl=full-icu )
	else
		# Default embedded subset (Temporal works, saves space over full-icu)
		myconf+=( --with-intl=small-icu )
	fi
	use inspector || myconf+=( --without-inspector )
	use npm || myconf+=( --without-npm )
	use snapshot || myconf+=( --without-node-snapshot )
	if use ssl; then
		use system-ssl && myconf+=( --shared-openssl --openssl-use-def-ca-store )
	else
		myconf+=( --without-ssl )
	fi
	! use temporal && myconf+=( --v8-disable-temporal-support )

	# https://bugs.gentoo.org/985006
	use ppc64 && myconf+=( --without-lief )

	local myarch=""
	case "${ARCH}:${ABI}" in
		*:amd64) myarch="x64";;
		*:arm) myarch="arm";;
		*:arm64) myarch="arm64";;
		loong:lp64*) myarch="loong64";;
		riscv:lp64*) myarch="riscv64";;
		*:ppc64) myarch="ppc64";;
		*:x32) myarch="x32";;
		*:x86) myarch="ia32";;
		*) myarch="${ABI}";;
	esac

	GYP_DEFINES="linux_use_gold_flags=0
		linux_use_bundled_binutils=0
		linux_use_bundled_gold=0" \
	"${EPYTHON}" configure.py \
		--prefix="${EPREFIX}${NODE_PREFIX}" \
		--dest-cpu=${myarch} \
		"${myconf[@]}" || die
}

src_compile() {
	eninja -C out/Release
	# There's just a plain make target for the FFI tests, and it doesn't support ninja.
	use test && emake build-ffi-tests
}

src_install() {
	local LIBDIR="${ED}${NODE_PREFIX}/lib"
	default

	pax-mark -m "${ED}${NODE_PREFIX}"/bin/node

	local bin bins=( node )
	use npm && bins+=( npm npx )
	for bin in "${bins[@]}"; do
		dosym -r "${NODE_PREFIX}/bin/${bin}" "/usr/bin/${bin}${SLOT}"
	done

	if use doc; then
		docinto html
		dodoc -r "${S}"/doc/*
	fi

	if use npm; then
		# npm takes its global prefix from the node that runs it, so each
		# slot's npm has to run with its own node, not the first in PATH.
		# /etc/npm and its env.d entry, shared by every slot, belong to
		# app-eselect/eselect-nodejs.
		local cli shebang="#!${EPREFIX}${NODE_PREFIX}/bin/node"
		for cli in npm npx; do
			cli="${LIBDIR}/node_modules/npm/bin/${cli}-cli.js"
			sed -i -e "1s|^#!/usr/bin/env node$|${shebang}|" "${cli}" || die
			[[ $(head -n 1 "${cli}") == "${shebang}" ]] ||
				die "Unexpected shebang in ${cli}"
		done

		# The completion and the man pages stay in the slot, and
		# eselect-nodejs points /usr/share/bash-completion and MANPATH at
		# the active one. The staged npm runs with an explicit node: its
		# shebang names a path that exists only after the merge.
		dodir "${NODE_PREFIX}"/share/bash-completion/completions
		"${ED}${NODE_PREFIX}"/bin/node "${LIBDIR}"/node_modules/npm/bin/npm-cli.js \
			completion > "${ED}${NODE_PREFIX}"/share/bash-completion/completions/npm ||
			die "Failed to generate the npm completion"

		# Clean up
		rm -f "${LIBDIR}"/node_modules/npm/{.mailmap,.npmignore,Makefile}

		local find_exp="-or -name"
		local find_name=()
		for match in "AUTHORS*" "CHANGELOG*" "CONTRIBUT*" "README*" \
			".travis.yml" ".eslint*" ".wercker.yml" ".npmignore" \
			"*.bat" "*.cmd"; do
			find_name+=( ${find_exp} "${match}" )
		done

		# Remove various development and/or inappropriate files and
		# useless docs of dependend packages.
		# Strict match for LICENSE files to avoid purging actual logic (e.g. license.js)
		# which breaks npm.
		find "${LIBDIR}"/node_modules \
			\( -type d -name examples \) -or \( -type f \( \
				\( -iname "LICEN?E*" -not -name "*.js" -not -name "*.json" \) \
				"${find_name[@]}" \
			\) \) -exec rm -rf "{}" \;
	fi

	mv "${ED}${NODE_PREFIX}"/share/doc/node "${ED}"/usr/share/doc/${PF} || die
}

src_test() {
	local drop_tests=(
		test/parallel/test-blocklist.js
		test/parallel/test-dns.js
		test/parallel/test-dns-resolveany-bad-ancount.js
		test/parallel/test-dns-setserver-when-querying.js
		test/parallel/test-dotenv.js
		test/parallel/test-fs-mkdir.js
		test/parallel/test-fs-read-stream.js
		test/parallel/test-fs-utimes-y2K38.js
		test/parallel/test-fs-watch-recursive-add-file.js
		test/parallel/test-http2-client-set-priority.js
		test/parallel/test-http2-priority-event.js
		test/parallel/test-process-euid-egid.js
		test/parallel/test-process-get-builtin.mjs
		test/parallel/test-process-initgroups.js
		test/parallel/test-process-setgroups.js
		test/parallel/test-process-uid-gid.js
		test/parallel/test-release-npm.js
		# Unreliable when using system libraries and ASLR.
		# The variations between snapshot generation passes appear limited to memory
		# allocation pointers leaking into the serialised V8 blob array; the actual
		# bytecode and engine structures remain consistently... consistent.
		test/parallel/test-snapshot-reproducible.js
		test/parallel/test-socket-write-after-fin-error.js
		test/parallel/test-strace-openat-openssl.js
		test/parallel/test-x509-escaping.js
		test/parallel/test-util-styletext.js
		test/parallel/test-util-styletext-hex.js
		test/sequential/test-tls-session-timeout.js
		test/sequential/test-util-debug.js
		test/sequential/test-watch-mode.mjs
	)

	if has_version "sys-libs/zlib-ng" ; then
		elog "Some tests will be skipped due to being known to fail with sys-libs/zlib-ng"
		elog
		drop_tests+=( test/parallel/test-process-versions.js )
		drop_tests+=( test/parallel/test-zlib-zip-interop.js )
		elog
	fi

	# Skip the ZIP interop test when system unzip lacks natspec
	# (zipinfo can't handle the Unicode filename otherwise)
	if ! has_version "app-arch/unzip[natspec]" ; then
		elog "Skipping test-zlib-zip-interop.js: system unzip was built without natspec"
		drop_tests+=( test/parallel/test-zlib-zip-interop.js )
	fi

	use inspector ||
		drop_tests+=(
			test/parallel/test-inspector-emit-protocol-event.js
			test/parallel/test-inspector-network-arbitrary-data.js
			test/parallel/test-inspector-network-domain.js
			test/parallel/test-inspector-network-fetch.js
			test/parallel/test-inspector-network-http.js
			test/sequential/test-watch-mode.mjs
		)
	rm -f "${drop_tests[@]}" || die "disabling tests failed"

	out/${BUILDTYPE}/cctest || die
	"${EPYTHON}" tools/test.py --mode=${BUILDTYPE,,} --flaky-tests=dontcare -J message parallel sequential || die
}

pkg_postinst() {
	local active
	active=$(eselect nodejs show)
	if [[ -z ${active} || ${active} == node${SLOT} ]]; then
		# Also for the active slot: a rebuild may add or drop npm and npx.
		eselect nodejs set "node${SLOT}" ||
			ewarn "Could not make node${SLOT} the default node: eselect nodejs set node${SLOT}"
	else
		elog "The default node is still ${active}; this one runs as node${SLOT}."
		elog "To make it the default: eselect nodejs set node${SLOT}"
	fi

	if use npm; then
		ewarn "remember to run: source /etc/profile if you plan to use nodejs"
		ewarn " in your current shell"
	fi

	if use system-icu; then
		ewarn ""
		ewarn "Node.js was built with USE='system-icu'."
		ewarn "The JavaScript 'Temporal' API has been disabled."
		ewarn "If you need full ES2026+ compliance, rebuild with USE='-system-icu'."
		ewarn ""
	fi
}

pkg_postrm() {
	# Removing the default slot leaves node, npm and npx dangling: point them
	# at the highest slot left, or remove them with the last one. A depclean
	# may have removed eselect-nodejs first, so it must not fail the unmerge.
	eselect nodejs update --if-unset ||
		ewarn "Could not update the default node: eselect nodejs update --if-unset"
}
