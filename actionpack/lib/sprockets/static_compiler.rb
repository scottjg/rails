require 'fileutils'

module Sprockets
  class StaticCompiler
    attr_accessor :env, :target, :paths

    def initialize(env, target, paths, options = {})
      @env = env
      @target = target
      @paths = paths
      @digest = options.fetch(:digest, true)
      @manifest = options.fetch(:manifest, true)
      @manifest_path = options.delete(:manifest_path) || target
      @zip_files = options.delete(:zip_files) || /\.(?:css|html|js|svg|txt|xml)$/

      @current_source_digests = options.fetch(:source_digests, {})
      @current_digest_files   = options.fetch(:digest_files,   {})

      @digest_files   = {}
      @source_digests = {}
    end

    def compile
      start_time = Time.now.to_f

      env.each_logical_path do |logical_path|
        if File.basename(logical_path)[/[^\.]+/, 0] == 'index'
          logical_path.sub!(/\/index\./, '.')
        end
        next unless compile_path?(logical_path)

        # Fetch asset without any processing or compression,
        # to calculate a digest of the concatenated source files
        asset = env.find_asset(logical_path, :process => false)

        @source_digests[logical_path] = asset.digest

        # Recompile if digest has changed or compiled digest file is missing
        current_digest_file = @current_digest_files[logical_path]

        if @source_digests[logical_path] != @current_source_digests[logical_path] ||
           !(current_digest_file && File.exists?("#{@target}/#{current_digest_file}"))

          if asset = env.find_asset(logical_path)
            @digest_files[logical_path] = write_asset(asset)
          end

        else
          # Set asset file from manifest.yml
          digest_file = @current_digest_files[logical_path]
          @digest_files[logical_path] = digest_file

          env.logger.debug "Not compiling #{logical_path}, sources digest has not changed " <<
                           "(#{@source_digests[logical_path][0...7]})"
        end
      end

      # Encode all filenames & digests as UTF-8 for Ruby 1.9,
      # otherwise YAML dumps other string encodings as !binary
      if RUBY_VERSION.to_f >= 1.9
        @source_digests = encode_hash_as_utf8 @source_digests
        @digest_files   = encode_hash_as_utf8 @digest_files
      end

      if @manifest
        write_manifest(source_digests: @source_digests, digest_files: @digest_files)
      end

      # Store digests in Rails config. (Important if non-digest is run after primary)
      config = ::Rails.application.config
      config.assets.digest_files   = @digest_files
      config.assets.source_digests = @source_digests

      elapsed_time = ((Time.now.to_f - start_time) * 1000).to_i
      env.logger.debug "Processed #{'non-' unless @digest}digest assets in #{elapsed_time}ms"
    end

    def write_manifest(manifest)
      FileUtils.mkdir_p(@manifest_path)
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

    private

    def path_for(asset)
      @digest ? asset.digest_path : asset.logical_path
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

    def encode_hash_as_utf8(hash)
      Hash[*hash.map {|k,v| [k.encode("UTF-8"), v.encode("UTF-8")] }.flatten]
    end
  end
end
