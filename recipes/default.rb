#
# Cookbook Name:: sqitch
# Recipe:: default
#
# Copyright 2013-2015, Chef Software, Inc.
#

include_recipe 'perl'

# TODO: Consider using the cpan[1] cookbook instead for more robust
# installation (specifying versions, installing from an artifact, etc.)
#
# [1]: http://community.opscode.com/cookbooks/cpan
cpan_module 'App::Sqitch'

# Map values of node['sqitch']['engine'] to the Perl modules that
# support them.
engine_modules = {
  'pg'     => 'DBD::Pg',
  'sqlite' => 'DBD::SQLite',
  'oracle' => 'DBD::oracle'
}

# Install the engine the user wants
cpan_module engine_modules[node['sqitch']['engine']]
