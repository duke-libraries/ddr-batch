require 'rails_helper'

module Ddr::Batch

  shared_examples "a valid batch object role object" do
    before { batch_object_role.valid? }
    it "should not report error" do
      expect(batch_object_role.errors).to be_empty
    end
  end

  shared_examples "an invalid batch object role object" do
    before { batch_object_role.valid? }
    it "should report the appropriate error" do
      expect(batch_object_role.errors.keys).to include(error_key)
    end
  end

  RSpec.describe BatchObjectRole, type: :model, batch: true do

    describe "validation" do
      describe "add operation" do
        let(:batch_object_role) { BatchObjectRole.new(batch_object: batch_object, operation: BatchObjectRole::OPERATION_ADD,
                                                      agent: 'test@test.com', role_type: Ddr::Auth::Roles::RoleTypes::EDITOR.title,
                                                      role_scope: role_scope) }
        describe "scope" do
          let(:error_key) { :role_scope }
          describe "policy" do
            let(:role_scope) { Ddr::Auth::Roles::POLICY_SCOPE }
            describe "collection batch object" do
              let(:batch_object) { BatchObject.new(model: 'Collection') }
              it_should_behave_like 'a valid batch object role object'
            end
            describe "non-collection batch object" do
              let(:batch_object) { BatchObject.new(model: 'TestModel') }
              it_should_behave_like 'an invalid batch object role object'
            end
          end
        end
      end
    end

  end
end
