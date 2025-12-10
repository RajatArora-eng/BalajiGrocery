package admin;

import dao.Dbconn;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.ResultSet;


@WebServlet("/admin/EditCategoryServlet")
public class EditCategoryServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String idStr = req.getParameter("id");
        if (idStr == null || idStr.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/admin/ShowCategory.jsp?error=no_id");
            return;
        }

        int id;
        try {
            id = Integer.parseInt(idStr);
        } catch (NumberFormatException ex) {
            resp.sendRedirect(req.getContextPath() + "/admin/ShowCategory.jsp?error=bad_id");
            return;
        }

        Dbconn db = null;
        ResultSet rs = null;
        try {
            db = new Dbconn();
            rs = db.getCategory(id); // returns ResultSet (caller must close)
            if (rs.next()) {
                req.setAttribute("cat_id", rs.getInt("id"));
                req.setAttribute("cat_name", rs.getString("name"));
                req.setAttribute("cat_image", rs.getString("image"));
                req.getRequestDispatcher("/admin/editCategory.jsp").forward(req, resp);
            } else {
                // not found
                resp.sendRedirect(req.getContextPath() + "/admin/ShowCategory.jsp?error=not_found");
            }
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/admin/ShowCategory.jsp?error=db_error");
        } finally {
            try { if (rs != null) rs.close(); } catch (Exception ignored) {}
            try { if (db != null) db.close(); } catch (Exception ignored) {}
        }
    }

    // optional: forward POST to GET so forms can also link with POST if needed
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        doGet(req, resp);
    }
}
