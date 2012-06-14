class FilmService < ActiveResource::Base
  self.site = 'http://www.example.com/:global_namespace/services'
  self.global_prefix_options = { :global_namespace => 'all' }
end

class Film < FilmService
  self.global_prefix_options = { :global_namespace => 'film' }
end

class Still < FilmService
  self.global_prefix_options = lambda { {:global_namespace => 'still'} }
end

class Trailer < FilmService
end
