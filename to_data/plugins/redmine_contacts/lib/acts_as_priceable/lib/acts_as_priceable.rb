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
  module Acts
    module Priceable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_priceable(*args)
          priceable_options = args
          priceable_options << :price if priceable_options.empty?
          priceable_methods = ""
          priceable_options.each do |priceable_attr|
            priceable_methods << %(
              def #{priceable_attr.to_s}_to_s
                object_price(self, :#{priceable_attr}) if self.respond_to?(:#{priceable_attr})
              end
            )
          end

          class_eval <<-EOV
            include RedmineContacts::MoneyHelper
            include RedmineContacts::Acts::Priceable::InstanceMethods

            #{priceable_methods}
          EOV

        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end

      end

    end
  end
end
