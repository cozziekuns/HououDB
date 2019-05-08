require 'sequel'

Sequel.migration do

  up do
    add_column :hanchan_players, :username, String
    
    # Add all the usernames to hanchan_players
    from(:hanchan_players).update(
      username: from(:players).select(:username).where(
        id: Sequel[:hanchan_players][:player_id],
      ),
    )
  end

  down do
    drop_column :hanchan_players, :username
  end

end