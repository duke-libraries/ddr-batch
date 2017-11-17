module Ddr::Batch

  class BatchProcessorRunMailer < ActionMailer::Base

    def send_notification(batch)
      @batch = batch
      @title = "Batch Processor Run #{@batch.status} #{@batch.outcome}"
      @title << " - #{@batch.collection_title}" if @batch.collection_title.present?
      @host = `uname -n`.strip
      @subject = "[#{@host}] #{@title}"
      @size = @batch.batch_objects.size
      @handled = @batch.handled_count
      @success = @batch.success_count
      attachments[attachment_file_name(@batch)] = File.read(@batch.logfile.path)
      mail(to: @batch.user.email, subject: @subject)
    end

    private

    def attachment_file_name(batch)
      if batch.collection_title.present?
        sanitized_title = sanitize_title_for_filename(batch.collection_title)
        "details_#{sanitized_title}.txt"
      else
        "details.txt"
      end
    end

    def sanitize_title_for_filename(title)
      title
          .gsub(/[^\w\s_-]+/, '')
          .gsub(/\s+/, '_')
    end
  end

end
