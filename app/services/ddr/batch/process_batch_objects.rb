module Ddr::Batch
  class ProcessBatchObjects

    attr_reader :batch_object_ids, :operator

    def initialize(batch_object_ids:, operator:)
      @batch_object_ids = batch_object_ids
      @operator = operator
    end

    def execute
      # Assume successful processing of all batch objects until proven otherwise.
      success = true
      batch_object_ids.each do |batch_object_id|
        batch_object = Ddr::Batch::BatchObject.find(batch_object_id)
        # Skip batch objects that have already been successfully processed.  This is useful when this service is
        # called within the context of a BatchObjectsProcessorJob, that job fails, and the failed job is retried.
        unless batch_object.verified?
          # Once any batch object included in this job fails to process successfully, do not attempt to process
          # any remaining batch objects included in this job.  Instead, mark them as "handled" so the batch knows
          # it's not waiting on them to be handled before it can consider itself "finished".
          # The use case prompting this behavior is a job containing an Item ingest batch object plus one or more
          # associated Component ingest batch objects.  If the Item batch object fails to process correctly, we don't
          # want to attempt to process the Component batch objects.
          # In the preceding use case, we could skip the remaining batch objects only if the failed batch object is an
          # Item but there might be future cases in which we don't want to process the remaining batch objects in the
          # job regardless of which batch object fails.  The failure of any batch object to process should be rare
          # enough that it doesn't seem harmful to cover this potential broader use case in the current code.
          if success
            success = ProcessBatchObject.new(batch_object_id: batch_object.id, operator: operator).execute
          else
            batch_object.update!(handled: true)
          end
        end
      end
    end

  end
end
