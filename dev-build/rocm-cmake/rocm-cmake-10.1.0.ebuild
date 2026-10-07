# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="Radeon Open Compute CMake Modules"
HOMEPAGE="https://github.com/ROCm/rocm-cmake"

ROCM_CMAKE_COMMIT=10155d7272ea1bf79f6b5a9dbc339657af1aa372
SRC_URI="https://github.com/ROCm/rocm-cmake/archive/${ROCM_CMAKE_COMMIT}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/rocm-cmake-${ROCM_CMAKE_COMMIT}"

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"
RESTRICT="test"

DOCS=( CHANGELOG.md LICENSE README.md )

PATCHES=(
	"${FILESDIR}"/${PN}-6.1.1-license.patch
	"${FILESDIR}"/${PN}-6.1.1-no-rocmchecks-warnings.patch
)

src_prepare() {
	sed -e "/CMAKE_INSTALL_LIBDIR/s:lib:$(get_libdir):" \
		-i "share/rocmcmakebuildtools/cmake/ROCMCreatePackage.cmake" \
		-i "share/rocmcmakebuildtools/cmake/ROCMInstallTargets.cmake" || die
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-Wno-dev
	)
	cmake_src_configure
}
