module Ddr::Batch
  class ProcessBatch

    attr_accessor :batch, :operator_id

    def initialize(batch_id:, operator_id:)
      @batch = Ddr::Batch::Batch.find(batch_id)
      @operator_id = operator_id
    end

    def execute
      ActiveSupport::Notifications.instrument('started.batch.batch.ddr', batch_id: batch.id)
      batch.batch_objects.each do |batch_object|
        case
          when batch_object.is_a?(IngestBatchObject)
            handle_ingest_batch_object(batch_object)
          when batch_object.is_a?(UpdateBatchObject)
            handle_update_batch_object(batch_object)
        end
      end
    end

    def handle_ingest_batch_object(batch_object)
      case batch_object.model
        when 'Collection'
          ingest_collection_object(batch_object)
        when 'Item'
          enqueue_item_component_ingest(batch_object)
        when 'Component'
          # skip -- will be handled along with associated Item
        when 'Target', 'Attachment'
          Resque.enqueue(BatchObjectsProcessorJob, [ batch_object.id ], operator_id)
      end
    end

    def handle_update_batch_object(batch_object)
      Resque.enqueue(BatchObjectsProcessorJob, [ batch_object.id ], operator_id)
    end

    def ingest_collection_object(batch_object)
      # Collection batch objects are processed synchronously because they need to exist in the repository
      # prior to the processing of any objects (e.g., Item, Component, Target) associated with them.
      # If the Collection batch object does not process successfully, consider the batch finished (albeit unsuccessfully)
      # and raise an exception.
      unless ProcessBatchObject.new(batch_object_id: batch_object.id, operator: User.find(operator_id)).execute
        ActiveSupport::Notifications.instrument('finished.batch.batch.ddr', batch_id: batch.id)
        raise Ddr::Batch::BatchObjectProcessingError, batch_object.id
      end
    end

    def enqueue_item_component_ingest(batch_object)
      query = [ "object = '#{batch_object.pid}'",
                "batch_object_relationships.name = '#{Ddr::Batch::BatchObjectRelationship::RELATIONSHIP_PARENT}'",
                "batches.id = #{batch_object.batch.id}" ].join(' AND ')
      recs = Ddr::Batch::BatchObjectRelationship.joins(batch_object: :batch).where(query)
      batch_object_ids = recs.map { |rec| rec.batch_object.id }.unshift(batch_object.id)
      Resque.enqueue(BatchObjectsProcessorJob, batch_object_ids, operator_id)
    end
  end
end
