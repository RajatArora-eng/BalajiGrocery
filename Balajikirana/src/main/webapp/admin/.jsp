<%@ page language="java" contentType="text/html; charset=UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <title>Add Category – Admin</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>

<body class="bg-gray-100">

<div class="max-w-xl mx-auto mt-10 bg-white p-8 shadow rounded">
    <h1 class="text-2xl font-bold mb-6">Add Category</h1>

    <form action="AddCategoryServlet" method="post" enctype="multipart/form-data" class="space-y-4">

        <div>
            <label class="block font-medium">Category Name</label>
            <input type="text" name="name" required class="w-full border p-2 rounded">
        </div>

        <div>
            <label class="block font-medium">Category Image</label>
            <input type="file" name="image" accept="image/*" required class="w-full">
        </div>

        <button class="bg-blue-600 px-4 py-2 text-white rounded hover:bg-blue-700">
            Add Category
        </button>
    </form>
</div>

</body>
</html>
