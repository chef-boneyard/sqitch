name             'sqitch'
maintainer       'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license          'Apache-2.0'
description      'Installs sqitch for managing SQL changesets'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.1.0'
recipe           'sqitch', 'Installs sqitch'

depends 'perl', '>= 1.0.0'
depends 'build-essential', '>= 5.0'

supports 'all'

source_url 'https://github.com/chef-cookbooks/sqitch'
issues_url 'https://github.com/chef-cookbooks/sqitch/issues'
chef_version '>= 12.1' if respond_to?(:chef_version)
