class ChangeUsUserPreferences < ActiveRecord::Migration

  def down
    if !Redmine::Plugin.installed?(:a_common_libs) && UserPreference.respond_to?(:favourite_project_id)
      remove_column :user_preferences, :favourite_project_id
    end
  end

end