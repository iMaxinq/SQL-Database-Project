import javax.swing.*;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.DefaultTableModel;
import javax.swing.table.JTableHeader;
import javax.swing.table.TableRowSorter;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.sql.*;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;

public class DBHandler extends JFrame {
    private JPanel mainPanel;
    protected JComboBox tabSelect;
    private JButton insertButton;
    private JButton updateButton;
    private JButton deleteButton;
    private JPanel Tables;
    private JTable dataTable;
    private JPanel coreButtons;
    private JButton clearDB;
    private JButton ClearTable;
    private JButton findEmployee;
    private JButton logOutButton;


    /* For database connection */
    protected static final String JDBC_URL = Main.JDBC_URL;
    protected static final String DB_USER = Main.DB_USER;
    protected static final String DB_PASSWORD = Main.DB_PASSWORD;

    public List<JTextField> textFieldList = new ArrayList<>();
    public List<String> labelList = new ArrayList<>();
    public List<JComboBox> comboBoxList = new ArrayList<>();


    public DBHandler(){
        setContentPane(mainPanel);
        setTitle(login.user);
        setVisible(true);
        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setSize(1100,750);
        setResizable(false);
        setLocationRelativeTo(null);
        setIconImage(Toolkit.getDefaultToolkit().getImage(getClass().getResource("admin.png")));

        fillComboBox(tabSelect);

        tabSelect.addActionListener(new ActionListener(){@Override
            public void actionPerformed(ActionEvent e) {
                String selectedTable = (String) tabSelect.getSelectedItem();
                displayTableData(dataTable,selectedTable,'a',"");
            }
        });

        insertButton.addActionListener(new ActionListener(){@Override
            public void actionPerformed(ActionEvent e) {
                dispose();
                new Insert(tabSelect.getSelectedItem());
            }
        });

        updateButton.addActionListener(new ActionListener(){@Override
            public void actionPerformed(ActionEvent e) {
                dispose();
                new Update(tabSelect.getSelectedItem());
            }
        });

        deleteButton.addActionListener(new ActionListener(){@Override
            public void actionPerformed(ActionEvent e) {
                DefaultTableModel defaultTableModel = (DefaultTableModel) dataTable.getModel();

                if(dataTable.getSelectedRowCount() == 1){
                    if(!confirmation(false))
                        return;
                    try{
                        Class.forName("com.mysql.cj.jdbc.Driver");
                        try (Connection connection = DriverManager.getConnection(JDBC_URL, DB_USER, DB_PASSWORD)) {

                            String selectedTable = (String) tabSelect.getSelectedItem();
                            DatabaseMetaData metaData = connection.getMetaData();

                            List<String> primaryKeyColumns = getPrimaryKeyColumns(metaData,selectedTable);

                            int row = dataTable.getSelectedRow();

                            String query = "DELETE FROM " + selectedTable + " WHERE " + whereConditions(primaryKeyColumns);

                            try (PreparedStatement prepStatement = connection.prepareStatement(query)){
                                for (int i = 0; i < primaryKeyColumns.size(); i++) {
                                    int pkIndex = defaultTableModel.findColumn(primaryKeyColumns.get(i));
                                    Object value = defaultTableModel.getValueAt(row, pkIndex);
                                    prepStatement.setObject(i + 1, value);
                                }
                                prepStatement.executeUpdate();
                                /*  Remove row from GUI after removing from DB  */
                                defaultTableModel.removeRow(dataTable.getSelectedRow());
                            }
                        }
                    } catch(ClassNotFoundException | SQLException er)
                    {
                        er.printStackTrace();
                    }
                }else{
                    if (dataTable.getRowCount() == 0)
                        JOptionPane.showMessageDialog(null,"Table is empty.");
                    else
                        JOptionPane.showMessageDialog(null,"Select a single row.");
                }
            }
        });

        clearDB.addActionListener(new ActionListener(){@Override
            public void actionPerformed(ActionEvent e) {
                if(!confirmation(false))
                    return;
                if(!confirmation(true))
                    return;

                try{
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    try (Connection connection = DriverManager.getConnection(JDBC_URL, DB_USER, DB_PASSWORD)) {
                        Statement statement = connection.createStatement();
                        String query = "CALL clearDB()";
                        statement.executeQuery(query);
                    }
                } catch(ClassNotFoundException | SQLException err)
                {
                    err.printStackTrace();
                }
            }
        });

        ClearTable.addActionListener(new ActionListener(){@Override
            public void actionPerformed(ActionEvent e) {
                if(!confirmation(false))
                    return;
                if(!confirmation(true))
                    return;

                String selectedTable = tabSelect.getSelectedItem().toString();

                try{
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    try (Connection connection = DriverManager.getConnection(JDBC_URL, DB_USER, DB_PASSWORD)) {
                        Statement statement = connection.createStatement();
                        String query = "CALL clearTable('" + selectedTable + "')";
                        statement.executeQuery(query);
                    }
                } catch(ClassNotFoundException | SQLException e1)
                {
                    e1.printStackTrace();
                }
            }
        });

        findEmployee.addActionListener(new ActionListener(){@Override
            public void actionPerformed(ActionEvent e) {

                int job = jobOptionPane();

                if(job == -1)
                    return;

                try{
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    try (Connection connection = DriverManager.getConnection(JDBC_URL, DB_USER, DB_PASSWORD)) {
                        Statement statement = connection.createStatement();
                        String query = "CALL findEmployee("+job+")";
                        ResultSet resultSet = statement.executeQuery(query);

                        String message = "";

                        if(resultSet.next())
                            message = resultSet.getObject(1).toString();
                        else
                            message = "No candidates for job.";

                        JOptionPane.showMessageDialog(null,message);

                    }
                } catch(ClassNotFoundException | SQLException e1)
                {
                    e1.printStackTrace();
                }
            }
        });

        logOutButton.addActionListener(new ActionListener(){@Override
            public void actionPerformed(ActionEvent e) {
                dispose();
                new login();
            }
        });
    }

