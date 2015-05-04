class CreateChecksAndIncidents < ActiveRecord::Migration
  def change
    create_table(:checks) do |t|
      t.string :name
      t.string :url
      t.integer :frequency
      t.string :method
      t.text :headers
      t.text :data
      t.boolean :save_body
      t.string :http_username
      t.string :http_password

      t.text :custom_properties
      t.text :incident_checking
      t.text :configurations, :default => '{"email_warn":false, "email_bad":true}'

      t.timestamps
    end

    add_index :checks, :name, unique: true

    create_table(:incidents) do |t|
      t.integer :check_id
      t.integer :incident_type
      t.text :info
      t.text :check_response

      t.timestamps
    end

    add_index :incidents, :check_id
  end
end
