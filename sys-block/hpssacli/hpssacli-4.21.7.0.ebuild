# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit rpm linux-info

MY_PV="$(ver_cut 1-2)-$(ver_cut 3-4)"

DESCRIPTION="HPE Smart Storage Administrator (HPE SSA) CLI (HPSSACLI, formerly HPACUCLI)"
HOMEPAGE="https://support.hpe.com/hpsc/swd/public/detail?swItemId=MTX_521fc533ba8f468f9ad9db20e4"
SRC_URI="https://downloads.hpe.com/pub/softlib2/software1/pubsw-linux/p1857046646/v183344/ssacli-${MY_PV}.x86_64.rpm"

LICENSE="hpe"
SLOT="0"
KEYWORDS="-* amd64"
IUSE=""

DEPEND=""
RDEPEND="elibc_glibc? ( >sys-libs/glibc-2.14 )"

MY_HPSSACLI_BASEDIR="opt/smartstorageadmin/ssacli/bin"
S="${WORKDIR}"

pkg_pretend() {
	CONFIG_CHECK="CHR_DEV_SG"

	check_extra_config
}
src_prepare() {
	default
	gunzip usr/man/man8/ssacli.8.gz || die
}

src_install() {
	insinto ${MY_HPSSACLI_BASEDIR}

	doins "${MY_HPSSACLI_BASEDIR}"/{mklocks.sh,rmstr,ssacli,ssascripting}
	fperms 755 "/${MY_HPSSACLI_BASEDIR}"/{mklocks.sh,rmstr,ssacli,ssascripting}

	dosbin usr/sbin/ssacli
	dosbin usr/sbin/ssascripting

	insinto /usr/share/smartupdate/ssacli/
	doins usr/share/smartupdate/ssacli/component.xml

	doman usr/man/man8/ssacli.8
	dodoc ${MY_HPSSACLI_BASEDIR}/ssacli*.txt
}