    public static int jobOptionPane(){
        JComboBox jobs = makeComboBoxes("jobs");

        int input = JOptionPane.showConfirmDialog(null,jobs,"Select job",JOptionPane.DEFAULT_OPTION);

        int job = -1;

        if(input == JOptionPane.OK_OPTION)
            job = Integer.parseInt(jobs.getSelectedItem().toString());

        return job;
    }
    public static boolean confirmation(boolean important){
        String message;

        if(important)
            message = "!!!ATTENTION!!! PROCEEDING WILL DESTROY THE DATABASE !!!ATTENTION!!! are you sure?";
        else
            message = "Are you sure you want to continue?";

        int choice = JOptionPane.showConfirmDialog(null,message,"Confirm",JOptionPane.YES_NO_OPTION,JOptionPane.WARNING_MESSAGE);
        if (choice == JOptionPane.YES_OPTION) {
            return true;
        }else
            return false;
    }
    protected String whereConditions(List<String> primaryKeyColumns){
        StringBuilder whereConds = new StringBuilder();

        for(String column : primaryKeyColumns)
            whereConds.append(column).append(" = ? AND ");

        whereConds.delete(whereConds.length() - 5, whereConds.length()); //Delete the last AND

        return whereConds.toString();
    }

    private void addCB(JPanel txtFields, JTextField textField, String typeOfCB){
        JComboBox comboBox = makeComboBoxes(typeOfCB);
        txtFields.add(comboBox);
        textField.setText("CB");
        comboBoxList.add(comboBox);
        textFieldList.add(textField); // Add textfield to list in place of comboBox
    }
    protected void addTFnLabels(String tableName, JPanel txtFields, JTable selectedTableData, char action){
        DefaultTableModel tableModel = (DefaultTableModel) selectedTableData.getModel();
        int columnCount = tableModel.getColumnCount();

        txtFields.setLayout(new FlowLayout(FlowLayout.LEFT));

        /*  Makes Textfields and Labels based on the action  */
        for (int i = 0; i < columnCount; i++) {
            String columnName = selectedTableData.getColumnName(i);

            /*  If action is i (insert) then not all columns are added  */
            if(action == 'i'){
                switch (tableName){
                    case "user": if(Objects.equals(columnName, "reg_date"))  continue; break;

                    case "admins": if(!Objects.equals(columnName,"username")) continue; break;

                    case "job": if(Objects.equals(columnName,"id") || Objects.equals(columnName,"announce_date") || Objects.equals(columnName,"submission_date") || Objects.equals(columnName,"cancellation_deadline")) continue; break;

                    case "applies": if(!Objects.equals(columnName,"cand_usrname") && !Objects.equals(columnName,"job_id")) continue; break;

                    case "project": if(Objects.equals(columnName,"num")) continue; break;

                    case "application_history": if(Objects.equals(columnName,"appl_state")) continue; break;
                }
            }



            JLabel label = new JLabel(columnName);

            JTextField textField = new JTextField();

            if(Objects.equals(tableName,"application_history") && Objects.equals(columnName,"appl_state")){
                textFieldList.add(textField);
                continue;
            }

            if(action == 'i')
                textField.setPreferredSize(new Dimension(100,25));
            else
                textField.setPreferredSize(new Dimension(150,25));

            txtFields.add(label);
            labelList.add(columnName);


            /*  Add comboBoxes  */
            switch (tableName){
                case "admins", "employee":{
                    if(i == 0){
                        addCB(txtFields,textField,"users");
                        continue;
                    }
                    break;
                }
                case "application_history":{
                    if(i == 0 || i == 1){
                        addCB(txtFields,textField,"evaluators");
                        continue;
                    }
                    if(i == 2){
                        addCB(txtFields,textField,"employees");
                        continue;
                    }
                    if(i == 3){
                        addCB(txtFields,textField,"jobs");
                        continue;
                    }
                    break;
                }
                case "applies":{
                    if(i == 0){
                        addCB(txtFields,textField,"employees");
                        continue;
                    }
                    if(i == 1){
                        addCB(txtFields,textField,"jobs");
                        continue;
                    }
                    break;
                }
                case "evaluator":{
                    if(i == 0){
                        addCB(txtFields,textField,"users");
                        continue;
                    }
                    if(i == 2){
                        addCB(txtFields,textField,"etairia");
                        continue;
                    }
                    break;
                }
                case "has_degree":{
                    if(i == 0){
                        addCB(txtFields,textField,"degrees_title");
                        continue;
                    }
                    if(i == 1){
                        addCB(txtFields,textField,"degrees_idryma");
                        continue;
                    }
                    if(i == 2){
                        addCB(txtFields,textField,"employees");
                        continue;
                    }
                    break;
                }
                case "job":{
                    if(i == 0){
                        addCB(txtFields,textField,"jobs");
                        continue;
                    }
                    if(i == 5){
                        addCB(txtFields,textField,"evaluators");
                        continue;
                    }
                    if(i == 6 || i == 7){
                        addCB(txtFields,textField,"evaluatorsNull");
                        continue;
                    }

                    break;
                }
                case "languages","project":{
                    if(i == 0){
                        addCB(txtFields,textField,"employees");
                        continue;
                    }
                    break;
                }
                case "requires":{
                    if(i == 0){
                        addCB(txtFields,textField,"jobs");
                        continue;
                    }
                    if(i == 1){
                        addCB(txtFields,textField,"subjects");
                        continue;
                    }
                    break;
                }
                case "subject":{
                    if(i == 2){
                        addCB(txtFields,textField,"subjectsNull");
                        continue;
                    }
                    break;
                }
            }

            /*  Add textFields  */
            txtFields.add(textField);
            textFieldList.add(textField);

            if(Objects.equals(tableName,"languages")){
                JLabel languages = new JLabel("('EN','FR','SP','GE','CH','GR')");
                txtFields.add(languages);
            }
        }
    }
    private static JComboBox makeComboBoxes(String column){
        JComboBox fkCB = new JComboBox<>();
        String query = "";

        switch (column){
            case "users": query = "SELECT username FROM user"; break;

            case "jobs": query = "SELECT id FROM job ORDER BY 1";break;

            case "evaluators","evaluatorsNull": query = "SELECT username FROM evaluator";break;

            case "employees": query = "SELECT username FROM employee";break;

            case "etairia": query = "SELECT AFM FROM etairia";break;

            case "degrees_title": query = "SELECT titlos FROM degree";break;

            case "degrees_idryma": query = "SELECT idryma FROM degree";break;

            case "subjects","subjectsNull": query = "SELECT title FROM subject";break;
        }

        try{
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection connection = DriverManager.getConnection(JDBC_URL, DB_USER, DB_PASSWORD)) {
                Statement statement = connection.createStatement();
                ResultSet resultSet = statement.executeQuery(query);

                /*  NULL choice  */
                if(Objects.equals(column,"subjectsNull") || Objects.equals(column,"evaluatorsNull"))
                    fkCB.addItem(null);

                /*  No NULL choice*/
                while(resultSet.next()){
                    String tableName = resultSet.getString(1);
                    fkCB.addItem(tableName);
                }
            }
        } catch(ClassNotFoundException | SQLException e)
        {
            e.printStackTrace();
        }
        return fkCB;
    }
    protected boolean allTextFieldsEmpty(char action) {
        for (JTextField textField : textFieldList){
            if(action == 'u' && Objects.equals(textField.getText().trim(),"CB"))
                continue;
            if (!textField.getText().trim().isEmpty()){
                return false;
            }
        }
        return true;
    }
    protected void clearTextFields(){
        for (JTextField textField : textFieldList){
            if(!Objects.equals(textField.getText(),"CB"))
                textField.setText("");
        }
    }
    protected   String[] makeRow(){
        String data[] = new String[textFieldList.size()];
        int j = 0;
        for(int i = 0; i < textFieldList.size(); i++){
            if(Objects.equals(textFieldList.get(i).getText(),"CB")){
                if(comboBoxList.get(j).getSelectedItem() == null)
                    data[i] = "";
                else
                    data[i] = comboBoxList.get(j).getSelectedItem().toString();
                j ++;
            }else {
                JTextField textField = textFieldList.get(i);
                data[i] = textField.getText();
            }
        }
        return data;
    }
    protected static List<String> getPrimaryKeyColumns(DatabaseMetaData metaData, String tableName) throws SQLException {
        List<String> primaryKeyColumns = new ArrayList<>();

        ResultSet primaryKeys = metaData.getPrimaryKeys("project1", "project1", tableName);

        while (primaryKeys.next()) {
            String primaryKeyColumn = primaryKeys.getString("COLUMN_NAME");
            primaryKeyColumns.add(primaryKeyColumn);
        }

        return primaryKeyColumns;
    }
    public static void displayTableData(JTable jTableName, String tableName, char user, String username){ // a for admin u for user... username in case of u
        String query = "";

        if(user == 'a')
            query = "SELECT * FROM " + tableName;
        else if(user == 'u') {
            if(Objects.equals(tableName,"job"))
                query = "SELECT id, start_date, salary, position, edra, announce_date, submission_date, cancellation_deadline FROM job";
            else if(Objects.equals(tableName,"application_history")) {
                query = "SELECT job_id, appl_state, final_grade FROM application_history WHERE cand_usrname = '" + username + "'";
            } else if(Objects.equals(tableName,"applies")) {
                query = "SELECT job_id, appl_state ,appl_date, grade1, grade2 FROM applies WHERE cand_usrname = '" + username + "'";
            }
        }

        try{
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection connection = DriverManager.getConnection(JDBC_URL, DB_USER, DB_PASSWORD)) {
               try (Statement statement = connection.createStatement()){
                   ResultSet resultSet = statement.executeQuery(query);

                    ResultSetMetaData metaData = resultSet.getMetaData();
                    final int columnCount = metaData.getColumnCount();

                    /*  Overriding default mode of saving all types as String objects in JTable to ints and floats*/
                   DefaultTableModel tableModel = new DefaultTableModel(){@Override
                        public Class<?> getColumnClass(int columnIndex) {
                            if (columnIndex >= 0 && columnIndex < columnCount) {
                                try {
                                    switch (metaData.getColumnType(columnIndex + 1)) {
                                        case Types.INTEGER:
                                            return Integer.class;
                                        case Types.REAL: // REAL kai oxi FLOAT giati apo to table ths DB ta diavazei REAL
                                            return Float.class;
                                        default:
                                            return Object.class;
                                    }
                                }catch (SQLException sqlException){
                                    sqlException.printStackTrace();
                                }
                            }
                            return Object.class;
                        }
                   };
                   jTableName.setModel(tableModel);

                   /*   Sorter   */
                   TableRowSorter<DefaultTableModel> sorter = new TableRowSorter<DefaultTableModel>(tableModel);

                   /*   Comparator for floats   */
                   for (int i = 0; i < columnCount; i++) {
                       if (metaData.getColumnType(i + 1) == Types.FLOAT) {
                           sorter.setComparator(i, Comparator.<Float, Float>comparing(Float::valueOf));
                       }
                   }

                   jTableName.setRowSorter(sorter);

                   /*  Adding columns  */
                   for(int i = 1; i <= columnCount; i++){
                       tableModel.addColumn(metaData.getColumnName(i));
                   }

                   /*   Render all fields to the left   */
                   DefaultTableCellRenderer renderer = new DefaultTableCellRenderer();
                   renderer.setHorizontalAlignment(DefaultTableCellRenderer.LEFT);

                   for (int i = 0; i < jTableName.getColumnCount(); i++) {
                       jTableName.getColumnModel().getColumn(i).setCellRenderer(renderer);
                   }


                    /*  Drag and drop columns false  */
                   JTableHeader header = jTableName.getTableHeader();
                   header.setReorderingAllowed(false);

                    /*  Adding rows  */
                    while(resultSet.next()){
                        Object[] rowData = new Object[columnCount];
                        for(int i = 1; i<=columnCount; i++){
                            rowData[i-1] = resultSet.getObject(i);
                        }
                        tableModel.addRow(rowData);
                    }
               }
            }
        } catch(ClassNotFoundException | SQLException e)
        {
            e.printStackTrace();
        }
    }
    private static void fillComboBox(JComboBox tableCB){
        try{
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection connection = DriverManager.getConnection(JDBC_URL, DB_USER, DB_PASSWORD)) {
                Statement statement = connection.createStatement();
                String query = "SHOW TABLES";
                ResultSet resultSet = statement.executeQuery(query);
                
                while(resultSet.next()){
                    String tableName = resultSet.getString(1);
                    tableCB.addItem(tableName);
                }
            }
        } catch(ClassNotFoundException | SQLException e)
        {
            e.printStackTrace();
        }
    }
}
