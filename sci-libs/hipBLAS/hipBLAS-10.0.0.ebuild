# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ROCM_VERSION=${PV}

ROCM_LIBRARIES_COMMIT=8d1ae90eff7d022f26019ec55b2ec6a7674b3112

inherit cmake fortran-2 rocm
DESCRIPTION="ROCm BLAS marshalling library"
HOMEPAGE="https://github.com/ROCm/rocm-libraries/tree/develop/projects/hipblas"
SRC_URI="https://github.com/ROCm/rocm-libraries/archive/${ROCM_LIBRARIES_COMMIT}.tar.gz -> rocm-libraries-${ROCM_LIBRARIES_COMMIT}.tar.gz"
S="${WORKDIR}/rocm-libraries-${ROCM_LIBRARIES_COMMIT}/projects/hipblas"

REQUIRED_USE="${ROCM_REQUIRED_USE}"

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"
RDEPEND="
	sci-libs/rocBLAS:${SLOT}
"
DEPEND="
	dev-util/hip:${SLOT}
	sci-libs/hipBLAS-common:${SLOT}
	${RDEPEND}
"

PATCHES=(
	"${FILESDIR}"/${PN}-6.3.0-no-git.patch
)

src_unpack() {
	local archive="rocm-libraries-${ROCM_LIBRARIES_COMMIT}.tar.gz"
	local source="rocm-libraries-${ROCM_LIBRARIES_COMMIT}/projects/hipblas"
	tar -xzf "${DISTDIR}/${archive}" -C "${WORKDIR}" "${source}" || die
}

src_configure() {
	rocm_use_clang

	local mycmakeargs=(
		# currently hipBLAS is a wrapper of rocBLAS which has tests, so no need to perform test here
		-DBUILD_CLIENTS_TESTS=OFF
		-DBUILD_CLIENTS_BENCHMARKS=OFF
		-DROCM_SYMLINK_LIBS=OFF
		-DBUILD_WITH_SOLVER=OFF
	)

	cmake_src_configure
}
