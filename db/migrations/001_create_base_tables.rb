require 'sequel'

Sequel.migration do
  up do
    create_table(:players) do
      primary_key :id
      String :username, null: false 
    end

    create_table(:hanchan) do
      primary_key :id
      Time :time_start, index: true
      foreign_key :east_player_id, :players
      foreign_key :south_player_id, :players
      foreign_key :west_player_id, :players
      foreign_key :north_player_id, :players
      Integer :avg_rating
      String :tenhou_log
    end
  end

  down do
    drop_table(:players)
    drop_table(:hanchan)
  end
end