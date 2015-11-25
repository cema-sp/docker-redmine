require_dependency 'setting'

module RedmineGitHosting
  module Patches
    module SettingPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          before_save  :save_git_hosting_values
          after_commit :restore_git_hosting_values
        end
      end

      module InstanceMethods

        private

        @@old_valuehash     = ((Setting.plugin_redmine_git_hosting).clone rescue {})
        @@resync_projects   = false
        @@resync_ssh_keys   = false
        @@flush_cache       = false
        @@delete_trash_repo = []


        def save_git_hosting_values
          # Only validate settings for our plugin
          if self.name == 'plugin_redmine_git_hosting'
            valuehash = self.value

            ## This a force update
            @@resync_projects = true if valuehash[:gitolite_resync_all_projects] == 'true'
            @@resync_ssh_keys = true if valuehash[:gitolite_resync_all_ssh_keys] == 'true'

            ## Flush Gitolite Cache
            @@flush_cache = true if valuehash[:gitolite_flush_cache] == 'true'

            ## Empty Recycle Bin
            @@delete_trash_repo = valuehash[:gitolite_purge_repos] if valuehash.has_key?(:gitolite_purge_repos) && !valuehash[:gitolite_purge_repos].empty?

            # Call ValidateSettings and save back results (this return a modified valuehash)
            self.value = ValidateSettings.new(@@old_valuehash, valuehash).call
          end
        end


        def restore_git_hosting_values
          # Only perform after-actions on settings for our plugin
          if self.name == 'plugin_redmine_git_hosting'
            valuehash = self.value

            # Settings cache doesn't seem to invalidate symbolic versions of Settings immediately,
            # so, any use of Setting.plugin_redmine_git_hosting[] by things called during this
            # callback will be outdated.... True for at least some versions of redmine plugin...
            #
            # John Kubiatowicz 12/21/2011
            # Clear out all cached settings.
            GitoliteAccessor.flush_settings_cache

            # Build options to pass to RestoreSettings object
            opts = {
              resync_projects:   @@resync_projects,
              resync_ssh_keys:   @@resync_ssh_keys,
              delete_trash_repo: @@delete_trash_repo,
              flush_cache:       @@flush_cache
            }

            # Call RestoreSettings
            ApplySettings.new(@@old_valuehash, valuehash, opts).call

            # Restore default class settings
            @@resync_projects   = false
            @@resync_ssh_keys   = false
            @@flush_cache       = false
            @@delete_trash_repo = []

            @@old_valuehash = valuehash.clone
          end
        end

      end

    end
  end
end

unless Setting.included_modules.include?(RedmineGitHosting::Patches::SettingPatch)
  Setting.send(:include, RedmineGitHosting::Patches::SettingPatch)
end
