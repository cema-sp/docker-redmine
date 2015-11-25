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

    module QueryPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          class << self
            VISIBILITY_PRIVATE = 0
            VISIBILITY_ROLES   = 1
            VISIBILITY_PUBLIC  = 2
          end

        end
      end
    end

    module InstanceMethods
      VISIBILITY_PRIVATE = 0
      VISIBILITY_ROLES   = 1
      VISIBILITY_PUBLIC  = 2

      def is_private?
        visibility == VISIBILITY_PRIVATE
      end

      def is_public?
        !is_private?
      end

      def visibility=(value)
        self.is_public = value == VISIBILITY_PUBLIC
      end

      def visibility
        self.is_public ? VISIBILITY_PUBLIC : VISIBILITY_PRIVATE
      end

    end

  end
end

unless Query.included_modules.include?(RedmineContacts::Patches::QueryPatch)
  Query.send(:include, RedmineContacts::Patches::QueryPatch)
end
