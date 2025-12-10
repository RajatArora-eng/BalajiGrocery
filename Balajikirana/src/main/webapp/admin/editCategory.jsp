<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*, dao.Dbconn" %>

<%
    // ---- Read data sent by EditCategoryServlet ----
    String id = String.valueOf(request.getAttribute("cat_id"));
    String name = String.valueOf(request.getAttribute("cat_name"));
    String image = String.valueOf(request.getAttribute("cat_image"));

    if(id == null || id.equals("null")) id = "";
    if(name == null || name.equals("null")) name = "";
    if(image == null || image.equals("null")) image = "";
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Edit Category</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>

<body class="bg-gray-100 min-h-screen">

<div class="max-w-lg mx-auto bg-white p-6 mt-10 rounded shadow">

    <h1 class="text-xl font-semibold mb-4">Edit Category</h1>

    <!-- Error Message -->
    <% if(request.getParameter("error") != null) { %>
        <div class="mb-4 p-3 bg-red-200 text-red-800 rounded">
            <%= request.getParameter("error") %>
        </div>
    <% } %>

    <form action="<%= request.getContextPath() %>/admin/UpdateCategoryServlet"
          method="post" enctype="multipart/form-data">

        <!-- Hidden: ID -->
        <input type="hidden" name="id" value="<%= id %>">

        <!-- Category Name -->
        <label class="block font-medium">Category Name</label>
        <input type="text"
               name="name"
               value="<%= name %>"
               required
               class="w-full border rounded px-3 py-2 mb-4">

        <!-- Upload Image -->
        <label class="block font-medium">Upload Image</label>
        <input type="file"
               name="image"
               class="mb-4">

        <% if (!image.isEmpty()) { %>
            <p class="font-medium text-gray-600 mb-2">Current Image:</p>
            <img src="<%= request.getContextPath() + image %>"
                 class="w-28 h-28 object-cover border rounded mb-4">
        <% } %>

        <button class="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700">
            Update Category
        </button>
    </form>

    <a href="<%=request.getContextPath()%>/admin/Showcategories.jsp"
       class="block text-center mt-4 text-blue-600 hover:underline">
        ← Back to Categories
    </a>

</div>

</body>
</html>