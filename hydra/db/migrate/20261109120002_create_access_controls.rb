# Phase 1.2 (access control piece): one row per permission grant, mirroring
# how Hydra::AccessControls::Permissions works today (discover/read/edit x
# person/group), rather than flattening permissions into array columns on
# congressional_records.
#
# `visibility` (public/registered/private) is NOT a column anywhere - it
# will be a computed method on the CongressionalRecord model, derived from
# whether a 'public' or 'registered' read grant exists here, exactly
# matching Hydra::AccessControls::Visibility's current logic.
class CreateAccessControls < ActiveRecord::Migration[7.0]
  def change
    create_table :access_controls do |t|
      t.string :congressional_record_id, null: false
      t.string :agent_type, null: false   # 'person' or 'group'
      t.string :agent_name, null: false   # username or group name (e.g. 'public', 'registered')
      t.string :access_level, null: false # 'discover', 'read', or 'edit'

      t.timestamps
    end

    add_foreign_key :access_controls, :congressional_records, column: :congressional_record_id
    add_index :access_controls, :congressional_record_id
    # One agent can only hold one grant per access level per record - this
    # is what lets set_read_groups/set_edit_groups-style logic upsert
    # cleanly instead of accumulating duplicate rows.
    add_index :access_controls, [:congressional_record_id, :agent_type, :agent_name, :access_level],
              unique: true, name: 'index_access_controls_uniqueness'
  end
end
