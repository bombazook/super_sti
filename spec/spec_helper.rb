ENV["RAILS_ENV"] ||= 'test'

require 'rails'
require 'rspec-rails'
require 'active_record'

$:.unshift File.dirname(__FILE__) + '/../lib'

# Thie first line isn't working so I have added the second...
require File.dirname(__FILE__) + '/../lib/super_sti'
ActiveRecord::Base.send(:extend, SuperSTI::Hook)
 
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
 
# AR keeps printing annoying schema statements
$stdout = StringIO.new

ActiveRecord::Base.logger
ActiveRecord::Schema.define(:version => 1) do
  create_table :accounts do |t|
    t.float :balance
    t.boolean :is_approved, :null => false
    t.string :type, :null => false
  end

  create_table :basic_account_data do |t|
    t.integer :basic_account_id, :null => false
  end
  
  create_table :bank_account_data do |t|
    t.integer :bank_account_id, :null => false
    t.integer :bank_id, :null => false
    t.string :account_number, :null => false
    t.string :sort_code, :null => false
  end

  create_table :credit_card_data do |t|
    t.integer :credit_card_id, :null => false
    t.string :credit_card_number, :null => false
    t.date :expiry_date, :null => false
  end

  create_table :banks do |t|
    t.string :name, :null => false
  end
  
  create_table :unusual_table_name do |t|
    t.integer :unusual_table_name_id, :null => false
  end

  create_table :unusual_foreign_key_data do |t|
    t.integer :unusual_foreign_key, :null => false
  end

  create_table :scoped_accounts do |t|
    t.boolean :is_live, :null => false
  end

  create_table :scoped_account_data do |t|
    t.boolean :scoped_account_id, :null => false
  end

  create_table :as do |t|
  end

  create_table :a2s do |t|
  end

  create_table :a3s do |t|
  end

  create_table :a4s do |t|
  end

  create_table :a5s do |t|
  end

  create_table :b_data do |t|
    t.integer :b_id
  end

  create_table :a2_data do |t|
    t.integer :a2_id
  end

  create_table :b3_data do |t|
    t.integer :b3_id
  end

  create_table :a4_data do |t|
    t.integer :a4_id
  end

  create_table :b5_data do |t|
    t.integer :b5_id
  end
end

require 'test_classes'