<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.util.Map" %>

<%
    Map<String,Object> p = (Map<String,Object>) request.getAttribute("product");

    if (p == null) {
        p = Map.of(); // empty map fallback
    }
    


    String id = String.valueOf(p.getOrDefault("id", ""));
    String name = String.valueOf(p.getOrDefault("name", ""));
    String description = String.valueOf(p.getOrDefault("description", ""));
    String price = String.valueOf(p.getOrDefault("price", ""));
    String stock = String.valueOf(p.getOrDefault("stock", ""));
    String category = String.valueOf(p.getOrDefault("category_id", ""));  // FIX: your table uses category_id
    String image = String.valueOf(p.getOrDefault("image", ""));
%>
<%@ page import="java.sql.*, dao.Dbconn" %>

    <%
        Dbconn db2 = new Dbconn();
        ResultSet catRs = db2.getCategories();   // fetch all categories
    %>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Edit Product</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>

<body class="bg-gray-100 min-h-screen">

<div class="max-w-lg mx-auto bg-white p-6 mt-10 rounded shadow">
    <h1 class="text-xl font-semibold mb-4">Edit Product</h1>

    <form action="<%= request.getContextPath() %>/admin/UpdateProductServlet"
          method="post" enctype="multipart/form-data">

        <input type="hidden" name="id" value="<%= id %>">
        <input type="hidden" name="oldImage" value="<%= image %>">

        <label class="block font-medium">Name</label>
        <input type="text" name="name" value="<%= name %>" required
               class="w-full border rounded px-3 py-2 mb-4">

        <label class="block font-medium">Description</label>
        <textarea name="description" required
                  class="w-full border rounded px-3 py-2 mb-4"><%= description %></textarea>

        <label class="block font-medium">Price</label>
        <input type="number" name="price" step="0.01" value="<%= price %>" required
               class="w-full border rounded px-3 py-2 mb-4">

        <label class="block font-medium">Stock</label>
        <input type="number" name="stock" value="<%= stock %>" required
               class="w-full border rounded px-3 py-2 mb-4">

       <select name="category_id" class="w-full border rounded px-3 py-2 mb-4">
    <%
        while (catRs.next()) {
            int catId = catRs.getInt("id");
            String catName = catRs.getString("name");

            boolean selected = String.valueOf(catId).equals(category);
    %>
        <option value="<%= catId %>" <%= selected ? "selected" : "" %>>
            <%= catName %>
        </option>
    <%
        }
        catRs.close();
        db2.close();
    %>
</select>



        <label class="block font-medium">Product Image</label>
        <input type="file" name="image" class="mb-3">

        <% if (image != null && !image.equals("") && !"null".equals(image)) { %>
            <img src="<%= request.getContextPath() + "/images/products/" + image %>"
                 class="w-28 h-28 object-cover border rounded mb-4">
        <% } %>

        <button class="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700">
            Update Product
        </button>
    </form>
</div>

</body>
</html>
