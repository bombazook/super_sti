module SuperSTI
  module Inheritance
    def inherited(subclass)
      super
      super_sti_config.each do |key, options|
        subclass.send(options.sti_method, key)
      end
    end
  end
end
