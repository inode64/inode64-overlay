# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
ROCM_SKIP_GLOBALS=1
inherit cmake linux-info python-r1 rocm

ROCM_SYSTEMS_COMMIT=6b0e43f341195e203754e08f850e437ff2fc09f9
ESMI_COMMIT=d494a3194ceb4cc4dbb2debf9fcbe8773c6d3bef

DESCRIPTION="AMD System Management Interface for managing and monitoring GPUs"
HOMEPAGE="
	https://github.com/ROCm/rocm-systems
	https://rocm.docs.amd.com/projects/amdsmi/en/latest/
"
SRC_URI="
	https://github.com/ROCm/rocm-systems/archive/${ROCM_SYSTEMS_COMMIT}.tar.gz
		-> rocm-systems-${ROCM_SYSTEMS_COMMIT}.tar.gz
	https://github.com/amd/esmi_ib_library/archive/${ESMI_COMMIT}.tar.gz -> esmi_ib_library-${ESMI_COMMIT}.tar.gz
"
S="${WORKDIR}/rocm-systems-${ROCM_SYSTEMS_COMMIT}/projects/amdsmi"
ESMI_S="${WORKDIR}/esmi_ib_library-${ESMI_COMMIT}"

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"

IUSE="test"
RESTRICT="!test? ( test )"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

DEPEND="
	${PYTHON_DEPS}
	test? ( dev-cpp/gtest )
	x11-libs/libdrm[video_cards_amdgpu]
	net-libs/libmnl
	dev-libs/libnl:3
	dev-libs/rocm-core:${SLOT}
"
RDEPEND="${PYTHON_DEPS}"

CONFIG_CHECK="~HSA_AMD ~DRM_AMDGPU"

src_prepare() {
	ln -s "${ESMI_S}" esmi_ib_library || die

	# Compatibility with CMake < 3.10 will be removed
	sed -e "/cmake_minimum_required/ s/3\.5\.0/3.10/" \
		-i goamdsmi_shim/CMakeLists.txt "${ESMI_S}"/CMakeLists.txt || die

	sed -e "s/-Wall -Wextra//" \
		-i CMakeLists.txt "${ESMI_S}"/CMakeLists.txt goamdsmi_shim/CMakeLists.txt || die

	# Reset custom installation path
	sed -e "/generic_add_rocm/d" -i CMakeLists.txt || die


	# Install docs to correct place
	sed -e "s:doc/\${CPACK_PACKAGE_NAME}:doc/${P}:" -i CMakeLists.txt || die

	# Do not install /usr/share/doc/${P}-asan
	sed -e "s/COMPONENT asan/COMPONENT asan EXCLUDE_FROM_ALL/" -i CMakeLists.txt || die

	cmake_src_prepare
}

src_configure() {
	python_setup

	local mycmakeargs=(
		-DBUILD_TESTS=$(usex test)
		-Wno-dev
	)
	use test && mycmakeargs+=( -DCMAKE_REQUIRE_FIND_PACKAGE_GTest=ON )
	cmake_src_configure
}

src_test() {
	# GPU access in amdsmitstReadOnly.TestSysInfoRead and amdsmitstReadOnly.TestIdInfoRead
	addwrite /dev/dri/renderD128

	# Few tests fail on ASUS GZ302E: no metrics from kernel?
	GTEST_FILTER="-amdsmitstReadOnly.TempRead:amdsmitstReadOnly.TestFrequenciesRead" \
	"${BUILD_DIR}/tests/amd_smi_test/amdsmitst" || die "Test failed"
}

src_install() {
	cmake_src_install

	# Wrong places
	rm "${ED}"/usr/share/amd_smi/amdsmi/{libamd_smi.so,LICENSE,README.md} || die

	python_fix_shebang "${ED}"/usr/libexec/amdsmi_cli
	python_domodule "${ED}"/usr/libexec/amdsmi_cli
	python_domodule "${ED}"/usr/share/amd_smi/amdsmi

	fperms a+x "/usr/lib/${EPYTHON}/site-packages/amdsmi_cli/amdsmi_cli.py"
	dosym -r "/usr/lib/${EPYTHON}/site-packages/amdsmi_cli/amdsmi_cli.py" /usr/bin/amd-smi

	rm -rf "${ED}"/usr/share/amd_smi "${ED}"/usr/libexec/amdsmi_cli || die
}
