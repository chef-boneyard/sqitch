name             "sqitch"
maintainer       "Opscode, Inc."
maintainer_email "cm@opscode.com"
license          "Apache 2.0"
description      "Installs sqitch for managing SQL changesets"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"
recipe           "sqitch", "Installs sqitch"

depends "perl"
