class Account < ActiveRecord::Base
  before_create :set_defaults
  
  scope :approved,  -> { where(:is_approved => true) }
  
private
  def set_defaults
    self.balance = 0 unless balance
    self.is_approved = 0 unless is_approved
    true
  end
end

class BasicAccount < Account
  has_subject
end

class BankAccount < Account
  has_subject do
    belongs_to :bank
  end
end

class CreditCard < Account
  has_subject
end

class UnusualForeignKey < Account
  has_subject :foreign_key => "unusual_foreign_key"
end

class UnusualTableName < Account
  has_subject :table_name => "unusual_table_name"
end

class Bank < ActiveRecord::Base
  has_one :bank_account
end

class ExtendedBasicAccount < BasicAccount
end

class ExtendedBasicAccountWithOtherDataSubject < ActiveRecord::Base
end

class ExtendedBasicAccountWithOtherData < BasicAccount
end

class ExtendedBasicAccountWithoutSubjectInheritance < ActiveRecord::Base
  has_subject :inherit_subject_type => false, :foreign_key => :basic_account_id
end

class InheritedAccountWithOtherData < ExtendedBasicAccountWithoutSubjectInheritance
end

# belongs_to Subjects

class StiBaseSubject < ActiveRecord::Base
end

class Subject1 < ActiveRecord::Base
end

class Subject2 < ActiveRecord::Base
end

class SuperSTI::Subject3 < ActiveRecord::Base
end

class SuperSTI::WithNameOfSelfSubject < ActiveRecord::Base
end

class WithNameOfSelfInRootSubject < ActiveRecord::Base
end

class WithExistingInRootNameOfSelfInheritedSubject < ActiveRecord::Base
end

class SuperSTI::WithExistingNameOfSelfInherited < ActiveRecord::Base
end


# belongs_to nodels


class StiBase < ActiveRecord::Base
  belongs_to_subject
end

class WithPolymorphicSubject < ActiveRecord::Base
  belongs_to_subject :polymorphic => :true
end

class WithNonExistingNameOfSelf < ActiveRecord::Base
  belongs_to_subject
end

class WithInheritSubjectFalse < ActiveRecord::Base
  belongs_to_subject :inherit_subject_type => false
end
