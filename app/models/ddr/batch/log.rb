module Ddr::Batch
  class Log

    DEFAULT_LOG_DIR = File.join(Rails.root, 'log')

    class << self

      def logger(batch_id)
        loggr = Logger.new(File.open(file_path(batch_id), File::WRONLY | File::APPEND | File::CREAT))
        loggr.level = Ddr::Batch.processor_logging_level
        loggr.datetime_format = "%Y-%m-%d %H:%M:%S.L"
        loggr.formatter = proc do |severity, datetime, progname, msg|
          "#{datetime} #{severity}: #{msg}\n"
        end
        loggr
      end

      def clear_log(batch_id)
        log_file_path = file_path(batch_id)
        FileUtils.remove(log_file_path) if File.exists?(log_file_path)
      end

      def file_path(batch_id)
        File.join(DEFAULT_LOG_DIR, "batch_#{batch_id}_log.txt")
      end

    end
  end
end
