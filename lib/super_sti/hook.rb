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
      options = args.extract_options!
      setup_options! options

      association_options = options.slice! :table_name
    end

    define_method "has_#{DEFAULT_AFFIX}" do |*args, &block|
      options = args.extract_options!
      create_options_storage
      options[:association_name] = args.shift if args.first.kind_of? Symbol or args.first.kind_of? String
      setup_options! options
      setup_delegation options
      setup_inheritance options
      
      association_name = options.delete :association_name
      options.delete :table_name
      klass = options.delete(:association_class)

      klass.class_eval &block if block
      # Add a reference to a data object that gets created when this is created
      has_one association_name, options
    end


    private
      def create_options_storage
        class << self
          attr_reader :super_sti_options
          private
            attr_writer :super_sti_options
        end
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
          options[:table_name] ||= model_underscore.pluralize
          fallback_class_name = ["super_s_t_i", model_underscore].join('/').classify
          data_class = fallback_class_name.safe_constantize
          data_class ||= model_underscore.classify.safe_constantize
          if data_class
            options[:class_name] = data_class.name
          else
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
      end

      def setup_inheritance options={}
        class << self
          def inherited subclass

          end
        end
      end

      def setup_delegation options={}
        before_create :get_data
        assoc_name = options[:association_name]
        # A helper method which gets the existing data or builds a new object
        define_method :get_data do
          data = self.send(assoc_name).presence
          return data if data.present?
          return self.send("build_#{assoc_name}") if new_record?
          raise SuperSTI::DataMissingError
        end
        
        # Override respond_to? to check both this object and its data object.
        define_method "respond_to?" do |sym, include_private = false|
          begin
            super(sym, include_private) || get_data.respond_to?(sym, include_private)
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
            get_data.send(sym, *args)
          end
        end

    end
  end
end
