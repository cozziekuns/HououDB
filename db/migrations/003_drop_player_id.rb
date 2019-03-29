require 'sequel'

Sequel.migration do

  up do
    create_table(:hanchan_players) do
      primary_key :id
      foreign_key :player_id, :players
      Integer :dan
      Float :rating
    end

    alter_table(:hanchan) do
      add_foreign_key :east_hanchan_player_id, :hanchan_players
      add_foreign_key :south_hanchan_player_id, :hanchan_players
      add_foreign_key :west_hanchan_player_id, :hanchan_players
      add_foreign_key :north_hanchan_player_id, :hanchan_players
    end

    drop_column :hanchan, :east_player_id
    drop_column :hanchan, :south_player_id
    drop_column :hanchan, :west_player_id
    drop_column :hanchan, :north_player_id
  end

  down do
    drop_column :hanchan, :east_hanchan_player_id
    drop_column :hanchan, :south_hanchan_player_id
    drop_column :hanchan, :west_hanchan_player_id
    drop_column :hanchan, :north_hanchan_player_id

    alter_table(:hanchan) do
      add_foreign_key :east_player_id, :players
      add_foreign_key :south_player_id, :players
      add_foreign_key :west_player_id, :players
      add_foreign_key :north_player_id, :players
    end

    drop_table(:hanchan_players)
  end

end