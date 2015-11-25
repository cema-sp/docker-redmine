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

class CrmQuery < Query

  def self.visible(*args)
    user = args.shift || User.current
    base = Project.allowed_to_condition(user, "view_#{queried_class.name.pluralize.downcase}".to_sym, *args)
    scope = includes(:project).where("#{table_name}.project_id IS NULL OR (#{base})")

    if user.admin?
      scope.where("#{table_name}.visibility <> ? OR #{table_name}.user_id = ?", VISIBILITY_PRIVATE, user.id)
    elsif user.memberships.any?
      scope.where("#{table_name}.visibility = ?" +
        " OR (#{table_name}.visibility = ? AND #{table_name}.id IN (" +
          "SELECT DISTINCT q.id FROM #{table_name} q" +
          " INNER JOIN #{table_name_prefix}queries_roles#{table_name_suffix} qr on qr.query_id = q.id" +
          " INNER JOIN #{MemberRole.table_name} mr ON mr.role_id = qr.role_id" +
          " INNER JOIN #{Member.table_name} m ON m.id = mr.member_id AND m.user_id = ?" +
          " WHERE q.project_id IS NULL OR q.project_id = m.project_id))" +
        " OR #{table_name}.user_id = ?",
        VISIBILITY_PUBLIC, VISIBILITY_ROLES, user.id, user.id)
    elsif user.logged?
      scope.where("#{table_name}.visibility = ? OR #{table_name}.user_id = ?", VISIBILITY_PUBLIC, user.id)
    else
      scope.where("#{table_name}.visibility = ?", VISIBILITY_PUBLIC)
    end
  end

  def visible?(user=User.current)
    return true if user.admin?
    return false unless project.nil? || user.allowed_to?("view_#{queried_class.name.pluralize.downcase}".to_sym, project)
    case visibility
    when VISIBILITY_PUBLIC
      true
    when VISIBILITY_ROLES
      if project
        (user.roles_for_project(project) & roles).any?
      else
        Member.where(:user_id => user.id).joins(:roles).where(:member_roles => {:role_id => roles.map(&:id)}).any?
      end
    else
      user == self.user
    end
  end

  def is_private?
    visibility == VISIBILITY_PRIVATE
  end

  def is_public?
    !is_private?
  end

  def initialize_project_filter(position=nil)
    if project.blank?
      project_values = []
      if User.current.logged? && User.current.memberships.any?
        project_values << ["<< #{l(:label_my_projects).downcase} >>", "mine"]
      end
      project_values += all_projects_values
      add_available_filter("project_id", :order => position,
        :type => :list, :values => project_values
      ) unless project_values.empty?
    end
  end

  def initialize_author_filter(position=nil)
    add_available_filter("author_id", :order => position,
      :type => :list_optional, :values => users_values
    ) unless users_values.empty?
  end

  def initialize_assignee_filter(position=nil)
    add_available_filter("assigned_to_id", :order => position,
      :type => :list_optional, :values => users_values
    ) unless users_values.empty?
  end

  def initialize_contact_country_filter(position=nil)
    contact_countries = l(:label_crm_countries).map{|k, v| [v, k]}
    add_available_filter("contact_country", :order => position,
      :type => :list_optional, :values => contact_countries, :label => :label_crm_contact_country
    ) unless contact_countries.empty?
  end

  def initialize_contact_city_filter(position=nil)
    add_available_filter("contact_city", :order => position,
      :type => :string, :label => :label_crm_contact_city
    )
  end

  def sql_for_contact_country_field(field, operator, value)
    if operator == '*' # Any group
      contact_countries = l(:label_crm_countries).map{|k, v| k.to_s}
      operator = '=' # Override the operator since we want to find by assigned_to
    elsif operator == "!*"
      contact_countries = l(:label_crm_countries).map{|k, v| k.to_s}
      operator = '!' # Override the operator since we want to find by assigned_to
    else
      contact_countries = value
    end
    '(' + sql_for_field("address_id", operator, contact_countries, Address.table_name, "country_code", false) + ')'
  end

  def sql_for_contact_city_field(field, operator, value)
     sql_for_field(field, operator, value, Address.table_name, "city")
  end

  def principals
    return @principals if @principals
    @principals = []
    if project
      @principals += project.principals.sort
      unless project.leaf?
        subprojects = project.descendants.visible.all
        @principals += Principal.member_of(subprojects)
      end
    else
      if all_projects.any?
        @principals += Principal.member_of(all_projects)
      end
    end
    @principals.uniq!
    @principals.sort!
  end

  def users_values
    return @users_values if @users_values
    users = principals.select {|p| p.is_a?(User)}
    @users_values = []
    @users_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
    @users_values += users.collect{|s| [s.name, s.id.to_s] }
    @users_values
  end

  def object_count
    objects_scope.count
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def object_count_by_group
    r = nil
    if grouped?
      begin
        # Rails3 will raise an (unexpected) RecordNotFound if there's only a nil group value
        r = objects_scope.
          joins(joins_for_order_statement(group_by_statement)).
          group(group_by_statement).count
      rescue ActiveRecord::RecordNotFound
        r = {nil => object_count}
      end
      c = group_by_column
      if c.is_a?(QueryCustomFieldColumn)
        r = r.keys.inject({}) {|h, k| h[c.custom_field.cast_value(k)] = r[k]; h}
      end
    end
    r
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def objects_scope(options={})
    raise NotImplementedError.new("You must implement #{name}.")
  end

  def results_scope(options={})
    order_option = [group_by_sort_order, options[:order]].flatten.reject(&:blank?)

    objects_scope(options).
      order(order_option).
      joins(joins_for_order_statement(order_option.join(','))).
      limit(options[:limit]).
      offset(options[:offset])
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

end
