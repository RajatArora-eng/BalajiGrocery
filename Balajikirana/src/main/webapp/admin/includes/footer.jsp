</main>

<footer class="bg-white shadow-inner p-4 text-center text-gray-500 mt-6">
    © <%= java.time.Year.now() %> • Balaji Grocery Admin Panel
</footer>

</div>

<script>
    const menuBtn = document.getElementById('menuBtn');
    const sidebar = document.getElementById('sidebar');

    menuBtn?.addEventListener('click', () => {
        sidebar.classList.toggle('hidden');
    });
</script>
