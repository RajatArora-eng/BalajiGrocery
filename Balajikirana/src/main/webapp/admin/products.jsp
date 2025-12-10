<%@ page import="java.sql.*,dao.Dbconn" %>
<%@ page language="java" contentType="text/html; charset=UTF-8"%>

<!DOCTYPE html>
<html>
<head>
    <title>Add Product</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>

<body class="bg-gray-100">

<%
    Dbconn db = new Dbconn();
    ResultSet rs = db.getCategories();
%>

<div class="max-w-3xl mx-auto bg-white p-8 shadow rounded mt-8">
    <h1 class="text-2xl font-bold mb-6">Add Product</h1>

    <form action="AddProductServlet" method="post" enctype="multipart/form-data" class="space-y-4">

        <div>
            <label class="block font-medium">Select Category</label>
            <select name="category_id" required class="w-full border p-2 rounded">
                <option value="">Choose Category</option>
                <% while (rs.next()) { %>
                    <option value="<%= rs.getInt("id") %>">
                        <%= rs.getString("name") %>
                    </option>
                <% } %>
            </select>
        </div>

        <div>
            <label class="block font-medium">Product Name</label>
            <input type="text" name="name" required class="w-full border p-2 rounded">
        </div>

        <div>
            <label class="block font-medium">Description</label>
            <textarea name="description" class="w-full border p-2 rounded"></textarea>
        </div>

        <div class="grid grid-cols-2 gap-4">
            <div>
                <label class="block font-medium">Price</label>
                <input type="number" step="0.01" name="price" required class="w-full border p-2 rounded">
            </div>

            <div>
                <label class="block font-medium">MRP</label>
                <input type="number" step="0.01" name="mrp" required class="w-full border p-2 rounded">
            </div>
        </div>

        <div class="grid grid-cols-2 gap-4">
            <div>
                <label class="block font-medium">Stock</label>
                <input type="number" name="stock" required class="w-full border p-2 rounded">
            </div>

            <div>
                <label class="block font-medium">Discount (%)</label>
                <input type="number" name="discount" value="0" class="w-full border p-2 rounded">
            </div>
        </div>

        <div>
            <label class="block font-medium">Product Image</label>
            <input type="file" name="image" accept="image/*" required class="w-full">
        </div>

        <button class="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700">
            Add Product
        </button>
    </form>
</div>

</body>
</html>
