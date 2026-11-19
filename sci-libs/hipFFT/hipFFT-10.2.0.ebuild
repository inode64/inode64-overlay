# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ROCM_VERSION=${PV}

inherit cmake rocm

DESCRIPTION="CU / ROCM agnostic hip FFT implementation"
HOMEPAGE="https://github.com/ROCm/rocm-libraries/tree/develop/projects/hipfft"
SRC_URI="https://github.com/ROCm/rocm-libraries/releases/download/therock-${PV%.0}/hipfft.tar.gz -> hipfft-${PV}.tar.gz"
S="${WORKDIR}/hipfft"

REQUIRED_USE="${ROCM_REQUIRED_USE}"

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"

RDEPEND="
	dev-util/hip:${SLOT}
	sci-libs/rocFFT:${SLOT}
"
DEPEND="${RDEPEND}"

src_prepare() {
	# unused standalone project that downloads gtest; its
	# cmake_minimum_required(3.5) triggers the CMake < 3.10 QA notice
	rm -r deps || die

	cmake_src_prepare
}

src_configure() {
	rocm_use_clang

	local mycmakeargs=(
		# rocm_install_targets sets RUNPATH to $ORIGIN/../lib otherwise
		-DCMAKE_SKIP_RPATH=ON
		-DROCM_SYMLINK_LIBS=OFF
		-DBUILD_CLIENTS_TESTS=OFF
		-DBUILD_CLIENTS_BENCH=OFF
		-DGPU_TARGETS="$(get_amdgpu_flags)"
	)

	cmake_src_configure
}
