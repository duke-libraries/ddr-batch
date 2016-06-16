module Ddr::Batch

  class BatchObjectFile < ActiveRecord::Base

    belongs_to :batch_object, :inverse_of => :batch_object_files

    FILES = [ Ddr::Models::File::CONTENT,
              Ddr::Models::File::STRUCT_METADATA ]

    OPERATION_ADD = "ADD" # add this file to the object -- considered an error if file already exists
    OPERATION_ADDUPDATE = "ADDUPDATE" # add this file to or update this file in the object
    OPERATION_UPDATE = "UPDATE" # update this file in the object -- considered an error if file does not already exist
    OPERATION_DELETE = "DELETE" # delete this file from the object -- considered an error if file does not exist

    PAYLOAD_TYPE_BYTES = "BYTES"
    PAYLOAD_TYPE_FILENAME = "FILENAME"

    PAYLOAD_TYPES = [ PAYLOAD_TYPE_BYTES, PAYLOAD_TYPE_FILENAME ]
  end

end
