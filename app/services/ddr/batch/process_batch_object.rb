module Ddr::Batch
  class ProcessBatchObject

    attr_reader :batch_object_id, :operator

    def initialize(batch_object_id:, operator:)
      @batch_object_id = batch_object_id
      @operator = operator
    end

    def execute
      ActiveSupport::Notifications.instrument("handled.batchobject.batch.ddr",
                                              batch_object_id: batch_object_id) do |payload|
        batch_object = BatchObject.find(batch_object_id)
        # Validate batch object
        errors = batch_object.validate
        # Process batch object or record validation errors
        if errors.empty?
          process(batch_object, operator)
        else
          record_errors(batch_object, errors)
        end
        # return true if batch_object was processed; otherwise, false
        batch_object.processed? ? true : false
      end
    end

    def process(batch_object, operator)
      batch_object.update!(validated: true)
      batch_object.process(operator)
      batch_object.update!(processed: true)
      results_message = batch_object.results_message
      Ddr::Batch::BatchObjectMessage.create!(batch_object: batch_object,
                                             level: results_message.level,
                                             message: results_message.message)
    end

    def record_errors(batch_object, errors)
      errors.each do |error|
        Ddr::Batch::BatchObjectMessage.create!(batch_object: batch_object,
                                               level: Logger::ERROR,
                                               message: error)
      end
    end
  end
end
