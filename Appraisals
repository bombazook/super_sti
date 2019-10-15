# frozen_string_literal: true

require 'yaml'
require 'gems'

ruby_version_range = 1.9..2.7
ruby_versions = ruby_version_range.step(0.1).to_a.map { |i| i.floor(1) }
not_working_combinations = [[2.4, "6.0.0"], [2.7, "4.2.11.1"]].freeze

first_rails_version = Gem::Version.new('3.2')

rails_versions = Gems.versions('rails').select do |version|
  v = Gem::Version.new(version['number'])
  (v >= first_rails_version) && !v.prerelease?
end

rails_versions = rails_versions.group_by do |v|
  Gem::Version.new(v['number']).segments[0..1]
end

rails_versions = rails_versions.values.flat_map do |version_group|
  version_group.inject(version_group.first) do |m, version|
    if Gem::Version.new(version['number']) > Gem::Version.new(m['number'])
      version
    else
      m
    end
  end
end

if defined? Appraisal
  rails_versions.each do |version|
    version_number = version['number']
    appraise version_number do
      gem('activerecord', version_number)
      if Gem::Requirement.new('~> 6.0').satisfied_by?(Gem::Version.new(version_number))
        gem('sqlite3', '~> 1.4.0')
      end
    end
  end
end

versions_product = ruby_versions.product(rails_versions)
exclusion_matrix = versions_product.select do |ruby_version, rails_version|
  if not_working_combinations.include?([ruby_version, rails_version["number"]])
    true
  elsif Gem::Requirement.new('> 2.3').satisfied_by?(Gem::Version.new(ruby_version))
    Gem::Requirement.new('< 4.2').satisfied_by?(Gem::Version.new(rails_version["number"]))
  elsif rails_version['ruby_version']
    rails_ruby_requirement = Gem::Requirement.new(rails_version['ruby_version'])
    !rails_ruby_requirement.satisfied_by?(Gem::Version.new(ruby_version))
  end
end

exclusion_list = exclusion_matrix.map do |ruby_version, rails_version|
  {
    'rvm' => ruby_version,
    'gemfile' => "gemfiles/#{rails_version['number']}.gemfile"
  }
end

travis_hash = {
  'language' => 'ruby',
  'rvm' => ruby_versions,
  'before_install' => 'ruby prepare_rubygems.rb',
  'script' => 'bundle exec rspec spec',
  'gemfile' => Dir.glob('gemfiles/*.gemfile'),
  'matrix' => {
    'exclude' => exclusion_list
  }
}

::File.open('.travis.yml', 'w+') do |f|
  travis = ::YAML.dump(travis_hash)
  f.write travis
end
