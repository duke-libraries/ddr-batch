require 'rails_helper'

module Ddr::Batch
  RSpec.describe ProcessBatch do
    let(:pb) { described_class.new(batch_id: batch.id, operator_id: batch.user.id) }

    describe "notifications" do
      let(:batch) { FactoryGirl.create(:batch) }
      it "should issue a 'batch started' notification" do
        expect(ActiveSupport::Notifications).to receive(:instrument).with("started.batch.batch.ddr", batch_id: batch.id)
        pb.execute
      end
    end

    describe "ingest batch" do
      context "collection creating" do
        let(:batch) { FactoryGirl.create(:collection_creating_ingest_batch) }
        it "should call the appropriate methods" do
          expect(pb).to receive(:ingest_collection_object).with(batch.batch_objects[0])
          expect(Resque).to receive(:enqueue).with(BatchObjectsProcessorJob, [ batch.batch_objects[1].id, batch.batch_objects[2].id ], batch.user.id)
          expect(Resque).to receive(:enqueue).with(BatchObjectsProcessorJob, [ batch.batch_objects[3].id, batch.batch_objects[4].id, batch.batch_objects[5].id ], batch.user.id)
          expect(Resque).to receive(:enqueue).with(BatchObjectsProcessorJob, [ batch.batch_objects[6].id ], batch.user.id)
          expect(Resque).to receive(:enqueue).with(BatchObjectsProcessorJob, [ batch.batch_objects[7].id ], batch.user.id)
          pb.execute
        end
        describe "collection creation failure" do
          before do
            allow(ActiveSupport::Notifications).to receive(:instrument).with("started.batch.batch.ddr", batch_id: batch.id)
            pbo = ProcessBatchObject.new(batch_object_id: batch.batch_objects[0].id, operator: User.find(batch.user.id))
            allow(ProcessBatchObject).to receive(:new).and_call_original
            allow(ProcessBatchObject).to receive(:new).with(batch_object_id: batch.batch_objects[0].id, operator: User.find(batch.user.id)) { pbo }
            allow(pbo).to receive(:execute) { false }
          end
          it "should issue a 'batch finished' notification and raise an exception" do
            expect(ActiveSupport::Notifications).to receive(:instrument).with("finished.batch.batch.ddr", batch_id: batch.id)
            expect { pb.execute }.to raise_error(Ddr::Batch::BatchObjectProcessingError)
          end
        end
      end
      context "item adding" do
        let(:batch) { FactoryGirl.create(:item_adding_ingest_batch) }
        it "should call the appropriate methods" do
          expect(pb).to_not receive(:ingest_collection_object)
          expect(Resque).to receive(:enqueue).with(BatchObjectsProcessorJob, [ batch.batch_objects[0].id, batch.batch_objects[1].id ], batch.user.id)
          expect(Resque).to receive(:enqueue).with(BatchObjectsProcessorJob, [ batch.batch_objects[2].id, batch.batch_objects[3].id, batch.batch_objects[4].id ], batch.user.id)
          expect(Resque).to receive(:enqueue).with(BatchObjectsProcessorJob, [ batch.batch_objects[5].id ], batch.user.id)
          expect(Resque).to receive(:enqueue).with(BatchObjectsProcessorJob, [ batch.batch_objects[6].id ], batch.user.id)
          pb.execute
        end
      end
    end

    describe "update batch" do
      let(:batch) { FactoryGirl.create(:item_update_batch) }
      it "should call the appropriate methods" do
        expect(Resque).to receive(:enqueue).with(BatchObjectsProcessorJob, [ batch.batch_objects[0].id ], batch.user.id)
        expect(Resque).to receive(:enqueue).with(BatchObjectsProcessorJob, [ batch.batch_objects[1].id ], batch.user.id)
        expect(Resque).to receive(:enqueue).with(BatchObjectsProcessorJob, [ batch.batch_objects[2].id ], batch.user.id)
        pb.execute
      end
    end
  end
end
