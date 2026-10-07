# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

ROCM_SYSTEMS_COMMIT=7da43026e4f2ef7600433c38c820732f7a205d22

DESCRIPTION="Library that provides ROCm release version and install path information"
HOMEPAGE="https://github.com/ROCm/rocm-systems/tree/develop/projects/rocm-core"
SRC_URI="https://github.com/ROCm/rocm-systems/archive/${ROCM_SYSTEMS_COMMIT}.tar.gz -> rocm-systems-${ROCM_SYSTEMS_COMMIT}.tar.gz"
S="${WORKDIR}/rocm-systems-${ROCM_SYSTEMS_COMMIT}/projects/rocm-core"

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"

src_configure() {
	# upstream requires a MAJOR.MINOR.PATCH version string
	local rocm_version=${PV}
	[[ -n $(ver_cut 3) ]] || rocm_version+=".0"
	local mycmakeargs=( -DROCM_VERSION=${rocm_version} )
	cmake_src_configure
}

src_install() {
	cmake_src_install
	# too broad for standard directory
	rm "${ED}"/usr/.info/version || die
}

RDEPEND="!<dev-util/hip-7.0"
