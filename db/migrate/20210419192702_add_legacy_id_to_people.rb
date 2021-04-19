class AddLegacyIdToPeople < ActiveRecord::Migration[5.2]
  def change
    add_column :people, :legacy_id, :integer
  end
end
