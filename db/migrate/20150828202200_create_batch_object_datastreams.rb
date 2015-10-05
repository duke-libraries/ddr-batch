class CreateBatchObjectDatastreams < ActiveRecord::Migration
  def change
    unless table_exists?(:batch_object_datastreams)
      create_table :batch_object_datastreams do |t|
        t.integer  "batch_object_id"
        t.string   "operation"
        t.string   "name"
        t.text     "payload"
        t.string   "payload_type"
        t.datetime "created_at"
        t.datetime "updated_at"
        t.string   "checksum"
        t.string   "checksum_type"
      end
    end
  end
end
