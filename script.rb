input="
[Person]
name,text,not null
height,integer,not null
weight,integer,not null
+birth_location_id,integer,not null

[Location]
id,serial,not null
city,text
state,text,not null
country,text,not null

Person *--1 Location
"

node_template = %{
  "%{entity_name}" [label=<%{entity_contents}>]
}

table_template = %(
<table border="0" cellborder="0" cellspacing="0">
  <tr>
    <td colspan="3" border="1" bgcolor="#EEEEEE" cellpadding="0"><font face="PT Mono"><b>%{entity_name}</b></font></td>
  </tr>
  %{attributes}
</table>
)

row_template = %Q(<tr>
  <td border="1" sides="l%{b}" align="left" port="id"><font face="PT Mono">%{column_name}&nbsp;</font></td>
  <td %{draw_bottom} align="left"><font color="#999999" face="PT Mono">%{column_type}&nbsp;</font></td>
  <td border="1" sides="r%{b}" align="left"><font color="#CCCCCC" face="PT Mono">%{null_or_not}</font></td>
</tr>)

edge_template = %{
%{from} -> %{to} [headlabel="%{from_n}", taillabel="%{to_n}", arrowtail=odot, arrowhead=none, style="dashed", fontname="PT Mono"]
}

contents =
  input.split("\n\n").map do |group|
    lines = group.strip.split("\n")

    if lines[0].start_with?("[")
      entity_name = lines[0].scan(/\w+/)[0]

      n_of_attributes = lines[1..-1].size

      attributes =
        lines[1..-1].map.with_index do |line, idx|
          column_name, column_type, null_or_not = line.split(",")

          draw_bottom = idx == n_of_attributes - 1

          row_template % {
            column_name: column_name,
            column_type: column_type,
            null_or_not: null_or_not || "&nbsp;",
            b: draw_bottom ? "b" : "",
            draw_bottom: draw_bottom ? 'border="1" sides="b"' : ""
          }
        end.join("\n")

      table =
        table_template % {
          entity_name: entity_name,
          attributes: attributes
        }

      node_template % {
        entity_name: entity_name,
        entity_contents: table
      }
    else
      lines.map do |line|
        from, relation, to = line.split(" ")
        from_n, to_n = relation.split("--")

        t = ->(string) {
          case string
          when "?" then "0..1"
          when "1" then "1"
          when "*" then "0..n"
          when "+" then "1..n"
          end
        }

        edge_template % {
          from: from,
          from_n: t.(from_n),
          to: to,
          to_n: t.(to_n),
        }
      end
    end
  end.join("\n\n")

File.open("test.dot", "w+") do |f|
  f.puts "
digraph G {
  node [shape=plaintext]

  #{contents}
}
  "
end

`dot test.dot -Tpdf > test.pdf`
`open test.pdf`