require 'rails_helper'

module Ddr::Batch

  describe Batch, type: :model, batch: true do

    let(:batch) { FactoryGirl.create(:batch_with_basic_ingest_batch_objects) }

    context "completed count" do
      before { batch.batch_objects.first.update_attributes(handled: true) }
      it "should return the number of handled batch objects" do
        expect(batch.handled_count).to eq(1)
      end
    end

    context "time to complete" do
      before do
        batch.batch_objects.first.update_attributes(handled: true)
        batch.update_attributes(start: DateTime.now - 5.minutes)
      end
      it "should estimate the time to complete processing" do
        expect(batch.time_to_complete).to be_within(3).of(600)
      end
    end

    context "destroy" do
      before do
        batch.user.destroy
        batch.destroy
      end
      it "should destroy all the associated dependent objects" do
        expect(Batch.all).to be_empty
        expect(BatchObject.all).to be_empty
        expect(BatchObjectAttribute.all).to be_empty
        expect(BatchObjectDatastream.all).to be_empty
        expect(BatchObjectRelationship.all).to be_empty
        expect(BatchObjectRole.all).to be_empty
      end
    end

    describe "#deletable?" do
      it "should determine if the batch is deletable" do
        expect(Ddr::Batch::Batch.new).to be_deletable
        expect(Ddr::Batch::Batch.new(status: Ddr::Batch::Batch::STATUS_DELETING)).to_not be_deletable
        expect(Ddr::Batch::Batch.new(status: Ddr::Batch::Batch::STATUS_FINISHED)).to_not be_deletable
        expect(Ddr::Batch::Batch.new(status: Ddr::Batch::Batch::STATUS_INTERRUPTED)).to_not be_deletable
        expect(Ddr::Batch::Batch.new(status: Ddr::Batch::Batch::STATUS_INVALID)).to be_deletable
        expect(Ddr::Batch::Batch.new(status: Ddr::Batch::Batch::STATUS_PROCESSING)).to_not be_deletable
        expect(Ddr::Batch::Batch.new(status: Ddr::Batch::Batch::STATUS_QUEUED)).to_not be_deletable
        expect(Ddr::Batch::Batch.new(status: Ddr::Batch::Batch::STATUS_QUEUED_FOR_DELETION)).to_not be_deletable
        expect(Ddr::Batch::Batch.new(status: Ddr::Batch::Batch::STATUS_READY)).to be_deletable
        expect(Ddr::Batch::Batch.new(status: Ddr::Batch::Batch::STATUS_RESTARTABLE)).to_not be_deletable
        expect(Ddr::Batch::Batch.new(status: Ddr::Batch::Batch::STATUS_RUNNING)).to_not be_deletable
        expect(Ddr::Batch::Batch.new(status: Ddr::Batch::Batch::STATUS_VALIDATED)).to be_deletable
        expect(Ddr::Batch::Batch.new(status: Ddr::Batch::Batch::STATUS_VALIDATING)).to_not be_deletable
      end
    end
  end

end
