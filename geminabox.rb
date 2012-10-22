PACKAGES = %w(activesupport activerecord actionpack actionmailer activeresource railties)

build = ENV['PKG_BUILD'] || "pp_#{`git rev-parse HEAD`.strip[0..6]}"
PACKAGES.each do |p|
  system "PKG_BUILD=#{cd #{p} && rm -rf pkg/* && rake package && gem inabox pkg/*.gem && rm -rf pkg/*"
end
