class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.bigint :task_id, null: false
      t.bigint :user_id, null: false
      t.bigint :author_id, null: false
      t.text :body, null: false

      t.timestamps
    end

    add_index :comments, :task_id
    add_index :comments, [:user_id, :task_id]
    add_foreign_key :comments, :tasks
  end
end
