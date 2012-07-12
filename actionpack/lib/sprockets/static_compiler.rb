require 'fileutils'

module Sprockets
  class StaticCompiler
    attr_accessor :env, :target, :paths, :files, :compiled_files

    def initialize(env, target, paths, options = {})
      @env = env
      @target = target
      @paths = paths
      @digest = options.key?(:digest) ? options.delete(:digest) : true
      @manifest = options.key?(:manifest) ? options.delete(:manifest) : true
      @manifest_path = options.delete(:manifest_path) || target
      @files = options.delete(:files)
      @paths = Array.wrap(@files) if @files
    end

    def compile
      @compiled_files = {}
      if @digest && File.exists?("#{@manifest_path}/manifest.yml") && @files #we compile only specific files, so have to add
        @compiled_files = YAML.load_file("#{@manifest_path}/manifest.yml")
      end

      manifest = {}
      env.each_logical_path do |logical_path|
        if File.basename(logical_path)[/[^\.]+/, 0] == 'index'
          logical_path.sub!(/\/index\./, '.')
        end
        next unless compile_path?(logical_path)
        if asset = env.find_asset(logical_path)
          manifest[logical_path] = write_asset(asset)
          if @digest && @compiled_files[logical_path] && @compiled_files[logical_path] != manifest[logical_path]
            filename = File.join(target, @compiled_files[logical_path])
            FileUtils.rm(filename) if File.exists?(filename)
            FileUtils.rm("#{filename}.gz") if filename.to_s =~ /\.(css|js)$/ && File.exists?("#{filename}.gz")
          end
        end
      end
      write_manifest(manifest) if @manifest
    end

    def write_manifest(manifest)
      FileUtils.mkdir_p(@manifest_path)
      if @digest && File.exists?("#{@manifest_path}/manifest.yml") && @files #we compile only specific files, so have to add
        @compiled_files.merge!(manifest)
        manifest = @compiled_files
      end
      File.open("#{@manifest_path}/manifest.yml", 'wb') do |f|
        YAML.dump(manifest, f)
      end
    end

    def write_asset(asset)
      path_for(asset).tap do |path|
        filename = File.join(target, path)
        FileUtils.mkdir_p File.dirname(filename)
        asset.write_to(filename)
        asset.write_to("#{filename}.gz") if filename.to_s =~ /\.(css|js)$/
      end
    end

    def compile_path?(logical_path)
      paths.each do |path|
        case path
        when Regexp
          return true if path.match(logical_path)
        when Proc
          return true if path.call(logical_path)
        else
          return true if File.fnmatch(path.to_s, logical_path)
        end
      end
      false
    end

    def path_for(asset)
      @digest ? asset.digest_path : asset.logical_path
    end
  end
end
