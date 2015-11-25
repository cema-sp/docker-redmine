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
  module DateUtils
    class << self
      def retrieve_date_range(period)
        from, to = nil, nil
        case period
        when 'today'
          from = to = Date.today
        when 'yesterday'
          from = to = Date.today - 1
        when 'current_week'
          from = Date.today - (Date.today.cwday - 1)%7
          to = from + 6
        when 'last_week'
          from = Date.today - 7 - (Date.today.cwday - 1)%7
          to = from + 6
        when 'last_2_weeks'
          from = Date.today - 14 - (Date.today.cwday - 1)%7
          to = from + 13
        when '7_days'
          from = Date.today - 7
          to = Date.today
        when 'last_7_days'
          from = Date.today - 14
          to = from + 7
        when 'current_month'
          from = Date.civil(Date.today.year, Date.today.month, 1)
          to = (from >> 1) - 1
        when 'last_month'
          from = Date.civil(Date.today.year, Date.today.month, 1) << 1
          to = (from >> 1) - 1
        when '30_days'
          from = Date.today - 30
          to = Date.today
        when 'current_year'
          from = Date.civil(Date.today.year, 1, 1)
          to = Date.civil(Date.today.year, 12, 31)
        when 'last_year'
          from = Date.civil(1.year.ago.year, 1, 1)
          to = Date.civil(1.year.ago.year, 12, 31)
        end

        from, to = from, to + 1 if (from && to)
        [from, to]
      end
    end
  end
end
