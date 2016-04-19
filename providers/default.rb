#
# Cookbook Name:: sqitch
# Provider:: default
#
# TODO: ensure we respect config files
# TODO: add an LWRP for config files?

# @resource sqitch

def whyrun_supported?
  true
end

use_inline_resources

# Deploy sqitch changesets
action :deploy do
  do_sqitch_action(:deploy, deploy_command)
end

# Roll back sqitch changesets
action :revert do
  do_sqitch_action(:revert, revert_command)
end

private

# Encapsulate the commonalities of executing the various LWRP actions.
# This is where the magic happens, people.
#
# @param action [:deploy, :revert]
# @param command [String] the complete CLI command to execute for the
#   given action
#
# @return [void]
def do_sqitch_action(action, command)
  include_sqitch

  converge_by(why_run_message_for(action)) do
    execute command do
      user new_resource.user if new_resource.user

      # DEPLOY:
      # If you deploy with --to-target and you're already at
      # the target, the return code is 0.  If you just deploy without
      # --to-target (i.e., deploy everything you've got) and there's
      # nothing new to deploy, the return code is 1.
      #
      # REVERT:
      # Similar to the deploy case, reverting to a tag when you are
      # beyond the tag will have a return code of 0.  Reverting to a
      # tag when you're already at that tag returns a 1
      returns [0, 1]
    end
  end
end

# Utility method for ensuring that sqitch is installed.  This allows
# the user to simply use the `sqitch` LWRP, without also having to
# remember to include the recipe manually.
#
# @return [void]
def include_sqitch
  recipe_eval do
    run_context.include_recipe 'sqitch::default'
  end
end

# Create a complete `sqitch deploy` command line invocation, with all
# applicable options set.
#
# @return [String]
def deploy_command
  cmd = make_base_command(:deploy)

  cmd = add_target(cmd)

  cmd << '--verify' # always verify when deploying!  Verification
  # failures can trigger a rollback of changes (on
  # postgres, anyway... transactional DDL FTW)

  # Currently not providing support for the following options:
  #
  # --mode
  # --set
  # --log-only

  cmd.join(' ')
end

# Create a complete `sqitch revert` command line invocation, with all
# applicable options set.
#
# @return [String]
def revert_command
  cmd = make_base_command(:revert)

  cmd = add_target(cmd)

  cmd << '-y' # Yes, we're sure we want to revert the changes; a Chef
  # run is not an interactive context, after all

  # Currently not providing support for the following options:
  #
  # --set
  # --log-only

  cmd.join(' ')
end

# Create the initial sqitch command string, with all available general
# options and including the sqitch command.  Individual action methods
# will need to then add action-specific options and arguments.
#
# The command is built up as an Array of Strings for ease of manipulation.
# Elements will need to be joined into a single String prior to use.
#
# All options are taken from the attributes set on the Resource; if a
# value is set, that option and value are added to the command Array.
#
# @note Assumes that the sqitch executable is available on $PATH.
#
# @param action [:deploy, :revert] The sqitch command to create a
#   command line invocation for
#
# @return [Array<String>]
def make_base_command(action)
  cmd = add_options(['sqitch'], # The beginning of our CLI command

                   # These are all the global options specified by the
                   # Resource (as their Ruby method names)

                   [ # general options
                     'engine',
                     'extension',
                     'plan_file',

                     # connection info
                     'db_client',
                     'db_name',
                     'db_user',
                     'db_host',
                     'db_port',

                     # directories
                     'top_dir',
                     'deploy_dir',
                     'revert_dir',
                     'verify_dir'])

  # Tack on the specific sqitch command to invoke
  cmd << action
end

# Add option flag / value pairs to a command array for each of
# `options` which are set on the Resource.
#
# @param cmd [Array<String>] The command so far
# @param options [Array<String>] The names of accessor methods on the
#   Resource for each option that could be added to the command
#
# @return [Array<String>] `cmd` with all non-nil options added
def add_options(cmd, options)
  options.inject(cmd) do |command, option|
    add_option(command, option)
  end
end

# Append to `cmd` the CLI flag and value corresponding to
# `method_name` if a value has been set
#
# @param cmd [Array<String>] The command so far
# @param method_name [String] The name of an accessor method on the
#   Resource
#
# @return [Array<String>] `cmd`, potentially with an additional flag /
#   value pair
#
# @note Assumes that the `method_name` corresponds directly with the
#   CLI flag for that option.  That is, the method name `top_dir`
#   corresponds to the CLI flag `--top-dir`.
def add_option(cmd, method_name)
  if (value = new_resource.send(method_name))
    flag_name = method_name.tr('_', '-')
    cmd << "--#{flag_name} #{value}"
  else
    cmd
  end
end

# Add a deploy / revert target tag (i.e., `--to-target`) to the CLI
# command.  This is handled specially (instead of using
# `#add_option`), in order to prepend a "@" to the tag (as required by
# sqitch).  As with other options, a target is only added if one was
# specified in the Resource.
#
# @param cmd [Array<String>] The command so far
#
# @return [Array<String>] `cmd`, potentially with a `--to-target`
#   option set.
#
# @todo We *could* also detect if the tag already has a "@" and Do The
#   Right Thing...
def add_target(cmd)
  value = new_resource.to_target
  cmd << "--to-target @#{value}" if value
  cmd
