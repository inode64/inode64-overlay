# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( pypy3 python3_{10..13} )
#DISTUTILS_USE_PEP517="no"
#inherit python-single-r1
#inherit distutils-r1
inherit python-any-r1 webapp

DESCRIPTION="A cron monitoring service with a web-based dashboard, API, and notification integrations"
HOMEPAGE="https://github.com/healthchecks/healthchecks"
SRC_URI="https://github.com/${PN}/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="BSD"
KEYWORDS="~amd64 ~arm64"

IUSE="apprise mysql postgres sqlite"
REQUIRED_USE="|| ( mysql postgres sqlite )"

DOCS="CONTRIBUTING.md README.md SECURITY.md"

DEPEND="
	${PYTHON_DEPS}
"
RDEPEND="
	${DEPEND}
	apprise? ( dev-python/apprise )
	mysql? ( dev-python/mysqlclient )
	postgres? ( dev-python/psycopg )
	sqlite? ( dev-lang/python[sqlite] )
	$(python_gen_any_dep '
	dev-python/whitenoise[${PYTHON_USEDEP}]
	dev-python/fido2[${PYTHON_USEDEP}]
	dev-python/segno[${PYTHON_USEDEP}]
	dev-python/oncalendar[${PYTHON_USEDEP}]
	dev-python/cronsim[${PYTHON_USEDEP}]
	dev-python/pycurl[${PYTHON_USEDEP}]
	>=dev-python/django-5.1[${PYTHON_USEDEP}]
	dev-python/django-compressor[${PYTHON_USEDEP}]
	dev-python/django-stubs-ext[${PYTHON_USEDEP}]
	dev-python/aiosmtpd[${PYTHON_USEDEP}]
	dev-python/statsd[${PYTHON_USEDEP}]
	dev-python/pyotp[${PYTHON_USEDEP}]
	dev-python/pydantic[${PYTHON_USEDEP}]
	')
"

PROPERTIES="test_network" #actually sends a test request

pkg_setup() {
	python-any-r1_pkg_setup
	webapp_pkg_setup
}

src_test() {
	./manage.py test
}

src_compile() {
	python -m compileall .
	./manage.py compress --force
	./manage.py collectstatic --no-input
}

src_install() {
	mv hc/local_settings.py.example hc/local_settings.py || die
	webapp_src_preinst

	insinto "${MY_HTDOCSDIR}"

	doins manage.py
	doins CHANGELOG.md
	doins -r hc static static-collected stuff templates

	webapp_configfile "${MY_HTDOCSDIR}"/hc/local_settings.py
	webapp_src_install
}

pkg_postinst() {
	webapp_pkg_postinst
}
