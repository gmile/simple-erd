template="
  digraph G {
    \"Record\" [ label=<<table>
                          <tr>
                              <td>A</td>
                              <td bgcolor='#00CC11'>B</td>
                          </tr>
                       </table> 
                      >
             ];
  }
"

echo $template > /tmp/models_exp.dot
dot /tmp/models_exp.dot -Tpdf > /tmp/models.pdf
open /tmp/models.pdf
