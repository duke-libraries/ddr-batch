module Ddr::Batch

  class BatchObjectAttribute < ActiveRecord::Base
    belongs_to :batch_object, :inverse_of => :batch_object_attributes

    OPERATION_ADD = "ADD"              # Add the provided value to the attribute
    OPERATION_DELETE = "DELETE"        # Delete the provided value from the attribute
    OPERATION_CLEAR = "CLEAR"          # Clear all values from the attribute
    OPERATION_CLEAR_ALL = "CLEAR_ALL"  # Clear all attributes for a particular type of metadata

    OPERATIONS = [ OPERATION_ADD, OPERATION_DELETE, OPERATION_CLEAR, OPERATION_CLEAR_ALL ]

    VALUE_TYPE_STRING = "STRING"

    VALUE_TYPES = [ VALUE_TYPE_STRING ]

    validates :operation, inclusion: { in: OPERATIONS }
    validates :metadata, presence: true
    validate :valid_metadata_operation
    with_options if: :operation_requires_name? do |obj|
      obj.validates :name, presence: true
    end
    validate :valid_metadata_and_attribute_name, if: [ 'batch_object.model', 'metadata', 'name' ]
    with_options if: :operation_requires_value? do |obj|
      obj.validates :value, presence: true
      obj.validates :value_type, inclusion: { in: VALUE_TYPES }
    end

    def valid_metadata_operation
      if operation == OPERATION_CLEAR_ALL
        unless metadata == Ddr::Models::Metadata::DESC_METADATA
          errors.add(:operation, "Operation #{operation} is not valid for #{metadata}")
        end
      end
    end

    def operation_requires_name?
      [ OPERATION_ADD, OPERATION_DELETE, OPERATION_CLEAR ].include? operation
    end

    def operation_requires_value?
      [ OPERATION_ADD, OPERATION_DELETE ].include? operation
    end

    def valid_metadata_and_attribute_name
      if metadata_valid?
        errors.add(:name, "is not valid") unless attribute_name_valid?
      else
        errors.add(:metadata, "is not valid")
      end
    end

    def metadata_valid?
        [ Ddr::Models::Metadata::ADMIN_METADATA, Ddr::Models::Metadata::DESC_METADATA ].include?(metadata)
    end

    def attribute_name_valid?
      case metadata
        when Ddr::Models::Metadata::ADMIN_METADATA
          batch_object.model.constantize.properties.include?(name)
        when Ddr::Models::Metadata::DESC_METADATA
          Ddr::Models::DescriptiveMetadata.unqualified_names.include?(name.to_sym)
      end
    end

  end
end
