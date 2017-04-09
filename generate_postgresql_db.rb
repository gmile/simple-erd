#!/usr/bin/env ruby

require 'optparse'
require 'json'

required_options = {
  input: nil,
  output: nil
}

OptionParser.new do |parser|
  parser.on("-i", "--input PATH", "A path to the input file.") do |v|
    required_options[:input] = v
  end

  parser.on("-o", "--output PATH", "A path to the output file.") do |v|
    required_options[:output] = v
  end
end.parse!

input_filename = required_options[:input]
output_filename = required_options[:output]

input = IO.read(input_filename)
table_data = JSON.parse(input)

table_template = %{
%{new_types}

CREATE TABLE %{table_name} (
%{rows}
);
}

output = ""

def translate_type_from_mysql_to_pgsql(name, type)
  case
  when type =~ /^int/           then "integer"
  when type =~ /^datetime/      then "timestamp"
  when type =~ /^varchar\(36\)/ then "uuid"
  when type =~ /^enum/          then
    type.match(/^enum\(.*\)/)[1]&.split(",")&.map(&:strip) || ["default1", "default2"]
  else
    type
  end
end

def custom_fix(tbl_name, name, type)
  pg_name, array =
    if name.end_with?("[]")
      [name.delete("[]"), true]
    else
      [name, false]
    end

  pg_type = translate_type_from_mysql_to_pgsql(name, type)

  pg_type =
    if pg_type.is_a? Array
      type_name = "#{tbl_name}_#{name}"
      puts "WARNING: need to register a new enum type \"#{type_name}\" with values: #{pg_type.join(", ")}"

      [type_name, pg_type]
    else
      pg_type
    end

  pg_type =
    if array
      pg_type << "[]"
    else
      pg_type
    end

  [pg_name, pg_type]
end

output =
  table_data.first(3).map do |tbl_name, columns|
    max_name = columns.max_by { |c| c["col_name"] }["col_name"].size
    max_type = columns.max_by { |c| c["col_type"] }["col_type"].size

    new_types = []

    cols_out =
      columns.map do |column|
        name, type = custom_fix(tbl_name, column["col_name"], column["col_type"])

        t = if type.is_a? Array
              new_types << type

              type[0]
            else
              type
            end

        "  %-#{max_name + 10}{name}%-#{max_type}{type}" % {
          name: name,
          type: t
        }
      end

    table_template % {
      new_types: "",
      table_name: tbl_name,
      rows: cols_out.join(",\n")
    }
  end.join("\n")

puts output

db_script = "/tmp/test_psql_db.sql"

File.open(db_script, "w+") do |file|
  file.puts output
end

`dropdb test`
`createdb test`

`psql test < #{db_script}`

# CREATE TABLE films (
#     code        char(5) CONSTRAINT firstkey PRIMARY KEY,
#     title       varchar(40) NOT NULL,
#     did         integer NOT NULL,
#     date_prod   date,
#     kind        varchar(10),
#     len         interval hour to minute
# );
