require 'spec_helper'

describe SuperSTI do
  before :all do
    class WithClassNameProperty < StiBase
      belongs_to_subject :class_name => "Subject1"
    end
    class WithClassNamePropertyAndAssociationName < StiBase
      belongs_to_subject :subject1, :class_name => "Subject2"
    end
  end

  it "adds :subject_type or :<association_name>_type if any association given" do
    WithClassNameProperty.create.subject_type.should_not be_nil
    WithClassNamePropertyAndAssociationName.create.subject1_type.should_not be_nil
    WithClassNamePropertyAndAssociationName.__subject_type__.name.should == WithClassNamePropertyAndAssociationName.create.subject1_type
  end

  describe "belongs_to_subject" do

    it "uses :table_name if create subject class" do
      class WithClassNamePropertyNotFoundAndTableName < StiBase
        belongs_to_subject :class_name => "AutoCreateSubject2", :table_name => "auto_create_subjects"
      end
      obj = WithClassNamePropertyNotFoundAndTableName.create
      obj.subject_type.should == "SuperSTI::AutoCreateSubject2"
      WithClassNamePropertyNotFoundAndTableName.__subject_type__.table_name.should == "auto_create_subjects"
    end

    it "uses by default :foreign_key 'subject_id' with no association_name given" do
      obj = WithClassNameProperty.create
      obj.reflections[:subject].foreign_key.should == "subject_id"
    end
    it "uses [association_name, 'id'].join('_') for foreign_key and association_name for association if association name given" do
      obj = WithClassNamePropertyAndAssociationName.create
      obj.reflections[:subject1].foreign_key.should == "subject1_id"
    end
    it "uses :foreign_key option if given" do
      class WithClassNamePropertyAndAssociationNameAndForeignKey < StiBase
        belongs_to_subject :subject1, :class_name => "Subject2", :foreign_key => :other_id
      end
      obj = WithClassNamePropertyAndAssociationNameAndForeignKey.create
      obj.reflections[:subject].foreign_key.should == "other_id"
    end

    describe "default subject classes and naming" do

      it "uses subject class from :class_name property" do
        obj = WithClassNameProperty.create
        obj.reflections[:subject].association.should == Subject1
      end

      it "creates SuperSTI::(class_name) if :class_name property given but no class with such name found" do
        obj = WithClassNamePropertyNotFound.create
        obj.subject_type.should == "SuperSTI::AutoCreateSubject"
      end

      it "uses subject class SuperSTI::(association_name.singularize.classify) for subject if no :class_name given" do
        class WithExistingAssociationName < StiBase
          belongs_to_subject :subject3
        end
        obj = WithExistingAssociationName.create
        obj.subject3_type.should == "SuperSTI::Subject3"
      end

      it "uses subject class (association_name.singularize.classify) if if no :class_name given and not found in SuperSTI namespace" do
        class WithExistingInRootAssociationName < StiBase
          belongs_to_subject :subject2
        end
        obj = WithExistingInRootAssociationName.create
        obj.root_subject_type.should == "ExistingInRootSubjectName"
      end

      it "creates SuperSTI::(association_name.singularize.classify) if association name given but no class with such name found" do
        class WithNonExistingAssociationName < StiBase
          belongs_to_subject :non_existing_subject
        end
        obj = WithNonExistingAssociationName.create
        obj.non_existing_subject_type.should == "SuperSTI::NonExistingSubject"
      end

      it "uses SuperSTI::([self.name, 'subject'].join('_').classify) for subject if no association nor :class_name given" do
        class WithNameOfSelf < StiBase
          belongs_to_subject
        end
        obj = WithNameOfSelf.create
        obj.subject_type.should == "SuperSTI::WithNameOfSelfSubject"
      end

      it "uses [self.name, 'subject'].join('_').classify) for subject if if no association nor :class_name and not found in SuperSTI namespace" do
        class WithNameOfSelfInRoot < StiBase
          belongs_to_subject
        end
        obj = WithNameOfSelfInRoot.create
        obj.subject_type.should == "WithNameOfSelfInRootSubject"
      end

      it "creates SuperSTI::([self.name, 'subject'].join('_').classify) class with no table if no association name nor :class_name given" do
        class WithNonExistingNameOfSelf < StiBase
        end
        obj = WithNonExistingNameOfSelf.create
        obj.subject_type.should == "SuperSTI::WithNonExistingNameOfSelfSubject"
      end
    end

    describe "inheritance" do
      xit "use same subject class, foreign_key and relation by default" do
        
      end

      it "doesnt inherit subject class if :inherit_subject set to `false`" do
        class InheritClass < WithInheritSubjectFalse
        end
        expect{InheritClass.__subject_type__}.to_not == klass.__subject_type__
      end
    end

    describe "polymorphic subjects" do
      xit "should use same rules for default subject class creation as simple belongs_to_#{SuperSTI::Hook::DEFAULT_AFFIX}" do
      end

      xit "should be able to set subject to another classes items" do
      end
    end
  end
end