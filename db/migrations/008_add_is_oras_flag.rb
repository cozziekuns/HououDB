require 'sequel'

Sequel.migration do

  up do
    alter_table(:hand_results) do
      add_column :is_oras, TrueClass
    end
  end

  down do
    drop_column :hand_results, :is_oras
  end
  
end