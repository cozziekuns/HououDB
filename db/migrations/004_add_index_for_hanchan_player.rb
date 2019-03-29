require 'sequel'

Sequel.migration do

  up do
    alter_table(:hanchan_players) do
      add_index :player_id
    end
  end

  down do
    alter_table(:hanchan_players) do
      drop_index :player_id
    end
  end

end