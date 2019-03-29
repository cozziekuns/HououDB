require 'sequel'

Sequel.migration do

  up do
    alter_table(:hand_results) do
      add_column :winning_player, Integer
      add_column :losing_player, Integer
    end

    drop_column :hand_results, :winning_hanchan_player_id
    drop_column :hand_results, :losing_hanchan_player_id
  end

  down do
    drop_column :hand_results, :winning_player
    drop_column :hand_results, :losing_player

    alter_table(:hanchan) do
      add_foreign_key :winning_hanchan_player_id, :hanchan_players
      add_foreign_key :losing_hanchan_player_id, :hanchan_players
    end
  end

end