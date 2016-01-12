require 'rails_helper'

module Ddr::Batch

  shared_examples "an invalid batch object attribute object" do
    before { object.valid? }
    it "shouild report the appropriate error" do
      expect(object.errors.keys).to include(error_key)
    end
  end

  RSpec.describe BatchObjectAttribute, type: :model, batch: true do

    describe "validation" do
      let(:batch_object) { BatchObject.new(model: 'TestModel') }
      context "invalid" do
        context "datastream" do
          let(:error_key) { :datastream }
          let(:object) { BatchObjectAttribute.new(batch_object: batch_object, datastream: 'foo', name: 'bar') }
          it_should_behave_like 'an invalid batch object attribute object'
        end
        context "name" do
          let(:error_key) { :name }
          let(:object) { BatchObjectAttribute.new(batch_object: batch_object, datastream: 'descMetadata', name: 'bar') }
          it_should_behave_like 'an invalid batch object attribute object'
        end
        context "operation" do
          context "clear all" do
            context "descMetadata datastream" do
              let(:object) { BatchObjectAttribute.new(batch_object: batch_object,
                                                      datastream: 'descMetadata',
                                                      operation: BatchObjectAttribute::OPERATION_CLEAR_ALL)
                           }
              it "should be valid" do
                expect(object.valid?).to be_truthy
              end
            end
            context "adminMetadata datastream" do
              let(:error_key) { :operation }
              let(:object) { BatchObjectAttribute.new(batch_object: batch_object,
                                                      datastream: 'adminMetadata',
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