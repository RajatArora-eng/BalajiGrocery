<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*, dao.Dbconn" %>
<%
  // Optional admin guard
  jakarta.servlet.http.HttpSession Session = request.getSession(false);
  if (Session == null || Session.getAttribute("role") == null) {
    response.sendRedirect(request.getContextPath() + "/admin/login.jsp");
    return;
  }

  String idParam = request.getParameter("id");
  if (idParam == null) {
    out.println("<p style='color:red'>Order id missing.</p>");
    return;
  }

  int orderId = 0;
  try {
    orderId = Integer.parseInt(idParam);
  } catch (NumberFormatException nfe) {
    out.println("<p style='color:red'>Invalid order id.</p>");
    return;
  }

  Map<String,Object> order = null;
  List<Map<String,Object>> items = new ArrayList<>();
  double calcSubtotal = 0.0;
  double deliveryCharge = 0.0;
  double discount = 0.0;

  Dbconn db = null;
  Connection conn = null;
  try {
    db = new Dbconn();
    conn = db.getConnection();

    // fetch order and user name (if available)
    String orderSql = "SELECT o.*, u.name AS customer_name FROM orders o LEFT JOIN users u ON o.user_id = u.id WHERE o.id = ?";
    try (PreparedStatement ps = conn.prepareStatement(orderSql)) {
      ps.setInt(1, orderId);
      try (ResultSet rs = ps.executeQuery()) {
        if (rs.next()) {
          order = new HashMap<>();
          order.put("id", rs.getInt("id"));
          order.put("user_id", rs.getObject("user_id"));
          order.put("total_amount", rs.getObject("total_amount"));
          order.put("status", rs.getString("status"));
          order.put("address", rs.getString("address"));
          // payment_id might not exist in table -> handle gracefully
          try {
            String pay = rs.getString("payment_id");
            order.put("payment_id", pay);
          } catch (SQLException ignore) {
            order.put("payment_id", null);
          }
          order.put("created_at", rs.getTimestamp("created_at"));
          order.put("customer_name", rs.getString("customer_name"));
        }
      }
    }

    if (order == null) {
      out.println("<p style='color:red'>Order not found (id=" + orderId + ").</p>");
      return;
    }

    // fetch items via existing helper (db.getOrderItems)
    try (ResultSet rs = db.getOrderItems(orderId)) {
      while (rs.next()) {
        Map<String,Object> it = new HashMap<>();
        it.put("id", rs.getInt("id"));
        it.put("product_id", rs.getInt("product_id"));
        it.put("name", rs.getString("name"));
        it.put("image", rs.getString("image"));
        it.put("price", rs.getObject("price") == null ? 0.0 : rs.getDouble("price"));
        it.put("quantity", rs.getInt("quantity"));
        double subtotal = (rs.getObject("price") == null ? 0.0 : rs.getDouble("price")) * rs.getInt("quantity");
        it.put("subtotal", subtotal);
        calcSubtotal += subtotal;
        items.add(it);
      }
    }

    deliveryCharge = (calcSubtotal > 0 && calcSubtotal < 500) ? 30.0 : 0.0;
    discount = 0.0;

  } catch (Exception e) {
    e.printStackTrace();
    out.println("<p style='color:red'>Error loading order: " + e.getMessage() + "</p>");
    return;
  } finally {
    try { if (db != null) db.close(); } catch (Exception ignored) {}
  }

  // prepare display values
  String customerName = (String) order.get("customer_name");
  String address = (String) order.get("address");
  if ((customerName == null || customerName.trim().isEmpty()) && address != null && address.contains(",")) {
    // assume address begins with "Receiver name, ..."
    String first = address.split(",", 2)[0].trim();
    if (!first.isEmpty()) customerName = first;
  }
  if (customerName == null || customerName.trim().isEmpty()) customerName = "Guest";

  String paymentRef = (order.get("payment_id") == null) ? "-" : String.valueOf(order.get("payment_id"));
  String status = (String) order.get("status");
  java.util.Date created = (java.util.Date) order.get("created_at");
  double totalFromOrder = 0.0;
  if (order.get("total_amount") != null) {
    try { totalFromOrder = ((Number) order.get("total_amount")).doubleValue(); } catch (Exception ignored) {}
  }
  double calcTotal = calcSubtotal + deliveryCharge - discount;
%>

<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Print Order — #<%= orderId %></title>
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <script src="https://cdn.tailwindcss.com"></script>
  <style>
    @media print { .no-print { display:none !important; } body { -webkit-print-color-adjust: exact; } }
  </style>
