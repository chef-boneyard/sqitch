name             "sqitch"
maintainer       'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license          "Apache 2.0"
description      "Installs sqitch for managing SQL changesets"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.5.0"
recipe           "sqitch", "Installs sqitch"

depends "perl", ">= 1.0.0"

source_url 'https://github.com/chef-cookbooks/sqitch' if respond_to?(:source_url)
issues_url 'https://github.com/chef-cookbooks/sqitch/issues' if respond_to?(:issues_url)
