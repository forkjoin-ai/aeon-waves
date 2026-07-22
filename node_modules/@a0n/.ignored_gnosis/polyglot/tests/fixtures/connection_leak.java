import java.sql.*;

public class DatabaseService {
    // Bug: connection leak -- not using try-with-resources.
    public String query(String sql) throws SQLException {
        Connection conn = DriverManager.getConnection("jdbc:mysql://localhost/db");
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery(sql);
        if (rs.next()) {
            return rs.getString(1);
            // BUG: conn never closed on this path
        }
        conn.close();
        return null;
    }
}
