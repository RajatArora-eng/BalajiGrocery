package servlets;

import com.google.gson.Gson;
import dao.Dbconn;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.Map;

@WebServlet("/GetProductServlet")
public class GetProductServlet extends HttpServlet {
    private static final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        try {
            String idStr = req.getParameter("id");
            if (idStr == null) { resp.getWriter().write("{}"); return; }
            int id = Integer.parseInt(idStr);
            Dbconn db = new Dbconn();
            Map<String,Object> p = (Map<String, Object>) db.getProduct(id);
            if (p == null) p = Map.of();
            resp.getWriter().write(gson.toJson(p));
        } catch (Exception e) {
            e.printStackTrace();
            resp.setStatus(500);
            resp.getWriter().write("{}");
        }
    }
}
