package admin;

import dao.Dbconn;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;
import java.util.*;

@WebServlet("/admin/PrintOrderServlet")
public class PrintOrderServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String idParam = req.getParameter("id");
        if (idParam == null) {
            resp.getWriter().write("Order ID missing.");
            return;
        }

        int orderId;
        try { orderId = Integer.parseInt(idParam); }
        catch (Exception e) {
            resp.getWriter().write("Invalid order ID.");
            return;
        }

        Map<String, Object> order = new HashMap<>();
        List<Map<String, Object>> items = new ArrayList<>();

        Dbconn db = null;
        Connection con = null;

        try {
            db = new Dbconn();
            con = db.getConnection();

            // Fetch order + user details
            String sql = "SELECT o.*, u.name AS user_name, u.email, u.phone " +
                         "FROM orders o LEFT JOIN users u ON o.user_id = u.id " +
                         "WHERE o.id = ?";

            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, orderId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        order.put("id", rs.getInt("id"));
                        order.put("user_id", rs.getInt("user_id"));
                        order.put("total_amount", rs.getDouble("total_amount"));
                        order.put("status", rs.getString("status"));
                        order.put("address", rs.getString("address"));
                        order.put("created_at", rs.getTimestamp("created_at"));
                        order.put("user_name", rs.getString("user_name"));
                        order.put("email", rs.getString("email"));
                        order.put("phone", rs.getString("phone"));
                    }
                }
            }

            // Fetch items using your Dbconn method
            try (ResultSet rs = db.getOrderItems(orderId)) {
                while (rs.next()) {
                    Map<String, Object> m = new HashMap<>();
                    m.put("product_id", rs.getInt("product_id"));
                    m.put("name", rs.getString("name"));
                    m.put("image", rs.getString("image"));
                    m.put("price", rs.getDouble("price"));
                    m.put("qty", rs.getInt("quantity"));
                    m.put("subtotal", rs.getDouble("price") * rs.getInt("quantity"));
                    items.add(m);
                }
            }

            req.setAttribute("order", order);
            req.setAttribute("items", items);

            req.getRequestDispatcher("/admin/printorder.jsp").forward(req, resp);

        } catch (Exception ex) {
            ex.printStackTrace();
            throw new ServletException(ex);
        } finally {
            try { if (db != null) db.close(); } catch (Exception ignored) {}
        }
    }
}

