module SuperSTI
  module Delegation
    def respond_to? *args
      return true if super
      self.class.super_sti_config.keys.detect do |key|
        begin
          __get_assoc(key).respond_to? key
        rescue SuperSTI::DataMissingError
          false
        end
      end.present?
    end

    def method_missing name, *args, &block
      begin
        super(name, *args, &block)
      rescue NoMethodError => e
        ref = nil
        self.class.super_sti_config.keys.each do |key| 
          sub = __get_assoc(key)
          if sub.respond_to? name
            ref = sub
            break
          end
        end
        raise e unless ref
        ref.send(name, *args, &block)
      end
    end

    private
      def __get_assoc assoc_name
        data = self.send(assoc_name).presence
        return data if data.present?
        return self.send("build_#{assoc_name}") if new_record?
        raise SuperSTI::DataMissingError
      end
  end
end