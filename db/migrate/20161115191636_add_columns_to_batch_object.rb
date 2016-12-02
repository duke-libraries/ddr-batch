class AddColumnsToBatchObject < ActiveRecord::Migration
  def change
    change_table :batch_objects do |t|
      t.boolean "handled", default: false
      t.boolean "processed", default: false
      t.boolean "validated", default: false
    end
  end
end
