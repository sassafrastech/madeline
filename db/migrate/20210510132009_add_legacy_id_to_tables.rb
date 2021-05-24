class AddLegacyIdToTables < ActiveRecord::Migration[5.2]
  def change
    add_column :people, :legacy_id, :integer, index: true
    add_column :timeline_entries, :legacy_id, :integer, index: true
    add_column :project_logs, :legacy_id, :integer, index: true
    add_column :media, :legacy_id, :integer, index: true
  end
end
