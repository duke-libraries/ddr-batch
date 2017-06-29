module Ddr::Batch

  class BatchProcessorRunMailer < ActionMailer::Base

    def send_notification(batch)
      @batch = batch
      @title = "Batch Processor Run #{@batch.status} #{@batch.outcome}"
      @host = `uname -n`.strip
      @subject = "[#{@host}] #{@title}"
      @size = @batch.batch_objects.size
      @handled = @batch.handled_count
      @success = @batch.success_count
      attachments["details.txt"] = File.read(@batch.logfile.path)
      mail(to: @batch.user.email, subject: @subject)
    end

  end

end
