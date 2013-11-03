require 'spec_helper'

describe SuperSTI do
  before :all do
    class WithClassNameProperty < StiBase
      belongs_to_extra_data :class_name => "Data1"
    end
    class WithClassNamePropertyAndAssociationName < StiBase
      belongs_to_extra_data :data1, :class_name => "Data2"
    end
  end

  it "adds :data_type or :<association_name>_type if any association given" do
    WithClassNameProperty.create.data_type.should_not be_nil
    WithClassNamePropertyAndAssociationName.create.data1_type.should_not be_nil
    WithClassNamePropertyAndAssociationName.__data_type__.name.should == WithClassNamePropertyAndAssociationName.create.data1_type
  end

  describe "belongs_to_extra_data" do

    it "uses :table_name if create data class" do
      class WithClassNamePropertyNotFoundAndTableName < StiBase
        belongs_to_extra_data :class_name => "AutoCreateData2", :table_name => "auto_create_datas"
      end
      obj = WithClassNamePropertyNotFoundAndTableName.create
      obj.data_type.should == "SuperSTI::AutoCreateData2"
      WithClassNamePropertyNotFoundAndTableName.__data_type__.table_name.should == "auto_create_datas"
    end

    it "uses by default :foreign_key 'data_id' with no association_name given" do
      obj = WithClassNameProperty.create
      obj.reflections[:data].foreign_key.should == "data_id"
    end
    it "uses [association_name, 'id'].join('_') for foreign_key and association_name for association if association name given" do
      obj = WithClassNamePropertyAndAssociationName.create
      obj.reflections[:data1].foreign_key.should == "data1_id"
    end
    it "uses :foreign_key option if given" do
      class WithClassNamePropertyAndAssociationNameAndForeignKey < StiBase
        belongs_to_extra_data :data1, :class_name => "Data2", :foreign_key => :other_id
      end
      obj = WithClassNamePropertyAndAssociationNameAndForeignKey.create
      obj.reflections[:data].foreign_key.should == "other_id"
    end

    describe "default data classes and naming" do

      it "uses data class from :class_name property" do
        obj = WithClassNameProperty.create
        obj.reflections[:data].association.should == Data1
      end

      it "creates SuperSTI::(class_name) if :class_name property given but no class with such name found" do
        obj = WithClassNamePropertyNotFound.create
        obj.data_type.should == "SuperSTI::AutoCreateData"
      end

      it "uses data class SuperSTI::(association_name.singularize.classify) for data if no :class_name given" do
        class WithExistingAssociationName < StiBase
          belongs_to_extra_data :data3
        end
        obj = WithExistingAssociationName.create
        obj.data3_type.should == "SuperSTI::Data3"
      end

      it "uses data class (association_name.singularize.classify) if if no :class_name given and not found in SuperSTI namespace" do
        class WithExistingInRootAssociationName < StiBase
          belongs_to_extra_data :data2
        end
        obj = WithExistingInRootAssociationName.create
        obj.root_data_type.should == "ExistingInRootDataName"
      end

      it "creates SuperSTI::(association_name.singularize.classify) if association name given but no class with such name found" do
        class WithNonExistingAssociationName < StiBase
          belongs_to_extra_data :non_existing_data
        end
        obj = WithNonExistingAssociationName.create
        obj.non_existing_data_type.should == "SuperSTI::NonExistingData"
      end

      it "uses SuperSTI::([self.name, 'data'].join('_').classify) for data if no association nor :class_name given" do
        class WithNameOfSelf < StiBase
          belongs_to_extra_data
        end
        obj = WithNameOfSelf.create
        obj.data_type.should == "SuperSTI::WithNameOfSelfData"
      end

      it "uses [self.name, 'data'].join('_').classify) for data if if no association nor :class_name and not found in SuperSTI namespace" do
        class WithNameOfSelfInRoot < StiBase
          belongs_to_extra_data
        end
        obj = WithNameOfSelfInRoot.create
        obj.data_type.should == "WithNameOfSelfInRootData"
      end

      it "creates SuperSTI::([self.name, 'data'].join('_').classify) class with no table if no association name nor :class_name given" do
        class WithNonExistingNameOfSelf < StiBase
        end
        obj = WithNonExistingNameOfSelf.create
        obj.data_type.should == "SuperSTI::WithNonExistingNameOfSelfData"
      end
    end

    describe "inheritance" do
      xit "use same data class, foreign_key and relation by default" do
        
      end

      it "doesnt inherit data class if :inherit_data set to `false`" do
        class InheritClass < WithInheritDataFalse
        end
        expect{InheritClass.__data_type__}.to_not == klass.__data_type__
      end

      it "doesnt inherit belongs_to_extra_data if :inherit_relation set to `false`" do
        class InheritClass < WithInheritRelationFalse
        end
        expect{InheritClass.__data_type__}.to raise_exception
      end
    end

    describe "polymorphic datas" do
      xit "should use same rules for default data class creation as simple belongs_to_extra_data" do
      end

      xit "should be able to set data to another classes items" do
      end
    end
  end
end