require_relative 'options'
require_relative 'delegation'
require_relative 'inheritance'

module SuperSTI
  
  class DataMissingError < ::StandardError;end
  class DataClassMissingError < ::StandardError;end
  class IncorrectOptionsError < ::StandardError;end
  
  module Hook

    def belongs_to_extra_data *args, &block
      assoc_name, options = common_setup(*args, &block)
      belongs_to assoc_name, options, &block
      @super_sti_config[assoc_name].sti_method = :belongs_to_extra_data
      before_create :"#{assoc_name}"
    end

    def has_extra_data *args, &block
      assoc_name, options = common_setup(*args, &block)
      has_one assoc_name, options, &block
      @super_sti_config[assoc_name].sti_method = :has_extra_data
      before_create :"#{assoc_name}"
    end

    private
      def common_setup *args, &block
        options = args.extract_options!
        options.symbolize_keys!

        association_name = args.shift if args.first.kind_of? Symbol or args.first.kind_of? String
        association_name ||= :data

        unless self.respond_to? :super_sti_config
          include Options::Storage
          include Delegation
          extend Inheritance
        end

        @super_sti_config ||= SuperSTI::Options.new(self)
        @super_sti_config.load_defaults_for(association_name)
        @super_sti_config.load_inherited_for(association_name)

        # merging explicit options
        association_config = @super_sti_config[association_name]
        association_config.deep_merge!(options)

        # fallback class_name setup (if not inherited nor default classes exist)
        @super_sti_config.set_fallback_class_name_for(association_name)

        # undef rails callbacks for autosave associations (inheritance does not create new ones and some options can't be used)
        autosave_method = "autosave_associated_records_for_#{association_name}"
        autovalidate_method = "validate_associated_records_for_#{association_name}"
        undef_method(autosave_method) if method_defined?(autosave_method)
        undef_method(autovalidate_method) if method_defined?(autovalidate_method)

        # find or create data class
        klass = association_config.class_name.safe_constantize || create_data_class(association_config)
        klass.class_eval &block if block_given?

        [association_name.to_sym, association_config.reflection_options.symbolize_keys]
      end

      def create_data_class association_config
        klass = Class.new(ActiveRecord::Base) do
          self.table_name = association_config.plugin_options.table_name if association_config.plugin_options.table_name
        end
        klass_name = association_config.reflection_options.class_name
        namespace = klass_name.deconstantize.constantize
        const = klass_name.demodulize
        namespace.const_set const, klass
        klass
      end
    
  end
end
