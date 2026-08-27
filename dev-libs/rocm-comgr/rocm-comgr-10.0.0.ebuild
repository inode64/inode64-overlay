# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

LLVM_COMPAT=( 23 )

inherit cmake llvm-r2

DESCRIPTION="Radeon Open Compute Code Object Manager"
HOMEPAGE="https://github.com/ROCm/llvm-project/tree/amd-staging/amd/comgr"

LLVM_COMMIT=8f497e0992fb7513f7f78a6f6b6f1056c375e961
SRC_URI="https://github.com/ROCm/llvm-project/archive/${LLVM_COMMIT}.tar.gz -> llvm-project-${LLVM_COMMIT}.tar.gz"

S="${WORKDIR}/llvm-project-${LLVM_COMMIT}/amd/comgr"

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"

IUSE="test"
RESTRICT="!test? ( test )"

PATCHES=(
	"${FILESDIR}/${PN}-6.4.1-extend-isa-compatibility-check.patch"
	"${FILESDIR}/${PN}-6.1.0-dont-add-nogpulib.patch"
)

RDEPEND="
	dev-libs/rocm-device-libs:${SLOT}
	llvm-runtimes/clang-runtime:=
	$(llvm_gen_dep "
		llvm-core/clang:\${LLVM_SLOT}=
		llvm-core/lld:\${LLVM_SLOT}=
		llvm-core/llvm:\${LLVM_SLOT}=
	")
	dev-util/hipcc:${SLOT}
"
DEPEND="${RDEPEND}"

# Circular dependency: to build tests, hip compiler must be functional
BDEPEND="test? ( dev-util/hip:${SLOT} )"

CMAKE_BUILD_TYPE=Release

src_unpack() {
	local archive="llvm-project-${LLVM_COMMIT}.tar.gz"
	local source="llvm-project-${LLVM_COMMIT}/amd/comgr"
	tar -xzf "${DISTDIR}/${archive}" -C "${WORKDIR}" "${source}" || die
}

src_prepare() {
	sed -e "s:\${CLANG_CMAKE_DIR}/../../../\*:${EPREFIX}/usr/lib/clang/${LLVM_SLOT}/include:" \
		-i cmake/opencl_header.cmake || die


	# comgr-compiler.cpp uses std::unordered_set without including its header.
	sed -e '/#include <sstream>/i#include <unordered_set>' \
		-i src/comgr-compiler.cpp || die

	# Match the system LLVM shared-library build in the hotswap subproject too.
	sed -e '/target_link_libraries(hotswap-rewriter PUBLIC/i\
if(LLVM_LINK_LLVM_DYLIB)\
set(hotswap_rewriter_llvm_libs LLVM)\
endif()' \
		-i src/hotswap/rewriter/CMakeLists.txt || die

	cmake_src_prepare
}

src_configure() {
	llvm_prepend_path "${LLVM_SLOT}"

	local mycmakeargs=(
		-DCMAKE_STRIP=""  # disable stripping defined at lib/comgr/CMakeLists.txt:58
		-DBUILD_TESTING=$(usex test ON OFF)
		-DCLANG_LINK_CLANG_DYLIB=ON
		-DCOMGR_DISABLE_SPIRV=ON  # requires ROCm/SPIRV-LLVM-Translator (fork of dev-util/spirv-llvm-translator)
		-DLLVM_LINK_LLVM_DYLIB=ON
	)
	# Prevent CMake from finding systemwide hip, which breaks tests
	use test && mycmakeargs+=( -DCMAKE_DISABLE_FIND_PACKAGE_hip=ON )
	cmake_src_configure
}

src_test() {
	cmake_src_test
}
