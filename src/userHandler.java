import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

public class userHandler extends JFrame{
    private JPanel mainPanel;
    private JButton jobsButton;
    private JButton applyButton;
    private JButton cancelButton;
    private JButton activateButton;
    private JButton apHistButton;
    private JPanel coreButtons;
    private JTable dataTable;
    private JButton logOutButton;
    private JButton applicationsButton;

    /* For database connection */
    private static final String JDBC_URL = Main.JDBC_URL;
    private static final String DB_USER = Main.DB_USER;
    private static final String DB_PASSWORD = Main.DB_PASSWORD;

    public userHandler(){
        setContentPane(mainPanel);
        setTitle(login.user);
        setVisible(true);
        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setSize(1100,750);
        setResizable(false);
        setLocationRelativeTo(null);
        setIconImage(Toolkit.getDefaultToolkit().getImage(getClass().getResource("user.png")));


        jobsButton.addActionListener(new ActionListener(){@Override
            public void actionPerformed(ActionEvent e) {
                DBHandler.displayTableData(dataTable,"job",'u', login.user);
            }
        });

        apHistButton.addActionListener(new ActionListener(){@Override
            public void actionPerformed(ActionEvent e) {
                DBHandler.displayTableData(dataTable,"application_history",'u', login.user);
            }
        });

        applicationsButton.addActionListener(new ActionListener(){@Override
            public void actionPerformed(ActionEvent e) {
                DBHandler.displayTableData(dataTable,"applies",'u', login.user);
            }
        });

        applyButton.addActionListener(new ActionListener(){@Override
            public void actionPerformed(ActionEvent e) {
                applySP(login.user,'i');
            }
        });

        cancelButton.addActionListener(new ActionListener(){@Override
            public void actionPerformed(ActionEvent e) {
            applySP(login.user,'c');
            }
        });

        activateButton.addActionListener(new ActionListener(){@Override
            public void actionPerformed(ActionEvent e) {
            applySP(login.user,'a');
            }
        });

        logOutButton.addActionListener(new ActionListener(){@Override
            public void actionPerformed(ActionEvent e) {
                dispose();
                new login();
            }
        });
    }

    private void applySP(String candidate, char action){
        /*   Using OptionPane to let the user choose job id   */
        int job = DBHandler.jobOptionPane();

        if(job == -1)
            return;

        if(!DBHandler.confirmation(false))
            return;

        try{
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection connection = DriverManager.getConnection(JDBC_URL, DB_USER, DB_PASSWORD)) {
                Statement statement = connection.createStatement();
                String query = "CALL applyProcedure('"+candidate+"',"+job+","+"'"+action+"'"+")";
                statement.executeQuery(query);
            }
        } catch(ClassNotFoundException | SQLException er)
        {
            er.printStackTrace();
        }
    }
}
