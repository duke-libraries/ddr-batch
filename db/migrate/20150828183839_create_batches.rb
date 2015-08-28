class CreateBatches < ActiveRecord::Migration
  def change
    unless table_exists?(:batches)
      create_table :batches do |t|
        t.string   "name"
        t.string   "description"
        t.datetime "created_at"
        t.datetime "updated_at"
        t.integer  "user_id"
        t.string   "status"
        t.datetime "start"
        t.datetime "stop"
        t.string   "outcome"
        t.integer  "failure",               default: 0
        t.integer  "success",               default: 0
        t.string   "version"
        t.string   "logfile_file_name"
        t.string   "logfile_content_type"
        t.integer  "logfile_file_size"
        t.datetime "logfile_updated_at"
        t.datetime "processing_step_start"
      end
    end
  end
end
