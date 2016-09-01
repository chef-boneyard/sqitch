sqitch cookbook
===============
[![Build Status](https://travis-ci.org/chef-cookbooks/sqitch.svg?branch=master)](http://travis-ci.org/chef-cookbooks/sqitch)
[![Cookbook Version](https://img.shields.io/cookbook/v/sqitch.svg)](https://supermarket.chef.io/cookbooks/sqitch)

This cookbook installs [sqitch](http://sqitch.org), a
database-agnostic change management system.  It also provides LWRPs
for using Sqitch to deploy database schema changes.

## Features

- `sqitch` LWRP with support for deploying and reverting schema changes
- `why-run` support, indicating which changesets (if any) would be deployed

Tested on PostgreSQL.  Theoretically supports SQLite, Oracle, and MySQL as
well, but is untested for those platforms.

##Requirements
#### Platforms
- Debian/Ubuntu
- RHEL/CentOS/Scientific/Amazon/Oracle

#### Chef
- Chef 11+

#### Cookbooks
- perl


## Usage

In general, you should just use the `sqitch` LWRP (it will
automatically include the recipe that installs Sqitch, so you don't
need to worry about that).

For example, to deploy version 2.0.0 of the `myface` schema, you could do:

    sqitch "myface_schema" do
      action :deploy
      db_name "myface_db"
      to_target "2.0.0"
      top_dir "/path/to/myface/sqitch/dir"
    end

Similarly, to roll back to version 1.5.0, you might have:

    sqitch "myface_schema" do
      action :revert
      db_name "myface_db"
      to_target "1.5.0"
      top_dir "/path/to/myface/sqitch/dir"
    end

Please consult the documentation in `/resources/default.rb` for
complete details on the LWRP.

## Attributes

* `node['sqitch']['engine']` Controls which driver module is
  installed, as well as which one is used by the LWRP.  Defaults to
  `pg` for PostgreSQL.

## Recipes

* `default` - Installs Sqitch, as well as necessary driver modules for
  the databases it supports.

## Documentation

Additional documentation can be generated using [Yard][].

    bundle install
    rake yard

You can view the documentation in your browser by running a yard
server:

    yard server --reload -B localhost --plugin yard-chef

[Yard]:(http://yardoc.org)


License & Authors
-----------------

**Author:** Cookbook Engineering Team (<cookbooks@chef.io>)

**Copyright:** 2008-2016, Chef Software, Inc.

```
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
