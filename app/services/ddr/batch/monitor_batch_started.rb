module Ddr::Batch
  class MonitorBatchStarted

    class << self
      def call(*args)
        event = ActiveSupport::Notifications::Event.new(*args)
        batch = Ddr::Batch::Batch.find(event.payload[:batch_id])
        batch_started(batch)
      end

      private

      def batch_started(batch)
        clear_logs(batch)
        log_batch_start(batch)
        update_batch(batch)
      end

      def clear_logs(batch)
        # delete any previously existing filesystem log file for this batch
        Ddr::Batch::Log.clear_log(batch.id)
        # remove any existing attached log file from the Batch ActiveRecord object
        batch.logfile.clear
      end

      def log_batch_start(batch)
        logger = Ddr::Batch::Log.logger(batch.id)
        logger.info "Batch id: #{batch.id}"
        logger.info "Batch name: #{batch.name}" if name
        logger.info "Batch size: #{batch.batch_objects.size}"
        logger.close
      end

      def update_batch(batch)
        batch.update!(start: DateTime.now,
                      status: Ddr::Batch::Batch::STATUS_RUNNING,
                      version: VERSION)
      end
    end

  end
end
