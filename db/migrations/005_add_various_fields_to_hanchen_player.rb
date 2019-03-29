require 'sequel'

Sequel.migration do

  up do
    alter_table(:hanchan_players) do
      add_foreign_key :hanchan_id, :hanchan
      add_column :seat, Integer
      add_column :placement, Integer
      add_column :score, Integer
    end
  end

  down do
    drop_column :hanchan_players, :hanchan_id
    drop_column :hanchan_players, :seat
    drop_column :hanchan_players, :placement
    drop_column :hanchan_players, :score
  end

end