<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*, dao.Dbconn" %>
<%
  // admin guard (redirect to login if not admin)
  jakarta.servlet.http.HttpSession sess = request.getSession(false);
  if (sess == null || sess.getAttribute("role") == null || !"admin".equalsIgnoreCase((String)sess.getAttribute("role"))) {
    response.sendRedirect(request.getContextPath() + "/admin/login.jsp");
    return;
  }

  String idParam = request.getParameter("id");
  if (idParam == null) {
    out.println("Order id required");
    return;
  }
  int orderId = 0;
  try { orderId = Integer.parseInt(idParam); } catch (Exception e) { out.println("Invalid id"); return; }

  // containers
  Map<String,Object> order = new HashMap<>();
  List<Map<String,Object>> items = new ArrayList<>();

  Dbconn db = null;
  Connection conn = null;
  try {
    db = new Dbconn();
    conn = db.getConnection();

    // fetch order + user
    String sql = "SELECT o.*, u.name AS user_name, u.email AS user_email, u.phone AS user_phone FROM orders o LEFT JOIN users u ON o.user_id = u.id WHERE o.id = ?";
    try (PreparedStatement ps = conn.prepareStatement(sql)) {
      ps.setInt(1, orderId);
      try (ResultSet rs = ps.executeQuery()) {
        if (rs.next()) {
          order.put("id", rs.getInt("id"));
          order.put("user_id", rs.getInt("user_id"));
          order.put("total_amount", rs.getDouble("total_amount"));
          order.put("status", rs.getString("status"));
          order.put("address", rs.getString("address"));
          order.put("created_at", rs.getTimestamp("created_at"));
          order.put("user_name", rs.getString("user_name"));
          order.put("user_email", rs.getString("user_email"));
          order.put("user_phone", rs.getString("user_phone"));
        } else {
          out.println("Order not found");
          return;
        }
      }
    }

    // fetch order items using existing helper
    try (ResultSet rs = db.getOrderItems(orderId)) {
      while (rs.next()) {
        Map<String,Object> it = new HashMap<>();
        it.put("product_id", rs.getInt("product_id"));
        it.put("name", rs.getString("name"));
        it.put("image", rs.getString("image"));
        it.put("price", rs.getDouble("price"));
        it.put("quantity", rs.getInt("quantity"));
        it.put("subtotal", rs.getDouble("price") * rs.getInt("quantity"));
        items.add(it);
      }
    }

  } catch (Exception e) {
    e.printStackTrace();
    out.println("Error loading order: " + e.getMessage());
    return;
  } finally {
    try { if (db != null) db.close(); } catch (Exception ignored) {}
  }

  // Helper: extract receiver from address (same logic used earlier)
  String address = (String) order.get("address");
  String receiver = null;
  if (address != null) {
    try {
      String tmp = address;
      int ci = tmp.indexOf("Contact");
      if (ci >= 0) tmp = tmp.substring(0, ci);
      String firstLine = tmp.split("\\r?\\n")[0].trim();
      if (firstLine.contains(",")) receiver = firstLine.substring(0, firstLine.indexOf(",")).trim();
      else {
        int dash = firstLine.indexOf(" - ");
        int pipe = firstLine.indexOf("|");
        if (dash > 0) receiver = firstLine.substring(0, dash).trim();
        else if (pipe > 0) receiver = firstLine.substring(0, pipe).trim();
        else if (!firstLine.isEmpty() && firstLine.length() <= 80) receiver = firstLine;
      }
      if (receiver != null && receiver.isEmpty()) receiver = null;
    } catch (Exception ignore) { receiver = null; }
  }
  String displayCustomer = (receiver != null) ? receiver : ((String)order.get("user_name") != null ? (String)order.get("user_name") : "Guest");
