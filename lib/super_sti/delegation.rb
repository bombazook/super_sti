module SuperSTI
  module Delegation
    def respond_to_missing?(*args)
      super || self.class.super_sti_config.keys.detect do |key|
        begin
          __get_assoc(key).respond_to? *args
        rescue SuperSTI::DataMissingError
          false
        end
      end
    end

    def method_missing(*args, &block)
      ref = nil
      self.class.super_sti_config.keys.each do |key|
        s = __get_assoc(key)
        if s.respond_to? *args
          ref = s
          break
        end
      end
      if ref
        ref.send(*args, &block)
      else
        super
      end
    end

    private

    def __get_assoc(assoc_name)
      data = send(assoc_name)
      return data if data.present?
      return send("build_#{assoc_name}") if new_record?

      raise SuperSTI::DataMissingError
    end
  end
end
