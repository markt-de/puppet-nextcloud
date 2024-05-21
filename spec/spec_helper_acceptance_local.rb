# frozen_string_literal: true

require 'puppet_litmus'
require 'singleton'
require 'tempfile'

class LitmusHelper
  include Singleton
  include PuppetLitmus
end

# create a file on the test machine
def create_remote_file(name, dest_filepath, file_content)
  Tempfile.open name do |tempfile|
    File.open(tempfile.path, 'w') { |file| file.puts file_content }
    LitmusHelper.instance.bolt_upload_file(tempfile.path, "#{dest_filepath}/#{name}")
    puts "Uploaded file #{tempfile.path} to #{dest_filepath}/#{name}"
  end
end

hiera_config_content = <<-EOS
# Created by puppet litmus
version: 5
defaults:
  datadir: data
  data_hash: yaml_data
hierarchy:
  - name: "Common data"
    path: "common.yaml"
EOS

# rubocop:disable all
hiera_data_content = if os[:family].eql?('debian')
<<-EOS
---
# Created by puppet litmus
php::composer: true
php::extensions:
  bcmath: {}
  dba: {}
  gd: {}
  gmp: {}
  intl: {}
  json: {}
  ldap: {}
  mbstring: {}
  mysqlnd: {}
  opcache: {}
  pdo: {}
  xml: {}
  zip: {}
php::fpm: false
php::manage_repos: false
php::settings:
  'PHP/memory_limit': '768M'
php::globals::php_version: '7.4'
mysql::server::root_password: 'strongpassword'
EOS
elsif os[:family].eql?('ubuntu')
<<-EOS
---
# Created by puppet litmus
php::composer: true
php::extensions:
  bcmath: {}
  dba: {}
  gd: {}
  gmp: {}
  intl: {}
  ldap: {}
  mbstring: {}
  mysqlnd: {}
  opcache: {}
  pdo: {}
  xml: {}
  zip: {}
php::fpm: false
php::manage_repos: false
php::settings:
  'PHP/memory_limit': '768M'
php::globals::php_version: '8.1'
mysql::server::root_password: 'strongpassword'
EOS
else
<<-EOS
---
# Created by puppet litmus
php::composer: true
php::extensions:
  bcmath: {}
  dba: {}
  gd: {}
  gmp: {}
  intl: {}
  json: {}
  ldap: {}
  mbstring: {}
  mysqlnd: {}
  opcache: {}
  pdo: {}
  process: {}
  xml: {}
  zip: {}
php::fpm: false
php::manage_repos: false
php::settings:
  'PHP/memory_limit': '768M'
php::globals::php_version: '7.4'
mysql::server::root_password: 'strongpassword'
EOS
end
# rubocop:enable all

setup_php_pp = <<-EOS
if (($facts['os']['family'] == 'RedHat') and ($facts['os']['release']['major'] == '8')) {
  package { 'php':
    ensure => '7.4',
    enable_only => true,
    provider => 'dnfmodule',
  }
}
include php
EOS

setup_mysql_pp = <<-EOS
include mysql::server
mysql::db { 'nextcloud':
  user     => 'nextcloud',
  password => 'secRetPasSwOrd',
  host     => 'localhost',
  grant    => ['ALL'],
}
EOS

RSpec.configure do |c|
  c.before :suite do
    puts 'Running acceptance test with custom hiera data'

    # Install soft dependencies.
    LitmusHelper.instance.run_shell('puppet module install puppet/php')
    LitmusHelper.instance.run_shell('puppet module install puppetlabs/mysql')

    # Configure Hiera and add data to setup requirements.
    LitmusHelper.instance.run_shell('mkdir /tmp/data')
    create_remote_file('hiera.yaml', '/tmp', hiera_config_content)
    create_remote_file('common.yaml', '/tmp/data', hiera_data_content)

    # Avoid dependency hell by setting things up in separate runs.
    LitmusHelper.instance.apply_manifest(setup_php_pp, catch_failures: true, hiera_config: '/tmp/hiera.yaml')
    LitmusHelper.instance.apply_manifest(setup_mysql_pp, catch_failures: true, hiera_config: '/tmp/hiera.yaml')
  end
end
