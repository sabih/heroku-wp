<?php
/*
Plugin name: Secure DB Connection
Plugin URI: http://wordpress.org/plugins/secure-db-connection/
Description: Sets SSL keys and certs for encrypted database connections
Author: Xiao Yu
Author URI: http://xyu.io/
Version: 1.0
*/

if ( ! defined( 'ABSPATH' ) ) exit;

class WP_SecureDBConnection {

	public function __construct() {
		$this->init();
	}

	public function init() {
		add_action( 'admin_enqueue_scripts', array( $this, 'enqueue_admin_styles' ) );
		add_filter( 'dashboard_glance_items', array( $this, 'add_to_dashboard' ) );

		register_deactivation_hook( __FILE__, array( $this, 'on_deactivation' ) );
	}

	public function enqueue_admin_styles( $hook_suffix ) {
		if ( "index.php" === $hook_suffix ) {
			$plugin = get_plugin_data( __FILE__ );
			wp_enqueue_style(
				'secure-db-connection',
				plugin_dir_url( __FILE__ ) . 'includes/admin-page.css',
				null,
				$plugin[ 'Version' ]
			);
		}
	}

	/**
	 * Add to Dashboard At a Glance
	 */
	public function add_to_dashboard( $elements ) {
		if ( current_user_can( 'administrator' ) ) {
			$status = $this->_getConnStatus();

			if ( empty( $status['ssl_cipher'] ) ) {
				printf(
					'<li class="securedbconnection-nossl"><span>%s</span></li>',
					'MySQL connection is unencrypted'
				);
			} else {
				printf(
					'<li class="securedbconnection-ssl"><span>%s</span></li>',
					"MySQL connection is secured with {$status['ssl_version']} ({$status['ssl_cipher']})"
				);
			}
		}

		return $elements;
	}

	public function on_deactivation() {
		global $wp_filesystem;
		global $wpdb;

		if ( file_exists( WP_CONTENT_DIR . '/db.php' ) && ( $wpdb instanceof wpdb_ssl ) ) {
			if ( WP_Filesystem( request_filesystem_credentials( '' ) ) ) {
				$wp_filesystem->delete( WP_CONTENT_DIR . '/db.php' );
			}
		}
	}

	private function _getConnStatus() {
		global $wpdb;

		$results = $wpdb->get_results(
			"SHOW SESSION STATUS WHERE variable_name IN ( 'Ssl_cipher', 'Ssl_version' )"
		);

		$return = array();
		foreach ( $results as $row ) {
			$key = strtolower( $row->Variable_name );
			$return[ $key ] = $row->Value;
		}
		return $return;
	}

}

new WP_SecureDBConnection();
