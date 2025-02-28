class CreateUrlChecks < ActiveRecord::Migration[7.0]
  def change
    create_table :url_checks do |t|
      t.string :url, null: false
      t.boolean :active, null: false, default: false
      t.datetime :last_checked_at
      t.string :status, default: 'pending'  # Add status for tracking check state
      t.integer :retry_count, default: 0    # Track number of retries
      t.text :error_message                 # Store any error messages
      t.timestamps
    end
    
    add_index :url_checks, :url, unique: true
    add_index :url_checks, :status          # Add index for status queries
  end
end
