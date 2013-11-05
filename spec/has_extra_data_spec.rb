require 'spec_helper'

describe "Super STI models with has_extra_data models" do
  
  before :each do 
    @bank = Bank.create!(:name => "My Bank")
    @bank_account = BankAccount.new
    @valid_bank_account_attributes = {:account_number => "12345678", :sort_code => "12 34 56", :bank => @bank}
  end
  
  it "have the #{SuperSTI::Hook::DEFAULT_AFFIX} method" do
    @bank_account.should respond_to(SuperSTI::Hook::DEFAULT_AFFIX)
  end

  it "can have variables set" do
    @bank_account.account_number = "12345678"
    @bank_account.sort_code = "12 34 56"
    @bank_account.bank = @bank
    @bank_account.save!
    @bank_account.send(SuperSTI::Hook::DEFAULT_AFFIX).id.should_not == 0
  end
  
  it "creates #{SuperSTI::Hook::DEFAULT_AFFIX} with the test class" do
    @bank_account.attributes = @valid_bank_account_attributes
    @bank_account.save!
    @bank_account.send(SuperSTI::Hook::DEFAULT_AFFIX).id.should_not == 0
  end

  it "can read attributes" do
    @bank_account.attributes = @valid_bank_account_attributes
    @bank_account.save!
    @bank_account = BankAccount.find(@bank_account.id)
    @bank_account.account_number.should == "12345678"
  end
  
  it "can read associations" do
    @bank_account.attributes = @valid_bank_account_attributes
    @bank_account.save!
    @bank_account = BankAccount.find(@bank_account.id)
    @bank_account.bank.should == @bank
  end
  
  it "can have a specifc foreign_key" do
    obj = UnusualForeignKey.create!
    obj.send(SuperSTI::Hook::DEFAULT_AFFIX).should_not be_nil
  end
  
  it "can have any table name" do
    obj = UnusualTableName.create!
    obj.send(SuperSTI::Hook::DEFAULT_AFFIX).should_not be_nil
  end
  
  it "does not break scoped" do
    ba1 = BasicAccount.create!(:is_approved => true)
    ba2 = BasicAccount.create!(:is_approved => false)
    ba1.is_approved?.should == true
    ba2.is_approved?.should == false
    BasicAccount.approved.count.should == 1
  end
  
  it "correctly gets parent id, not data id" do
    ActiveRecord::Base.connection.execute("INSERT INTO basic_account_#{SuperSTI::Hook::DEFAULT_AFFIX.to_s.pluralize}('basic_account_id') VALUES (0)")
    ba = BasicAccount.create!
    ba.id.should_not == ba.send(SuperSTI::Hook::DEFAULT_AFFIX).id
    
    ba2 = BasicAccount.find(ba.id)
    ba2.id.should == ba.id
    ba2.send(SuperSTI::Hook::DEFAULT_AFFIX).id.should == ba.send(SuperSTI::Hook::DEFAULT_AFFIX).id
    ba2.id.should_not == ba2.send(SuperSTI::Hook::DEFAULT_AFFIX).id
    
    ba3 = Account.find(ba.id)
    ba3.id.should == ba.id
    ba3.send(SuperSTI::Hook::DEFAULT_AFFIX).id.should == ba.send(SuperSTI::Hook::DEFAULT_AFFIX).id
    ba3.id.should_not == ba3.send(SuperSTI::Hook::DEFAULT_AFFIX).id
  end
  
  it "if extra data is deleted, it still loads but can't load extra data" do
    ba = BankAccount.create!(@valid_bank_account_attributes)
    ActiveRecord::Base.connection.execute("DELETE FROM bank_account_#{SuperSTI::Hook::DEFAULT_AFFIX.to_s.pluralize} where id = #{ba.send(SuperSTI::Hook::DEFAULT_AFFIX.to_s).id}")
    
    ba2 = BankAccount.find(ba.id)
    ba2.id.should == ba.id
    ba2.send(SuperSTI::Hook::DEFAULT_AFFIX).should be_nil 
    lambda{ba2.bank_id}.should raise_error(SuperSTI::DataMissingError)
  end
  
  it "saves data on updates" do
    # Setup normal bank account
    @bank_account.attributes = @valid_bank_account_attributes
    @bank_account.save!
    @bank_account.account_number.should == "12345678"
    
    # Update attribute
    @bank_account.account_number = "87654321"
    @bank_account.save!
    
    # Check the database has been updated
    BankAccount.find(@bank_account.id).account_number.should == "87654321"
  end


  describe "inheritance of classes with has_one" do
    it "inherit relation and subject when no corresponded subject model" do
      #raise ExtendedBasicAccount.super_sti_options.inspect
      account = ExtendedBasicAccount.create
      superclass_account = BasicAccount.create
      account.send(SuperSTI::Hook::DEFAULT_AFFIX).class.should == superclass_account.send(SuperSTI::Hook::DEFAULT_AFFIX).class
    end

    it "use corresponded relation if exists" do
      account = ExtendedBasicAccountWithOtherData.create
      account.send(SuperSTI::Hook::DEFAULT_AFFIX).class.should == ExtendedBasicAccountWithOtherDataSubject
    end

    it "forcefully create non existed subject class if declared :inherit_subject_type => false on parent relation" do
      account = InheritedAccountWithOtherData.create
      superclass_account = ExtendedBasicAccountWithoutSubjectInheritance.create
      superclass_account.subject.class.should == SuperSTI::ExtendedBasicAccountWithoutSubjectInheritanceSubject
      account.send(SuperSTI::Hook::DEFAULT_AFFIX).class.should_not == superclass_account.send(SuperSTI::Hook::DEFAULT_AFFIX).class
      #raise InheritedAccountWithOtherData.reflections.inspect
    end

  end
  
  
end