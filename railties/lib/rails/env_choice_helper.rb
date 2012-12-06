module Rails
  module EnvChoiceHelper
    def self.env
      ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development"
    end
  end
end

