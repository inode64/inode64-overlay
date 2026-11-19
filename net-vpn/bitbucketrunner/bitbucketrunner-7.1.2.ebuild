# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

DESCRIPTION="Bitbucket self-hosted Pipelines runner"
HOMEPAGE="https://support.atlassian.com/bitbucket-cloud/docs/runners/"
SRC_URI="https://product-downloads.atlassian.com/software/bitbucket/pipelines/atlassian-bitbucket-pipelines-runner-${PV}.tar.gz"

S="${WORKDIR}"
LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="test mirror"
# runner.jar is class file version 69, it cannot load on Java older than 25.
RDEPEND="
	app-misc/ca-certificates
	>=virtual/jre-25
	dev-libs/glib
	dev-vcs/git
"

src_install() {
	insinto /opt/bitbucketrunner
	doins bin/runner.jar

	insinto /etc/bitbucketrunner
	doins "${FILESDIR}"/logback.xml
	insopts -m0600
	doins "${FILESDIR}"/tunnel.cfg

	exeinto /usr/libexec/bitbucketrunner
	newexe "${FILESDIR}"/bitbucketrunner-cleanup.sh cleanup

	newinitd "${FILESDIR}/bitbucketrunner.initd" bitbucketrunner
	newconfd "${FILESDIR}/bitbucketrunner.confd" bitbucketrunner
	# The log and working directories belong to the service user, which
	# conf.d can change: the init script creates them with checkpath and the
	# unit with LogsDirectory/CacheDirectory. A tmpfiles entry would hand them
	# back to root on every boot and upgrade.
	systemd_dounit "${FILESDIR}/bitbucketrunner.service"
}

pkg_postinst() {
	if [[ ! -d /etc/ssl/certs/java/cacerts ]]; then
		# Java certificates is necessary for the runner to work properly
		mkdir -p /etc/ssl/certs/java
	fi
	update-ca-certificates -f

	einfo "The configuration file tunnel.cfg contains sensitive tokens and must be accessible only by the service user."
	einfo "Ensure permissions are set to 600 and not accessible by other users."
	einfo "The runner needs Java 25 or newer as the system VM: check 'eselect java-vm list'."
}
