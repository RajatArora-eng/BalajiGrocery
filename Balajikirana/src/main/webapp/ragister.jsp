<%@ page contentType="text/html;charset=UTF-8" %>
<script src="https://cdn.tailwindcss.com"></script>

<div class="min-h-screen flex items-center justify-center bg-gray-50 py-10">
    <div class="bg-white shadow-lg rounded-xl p-8 w-full max-w-md">

        <h2 class="text-2xl font-bold mb-6 text-center text-green-700">Create Account</h2>

        <form action="AuthServlet" method="post">
            <input type="hidden" name="action" value="register" />

            <label class="block mb-2 text-gray-700">Full Name</label>
            <input type="text" name="name" required
                   class="w-full px-3 py-2 border rounded focus:ring focus:ring-green-300" />

            <label class="block mt-4 mb-2 text-gray-700">Email</label>
            <input type="email" name="email" required
                   class="w-full px-3 py-2 border rounded focus:ring focus:ring-green-300" />

            <label class="block mt-4 mb-2 text-gray-700">Phone</label>
            <input type="text" name="phone" required
                   class="w-full px-3 py-2 border rounded focus:ring focus:ring-green-300" />

            <label class="block mt-4 mb-2 text-gray-700">Password</label>
            <input type="password" name="password" required
                   class="w-full px-3 py-2 border rounded focus:ring focus:ring-green-300" />

            <button class="mt-6 bg-green-700 hover:bg-green-800 text-white w-full py-2 rounded-md">
                Register
            </button>

            <p class="text-center text-sm mt-4">
                Already have an account?
                <a href="login.jsp" class="text-green-700 underline">Login</a>
            </p>
        </form>

    </div>
</div>

<%@ include file="/footer.jsp" %>
