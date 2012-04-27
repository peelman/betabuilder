require 'rake/tasklib'
require 'ostruct'
require 'fileutils'
require 'cfpropertylist'
require File.dirname(__FILE__) + '/beta_builder/archived_build'
require File.dirname(__FILE__) + '/beta_builder/deployment_strategies'
require File.dirname(__FILE__) + '/beta_builder/build_output_parser'

module BetaBuilder
  class Tasks < ::Rake::TaskLib
    def initialize(namespace = :beta, &block)
      @configuration = Configuration.new(
        :configuration => "Adhoc",
        :build_dir => "build",
        :auto_archive => false,
        :archive_path  => File.expand_path("~/Library/Developer/Xcode/Archives"),
        :xcodebuild_path => "xcodebuild",
        :xcodeargs => nil,
        :project_file_path => nil,
        :workspace_path => nil,
        :ipa_destination_path => "./",
        :scheme => nil,
        :app_name => nil,
        :arch => nil,
        :xcode4_archive_mode => false,
        :skip_clean => false,
        :verbose => false,
        :dry_run => false,
        :set_version_number => false
      )
      @namespace = namespace
      yield @configuration if block_given?
      define
    end

    def xcodebuild(*args)
      # we're using tee as we still want to see our build output on screen
      system("#{@configuration.xcodebuild_path} #{args.join(" ")} 2>&1 | tee build.output")
    end

    class Configuration < OpenStruct
      def release_notes_text
        return release_notes.call if release_notes.is_a? Proc
        release_notes
      end
      def build_arguments
        args = ""
        if workspace_path
          raise "A scheme is required if building from a workspace" unless scheme
          args << "-workspace '#{workspace_path}' -scheme '#{scheme}' -configuration '#{configuration}'"
        else
          args = "-target '#{target}' -configuration '#{configuration}' -sdk iphoneos"
          args << " -project #{project_file_path}" if project_file_path
        end

        args << " -arch \"#{arch}\"" unless arch.nil?


        args << " VERSION_LONG=#{build_number_git}" if set_version_number
        
        args << " #{xcodeargs}" unless xcodeargs.nil?

        
        args
      end

      def archive_name
        app_name || target
      end
      
      def app_file_name
        raise ArgumentError, "app_name or target must be set in the BetaBuilder configuration block" if app_name.nil? && target.nil?
        if app_name
          "#{app_name}.app"
        else
          "#{target}.app"
        end
      end
      
      def ipa_name
        if app_name
          "#{app_name}.ipa"
        else
          "#{target}.ipa"
        end
      end
      
      def built_app_path
        if build_dir == :derived
          File.join("#{derived_build_dir_from_build_output}", "#{configuration}-iphoneos", "#{app_file_name}")
        else
          File.join("#{build_dir}", "#{configuration}-iphoneos", "#{app_file_name}")
        end
      end
      
      def derived_build_dir_from_build_output
        output = BuildOutputParser.new(File.read("build.output"))
        output.build_output_dir  
      end
      
      def built_app_dsym_path
        "#{built_app_path}.dSYM"
      end
      
      def ipa_path
        File.join(File.expand_path(ipa_destination_path), ipa_name)
      end
      
      def build_number_git
        `git describe --tags --long`.chop
      end
      
      def deploy_using(strategy_name, &block)
        if DeploymentStrategies.valid_strategy?(strategy_name.to_sym)
          self.deployment_strategy = DeploymentStrategies.build(strategy_name, self)
          self.deployment_strategy.configure(&block)
        else
          raise "Unknown deployment strategy '#{strategy_name}'."
        end
      end
    end
    
    private
    
    def define
      namespace(@namespace) do        
        desc "Clean the Build"
        task :clean do
          unless @configuration.skip_clean
            xcodebuild @configuration.build_arguments, "clean"
          end
        end
        
        desc "Build the beta release of the app"
        task :build => :clean do
          xcodebuild @configuration.build_arguments, "build"
          raise "** BUILD FAILED **" if BuildOutputParser.new(File.read("build.output")).failed?
        end
        
        desc "Package the beta release as an IPA file"
        task :package => :build do
          if @configuration.auto_archive
            Rake::Task["#{@namespace}:archive"].invoke
          end
               
          system("/usr/bin/xcrun -sdk iphoneos PackageApplication -v '#{@configuration.built_app_path}' -o '#{@configuration.ipa_path}' --sign '#{@configuration.signing_identity}' --embed '#{@configuration.provisioning_profile}'")

        end

        desc "Build and archive the app"
        task :archive => :build do
          puts "Archiving build..."
          archive = BetaBuilder.archive(@configuration)
          output_path = archive.save_to(@configuration.archive_path)
          puts "Archive saved to #{output_path}."
        end

        if @configuration.deployment_strategy
          desc "Prepare your app for deployment"
          task :prepare => :package do
            @configuration.deployment_strategy.prepare
          end
          
          desc "Deploy the beta using your chosen deployment strategy"
          task :deploy => :prepare do
            @configuration.deployment_strategy.deploy
          end
          
          desc "Deploy the last build"
          task :redeploy do
            @configuration.deployment_strategy.prepare
            @configuration.deployment_strategy.deploy
          end
        end
        

      end
    end
  end
end
