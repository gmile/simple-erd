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

table_template = %{CREATE TABLE %{table_name} (
%{rows}
);
}

output = ""

output =
  table_data.first(2).map do |tbl_name, columns|
    max_name = columns.max_by { |c| c["col_name"] }["col_name"].size
    max_type = columns.max_by { |c| c["col_type"] }["col_type"].size

    cols_out =
      columns.map do |column|
        "  %-#{max_name + 5}{name}%-#{max_type}{type}" % {
          name: column["col_name"],
          type: column["col_type"]
        }
      end

    table_template % {
      table_name: tbl_name,
      rows: cols_out.join(",\n")
    }
  end.join("\n")

puts output

# CREATE TABLE films (
#     code        char(5) CONSTRAINT firstkey PRIMARY KEY,
#     title       varchar(40) NOT NULL,
#     did         integer NOT NULL,
#     date_prod   date,
#     kind        varchar(10),
#     len         interval hour to minute
# );
