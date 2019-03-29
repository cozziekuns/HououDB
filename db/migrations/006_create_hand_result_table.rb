require 'sequel'

Sequel.migration do
  
  up do
    create_table(:hand_results) do
      primary_key :id
      foreign_key :hanchan_id, :hanchan
      Integer :round
      Integer :honba
      Integer :riichi_sticks
      Integer :east_player_score
      Integer :south_player_score
      Integer :west_player_score
      Integer :north_player_score
      Integer :result_type
      foreign_key :winning_hanchan_player_id
      foreign_key :losing_hanchan_player_id
      Integer :han
      Integer :fu
      Integer :base_score
    end
  end

  down do
    drop_table(:hand_results)
  end

end