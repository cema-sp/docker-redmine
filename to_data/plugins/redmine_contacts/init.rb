# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2015 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

require 'redmine'

CONTACTS_VERSION_NUMBER = '3.4.5'
CONTACTS_VERSION_TYPE = "Light version"

Redmine::Plugin.register :redmine_contacts do
  name "Redmine CRM plugin (#{CONTACTS_VERSION_TYPE})"
  author 'RedmineCRM'
  description 'This is a CRM plugin for Redmine that can be used to track contacts and deals information'
  version CONTACTS_VERSION_NUMBER
  url 'http://redminecrm.com'
  author_url 'mailto:support@redminecrm.com'

  requires_redmine :version_or_higher => '2.3'

  settings :default => {
    :name_format => :lastname_firstname.to_s,
    :auto_thumbnails  => true,
    :major_currencies => "USD, EUR, GBP, RUB, CHF",
    :contact_list_default_columns => ["first_name", "last_name"],
    :max_thumbnail_file_size => 300
  }, :partial => 'settings/contacts/contacts'

  project_module :contacts do
    permission :view_contacts, {
      :contacts => [:show, :index, :live_search, :contacts_notes, :context_menu],
      :notes => [:show]
    }
    permission :view_private_contacts, {
      :contacts => [:show, :index, :live_search, :contacts_notes, :context_menu],
      :notes => [:show]
    }

    permission :add_contacts, {
      :contacts => [:new, :create],
      :contacts_duplicates => [:index, :duplicates],
      :contacts_vcf => [:load]
    }

    permission :edit_contacts, {
      :contacts => [:edit, :update, :bulk_update, :bulk_edit],
      :notes => [:create, :destroy, :edit, :update],
      :contacts_duplicates => [:index, :merge, :duplicates],
      :contacts_projects => [:new, :destroy, :create],
      :contacts_vcf => [:load]
    }

    permission :manage_contact_issue_relations, {
      :contacts_issues => [:new, :create_issue, :create, :delete, :close, :autocomplete_for_contact],
    }

    permission :delete_contacts, :contacts => [:destroy, :bulk_destroy]
    permission :add_notes, :notes => [:create]
    permission :delete_notes, :notes => [:destroy, :edit, :update]
    permission :delete_own_notes, :notes => [:destroy, :edit, :update]

    permission :manage_contacts, {
      :projects => :settings,
      :contacts_settings => :save,
    }

  end

  menu :project_menu, :contacts, {:controller => 'contacts', :action => 'index'}, :caption => :contacts_title, :param => :project_id
  menu :top_menu, :contacts,
                          {:controller => 'contacts', :action => 'index', :project_id => nil},
                          :caption => :label_contact_plural,
                          :if => Proc.new{ User.current.allowed_to?({:controller => 'contacts', :action => 'index'},
                                          nil, {:global => true})  && ContactsSetting.contacts_show_in_top_menu? }

  menu :application_menu, :contacts,
                          {:controller => 'contacts', :action => 'index'},
                          :caption => :label_contact_plural,
                          :if => Proc.new{ User.current.allowed_to?({:controller => 'contacts', :action => 'index'},
                                          nil, {:global => true})  && ContactsSetting.contacts_show_in_app_menu? }

  menu :admin_menu, :contacts, {:controller => 'settings', :action => 'plugin', :id => "redmine_contacts"}, :caption => :contacts_title

  activity_provider :contacts, :default => false, :class_name => ['ContactNote', 'Contact']

  Redmine::Search.map do |search|
    search.register :contacts
  end

end

ActionDispatch::Callbacks.to_prepare do
  require 'redmine_contacts'
end
