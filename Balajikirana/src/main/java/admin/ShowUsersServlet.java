package admin;

import dao.Dbconn;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;
import java.util.*;

@WebServlet("/admin/ShowUsersServlet")
public class ShowUsersServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

        List<Map<String,Object>> users = new ArrayList<>();
        Dbconn db = null;

        try {
            db = new Dbconn();
            Connection con = db.getConnection();

            String sql = "SELECT id, name, email, phone, created_at FROM users ORDER BY id ASC";

            try (PreparedStatement ps = con.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    Map<String,Object> m = new HashMap<>();
                    m.put("id", rs.getInt("id"));
                    m.put("name", rs.getString("name"));
                    m.put("email", rs.getString("email"));
                    m.put("phone", rs.getString("phone"));
                    m.put("created_at", rs.getTimestamp("created_at"));
                    users.add(m);
                }
            }

            req.setAttribute("users", users);

            System.out.println("[ShowUsersServlet] Users count: " + users.size());

            req.getRequestDispatcher("/admin/showusers.jsp").forward(req, resp);

        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/admin/showusers.jsp?error=" +
                    java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
        } finally {
            try { if (db != null) db.close(); } catch (Exception ignored) {}
        }
    }
}
