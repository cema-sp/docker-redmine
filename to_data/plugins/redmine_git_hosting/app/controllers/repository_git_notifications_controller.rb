class RepositoryGitNotificationsController < RedmineGitHostingController
  unloadable

  before_filter :can_view_git_notifications,   :only => [:index]
  before_filter :can_create_git_notifications, :only => [:new, :create]
  before_filter :can_edit_git_notifications,   :only => [:edit, :update, :destroy]

  helper :tag_it


  def index
    render_404
  end


  def show
    @git_notification = @repository.git_notification
    render layout: false
  end


  def new
    @git_notification = @repository.build_git_notification
  end


  def create
    @git_notification = @repository.build_git_notification(params[:repository_git_notification])
    respond_to do |format|
      if @git_notification.save
        # Update Gitolite repository
        call_use_case

        flash[:notice] = l(:notice_git_notifications_created)
        format.js { render js: "window.location = #{success_url.to_json};" }
      else
        format.js
      end
    end
  end


  def edit
    @git_notification = @repository.git_notification
  end


  def update
    @git_notification = @repository.git_notification
    respond_to do |format|
      if @git_notification.update_attributes(params[:repository_git_notification])
        # Update Gitolite repository
        call_use_case

        flash[:notice] = l(:notice_git_notifications_updated)
        format.js { render js: "window.location = #{success_url.to_json};" }
      else
        format.js
      end
    end
  end


  def destroy
    @git_notification = @repository.git_notification
    respond_to do |format|
      if @git_notification.destroy
        # Update Gitolite repository
        call_use_case

        flash[:notice] = l(:notice_git_notifications_deleted)
        format.js { render js: "window.location = #{success_url.to_json};" }
      end
    end
  end


  private


    def set_current_tab
      @tab = 'repository_git_notifications'
    end


    def can_view_git_notifications
      render_403 unless User.current.git_allowed_to?(:view_repository_git_notifications, @repository)
    end


    def can_create_git_notifications
      render_403 unless User.current.git_allowed_to?(:create_repository_git_notifications, @repository)
    end


    def can_edit_git_notifications
      render_403 unless User.current.git_allowed_to?(:edit_repository_git_notifications, @repository)
    end


    def call_use_case
      options = { message: "Rebuild mailing list for respository : '#{@repository.gitolite_repository_name}'" }
      GitoliteAccessor.update_repository(@repository, options)
    end

end
