require 'rails_helper'

module Ddr::Batch
  RSpec.describe ProcessBatchObjects do
    let(:batch) { FactoryGirl.create(:item_adding_ingest_batch) }
    let(:pbos) { ProcessBatchObjects.new(batch_object_ids: [ batch.batch_objects[0].id, batch.batch_objects[1].id ], operator: batch.user) }

    describe "first object processes successfully" do
      before do
        allow(ProcessBatchObject).to receive(:new).with(batch_object_id: batch.batch_objects[0].id, operator: batch.user).and_call_original
        allow_any_instance_of(ProcessBatchObject).to receive(:execute) { true }
      end
      it "should process the second object" do
        expect(ProcessBatchObject).to receive(:new).with(batch_object_id: batch.batch_objects[1].id, operator: batch.user).and_call_original
        pbos.execute
      end
    end

    describe "first object does not process successfully" do
      before do
        allow(ProcessBatchObject).to receive(:new).with(batch_object_id: batch.batch_objects[0].id, operator: batch.user).and_call_original
        allow_any_instance_of(ProcessBatchObject).to receive(:execute) { false }
      end
      it "should not process the second object" do
        expect(ProcessBatchObject).to_not receive(:new).with(batch_object_id: batch.batch_objects[1].id, operator: batch.user)
        pbos.execute
      end
    end

  end
end
