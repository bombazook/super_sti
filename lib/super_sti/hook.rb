require 'pp'

module SuperSTI
  
  class DataMissingError < ::StandardError;end
  
  module Hook
    DEFAULT_AFFIX = :subject
    ######
    # has_extra_data(options = {})
    #
    # In it's most raw form, this method creates an associated Data class, 
    # which seamlessly adds attributes and methods to the main class
    #
    # If passed a block, extra attributes can be set on the data table, 
    # methods (e.g. has_many) can be called, and other methods can be defined.
    #
    # Options:
    #   table_name: The table name of the class
    #####

    define_method "belongs_to_#{DEFAULT_AFFIX}" do |*args, &block|
      options = common_setup(*args, &block)
      association_name = options[:association_name]
      options.except!(:association_name, :association_class, "inherit_#{DEFAULT_AFFIX}_type".to_sym, :table_name, :parent_association_class)
      belongs_to association_name, options
      super_sti_options[association_name][:reflection] = reflections[association_name]
      super_sti_options[association_name][:method] = "belongs_to_#{DEFAULT_AFFIX}".to_sym
    end

    define_method "has_#{DEFAULT_AFFIX}" do |*args, &block|
      options = common_setup(*args, &block)
      association_name = options[:association_name]

      # in rails 4.1 it would look like this
      # valid_options = ActiveRecord::Associations::Builder::HasOne.valid_options(options)
      # options.slice! valid_options

      options.except!(:association_name, :association_class, "inherit_#{DEFAULT_AFFIX}_type".to_sym, :table_name, :parent_association_class)

      has_one association_name, options

      super_sti_options[association_name][:reflection] = reflections[association_name]

      super_sti_options[association_name][:method] = "has_#{DEFAULT_AFFIX}".to_sym
    end


    private
      def common_setup *args, &block
        create_options_storage

        options = args.extract_options!
        options.symbolize_keys!
        options[:association_name] = args.shift if args.first.kind_of? Symbol or args.first.kind_of? String
        setup_options! options
        super_sti_options[options[:association_name]] = {}
        super_sti_options[options[:association_name]][:options] = options.deep_dup

        setup_delegation options
        setup_inheritance unless superclass.respond_to? :super_sti_options
        
        options[:association_class].class_eval &block if block

        options
      end


      def create_options_storage
        class << self
          attr_reader :super_sti_options
          private
            attr_writer :super_sti_options
        end
        @super_sti_options ||= {}
      end

      def setup_options! options
        options[:autosave] ||= true 
        options[:dependent] ||= :destroy
        options[:association_name] ||= DEFAULT_AFFIX
        if options[:class_name].present?
          data_class = options[:class_name].safe_constantize
          data_class = create_data_class(options.slice :class_name, :table_name) if data_class.nil?
        else
          model_underscore = "#{self.name.underscore.gsub("/", "_")}_#{options[:association_name]}"
          fallback_class_name = ["super_s_t_i", model_underscore].join('/').classify
          data_class = fallback_class_name.safe_constantize
          data_class ||= model_underscore.classify.safe_constantize
          if data_class
            options[:class_name] = data_class.name
          elsif parent_class_name = options.delete(:parent_association_class) and parent_class_name.present?
            options[:class_name] = parent_class_name
            data_class = parent_class_name.constantize
          else
            options[:table_name] ||= model_underscore.pluralize
            options[:class_name] = fallback_class_name
            data_class = create_data_class(options.slice :class_name, :table_name)
          end
        end
        options[:association_class] = data_class
      end

      def create_data_class options={}
        klass = Class.new(ActiveRecord::Base) do
          self.table_name = options[:table_name]
        end
        namespace = options[:class_name].deconstantize.constantize
        const = options[:class_name].demodulize
        namespace.const_set const, klass
        klass
      end

      def setup_inheritance
        class << self
          def inherited subclass
            super
            self.super_sti_options.each do |key, options|
              sending_options = options[:options].except(:class_name, :table_name)
              if sending_options["inherit_#{DEFAULT_AFFIX}_type".to_sym] != false
                sending_options[:parent_association_class] = options[:options][:class_name]
                sending_options[:foreign_key] ||= self.name.foreign_key
              else
                #sending_options[:foreign_key] ||= subclass.name.foreign_key
                sending_options.except!(:foreign_key)
              end
              subclass.class_eval do
                undef_method("autosave_associated_records_for_#{key}")
                undef_method("validate_associated_records_for_#{key}")
              end

              subclass.send(options[:method], options[:association_name], sending_options)
            end
          end
        end
      end

      def setup_delegation options={}
        assoc_name = options[:association_name]
        before_create "get_#{assoc_name}"
        # A helper method which gets the existing data or builds a new object
        define_method "get_#{assoc_name}" do
          data = self.send(assoc_name).presence
          return data if data.present?
          return self.send("build_#{assoc_name}") if new_record?
          raise SuperSTI::DataMissingError
        end
        
        # Override respond_to? to check both this object and its data object.
        define_method "respond_to?" do |sym, include_private = false|
          begin
            super(sym, include_private) || self.send("get_#{assoc_name}").respond_to?(sym, include_private)
          rescue SuperSTI::DataMissingError
            false
          end
        end
        
        # Override method_missing to check both this object and it's data object for any methods or magic functionality.
        # Firstly, try the original method_missing because there may well be 
        # some magic piping that will return a result and then try the data object.
        define_method :method_missing do |sym, *args|
          begin
            super(sym, *args)
          rescue NoMethodError
            self.send("get_#{assoc_name}").send(sym, *args)
          end
        end

    end
  end
end
