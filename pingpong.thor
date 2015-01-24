class PingPong < Thor
  include Thor::Actions

  desc "setup", "Creates the initial migration for checks and applies it."
  def setup
    # lets create the migration file
    t = Time.new()
    fileName = "db/migrate/#{t.strftime("%Y%m%d%H%M%S")}_create_checks.rb"

    create_file fileName do
<<TEMPLATE
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
TEMPLATE
    end unless File.exists?(fileName)

    run("bundle exec rake db:migrate")
  end

  def self.source_root
    File.dirname(__FILE__)
  end
end
