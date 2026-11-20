# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

set -eu
cli=$1
wordpress=$2
symfony=$3
plugin=$4
temp=$5
driver=$6

php=( "${cli}/sapi/cli/php" -n -d "extension_dir=${cli}/modules" )
if [[ -f ${cli}/modules/opcache.so ]]; then
	php+=( -d "zend_extension=${cli}/modules/opcache.so" )
fi
php+=( -d opcache.enable_cli=1 -d opcache.jit=disable -d opcache.jit_buffer_size=0
	-d memory_limit=512M -d display_errors=0 -d log_errors=1
	-d 'error_reporting=E_ALL & ~E_DEPRECATED & ~E_USER_DEPRECATED' )
export APP_ENV=prod APP_DEBUG=0
export DATABASE_URL='sqlite:///%kernel.project_dir%/data/database.sqlite'
PHP_PGO_DB_DIR=$(mktemp -d "${temp}/wordpress-db.XXXXXX")
export PHP_PGO_DB_DIR

ln -sfn "${plugin}" "${wordpress}/wp-content/plugins/sqlite-database-integration"
cp "${plugin}/db.copy" "${wordpress}/wp-content/db.php"
cat > "${wordpress}/wp-config.php" <<'PHP'
<?php
define('DB_NAME', 'pgo');
define('DB_USER', '');
define('DB_PASSWORD', '');
define('DB_HOST', '');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');
define('DB_DIR', getenv('PHP_PGO_DB_DIR'));
define('WP_HOME', 'http://bench.invalid');
define('WP_SITEURL', WP_HOME);
define('WP_HTTP_BLOCK_EXTERNAL', true);
define('DISABLE_WP_CRON', true);
define('AUTOMATIC_UPDATER_DISABLED', true);
$table_prefix = 'wp_';
require_once ABSPATH . 'wp-settings.php';
PHP

request() {
	"${php[@]}" "${driver}" "$1" "$2" > "${temp}/pgo-response.html"
	if ! grep -Fqi -- "$3" "${temp}/pgo-response.html" || ! grep -Fqi -- '</html>' "${temp}/pgo-response.html"; then
		echo "Unexpected response from $1 on route $2" >&2
		return 1
	fi
}

# Keep installation and Symfony cache generation out of the production workload.
(
	saved=$(mktemp -d "${temp}/pgo-save.XXXXXX")
	mv "${temp}/pgo" "${saved}/"
	trap 'rm -rf "${temp}/pgo"; mv "${saved}/pgo" "${temp}/"; rmdir "${saved}"' EXIT
	"${php[@]}" "${driver}" "${wordpress}" install > "${temp}/pgo-post-id"
	request "${symfony}/public" /en/blog/ 'Pellentesque vitae'
)

read -r post_id < "${temp}/pgo-post-id"
[[ ${post_id} =~ ^[1-9][0-9]*$ ]]
for (( i=0; i<30; ++i )); do
	request "${wordpress}" "/?p=${post_id}" 'Journal entry 1'
	request "${wordpress}" '/?s=Journal' 'Journal entry'
done
for (( i=0; i<30; ++i )); do
	request "${symfony}/public" /en/blog/posts/in-hac-habitasse-platea-dictumst 'In hac habitasse'
	request "${symfony}/public" /en/blog/ 'Pellentesque vitae'
done
