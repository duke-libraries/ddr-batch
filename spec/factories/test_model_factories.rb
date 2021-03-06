class TestModel < Ddr::Models::Base
end

class TestContent < TestModel
  include Ddr::Models::HasContent
end

class TestParent < TestModel
  include Ddr::Models::HasChildren
  has_many :children, property: :is_part_of, class_name: 'TestChild'
end

class TestChild < TestModel
  belongs_to :parent, property: :is_part_of, class_name: 'TestParent'
end

class TestModelOmnibus < TestModel
  include Ddr::Models::Governable
  include Ddr::Models::HasContent
  include Ddr::Models::HasAttachments
  has_many :children, property: :is_part_of, class_name: 'TestChild'
  belongs_to :parent, property: :is_part_of, class_name: 'TestParent'
end

FactoryGirl.define do

  factory :test_model do
    title [ "Ddr Test Object" ]
    sequence(:identifier) { |n| [ "test%05d" % n ] }
  end

  factory :test_parent do
    title [ "Ddr Test Parent Object" ]
    sequence(:identifier) { |n| [ "testparent%05d" % n ] }

    factory :test_parent_has_children do
      transient do
        child_count 3
      end
      after(:create) do |parent, evaluator|
        FactoryGirl.create_list(:test_child, evaluator.child_count, :parent => parent)
      end
    end
  end

  factory :test_child do
    title [ "Ddr Test Child Object" ]
    sequence(:identifier) { |n| [ "testchild%05d" % n ] }

    factory :test_child_has_parent do
      association :parent, :factory => :test_parent
    end
  end

  factory :test_content do
    title [ "Ddr Test Content Object" ]
    sequence(:identifier) { |n| [ "testcontent%05d" % n ] }
    after(:build) do |c|
      c.upload File.new(File.join(Rails.root, "spec", "fixtures", "imageA.tif"))
    end

    factory :test_content_with_fixity_check do
      after(:create) { |c| c.fixity_check! }
    end
  end

  factory :test_model_omnibus do
    title [ "Ddr Test Omnibus Object" ]
    sequence(:identifier) { |n| [ "test%05d" % n ] }
    after(:build) do |c|
      c.upload File.new(File.join(Rails.root, "spec", "fixtures", "imageA.tif"))
    end
  end

end

