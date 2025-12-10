<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.util.*, java.text.SimpleDateFormat" %>
<%
    List<Map<String,Object>> orders = (List<Map<String,Object>>) request.getAttribute("orders");
    if (orders == null) orders = Collections.emptyList();
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm");
%>
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Orders - Admin</title>
  <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 min-h-screen p-8">
  <div class="max-w-7xl mx-auto">
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-2xl font-bold">Orders</h1>
      <a href="<%= request.getContextPath() %>/admin/ShowOrdersServlet" class="bg-blue-600 text-white px-4 py-2 rounded">Refresh</a>
    </div>

    <% if (request.getParameter("error") != null) { %>
      <div class="mb-4 p-3 rounded bg-red-100 text-red-800"><%= request.getParameter("error") %></div>
    <% } %>

    <div class="bg-white p-4 rounded shadow overflow-x-auto">
      <table class="w-full table-auto text-sm">
        <thead>
          <tr class="text-left border-b">
            <th class="py-2">#</th>
            <th>Customer / Receiver</th>
            <th>Items</th>
            <th>Total</th>
            <th>Status</th>
            <th>Placed</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <%
            int idx = 1;
            for (Map<String,Object> o : orders) {
              int id = (Integer) o.get("id");
              Object custObj = o.get("customer");
              String customer = (custObj == null || "null".equals(String.valueOf(custObj))) ? null : String.valueOf(custObj);

              // servlet provided user_name when a real user exists (null when guest)
              Object userNameObj = o.get("user_name");
              String user_name = (userNameObj == null || "null".equals(String.valueOf(userNameObj))) ? null : String.valueOf(userNameObj);

              // full address (may be null)
              Object addrObj = o.get("address");
              String fullAddress = (addrObj == null ? "" : String.valueOf(addrObj));

              int items = (o.get("items") instanceof Number) ? ((Number)o.get("items")).intValue() : 0;
              double total = (o.get("total") instanceof Number) ? ((Number)o.get("total")).doubleValue() : 0.0;
              String status = (o.get("status") == null ? "-" : String.valueOf(o.get("status")));
              java.util.Date created = (java.util.Date) o.get("created_at");
              String statusClass = "bg-sky-500";
              if ("Complete".equalsIgnoreCase(status)) statusClass = "bg-emerald-500";
              else if ("Pending".equalsIgnoreCase(status)) statusClass = "bg-yellow-500";
          %>
          <tr class="border-b hover:bg-gray-50">
            <td class="py-3 align-top"><%= idx++ %></td>

            <!-- Customer / Receiver column -->
            <td class="px-4 py-3 align-top" title="<%= fullAddress.replace("\"", "&quot;") %>">
              <div class="font-medium">
                <%
                  if (customer != null && user_name != null) {
                    // user exists: show user name (customer)
                %>
                  <%= customer %>
                <%
                  } else if (customer != null && user_name == null) {
                    // customer derived from address (receiver)
                %>
                  <%= customer %> <span class="text-xs text-slate-500 ml-2">(Receiver)</span>
                <%
                  } else {
                %>
                  <span class="text-slate-600">Guest</span>
                <%
                  }
                %>
              </div>

              <% if (fullAddress != null && !fullAddress.trim().isEmpty()) { %>
                <div class="text-xs text-slate-500 mt-1"><%= fullAddress.length() > 80 ? fullAddress.substring(0,80) + "…" : fullAddress %></div>
              <% } %>
            </td>

            <td class="text-center align-top"><%= items %></td>
            <td class="text-right align-top">₹<%= String.format("%.2f", total) %></td>
            <td class="align-top">
              <span class="px-2 py-1 rounded-full text-white text-xs <%= statusClass %>"><%= status %></span>
            </td>
            <td class="align-top"><%= (created==null? "-" : sdf.format(created)) %></td>
            <td class="align-top">
              <a class="text-blue-600 hover:underline mr-3" href="<%= request.getContextPath() %>/admin/orderDetails.jsp?id=<%= id %>">View</a>
              <form action="<%= request.getContextPath() %>/admin/UpdateOrderStatusServlet" method="post" style="display:inline">
                <input type="hidden" name="id" value="<%= id %>"/>
                <select name="status" onchange="this.form.submit()" class="text-xs border rounded px-2 py-1">
                  <option value="">Change</option>
                  <option value="Pending">Pending</option>
                  <option value="Complete">Complete</option>
                  <option value="Shipped">Shipped</option>
                </select>
              </form>
            </td>
          </tr>
          <% } %>

          <% if (orders.isEmpty()) { %>
            <tr><td colspan="7" class="py-6 text-center text-slate-500">No orders found.</td></tr>
          <% } %>
        </tbody>
      </table>
    </div>
  </div>
</body>
</html>
