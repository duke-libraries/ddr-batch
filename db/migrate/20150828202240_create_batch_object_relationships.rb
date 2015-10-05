class CreateBatchObjectRelationships < ActiveRecord::Migration
  def change
    unless table_exists?(:batch_object_relationships)
      create_table :batch_object_relationships do |t|
        t.integer  "batch_object_id"
        t.string   "name"
        t.string   "operation"
        t.string   "object"
        t.string   "object_type"
        t.datetime "created_at"
        t.datetime "updated_at"
      end
    end
  end
end
