package servlets;

import com.google.gson.Gson;
import dao.Dbconn;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

@WebServlet("/UpdateCartServlet")
public class UpdateCartServlet extends HttpServlet {
    private static final Gson gson = new Gson();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        try {
            int userId = 1; // demo
            int productId = Integer.parseInt(req.getParameter("product_id"));
            int quantity = Integer.parseInt(req.getParameter("quantity"));

            Dbconn db = new Dbconn();
            int ok = db.updateCartQuantity(userId, productId, quantity);
            int count = db.getCartCount(userId);

            Map<String,Object> out = new HashMap<>();
            out.put("success", ok);
            out.put("count", count);
            resp.getWriter().write(gson.toJson(out));
        } catch (Exception e) {
            e.printStackTrace();
            resp.setStatus(500);
            Map<String,Object> out = new HashMap<>();
            out.put("success", false);
            out.put("message", e.getMessage());
            resp.getWriter().write(gson.toJson(out));
        }
    }
}
