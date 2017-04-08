require 'json'

DB_NAME = "mydb"

table_list_sql = "SHOW TABLES;"

table_description_sql = %{
  SELECT COLUMN_KEY,
         COLUMN_NAME,
         COLUMN_TYPE,
         COLUMN_DEFAULT,
         IS_NULLABLE,
         COLUMN_COMMENT
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = '%{db_name}'
     AND TABLE_NAME = '%{table_name}';
}

table_references_sql = %{
  SELECT TABLE_NAME,
         COLUMN_NAME,
         REFERENCED_TABLE_NAME
    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
   WHERE REFERENCED_TABLE_SCHEMA = '%{db_name}'
     AND TABLE_NAME = '%{table_name}';
}

list_of_tables = `mysql --silent -uroot mydb -e "#{table_list_sql}"`

result =
  list_of_tables.split("\n").reduce({}) do |acc, table|
    sql = table_description_sql % {table_name: table, db_name: DB_NAME}
    sql2 = table_references_sql % {table_name: table, db_name: DB_NAME}

    acc[table] = {
      columns: [],
      references: []
    }

    result1 = `mysql --silent -uroot mydb -e "#{sql}"`
    result2 = `mysql --silent -uroot mydb -e "#{sql2}"`

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
      table_name,
      column_name,
      ref_table_name = line.split("\t")

      acc[table][:references] << {
        table_name:     table_name,
        column_name:    column_name,
        ref_table_name: ref_table_name
      }
    end

    acc
  end

output = ""

result.each do |tbl_name, tbl_info|
  output << "[#{tbl_name}]\n"

  tbl_info[:columns].each do |col|
    nullable = col[:is_nullable] == "NO" ? "NOT NULL" : nil

    output << [col[:name], col[:type], nullable].compact.join(" | ") << "\n"
  end

  if tbl_info[:references].size > 0
    output << "\n"

    tbl_info[:references].each do |ref|
      this_col = tbl_info[:columns].find { |c| c[:name] == ref[:column_name] }

      right =
        if this_col[:is_nullable] == "NO"
          "1"
        else
          "?"
        end

      left = "1"

      output << "#{ref[:table_name]} #{left}--#{right} #{ref[:ref_table_name]}\n"
    end
  end

  output << "\n"
end

File.open("/tmp/output.txt", "w+") do |file|
  file.puts output
end

`./simple-erd -i /tmp/output.txt -o /tmp/yo.png -f png`
