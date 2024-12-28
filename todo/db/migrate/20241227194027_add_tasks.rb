class AddTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.bigint :user_id, null: false, index: true
      t.string :name
      t.boolean :done, default: false
      t.timestamps
    end
  end
end
