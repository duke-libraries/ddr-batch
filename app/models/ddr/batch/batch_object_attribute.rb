module Ddr::Batch

  class BatchObjectAttribute < ActiveRecord::Base
    belongs_to :batch_object, :inverse_of => :batch_object_attributes

    OPERATION_ADD = "ADD"              # Add the provided value to the attribute
    OPERATION_DELETE = "DELETE"        # Delete the provided value from the attribute
    OPERATION_CLEAR = "CLEAR"          # Clear all values from the attribute
    OPERATION_CLEAR_ALL = "CLEAR_ALL"  # Clear all attributes in the datastream

    OPERATIONS = [ OPERATION_ADD, OPERATION_DELETE, OPERATION_CLEAR, OPERATION_CLEAR_ALL ]

    VALUE_TYPE_STRING = "STRING"

    VALUE_TYPES = [ VALUE_TYPE_STRING ]

    validates :operation, inclusion: { in: OPERATIONS }
    validates :datastream, presence: true
    validate :valid_datastream_operation
    with_options if: :operation_requires_name? do |obj|
      obj.validates :name, presence: true
    end
    validate :valid_datastream_and_attribute_name, if: [ 'batch_object.model', 'datastream', 'name' ]
    with_options if: :operation_requires_value? do |obj|
      obj.validates :value, presence: true
      obj.validates :value_type, inclusion: { in: VALUE_TYPES }
    end

    def valid_datastream_operation
      if operation == OPERATION_CLEAR_ALL
        unless datastream == Ddr::Models::Metadata::DESC_METADATA
          errors.add(:operation, "Operation #{operation} is not valid for #{datastream}")
        end
      end
    end

    def operation_requires_name?
      [ OPERATION_ADD, OPERATION_DELETE, OPERATION_CLEAR ].include? operation
    end

    def operation_requires_value?
      [ OPERATION_ADD, OPERATION_DELETE ].include? operation
    end

    def valid_datastream_and_attribute_name
      if datastream_valid?
        errors.add(:name, "is not valid") unless attribute_name_valid?
      else
        errors.add(:datastream, "is not valid")
      end
    end

    def datastream_type
      batch_object.model.constantize.ds_specs[datastream][:type] rescue nil
    end

    def datastream_valid?
        [ Ddr::Models::Metadata::ADMIN_METADATA, Ddr::Models::Metadata::DESC_METADATA ].include?(datastream)
    end

    def attribute_name_valid?
      case datastream
        when Ddr::Models::Metadata::ADMIN_METADATA
          batch_object.model.constantize.properties.include?(name)
        when Ddr::Models::Metadata::DESC_METADATA
          Ddr::Models::DescriptiveMetadata.unqualified_names.include?(name.to_sym)
      end
    end

  end
end
