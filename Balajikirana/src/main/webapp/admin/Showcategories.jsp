<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ page import="dao.Dbconn, java.sql.*" %>
<script src="https://cdn.tailwindcss.com"></script>

<%
    Dbconn db = new Dbconn();
    ResultSet rs = db.getCategories();
%>
<%
  String catMsg = (String) session.getAttribute("catMsg");
  if (catMsg != null) {
%>
  <div class="mb-3 p-3 bg-yellow-50 text-yellow-900 rounded">
    <%= catMsg %>
  </div>
<%
    session.removeAttribute("catMsg");
  }
%>

<!DOCTYPE html>
<html>

<head>

    <meta charset="UTF-8">
    <title>Categories - Admin</title>
</head>
<body class="bg-gray-100 min-h-screen p-8">

<div class="max-w-6xl mx-auto">

    <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-bold">Categories</h1>
        <a href="<%=request.getContextPath()%>/admin/categories.jsp"
           class="bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700">
           Add Category
        </a>
    </div>

    <% if(request.getParameter("success") != null) { %>
        <div class="mb-4 p-3 bg-green-200 text-green-900 rounded">
            Done.
        </div>
    <% } else if(request.getParameter("error") != null) { %>
        <div class="mb-4 p-3 bg-red-200 text-red-900 rounded">
            <%=request.getParameter("error")%>
        </div>
    <% } %>

    <div class="bg-white p-4 rounded shadow overflow-x-auto">
        <table class="w-full table-auto">
            <thead>
            <tr class="text-left border-b">
                <th class="py-2">#</th>
                <th>Name</th>
                <th>Image</th>
                <th>Actions</th>
            </tr>
            </thead>

            <tbody>
            <%
                int idx = 1;
                while(rs.next()) {
                    int id = rs.getInt("id");
                    String name = rs.getString("name");
                    String image = rs.getString("image");

                    String imgSrc = request.getContextPath() + "/images/categories/" + image;
            %>

            <tr class="border-b">
                <td class="py-3"><%= idx++ %></td>
                <td><%= name %></td>
                <td>
                    <img src="<%= imgSrc %>" class="h-16 w-16 object-contain border rounded" />
                </td>

                <td class="space-x-2">

                    <!-- Edit -->
                    <a href="<%=request.getContextPath()%>/admin/EditCategoryServlet?id=<%=id%>"
                       class="px-3 py-1 rounded bg-blue-600 text-white hover:bg-blue-700">
                       Edit
                    </a>

                    <!-- Delete -->
                    <a href="<%=request.getContextPath()%>/admin/DeleteCategoryServlet?id=<%=id%>"
   class="px-3 py-1 bg-red-600 text-white rounded">
   Delete
        </a>


                </td>
            </tr>

            <% } %>
            </tbody>
        </table>
    </div>

</div>

<% db.close(); %>

</body>
</html>
