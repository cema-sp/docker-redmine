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

require 'redmine_contacts/helpers/money_helper'
require 'redmine_contacts/helpers/contacts_helper'
require 'redmine_contacts/helpers/crm_calendar_helper'

# Plugins
require 'acts_as_viewable/init'
require 'acts_as_priceable/init'
require 'acts_as_taggable_on_patch'

require_dependency 'redmine_contacts/utils/thumbnail'
require_dependency 'redmine_contacts/utils/check_mail'
require_dependency 'redmine_contacts/utils/date_utils'
require_dependency 'redmine_contacts/utils/csv_utils'
require_dependency 'redmine_contacts/contacts_project_setting'

# Patches
require_dependency 'redmine_contacts/patches/compatibility_patch'
require_dependency 'redmine_contacts/patches/issue_patch'
require_dependency 'redmine_contacts/patches/project_patch'
require_dependency 'redmine_contacts/patches/mailer_patch'
require_dependency 'redmine_contacts/patches/notifiable_patch'
require_dependency 'redmine_contacts/patches/application_controller_patch'
require_dependency 'redmine_contacts/patches/attachments_controller_patch'
require_dependency 'redmine_contacts/patches/auto_completes_controller_patch'
require_dependency 'redmine_contacts/patches/issue_query_patch'
require_dependency 'redmine_contacts/patches/queries_helper_patch'
require_dependency 'redmine_contacts/patches/timelog_helper_patch'
require_dependency 'redmine_contacts/patches/projects_helper_patch'

require_dependency 'redmine_contacts/wiki_macros/contacts_wiki_macros'

# Hooks
require_dependency 'redmine_contacts/hooks/views_projects_hook'
require_dependency 'redmine_contacts/hooks/views_issues_hook'
require_dependency 'redmine_contacts/hooks/views_layouts_hook'

require 'redmine_contacts/liquid/liquid' if Object.const_defined?("Liquid") rescue false



module RedmineContacts

  def self.companies_select
  	RedmineContacts.settings["select_companies_to_deal"]
  end

  def self.settings() Setting[:plugin_redmine_contacts].blank? ? {} : Setting[:plugin_redmine_contacts]  end

  def self.default_list_style
    return 'list_excerpt'
  end

end
