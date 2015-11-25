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

class ContactQuery < CrmQuery

  self.queried_class = Contact

  self.available_columns = [
    QueryColumn.new(:name, :sortable => lambda {Contact.fields_for_order_statement}, :caption => :field_contact_full_name),
    QueryColumn.new(:first_name, :sortable => "#{Contact.table_name}.first_name"),
    QueryColumn.new(:last_name, :sortable => "#{Contact.table_name}.last_name"),
    QueryColumn.new(:middle_name, :sortable => "#{Contact.table_name}.middle_name", :caption => :field_contact_middle_name),
    QueryColumn.new(:job_title, :sortable => "#{Contact.table_name}.job_title", :caption => :field_contact_job_title, :groupable => true),
    QueryColumn.new(:company, :sortable => "#{Contact.table_name}.company", :groupable => "#{Contact.table_name}.company", :caption => :field_contact_company, :groupable => true),
    QueryColumn.new(:phones, :sortable => "#{Contact.table_name}.phone", :caption => :field_contact_phone),
    QueryColumn.new(:emails, :sortable => "#{Contact.table_name}.email", :caption => :field_contact_email),
    QueryColumn.new(:address, :sortable => "#{Address.table_name}.full_address", :caption => :label_crm_address),
    QueryColumn.new(:street1, :sortable => "#{Address.table_name}.street1", :caption => :label_crm_street1),
    QueryColumn.new(:street2, :sortable => "#{Address.table_name}.street2", :caption => :label_crm_street2),
    QueryColumn.new(:city, :sortable => "#{Address.table_name}.city", :groupable => "#{Address.table_name}.city", :caption => :label_crm_city),
    QueryColumn.new(:region, :sortable => "#{Address.table_name}.region", :caption => :label_crm_region),
    QueryColumn.new(:postcode, :sortable => "#{Address.table_name}.postcode", :caption => :label_crm_postcode),
    QueryColumn.new(:country, :sortable => "#{Address.table_name}.country_code", :groupable => "#{Address.table_name}.country_code", :caption => :label_crm_country),
    QueryColumn.new(:tags),
    QueryColumn.new(:created_on, :sortable => "#{Contact.table_name}.created_on"),
    QueryColumn.new(:updated_on, :sortable => "#{Contact.table_name}.updated_on"),
    QueryColumn.new(:assigned_to, :sortable => lambda {User.fields_for_order_statement}, :groupable => true),
    QueryColumn.new(:author, :sortable => lambda {User.fields_for_order_statement("authors")})
  ]


  def initialize(attributes=nil, *args)
    super attributes
    self.filters = {}
  end

  def initialize_available_filters
    add_available_filter "tags", :type => :list, :values => Contact.available_tags(project.blank? ? {} : {:project => project.id}).collect{ |t| [t.name, t.name] }, :order => 12
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = self.class.available_columns.dup
    @available_columns
  end

  def default_columns_names
    @default_columns_names ||= [:name, :job_title, :company, :phone, :email, :address]
  end

  def sql_for_tags_field(field, operator, value)
    compare   = operator_for('tags').eql?('=') ? 'IN' : 'NOT IN'
    ids_list  = Contact.tagged_with(value).collect{|contact| contact.id }.push(0).join(',')
    "( #{Contact.table_name}.id #{compare} (#{ids_list}) ) "
  end

  def objects_scope(options={})
    scope = Contact.visible
    options[:search].split(' ').collect{ |search_string| scope = scope.live_search(search_string) } unless options[:search].blank?
    scope = scope.includes((query_includes + (options[:include] || [])).uniq).
      where(statement).
      where(options[:conditions])
    scope
  end

  def query_includes
    includes = [:address, :projects]
    includes << :assigned_to if self.filters["assigned_to_id"] || (group_by_column && [:assigned_to].include?(group_by_column.name))
    includes
  end

end
