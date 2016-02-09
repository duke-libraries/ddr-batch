module Ddr::Batch
  class BatchProcessorRunMailer < ActionMailer::Base

    def send_notification(batch)
      @batch = batch
      @title = "Batch Processor Run #{@batch.status}"
      @host = `uname -n`.strip
      @subject = "[#{@host}] #{@title}"
      attachments["details.txt"] = File.read(@batch.logfile.path)
      mail(from: from_address, to: @batch.user.email, subject: @subject)
    end

    private

    def from_address
      if Rails.application.config.action_mailer.default_options &&
              addr = Rails.application.config.action_mailer.default_options[:from]
        addr
      else
        raise Ddr::Batch::Error, 'Application config.action_mailer.default_options[:from] must be set'
      end
    end

  end
end