</head>
<body class="bg-slate-50 p-6">
  <div class="max-w-3xl mx-auto bg-white shadow rounded-lg overflow-hidden">
    <div class="p-6 border-b flex items-start justify-between">
      <div>
        <h2 class="text-2xl font-bold text-slate-800">Balaji Grocery</h2>
        <div class="text-sm text-slate-500">Invoice / Order — <span class="font-medium">#<%= orderId %></span></div>
        <div class="text-xs text-slate-400 mt-1">Placed: <%= (created==null? "-" : new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm").format(created)) %></div>
      </div>
      <div class="text-right">
        <div class="text-sm text-slate-500">Status</div>
        <div class="mt-1 inline-block px-3 py-1 rounded-full text-white text-xs <%= ("Complete".equalsIgnoreCase(status) ? "bg-emerald-500" : ("Pending".equalsIgnoreCase(status) ? "bg-yellow-500" : "bg-sky-500")) %>">
          <%= (status==null? "-" : status) %>
        </div>
      </div>
    </div>

    <div class="p-6">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
        <div>
          <h3 class="text-sm font-semibold text-slate-700">Deliver To</h3>
          <div class="mt-2 text-sm text-slate-600">
            <div class="font-medium"><%= customerName %></div>
            <div class="mt-1 break-words"><%= (address == null ? "-" : address) %></div>
          </div>
        </div>

        <div>
          <h3 class="text-sm font-semibold text-slate-700">Order Summary</h3>
          <div class="mt-2 text-sm text-slate-600 space-y-1">
            <div>Order ID: <span class="font-medium"><%= orderId %></span></div>
            <div>Payment ref: <span class="font-medium"><%= paymentRef %></span></div>
            <div>Total (DB): <span class="font-medium">₹<%= String.format("%.2f", totalFromOrder) %></span></div>
          </div>
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead class="text-left text-xs text-slate-500 uppercase border-b">
            <tr>
              <th class="py-2">Item</th>
              <th class="py-2 text-center">Qty</th>
              <th class="py-2 text-right">Rate</th>
              <th class="py-2 text-right">Subtotal</th>
            </tr>
          </thead>
          <tbody>
            <%
              for (Map<String,Object> it : items) {
                String nm = (String) it.get("name");
                int qty = ((Number) it.get("quantity")).intValue();
                double price = ((Number) it.get("price")).doubleValue();
                double sub = ((Number) it.get("subtotal")).doubleValue();
            %>
            <tr class="border-b">
              <td class="py-3"><div class="font-medium"><%= nm %></div></td>
              <td class="py-3 text-center"><%= qty %></td>
              <td class="py-3 text-right">₹<%= String.format("%.2f", price) %></td>
              <td class="py-3 text-right">₹<%= String.format("%.2f", sub) %></td>
            </tr>
            <% } %>

            <% if (items.isEmpty()) { %>
              <tr><td colspan="4" class="py-6 text-center text-slate-500">No items found for this order.</td></tr>
            <% } %>
          </tbody>
          <tfoot>
            <tr>
              <td colspan="3" class="py-3 text-right text-slate-600">Subtotal</td>
              <td class="py-3 text-right font-medium">₹<%= String.format("%.2f", calcSubtotal) %></td>
            </tr>
            <tr>
              <td colspan="3" class="py-3 text-right text-slate-600">Delivery</td>
              <td class="py-3 text-right font-medium">₹<%= String.format("%.2f", deliveryCharge) %></td>
            </tr>
            <tr>
              <td colspan="3" class="py-3 text-right text-slate-600">Discount</td>
              <td class="py-3 text-right font-medium">₹<%= String.format("%.2f", discount) %></td>
            </tr>
            <tr class="border-t">
              <td colspan="3" class="py-3 text-right font-bold">Total</td>
              <td class="py-3 text-right font-bold text-lg">₹<%= String.format("%.2f", calcTotal) %></td>
            </tr>
          </tfoot>
        </table>
      </div>

      <div class="mt-6 text-xs text-slate-500">
        <div>Note: This is a system generated invoice.</div>
      </div>
    </div>

    <div class="p-6 border-t flex items-center justify-between no-print">
      <div class="text-sm text-slate-600">Printed by: <span class="font-medium"><%= (session.getAttribute("adminName") != null ? (String)session.getAttribute("adminName") : (String)session.getAttribute("userName")) %></span></div>
      <div class="space-x-3">
        <a href="<%= request.getContextPath() %>/admin/ShowOrdersServlet" class="px-4 py-2 border rounded text-sm">Back</a>
        <button onclick="window.print()" class="px-4 py-2 bg-sky-600 text-white rounded text-sm">Print</button>
      </div>
    </div>
  </div>
</body>
</html>
