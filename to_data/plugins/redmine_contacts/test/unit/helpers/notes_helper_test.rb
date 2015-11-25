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

require File.expand_path('../../../test_helper', __FILE__)

class NotesHelperTest < ActionView::TestCase
  include ApplicationHelper
  include NotesHelper
  include Redmine::I18n
  include ERB::Util

  fixtures :projects, :trackers, :issue_statuses, :issues,
           :enumerations, :users, :issue_categories,
           :versions,
           :projects_trackers,
           :member_roles,
           :members,
           :groups_users,
           :enabled_modules

  ActiveRecord::Fixtures.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/',
                          [:contacts,
                           :contacts_projects,
                           :contacts_issues,
                           :deals,
                           :notes,
                           :tags,
                           :taggings,
                           :queries])
  def setup
    super
    set_language_if_valid('en')
    User.current = nil
  end

  def test_authoring_note_without_time
    RedmineContacts.settings[:note_authoring_time] = false
    assert_nothing_raised { authoring_note('2012-12-12 10:00'.to_time, User.find(1))}
  end

  def test_authoring_note_with_time
    RedmineContacts.settings[:note_authoring_time] = true
    assert_nothing_raised { authoring_note('2012-12-12 10:00'.to_time, User.find(1)) }
  end

  def test_authoring_note_without_time_with_empty_time
    RedmineContacts.settings[:note_authoring_time] = true
    assert_nothing_raised { authoring_note(nil, User.find(1))}
  end

  def test_authoring_note_without_time_with_empty_time
    RedmineContacts.settings[:note_authoring_time] = false
    assert_nothing_raised { authoring_note(nil, User.find(1))}
  end

  def test_authoring_note_without_time_with_empty_user
    RedmineContacts.settings[:note_authoring_time] = true
    assert_nothing_raised { authoring_note('2012-12-12 10:00'.to_time, nil) }
  end

end
