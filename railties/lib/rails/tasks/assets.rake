namespace :assets do
  task :compile => :environment do
    raise "Asset Pipelining is not enabled" unless Rails.application.config.assets.enabled
    assets = Rails.application.config.assets.precompile
    Rails.application.assets.precompile(*assets)
  end
end
