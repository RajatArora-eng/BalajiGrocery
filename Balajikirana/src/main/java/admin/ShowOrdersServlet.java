package admin;

import dao.Dbconn;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;
import java.util.*;

@WebServlet("/admin/ShowOrdersServlet")
public class ShowOrdersServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        List<Map<String,Object>> orders = new ArrayList<>();
        Dbconn db = null;
        try {
            db = new Dbconn();
            Connection con = db.getConnection();

            String sql = "SELECT o.id, o.total_amount, o.status, o.created_at, o.address, u.name AS user_name, " +
                         "(SELECT COUNT(*) FROM order_items oi WHERE oi.order_id = o.id) AS items " +
                         "FROM orders o LEFT JOIN users u ON o.user_id = u.id ORDER BY o.created_at DESC";

            try (PreparedStatement ps = con.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    Map<String,Object> m = new HashMap<>();
                    m.put("id", rs.getInt("id"));
                    m.put("total", rs.getDouble("total_amount"));
                    m.put("status", rs.getString("status"));
                    m.put("created_at", rs.getTimestamp("created_at"));
                    m.put("items", rs.getInt("items"));
                    String storedAddress = rs.getString("address");
                    String dbUserName = rs.getString("user_name");

                    // Extract receiver name from address (if available).
                    String receiver = extractReceiverFromAddress(storedAddress);

                    // Prefer receiver name; if missing, use DB user name; else 'Guest'
                    String displayName = (receiver != null && !receiver.isBlank()) ?
                                            receiver :
                                            (dbUserName != null && !dbUserName.isBlank() ? dbUserName : "Guest");

                    m.put("customer", displayName);
                    m.put("raw_address", storedAddress); // optional for details view
                    orders.add(m);
                }
            }

            req.setAttribute("orders", orders);
            req.getRequestDispatcher("/admin/showorders.jsp").forward(req, resp);
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/admin/showorders.jsp?error=" +
                              java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
        } finally {
            try { if (db != null) db.close(); } catch (Exception ignored) {}
        }
    }

    // Helper: returns the leading token(s) from the saved address that look like a name.
    private static String extractReceiverFromAddress(String address) {
        if (address == null) return null;
        address = address.trim();
        if (address.isEmpty()) return null;

        // Common patterns your checkout builds: "ReceiverName, House..., Landmark..., Contact: 98xxxx | fulladdress"
        // Strategy:
        // 1) split by newline first (if present)
        // 2) split by "Contact" or "Contact:" and remove trailing part
        // 3) take substring before first comma as receiver if that seems short (<= 60 chars)
        try {
            // cut off contact portion if present
            String tmp = address;
            int ci = tmp.indexOf("Contact");
            if (ci >= 0) tmp = tmp.substring(0, ci);

            // use first line or first comma-separated token
            String firstLine = tmp.split("\\r?\\n")[0].trim();
            if (firstLine.contains(",")) {
                String cand = firstLine.substring(0, firstLine.indexOf(",")).trim();
                if (!cand.isEmpty()) return cand;
            }

            // if no comma, maybe the address starts with name + dash etc.
            // take up to first " - " or pipe
            int dash = firstLine.indexOf(" - ");
            if (dash > 0) return firstLine.substring(0, dash).trim();

            int pipe = firstLine.indexOf("|");
            if (pipe > 0) return firstLine.substring(0, pipe).trim();

            // fallback: if first token length reasonable, return it (could be full name)
            if (firstLine.length() <= 80) return firstLine;

        } catch (Exception ignore) {}

        return null;
    }
}
