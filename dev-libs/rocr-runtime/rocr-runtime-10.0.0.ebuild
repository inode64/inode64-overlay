# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

LLVM_COMPAT=( 23 )

inherit cmake flag-o-matic llvm-r2

DESCRIPTION="Radeon Open Compute Runtime"
HOMEPAGE="https://github.com/ROCm/rocm-systems/tree/develop/projects/rocr-runtime"

ROCM_SYSTEMS_COMMIT=6b0e43f341195e203754e08f850e437ff2fc09f9

SRC_URI="https://github.com/ROCm/rocm-systems/archive/${ROCM_SYSTEMS_COMMIT}.tar.gz -> rocm-systems-${ROCM_SYSTEMS_COMMIT}.tar.gz"
S="${WORKDIR}/rocm-systems-${ROCM_SYSTEMS_COMMIT}/projects/rocr-runtime"

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"
IUSE="debug +profile"

COMMON_DEPEND="dev-libs/elfutils
	profile? ( dev-util/rocprofiler-register:${SLOT} )
	x11-libs/libdrm"
DEPEND="${COMMON_DEPEND}
	dev-libs/roct-thunk-interface:${SLOT}
	dev-libs/rocm-device-libs:${SLOT}
		$(llvm_gen_dep "
			llvm-core/clang:\${LLVM_SLOT}=
			llvm-core/lld:\${LLVM_SLOT}=
			llvm-core/llvm:\${LLVM_SLOT}=
		")
"
RDEPEND="${DEPEND}"
BDEPEND="app-editors/vim-core"
	# vim-core is needed for "xxd"

# skip false positive detection in samples, bug #958188
CMAKE_QA_COMPAT_SKIP=1

src_prepare() {
	cd "${S}/runtime/hsa-runtime" || die

	# Gentoo installs "*.bc" to "/usr/lib" instead of a "[path]/bitcode" directory ...
	sed -e "s:-O2:--rocm-path=${EPREFIX}/usr/lib/ -O2:" -i image/blit_src/CMakeLists.txt || die

	cd "${S}" || die
	cmake_src_prepare
}

src_configure() {
	# TheRock builds the core runtime with the matching AMD LLVM toolchain.
	llvm_prepend_path "${LLVM_SLOT}"
	local -x CC=${CHOST}-clang
	local -x CXX=${CHOST}-clang++
	strip-unsupported-flags

	# -Werror=odr
	# https://bugs.gentoo.org/856091
	# https://github.com/ROCm/ROCR-Runtime/issues/182
	filter-lto

	use debug || append-cxxflags "-DNDEBUG"

	# The external hsakmt package intentionally does not install its private
	# Linux UAPI wrapper, but ROCr's core-dump support still includes it.
	append-cppflags "-I${S}/libhsakmt/include"

	local mycmakeargs=(
		-Wno-dev
		-DCMAKE_DISABLE_FIND_PACKAGE_rocprofiler-register="$(usex !profile)"
	)

	cmake_src_configure
}

src_install() {
	cmake_src_install

	# HSAKMT is linked statically into ROCr, as in TheRock, but its standalone
	# development files remain owned by roct-thunk-interface in Gentoo.
	rm -f "${ED}/usr/$(get_libdir)/libhsakmt.a" \
		"${ED}/usr/$(get_libdir)/pkgconfig/libhsakmt.pc" || die
	rm -rf "${ED}/usr/$(get_libdir)/cmake/hsakmt" \
		"${ED}/usr/include/hsakmt" || die
}
