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

module ContactsHelper

  def contact_tabs(contact)
    contact_tabs = []
    contact_tabs << {:name => 'notes', :partial => 'contacts/notes', :label => l(:label_crm_note_plural)} if contact.visible?
    contact_tabs << {:name => 'contacts', :partial => 'company_contacts', :label => l(:label_contact_plural) + (contact.company_contacts.visible.count > 0 ? " (#{contact.company_contacts.count})" : "")} if contact.is_company?
    contact_tabs
  end

  def settings_contacts_tabs
    ret = [
      {:name => 'general', :partial => 'settings/contacts/contacts_general', :label => :label_general},
      {:name => 'money', :partial => 'settings/contacts/money', :label => :label_crm_money_settings},
    ]
    ret.push({:name => 'hidden', :partial => 'settings/contacts/contacts_hidden', :label => :label_crm_contacts_hidden}) if params[:hidden]
    ret
  end

  def collection_for_visibility_select
    [[l(:label_crm_contacts_visibility_project), Contact::VISIBILITY_PROJECT],
     [l(:label_crm_contacts_visibility_public), Contact::VISIBILITY_PUBLIC],
     [l(:label_crm_contacts_visibility_private), Contact::VISIBILITY_PRIVATE]]
  end

  def contact_list_styles_for_select
    list_styles = [[l(:label_crm_list_excerpt), "list_excerpt"]]
  end

  def contacts_list_style
    list_styles = contact_list_styles_for_select.map(&:last)
    if params[:contacts_list_style].blank?
      list_style = list_styles.include?(session[:contacts_list_style]) ? session[:contacts_list_style] : RedmineContacts.default_list_style
    else
      list_style = list_styles.include?(params[:contacts_list_style]) ? params[:contacts_list_style] : RedmineContacts.default_list_style
    end
    session[:contacts_list_style] = list_style
  end

  def authorized_for_permission?(permission, project, global = false)
    User.current.allowed_to?(permission, project, :global => global)
  end

  def render_contact_projects_hierarchy(projects)
    s = ''
    project_tree(projects) do |project, level|
      s << "<ul>"
      name_prefix = (level > 0 ? ('&nbsp;' * 2 * level + '&#187; ') : '')
      s << "<li id='project_#{project.id}'>" + name_prefix + link_to_project(project)

      s += ' ' + link_to(image_tag('delete.png'),
                                 contact_contacts_project_path(@contact, :id => project.id, :project_id => @project.id),
                                 :remote => true,
                                 :method => :delete,
                                 :style => "vertical-align: middle",
                                 :class => "delete",
                                 :title => l(:button_delete)) if (projects.size > 1 && User.current.allowed_to?(:edit_contacts, project))
      s << "</li>"

      s << "</ul>"
    end
    s.html_safe
  end

  def contact_to_vcard(contact)
    return false unless ContactsSetting.vcard?

    card = Vcard::Vcard::Maker.make2 do |maker|

      maker.add_name do |name|
        name.prefix = ''
        name.given = contact.first_name.to_s
        name.family = contact.last_name.to_s
        name.additional = contact.middle_name.to_s
      end

      maker.add_addr do |addr|
        addr.preferred = true
        addr.street = contact.street1.to_s.gsub("\r\n"," ").gsub("\n"," ")
        addr.locality = contact.city.to_s
        addr.region = contact.region.to_s
        addr.postalcode = contact.postcode.to_s
        addr.country = contact.country.to_s
        addr.location = 'business'
      end

      maker.title = contact.job_title.to_s
      maker.org = contact.company.to_s
      maker.birthday = contact.birthday.to_date unless contact.birthday.blank?
      maker.add_note(contact.background.to_s.gsub("\r\n"," ").gsub("\n", ' '))

      maker.add_url(contact.website.to_s)

      contact.phones.each { |phone| maker.add_tel(phone) }
      contact.emails.each { |email| maker.add_email(email) }
    end
    avatar = contact.attachments.find_by_description('avatar')
    card = card.encode.sub("END:VCARD", "PHOTO;BASE64:" + "\n " + [File.open(avatar.diskfile).read].pack('m').to_s.gsub(/[ \n]/, '').scan(/.{1,76}/).join("\n ") + "\nEND:VCARD") if avatar && avatar.readable?

    card.to_s

  end

  def set_flash_from_bulk_contact_save(contacts, unsaved_contact_ids)
    if unsaved_contact_ids.empty?
      flash[:notice] = l(:notice_successful_update) unless contacts.empty?
    else
      flash[:error] = l(:notice_failed_to_save_contacts,
                        :count => unsaved_contact_ids.size,
                        :total => contacts.size,
                        :ids => '#' + unsaved_contact_ids.join(', #'))
    end
  end

  def render_contact_tabs(tabs)
    if tabs.any?
      render :partial => 'common/contact_tabs', :locals => {:tabs => tabs}
    else
      content_tag 'p', l(:label_no_data), :class => "nodata"
    end
  end


end
