# Rails 2 for the rest of us

The Rails core team no longer supports Rails 2.3 for anything other
than what they deem "severe security issues". That's bad news for
those of us who still run 2.3 apps in production and for some reason
are unable to upgrade.

The alternative to using the latest (unpatched) gem is either to
vendor all of Rails - thus bloating your own repo - or depending on
Rails from Git with Bundler. The official Rails repo does not include
the necessary gemspecs to do so (understandably, they are build
artefacts after all), making this impossible. Thus this repository.

You can now depend on a safe(r) Rails 2 through this repository. The
idea is that it will be patched and kept up to date (security-wise
only, no breaking changes, no features etc) by us - the community that
needs it - so you can avoid vendoring Rails to stay safe.

In your Rails 2 app using Bundler, replace `gem "rails", "2.3.15"`
in `Gemfile` with:

```rb
git "git://github.com/rails2/rails.git", :branch => "2-3-stable" do
  gem "rails"
  gem "actionmailer"
  gem "actionpack"
  gem "activerecord"
  gem "activeresource"
  gem "activesupport"
end
```

Do `bundle` (optionally shed a tear at how slow this now is), and
rejoice in your safe(r) Rails 2.3 app!
