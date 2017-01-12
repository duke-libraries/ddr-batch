module Ddr::Batch
  class MonitorBatchFinished

    class << self
      def call(*args)
        event = ActiveSupport::Notifications::Event.new(*args)
        batch = Ddr::Batch::Batch.find(event.payload[:batch_id])
        batch_finished(batch)
      end

      private

      def batch_finished(batch)
        log_batch_finish(batch)
        update_batch(batch)
        send_notification(batch) if batch.user && batch.user.email
      end

      def log_batch_finish(batch)
        logger = Ddr::Batch::Log.logger(batch.id)
        logger.info "====== Summary ======"
        results_tracker = results(batch)
        results_tracker.keys.each do |type|
          results_tracker[type].keys.each do |model|
            log_result(results_tracker, type, model, logger)
          end
        end
        logger.close
      end

      def results(batch)
        results_tracker = Hash.new
        batch.batch_objects.each do |batch_object|
          track_result(results_tracker, batch_object)
        end
        results_tracker
      end

      def track_result(results_tracker, batch_object)
        type, model = [ batch_object.type, batch_object.model ]
        results_tracker[type] = Hash.new unless results_tracker.has_key?(type)
        results_tracker[type][model] = Hash.new unless results_tracker[type].has_key?(model)
        results_tracker[type][model][:successes] = 0 unless results_tracker[type][model].has_key?(:successes)
        results_tracker[type][model][:successes] += 1 if batch_object.verified
      end

      def log_result(results_tracker, type, model, logger)
        verb = type_verb(type)
        count = results_tracker[type][model][:successes]
        logger.info "#{verb} #{ActionController::Base.helpers.pluralize(count, model)}"
      end

      def type_verb(type)
        case type
          when Ddr::Batch::IngestBatchObject.name
            "Ingested"
          when Ddr::Batch::UpdateBatchObject.name
            "Updated"
        end
      end

      def update_batch(batch)
        outcome = batch.success_count.eql?(batch.batch_objects.size) ? Batch::OUTCOME_SUCCESS : Batch::OUTCOME_FAILURE
        logfile = File.new(Ddr::Batch::Log.file_path(batch.id))
        batch.update!(stop: DateTime.now,
                      status: Batch::STATUS_FINISHED,
                      outcome: outcome,
                      logfile: logfile)
      end

      def send_notification(batch)
        begin
          Ddr::Batch::BatchProcessorRunMailer.send_notification(batch).deliver!
        rescue => e
          Rails.logger.error("An error occurred while attempting to send a notification for batch #{batch.id}")
          Rails.logger.error(e.message)
          Rails.logger.error(e.backtrace)
        end
      end
    end

  end
end



