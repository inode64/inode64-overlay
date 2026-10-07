# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ROCM_LIBRARIES_COMMIT=39d8d60365d2272a5366f76ccb3bfba24b219eaf

inherit cmake
DESCRIPTION="Common files shared by hipBLAS and hipBLASLt"
HOMEPAGE="https://github.com/ROCm/rocm-libraries/tree/develop/projects/hipblas-common"
SRC_URI="https://github.com/ROCm/rocm-libraries/archive/${ROCM_LIBRARIES_COMMIT}.tar.gz -> rocm-libraries-${ROCM_LIBRARIES_COMMIT}.tar.gz"
S="${WORKDIR}/rocm-libraries-${ROCM_LIBRARIES_COMMIT}/projects/hipblas-common"

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"

BDEPEND="dev-build/rocm-cmake"

src_unpack() {
	local archive="rocm-libraries-${ROCM_LIBRARIES_COMMIT}.tar.gz"
	local source="rocm-libraries-${ROCM_LIBRARIES_COMMIT}/projects/hipblas-common"
	tar -xzf "${DISTDIR}/${archive}" -C "${WORKDIR}" "${source}" || die
}
