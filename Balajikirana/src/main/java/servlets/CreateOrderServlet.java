
package servlets;

import com.google.gson.Gson;
import dao.Dbconn;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.PrintWriter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/CreateOrderServlet")
public class CreateOrderServlet extends HttpServlet {
    private static final Gson gson = new Gson();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) {
        resp.setContentType("application/json;charset=UTF-8");
        Map<String,Object> out = new HashMap<>();
        try (PrintWriter pw = resp.getWriter()) {
            req.setCharacterEncoding("UTF-8");

            // demo user id (replace with session user id)
            int userId = 1;

            String paytype = req.getParameter("paytype"); // "COD" or "ONLINE"
            String paymentId = req.getParameter("payment_id"); // razorpay payment id (optional)
            String address = req.getParameter("address");
            String lat = req.getParameter("lat");
            String lng = req.getParameter("lng");

            if (address == null || address.trim().isEmpty()) {
                resp.setStatus(400);
                out.put("success", false);
                out.put("message", "address required");
                pw.write(gson.toJson(out)); return;
            }

            Dbconn db = new Dbconn();

            // read cart items from DB for this user
            List<Map<String,Object>> items = null;
            try {
                // Dbconn.getCartItems returns ResultSet in your version.
                // If your Dbconn exposes a method returning List<Map>, use that.
                // Here we'll build productId->qty map by iterating ResultSet.
                java.sql.ResultSet rs = db.getCartItems(userId);
                java.util.Map<Integer,Integer> pidToQty = new java.util.HashMap<>();
                double total = 0.0;
                while (rs.next()) {
                    int pid = rs.getInt("product_id");
                    int qty = rs.getInt("quantity");
                    double price = rs.getDouble("price");
                    pidToQty.put(pid, pidToQty.getOrDefault(pid, 0) + qty);
                    total += price * qty;
                }
                // if cart empty
                if (pidToQty.isEmpty()) {
                    resp.setStatus(400);
                    out.put("success", false);
                    out.put("message", "cart empty");
                    pw.write(gson.toJson(out)); db.close(); return;
                }

                // if online payment chosen, verify payment_id exists (basic)
                if ("ONLINE".equalsIgnoreCase(paytype) && (paymentId == null || paymentId.trim().isEmpty())) {
                    resp.setStatus(400);
                    out.put("success", false);
                    out.put("message", "payment_id required for online payment");
                    pw.write(gson.toJson(out)); db.close(); return;
                }

                // create order (transactional inside Dbconn)
                int orderId = db.createOrder(userId, total, address + (lat!=null && lng!=null ? (" (lat:"+lat+",lng:"+lng+")") : ""), pidToQty);
                if (orderId <= 0) {
                    resp.setStatus(500);
                    out.put("success", false);
                    out.put("message", "failed to create order");
                    pw.write(gson.toJson(out));
                    db.close();
                    return;
                }

                // save payment record optional - you can create a payment table or update orders table
                // For now we return success
                out.put("success", true);
                out.put("order_id", orderId);
                out.put("total", total);
                pw.write(gson.toJson(out));
                db.close();
            } catch (Exception ex) {
                ex.printStackTrace();
                resp.setStatus(500);
                out.put("success", false);
                out.put("message", ex.getMessage());
                pw.write(gson.toJson(out));
                try { db.close(); } catch (Exception ignored) {}
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}