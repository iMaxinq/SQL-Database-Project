import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.awt.event.*;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class Insert extends DBHandler{
    private JPanel insertPanel;
    private JTable selectedTableData;
    private JPanel data;
    private JPanel txtFields;
    private JButton confirmButton;
    private JButton backButton;


    public Insert(Object comboBoxSelection){
        setContentPane(insertPanel);
        setTitle(login.user);
        setVisible(true);
        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setSize(1100,750);
        setResizable(false);
        setLocationRelativeTo(null);
        setIconImage(Toolkit.getDefaultToolkit().getImage(getClass().getResource("admin.png")));

        displayTableData(selectedTableData,comboBoxSelection.toString(),'a',"");

        addTFnLabels(comboBoxSelection.toString(), txtFields, selectedTableData,'i');

        confirmButton.addActionListener(new ActionListener(){@Override
            public void actionPerformed(ActionEvent e) {
                if(allTextFieldsEmpty('i')){
                    JOptionPane.showMessageDialog(null,"Nothing to insert.");
                }else{
                    if(!confirmation(false))
                        return;
                    String rowdata[] = makeRow();
                    try{
                        Class.forName("com.mysql.cj.jdbc.Driver");
                        try (Connection connection = DriverManager.getConnection(JDBC_URL, DB_USER, DB_PASSWORD)) {

                            String query = generateInsertQuery(comboBoxSelection.toString(),rowdata);

                            try(PreparedStatement preparedStatement = connection.prepareStatement(query)){
                                preparedStatement.executeUpdate();

                                DefaultTableModel defaultTableModel = (DefaultTableModel) selectedTableData.getModel();
                                defaultTableModel.addRow(rowdata);

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
    }

    private String generateInsertQuery(String tableName, String[] rowData) {
        StringBuilder queryBuilder = new StringBuilder("INSERT INTO ");
        queryBuilder.append(tableName).append("(");

        for(int i = 0; i < labelList.size(); i++){
            if (i > 0) {
                queryBuilder.append(",");
            }
            queryBuilder.append(labelList.get(i));
        }


        queryBuilder.append(")").append(" VALUES (");

        for (int i = 0; i < rowData.length; i++) {
            if (i > 0) {
                queryBuilder.append(", ");
            }

            if(Objects.equals(rowData[i],"")){
                queryBuilder.append("null");
                continue;
            }

            // Check if the column is of type int
            try {
                Integer.parseInt(rowData[i]);
                // If successful it's an integer so no quotes
                queryBuilder.append(rowData[i]);
            } catch (NumberFormatException e) {
                // If not integer it's a string, so single quotes
                queryBuilder.append("'").append(rowData[i]).append("'");
            }
        }

        queryBuilder.append(")");

        return queryBuilder.toString();
    }
}
