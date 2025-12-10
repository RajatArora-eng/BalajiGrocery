package admin;

import dao.Dbconn;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Map;

@WebServlet("/admin/EditProductServlet")
public class EditProductServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String idStr = request.getParameter("id");
        if (idStr == null || idStr.isBlank()) {
            response.sendRedirect("products.jsp?error=no_id");
            return;
        }

        int id = Integer.parseInt(idStr);

        try {
            Dbconn db = new Dbconn();
            Map<String, Object> product = db.getProductMap(id);

            if (product == null) {
                response.sendRedirect("products.jsp?error=not_found");
                return;
            }

            // Send product to JSP
            request.setAttribute("product", product);

            request.getRequestDispatcher("/admin/editproduct.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("products.jsp?error=db_error");
        }
    }
}
