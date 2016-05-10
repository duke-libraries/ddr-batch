class RenameBatchObjectDatastreamsToBatchObjectFiles < ActiveRecord::Migration
  def change
    rename_table :batch_object_datastreams, :batch_object_files
  end
end
