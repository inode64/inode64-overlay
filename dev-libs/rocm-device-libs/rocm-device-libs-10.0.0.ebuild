# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

LLVM_COMPAT=( 23 )
inherit cmake flag-o-matic llvm-r2

DESCRIPTION="Radeon Open Compute Device Libraries"
HOMEPAGE="https://github.com/ROCm/llvm-project/tree/amd-staging/amd/device-libs"

LLVM_COMMIT=8f497e0992fb7513f7f78a6f6b6f1056c375e961
SRC_URI="https://github.com/ROCm/llvm-project/archive/${LLVM_COMMIT}.tar.gz -> llvm-project-${LLVM_COMMIT}.tar.gz"

S="${WORKDIR}/llvm-project-${LLVM_COMMIT}/amd/device-libs"

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"
IUSE="test"
RESTRICT="!test? ( test )"

BDEPEND="
	dev-build/rocm-cmake
	$(llvm_gen_dep "
		llvm-core/clang:\${LLVM_SLOT}
		llvm-core/lld:\${LLVM_SLOT}
		llvm-core/llvm:\${LLVM_SLOT}
	")
"

CMAKE_BUILD_TYPE=Release

PATCHES=(
	"${FILESDIR}/${PN}-6.2.0-test-bitcode-dir.patch"
)

src_unpack() {
	local archive="llvm-project-${LLVM_COMMIT}.tar.gz"
	local source="llvm-project-${LLVM_COMMIT}/amd/device-libs"
	tar -xzf "${DISTDIR}/${archive}" -C "${WORKDIR}" "${source}" || die
}

src_prepare() {
	sed -e "s:\"amdgcn/bitcode\":\"lib/amdgcn/bitcode\":" \
		-i cmake/OCL.cmake || die
	# shellcheck disable=SC2016
	sed -e 's:${CMAKE_INSTALL_DATADIR}/doc/${CPACK_PACKAGE_NAME}:${CMAKE_INSTALL_DOCDIR}:' \
		-i CMakeLists.txt || die
	cmake_src_prepare
}

src_configure() {
	# Do not trust CMake with autoselecting Clang, as it autoselects the latest one
	# producing too modern LLVM bitcode and causing linker errors in other packages.
	llvm_prepend_path "${LLVM_SLOT}"
	local -x CC=${CHOST}-clang
	local -x CXX=${CHOST}-clang++
	# Clean up unsupported flags for the switched compiler, see #936099
	strip-unsupported-flags

	cmake_src_configure
}

src_install() {
	cmake_src_install
	# install symlink, so that clang won't ask for "--rocm-device-lib-path" flag anymore
	local bitcodedir="$(clang -print-resource-dir)/$(get_libdir)/amdgcn/bitcode"
	dosym -r "/usr/lib/amdgcn/bitcode" "${bitcodedir#"${EPREFIX}"}"
}

src_test() {
	# https://github.com/ROCm/llvm-project/issues/76
	# "Failing tests are on gfx that are not supported"
	local CMAKE_SKIP_TESTS=(
		compile_frexp__gfx600
		compile_fract__gfx600
		compile_native_rcp__gfx600
		compile_native_rsqrt__gfx600
		compile_fract__gfx700
		compile_native_rcp__gfx700
		compile_native_rsqrt__gfx700
		compile_native_rcp__gfx803
		compile_native_rsqrt__gfx803
		compile_atomic_work_item_fence__*
	)

	cmake_src_test
}
