#
# Cookbook Name:: sqitch
# Recipe:: default
#
# Copyright (C) 2013 Opscode, Inc.
#

include_recipe "perl"

# TODO: Consider using the cpan[1] cookbook instead for more robust
# installation (specifying versions, installing from an artifact, etc.)
#
# [1]: http://community.opscode.com/cookbooks/cpan

# Unfortunately, we can't just run `cpan_module "App::Sqitch"` with
# the ancient version of the Perl cookbook we've got in production.
# Until we can get that updated, we'll just fake it by installing
# cpanminus ourselves and installing sqitch that way.
#
# (sadpanda)

# This is the same cpanminus installation logic from the perl
# cookbook, but with the attribute values hard-coded
remote_file '/usr/local/bin/cpanm' do
  source 'https://raw.github.com/miyagawa/cpanminus/1.5015/cpanm'
  checksum '8cb7b62b55a3043c4ccb'
  owner "root"
  group "root"
  mode 0755
end

# Can't use the cpan_module definition because it uses cpan, not cpanm
execute "cpanm App::Sqitch"

# Map values of node['sqitch']['engine'] to the Perl modules that
# support them.
engine_modules = {
  "pg"     => "DBD::Pg",
  "sqlite" => "DBD::SQLite",
  "oracle" => "DBD::oracle"
}

# Install the engine the user wants
cpan_module engine_modules[node['sqitch']['engine']]
