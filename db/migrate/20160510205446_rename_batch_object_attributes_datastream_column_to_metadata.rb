class RenameBatchObjectAttributesDatastreamColumnToMetadata < ActiveRecord::Migration
  def change
    rename_column :batch_object_attributes, :datastream, :metadata
  end
end
