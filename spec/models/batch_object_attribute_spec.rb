require 'rails_helper'

module Ddr::Batch

  RSpec.shared_examples "an invalid batch object attribute object" do
    before { object.valid? }
    it "shouild report the appropriate error" do
      expect(object.errors.keys).to include(error_key)
    end
  end

  RSpec.describe BatchObjectAttribute, type: :model, batch: true do

    describe "validation" do
      let(:batch_object) { BatchObject.new(model: 'TestModel') }
      context "invalid" do
        context "metadata" do
          let(:error_key) { :metadata }
          let(:object) { BatchObjectAttribute.new(batch_object: batch_object, metadata: 'foo', name: 'bar') }
          it_should_behave_like 'an invalid batch object attribute object'
        end
        context "name" do
          let(:error_key) { :name }
          let(:object) { BatchObjectAttribute.new(batch_object: batch_object,
                                                  metadata: Ddr::Models::Metadata::DESC_METADATA, name: 'bar') }
          it_should_behave_like 'an invalid batch object attribute object'
        end
        context "operation" do
          context "clear all" do
            context "desc_metadata metadata" do
              let(:object) { BatchObjectAttribute.new(batch_object: batch_object,
                                                      metadata: Ddr::Models::Metadata::DESC_METADATA,
                                                      operation: BatchObjectAttribute::OPERATION_CLEAR_ALL)
                           }
              it "should be valid" do
                expect(object.valid?).to be_truthy
              end
            end
            context "admin_metadata metadata" do
              let(:error_key) { :operation }
              let(:object) { BatchObjectAttribute.new(batch_object: batch_object,
                                                      metadata: Ddr::Models::Metadata::ADMIN_METADATA,
                                                      operation: BatchObjectAttribute::OPERATION_CLEAR_ALL)
              }
              it_should_behave_like 'an invalid batch object attribute object'
            end
          end
        end
      end
    end

  end
end
