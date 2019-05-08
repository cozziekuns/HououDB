require 'sequel'

Sequel.migration do

  up do
    alter_table(:hanchan_players) do
      drop_column :player_id
    end

    drop_table :players
  end

  down do
    create_table(:players) do
      primary_key :id
      String :username, null: false 
    end
  
    alter_table(:hanchan_players) do
      add_foreign_key :player_id, :players
    end
  end

end