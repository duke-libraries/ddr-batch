module Ddr::Batch

  class IngestBatchObject < BatchObject

    def local_validations
      errors = []
      errors << "#{@error_prefix} Model required for INGEST operation" unless model
      errors += validate_pre_assigned_pid if pid
      errors += validate_collection if model == 'Collection'
      errors
    end

    def model_datastream_keys
      model.constantize.new.datastreams.keys
    end

    def process(user, opts = {})
      ingest(user, opts) unless verified
    end

    def results_message
      if pid
        message_level = verified ? Logger::INFO : Logger::WARN
        verification_result = verified ? "Verified" : "VERIFICATION FAILURE"
        ProcessingResultsMessage.new(message_level, "Ingested #{model} #{identifier} into #{pid}...#{verification_result}")
      else
        ProcessingResultsMessagemessage.new(Logger::ERROR, "Attempt to ingest #{model} #{identifier} FAILED")
      end
    end

    private

    def validate_pre_assigned_pid
      errs = []
      errs << "#{@error_prefix} #{pid} already exists in repository" if ActiveFedora::Base.exists?(pid)
      return errs
    end

    def validate_collection
      errs = []
      coll = Collection.new
      batch_object_attributes.each { |attr| coll = add_attribute(coll, attr) }
      unless coll.valid?
        coll.errors.messages.each { |k, v| errs << "#{@error_prefix} Collection #{k} #{v.join(';')}" }
      end
      errs
    end

    def ingest(user, opts = {})
      repo_object = create_repository_object
      if !repo_object.nil? && !repo_object.new_record?
        ingest_outcome_detail = []
        ingest_outcome_detail << "Ingested #{model} #{identifier} into #{repo_object.pid}"
        Ddr::Events::IngestionEvent.new.tap do |event|
          event.object = repo_object
          event.user = user
          event.summary = EVENT_SUMMARY % {
            :label => "Object ingestion",
            :batch_id => id,
            :identifier => identifier,
            :model => model
          }
          event.detail = ingest_outcome_detail.join("\n")
          event.save!
        end
        update_attributes(:pid => repo_object.pid)
        verifications = verify_repository_object
        verification_outcome_detail = []
        verified = true
        verifications.each do |key, value|
          verification_outcome_detail << "#{key}...#{value}"
          verified = false if value.eql?(VERIFICATION_FAIL)
        end
        update_attributes(:verified => verified)
        Ddr::Events::ValidationEvent.new.tap do |event|
          event.object = repo_object
          event.failure! unless verified
          event.summary = EVENT_SUMMARY % {
            :label => "Object ingestion validation",
            :batch_id => id,
            :identifier => identifier,
            :model => model
          }
          event.detail = verification_outcome_detail.join("\n")
          event.save!
        end
      else
        verifications = nil
      end
      repo_object
    end

    def create_repository_object
      repo_pid = pid if pid.present?
      repo_object = nil
      begin
        repo_object = model.constantize.new(:pid => repo_pid)
        repo_object.label = label if label
        repo_object.save(validate: false)
        batch_object_attributes.each { |a| repo_object = add_attribute(repo_object, a) }
        batch_object_datastreams.each { |d| repo_object = populate_datastream(repo_object, d) }
        batch_object_relationships.each { |r| repo_object = add_relationship(repo_object, r) }
        batch_object_roles.each { |r| repo_object = add_role(repo_object, r) }
        repo_object.save! # Do not allow batch ingest to successfully create an invalid object
      rescue Exception => e1
        logger.fatal("Error in creating repository object #{repo_object.pid} for #{identifier} : #{e1}")
        if repo_object && !repo_object.new_record?
          begin
            logger.info("Deleting potentially incomplete #{repo_object.pid} due to error in ingest batch processing")
            repo_object.destroy
          rescue Exception => e2
            logger.fatal("Error deleting repository object #{repo_object.pid}: #{e2}")
          end
        end
        raise e1
      end
      repo_object
    end

  end

end
