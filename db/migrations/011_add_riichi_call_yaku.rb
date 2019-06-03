require 'sequel'

Sequel.migration do

  up do
    alter_table(:hand_results) do
      add_column :riichi, Integer
      add_column :calls, Integer
      add_column :yaku, Integer
    end
  end

  down do
    drop_column :hand_results, :riichi
    drop_column :hand_results, :calls
    drop_column :hand_results, :yaku
  end
  
end