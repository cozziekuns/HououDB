require 'sequel'

Sequel.migration do

  up do
    alter_table(:hand_results) do
      drop_column :yaku
      add_column :yaku, :Bignum
    end
  end

  down do
    alter_table(:hand_results) do
      drop_column :yaku
      add_column :yaku, Integer
    end
  end
  
end