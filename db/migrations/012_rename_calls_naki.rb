require 'sequel'

Sequel.migration do

  up do
    alter_table(:hand_results) do
      rename_column :calls, :naki
    end
  end

  down do
    alter_table(:hand_results) do
      rename_column :naki, :calls
    end
  end
  
end