# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# linux-info lo hereda linux-mod-r1; heredarlo despues sobreescribe pkg_setup y
# rompe linux-mod-r1_pkg_postinst ("called without running linux-mod-r1_pkg_setup").
inherit flag-o-matic linux-mod-r1 toolchain-funcs

# Snapshot del master de https://github.com/asterisk/dahdi-linux (2026-03-04).
# Respecto a la release 3.4.0 (jun-2024) anade los wrappers para kernels
# 6.15/6.16+ (hrtimer_setup, from_timer -> timer_container_of, del_timer ->
# timer_delete) necesarios para compilar en 6.18. Los drivers legacy
# (wctdm, wcfxo, wct1xxp, wcte11xp) ya vienen restaurados en la serie 3.x, por
# lo que restore_wctdm.patch no hace falta. Se eliminan los drivers jnet
# (cwain/qozap/ztgsm, 2010): no compilan en kernels modernos y no hay hardware.
COMMIT="276c914ea7d58bc2c19478f17835ed833e8f66d4"
MY_P="dahdi-linux-${COMMIT}"
S="${WORKDIR}/${MY_P}"

DESCRIPTION="Kernel modules for Digium compatible hardware (formerly known as Zaptel)"
HOMEPAGE="https://www.asterisk.org https://github.com/asterisk/dahdi-linux"
SRC_URI="https://github.com/asterisk/dahdi-linux/archive/${COMMIT}.tar.gz -> ${P}.tar.gz
	https://downloads.digium.com/pub/telephony/firmware/releases/dahdi-fwload-vpmadt032-1.25.0.tar.gz
	https://downloads.digium.com/pub/telephony/firmware/releases/dahdi-fw-a4a-a0017.tar.gz
	https://downloads.digium.com/pub/telephony/firmware/releases/dahdi-fw-a4b-d001e.tar.gz
	https://downloads.digium.com/pub/telephony/firmware/releases/dahdi-fw-a8a-1d0017.tar.gz
	https://downloads.digium.com/pub/telephony/firmware/releases/dahdi-fw-a8b-1f001e.tar.gz
	https://downloads.digium.com/pub/telephony/firmware/releases/dahdi-fw-hx8-2.06.tar.gz
	https://downloads.digium.com/pub/telephony/firmware/releases/dahdi-fw-oct6114-032-1.05.01.tar.gz
	https://downloads.digium.com/pub/telephony/firmware/releases/dahdi-fw-oct6114-064-1.05.01.tar.gz
	https://downloads.digium.com/pub/telephony/firmware/releases/dahdi-fw-oct6114-128-1.05.01.tar.gz
	https://downloads.digium.com/pub/telephony/firmware/releases/dahdi-fw-oct6114-256-1.05.01.tar.gz
	https://downloads.digium.com/pub/telephony/firmware/releases/dahdi-fw-tc400m-MR6.12.tar.gz
	https://downloads.digium.com/pub/telephony/firmware/releases/dahdi-fw-te133-7a001e.tar.gz
	https://downloads.digium.com/pub/telephony/firmware/releases/dahdi-fw-te134-780017.tar.gz
	https://downloads.digium.com/pub/telephony/firmware/releases/dahdi-fw-te435-13001e.tar.gz
	https://downloads.digium.com/pub/telephony/firmware/releases/dahdi-fw-te436-10017.tar.gz
	https://downloads.digium.com/pub/telephony/firmware/releases/dahdi-fw-te820-1.76.tar.gz
	https://downloads.digium.com/pub/telephony/firmware/releases/dahdi-fw-vpmoct032-1.12.0.tar.gz
"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="flash oslec"

CONFIG_CHECK="MODULES PCI ~CRC_CCITT ~PPP_ASYNC"

pkg_pretend() {
	use oslec && CONFIG_CHECK+=" ECHO"
	check_extra_config
}

src_unpack() {
	unpack ${A}
	# Copy the firmware tarballs over, the makefile will try and download them otherwise
	for file in ${A} ; do
		[[ "${file}" = dahdi-fw* ]] || continue
		cp "${DISTDIR}"/${file} "${S}"/drivers/dahdi/firmware/ ||
			die "Error copying ${file} to ${S}/drivers/dahdi/firmware/"
	done
	# But without the .bin's it'll still fall over and die, so copy those too.
	mv *.bin "${S}"/drivers/dahdi/firmware/ ||
		die "Error moving firmware files into the right folders."
}

src_prepare() {
	# Sin .git ni .version, build_tools/make_version devuelve "UNKNOWN".
	echo "3.4.0-git${COMMIT:0:7}" > .version || die

	# install-modules lanza /sbin/depmod -a sobre el /lib/modules real (viola el
	# sandbox); linux-mod-r1_pkg_postinst ya ejecuta depmod tras instalar.
	sed -i -e "/\/sbin\/depmod -a/d" Makefile || die "Failed to drop depmod from Makefile"
	grep -q "/sbin/depmod" Makefile && die "depmod call still present in Makefile"

	if use flash; then
		sed -i -e "s:/\* #define FXSFLASH \*/:#define FXSFLASH:" include/dahdi/dahdi_config.h ||
			die "Failed to define FXSFLASH"
		sed -i -e "s:/\* #define SHORT_FLASH_TIME \*/:#define SHORT_FLASH_TIME:" \
			include/dahdi/dahdi_config.h || die "Failed to define SHORT_FLASH_TIME"
	fi
	if use oslec; then
		sed -i -e 's:^#include .*oslec[.]h:#include "/usr/src/linux/drivers/misc/echo/oslec.h:' \
			drivers/dahdi/dahdi_echocan_oslec.c || die "Failed to prepare oslec source files."
	fi
	default
}

src_compile() {
	unset ARCH
	emake V=1 CC="$(tc-getCC)" LD="$(tc-getLD)" KSRC="${KV_OUT_DIR}" KVERS="${KV_FULL}" \
		DAHDI_MODULES_EXTRA="$(usex oslec "dahdi_echocan_oslec.o" "")" \
		LDFLAGS="$(raw-ldflags)" all
}

src_install() {
	einfo "Installing kernel module"
	emake V=1 CC="$(tc-getCC)" LD="$(tc-getLD)" KSRC="${KV_OUT_DIR}" KVERS="${KV_FULL}" DESTDIR="${D}" \
		DAHDI_MODULES_EXTRA="$(usex oslec "dahdi_echocan_oslec.o" "")" \
		LDFLAGS="$(raw-ldflags)" install

	# Remove the blank "version" files (these files are all empty, and root owned).
	find "${ED}/lib/firmware" -name ".*" -delete || die "Error removing empty firmware version files"

	# If the kernel sources have a System.map, and there a suitable depmod
	# available (seemingly when we're not cross-compiling), then the kernel
	# sources depmod kicks in.  Remove the files caused by that.
	find "${ED}/lib/modules" -name "modules.*" -delete || die "Error deleting bogus modules.* files"
}
