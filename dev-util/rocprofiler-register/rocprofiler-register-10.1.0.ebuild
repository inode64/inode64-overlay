# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="ROCm profiling registration library"
HOMEPAGE="https://github.com/ROCm/rocm-systems/tree/develop/projects/rocprofiler-register"
SRC_URI="https://github.com/ROCm/rocm-systems/releases/download/therock-${PV%.0}/${PN}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}"

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"

RDEPEND="
	dev-cpp/glog
	dev-libs/libfmt:=
"
DEPEND="${RDEPEND}"

src_prepare() {
	sed -e "s:set(CMAKE_INSTALL_LIBDIR \"lib\"):set(CMAKE_INSTALL_LIBDIR \"$(get_libdir)\"):" \
		-i CMakeLists.txt || die
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_DISABLE_FIND_PACKAGE_Git=ON
		-DROCPROFILER_REGISTER_BUILD_FMT=OFF
		-DROCPROFILER_REGISTER_BUILD_GLOG=OFF
		-DROCPROFILER_REGISTER_BUILD_SAMPLES=OFF
		-DROCPROFILER_REGISTER_BUILD_TESTS=OFF
	)
	cmake_src_configure
}
