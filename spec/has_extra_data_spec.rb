require 'spec_helper'

describe 'Super STI models with has_extra_data models' do
  let(:bank) { Bank.create!(name: 'My Bank') }
  let(:bank_account) { BankAccount.new }
  let(:valid_bank_account_attributes) do
    { account_number: '12345678', sort_code: '12 34 56', bank: bank }
  end

  it 'uses default :data method to access association' do
    expect(bank_account).to respond_to(:data)
  end

  it 'can have variables set' do
    bank_account.account_number = '12345678'
    bank_account.sort_code = '12 34 56'
    bank_account.bank = bank
    bank_account.save!
    expect(bank_account.data.id).to_not be == 0
  end

  it 'creates data with the test class' do
    bank_account.attributes = valid_bank_account_attributes
    bank_account.save!
    expect(bank_account.data.id).to_not be == 0
  end

  it 'can read attributes through association' do
    bank_account.attributes = valid_bank_account_attributes
    bank_account.save!
    account = BankAccount.find(bank_account.id)
    expect(account.account_number).to be == valid_bank_account_attributes[:account_number]
  end

  it 'can read associations' do
    bank_account.attributes = valid_bank_account_attributes
    bank_account.save!
    account = BankAccount.find(bank_account.id)
    expect(account.bank).to be == bank
  end

  it 'can have a specifc foreign_key' do
    obj = UnusualForeignKey.create!
    obj.data
    obj.test_info
    expect(obj.data).to_not be_nil
  end

  it 'can have any table name' do
    obj = UnusualTableName.create!
    expect(obj.data).to_not be_nil
  end

  it 'does not break scoped' do
    ba1 = BasicAccount.create!(is_approved: true)
    ba2 = BasicAccount.create!(is_approved: false)
    expect(ba1.is_approved?).to be == true
    expect(ba2.is_approved?).to be == false
    expect(BasicAccount.approved.count).to be == 1
  end

  it 'correctly gets parent id, not data id' do
    ActiveRecord::Base.connection.execute("INSERT INTO basic_account_data('basic_account_id') VALUES (0)")
    ba = BasicAccount.create!
    expect(ba.id).to_not be == ba.data.id

    ba2 = BasicAccount.find(ba.id)
    expect(ba2.id).to be == ba.id
    expect(ba2.data.id).to be == ba.data.id
    expect(ba2.id).to_not be == ba2.data.id

    ba3 = Account.find(ba.id)
    expect(ba3.id).to be == ba.id
    expect(ba3.data.id).to be == ba.data.id
    expect(ba3.id).to_not be == ba3.data.id
  end

  it "if extra data is deleted, it still loads but can't load extra data" do
    ba = BankAccount.create!(valid_bank_account_attributes)
    ActiveRecord::Base.connection.execute("DELETE FROM bank_account_data where id = #{ba.data.id}")

    ba2 = BankAccount.find(ba.id)
    expect(ba2.id).to be == ba.id
    expect(ba2.data).to be_nil
    expect { ba2.bank_id }.to raise_error(SuperSTI::DataMissingError)
  end

  it 'saves data on updates' do
    # Setup normal bank account
    bank_account.attributes = valid_bank_account_attributes
    bank_account.save!
    expect(bank_account.account_number).to be == '12345678'

    # Update attribute
    bank_account.account_number = '87654321'
    bank_account.save!

    # Check the database has been updated
    expect(BankAccount.find(bank_account.id).account_number).to be == '87654321'
  end

  describe 'inheritance of classes with has_one' do
    it 'uses its own data type unless parent has :inherit => {:class_name => true} ' do
      class A < ActiveRecord::Base; has_extra_data; end
      class BData < ActiveRecord::Base; end
      class B < A; end

      expect(B.super_sti_config[:data]).to include('class_name' => 'BData')
      b = B.create!
      expect(b.data.class).to be == BData
    end

    it 'uses parent data type if its own one doesnt exist' do
      class A2 < ActiveRecord::Base; has_extra_data; end
      class B2 < A2; has_extra_data foreign_key: :a2_id; end

      a2 = A2.create!
      expect(a2.data.class).to be == SuperSTI::A2Data

      expect(B2.super_sti_config[:data]).to include('class_name' => 'SuperSTI::A2Data')
      b2 = B2.create!
      expect(b2.data.class).to be == SuperSTI::A2Data
    end

    it 'uses its own data type if inherit :class_name set to false' do
      class A3 < ActiveRecord::Base; has_extra_data inherit: { class_name: false }; end
      class B3 < A3; end

      expect(B3.super_sti_config[:data]).to include('class_name' => 'SuperSTI::B3Data')
      b3 = B3.create!
      expect(b3.data.class).to be == SuperSTI::B3Data
    end

    it 'uses parent class_name if :inherit => {:class_name => true} even if corresponded class exists' do
      class A4 < ActiveRecord::Base; has_extra_data inherit: { class_name: true }; end
      class B4Data < ActiveRecord::Base; end
      class B4 < A4; has_extra_data foreign_key: :a4_id; end

      expect(B4.super_sti_config[:data]).to include('class_name' => 'SuperSTI::A4Data')
      b4 = B4.create!
      expect(b4.data.class).to be == SuperSTI::A4Data
    end

    it 'uses class_name explicitly set in subclass even if :inherit => {:class_name => true} set' do
      class A5 < ActiveRecord::Base; has_extra_data inherit: { class_name: true }; end
      class B5Data < ActiveRecord::Base; end
      class B5 < A5; has_extra_data class_name: 'B5Data'; end

      expect(B5.super_sti_config[:data]).to include('class_name' => 'B5Data')
      b5 = B5.create!
      expect(b5.data.class).to be == B5Data
    end
  end

  describe 'support several extra_data' do
    before :all do
      class N < ActiveRecord::Base
        self.table_name = 'as'
        has_extra_data :data, table_name: 'b_data', foreign_key: 'b_id'
        has_extra_data :data2, table_name: 'a2_data', foreign_key: 'a2_id'
      end
    end

    xit 'safely overrides existing relation' do
    end

    it 'support method_missing on each of extra_data' do
      a = N.create!
      expect(a.b_id).to eq(a.id)
      expect(a.a2_id).to eq(a.id)
    end

    it 'support respond_to? on each of extra_data' do
      a = N.create!
      expect(a).to respond_to(:b_id)
      expect(a).to respond_to(:a2_id)
    end

    xit 'creates each of extra_data subjects on base model creation' do
    end
  end
end
