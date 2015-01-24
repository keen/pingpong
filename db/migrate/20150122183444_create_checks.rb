class CreateChecks < ActiveRecord::Migration
  def change
    create_table(:checks) do |t|
      t.string :name
      t.string :url
      t.integer :frequency
      t.string :method
      t.text :data
      t.text :save_body
      t.string :http_username
      t.string :http_password

      t.text :custom_properties

      t.timestamps
    end

    add_index :checks, :name, unique: true
  end
end
