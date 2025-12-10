package servlets;




import java.io.IOException;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import dao.Dbconn;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import com.google.gson.Gson;
@WebServlet("/CategoryServlet")
public class CategoryServlet extends HttpServlet {
	private static final Gson gson = new Gson();


@Override
protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
resp.setContentType("application/json;charset=UTF-8");
try {
	Dbconn db = new Dbconn();
	ResultSet rs = db.getCategories();
	List<Map<String,Object>> cats = new ArrayList<>();
	while (rs.next()) {
		Map<String,Object> c = new HashMap<>();
		c.put("id", rs.getInt("id"));
c.put("name", rs.getString("name"));
c.put("image", rs.getString("image"));
cats.add(c);
}
resp.getWriter().write(gson.toJson(cats));
rs.getStatement().close();
} catch (Exception e) {
resp.setStatus(500);
resp.getWriter().write(gson.toJson(new ArrayList<>()));
}
}
}