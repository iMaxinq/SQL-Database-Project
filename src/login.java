import javax.swing.*;
import java.awt.event.*;
import java.awt.*;
import java.sql.*;

public class login extends JFrame{
    private JLabel usernameLabel;
    private JLabel passwordLabel;
    private JButton clearButton;
    private JButton loginButton;
    private JPanel Login;
    private JTextField usernameTF;
    private JPasswordField passwordField;


    /* For database connection */
    private static final String JDBC_URL = Main.JDBC_URL;
    private static final String DB_USER = Main.DB_USER;
    private static final String DB_PASSWORD = Main.DB_PASSWORD;

    public static String user;
    public login(){
        setContentPane(Login);
        setTitle("Login");
        setVisible(true);
        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setSize(500,300);
        setResizable(false);
        setLocationRelativeTo(null);
        setIconImage(Toolkit.getDefaultToolkit().getImage(getClass().getResource("login.png")));

        loginButton.addActionListener(new ActionListener(){@Override
            public void actionPerformed(ActionEvent e) {
                String username = usernameTF.getText();
                user = username;
                char[] passwordChars = passwordField.getPassword();
                String password = new String(passwordChars);


                switch (credentialsCheck(username,password)) {
                    case 'a':{
                        usernameTF.setText("");
                        passwordField.setText("");
                        JOptionPane.showMessageDialog(null, "Login Successful as Admin!");
                        dispose();
                        new DBHandler();
                        break;
                    }
                    case 'e':{
                        usernameTF.setText("");
                        passwordField.setText("");
                        JOptionPane.showMessageDialog(null, "Login Successful as Employee!");
                        dispose();
                        new userHandler();
                        break;
                    }
                    default:{
                        usernameTF.setText("");
                        passwordField.setText("");
                        JOptionPane.showMessageDialog(null,"Invalid username or password. Please try again.");
                    }
                }
            }
        });
        
        clearButton.addActionListener(new ActionListener(){@Override
            public void actionPerformed(ActionEvent e) {
                usernameTF.setText("");
                passwordField.setText("");
            }
        });

        passwordField.addActionListener(new ActionListener(){@Override
            public void actionPerformed(ActionEvent e) {
                loginButton.doClick();
            }
        });
    }

    private char credentialsCheck(String username, String password) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection connection = DriverManager.getConnection(JDBC_URL, DB_USER, DB_PASSWORD)) {
                String query = "SELECT admins.username, password FROM admins inner join user on admins.username = user.username WHERE BINARY admins.username = ? AND password = ?";
                try (PreparedStatement preparedStatement = connection.prepareStatement(query)) {
                    preparedStatement.setString(1, username);
                    preparedStatement.setString(2, password);
                    try (ResultSet resultSet = preparedStatement.executeQuery()) {
                        if(resultSet.next()) // Returns true if the result set is not empty (valid credentials)
                            return 'a'; // a for admin
                        else{
                            query = "SELECT employee.username, password FROM employee inner join user on employee.username = user.username WHERE BINARY employee.username = ? AND password = ?";
                            try (PreparedStatement preparedStatement2 = connection.prepareStatement(query)){
                                preparedStatement2.setString(1, username);
                                preparedStatement2.setString(2, password);
                                try (ResultSet resultSet2 = preparedStatement2.executeQuery()){
                                    if(resultSet2.next()) // Returns true if the result set is not empty (valid credentials)
                                        return 'e';// e for employee
                                    else
                                        return 'i';
                                }
                            }
                        }
                    }
                }
            }
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
        }
        return 'i'; // i for invalid
    }


}


