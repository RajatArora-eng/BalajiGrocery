package admin;

import dao.Dbconn;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;

@WebServlet("/admin/UpdateOrderStatusServlet")
public class UpdateOrderStatusServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        String idParam = req.getParameter("id");
        String status = req.getParameter("status");

        // Validate
        if (idParam == null || status == null || status.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() +
                    "/admin/ShowOrdersServlet?error=Invalid+status+or+ID");
            return;
        }

        int orderId;
        try {
            orderId = Integer.parseInt(idParam);
        } catch (Exception e) {
            resp.sendRedirect(req.getContextPath() +
                    "/admin/ShowOrdersServlet?error=Invalid+order+ID");
            return;
        }

        Dbconn db = null;
        Connection con = null;

        try {
            db = new Dbconn();
            con = db.getConnection();

            String sql = "UPDATE orders SET status = ? WHERE id = ?";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, status);
            ps.setInt(2, orderId);

            int rows = ps.executeUpdate();

            if (rows > 0) {
                resp.sendRedirect(req.getContextPath() + "/admin/ShowOrdersServlet?updated=1");
            } else {
                resp.sendRedirect(req.getContextPath() + "/admin/ShowOrdersServlet?error=Not+updated");
            }

        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() +
                    "/admin/ShowOrdersServlet?error=" + e.getMessage());
        } finally {
            try { if (db != null) db.close(); } catch (Exception ignored) {}
        }
    }
}
