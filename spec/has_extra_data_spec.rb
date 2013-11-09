require 'spec_helper'

describe "Super STI models with has_extra_data models" do
  
  before :each do 
    @bank = Bank.create!(:name => "My Bank")
    @bank_account = BankAccount.new
    @valid_bank_account_attributes = {:account_number => "12345678", :sort_code => "12 34 56", :bank => @bank}
  end
  
  it "uses default :data method to access association" do
    @bank_account.should respond_to :data
  end

  it "can have variables set" do
    @bank_account.account_number = "12345678"
    @bank_account.sort_code = "12 34 56"
    @bank_account.bank = @bank
    @bank_account.save!
    @bank_account.data.id.should_not == 0
  end
  
  it "creates data with the test class" do
    @bank_account.attributes = @valid_bank_account_attributes
    @bank_account.save!
    @bank_account.data.id.should_not == 0
  end

  it "can read attributes through association" do
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
    obj.data.should_not be_nil
  end
  
  it "can have any table name" do
    obj = UnusualTableName.create!
    obj.data.should_not be_nil
  end
  
  it "does not break scoped" do
    ba1 = BasicAccount.create!(:is_approved => true)
    ba2 = BasicAccount.create!(:is_approved => false)
    ba1.is_approved?.should == true
    ba2.is_approved?.should == false
    BasicAccount.approved.count.should == 1
  end
  
  it "correctly gets parent id, not data id" do
    ActiveRecord::Base.connection.execute("INSERT INTO basic_account_data('basic_account_id') VALUES (0)")
    ba = BasicAccount.create!
    ba.id.should_not == ba.data.id
    
    ba2 = BasicAccount.find(ba.id)
    ba2.id.should == ba.id
    ba2.data.id.should == ba.data.id
    ba2.id.should_not == ba2.data.id
    
    ba3 = Account.find(ba.id)
    ba3.id.should == ba.id
    ba3.data.id.should == ba.data.id
    ba3.id.should_not == ba3.data.id
  end
  
  it "if extra data is deleted, it still loads but can't load extra data" do
    ba = BankAccount.create!(@valid_bank_account_attributes)
    ActiveRecord::Base.connection.execute("DELETE FROM bank_account_data where id = #{ba.data.id}")
    
    ba2 = BankAccount.find(ba.id)
    ba2.id.should == ba.id
    ba2.data.should be_nil 
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
    it "uses its own data type unless parent has :inherit => {:class_name => true} " do
      class A < ActiveRecord::Base; has_extra_data; end
      class BData < ActiveRecord::Base; end
      class B < A; end

      B.super_sti_config[:data].should include("class_name" => "BData")
      b = B.create!
      b.data.class.should == BData
    end

    it "uses parent data type if its own one doesnt exist" do
      class A2 < ActiveRecord::Base; has_extra_data; end
      class B2 < A2; has_extra_data :foreign_key => :a2_id; end

      a2 = A2.create!
      a2.data.class.should == SuperSTI::A2Data

      B2.super_sti_config[:data].should include("class_name" => "SuperSTI::A2Data")
      b2 = B2.create!
      b2.data.class.should == SuperSTI::A2Data
    end

    it "uses its own data type if inherit :class_name set to false" do
      class A3 < ActiveRecord::Base; has_extra_data :inherit => {:class_name => false}; end
      class B3 < A3; end

      B3.super_sti_config[:data].should include("class_name" => "SuperSTI::B3Data")
      b3 = B3.create!
      b3.data.class.should == SuperSTI::B3Data
    end

    it "uses parent clas_name if :inherit => {:class_name => true} even if corresponded class exists" do
      class A4 < ActiveRecord::Base; has_extra_data :inherit => {:class_name => true}; end
      class B4Data < ActiveRecord::Base; end
      class B4 < A4; has_extra_data :foreign_key => :a4_id; end

      B4.super_sti_config[:data].should include("class_name" => "SuperSTI::A4Data")
      b4 = B4.create!
      b4.data.class.should == SuperSTI::A4Data
    end

    it "uses class_name explicitly set in subclass even if :inherit => {:class_name => true} set" do
      class A5 < ActiveRecord::Base; has_extra_data :inherit => {:class_name => true}; end
      class B5Data < ActiveRecord::Base; end
      class B5 < A5; has_extra_data :class_name => "B5Data"; end

      B5.super_sti_config[:data].should include("class_name" => "B5Data")
      b5 = B5.create!
      b5.data.class.should == B5Data
    end
  end


  describe "support several extra_data" do
    it "safely overrides existing relation" do
    end

    it "support method_missing on each of extra_data" do
    end

    it "support respond_to? on each of extra_data" do
    end

    it "creates each of extra_data subjects on base model creation" do
    end
  end
  
  
end