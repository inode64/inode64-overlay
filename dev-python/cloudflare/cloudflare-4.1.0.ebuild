# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..13} python3_13t pypy3 )
DISTUTILS_USE_PEP517="hatchling"
inherit distutils-r1 pypi

DESCRIPTION="Python wrapper for the Cloudflare v4 API"
HOMEPAGE="https://pypi.org/project/cloudflare/"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
RDEPEND="
	dev-python/httpx[${PYTHON_USEDEP}]
	dev-python/pydantic[${PYTHON_USEDEP}]
	dev-python/typing-extensions[${PYTHON_USEDEP}]
	dev-python/anyio[${PYTHON_USEDEP}]
	dev-python/sniffio[${PYTHON_USEDEP}]
"
BDEPEND="
	test? (
		dev-python/nox[${PYTHON_USEDEP}]
		dev-python/mypy[${PYTHON_USEDEP}]
		dev-python/respx[${PYTHON_USEDEP}]
		dev-python/pytest-asyncio[${PYTHON_USEDEP}]
		dev-util/ruff[${PYTHON_USEDEP}]
		dev-python/time-machine[${PYTHON_USEDEP}]
		dev-python/dirty-equals[${PYTHON_USEDEP}]
		dev-python/importlib-metadata[${PYTHON_USEDEP}]
		dev-python/rich[${PYTHON_USEDEP}]
	)
"

DOCS=( {CHANGELOG,CONTRIBUTING,README,SECURITY,api}.md )

PROPERTIES="test_network" #actually sends a test request

distutils_enable_tests pytest

python_test() {
	if [ -z "${CLOUDFLARE_API_TOKEN}" ]; then
		ewarn "Skipping some tests which require an actual cloudflare api token"
		ewarn "To run them, provide the token in the environment variable CLOUDFLARE_API_TOKEN"
		ewarn "The permissions needed are zone dns edit and user details read"
		local EPYTEST_IGNORE=(
			'test_dns_records.py' 'test_radar_returning_csv.py'
			'test_dns_import_export.py' 'test_load_balancers.py' 'test_log_received.py'
			'test_rulesets.py' 'test_urlscanner.py' 'test_paging_thru_zones.py'
			'test_purge_cache.py'
			'test_graphql.py' 'test_waiting_room.py' 'test_workers.py'
		)
		# these test(s) need an api key/token setup
		# Permissions needed are zone dns edit and user details read, account worker scripts edit,
		# zone analytics read, zone load balancer edit, account ruleset edit, zone firewall edit
		# account url scanner edit, zone waiting room edit, zone cache purge
	fi

	# Not sure what permissions/tokens/whatever this test needs, maybe both a token and old api login
	# tried several of the ssl related options for the cert test but no luck either
	# Tried several of the prefix related options to try to get loa docs working but nope
	local EPYTEST_IGNORE+=(
		'test_images_v2_direct_upload.py'
		'test_issue114.py' 'test_certificates.py'
		'test_loa_documents.py'
		'test_load_balancers.py' 'test_rulesets.py'
	)

	# maybe needs a paid plan or just some unknown permission
	local EPYTEST_DESELECT=(
		'test_load_balancers.py::test_load_balancers_list_regions'
		'test_load_balancers.py::test_load_balancers_pools'
		'test_load_balancers.py::test_load_balancers_search'
		'test_load_balancers_get_regions'
		'test_rulesets.py::test_zones_ruleset_delete'
		'test_rulesets.py::test_zones_ruleset_post'
		'test_rulesets.py::test_zones_rulesets_get_specific'
	)

	epytest
}
