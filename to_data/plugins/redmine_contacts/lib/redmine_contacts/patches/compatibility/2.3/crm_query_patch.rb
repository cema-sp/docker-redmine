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

module RedmineContacts
  module Patches

    module CrmQueryPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          def self.visible(*args)
            user = args.shift || User.current
            base = Project.allowed_to_condition(user, "view_#{queried_class.name.pluralize.downcase}".to_sym, *args)
            user_id = user.logged? ? user.id : 0

            includes(:project).where("(#{table_name}.project_id IS NULL OR (#{base})) AND (#{table_name}.is_public = ? OR #{table_name}.user_id = ?)", true, user_id)
          end

        end
      end
    end


    module InstanceMethods
      def visible?(user=User.current)
        (project.nil? || user.allowed_to?("view_#{queried_class.name.pluralize.downcase}".to_sym, project)) && (self.is_public? || self.user_id == user.id)
      end

    end

  end
end

unless CrmQuery.included_modules.include?(RedmineContacts::Patches::CrmQueryPatch)
  CrmQuery.send(:include, RedmineContacts::Patches::CrmQueryPatch)
end
