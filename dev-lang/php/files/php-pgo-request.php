<?php
// Copyright 2026 Gentoo Authors
// Distributed under the terms of the GNU General Public License v2

[, $root, $route] = $argv;
chdir($root);
$_SERVER['HTTP_HOST'] = $_SERVER['SERVER_NAME'] = 'bench.invalid';
$_SERVER['SERVER_PORT'] = 80;
$_SERVER['REMOTE_ADDR'] = '127.0.0.1';
$_SERVER['REQUEST_METHOD'] = 'GET';
$_SERVER['SERVER_PROTOCOL'] = 'HTTP/1.1';
$_SERVER['SCRIPT_NAME'] = $_SERVER['PHP_SELF'] = '/index.php';
$_SERVER['SCRIPT_FILENAME'] = $root . '/index.php';
$_SERVER['REQUEST_URI'] = $route;
$_SERVER['QUERY_STRING'] = parse_url($route, PHP_URL_QUERY) ?? '';
parse_str($_SERVER['QUERY_STRING'], $_GET);
$_REQUEST = $_GET;

if ($route === 'install') {
    define('WP_INSTALLING', true);
    // The build has no mail transport or real administrator.
    function wp_new_blog_notification(...$args) {}
    require 'wp-load.php';
    require_once ABSPATH . 'wp-admin/includes/upgrade.php';
    wp_install('PGO Journal', 'bench', 'bench@example.invalid', false, '', 'benchmark-fixture');
    for ($i = 1; $i <= 4; ++$i) {
        $id = wp_insert_post([
            'post_title' => "Journal entry $i",
            'post_content' => "<!-- wp:paragraph --><p>Training article $i</p><!-- /wp:paragraph -->",
            'post_status' => 'publish',
            'post_author' => 1,
        ], true);
        if (is_wp_error($id)) {
            throw new RuntimeException($id->get_error_message());
        }
        if ($i === 1) {
            echo $id, PHP_EOL;
        }
    }
} else {
    require 'index.php';
}
