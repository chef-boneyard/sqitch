#
# Cookbook:: sqitch
# Recipe:: default
#
# Copyright:: 2013-2016, Chef Software, Inc.
#

include_recipe 'build-essential'
include_recipe 'perl'

# TODO: Consider using the cpan[1] cookbook instead for more robust
# installation (installing from an artifact, etc.)
#
# [1]: https://supermarket.chef.io/cookbooks/cpan
cpan_module 'App::Sqitch'

# Map values of node['sqitch']['engine'] to the Perl modules that
# support them.
engine_modules = {
  'pg'     => 'DBD::Pg',
  'sqlite' => 'DBD::SQLite',
  'oracle' => 'DBD::oracle',
  'mysql'  => 'DBD::mysql'
}

# prevent pg module install failures on debian platforms
package 'libpq-dev' if node['platform_family'] == 'debian' && node['sqitch']['engine'] == 'pg'

# Install the engine the user wants
cpan_module engine_modules[node['sqitch']['engine']]
