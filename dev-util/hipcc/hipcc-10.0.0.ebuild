# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

LLVM_COMPAT=( 23 )
inherit cmake llvm-r2

DESCRIPTION="Radeon Open Compute hipcc"
HOMEPAGE="https://github.com/ROCm/llvm-project/tree/amd-staging/amd/hipcc"

LLVM_COMMIT=8f497e0992fb7513f7f78a6f6b6f1056c375e961
SRC_URI="https://github.com/ROCm/llvm-project/archive/${LLVM_COMMIT}.tar.gz -> llvm-project-${LLVM_COMMIT}.tar.gz"
S="${WORKDIR}/llvm-project-${LLVM_COMMIT}/amd/hipcc"

LICENSE="Apache-2.0 MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"
IUSE="debug"

DEPEND="
	$(llvm_gen_dep "
		llvm-runtimes/compiler-rt:\${LLVM_SLOT}=
		llvm-core/llvm:\${LLVM_SLOT}=
		llvm-core/clang:\${LLVM_SLOT}=
	")
"
RDEPEND="${DEPEND}"

src_unpack() {
	local archive="llvm-project-${LLVM_COMMIT}.tar.gz"
	local source="llvm-project-${LLVM_COMMIT}/amd/hipcc"
	tar -xzf "${DISTDIR}/${archive}" -C "${WORKDIR}" "${source}" || die
}

src_prepare() {
	cmake_src_prepare

	sed -e "s:lib/llvm/bin:lib/llvm/${LLVM_SLOT}/bin:" \
		-e "s:/opt/rocm:/usr:g" \
		-i src/hipBin_base.h || die

	# The C++ driver now constructs this path component-by-component.
	sed -e "/hipClangPath \/= \"llvm\";/a\\    hipClangPath /= \"${LLVM_SLOT}\";" \
		-i src/hipBin_amd.h || die

	# Point Clang at a lib64-aware SDK view installed below.
	sed -e '/hipLdFlags_ = hipLdFlags;/i\\  hipLdFlags += " --hip-path=\/usr\/share\/hip\/gentoo-sdk";' \
		-e '/hipCXXFlags_ = hipCXXFlags;/i\\  hipCXXFlags += " --hip-path=\/usr\/share\/hip\/gentoo-sdk";' \
		-i src/hipBin_amd.h || die

	sed -e "s:amdgcn/bitcode:lib/amdgcn/bitcode:g" \
		-i src/hipBin_amd.h || die
}

src_install() {
	cmake_src_install
	# remove bat files...
	rm -rf "${ED}/usr/hip" || die

	dodir /usr/share/hip/gentoo-sdk/share/hip
	dosym -r /usr/include /usr/share/hip/gentoo-sdk/include
	dosym -r "/usr/$(get_libdir)" /usr/share/hip/gentoo-sdk/lib
	dosym -r /usr/share/hip/version /usr/share/hip/gentoo-sdk/share/hip/version
}
