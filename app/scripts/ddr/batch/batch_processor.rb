module Ddr::Batch
  class BatchProcessor

    LOG_CONFIG_FILEPATH = File.join(Rails.root, 'config', 'log4r_batch_processor.yml')
    DEFAULT_LOG_DIR = File.join(Rails.root, 'log')
    DEFAULT_LOG_FILE = "batch_processor_log.txt"
    PASS = "PASS"
    FAIL = "FAIL"

    # Options
    #   :log_dir - optional - directory for log file - default is given in DEFAULT_LOG_DIR
    #   :log_file - optional - filename of log file - default is given in DEFAULT_LOG_FILE
    #   :skip_validation - optional - whether to skip batch object validation step when processing - default is false
    #   :ignore_validation_errors - optional - whether to continue processing even if batch object validation errors occur - default is false
    def initialize(batch, operator=nil, opts={})
      @batch = batch
      @operator = operator
      @bp_log_dir = opts.fetch(:log_dir, DEFAULT_LOG_DIR)
      @bp_log_file = opts.fetch(:log_file, DEFAULT_LOG_FILE)
      @skip_validation = opts.fetch(:skip_validation, false)
      @ignore_validation_errors = opts.fetch(:ignore_validation_errors, false)
    end

    def execute
      config_logger
      if @batch
        initiate_batch_run
        unless @skip_validation
          valid_batch = validate_batch
          @batch.update_attributes(status: Batch::STATUS_INVALID) unless valid_batch
        end
        if @skip_validation || @ignore_validation_errors || valid_batch
          process_batch
        end
        close_batch_run
      end
      save_logfile
      send_notification if @batch.user && @batch.user.email
    end

    private

    def validate_batch
      @batch.update_attributes(status: Batch::STATUS_VALIDATING)
      valid = true
      errors = @batch.validate
      unless errors.empty?
        valid = false
        errors.each do |error|
          message = "Batch Object Validation Error: #{error}"
          @bp_log.error(message)
        end
      end
      @batch.update_attributes(status: Batch::STATUS_RUNNING)
      return valid
    end

    def process_batch
      @batch.update_attributes(status: Batch::STATUS_PROCESSING, processing_step_start: DateTime.now)
      @batch.batch_objects.each do |object|
        begin
          process_object(object)
        rescue Exception => e
          @bp_log.error(e.backtrace)
          break
        end
        sleep 2
      end
      @batch.update_attributes(status: Batch::STATUS_RUNNING) if @batch.status == Batch::STATUS_PROCESSING
    end

    def initiate_batch_run
      @bp_log.info "Batch id: #{@batch.id}"
      @bp_log.info "Batch name: #{@batch.name}" if @batch.name
      @bp_log.info "Batch size: #{@batch.batch_objects.size}"
      @batch.logfile.clear  # clear out any attached logfile
      @batch.update_attributes(:start => DateTime.now,
                               :status => Batch::STATUS_RUNNING,
                               :version => VERSION)
      @failures = 0
      @successes = 0
      @results_tracker = Hash.new
    end

    def close_batch_run
      @batch.reload
      @batch.failure = @failures
      @batch.outcome = @successes.eql?(@batch.batch_objects.size) ? Batch::OUTCOME_SUCCESS : Batch::OUTCOME_FAILURE
      if @batch.status.eql?(Batch::STATUS_RUNNING)
        @batch.status = Batch::STATUS_FINISHED
      end
      @batch.stop = DateTime.now
      @batch.success = @successes
      @batch.save
      @bp_log.info "====== Summary ======"
      @results_tracker.keys.each do |type|
        verb = case type
        when IngestBatchObject.name
          "Ingested"
        when UpdateBatchObject.name
          "Updated"
        end
        @results_tracker[type].keys.each do |model|
          @bp_log.info "#{verb} #{@results_tracker[type][model][:successes]} #{model}"
        end
      end
    end

    def update_results_tracker(type, model, verified)
      @results_tracker[type] = Hash.new unless @results_tracker.has_key?(type)
      @results_tracker[type][model] = Hash.new unless @results_tracker[type].has_key?(model)
      @results_tracker[type][model][:successes] = 0 unless @results_tracker[type][model].has_key?(:successes)
      @results_tracker[type][model][:successes] += 1 if verified
    end

    def process_object(object)
      @bp_log.debug "Processing object: #{object.identifier}"
      repository_object = object.process(@operator)
      update_results_tracker(object.type, repository_object.present? ? repository_object.class.name : object.model, object.verified)
      if object.verified
        @successes += 1
      else
        @failures += 1
      end
      message = object.results_message
      @bp_log.info(message)
    end

    def config_logger
      logconfig = Log4r::YamlConfigurator
      logconfig['LOG_FILE'] = File.join(@bp_log_dir, @bp_log_file)
      logconfig.load_yaml_file File.join(LOG_CONFIG_FILEPATH)
      @bp_log = Log4r::Logger['batch_processor']
    end

    def save_logfile
      @bp_log.outputters.each do |outputter|
        @logfilename = outputter.filename if outputter.respond_to?(:filename)
      end
      @batch.update!({ logfile: File.new(@logfilename) }) if @logfilename
    end

    def send_notification
      begin
        BatchProcessorRunMailer.send_notification(@batch).deliver!
      rescue
        puts "An error occurred while attempting to send the notification."
      end
    end

  end
end