require 'rails_helper'

module Ddr::Batch

  RSpec.describe Batch, type: :model, batch: true do

    let(:batch) { FactoryGirl.create(:batch_with_basic_ingest_batch_objects) }

    context "completed count" do
      before { batch.batch_objects.first.update_attributes(verified: true) }
      it "should return the number of verified batch objects" do
        expect(batch.completed_count).to eq(1)
      end
    end

    context "time to complete" do
      before do
        batch.batch_objects.first.update_attributes(verified: true)
        batch.update_attributes(processing_step_start: DateTime.now - 5.minutes)
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
        expect(BatchObjectFile.all).to be_empty
        expect(BatchObjectRelationship.all).to be_empty
      end
    end

    context "validate" do
      let(:parent) { FactoryGirl.create(:test_parent) }
      let(:pid_cache) { { parent.id => parent.class.name} }
      it "should cache the results of looking up relationship objects" do
        expect(batch).to receive(:add_found_pid).once.with(parent.id, "TestParent").and_call_original
        batch.batch_objects.each do |obj|
          obj.batch_object_relationships <<
              BatchObjectRelationship.new(
                  :name => BatchObjectRelationship::RELATIONSHIP_PARENT,
                  :object => parent.id,
                  :object_type => BatchObjectRelationship::OBJECT_TYPE_REPO_ID,
                  :operation => BatchObjectRelationship::OPERATION_ADD
              )
        end
        batch.validate
        expect(batch.found_pids).to eq(pid_cache)
      end
    end

  end

end
