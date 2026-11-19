# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ROCM_VERSION=${PV}

inherit cmake rocm

DESCRIPTION="CU / ROCM agnostic hip RAND implementation"
HOMEPAGE="https://github.com/ROCm/rocm-libraries/tree/develop/projects/hiprand"
SRC_URI="https://github.com/ROCm/rocm-libraries/releases/download/therock-${PV%.0}/hiprand.tar.gz -> hiprand-${PV}.tar.gz"
S="${WORKDIR}/hiprand"

REQUIRED_USE="${ROCM_REQUIRED_USE}"

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"

RESTRICT="test"

RDEPEND="
	sci-libs/rocRAND:${SLOT}
	dev-util/hip:${SLOT}
"
DEPEND="${RDEPEND}"

src_prepare() {
	# standalone project to test an installed hipRAND (tests are not built); its
	# cmake_minimum_required(3.5.1) triggers the CMake < 3.10 QA notice
	rm -r test/package || die

	cmake_src_prepare
}

src_configure() {
	rocm_use_clang

	local mycmakeargs=(
		-Wno-dev
		# rocm_install_targets sets RUNPATH to $ORIGIN/../lib otherwise
		-DCMAKE_SKIP_RPATH=ON
		-DAMDGPU_TARGETS="$(get_amdgpu_flags)"
		-DROCM_SYMLINK_LIBS=OFF
		-DCMAKE_DISABLE_FIND_PACKAGE_Git=ON
	)

	cmake_src_configure
}
