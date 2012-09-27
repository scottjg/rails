PACKAGES = %w(activesupport activerecord actionpack actionmailer activeresource railties)

PACKAGES.each do |p|
  system "cd #{p} && rm -rf pkg/* && rake package && gem inabox pkg/*.gem && rm -rf pkg/*"
end
