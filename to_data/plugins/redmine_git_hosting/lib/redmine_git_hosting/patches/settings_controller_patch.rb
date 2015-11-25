require_dependency 'settings_controller'

module RedmineGitHosting
  module Patches
    module SettingsControllerPatch

      def self.included(base)
        base.class_eval do
          unloadable

          helper :bootstrap_switch
          helper :tag_it
          helper :gitolite_plugin_settings
        end
      end

    end
  end
end

unless SettingsController.included_modules.include?(RedmineGitHosting::Patches::SettingsControllerPatch)
  SettingsController.send(:include, RedmineGitHosting::Patches::SettingsControllerPatch)
end
