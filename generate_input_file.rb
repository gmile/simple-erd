DB_NAME = "mydb"

table_description_sql = %{
   SELECT C.TABLE_NAME,
          C.COLUMN_NAME,
          C.COLUMN_TYPE,
          C.IS_NULLABLE,
          C.COLUMN_COMMENT,
          KCU.REFERENCED_TABLE_NAME
     FROM INFORMATION_SCHEMA.COLUMNS C
LEFT JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE KCU
          ON KCU.COLUMN_NAME = C.COLUMN_NAME AND
             KCU.TABLE_NAME = C.TABLE_NAME
    WHERE C.TABLE_SCHEMA = '%{db_name}';
}

table_description = `mysql --silent -uroot #{DB_NAME} -e "#{table_description_sql % {db_name: DB_NAME}}"`

result =
  table_description
    .split("\n")
    .map { |line| line.split("\t") }
    .group_by { |line| line[0] }
    .reduce({}) { |acc, (table, lines)|
      acc[table] = []

      lines.each do |line|
        puts line.inspect

        tbl_name,
        col_name,
        col_type,
        col_is_nullable,
        col_comment,
        col_refs_table = line

        acc[table] << {
          tbl_name:           tbl_name,
          col_name:           col_name,
          col_type:           col_type,
          col_is_nullable:    col_is_nullable == "NO" ? false : true,
          col_column_comment: col_comment.empty? ? nil : col_comment,
          col_refs_table:     col_refs_table == "NULL" ? nil : col_refs_table
        }
      end

      acc
    }

puts result

output = ""
refs = []

result.each do |tbl_name, tbl_info|
  output << "[#{tbl_name}]\n"

  tbl_info.each do |col|
    nullable = col[:col_is_nullable] ? nil : "NOT NULL"

    output << [col[:col_name], col[:col_type], nullable].compact.join(" | ") << "\n"

    if col[:col_refs_table]
      refs << col.select { |k| [:tbl_name, :col_name, :col_is_nullable, :col_refs_table].include?(k) }
    end
  end

  output << "\n"
end

refs.each do |ref|
  left  = "1"
  right = ref[:col_is_nullable] ? "?" : "1"

  output << "#{ref[:tbl_name]} #{left}--#{right} #{ref[:col_refs_table]}\n"
end

puts output

File.open("/tmp/output.txt", "w+") do |file|
  file.puts output
end

`./simple-erd -i /tmp/output.txt -o /tmp/yo.png -f png`
