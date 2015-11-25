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

#custom routes for this plugin
  resources :contacts, :path_names => {:contacts_notes => 'notes'} do
    collection do
      get :bulk_edit, :context_menu, :edit_mails, :contacts_notes
      post :bulk_edit, :bulk_update, :send_mails, :preview_email
      delete :bulk_destroy
    end
    member do
      get 'tabs/:tab' => 'contacts#show', :as => "tabs"
      get 'load_tab' => 'contacts#load_tab', :as => "load_tab"
    end
    resources :contacts_projects, :path => "projects", :only => [:new, :create, :destroy]
  end

  resources :projects do
    resources :contacts, :path_names => {:contacts_notes => 'notes'} do
      collection do
        get :contacts_notes
      end
    end

  end

  resources :projects do
    resources :crm_queries, :only => [:new, :create]
  end

  resources :crm_queries, :except => [:show]

  resources :notes

  match '/contacts_tags', :controller => 'contacts_tags', :action => 'destroy', :via => :delete

  resources :contacts_tags do
    collection do
      post :merge, :context_menucha
      get :context_menu, :merge
    end
  end

  match 'projects/:project_id/contacts/:contact_id/new_task' => 'contacts_issues#new', :via => :post

  match 'contacts/:contact_id/duplicates' => 'contacts_duplicates#index', :via => [:get, :post]

  match 'projects/:project_id/deal_categories/new' => 'deal_categories#new', :via => [:get, :post]


  match 'auto_completes/taggable_tags' => 'auto_completes#taggable_tags', :via => :get, :as => 'auto_complete_taggable_tags'
  match 'auto_completes/contact_tags' => 'auto_completes#contact_tags', :via => :get, :as => 'auto_complete_contact_tags'
  match 'auto_completes/contacts' => 'auto_completes#contacts', :via => :get, :as => 'auto_complete_contacts'
  match 'auto_completes/companies' => 'auto_completes#companies', :via => :get, :as => 'auto_complete_companies'

  match 'users/new_from_contact/:id' => 'users#new_from_contact', :via => :get
  match 'contacts_duplicates/:action' => 'contacts_duplicates', :via => [:get, :post]
  match 'contacts_duplicates/search' => 'contacts_duplicates#search', :via => :get, :as => 'contacts_duplicates_search'
  match 'contacts_issues/:action' => 'contacts_issues', :via => [:get, :post, :delete, :put]
  match 'contacts_vcf/:action' => 'contacts_vcf', :via => [:get, :post]
  match 'deal_contacts/:action' => 'deal_contacts', :via => [:get, :post, :delete]
  match 'deals_tasks/:action' => 'deals_tasks', :via => [:get, :post, :put]
  match 'contacts_settings/:action' => 'contacts_settings', :via => [:get, :post]
  match 'contacts_mailer/:action' => 'contacts_mailer', :via => [:get, :post]
  match 'attachments/contacts_thumbnail/:id(/:size)', :controller => 'attachments', :action => 'contacts_thumbnail', :id => /\d+/, :via => :get
