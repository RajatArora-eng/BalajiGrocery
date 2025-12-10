<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.util.*, java.text.SimpleDateFormat" %>

<%
    List<Map<String,Object>> users = (List<Map<String,Object>>) request.getAttribute("users");
    if (users == null) users = Collections.emptyList();
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm");
%>

<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Users - Admin</title>
  <script src="https://cdn.tailwindcss.com"></script>
</head>

<body class="bg-gray-100 min-h-screen p-8">

<div class="max-w-6xl mx-auto">

  <div class="flex items-center justify-between mb-6">
    <h1 class="text-2xl font-bold">Users</h1>
    <a href="<%= request.getContextPath() %>/admin/ShowUsersServlet"
       class="bg-blue-600 text-white px-4 py-2 rounded">Refresh</a>
  </div>

  <% if (request.getParameter("error") != null) { %>
    <div class="mb-4 p-3 rounded bg-red-100 text-red-800">
      <%= request.getParameter("error") %>
    </div>
  <% } %>

  <div class="bg-white p-4 rounded shadow overflow-x-auto">
    <table class="w-full text-sm table-auto">
      <thead>
        <tr class="border-b text-left">
          <th class="py-2">ID</th>
          <th>Name</th>
          <th>Email</th>
          <th>Phone</th>
          <th>Created</th>
          <th>Actions</th>
        </tr>
      </thead>

      <tbody>
      <%
         for (Map<String,Object> u : users) {
            int id = (Integer) u.get("id");
            String name = String.valueOf(u.get("name"));
            String email = String.valueOf(u.get("email"));
            String phone = String.valueOf(u.get("phone"));
            java.util.Date created = (java.util.Date) u.get("created_at");
      %>

        <tr class="border-b hover:bg-gray-50">
          <td class="py-3"><%= id %></td>
          <td><%= name %></td>
          <td><%= email %></td>
          <td><%= phone %></td>
          <td><%= (created == null ? "-" : sdf.format(created)) %></td>
          <td>
            <a href="<%= request.getContextPath() %>/admin/ShowUserServlet?id=<%= id %>"
               class="text-blue-600 hover:underline mr-2">View</a>

            <a href="<%= request.getContextPath() %>/admin/EditUserServlet?id=<%= id %>"
               class="text-yellow-600 hover:underline mr-2">Edit</a>

            <form action="<%= request.getContextPath() %>/admin/DeleteUserServlet"
                  method="post" style="display:inline">
              <input type="hidden" name="id" value="<%= id %>">
              <button class="text-red-600 hover:underline"
                      onclick="return confirm('Delete user <%= name %>?')">Delete</button>
            </form>
          </td>
        </tr>

      <% } %>

      <% if (users.isEmpty()) { %>
        <tr>
          <td colspan="6" class="py-6 text-center text-slate-500">No users found.</td>
        </tr>
      <% } %>

      </tbody>
    </table>
  </div>
</div>

</body>
</html>
