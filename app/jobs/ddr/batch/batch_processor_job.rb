module Ddr::Batch
  class BatchProcessorJob
    @queue = :batch

    def self.perform(batch_id, operator_id)
      ts = Time.now.strftime("%Y%m%d%H%M%S%L")
      logfile = "batch_processor_#{ts}_log.txt"
      batch = Batch.find(batch_id)
      operator = User.find(operator_id)
      bp = BatchProcessor.new(batch, operator, log_file: logfile)
      bp.execute
    end

    def self.after_enqueue_set_status(batch_id, operator_id)
      batch = Batch.find(batch_id)
      batch.status = Batch::STATUS_QUEUED
      batch.save
    end

  end
end