module RedmineGitHosting

  module Config

    include Config::GitoliteAccess
    include Config::GitoliteBase
    include Config::GitoliteCache
    include Config::GitoliteConfigTests
    include Config::GitoliteHooks
    include Config::GitoliteInfos
    include Config::GitoliteNotifications
    include Config::GitoliteStorage
    include Config::Mirroring
    include Config::RedmineConfig

    GITHUB_ISSUE = 'https://github.com/jbox-web/redmine_git_hosting/issues'
    GITHUB_WIKI  = 'https://jbox-web.github.io/redmine_git_hosting/configuration/variables/'

    GITOLITE_DEFAULT_CONFIG_FILE       = 'gitolite.conf'
    GITOLITE_IDENTIFIER_DEFAULT_PREFIX = 'redmine_'


    ###############################
    ##                           ##
    ##  CONFIGURATION ACCESSORS  ##
    ##                           ##
    ###############################

    class << self

      def logger
        RedmineGitHosting.logger
      end


      def get_setting(setting, bool = false)
        if bool
          return_bool do_get_setting(setting)
        else
          return do_get_setting(setting)
        end
      end


      def reload_from_file!(opts = {})
        reload!(nil, opts)
      end


      ### PRIVATE ###


      def return_bool(value)
        value == 'true' ? true : false
      end


      def do_get_setting(setting)
        setting = setting.to_sym

        ## Wrap this in a begin/rescue statement because Setting table
        ## may not exist on first migration
        begin
          value = Setting.plugin_redmine_git_hosting[setting]
        rescue => e
          value = Redmine::Plugin.find('redmine_git_hosting').settings[:default][setting]
        else
          ## The Setting table exist but does not contain the value yet, fallback to default
          if value.nil?
            value = Redmine::Plugin.find('redmine_git_hosting').settings[:default][setting]
          end
        end

        value
      end


      def reload!(config = nil, opts = {})
        logger = ConsoleLogger.new(opts)

        if !config.nil?
          default_hash = config
        else
          ## Get default config from init.rb
          default_hash = Redmine::Plugin.find('redmine_git_hosting').settings[:default]
        end

        if default_hash.nil? || default_hash.empty?
          logger.info('No defaults specified in init.rb!')
        else
          do_reload_config(default_hash, logger)
        end
      end


      def do_reload_config(default_hash, logger)
        ## Refresh Settings cache
        Setting.check_cache

        ## Get actual values
        valuehash = (Setting.plugin_redmine_git_hosting).clone

        ## Update!
        changes = 0

        default_hash.each do |key, value|
          if valuehash[key] != value
            logger.info("Changing '#{key}' : #{valuehash[key]} => #{value}")
            valuehash[key] = value
            changes += 1
          end
        end

        if changes == 0
          logger.info('No changes necessary.')
        else
          logger.info('Committing changes ... ')
          begin
            ## Update Settings
            Setting.plugin_redmine_git_hosting = valuehash
            ## Refresh Settings cache
            Setting.check_cache
            logger.info('Success!')
          rescue => e
            logger.error('Failure.')
            logger.error(e.message)
          end
        end
      end

    end

    private_class_method :return_bool,
                         :do_get_setting,
                         :reload!,
                         :do_reload_config


    class ConsoleLogger

      attr_reader :console
      attr_reader :logger

      def initialize(opts = {})
        @console = opts[:console] || false
        @logger ||= RedmineGitHosting.logger
      end

      def info(message)
        puts message if console
        logger.info(message)
      end

      def error(message)
        puts message if console
        logger.error(message)
      end

      # Handle everything else with base object
      def method_missing(m, *args, &block)
        logger.send m, *args, &block
      end

    end

  end
end
