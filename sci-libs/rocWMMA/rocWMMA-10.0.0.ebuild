# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ROCM_SKIP_GLOBALS=1

ROCM_LIBRARIES_COMMIT=8d1ae90eff7d022f26019ec55b2ec6a7674b3112

inherit cmake rocm

DESCRIPTION="library for accelerating mixed precision matrix multiply-accumulate operations"
HOMEPAGE="https://github.com/ROCm/rocm-libraries/tree/develop/projects/rocwmma"
SRC_URI="https://github.com/ROCm/rocm-libraries/archive/${ROCM_LIBRARIES_COMMIT}.tar.gz -> rocm-libraries-${ROCM_LIBRARIES_COMMIT}.tar.gz"
S="${WORKDIR}/rocm-libraries-${ROCM_LIBRARIES_COMMIT}/projects/rocwmma"

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"

IUSE_TARGETS=( gfx908 gfx90a gfx942 gfx950 gfx1100 gfx1101 gfx1102 gfx1150 gfx1151 gfx1152 gfx1153 gfx1200 gfx1201 )
IUSE_TARGETS=( "${IUSE_TARGETS[@]/#/amdgpu_targets_}" )
ROCM_REQUIRED_USE=" || ( ${IUSE_TARGETS[*]} )"

IUSE="${IUSE_TARGETS[*]/#/+} test"
REQUIRED_USE="test? ( ${ROCM_REQUIRED_USE} )"

RESTRICT="!test? ( test )"

DEPEND="
	dev-util/hip:${SLOT}
	dev-util/rocm-smi:${SLOT}
"
# interface dependencies of header library
RDEPEND="${DEPEND}"

BDEPEND="
	test? (
		dev-cpp/gtest
		sci-libs/rocBLAS:${SLOT}
	)
	dev-build/rocm-cmake
"

PATCHES=(
	"${FILESDIR}"/${PN}-7.2.0-no-test-install.patch
)

src_unpack() {
	local archive="rocm-libraries-${ROCM_LIBRARIES_COMMIT}.tar.gz"
	local source="rocm-libraries-${ROCM_LIBRARIES_COMMIT}/projects/rocwmma"
	tar -xzf "${DISTDIR}/${archive}" -C "${WORKDIR}" "${source}" || die
}

src_prepare() {
	# unknown arguments for hipcc
	sed -e "s/ -parallel-jobs=4//" \
		-e "s/ -Xclang -fallow-half-arguments-and-returns//" \
		-i CMakeLists.txt || die

	cmake_src_prepare
}

src_configure() {
	rocm_use_clang

	local mycmakeargs=(
		-DGPU_TARGETS="$(get_amdgpu_flags)"
		-DROCWMMA_BUILD_SAMPLES=OFF
		-DROCWMMA_BUILD_TESTS="$(usex test)"
	)
	use test && mycmakeargs+=(-DROCWMMA_USE_SYSTEM_GOOGLETEST=ON)
	cmake_src_configure
}

src_test() {
	check_amdgpu

	# Expected time on gfx1100 is 1260s (-j1) or 936s (-j32)
	# Visible devices are limited to the first one to exclude APU (if not disabled in the BIOS)
	HIP_VISIBLE_DEVICES=0 cmake_src_test
}
