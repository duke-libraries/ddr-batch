module Ddr::Batch
  class BatchObjectsProcessorJob
    @queue = :batch

    def self.perform(batch_object_ids, operator_id)
      operator = User.find(operator_id)
      ProcessBatchObjects.new(batch_object_ids: batch_object_ids, operator: operator).execute
    end

  end
end
