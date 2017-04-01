input="
[Person]
*name
height
weight
+birth_location_id

[Location]
*id
city
state
country

Person *--1 Location
"

template = %Q(
  digraph G {
    "Record" [ label=<<table>
                          <tr>
                              <td>A</td>
                              <td bgcolor='#00CC11'>B</td>
                          </tr>
                       </table> 
                      >
             ];
  }
)

node_template = %{
  "%entity_name" [label=<%{entity_contents}>]
}

table_template = %(
<table border="0" cellborder="0" cellspacing="0">
  <tr>
    <td colspan="3" border="1" bgcolor="#EEEEEE" cellpadding="0"><font face="PT Mono"><b>%{entity_name}</b></font></td>
  </tr>
  %{attributes}
</table>
)

row_template = %Q(
<tr>
  <td border="1" sides="l" align="left" port="id"><font face="PT Mono">%{column_name}&nbsp;</font></td>
  <td align="left"><font color="#999999" face="PT Mono">%{column_type}&nbsp;</font></td>
  <td border="1" sides="r" align="left"><font color="#CCCCCC" face="PT Mono">%{null_or_not}</font></td>
</tr>
)

contents =
  input.split("\n\n").map do |group|
    lines = group.strip.split("\n")

    if lines[0].start_with("[")
      # dealing with box group
      entity_name = lines[0].scan(/\w+/)[0]

      attributes =
        lines[1..-1].map do |line|
          column_name, column_type, null_or_not = line.split(",")

          row_template % {
            column_name: column_name,
            column_type: column_type,
            null_or_not: null_or_not || "&nbsp;"
          }
        end.join("\n")

      table_template % {
        entity_name: entity_name,
        attributes: attributes
      }
    else
      ""
      # dealing with connections group
    end
  end.join("\n\n")

output = "
  digraph G {
    #{contents}
  }
"

puts output
