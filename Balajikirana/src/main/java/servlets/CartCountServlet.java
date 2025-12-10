package servlets;
import com.google.gson.Gson;
import dao.Dbconn;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;


@WebServlet("/CartCountServlet")
public class CartCountServlet extends HttpServlet {
private static final Gson gson = new Gson();
@Override
protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
resp.setContentType("application/json;charset=UTF-8");
try {Dbconn db = new Dbconn();

int userId = 1; // replace with session
int cnt = db.getCartCount(userId);
resp.getWriter().write(gson.toJson(new java.util.HashMap<String,Object>(){{ put("count", cnt); }}));
} catch (Exception e) {
resp.setStatus(500);
resp.getWriter().write(gson.toJson(new java.util.HashMap<String,Object>(){{ put("count", 0); }}));
}
}
}