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
    .reduce({}) { |acc, line|
      tbl_name,
      col_name,
      col_type,
      col_is_nullable,
      col_comment,
      col_refs_table = line.split("\t")

      acc[tbl_name] ||= []
      acc[tbl_name] << {
        tbl_name:           tbl_name,
        col_name:           col_name,
        col_type:           col_type,
        col_is_nullable:    col_is_nullable == "NO" ? false : true,
        col_column_comment: col_comment.empty? ? nil : col_comment,
        col_refs_table:     col_refs_table == "NULL" ? nil : col_refs_table
      }

      acc
    }

refs = []

output =
  result.map do |tbl_name, tbl_info|
    out = []

    out << "[#{tbl_name}]"
    out << tbl_info.map do |col|
      nullable = col[:col_is_nullable] ? nil : "NOT NULL"

      if col[:col_refs_table]
        refs << col.select { |k| [:tbl_name, :col_name, :col_is_nullable, :col_refs_table].include?(k) }
      end

      [col[:col_name], col[:col_type], nullable].compact.join(" | ")
    end
    out << ""
  end

output <<
  refs.map do |ref|
    left  = "1"
    right = ref[:col_is_nullable] ? "?" : "1"

    "#{ref[:tbl_name]} #{left}--#{right} #{ref[:col_refs_table]}"
  end

version_number = Dir.glob("/tmp/output_*").count + 1

output_filename = "/tmp/output_#{version_number}.txt"
output_diagram = "/tmp/diagram_output_#{version_number}.png"
output_json = "/tmp/json_output_#{version_number}.json"

require "json"
File.open(output_json, "w+") do |file|
  file.puts JSON.pretty_generate(result)
end

File.open(output_filename, "w+") do |file|
  file.puts output
end

string = "
Generated:
  - #{output_filename}
  - #{output_diagram}
  - #{output_json}"

puts string

`./simple-erd -i #{output_filename} -o #{output_diagram} -f png`
