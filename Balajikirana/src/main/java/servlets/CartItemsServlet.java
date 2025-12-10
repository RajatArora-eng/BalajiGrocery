package servlets;

import com.google.gson.Gson;
import dao.Dbconn;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/CartItemsServlet")
public class CartItemsServlet extends HttpServlet {
    private static final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        List<Map<String,Object>> out = new ArrayList<>();
        try {
            int userId = 1; // demo; replace with session user id when ready
            Dbconn db = new Dbconn();
            ResultSet rs = db.getCartItems(userId);
            try {
                ResultSetMetaData md = rs.getMetaData();
                int cols = md.getColumnCount();
                while (rs.next()) {
                    Map<String,Object> row = new HashMap<>(cols);
                    for (int i = 1; i <= cols; i++) {
                        String col = md.getColumnLabel(i);
                        Object val = rs.getObject(i);
                        row.put(col, val);
                    }
                    out.add(row);
                }
            } finally {
                try { if (rs != null) rs.getStatement().close(); } catch (Exception ignored) {}
                try { if (rs != null) rs.close(); } catch (Exception ignored) {}
                db.close();
            }

            resp.getWriter().write(gson.toJson(out));
        } catch (Exception e) {
            e.printStackTrace();
            resp.setStatus(500);
            resp.getWriter().write(gson.toJson(out)); // return empty array on error
        }
    }
}
