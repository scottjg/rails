if (min_release = "1.8.7") > RUBY_VERSION
  abort <<-end_message

    Rails requires Ruby version #{min_release} or later.
    You're running #{RUBY_VERSION}; please upgrade to continue.

  end_message
end
