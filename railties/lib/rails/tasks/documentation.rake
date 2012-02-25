begin
  require 'rdoc/task'
rescue LoadError
  require 'rdoc/rdoc'
  require 'rake/rdoctask'
  RDoc::Task = Rake::RDocTask
end

# Monkey-patch to remove redoc'ing and clobber descriptions to cut down on rake -T noise
class RDocTaskWithoutDescriptions < RDoc::Task
  include ::Rake::DSL

  def define
    task rdoc_task_name

    task rerdoc_task_name => [clobber_task_name, rdoc_task_name]

    task clobber_task_name do
      rm_r rdoc_dir rescue nil
    end

    task :clobber => [clobber_task_name]

    directory @rdoc_dir
    task rdoc_task_name => [rdoc_target]
    file rdoc_target => @rdoc_files + [Rake.application.rakefile] do
      rm_r @rdoc_dir rescue nil
      @before_running_rdoc.call if @before_running_rdoc
      args = option_list + @rdoc_files
      if @external
        argstring = args.join(' ')
        sh %{ruby -Ivendor vendor/rd #{argstring}}
      else
        require 'rdoc/rdoc'
        RDoc::RDoc.new.document(args)
      end
    end
    self
  end
end

namespace :doc do
  def gem_path(gem_name)
    path = $LOAD_PATH.grep(/#{gem_name}[\w.-]*\/lib$/).first
    yield File.dirname(path) if path
  end

  RDocTaskWithoutDescriptions.new("app") { |rdoc|
    rdoc.rdoc_dir = 'doc/app'
    rdoc.template = ENV['template'] if ENV['template']
    rdoc.title    = ENV['title'] || "Rails Application Documentation"
    rdoc.options << '--line-numbers'
    rdoc.options << '--charset' << 'utf-8'
    rdoc.rdoc_files.include('doc/README_FOR_APP')
    rdoc.rdoc_files.include('app/**/*.rb')
    rdoc.rdoc_files.include('lib/**/*.rb')
  }
  Rake::Task['doc:app'].comment = "Generate docs for the app -- also available doc:rails, doc:guides (options: TEMPLATE=/rdoc-template.rb, TITLE=\"Custom Title\")"

  # desc 'Generate documentation for the Rails framework.'
  RDocTaskWithoutDescriptions.new("rails") { |rdoc|
    rdoc.rdoc_dir = 'doc/api'
    rdoc.template = "#{ENV['template']}.rb" if ENV['template']
    rdoc.title    = "Rails Framework Documentation"
    rdoc.options << '--line-numbers'
    rdoc.rdoc_files.include('README.rdoc')

    gem_path('action_mailer') do |action_mailer|
      %w(README.rdoc CHANGELOG.md MIT-LICENSE lib/action_mailer/base.rb).each do |file|
        rdoc.rdoc_files.include("#{action_mailer}/#{file}")
      end
    end

    gem_path('action_pack') do |action_pack|
      %w(README.rdoc CHANGELOG.md MIT-LICENSE lib/action_controller/**/*.rb lib/action_view/**/*.rb).each do |file|
        rdoc.rdoc_files.include("#{action_pack}/#{file}")
      end
    end

    gem_path('active_model') do |active_model|
      %w(README.rdoc CHANGELOG.md MIT-LICENSE lib/active_model/**/*.rb).each do |file|
        rdoc.rdoc_files.include("#{active_model}/#{file}")
      end
    end

    gem_path('active_record') do |active_record|
      %w(README.rdoc CHANGELOG.md lib/active_record/**/*.rb).each do |file|
        rdoc.rdoc_files.include("#{active_record}/#{file}")
      end
    end

    gem_path('active_resource') do |active_resource|
      %w(README.rdoc CHANGELOG.md lib/active_resource.rb lib/active_resource/*).each do |file|
        rdoc.rdoc_files.include("#{active_resource}/#{file}")
      end
    end

    gem_path('active_support') do |active_support|
      %w(README.rdoc CHANGELOG.md lib/active_support/**/*.rb).each do |file|
        rdoc.rdoc_files.include("#{active_support}/#{file}")
      end
    end

    gem_path('railties') do |railties|
      %w(README.rdoc CHANGELOG.md lib/{*.rb,commands/*.rb,generators/*.rb}).each do |file|
        rdoc.rdoc_files.include("#{railties}/#{file}")
      end
    end
  }

  # desc "Generate Rails Guides"
  task :guides do
    # FIXME: Reaching outside lib directory is a bad idea
    require File.expand_path('../../../../guides/rails_guides', __FILE__)
    RailsGuides::Generator.new(Rails.root.join("doc/guides")).generate
  end
end
