require 'sequel'

Sequel.migration do
  
  up do
    alter_table(:hanchan) do
      add_index :tenhou_log, unique: true
    end
  end

  down do
    alter_table(:hanchan) do
      drop_index :tenhou_log
    end
  end

end