%>
<!doctype html>
<html>
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>Order #<%= orderId %> — Details</title>
  <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-slate-800 min-h-screen">
  <div class="max-w-6xl mx-auto p-6">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-semibold">Order Details — #<%= orderId %></h1>
        <div class="text-sm text-gray-600 mt-1">Placed: <strong><%= order.get("created_at") %></strong></div>
      </div>
      <div class="space-x-2">
        <a href="<%= request.getContextPath() %>/admin/ShowOrdersServlet" class="px-3 py-2 bg-white border rounded shadow-sm text-sm">← Back to orders</a>
      </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Left: Order summary -->
      <div class="lg:col-span-2 space-y-4">
        <div class="bg-white rounded-lg p-4 shadow">
          <h2 class="text-lg font-medium mb-2">Customer & Delivery</h2>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <div class="mini text-sm text-gray-500">Receiver</div>
              <div class="font-semibold"><%= displayCustomer %></div>
            </div>
            <div>
              <div class="mini text-sm text-gray-500">Account name</div>
              <div><%= order.get("user_name")==null? "Guest": order.get("user_name") %></div>
            </div>
            <div>
              <div class="mini text-sm text-gray-500">Contact</div>
              <div><%= order.get("user_phone")==null? "-" : order.get("user_phone") %></div>
            </div>
            <div>
              <div class="mini text-sm text-gray-500">Email</div>
              <div><%= order.get("user_email")==null? "-" : order.get("user_email") %></div>
            </div>
          </div>

          <div class="mt-4">
            <div class="mini text-sm text-gray-500">Delivery address (raw)</div>
            <div class="mt-1 p-3 bg-slate-50 rounded"><pre class="whitespace-pre-wrap"><%= address == null ? "-" : address %></pre></div>
          </div>
        </div>

        <div class="bg-white rounded-lg p-4 shadow">
          <h2 class="text-lg font-medium mb-2">Items</h2>
          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead class="text-left text-gray-500 text-xs uppercase">
                <tr>
                  <th class="py-2">Product</th>
                  <th class="py-2">Price</th>
                  <th class="py-2">Qty</th>
                  <th class="py-2 text-right">Subtotal</th>
                </tr>
              </thead>
              <tbody>
                <%
                  double calcTotal = 0.0;
                  for (Map<String,Object> it : items) {
                    double price = ((Number)it.get("price")).doubleValue();
                    int qty = ((Number)it.get("quantity")).intValue();
                    double sub = ((Number)it.get("subtotal")).doubleValue();
                    calcTotal += sub;
                %>
                <tr class="border-t">
                  <td class="py-3">
                    <div class="flex items-center gap-3">
                      <div class="w-12 h-12 bg-gray-100 rounded overflow-hidden flex items-center justify-center">
                        <% String img = (String)it.get("image"); if (img != null && !img.isEmpty()) { %>
                          <img src="<%= img %>" alt="" class="object-cover w-full h-full"/>
                        <% } else { %>
                          <div class="text-xs text-gray-400">No image</div>
                        <% } %>
                      </div>
                      <div><div class="font-medium"><%= it.get("name") %></div></div>
                    </div>
                  </td>
                  <td class="py-3">₹<%= String.format("%.2f", price) %></td>
                  <td class="py-3"><%= qty %></td>
                  <td class="py-3 text-right">₹<%= String.format("%.2f", sub) %></td>
                </tr>
                <% } %>
              </tbody>
              <tfoot>
                <tr class="border-t">
                  <td colspan="3" class="py-3 text-right font-semibold">Items total</td>
                  <td class="py-3 text-right font-semibold">₹<%= String.format("%.2f", calcTotal) %></td>
                </tr>
                <%
                  // compute delivery in a statement block (not inside an expression)
                  double delivery = (calcTotal > 0 && calcTotal < 500) ? 30 : 0;
                %>
                <tr>
                  <td colspan="3" class="py-3 text-right">Delivery</td>
                  <td class="py-3 text-right">₹<%= String.format("%.2f", delivery) %></td>
                </tr>
                <tr>
                  <td colspan="3" class="py-3 text-right font-bold">Total</td>
                  <td class="py-3 text-right font-bold">₹<%= String.format("%.2f", calcTotal + delivery) %></td>
                </tr>
              </tfoot>
            </table>
          </div>
        </div>

      </div>

      <!-- Right: Order actions & meta -->
      <aside class="space-y-4">
        <div class="bg-white rounded-lg p-4 shadow">
          <h3 class="font-medium text-sm text-gray-700 mb-2">Order Info</h3>
          <div class="text-sm text-gray-600">
            <div class="mb-2"><strong>Order #</strong> <span class="ml-2">#<%= orderId %></span></div>
            <div class="mb-2"><strong>Placed</strong> <span class="ml-2"><%= order.get("created_at") %></span></div>
            <div class="mb-2"><strong>Saved total</strong> <span class="ml-2">₹<%= String.format("%.2f", ((Number)order.get("total_amount")).doubleValue()) %></span></div>
            <div class="mb-2"><strong>Current status</strong>
              <div class="inline-block ml-2 px-3 py-1 rounded-full text-white text-xs <%= 
                 "Complete".equalsIgnoreCase((String)order.get("status"))? "bg-emerald-500" :
                 ("Pending".equalsIgnoreCase((String)order.get("status"))? "bg-yellow-500" : "bg-sky-500")
              %>"><%= order.get("status") == null ? "-" : order.get("status") %></div>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg p-4 shadow">
          <h3 class="font-medium text-sm text-gray-700 mb-2">Change status</h3>
          <form action="<%= request.getContextPath() %>/admin/UpdateOrderStatusServlet" method="post">
            <input type="hidden" name="id" value="<%= orderId %>"/>
            <select name="status" class="w-full border rounded p-2 mb-3" required>
              <option value="">Select status</option>
              <option value="Pending">Pending</option>
              <option value="Shipped">Shipped</option>
              <option value="Complete">Complete</option>
            </select>
            <button type="submit" class="w-full bg-blue-600 text-white py-2 rounded">Update</button>
          </form>
        </div>

        <div class="bg-white rounded-lg p-4 shadow">
          <h3 class="font-medium text-sm text-gray-700 mb-2">Actions</h3>
          <div class="space-y-2">
            <a href="<%= request.getContextPath() %>/admin/PrintOrderServlet?id=<%= orderId %>" class="block text-center w-full border rounded py-2">Print invoice</a>
            <form action="<%= request.getContextPath() %>/admin/DeleteOrderServlet" method="post" onsubmit="return confirm('Delete order #<%= orderId %>?');">
              <input type="hidden" name="id" value="<%= orderId %>"/>
              <button type="submit" class="w-full text-left text-red-600">Delete order</button>
            </form>
          </div>
        </div>

      </aside>
    </div>
  </div>
</body>
</html>
