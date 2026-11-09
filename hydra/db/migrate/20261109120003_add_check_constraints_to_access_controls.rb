# Restricts access_controls.agent_type and .access_level to the fixed set
# of values Hydra::AccessControls::Permissions actually uses today
# ('person'/'group' and 'discover'/'read'/'edit'). This doesn't change any
# real behavior - nothing in the app ever produces a different value - it
# just catches bad data at the DB level instead of relying on the model
# alone.
class AddCheckConstraintsToAccessControls < ActiveRecord::Migration[7.0]
  def change
    add_check_constraint :access_controls,
                         "agent_type IN ('person', 'group')",
                         name: "access_controls_agent_type_check"
    add_check_constraint :access_controls,
                         "access_level IN ('discover', 'read', 'edit')",
                         name: "access_controls_access_level_check"
  end
end
