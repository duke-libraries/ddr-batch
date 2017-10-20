module Ddr::Batch

  class Batch < ActiveRecord::Base
    belongs_to :user, :inverse_of => :batches, class_name: ::User
    has_many :batch_objects, -> { order("id ASC") }, :inverse_of => :batch, :dependent => :destroy
    has_attached_file :logfile
    do_not_validate_attachment_file_type :logfile

    OUTCOME_SUCCESS = "SUCCESS"
    OUTCOME_FAILURE = "FAILURE"

    STATUS_READY = "READY"
    STATUS_VALIDATING = "VALIDATING"
    STATUS_INVALID = "INVALID"
    STATUS_VALIDATED = "VALIDATED"
    STATUS_QUEUED = "QUEUED"
    STATUS_PROCESSING = "PROCESSING"
    STATUS_RUNNING = "RUNNING"
    STATUS_FINISHED = "FINISHED"
    STATUS_INTERRUPTED = "INTERRUPTED"
    STATUS_RESTARTABLE = "INTERRUPTED - RESTARTABLE"
    STATUS_QUEUED_FOR_DELETION = "QUEUED FOR DELETION"
    STATUS_DELETING = "DELETING"

    def handled_count
      batch_objects.where(handled: true).count
    end

    def success_count
      batch_objects.where(verified: true).count
    end

    def time_to_complete
      unless start.nil?
        if handled_count > 0
          handled = handled_count
          ((Time.now - start.to_time) / handled) * (batch_objects.count - handled)
        end
      end
    end

    def found_pids
      @found_pids ||= {}
    end

    def add_found_pid(pid, model)
      @found_pids[pid] = model
    end

    def pre_assigned_pids
      @pre_assigned_pids ||= collect_pre_assigned_pids
    end

    def collect_pre_assigned_pids
      batch_objects.map{ |x| x.pid if x.pid.present? }.compact
    end

    def unhandled_objects?
      batch_objects.any? { |batch_object| !batch_object.handled? }
    end

    def finished?
      status == STATUS_FINISHED
    end

    def deletable?
      [ nil,
        Ddr::Batch::Batch::STATUS_READY,
        Ddr::Batch::Batch::STATUS_VALIDATED,
        Ddr::Batch::Batch::STATUS_INVALID ].include?(status)
    end
  end

end
