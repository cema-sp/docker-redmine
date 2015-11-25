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

class Contact < ActiveRecord::Base
  unloadable
  include Redmine::SafeAttributes

  CONTACT_FORMATS = {
    :firstname_lastname => {
        :string => '#{first_name} #{last_name}',
        :order => %w(first_name middle_name last_name id),
        :setting_order => 1
      },
    :lastname_firstname_middlename => {
        :string => '#{last_name} #{first_name} #{middle_name}',
        :order => %w(last_name first_name middle_name id),
        :setting_order => 1
     },
    :firstname_middlename_lastname => {
        :string => '#{first_name} #{middle_name} #{last_name}',
        :order => %w(first_name middle_name last_name id),
        :setting_order => 1
    },
    :firstname_lastinitial => {
        :string => '#{first_name} #{middle_name.to_s.chars.first + \'.\' unless middle_name.blank?} #{last_name.to_s.chars.first + \'.\' unless last_name.blank?}',
        :order => %w(first_name middle_name last_name id),
        :setting_order => 2
      },
    :firstinitial_lastname => {
        :string => '#{first_name.to_s.gsub(/(([[:alpha:]])[[:alpha:]]*\.?)/, \'\2.\')} #{middle_name.to_s.chars.first + \'.\' unless middle_name.blank?} #{last_name}',
        :order => %w(first_name middle_name last_name id),
        :setting_order => 2
      },
    :lastname_firstinitial => {
        :string => '#{last_name} #{first_name.to_s.gsub(/(([[:alpha:]])[[:alpha:]]*\.?)/, \'\2.\')} #{middle_name.to_s.chars.first + \'.\' unless middle_name.blank?}',
        :order => %w(last_name first_name middle_name id),
        :setting_order => 2
      },
    :firstname => {
        :string => '#{first_name}',
        :order => %w(first_name middle_name id),
        :setting_order => 3
      },
    :lastname_firstname => {
        :string => '#{last_name} #{first_name}',
        :order => %w(last_name first_name middle_name id),
        :setting_order => 4
      },
    :lastname_coma_firstname => {
        :string => '#{last_name.to_s + \',\' unless last_name.blank?} #{first_name}',
        :order => %w(last_name first_name middle_name id),
        :setting_order => 5
      },
    :lastname => {
        :string => '#{last_name}',
        :order => %w(last_name id),
        :setting_order => 6
      }
  }

  VISIBILITY_PROJECT = 0
  VISIBILITY_PUBLIC = 1
  VISIBILITY_PRIVATE = 2

  delegate :street1, :city, :country, :postcode, :region, :post_address, :to => :address, :allow_nil => true

  has_many :notes, :as => :source, :class_name => 'ContactNote', :dependent => :delete_all
  has_many :addresses, :dependent => :destroy, :as => :addressable, :class_name => "Address"
  belongs_to :assigned_to, :class_name => 'User', :foreign_key => 'assigned_to_id'
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  has_and_belongs_to_many :projects, :uniq => true
  has_and_belongs_to_many :issues, :order => "#{Issue.table_name}.due_date", :uniq => true
  has_one :avatar, :conditions => "#{Attachment.table_name}.description = 'avatar'", :class_name => "Attachment", :as  => :container, :dependent => :destroy
  has_one :address, :conditions => {:address_type => "business"}, :dependent => :destroy, :as => :addressable, :class_name => "Address"

  attr_accessor :phones
  attr_accessor :emails
  acts_as_viewable
  acts_as_taggable
  acts_as_watchable
  acts_as_attachable :view_permission => :view_contacts,
                     :delete_permission => :edit_contacts


  acts_as_event :datetime => :created_on,
                :url => lambda {|o| {:controller => 'contacts', :action => 'show', :id => o}},
                :type => 'icon-contact',
                :title => lambda {|o| o.name },
                :description => lambda {|o| [o.info, o.company, o.email, o.address, o.background].join(' ') }

  acts_as_activity_provider :type => 'contacts',
                            :permission => :view_contacts,
                            :author_key => :author_id,
                            :find_options => {:include => :projects}

  acts_as_searchable :columns => ["#{table_name}.first_name",
                                  "#{table_name}.middle_name",
                                  "#{table_name}.last_name",
                                  "#{table_name}.company",
                                  "#{table_name}.email",
                                  "#{Address.table_name}.full_address",
                                  "#{table_name}.background",
                                  "#{ContactNote.table_name}.content"],
                     :project_key => "#{Project.table_name}.id",
                     :include => [:projects, :address, :notes],
                     # sort by id so that limited eager loading doesn't break with postgresql
                     :order_column => "#{table_name}.id"

  accepts_nested_attributes_for :address, :allow_destroy => true, :update_only => true, :reject_if => proc {|attributes| Address.reject_address(attributes)}

  scope :visible, lambda {|*args| includes(:projects).where(Contact.visible_condition(args.shift || User.current, *args)) }
  scope :deletable, lambda {|*args| includes(:projects).where(Contact.deletable_condition(args.shift || User.current, *args)) }
  scope :editable, lambda {|*args| includes(:projects).where(Contact.editable_condition(args.shift || User.current, *args)) }
  scope :by_project, lambda {|prj| joins(:projects).where("#{Project.table_name}.id = ?", prj) unless prj.blank? }
  scope :like_by, lambda {|field, search| {:conditions => ["LOWER(#{Contact.table_name}.#{field}) LIKE ?", search.downcase + "%"] }}
  scope :companies, lambda { where(:is_company => true) }
  scope :people, lambda { where(:is_company => false) }
  scope :order_by_name, lambda { order(Contact.fields_for_order_statement) }
  scope :order_by_creation, lambda { order("#{Contact.table_name}.created_on DESC") }

  scope :by_name, lambda {|search| where("(LOWER(#{Contact.table_name}.first_name) LIKE LOWER(:p) OR
                                                                  LOWER(#{Contact.table_name}.last_name) LIKE LOWER(:p) OR
                                                                  LOWER(#{Contact.table_name}.middle_name) LIKE LOWER(:p))",
                                                                  {:p => "%" + search.downcase + "%"})}

  scope :live_search, lambda {|search| where("(LOWER(#{Contact.table_name}.first_name) LIKE LOWER(:p) OR
                                               LOWER(#{Contact.table_name}.last_name) LIKE LOWER(:p) OR
                                               LOWER(#{Contact.table_name}.middle_name) LIKE LOWER(:p) OR
                                               LOWER(#{Contact.table_name}.company) LIKE LOWER(:p) OR
                                               LOWER(#{Contact.table_name}.email) LIKE LOWER(:p) OR
                                               LOWER(#{Contact.table_name}.phone) LIKE LOWER(:p) OR
                                               LOWER(#{Contact.table_name}.job_title) LIKE LOWER(:p))",
                                             {:p => "%" + search.downcase + "%"})}



  validates_presence_of :first_name, :project
  # validates_uniqueness_of :first_name, :scope => [:last_name, :company, :email]

  after_create :send_notification

  safe_attributes 'is_company',
    'first_name',
    'last_name',
    'middle_name',
    'company',
    'website',
    'skype_name',
    'birthday',
    'job_title',
    'background',
    'author_id',
    'assigned_to_id',
    'phone',
    'email',
    'tag_list',
    'visibility',
    'watcher_user_ids',
    'address_attributes'


  def self.visible_condition(user, options={})
    user.reload
    user_ids = [user.id] + user.groups.map(&:id)

    projects_allowed_to_view_contacts = Project.where(Project.allowed_to_condition(user, :view_contacts)).pluck(:id)
    allowed_to_view_condition = projects_allowed_to_view_contacts.empty? ? "(1=0)" : "#{Project.table_name}.id IN (#{projects_allowed_to_view_contacts.join(',')})"
    projects_allowed_to_view_private = Project.where(Project.allowed_to_condition(user, :view_private_contacts)).pluck(:id)
    allowed_to_view_private_condition = projects_allowed_to_view_private.empty? ? "(1=0)" : "#{Project.table_name}.id IN (#{projects_allowed_to_view_private.join(',')})"

    cond = "(#{Project.table_name}.id <> -1 ) AND ("
    if user.admin?
      cond << "(#{table_name}.visibility = 1) OR (#{allowed_to_view_condition}) "
    else
      cond << " (#{table_name}.visibility = 1) OR" if user.allowed_to_globally?(:view_contacts, {})
      cond << " (#{allowed_to_view_condition} AND #{table_name}.visibility <> 2) "

      if user.logged?
        cond << " OR (#{allowed_to_view_private_condition} " +
                " OR (#{allowed_to_view_condition} " +
                " AND (#{table_name}.author_id = #{user.id} OR #{table_name}.assigned_to_id IN (#{user_ids.join(',')}) )))"
      end
    end

    cond << ")"

  end

  def self.editable_condition(user, options={})
    self.visible_condition(user, options) + " AND (#{Project.allowed_to_condition(user, :edit_contacts)})"
  end

  def self.deletable_condition(user, options={})
    self.visible_condition(user, options) + " AND (#{Project.allowed_to_condition(user, :delete_contacts)})"
  end

  def self.available_tags(options = {})
    limit = options[:limit]

    scope = ActsAsTaggableOn::Tag.scoped({})
    scope = scope.scoped(:conditions => ["#{Project.table_name}.id = ?", options[:project]]) if options[:project]
    scope = scope.scoped(:conditions => [Contact.visible_condition(options[:user] || User.current)])
    scope = scope.scoped(:conditions => ["LOWER(#{ActsAsTaggableOn::Tag.table_name}.name) LIKE ?", "%#{options[:name_like].downcase}%"]) if options[:name_like]

    joins = []
    joins << "JOIN #{ActsAsTaggableOn::Tagging.table_name} ON #{ActsAsTaggableOn::Tagging.table_name}.tag_id = #{ActsAsTaggableOn::Tag.table_name}.id "
    joins << "JOIN #{Contact.table_name} ON #{Contact.table_name}.id = #{ActsAsTaggableOn::Tagging.table_name}.taggable_id AND #{ActsAsTaggableOn::Tagging.table_name}.taggable_type =  '#{Contact.name}' "
    joins << Contact.projects_joins

    scope = scope.select("#{ActsAsTaggableOn::Tag.table_name}.*, COUNT(DISTINCT #{ActsAsTaggableOn::Tagging.table_name}.taggable_id) AS count")
    scope = scope.joins(joins.flatten)
    scope = scope.group("#{ActsAsTaggableOn::Tag.table_name}.id, #{ActsAsTaggableOn::Tag.table_name}.name HAVING COUNT(*) > 0")
    scope = scope.limit(limit) if limit
    scope = scope.order("#{ActsAsTaggableOn::Tag.table_name}.name")
    scope
  end

  def duplicates(limit=10)
    scope = Contact.scoped({})
    scope = scope.like_by("first_name",  self.first_name.strip) if !self.first_name.blank?
    scope = scope.like_by("middle_name",  self.middle_name.strip) if !self.middle_name.blank?
    scope = scope.like_by("last_name",  self.last_name.strip) if !self.last_name.blank?
    scope = scope.scoped(:conditions => ["#{Contact.table_name}.id <> ?", self.id]) if !self.new_record?
    @duplicates ||= (self.first_name.blank? && self.last_name.blank? && self.middle_name.blank?) ? [] : scope.visible.limit(limit)
  end

  def company_contacts
    @contacts ||= Contact.order_by_name.includes(:avatar).where(["#{Contact.table_name}.is_company = ?  AND #{Contact.table_name}.company = ? AND #{Contact.table_name}.id <> ?", false, self.first_name, self.id])
  end
  alias_method :employees, :company_contacts

  def redmine_user
    @redmine_user ||= User.where(:mail => emails).first unless self.email.blank?
  end

  def contact_company
    @contact_company ||= Contact.where(:first_name => self.company, :is_company => true).
      where("#{Contact.table_name}.id <> #{self.id}").first unless self.company.blank?
  end

  def notes_attachments
    @contact_attachments ||= Attachment.where({ :container_type => "Note", :container_id => self.notes.map(&:id)}).order(:created_on)
  end

  # usr for mailer
  def visible?(usr=nil)
    usr ||= User.current
    if self.is_public?
      usr.allowed_to_globally?(:view_contacts, {})
    else
      self.allowed_to?(usr || User.current, :view_contacts)
    end
  end

  def editable?(usr=nil)
    self.allowed_to?(usr || User.current, :edit_contacts)
  end

  def deletable?(usr=nil)
    self.allowed_to?(usr || User.current, :delete_contacts)
  end

  def allowed_to?(user, action, options={})
    if self.is_private?
      (self.projects.map{|p| user.allowed_to?(action, p)}.compact.any? && (self.author == user || user.is_or_belongs_to?(assigned_to))) ||
        (self.projects.map{|p| user.allowed_to?(:view_private_contacts, p)}.compact.any? && self.projects.map{|p| user.allowed_to?(action, p)}.compact.any?)
    else
      self.projects.map{|p| user.allowed_to?(action, p)}.compact.any?
    end
  end

  def is_public?
    self.visibility == VISIBILITY_PUBLIC
  end

  def is_private?
    self.visibility == VISIBILITY_PRIVATE
  end


  def send_mail_allowed?(usr=nil)
    usr ||= User.current
    @send_mail_allowed ||= 0 < self.projects.visible(usr).count(:conditions => Project.allowed_to_condition(usr, :send_contacts_mail))
  end

  def self.projects_joins
    joins = []
    joins << ["JOIN contacts_projects ON contacts_projects.contact_id = #{self.table_name}.id"]
    joins << ["JOIN #{Project.table_name} ON contacts_projects.project_id = #{Project.table_name}.id"]
  end

  def project(current_project=nil)
    return @project if @project
    if current_project && self.projects.visible.include?(current_project)
      @project  = current_project
    else
      @project  = self.projects.visible.find(:first, :conditions => Project.allowed_to_condition(User.current, :view_contacts))
    end

    @project ||= self.projects.first
  end

  def project=(project)
    self.projects << project
  end

  def self.find_by_emails(emails)
    contact = nil
    cond = "(1 = 0)"
    emails = emails.map{|e| e.downcase }
    emails.each do |mail|
      cond << " OR (LOWER(#{Contact.table_name}.email) LIKE LOWER('%#{mail.gsub("'", "").gsub("\"", "")}%'))"
    end
    contacts = Contact.where(cond)
    contacts.select{|c| (c.emails.map{|e| e.downcase } & emails).any? }
  end

  def self.name_formatter(formatter = nil)
    CONTACT_FORMATS[formatter || ContactsSetting.contact_name_format.to_sym]
  end

  # Returns an array of fields names than can be used to make an order statement for users
  # according to how user names are displayed
  # Examples:
  #
  #   Contact.fields_for_order_statement              => ['contacts.first_name', 'contacts.first_name', 'contacts.id']
  #   Contact.fields_for_order_statement('customers')   => ['customers.last_name', 'customers.id']
  def self.fields_for_order_statement(table=nil)
    table ||= table_name
    name_formatter[:order].map {|field| "#{table}.#{field}"}
  end

  # Return contacts's full name for display
  def name(formatter = nil)
    unless self.is_company?
      f = self.class.name_formatter(formatter)
      if formatter
        eval('"' + f[:string] + '"')
      else
        @name ||= eval('"' + f[:string] + '"')
      end
    else
      self.first_name
    end
  end

  def info
    self.job_title
  end

  def phones
    @phones || self.phone ? self.phone.split( /, */) : []
  end

  def emails
    @emails || self.email ? self.email.split( /, */).map{|m| m.strip} : []
  end

  def primary_email
    self.emails.first
  end

  def age
    return nil if birthday.blank?
    now = Time.now
  # how many years?
  # has their birthday occured this year yet?
  # subtract 1 if so, 0 if not
    age = now.year - birthday.year - (birthday.to_time.change(:year => now.year) > now ? 1 : 0)
  end

  def website_address
    self.website.match("^https?://") ? self.website : self.website.gsub(/^/, "http://") unless self.website.blank?
  end

  def to_s
    self.name
  end

  def notified_users
    notified = []
    # Author and assignee are always notified unless they have been
    # locked or don't want to be notified
    notified << author if author
    if assigned_to
      notified += (assigned_to.is_a?(Group) ? assigned_to.users : [assigned_to])
    end

    notified += project.notified_users

    if !is_company && !contact_company.blank?
      notified += contact_company.notified_users
    end

    notified = notified.select {|u| u.active? }
    notified.uniq!
    # Remove users that can not view the issue
    notified.reject! {|user| !visible?(user)}
    notified
  end

  # Returns the mail adresses of users that should be notified
  def recipients
    notified_users.collect(&:mail)
  end

  def all_watcher_recepients
    notified = self.watcher_recipients
    if !is_company && !contact_company.blank?
      notified += contact_company.watcher_recipients
    end
    notified
  end

  private

  def assign_phone
    if @phones
      self.phone = @phones.uniq.map {|s| s.strip.delete(',').squeeze(" ")}.join(', ')
    end
  end

  def send_notification
    Mailer.crm_contact_add(self).deliver if Setting.notified_events.include?('crm_contact_added')
  end

end
