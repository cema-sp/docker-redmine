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
  module CSVUtils
    include Redmine::I18n

    class << self

      def csv_custom_value(custom_value)
        return "" unless custom_value
        value = custom_value.value
        case custom_value.custom_field.field_format
        when 'date'
          begin; format_date(value.to_date); rescue; value end
        when 'bool'
          l(value == "1" ? :general_text_Yes : :general_text_No)
        when 'float'
          sprintf("%.2f", value).gsub('.', l(:general_csv_decimal_separator))
        else
          if value.is_a?(Array)
            value.map(&:to_s).join(', ')
          else
            value.to_s
          end
        end
      rescue
        return ""
      end

    end
  end
end
