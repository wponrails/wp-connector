<?php
/*
Plugin Name: WP-API-ACF
Version: 0.0.1
Description: plugin for adding ACF fields to WP-API
*/

function wp_api_acf_json_prepare_post( $_post ) {
  $fields = get_fields($_post['ID']); 

  if( $fields )
  {
    foreach( $fields as $field_name => $value )
    {
      $_post[$field_name] = get_field($field_name, $_post['ID']);
    }
  }

  return $_post;
}
add_filter( 'json_prepare_post', 'wp_api_acf_json_prepare_post' );