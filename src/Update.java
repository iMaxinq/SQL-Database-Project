import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.sql.*;
import java.util.List;
import java.util.Objects;

public class Update extends DBHandler{


    private JPanel updatePanel;
    private JPanel data;
    private JPanel txtFields;
    private JButton backButton;
    private JButton confirmButton;
    private JTable selectedTableData;

    public Update(Object comboBoxSelection){
        setContentPane(updatePanel);
        setTitle(login.user);
        setVisible(true);
        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setSize(1100,750);
        setResizable(false);
        setLocationRelativeTo(null);
        setIconImage(Toolkit.getDefaultToolkit().getImage(getClass().getResource("admin.png")));

        displayTableData(selectedTableData,comboBoxSelection.toString(),'a', "");

        addTFnLabels(comboBoxSelection.toString(), txtFields, selectedTableData,'u');

        confirmButton.addActionListener(new ActionListener(){@Override
            public void actionPerformed(ActionEvent e) {
                if(allTextFieldsEmpty('u') || selectedTableData.getSelectedRowCount() != 1){
                    JOptionPane.showMessageDialog(null,"Select a single row to update.");
                }else{
                    if(!confirmation(false))
                        return;
                    String rowdata[] = makeRow();
                    try{
                        Class.forName("com.mysql.cj.jdbc.Driver");
                        try (Connection connection = DriverManager.getConnection(JDBC_URL, DB_USER, DB_PASSWORD)) {

                            DatabaseMetaData metaData = connection.getMetaData();

                            String selectedTable = (String) comboBoxSelection;

                            List<String> primaryKeyColumns = getPrimaryKeyColumns(metaData,selectedTable);

                            DefaultTableModel defaultTableModel = (DefaultTableModel) selectedTableData.getModel();
                            int row = selectedTableData.getSelectedRow();

                            String query = generateUpdateQuery(selectedTable,rowdata, primaryKeyColumns);

                            if(query.endsWith(" SET ")){
                                JOptionPane.showMessageDialog(null,"Nothing to update.");
                                return;
                            }

                            try(PreparedStatement preparedStatement = connection.prepareStatement(query)){
                                for (int i = 0; i < primaryKeyColumns.size(); i++) {
                                    int columnIndex = defaultTableModel.findColumn(primaryKeyColumns.get(i));
                                    Object value = defaultTableModel.getValueAt(row, columnIndex);
                                    preparedStatement.setObject(i + 1, value);
                                }
                                preparedStatement.executeUpdate();


                                for(int i = 0; i < rowdata.length ; i++) {
                                    if(!Objects.equals(rowdata[i],defaultTableModel.getValueAt(row, i)))
                                        defaultTableModel.setValueAt(rowdata[i],row, i);
                                }
                                clearTextFields();
                            }
                        }
                    } catch(ClassNotFoundException | SQLException er)
                    {
                        er.printStackTrace();
                        JOptionPane.showMessageDialog(null,er);
                    }
                }
            }
        });

        backButton.addActionListener(new ActionListener(){@Override
            public void actionPerformed(ActionEvent e) {
                dispose();
                new DBHandler();
            }
        });

        selectedTableData.addMouseListener(new MouseAdapter(){@Override
            public void mouseClicked(MouseEvent e){
                int row = selectedTableData.getSelectedRow();
                DefaultTableModel tableModel = (DefaultTableModel) selectedTableData.getModel();

                for(int i = 0; i < textFieldList.size(); i++){
                    JTextField temp = textFieldList.get(i);
                    if(Objects.equals(temp.getText(),"CB") || (Objects.equals(comboBoxSelection.toString(),"application_history") && Objects.equals(tableModel.getColumnName(i),"appl_state")) )
                        continue;
                    if(tableModel.getValueAt(row,i) == null)
                        continue;
                    temp.setText(tableModel.getValueAt(row,i).toString());
                }
            }
        });
    }

    private String generateUpdateQuery(String tableName, String[] rowData, List<String> primaryKeyColumns){
        DefaultTableModel tableModel = (DefaultTableModel) selectedTableData.getModel();
        int selectedRowIndex = selectedTableData.getSelectedRow();

        StringBuilder queryBuilder = new StringBuilder("UPDATE ");
        queryBuilder.append(tableName).append(" SET ");

        for (int i = 0; i < tableModel.getColumnCount(); i++) {

            if(Objects.equals(tableName,"application_history") && Objects.equals(tableModel.getColumnName(i),"appl_state"))
                continue;

            if(rowData[i].equals("")) // to compare objects
                rowData[i] = null;

            String castFromTable = "";// final object gia comparison

            if(tableModel.getValueAt(selectedRowIndex, i) == null) // set castFromTable = null giati an einai null to cast tou else petaei error
                castFromTable = null;
            else
                castFromTable = String.valueOf(tableModel.getValueAt(selectedRowIndex, i));// kano ta panta strings (ints & floats)


            if(!Objects.equals(rowData[i],castFromTable)){
                queryBuilder.append(tableModel.getColumnName(i)).append(" = ");
            }else continue;

            try{
                Float.parseFloat(rowData[i]);
                // If successful it's a float so no quotes
                queryBuilder.append(rowData[i]).append(",");
            }catch(NumberFormatException | NullPointerException eFloat){
                try{
                    Integer.parseInt(rowData[i]);
                    // If successful it's an integer so no quotes
                    queryBuilder.append(rowData[i]).append(",");
                }catch(NumberFormatException | NullPointerException eInt){
                    // If not integer or float it's a string so single quotes
                    if(rowData[i] == null)
                        queryBuilder.append(" NULL ").append(",");
                    else
                        queryBuilder.append("'").append(rowData[i]).append("'").append(",");
                }
            }
        }

        if(queryBuilder.charAt(queryBuilder.length() - 1) == ',')
            queryBuilder.deleteCharAt(queryBuilder.length() - 1);

        if(endsWithSubstring(queryBuilder," SET "))
            return queryBuilder.toString();

        queryBuilder.append(" WHERE ");

        queryBuilder.append(whereConditions(primaryKeyColumns));

        return queryBuilder.toString();
    }

    private boolean endsWithSubstring(StringBuilder stringBuilder, String substringToCheck) {
        int lastIndex = stringBuilder.lastIndexOf(substringToCheck);

        // Check if the last index is valid and if the substring is at the end
        return lastIndex != -1 && lastIndex == stringBuilder.length() - substringToCheck.length();
    }
}
