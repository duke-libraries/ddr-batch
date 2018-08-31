require 'rails_helper'

module Ddr::Batch

  shared_examples 'a handled batch object' do
    it 'marks the batch object as handled' do
      expect_any_instance_of(Ddr::Batch::BatchObject).to receive(:update!).with({ handled: true })
      described_class.call(*notification)
    end
  end

  RSpec.describe MonitorBatchObjectHandled do
    let(:batch) { FactoryGirl.create(:item_update_batch) }
    let(:batch_object) { batch.batch_objects.first }


    describe 'no errors during processing' do
      let(:notification) do
        [ "handled.batchobject.batch.ddr", Time.now, Time.now, "7ab63be5766dc3a9f9f5",
          { batch_object_id: batch_object.id } ]
      end
      it_behaves_like 'a handled batch object'
    end

    describe 'errors during processing' do
      let(:processing_error_message) { 'something bad happened' }
      let(:batch_object_message) do
        I18n.t('ddr.batch.errors.batch_object_processing', error_msg: processing_error_message)
      end
      let(:notification) do
        [ "handled.batchobject.batch.ddr", Time.now, Time.now, "7ab63be5766dc3a9f9f5",
          { batch_object_id: batch_object.id, exception: [ 'StandardError', processing_error_message ] } ]
      end
      it_behaves_like 'a handled batch object'
      it 'records a batch object message about the error' do
        described_class.call(*notification)
        expect(batch_object.batch_object_messages.where(message: batch_object_message)).to_not be_empty
      end
    end

  end
end
