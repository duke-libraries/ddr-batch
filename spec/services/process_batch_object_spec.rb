require 'rails_helper'

module Ddr::Batch
  RSpec.describe ProcessBatchObject do
    let(:batch) { FactoryGirl.create(:item_update_batch) }
    let(:batch_object) { batch.batch_objects.first }
    let(:pbo) { described_class.new(batch_object_id: batch_object.id, operator: batch.user) }

    describe "notifications" do
      it "should issue a 'batch object handled' notification" do
        expect(ActiveSupport::Notifications).to receive(:instrument).with("handled.batchobject.batch.ddr",
                                                                          batch_object_id: batch_object.id)
        pbo.execute
      end
    end

    describe "execution" do
      before do
        allow(BatchObject).to receive(:find).with(batch_object.id) { batch_object }
        allow(batch_object).to receive(:results_message) {
          Ddr::Batch::BatchObject::ProcessingResultsMessage.new(Logger::INFO, "Test message")
        }
      end

      describe "valid object" do
        before { allow(batch_object).to receive(:validate) { [] } }
        describe "messages" do
          before { allow(batch_object).to receive(:process) { } }
          it "should add appropriate messages" do
            pbo.execute
            expect(batch_object.batch_object_messages[0].level).to eq(Logger::INFO)
            expect(batch_object.batch_object_messages[0].message).to eq("Test message")
          end
        end
        describe "processing" do
          it "should process the object, mark it as handled, and return true" do
            expect(batch_object).to receive(:process) { }
            success = pbo.execute
            expect(batch_object.handled?).to be(true)
            expect(success).to be(true)
          end
        end
      end

      describe "invalid object" do
        before { allow(batch_object).to receive(:validate) { [ "Validation message" ] } }
        describe "messages" do
          it "should add appropriate messages" do
            pbo.execute
            expect(batch_object.batch_object_messages[0].level).to eq(Logger::ERROR)
            expect(batch_object.batch_object_messages[0].message).to eq("Validation message")
          end
        end
        describe "processing" do
          it "should not process the object but mark it as handled and return false" do
            expect(batch_object).to_not receive(:process)
            success = pbo.execute
            expect(batch_object.handled?).to be(true)
            expect(success).to be(false)
          end

        end
      end

    end

  end
end
