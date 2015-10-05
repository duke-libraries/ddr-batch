class CreateBatchObjectAttributes < ActiveRecord::Migration
  def change
    unless table_exists?(:batch_object_attributes)
      create_table :batch_object_attributes do |t|
        t.integer  "batch_object_id"
        t.string   "datastream"
        t.string   "name"
        t.string   "operation"
        t.text     "value",           limit: 65535
        t.string   "value_type"
        t.datetime "created_at"
        t.datetime "updated_at"
      end
    end
  end
end
