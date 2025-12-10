package admin;

import dao.Dbconn;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import jakarta.servlet.ServletException;

import java.io.IOException;

@WebServlet("/admin/DeleteProductServlet")
public class DeleteProductServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(true);
        String idStr = req.getParameter("id");
        if (idStr == null) {
            session.setAttribute("prodMsg", "No product id provided.");
            resp.sendRedirect(req.getContextPath() + "/admin/Showproducts.jsp");
            return;
        }

        int id;
        try { id = Integer.parseInt(idStr); }
        catch (NumberFormatException nfe) {
            session.setAttribute("prodMsg", "Invalid product id.");
            resp.sendRedirect(req.getContextPath() + "/admin/Showproducts.jsp");
            return;
        }

        Dbconn db = null;
        try {
            db = new Dbconn();
            int refs = db.countOrderItemsForProduct(id);
            if (refs > 0) {
                // cannot delete — deactivate instead
                db.deactivateProduct(id);
                session.setAttribute("prodMsg", "Product is referenced by " + refs + " order(s). Product has been deactivated.");
            } else {
                // safe delete
                int r = db.safeDeleteProduct(id);
                if (r > 0) session.setAttribute("prodMsg", "Product deleted.");
                else session.setAttribute("prodMsg", "Product not deleted.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            session.setAttribute("prodMsg", "Error deleting/deactivating product: " + e.getMessage());
        } finally {
            try { if (db != null) db.close(); } catch (Exception ignored) {}
        }

        resp.sendRedirect(req.getContextPath() + "/admin/Showproducts.jsp");
    }
}

