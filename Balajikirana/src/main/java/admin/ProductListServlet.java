package admin;
import dao.Dbconn;
import java.io.IOException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;



import jakarta.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import com.google.gson.Gson;

@WebServlet("/ProductListServlet")
public class ProductListServlet extends HttpServlet {
	private static final Gson gson = new Gson();


@Override
protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
resp.setContentType("application/json;charset=UTF-8");
String sort = req.getParameter("sort");
String q = req.getParameter("q");
try {
    Dbconn db = new Dbconn();
    ResultSet rs = db.getProducts(sort, q);
    List<Map<String,Object>> list = new ArrayList<>();
    while (rs.next()){
        Map<String,Object> p = new HashMap<>();
        p.put("id", rs.getInt("id"));
        p.put("name", rs.getString("name"));
        p.put("description", rs.getString("description"));
p.put("price", rs.getDouble("price"));
p.put("mrp", rs.getDouble("mrp"));
p.put("stock", rs.getInt("stock"));
p.put("image", rs.getString("image"));
p.put("category_name", rs.getString("category_name"));
list.add(p);
}
rs.getStatement().close();
resp.getWriter().write(gson.toJson(list));
} catch (Exception e) {
resp.setStatus(500);
resp.getWriter().write(gson.toJson(new ArrayList<>()));
}
}
}