package admin;

import dao.Dbconn;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletResponse;

import java.io.IOException;

@WebServlet("/admin/DeleteCategoryServlet")
public class DeleteCategoryServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(true);
        try {
            String idStr = req.getParameter("id");
            if (idStr == null) {
                session.setAttribute("catMsg", "No category id provided.");
                resp.sendRedirect(req.getContextPath() + "/admin/Showcategories.jsp");
                return;
            }

            int id = Integer.parseInt(idStr);
            Dbconn db = new Dbconn();

            try {
                int refs = db.countProductsInCategory(id);
                if (refs > 0) {
                    // If admin explicitly passed force=1, try transactional delete (dangerous)
                    String force = req.getParameter("force");
                    if ("1".equals(force)) {
                        try {
                            int removed = db.deleteCategoryAndProductsTransactional(id);
                            if (removed > 0) {
                                session.setAttribute("catMsg", "Category and its " + refs + " product(s) deleted.");
                            } else {
                                session.setAttribute("catMsg", "Category not deleted. Please check constraints.");
                            }
                        } catch (Exception ex) {
                            session.setAttribute("catMsg", "Failed to delete category & products: " + ex.getMessage());
                        } finally {
                            db.close();
                        }
                    } else {
                        // Block deletion and inform admin how to proceed
                        session.setAttribute("catMsg",
                            "Category cannot be deleted — it has " + refs + " product(s). " +
                            "Either remove those products first or use the safe 'deactivate' option.");
                        db.close();
                    }
                    resp.sendRedirect(req.getContextPath() + "/admin/Showcategories.jsp");
                    return;
                }

                // no referencing products — safe to delete
                int r = db.deleteCategory(id);
                db.close();
                if (r > 0) {
                    session.setAttribute("catMsg", "Category deleted.");
                } else {
                    session.setAttribute("catMsg", "Category not found or not deleted.");
                }
                resp.sendRedirect(req.getContextPath() + "/admin/Showcategories.jsp");
            } catch (Exception e) {
                try { db.close(); } catch (Exception ignored) {}
                session.setAttribute("catMsg", "Error deleting category: " + e.getMessage());
                resp.sendRedirect(req.getContextPath() + "/admin/Showcategories.jsp");
            }

        } catch (NumberFormatException nfe) {
            session.setAttribute("catMsg", "Invalid category id.");
            resp.sendRedirect(req.getContextPath() + "/admin/Showcategories.jsp");
        } catch (Exception e) {
            // very defensive fall-back
            try {
                ((ServletResponse) req).getWriter().write("Unexpected error: " + e.getMessage());
            } catch (Exception ignored) {}
        }
    }
}
