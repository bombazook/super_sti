# frozen_string_literal: true

require 'rubygems'

ruby_version = Gem::Version.new(RUBY_VERSION)
if ruby_version < Gem::Version.new('2.3')
  system "gem install rubygems-update -v '<3.0.0'"
  system "gem update --system"
  if ruby_version < Gem::Version.new('2.2')
    system "gem install bundler -v '~> 1.17.3'"
  end
else
  system 'gem install bundler'
end
