class Account < ActiveRecord::Base
  before_create :set_defaults

  scope :approved, -> { where(is_approved: true) }

  private

  def set_defaults
    self.balance = 0 unless balance
    self.is_approved = 0 unless is_approved
    true
  end
end

class BasicAccount < Account
  has_extra_data
end

class BankAccount < Account
  has_extra_data do
    belongs_to :bank
  end
end

class CreditCard < Account
  has_extra_data
end

class UnusualForeignKey < Account
  has_extra_data foreign_key: 'unusual_foreign_key'
end

class UnusualTableName < Account
  has_extra_data table_name: 'unusual_table_name'
end

class Bank < ActiveRecord::Base
  has_one :bank_account
end

# table_name doesnt work if using not autocreated class

# default inheritance without child data

# default inheritance with child data

# inheritance with child explicit no option inheritance

# inheritance with child inherit class_name to true and child data class exists

# removing inheritance from options behaviour with :default option

# # belongs_to Subjects
#
# class StiBaseSubject < ActiveRecord::Base
# end
#
# class Subject1 < ActiveRecord::Base
# end
#
# class Subject2 < ActiveRecord::Base
# end
#
# class SuperSTI::Subject3 < ActiveRecord::Base
# end
#
# class SuperSTI::WithNameOfSelfSubject < ActiveRecord::Base
# end
#
# class WithNameOfSelfInRootSubject < ActiveRecord::Base
# end
#
# class WithExistingInRootNameOfSelfInheritedSubject < ActiveRecord::Base
# end
#
# class SuperSTI::WithExistingNameOfSelfInherited < ActiveRecord::Base
# end
#
#
# belongs_to nodels
#
#
# class StiBase < ActiveRecord::Base
#   belongs_to_subject
# end
#
# class WithPolymorphicSubject < ActiveRecord::Base
#   belongs_to_subject :polymorphic => :true
# end
#
# class WithNonExistingNameOfSelf < ActiveRecord::Base
#   belongs_to_subject
# end
#
# class WithInheritSubjectFalse < ActiveRecord::Base
#   belongs_to_subject :inherit_subject_type => false
# end
#
