module RedmineGitHosting
  module GitoliteHandlers
    class RepositoryHandler

      attr_reader :repository
      attr_reader :gitolite_config
      attr_reader :action
      attr_reader :opts

      attr_reader :project

      attr_reader :gitolite_repo_name
      attr_reader :gitolite_repo_path
      attr_reader :gitolite_repo_conf


      def initialize(repository, gitolite_config, action, opts = {})
        # Create accessors for the params passed
        @repository         = repository
        @gitolite_config    = gitolite_config
        @action             = action
        @opts               = opts

        # Create syntaxic sugars
        @project            = repository.project
        @gitolite_repo_name = repository.gitolite_repository_name
        @gitolite_repo_path = repository.gitolite_repository_path
        @gitolite_repo_conf = gitolite_config.repos[gitolite_repo_name]
        @old_perms          = {}
      end


      private


        def logger
          RedmineGitHosting.logger
        end


        def backup_old_perms
          @old_perms ||= PermissionsBuilder.get_permissions(gitolite_repo_conf)
        end


        def configuration_exists?
          !gitolite_repo_conf.nil?
        end


        def create_repository_config
          do_update_repository
        end


        def update_repository_config
          recreate_repository_config
        end


        def recreate_repository_config
          # Backup old perms
          backup_old_perms

          # Remove repo from Gitolite conf, we're gonna recreate it
          gitolite_config.rm_repo(gitolite_repo_name)

          # Recreate repository in Gitolite
          do_update_repository
        end


        def do_update_repository
          # Create Gitolite config
          repo_conf = create_gitolite_config

          # Add it to Gitolite
          gitolite_config.add_repo(repo_conf)

          # Update permissions
          set_repository_permissions(repo_conf)
        end


        def set_repository_permissions(repo_conf)
          repo_conf.permissions = PermissionsBuilder.new(repository, @old_perms).call
        end


        def create_gitolite_config
          # Create new repo object
          repo_conf = build_gitolite_repository

          # Set post-receive hook params
          # TODO: set them only for active repositories?
          repo_conf = set_default_conf(repo_conf)

          if project.active?
            # Set repository config
            repo_conf = set_active_project_conf(repo_conf)
          else
            # Disable repository
            repo_conf = set_disabled_conf(repo_conf)
          end

          # Return repository config
          repo_conf
        end


        def build_gitolite_repository
          ::Gitolite::Config::Repo.new(gitolite_repo_name)
        end


        def set_default_conf(repo_conf)
          repo_conf.set_git_config('redminegitolite.projectid', project.identifier.to_s)
          repo_conf.set_git_config('redminegitolite.repositoryid', "#{repository.identifier || ''}")
          repo_conf.set_git_config('redminegitolite.repositorykey', repository.gitolite_hook_key)
          repo_conf
        end


        def set_active_project_conf(repo_conf)
          # Set SmartHttp download params
          repo_conf = set_smart_http_download_conf(repo_conf)

          # Set SmartHttp push params
          repo_conf = set_smart_http_upload_conf(repo_conf)

          # Set mail-notifications hook params
          repo_conf = set_mail_settings(repo_conf)

          # Set Git config keys
          repo_conf = set_repository_conf(repo_conf)

          repo_conf
        end


        def set_smart_http_download_conf(repo_conf)
          if repository.clonable_via_http?
            repo_conf.set_git_config('http.uploadpack', 'true')
          else
            repo_conf.set_git_config('http.uploadpack', 'false')
          end
          repo_conf
        end


        def set_smart_http_upload_conf(repo_conf)
          if repository.pushable_via_http?
            repo_conf.set_git_config('http.receivepack', 'true')
          else
            repo_conf.set_git_config('http.receivepack', 'false')
          end
          repo_conf
        end


        def set_mail_settings(repo_conf)
          if repository.git_notification_available?
            repo_conf.set_git_config('multimailhook.enabled', 'true')
            repo_conf.set_git_config('multimailhook.mailinglist', repository.mailing_list.join(", "))
            repo_conf.set_git_config('multimailhook.from', repository.sender_address)
            repo_conf.set_git_config('multimailhook.emailPrefix', repository.email_prefix)
          else
            repo_conf.set_git_config('multimailhook.enabled', 'false')
          end
          repo_conf
        end


        def set_repository_conf(repo_conf)
          repository.git_config_keys.each do |git|
            repo_conf.set_git_config(git.key, git.value)
          end if repository.git_config_keys.any?
          repo_conf
        end


        def set_disabled_conf(repo_conf)
          repo_conf.set_git_config('http.uploadpack', 'false')
          repo_conf.set_git_config('http.receivepack', 'false')
          repo_conf.set_git_config('multimailhook.enabled', 'false')
          repo_conf
        end

    end
  end
end
