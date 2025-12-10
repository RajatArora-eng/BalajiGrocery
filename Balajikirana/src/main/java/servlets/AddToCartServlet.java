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

@WebServlet("/AddToCartServlet")
public class AddToCartServlet extends HttpServlet {

    private static final Gson gson = new Gson();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {

        resp.setContentType("application/json;charset=UTF-8");
        Map<String,Object> out = new HashMap<>();

        try {
            req.setCharacterEncoding("UTF-8");

            String pid = req.getParameter("product_id");
            String qtyStr = req.getParameter("quantity");

            if (pid == null || pid.isEmpty()) {
                out.put("success", false);
                out.put("message", "Product ID required");
                resp.getWriter().write(gson.toJson(out));
                return;
            }

            int productId = Integer.parseInt(pid);
            int qty = 1;
            try { qty = Integer.parseInt(qtyStr); } catch (Exception ignored) {}

            int userId = 1;  // demo user

            Dbconn db = new Dbconn();
            int result = db.addToCart(userId, productId, qty);   

            int count = db.getCartCount(userId);

            out.put("success", result > 0);
            out.put("count", count);

            resp.getWriter().write(gson.toJson(out));

        } catch (Exception e) {
            e.printStackTrace();
            out.put("success", false);
            out.put("message", "Server error: " + e.getMessage());
            resp.setStatus(500);
            resp.getWriter().write(gson.toJson(out));
        }
    }
}
