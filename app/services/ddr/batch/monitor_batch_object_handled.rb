module Ddr::Batch
  class MonitorBatchObjectHandled

    class << self
      def call(*args)
        event = ActiveSupport::Notifications::Event.new(*args)
        batch_object = BatchObject.find(event.payload[:batch_object_id])
        batch = batch_object.batch
        if event.payload[:exception].present?
          record_batch_object_exception(batch_object, event.payload[:exception])
        end
        batch_object_handled(batch_object, batch)
      end

      private

      def record_batch_object_exception(batch_object, exception_info)
        batch_object_exception_msg = I18n.t('ddr.batch.errors.batch_object_processing', error_msg: exception_info[1])
        Ddr::Batch::BatchObjectMessage.create!(batch_object: batch_object,
                                               level: Logger::ERROR,
                                               message: batch_object_exception_msg)
      end

      def batch_object_handled(batch_object, batch)
        log_batch_object_messages(batch_object, batch.id)
        batch_object.update!(handled: true)
        unless batch.unhandled_objects?
          ActiveSupport::Notifications.instrument('finished.batch.batch.ddr', batch_id: batch.id)
        end
      end

      def log_batch_object_messages(batch_object, batch_id)
        logger = Ddr::Batch::Log.logger(batch_id)
        batch_object.batch_object_messages.each do |message|
          logger.add(message.level) { "Batch Object #{batch_object.id}: #{message.message}" }
        end
        logger.close
      end
    end

  end
end
