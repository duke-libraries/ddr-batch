module Ddr::Batch
  class BatchObjectRelationship < ActiveRecord::Base

    belongs_to :batch_object, :inverse_of => :batch_object_relationships

    RELATIONSHIP_ADMIN_POLICY = "admin_policy"
    RELATIONSHIP_COLLECTION = "collection"
    RELATIONSHIP_PARENT = "parent"
    RELATIONSHIP_ITEM = "item"
    RELATIONSHIP_COMPONENT = "component"
    RELATIONSHIP_ATTACHED_TO = "attached_to"

    RELATIONSHIPS = [ RELATIONSHIP_ADMIN_POLICY, RELATIONSHIP_COLLECTION, RELATIONSHIP_PARENT, RELATIONSHIP_ITEM,
      RELATIONSHIP_COMPONENT, RELATIONSHIP_ATTACHED_TO ]

    OPERATION_ADD = "ADD"
    OPERATION_DELETE = "DELETE"
    OPERATION_UPDATE = "UPDATE"

    OPERATIONS = [ OPERATION_ADD, OPERATION_DELETE, OPERATION_UPDATE ]

    OBJECT_TYPE_REC_ID = "REC_ID"
    OBJECT_TYPE_REPO_ID = "REPO_ID"

    OBJECT_TYPES = [ OBJECT_TYPE_REC_ID, OBJECT_TYPE_REPO_ID ]

    validates_presence_of :object, :batch_object

    validates_inclusion_of :name, in: RELATIONSHIPS, message: 'Invalid relationship name'
    validates_inclusion_of :operation, in: OPERATIONS, message: 'Invalid relationship operation'
    validates_inclusion_of :object_type, in: OBJECT_TYPES, message: 'Invalid relationship object type'
    validate :record_must_be_in_batch, if: :object_rec_id?
    validate :repo_object_must_exist, if: :object_repo_id?
    validate :relationship_name_must_be_valid_for_model

    delegate :batch, to: :batch_object
    delegate :batch_objects, to: :batch
    delegate :found_pids, to: :batch
    delegate :add_found_pid, to: :batch

    def object_rec_id?
      object_type == OBJECT_TYPE_REC_ID
    end

    def object_repo_id?
      object_type == OBJECT_TYPE_REPO_ID
    end

    def record_must_be_in_batch
      batch_objects.find(object).present?
    rescue ActiveRecord::RecordNotFound
        errors.add(:object, "#{object} not found in this batch")
    end

    def repo_object_must_exist
      unless found_pids.keys.include?(object)
        obj = ActiveFedora::Base.find(object)
        add_found_pid(obj.id, obj.class.name)
      end
    rescue ActiveFedora::ObjectNotFoundError
      errors.add(:object, "#{object} not found in repository")
    end

    def relationship_name_must_be_valid_for_model
      unless Ddr::Utils.relationship_object_reflection(batch_object.model, name).present?
        errors.add(:name, "#{batch_object.model} does not define a(n) #{name} relationship")
      end
    end

    def object_model_must_be_correct_for_relationship
      if relationship_reflection = Ddr::Utils.relationship_object_reflection(batch_object.model, name)
        klass = Ddr::Utils.reflection_object_class(relationship_reflection)
        if klass.present?
          unless object_model == klass.name
            errors.add(:object, "#{name} relationship object #{object} exists but is not a(n) #{klass}")
          end
        end
      end
    end

    private

    def object_model
      case object_type
        when OBJECT_TYPE_REC_ID
          batch_objects.find(object).model
        when OBJECT_TYPE_REPO_ID
          if found_pids.keys.include?(object)
            found_pids[object]
          else
            obj = ActiveFedora::Base.find(object)
            add_found_pid(obj.id, obj.class.name)
          end
      end
    end

  end
end
