class CreateNotes < ActiveRecord::Migration
  def change
    create_table :notes do |t|
      t.references :notable, polymorphic: true, index: true
      t.references :author, index: true

      t.timestamps null: false
    end
  end
end
