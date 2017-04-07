require 'json'

table_list_sql = "SHOW TABLES;"

table_description_sql = %{
  SELECT COLUMN_KEY,
         COLUMN_NAME,
         COLUMN_TYPE,
         COLUMN_DEFAULT,
         IS_NULLABLE,
         COLUMN_COMMENT
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = 'mydb'
     AND TABLE_NAME = '%{table_name}';
}

table_references_sql = %{
  SELECT COLUMN_NAME,
       --  CONSTRAINT_NAME,
         REFERENCED_TABLE_NAME,
         REFERENCED_COLUMN_NAME
    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
   WHERE REFERENCED_TABLE_SCHEMA = 'mydb'
     AND REFERENCED_TABLE_NAME = '%{table_name}';
}

list_of_tables = `mysql --raw --silent -uroot mydb -e "#{table_list_sql}"`

result =
  list_of_tables.split("\n").first(2).reduce({}) do |acc, table|
    sql = table_description_sql % {table_name: table}
    sql2 = table_references_sql % {table_name: table}

    acc[table] = {
      columns: [],
      references: []
    }

    result1 = `mysql --raw --silent -uroot mydb -e "#{sql}"`
    result2 = `mysql --raw --silent -uroot mydb -e "#{sql2}"`

    result1.split("\n").each do |line|
      key,
      name,
      type,
      default,
      is_nullable,
      column_comment = line.split("\t")

      acc[table][:columns] << {
        key:            key,
        name:           name,
        type:           type,
        default:        default,
        is_nullable:    is_nullable,
        column_comment: column_comment
      }
    end

    result2.split("\n").each do |line|
      key,
      ref_table_name,
      ref_col_name = line.split("\t")

      acc[table][:references] << {
        key:            key,
        ref_table_name: ref_table_name,
        ref_col_name:   ref_col_name
      }
    end

    acc
  end

puts JSON.pretty_generate(result)
