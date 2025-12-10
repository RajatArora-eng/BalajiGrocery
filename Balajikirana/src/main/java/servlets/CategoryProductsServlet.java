package servlets;

import com.google.gson.Gson;
import dao.Dbconn;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@WebServlet("/CategoryProductsServlet")
public class CategoryProductsServlet extends HttpServlet {
    private static final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        String catIdStr = req.getParameter("category_id");
        if (catIdStr == null || catIdStr.trim().isEmpty()) {
            resp.getWriter().write(gson.toJson(new ArrayList<>()));
            return;
        }

        try {
            int catId = Integer.parseInt(catIdStr);
            Dbconn db = new Dbconn();
            try {
                // Use a safe DAO method that orders by id (avoids missing created_at)
                List<Map<String,Object>> products = db.getProductsListByCategory(catId);
                resp.getWriter().write(gson.toJson(products));
            } finally {
                db.close();
            }
        } catch (NumberFormatException nfe) {
            resp.setStatus(400);
            resp.getWriter().write(gson.toJson(new ArrayList<>()));
        } catch (Exception e) {
            // For development: return an error object with message (remove in production)
            e.printStackTrace();
            resp.setStatus(500);
            Map<String,String> err = Map.of("error", "server_error", "message", e.getMessage() == null ? "unknown" : e.getMessage());
            resp.getWriter().write(gson.toJson(err));
        }
    }
}
