# Execute Sqitch

# Deploy SQL changesets to a database.  Corresponds to `sqitch deploy`
actions :deploy

# Roll back SQL changesets in a database.  Corresponds to `sqitch
# revert`
actions :revert

# Others exist, but these are the key ones for server-side ops

default_action :deploy

# The kind of database sqitch will be interacting with.  This
# influences which driver module will be installed and used.
#
# Defaults to `node['sqitch']['engine']`, since this is also what
# controls which sqitch driver module is installed.  You probably
# don't want to change it to something different.
#
# @todo Consider temporarily disallowing sqlite and oracle, since we
#   have no experience with them and can't devote time to testing /
#   supporting them right now.
attribute :engine,
kind_of: String,
default: node['sqitch']['engine'],
equal_to: %w(pg sqlite oracle)

# The absolute path to the database client application (e.g. `psql`
# for PostgreSQL) that sqitch should use to interact with the
# database.  Only required if the executable is not on the search
# path.
attribute :db_client,
kind_of: String

# The name of the database to connect to.  Required for PostgreSQL and
# Oracle; SQLite will create the database if it doesn't already exist.
attribute :db_name,
kind_of: String

# The name of the system user that will execute the sqitch command.
# May not be the same as the database system account.  May or may not
# be required, depending on how your database user security is set up.
attribute :user,
kind_of: String

# The database user to connect to the database as.
#
# @todo Not all engines require this; find out which ones do (probably
#   pg and oracle), and incorporate that into validations
attribute :db_user,
kind_of: String

# The database host to connect to.
#
# @todo Not all engines require this; find out which ones do (probably
#   pg and oracle), and incorporate that into validations
attribute :db_host,
kind_of: String

# The database port to connect to.
#
# @todo Not all engines require this; find out which ones do (probably
#   pg and oracle), and incorporate that into validations
attribute :db_port,
kind_of: Integer

# The directory in which to look for sqitch changesets (deploy,
# revert, and verify scripts), as well as the `sqitch.plan` file.
#
# By default this is the directory $PWD/sql.  You will almost
# certainly need to set this.
#
# @todo So, should this just be required, then?
attribute :top_dir,
kind_of: String

# The directory in which to find deploy scripts.  Defaults to `deploy`
# inside `top_dir`.
attribute :deploy_dir,
kind_of: String

# The directory in which to find revert scripts.  Defaults to `revert`
# inside `top_dir`.
attribute :revert_dir,
kind_of: String

# The directory in which to find verify scripts.  Defaults to `verify`
# inside `top_dir`.
attribute :verify_dir,
kind_of: String

# The file extension of deploy, revert, and verify scripts.  Defaults
# to `sql`
attribute :extension,
kind_of: String

# The location of the plan file.  Defaults to `sqitch.plan` in
# `top_dir`.
attribute :plan_file,
kind_of: String

# A sqitch tag to deploy or revert to.  Required for revert, optional
# for deploy.
#
# If a target is specified for a deploy, it must be later than what
# the database is currently at (it may also be the tag that the
# database is currently at).  If unspecified for a deploy, all
# available changesets are deployed.
#
# When reverting, the target is not optional, and must be at or
# earlier than the current database state.  The sqitch executable
# allows for reverting without specifying a target, but this has the
# effect of removing ALL changesets, which we are not allowing for the
# time being for safety.
#
# Note that this should NOT include a `@` prefix, as required by bare
# sqitch.  The provider will add that, so you don't have to do it
# manually.  So, instead of passing `@1.2.3`, simply pass `1.2.3`.
#
# @todo It might be nice to validate that this is a recognized sqitch
#   tag, too.
attribute :to_target,
kind_of: String

# Perform additional validation after the resource is created.  This
# allows access to the new resource itself, which provides more robust
# validation than the attribute validation callback approach.
def after_created
  # Doing validation of to_target here, in order to have access to the action
  # (Here, `action` is an array.  We only support a single action, though)
  if action.include?(:revert) && to_target.nil?
    Chef::Log.error("The revert action requires a value for 'to_target' (not supporting the wholesale reversion of an entire schema)!")
    fail
  end

  # TODO: This may not be the case if using a config file
  if %w(pg oracle).include?(engine) && db_name.nil?
    Chef::Log.error("A value for `db_name` is required for engine `#{engine}`!")
    fail
  end
end
