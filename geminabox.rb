PACKAGES = %w(activesupport activerecord actionpack actionmailer activeresource railties)

build = ENV['PKG_BUILD'] ||= "pp#{`git rev-parse HEAD`.strip[0..6]}"
PACKAGES.each do |p|
  system "export PKG_BUILD=#{build} && cd #{p} && rm -rf pkg/* && rake package && gem inabox pkg/*.gem && rm -rf pkg/*"
end
