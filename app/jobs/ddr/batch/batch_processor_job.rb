module Ddr::Batch
  class BatchProcessorJob
    @queue = :batch

    def self.perform(batch_id, operator_id)
      ProcessBatch.new(batch_id: batch_id, operator_id: operator_id).execute
    end

    def self.after_enqueue_set_status(batch_id, operator_id)
      batch = Batch.find(batch_id)
      batch.status = Batch::STATUS_QUEUED
      batch.save
    end

  end
end
