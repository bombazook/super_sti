require 'active_support/inflector'
require 'active_support/core_ext'
require 'active_record'

ActiveSupport::Inflector.inflections do |inflect|
  inflect.singular /(data)$/, '\1'
end

require_relative "super_sti/hook"
require_relative "super_sti/railtie"