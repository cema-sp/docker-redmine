# encoding: utf-8
#
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
  module Helpers

    class CrmCalendar
      include Redmine::I18n
      attr_reader :startdt, :enddt

      def initialize(date, options = {})
        @date = date
        @events = []
        @ending_events_by_days = {}
        @starting_events_by_days = {}
        @start_date_field = options[:start_date_field] || "start_date"
        @due_date_field = options[:due_date_field] || "due_date"
        set_language_if_valid options[:language] || current_language
        period = options[:period] || :month
        case period
        when :month
          @startdt = Date.civil(date.year, date.month, 1)
          @enddt = (@startdt >> 1)-1
          # starts from the first day of the week
          @startdt = @startdt - (@startdt.cwday - first_wday)%7
          # ends on the last day of the week
          @enddt = @enddt + (last_wday - @enddt.cwday)%7
        when :week
          @startdt = date - (date.cwday - first_wday)%7
          @enddt = date + (last_wday - date.cwday)%7
        else
          raise 'Invalid period'
        end
      end

      # Sets calendar events
      def events=(events)
        @events = events
        @ending_events_by_days = @events.group_by {|event| event.send(@start_date_field).to_date if event.send(@start_date_field)}
        @starting_events_by_days = @events.group_by {|event| event.send(@due_date_field).to_date if event.send(@due_date_field)}
      end

      # Returns events for the given day
      def events_on(day)
        ((@ending_events_by_days[day] || []) + (@starting_events_by_days[day] || [])).uniq
      end

      # Calendar current month
      def month
        @date.month
      end

      # Return the first day of week
      # 1 = Monday ... 7 = Sunday
      def first_wday
        case Setting.start_of_week.to_i
        when 1
          @first_dow ||= (1 - 1)%7 + 1
        when 6
          @first_dow ||= (6 - 1)%7 + 1
        when 7
          @first_dow ||= (7 - 1)%7 + 1
        else
          @first_dow ||= (l(:general_first_day_of_week).to_i - 1)%7 + 1
        end
      end

      def last_wday
        @last_dow ||= (first_wday + 5)%7 + 1
      end
    end
  end
end
