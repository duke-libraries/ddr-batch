class RemoveColumnsFromBatch < ActiveRecord::Migration
  def up
    remove_column :batches, :failure
    remove_column :batches, :success
  end

  def down
    change_table :batches do |t|
      t.integer  "failure",               default: 0
      t.integer  "success",               default: 0
    end
  end
end
