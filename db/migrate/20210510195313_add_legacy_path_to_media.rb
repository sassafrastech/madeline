class AddLegacyPathToMedia < ActiveRecord::Migration[5.2]
  def change
    add_column :media, :legacy_path, :string
  end
end
