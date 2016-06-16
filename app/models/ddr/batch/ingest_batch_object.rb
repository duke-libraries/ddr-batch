module Ddr::Batch

  class IngestBatchObject < BatchObject

    def local_validations
      errors = []
      errors << "#{error_prefix} Model required for INGEST operation" unless model
      errors
    end

    def model_file_keys
      model.constantize.new.attached_files.keys
    end

    def process(user, opts = {})
      ingest(user, opts) unless verified
    end

    def results_message
      if pid
        verification_result = (verified ? "Verified" : "VERIFICATION FAILURE")
        message = "Ingested #{model} #{identifier} into #{pid}...#{verification_result}"
      else
        message = "Attempt to ingest #{model} #{identifier} FAILED"
      end
    end

    private

    def ingest(user, opts = {})
      repo_object = create_repository_object
      if !repo_object.nil? && !repo_object.new_record?
        ingest_outcome_detail = []
        ingest_outcome_detail << "Ingested #{model} #{identifier} into #{repo_object.id}"
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
        repo_object = model.constantize.new(:id => repo_pid)
        repo_object.save(validate: false)
        update_attributes(:pid => repo_object.id)
        batch_object_attributes.each { |a| repo_object = add_attribute(repo_object, a) }
        batch_object_files.each { |d| repo_object = populate_file(repo_object, d) }
        batch_object_relationships.each { |r| repo_object = add_relationship(repo_object, r) }
        repo_object.save
      rescue Exception => e1
        logger.fatal("Error in creating repository object #{repo_object.id} for #{identifier} : #{e1}")
        repo_clean = false
        if repo_object && !repo_object.new_record?
          begin
            logger.info("Deleting potentially incomplete #{repo_object.id} due to error in ingest batch processing")
            repo_object.destroy
          rescue Exception => e2
            logger.fatal("Error deleting repository object #{repo_object.id}: #{e2}")
          else
            repo_clean = true
          end
          update_attributes(pid: nil)
        else
          repo_clean = true
        end
        if batch.present?
          batch.status = repo_clean ? Batch::STATUS_RESTARTABLE : Batch::STATUS_INTERRUPTED
          batch.save
        end
        raise e1
      end
      repo_object
    end

  end

end