end

# Create an appropriate why-run message, depending on what action is
# executing.  This should be used in a `converge_by` block.
def why_run_message_for(action)
  case action
  when :revert
    # It doesn't look like sqitch has built-in support for showing
    # what changes it would revert without first reverting them.  For
    # now, we'll just say that we would revert, and leave it at that.

    # TODO: If we're already at the specified tag, say we wouldn't
    # revert anything, 'cuz we're already there
    "revert schema to tag #{new_resource.to_target}"
  when :deploy
    s = status
    if s.nothing_to_deploy?
      'deploy nothing, because everything is up-to-date'
    else
      ''"deploy the following changesets:

      #{s.changes_to_deploy.join("\n")}
      "''
    end
  else
    # Just a little safety net for the future...
    Chef::Log.error("Unrecognized action for sqitch resource: #{new_resource.action}!")
    raise
  end
end

# Return a new Sqitch::Status object that encapsulates the current
# status of the sqitch system.
def status
  # We're basically executing `sqitch status`, subject to the options
  # that have been set on the Resource.

  env = new_resource.user ? { user: new_resource.user } : {}

  sqitch_status = Mixlib::ShellOut.new(make_base_command('status').join(' '), env)
  sqitch_status.run_command
  Sqitch::Status.new(sqitch_status.stdout,
                     sqitch_status.stderr)
end

module Sqitch
  # Encapsulates the output of a `sqitch status` command invocation
  # and provides various introspection methods based on a parsing of
  # that output.
  class Status
    # Initialize with the standard output and standard error of an
    # invocation of `sqitch status`.  The command should have already
    # been run; this is just to figure out what the output says.
    #
    # @param stdout [String]
    # @param stderr [String]
    def initialize(stdout, stderr)
      @stdout = stdout
      @stderr = stderr
    end

    # Indicate if sqitch has not yet been used to manage a given
    # database (e.g., we haven't even loaded the schema yet).  In this
    # case, the sqitch metadata tables won't even be present yet, and
    # we'll get an error.  This is probably best thought of as a UX
    # bug in sqitch.
    #
    # @return [Boolean]
    def not_a_sqitch_db_yet?
      !(@stderr =~ /ERROR:  relation "changes" does not exist/).nil?
    end

    # Indicate whether there are any changesets to deploy to bring the
    # database to the desired state.
    #
    # @return [Boolean]
    def nothing_to_deploy?
      !(@stdout =~ /Nothing to deploy/).nil?
    end

    # Provide a list of all sqitch changesets that need to be deployed
    # in order to bring the database to the desired state.
    #
    # @return [Array<String>]
    def changes_to_deploy
      if not_a_sqitch_db_yet?
        # TODO: list all the changesets available up to a specified
        # tag.  Currently, this probably requires parsing the plan
        # file directly, since sqitch errors out if it's not yet
        # managing the database.  As such, this is going to require
        # reworking this class, since it requires more information
        # than is contained in the output of `sqitch status`
        #
        # So, this is an admittedly hacky workaround, but it probably
        # expresses the intent well enough.
        ['all the changesets!']
      elsif nothing_to_deploy?
        [] # <-- Yup, nothing!
      else
        # OK, so this is pretty hairy...
        #
        # Representative output looks like this:
        #
        # # On database bifrost_test
        # # Project:  bifrost
        # # Change:   842b0858d77d016dd08bcc4452af3c2152e4c1ca
        # # Name:     debug_object_acl_view
        # # Tag:      @1.1.6
        # # Deployed: 2013-06-26 09:50:30 -0400
        # # By:       Christopher Maier <cm@opscode.com>
        #
        # Undeployed changes:
        #   * actor_has_bulk_permission_on @1.2.0 @1.2.1 @1.2.2
        #   * update_acl
        #
        # NOTE: This output is from running just `sqitch status` with
        # NO ADDITIONAL options for the status command (global options
        # are OK).  If we change the specific `status` invocation,
        # this parsing logic may have to be changed to account for
        # extra / different information.

        # split all the lines
        lines = @stdout.split("\n")

        # Get rid of everything until the undeployed changes
        undeployed = lines.drop_while { |line| line !~ /Undeployed changes/ }

        # At this point, we have something like this:
        #
        # ["Undeployed changes:",
        #  "  * actor_has_bulk_permission_on @1.2.0 @1.2.1 @1.2.2",
        #  "  * update_acl"]

        # Drop the "Undeployed changes" line, and remove the leading
        # whitespace
        change_lines = undeployed.drop(1).map(&:strip)

        # Now we have something like this:
        #
        # ["* actor_has_bulk_permission_on @1.2.0 @1.2.1 @1.2.2",
        # "* update_acl"]

        # Now we can isolate just the changeset names
        change_lines.map do |line|
          # There are several rules[1] about what constitutes a legal
          # changeset name.  We can assume they've all been followed
          # though, since we're just parsing sqitch's output.  Thus,
          # for our purposes, we'll just say a changeset name is "the
          # first bunch of non-space characters"
          #
          # [1]: https://metacpan.org/module/sqitchchanges
          line =~ /^\* ([^ ]+).*$/
          Regexp.last_match(1)
        end
      end
    end
  end
end
