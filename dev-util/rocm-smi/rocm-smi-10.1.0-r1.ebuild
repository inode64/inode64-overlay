# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} python3_13t )

inherit cmake flag-o-matic linux-info optfeature python-r1

DESCRIPTION="ROCm System Management Interface Library"
HOMEPAGE="https://github.com/ROCm/rocm-systems/tree/develop/projects/rocm-smi-lib"

if [[ ${PV} == *9999 ]] ; then
	inherit git-r3
	EGIT_SUBMODULES=()
	EGIT_REPO_URI="https://github.com/ROCm/rocm-systems.git"
	S="${WORKDIR}/${P}/projects/rocm-smi-lib"
else
	SRC_URI="https://github.com/ROCm/rocm-systems/releases/download/therock-${PV%.0}/rocm-smi-lib.tar.gz -> rocm-smi-${PV}.tar.gz"
	KEYWORDS="~amd64"
	S="${WORKDIR}/rocm-smi-lib"
fi

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

# rsmi_dev_market_name_get() dlopens libdrm_amdgpu.so at runtime
RDEPEND="
	${PYTHON_DEPS}
	x11-libs/libdrm[video_cards_amdgpu]
"
DEPEND="${RDEPEND}
	sys-kernel/linux-headers
"
BDEPEND="virtual/pkgconfig"

CONFIG_CHECK="~HSA_AMD ~DRM_AMDGPU"

# Any build type other than Release, including the eclass default, makes
# upstream append "-ggdb -O0 -DDEBUG" after the user's flags.
CMAKE_BUILD_TYPE=Release

src_prepare() {
	cmake_src_prepare

	# Disable code that relies on missing .git directory.
	# Just silences potential "git: command not found" QA warnings.
	sed -e "/find_program *(GIT NAMES git)/d" -i CMakeLists.txt || die
	sed -e "/num_change_since_prev_pkg(\${VERSION_PREFIX})/d" -i cmake_modules/utils.cmake || die

	local rocm_lib="${EPREFIX}/usr/$(get_libdir)/librocm_smi64.so.@VERSION_MAJOR@"
	sed -E "s|path_librocm =.+__file__.+|path_librocm = '${rocm_lib}'|" \
		-i python_smi_tools/rsmiBindingsInit.py.in || die
}

src_configure() {
	# The eclass blanks CMAKE_CXX_FLAGS_RELEASE, which is where NDEBUG comes from:
	# without it assert() can abort the caller and debug_print() writes to stderr.
	append-cppflags -DNDEBUG

	local mycmakeargs=(
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr"
	)
	cmake_src_configure
}

src_install() {
	cmake_src_install
	python_foreach_impl python_newscript python_smi_tools/rocm_smi.py rocm-smi
	python_foreach_impl python_domodule python_smi_tools/rsmiBindings.py
	python_foreach_impl python_domodule python_smi_tools/rsmiBindingsInit.py

	mv "${ED}"/usr/share/doc/rocm-smi-lib/* "${ED}/usr/share/doc/${PF}" || die
	rm -r "${ED}"/usr/share/doc/rocm-smi-lib || die
}

pkg_postinst() {
	optfeature "vendor and device names instead of hex device IDs" sys-apps/hwdata
}
