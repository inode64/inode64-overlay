# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit readme.gentoo-r1 rpm secureboot

MY_PR="${PR:1}"
MY_REV="2.fc42"

DESCRIPTION="UEFI firmware for 64-bit x86 virtual machines"
HOMEPAGE="https://github.com/tianocore/edk2"
SRC_URI="https://kojipkgs.fedoraproject.org/packages/edk2/${MY_PR}/${MY_REV}/noarch/edk2-ovmf-${MY_PR}-${MY_REV}.noarch.rpm"
S="${WORKDIR}"

LICENSE="BSD-2 MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~loong ~ppc ~ppc64 ~riscv ~x86"

RDEPEND="!sys-firmware/edk2"

DISABLE_AUTOFORMATTING=true
DOC_CONTENTS="This package contains the tianocore edk2 UEFI firmware for 64-bit x86
virtual machines. The firmware is located under
	/usr/share/edk2-ovmf/OVMF_CODE.fd
	/usr/share/edk2-ovmf/OVMF_VARS.fd
	/usr/share/edk2-ovmf/OVMF_CODE.secboot.fd

If USE=binary is enabled, we also install an OVMF variables file (coming from
fedora) that contains secureboot default keys

	/usr/share/edk2-ovmf/OVMF_VARS.secboot.fd

If you have compiled this package by hand, you need to either populate all
necessary EFI variables by hand by booting
	/usr/share/edk2-ovmf/UefiShell.(iso|img)
or creating OVMF_VARS.secboot.fd by hand:
	https://github.com/puiterwijk/qemu-ovmf-secureboot

The firmware does not support csm (due to no free csm implementation
available). If you need a firmware with csm support you have to download
one for yourself. Firmware blobs are commonly labeled
	OVMF{,_CODE,_VARS}-with-csm.fd

In order to use the firmware you can run qemu the following way

	$ qemu-system-x86_64 \\
		-drive file=/usr/share/edk2-ovmf/OVMF.fd,if=pflash,format=raw,unit=0,readonly=on \\
		..."

src_install() {
	rm -rf usr/share/OVMF || die
	mv usr/share/edk2/ovmf usr/share/edk2-ovmf || die
	mv usr/share/doc/edk2-ovmf "usr/share/doc/${PF}" || die

	rm -rf usr/share/licenses || die
	mv usr "${ED}" || die

	secureboot_auto_sign --in-place

	readme.gentoo_create_doc
}

pkg_postinst() {
	readme.gentoo_print_elog
}
