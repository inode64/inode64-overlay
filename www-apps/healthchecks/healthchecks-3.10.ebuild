# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
#DISTUTILS_USE_PEP517="no"
#inherit python-single-r1
#inherit distutils-r1
inherit python-single-r1 webapp optfeature

DESCRIPTION="A cron monitoring service and background task monitoring service"
HOMEPAGE="https://github.com/healthchecks/healthchecks"
SRC_URI="https://github.com/${PN}/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="BSD"
KEYWORDS="~amd64 ~arm64"

IUSE="apache apprise mysql nginx postgres +sqlite"
REQUIRED_USE="
	${PYTHON_REQUIRED_USE}
	|| ( mysql postgres sqlite )
"

DOCS="CONTRIBUTING.md README.md SECURITY.md"

RDEPEND="
	${PYTHON_DEPS}
	apache? ( www-apache/mod_wsgi )
	apprise? ( dev-python/apprise )
	mysql? ( dev-python/mysqlclient )
	nginx? ( www-servers/nginx[nginx_modules_uwsgi] )
	postgres? ( dev-python/psycopg )
	sqlite? ( dev-lang/python[sqlite] )
	!apache? ( !nginx? ( www-servers/uwsgi ) )
	$(python_gen_cond_dep '
		dev-python/aiosmtpd[${PYTHON_USEDEP}]
		dev-python/cronsim[${PYTHON_USEDEP}]
		>=dev-python/django-5.1[${PYTHON_USEDEP}]
		dev-python/django-compressor[${PYTHON_USEDEP}]
		dev-python/django-stubs-ext[${PYTHON_USEDEP}]
		dev-python/fido2[${PYTHON_USEDEP}]
		dev-python/oncalendar[${PYTHON_USEDEP}]
		dev-python/pycurl[${PYTHON_USEDEP}]
		dev-python/pydantic[${PYTHON_USEDEP}]
		dev-python/pyjwt[${PYTHON_USEDEP}]
		dev-python/pyotp[${PYTHON_USEDEP}]
		dev-python/segno[${PYTHON_USEDEP}]
		dev-python/statsd[${PYTHON_USEDEP}]
		dev-python/whitenoise[${PYTHON_USEDEP}]
	')
"
DEPEND="
	${RDEPEND}
"
PROPERTIES="test_network" #actually sends a test request

pkg_setup() {
	python-single-r1_pkg_setup
	webapp_pkg_setup
}

src_test() {
	./manage.py test
}

src_compile() {
	DEBUG=False SECRET_KEY=build-key ./manage.py compress --force
	DEBUG=False SECRET_KEY=build-key ./manage.py collectstatic --no-input
}

src_install() {
	python_optimize hc

	mv hc/local_settings.py.example hc/local_settings.py || die

	webapp_src_preinst

	insinto "${MY_HTDOCSDIR}"

	doins manage.py
	doins CHANGELOG.md
	doins -r hc static static-collected templates

	webapp_hook_script "${FILESDIR}"/reconfig
	webapp_configfile "${MY_HTDOCSDIR}"/hc/local_settings.py

	local x
	for x in $(find templates/ -type f); do
		webapp_configfile "${MY_HTDOCSDIR}"/${x}
	done

	webapp_src_install

	newinitd "${FILESDIR}"/ht-sendalerts.initd ht-sendalerts
	newinitd "${FILESDIR}"/ht-sendreports.initd ht-sendreports
}

pkg_postinst() {
	webapp_pkg_postinst

	optfeature "send Signal notifications\
	    https://blog.healthchecks.io/2023/01/how-healthchecks-sends-signal-notifications" \
	    net-im/signal-cli-bin
}
