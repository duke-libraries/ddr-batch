module Ddr::Batch
  class BatchDeletionJob
    @queue = :batch

    def self.perform(batch_id)
      batch = Batch.find(batch_id)
      batch.status = Batch::STATUS_DELETING
      batch.save!
      batch.destroy!
    end

    def self.before_enqueue_set_status(batch_id)
      batch = Batch.find(batch_id)
      batch.status = Batch::STATUS_QUEUED_FOR_DELETION
      batch.save
    end

  end
end
