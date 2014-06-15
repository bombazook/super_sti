module SuperSTI
  PLUGIN_OPTIONS = [:inherit, :table_name, :autobuild]
  DEFAULT_OPTIONS = {autosave: true, dependent: :destroy}
  INHERITED_BY_DEFAULT = [:inherit, :class_name]

  class OptionsHash < HashWithIndifferentAccess
    def method_missing mid, *args, &block
      mname = mid.id2name
      len = args.length
      if mname.chomp!('=') && mid != :[]=
        if len != 1
          raise ArgumentError, "wrong number of arguments (#{len} for 1)", caller(1)
        end
        self[mname] = args.first
      elsif len == 0 && mid != :[]
        self[mid]
      else
        super
      end
    end

    def inherit_merge! merging_hash, options = merging_hash[:inherit]
      case options
      when true
        deep_merge! merging_hash
      when :default, nil
        merge_with_rules! merging_hash
      when Hash
        merge_with_rules! merging_hash, options
      end
    end

    def merge_with_rules! merging_hash, rules = {}
      merging_hash.each_pair do |key, new_value|
        old_value = self[key]
        case rules[key]
        when true
          self[key] = new_value
        when :default, nil
          self[key] = new_value if INHERITED_BY_DEFAULT.include?(key.to_sym) and old_value.blank?
        when Hash
          self[key] = old_value.inherit_merge!(new_value, rules[key])
        end
      end
    end

    def respond_to? mid, include_private = false
      mname = mid.id2name
      return true if (mname.chomp('=') && mid != :[]=) || self[mname] || super
    end

  end

  class AssociationHash < OptionsHash
    attr_accessor :sti_method

    def plugin_options
      self.slice *PLUGIN_OPTIONS
    end

    def reflection_options
      self.except *PLUGIN_OPTIONS
    end
  end

  class Options

    def initialize klass=nil
      @klass = klass
      @options_hash = OptionsHash.new
    end

    def set_fallback_class_name_for association_name
      unless @options_hash[association_name][:class_name]
        model_underscore = "#{@klass.name.underscore.gsub("/", "_")}_#{association_name}"
        sti_namespaced = ["super_s_t_i", model_underscore].join('/').classify
        @options_hash[association_name][:class_name] = sti_namespaced
      end
    end


    def load_defaults_for association_name
      @options_hash[association_name] = AssociationHash.new
      assoc_options = @options_hash[association_name]
      assoc_options.deep_merge! DEFAULT_OPTIONS
      model_underscore = "#{@klass.name.underscore.gsub("/", "_")}_#{association_name}"
      sti_namespaced = ["super_s_t_i", model_underscore].join('/').classify
      root_namespaced = model_underscore.classify
      if sti_namespaced.safe_constantize
        assoc_options.class_name = sti_namespaced
      elsif root_namespaced.safe_constantize
        assoc_options.class_name = root_namespaced
      end
    end

    def load_inherited_for association_name
      if @klass.superclass.respond_to?(:super_sti_config) and (merging_options = @klass.superclass.super_sti_config[association_name])
        @options_hash[association_name].inherit_merge! merging_options
      end
    end

    def respond_to? name, include_private = false
      super || @options_hash.respond_to?(name, include_private)
    end

    def method_missing name, *args, &block
      @options_hash.send(name, *args, &block)
    end

  end

end

module SuperSTI
  module Options::Storage
    extend ActiveSupport::Concern

    included do
      class << self
        attr_reader :super_sti_config
        private
          attr_writer :super_sti_config
      end
    end
  end
end


        
        