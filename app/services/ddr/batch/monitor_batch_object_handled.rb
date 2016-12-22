module Ddr::Batch
  class MonitorBatchObjectHandled

    class << self
      def call(*args)
        event = ActiveSupport::Notifications::Event.new(*args)
        batch_object = BatchObject.find(event.payload[:batch_object_id])
        batch = batch_object.batch
        batch_object_handled(batch_object, batch)
      end

      private

      def batch_object_handled(batch_object, batch)
        log_batch_object_messages(batch_object, batch.id)
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
