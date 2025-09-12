# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd tmpfiles

DESCRIPTION="Bitbucket self-hosted Pipelines runner"
HOMEPAGE="https://support.atlassian.com/bitbucket-cloud/docs/runners/"
SRC_URI="https://product-downloads.atlassian.com/software/bitbucket/pipelines/atlassian-bitbucket-pipelines-runner-${PV}.tar.gz"

S="${WORKDIR}"
LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="test mirror"
RDEPEND="
	app-shells/bash
	>=virtual/jre-21
	dev-libs/glib
"

src_install() {
	insinto /opt/bitbucketrunner
	doins bin/runner.jar

	diropts -m0600
	insinto /etc/bitbucketrunner
	doins "${FILESDIR}"/logback.xml
	doins "${FILESDIR}"/tunnel.cfg

	newinitd "${FILESDIR}/bitbucketrunner.initd" bitbucketrunner
	newconfd "${FILESDIR}/bitbucketrunner.confd" bitbucketrunner
	systemd_douserunit "${FILESDIR}/bitbucketrunner.service"

	dotmpfiles "${FILESDIR}/${PN}.tmpfiles.conf"
}

pkg_postinst() {
	tmpfiles_process ${PN}.tmpfiles.conf
	if [[ ! -d /etc/ssl/certs/java/cacerts ]]; then
		# Java certificates is necessary for the runner to work properly
		mkdir -p /etc/ssl/certs/java
	fi
	update-ca-certificates -f

	einfo "The configuration file tunnel.cfg contains sensitive tokens and must be accessible only by the service user."
	einfo "Ensure permissions are set to 600 and not accessible by other users."
}
