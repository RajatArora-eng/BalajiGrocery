package dao;


import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Dbconn {

    
    private Connection cn;

    public Dbconn() throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        cn = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/balaji_grocery?useSSL=false&serverTimezone=UTC",
            "root",
            "Rajat@123"
        );
    }

    /** Expose raw connection if needed (use carefully). */
    public Connection getConnection() {
        return this.cn;
    }

    // ----------------- USERS -----------------
 // simple insert, returns rows affected
    public int insertUser(String name, String email, String phone, String passwordHash) throws SQLException {
        String sql = "INSERT INTO users (name, email, phone, password) VALUES (?, ?, ?, ?)";
        try (PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, name);
            ps.setString(2, email);
            ps.setString(3, phone);
            ps.setString(4, passwordHash);
            return ps.executeUpdate();
        }
    }
    public List<Map<String,Object>> getUsersList() throws Exception {
        List<Map<String,Object>> list = new ArrayList<>();
        String sql = "SELECT id,name,email,phone,created_at FROM users ORDER BY id";
        try (Statement st = cn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                Map<String,Object> u = new HashMap<>();
                u.put("id", rs.getInt("id"));
                u.put("name", rs.getString("name"));
                u.put("email", rs.getString("email"));
                u.put("phone", rs.getString("phone"));
                u.put("created_at", rs.getTimestamp("created_at"));
                list.add(u);
            }
        }
        return list;
    }


    public int updateUser(int id, String name, String email, String phone, String password) throws Exception {
        String sql = "UPDATE users SET name=?, email=?, phone=?, password=? WHERE id=?";
        try (PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, name);
            ps.setString(2, email);
            ps.setString(3, phone);
            ps.setString(4, password);
            ps.setInt(5, id); // <--- fixed index
            return ps.executeUpdate();
        }
    }


    public int deleteUser(int id) throws Exception {
        try (PreparedStatement ps = cn.prepareStatement("DELETE FROM users WHERE id=?")) {
            ps.setInt(1, id);
            return ps.executeUpdate();
        }
    }

    /** Caller must close the ResultSet (and its Statement) */
    public ResultSet getUserById(int id) throws Exception {
        PreparedStatement ps = cn.prepareStatement("SELECT id,name,email,phone,created_at FROM users WHERE id=?");
        ps.setInt(1, id);
        return ps.executeQuery();
    }

    public ResultSet getUserByEmail(String email) throws Exception {
        PreparedStatement ps = cn.prepareStatement(
            "SELECT id, name, email, phone, created_at, password, role FROM users WHERE email=?"
        );
        ps.setString(1, email);
        return ps.executeQuery();
    }


    public ResultSet getUsers() throws Exception {
        Statement st = cn.createStatement();
        return st.executeQuery("SELECT id,name,email,phone,created_at FROM users ORDER BY id");
    }

    // ----------------- CATEGORIES -----------------
    public int insertCategory(String name, String image) throws Exception {
        String sql = "INSERT INTO categories(name,image) VALUES (?,?)";
        try (PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, name);
            ps.setString(2, image);
            return ps.executeUpdate();
        }
    }

    public int updateCategory(int id, String name, String image) throws Exception {
        String sql = "UPDATE categories SET name=?, image=? WHERE id=?";
        try (PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, name);
            ps.setString(2, image);
            ps.setInt(3, id);
            return ps.executeUpdate();
        }
    }
 // returns number of products that reference given category id
    public int countProductsInCategory(int categoryId) throws Exception {
        String sql = "SELECT COUNT(*) FROM products WHERE category_id = ?";
        try (PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, categoryId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return 0;
    }

    /**
     * Optional: delete products for category and then delete category in a transaction.
     * Use with caution: this permanently removes products (and can cascade to order_items if cascade is configured).
     */
    public int deleteCategoryAndProductsTransactional(int categoryId) throws Exception {
        Connection c = null;
        PreparedStatement psDelProducts = null;
        PreparedStatement psDelCategory = null;
        try {
            c = this.cn;
            c.setAutoCommit(false);

            psDelProducts = c.prepareStatement("DELETE FROM products WHERE category_id = ?");
            psDelProducts.setInt(1, categoryId);
            int removedProducts = psDelProducts.executeUpdate();

            psDelCategory = c.prepareStatement("DELETE FROM categories WHERE id = ?");
            psDelCategory.setInt(1, categoryId);
            int removedCategory = psDelCategory.executeUpdate();

            c.commit();
            return removedCategory; // 1 if category removed, 0 otherwise
        } catch (SQLException ex) {
            if (c != null) try { c.rollback(); } catch (SQLException ignored) {}
            throw ex;
        } finally {
            try { if (c != null) c.setAutoCommit(true); } catch (SQLException ignored) {}
            closeQuiet(psDelProducts);
            closeQuiet(psDelCategory);
        }
    }

    public int deleteCategory(int id) throws Exception {
        try (PreparedStatement ps = cn.prepareStatement("DELETE FROM categories WHERE id=?")) {
            ps.setInt(1, id);
            return ps.executeUpdate();
        }
    }   // deactivate category
    public int deactivateCategory(int categoryId) throws Exception {
        try (PreparedStatement ps = cn.prepareStatement("UPDATE categories SET active=0 WHERE id=?")) {
            ps.setInt(1, categoryId);
            return ps.executeUpdate();
        }
    }

    // deactivate product
    public int deactivateProduct(int productId) throws Exception {
        try (PreparedStatement ps = cn.prepareStatement("UPDATE products SET active=0 WHERE id=?")) {
            ps.setInt(1, productId);
            return ps.executeUpdate();
        }
    }

    // count products in a category (only active products or all? here count active ones)
    public int countActiveProductsInCategory(int categoryId) throws Exception {
        try (PreparedStatement ps = cn.prepareStatement("SELECT COUNT(*) FROM products WHERE category_id = ? AND active = 1")) {
            ps.setInt(1, categoryId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return 0;
    }

    // check if product is referenced by order_items (returns count)
    public int countOrderItemsForProduct(int productId) throws Exception {
        try (PreparedStatement ps = cn.prepareStatement("SELECT COUNT(*) FROM order_items WHERE product_id = ?")) {
            ps.setInt(1, productId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return 0;
    }

    // optional: safeDeleteProduct (only if no order_items)
    public int safeDeleteProduct(int productId) throws Exception {
        if (countOrderItemsForProduct(productId) > 0) return 0; // cannot delete
        try (PreparedStatement ps = cn.prepareStatement("DELETE FROM products WHERE id = ?")) {
            ps.setInt(1, productId);
            return ps.executeUpdate();
        }
    }

 // add inside your existing Dbconn class
    public List<Map<String,Object>> getProductsListByCategory(int categoryId) throws Exception {
        String sql = "SELECT p.*, c.name AS category_name FROM products p LEFT JOIN categories c ON p.category_id=c.id WHERE p.category_id = ? ORDER BY p.created_at DESC";
        try (PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, categoryId);
            try (ResultSet rs = ps.executeQuery()) {
                List<Map<String,Object>> out = new ArrayList<>();
                while (rs.next()) {
                    Map<String,Object> m = new HashMap<>();
                    m.put("id", rs.getInt("id"));
                    m.put("name", rs.getString("name"));
                    m.put("description", rs.getString("description"));
                    m.put("price", rs.getObject("price") == null ? null : rs.getDouble("price"));
                    // mrp might be nullable — preserve null if DB has NULL
                    Object mrpObj = rs.getObject("mrp");
                    m.put("mrp", mrpObj == null ? null : rs.getDouble("mrp"));
                    m.put("stock", rs.getObject("stock") == null ? 0 : rs.getInt("stock"));
                    m.put("image", rs.getString("image"));
                    m.put("category_name", rs.getString("category_name"));
                    out.add(m);
                }
                return out;
            }
        }
    }


    public ResultSet getCategory(int id) throws Exception {
        PreparedStatement ps = cn.prepareStatement("SELECT id,name,image,created_at FROM categories WHERE id=?");
        ps.setInt(1, id);
        return ps.executeQuery();
    }

    public ResultSet getCategories() throws Exception {
        Statement st = cn.createStatement();
        return st.executeQuery("SELECT id,name,image,created_at FROM categories ORDER BY name");
    }

    // ----------------- PRODUCTS -----------------
    /** Simple insert (no generated key returned) */
    public int insertProduct(int categoryId, String name, String description, double price, double mrp, int stock, String image, int discount) throws Exception {
        String sql = "INSERT INTO products(category_id,name,description,price,mrp,stock,image,discount) VALUES (?,?,?,?,?,?,?,?)";
        try (PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, categoryId);
            ps.setString(2, name);
            ps.setString(3, description);
            ps.setDouble(4, price);
            ps.setDouble(5, mrp);
            ps.setInt(6, stock);
            ps.setString(7, image);
            ps.setInt(8, discount);
            return ps.executeUpdate();
        }
    }

    /** Insert and return generated product id, or -1 on failure */
    public int insertProductReturningKey(int categoryId, String name, String description, double price, double mrp, int stock, String image, int discount) throws Exception {
        String sql = "INSERT INTO products(category_id,name,description,price,mrp,stock,image,discount) VALUES (?,?,?,?,?,?,?,?)";
        try (PreparedStatement ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, categoryId);
            ps.setString(2, name);
            ps.setString(3, description);
            ps.setDouble(4, price);
            ps.setDouble(5, mrp);
            ps.setInt(6, stock);
            ps.setString(7, image);
            ps.setInt(8, discount);
            int affected = ps.executeUpdate();
            if (affected == 0) return -1;
            try (ResultSet gk = ps.getGeneratedKeys()) {
                if (gk.next()) return gk.getInt(1);
                else return -1;
            }
        }
    }

    public int updateProduct(int id, int categoryId, String name, String description, double price, double mrp, int stock, String image, int discount) throws Exception {
        String sql = "UPDATE products SET category_id=?, name=?, description=?, price=?, mrp=?, stock=?, image=?, discount=? WHERE id=?";
        try (PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, categoryId);
            ps.setString(2, name);
            ps.setString(3, description);
            ps.setDouble(4, price);
            ps.setDouble(5, mrp);
            ps.setInt(6, stock);
            ps.setString(7, image);
            ps.setInt(8, discount);
            ps.setInt(9, id);
            return ps.executeUpdate();
        }
    }

    public int deleteProduct(int id) throws Exception {
        try (PreparedStatement ps = cn.prepareStatement("DELETE FROM products WHERE id=?")) {
            ps.setInt(1, id);
            return ps.executeUpdate();
        }
    }

    public ResultSet getProduct(int id) throws Exception {
        PreparedStatement ps = cn.prepareStatement("SELECT p.*, c.name AS category_name FROM products p LEFT JOIN categories c ON p.category_id=c.id WHERE p.id=?");
        ps.setInt(1, id);
        return ps.executeQuery();
    }

    public ResultSet getProducts(String sort, String q) throws Exception {
        // simple flexible method: caller must close returned ResultSet
        StringBuilder sb = new StringBuilder("SELECT p.*, c.name AS category_name FROM products p LEFT JOIN categories c ON p.category_id=c.id");
        if (q != null && !q.trim().isEmpty()) {
            sb.append(" WHERE p.name LIKE ? OR p.description LIKE ?");
        }
        if ("price_asc".equals(sort)) sb.append(" ORDER BY p.price ASC");
        else if ("price_desc".equals(sort)) sb.append(" ORDER BY p.price DESC");
        else sb.append(" ORDER BY p.created_at DESC");

        PreparedStatement ps = cn.prepareStatement(sb.toString());
        if (q != null && !q.trim().isEmpty()) {
            ps.setString(1, "%" + q + "%");
            ps.setString(2, "%" + q + "%");
        }
        
        return ps.executeQuery();
    }
    public Map<String, Object> getProductMap(int id) throws Exception {
        String sql = "SELECT p.*, c.name AS category_name FROM products p LEFT JOIN categories c ON p.category_id=c.id WHERE p.id=?";
        try (PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return Map.of(
                            "id", rs.getInt("id"),
                            "category_id", rs.getInt("category_id"),
                            "name", rs.getString("name"),
                            "description", rs.getString("description"),
                            "price", rs.getDouble("price"),
                            "mrp", rs.getDouble("mrp"),
                            "stock", rs.getInt("stock"),
                            "image", rs.getString("image"),
                            "discount", rs.getInt("discount"),
                            "category_name", rs.getString("category_name")
                    );
                }
            }
        }
        return null;
    }

    // ----------------- CART -----------------
    public int addToCart(int userId, int productId, int quantity) throws Exception {
        // if exists update, else insert
        String check = "SELECT id, quantity FROM cart WHERE user_id=? AND product_id=?";
        String insert = "INSERT INTO cart(user_id,product_id,quantity) VALUES(?,?,?)";
        String update = "UPDATE cart SET quantity=? WHERE id=?";
        try (PreparedStatement ps = cn.prepareStatement(check)) {
            ps.setInt(1, userId);
            ps.setInt(2, productId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    int id = rs.getInt("id");
                    int existing = rs.getInt("quantity");
                    try (PreparedStatement ups = cn.prepareStatement(update)) {
                        ups.setInt(1, existing + quantity);
                        ups.setInt(2, id);
                        return ups.executeUpdate();
                    }
                } else {
                    try (PreparedStatement ins = cn.prepareStatement(insert)) {
                        ins.setInt(1, userId);
                        ins.setInt(2, productId);
                        ins.setInt(3, quantity);
                        return ins.executeUpdate();
                    }
                }
            }
        }
    }

    public int updateCartQuantity(int userId, int productId, int newQuantity) throws Exception {
        String sql = "UPDATE cart SET quantity=? WHERE user_id=? AND product_id=?";
        try (PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, newQuantity);
            ps.setInt(2, userId);
            ps.setInt(3, productId);
            return ps.executeUpdate();
        }
    }

    public int removeFromCart(int userId, int productId) throws Exception {
        try (PreparedStatement ps = cn.prepareStatement("DELETE FROM cart WHERE user_id=? AND product_id=?")) {
            ps.setInt(1, userId);
            ps.setInt(2, productId);
            return ps.executeUpdate();
        }
    }

    public ResultSet getCartItems(int userId) throws Exception {
        PreparedStatement ps = cn.prepareStatement(
            "SELECT cart.id AS cart_id, p.id AS product_id, p.name, p.price, p.image, cart.quantity, (p.price*cart.quantity) AS subtotal " +
            "FROM cart JOIN products p ON cart.product_id = p.id WHERE cart.user_id=?"
        );
        ps.setInt(1, userId);
        return ps.executeQuery();
    }

    public int getCartCount(int userId) throws Exception {
        PreparedStatement ps = cn.prepareStatement("SELECT COALESCE(SUM(quantity),0) AS cnt FROM cart WHERE user_id=?");
        ps.setInt(1, userId);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt("cnt");
        }
        return 0;
    }

    // ----------------- ORDERS -----------------
    /**
     * Create order (transactional):
     * inserts order, inserts order_items, clears cart, reduces stock.
     * Returns order id or -1 on failure.
     */
 // import java.sql.Types; near other imports if missing

    public int createOrder(Integer userId, double totalAmount, String address, Map<Integer,Integer> productIdToQty) throws Exception {
        String insOrder = "INSERT INTO orders(user_id,total_amount,address) VALUES(?,?,?)";
        String insItem = "INSERT INTO order_items(order_id,product_id,price,quantity) VALUES(?,?,?,?)";
        String delCart = "DELETE FROM cart WHERE user_id=?";
        String reduceStock = "UPDATE products SET stock = stock - ? WHERE id = ?";

        Connection c = null;
        PreparedStatement pOrder = null, pItem = null, pDelCart = null, pReduce = null;
        ResultSet rsKeys = null;
        try {
            c = this.cn;
            c.setAutoCommit(false);

            // insert order; allow NULL user_id
            pOrder = c.prepareStatement(insOrder, Statement.RETURN_GENERATED_KEYS);
            if (userId == null) pOrder.setObject(1, null, Types.INTEGER);
            else pOrder.setInt(1, userId);
            pOrder.setDouble(2, totalAmount);
            pOrder.setString(3, address);
            int r = pOrder.executeUpdate();
            if (r != 1) { c.rollback(); throw new SQLException("Failed to insert order row"); }

            rsKeys = pOrder.getGeneratedKeys();
            if (!rsKeys.next()) { c.rollback(); throw new SQLException("Failed to obtain generated order id"); }
            int orderId = rsKeys.getInt(1);

            // Check stock first for all products to avoid partial commits
            for (Map.Entry<Integer,Integer> e : productIdToQty.entrySet()) {
                int pid = e.getKey();
                int qty = e.getValue();
                try (PreparedStatement psCheck = c.prepareStatement("SELECT stock FROM products WHERE id=? FOR UPDATE")) {
                    psCheck.setInt(1, pid);
                    try (ResultSet rs = psCheck.executeQuery()) {
                        if (!rs.next()) { c.rollback(); throw new SQLException("Product not found: " + pid); }
                        int stock = rs.getInt("stock");
                        if (stock < qty) { c.rollback(); throw new SQLException("Insufficient stock for product " + pid + ": have=" + stock + " need=" + qty); }
                    }
                }
            }

            // Now insert order_items and reduce stock
            pItem = c.prepareStatement(insItem);
            pReduce = c.prepareStatement(reduceStock);
            for (Map.Entry<Integer,Integer> e : productIdToQty.entrySet()) {
                int pid = e.getKey();
                int qty = e.getValue();

                // get current price (use helper)
                ProductPrice pp = getProductPrice(pid);
                if (pp == null) { c.rollback(); throw new SQLException("Product price not found for id " + pid); }
                double price = pp.price;

                pItem.setInt(1, orderId);
                pItem.setInt(2, pid);
                pItem.setDouble(3, price);
                pItem.setInt(4, qty);
                pItem.addBatch();

                pReduce.setInt(1, qty);
                pReduce.setInt(2, pid);
                pReduce.addBatch();
            }
            pItem.executeBatch();
            pReduce.executeBatch();

            // delete cart only if userId is not null (if you store carts for guests differently, adjust)
            if (userId != null) {
                pDelCart = c.prepareStatement(delCart);
                pDelCart.setInt(1, userId);
                pDelCart.executeUpdate();
            }

            c.commit();
            return orderId;
        } catch (SQLException ex) {
            ex.printStackTrace();
            try { if (c != null) c.rollback(); } catch (SQLException ignored) {}
            throw ex;
        } finally {
            try { if (c != null) c.setAutoCommit(true); } catch (SQLException ignored) {}
            closeQuiet(rsKeys); closeQuiet(pOrder); closeQuiet(pItem); closeQuiet(pDelCart); closeQuiet(pReduce);
        }
    }

    /** Simple helper used by createOrder to fetch current product price (and stock) */
    private ProductPrice getProductPrice(int productId) throws Exception {
        PreparedStatement ps = cn.prepareStatement("SELECT price, stock FROM products WHERE id=?");
        ps.setInt(1, productId);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                ProductPrice pp = new ProductPrice();
                pp.price = rs.getDouble("price");
                pp.stock = rs.getInt("stock");
                return pp;
            }
        }
        return null;
    }

    private static class ProductPrice {
        double price;
        int stock;
    }

    public ResultSet getOrdersByUser(int userId) throws Exception {
        PreparedStatement ps = cn.prepareStatement("SELECT * FROM orders WHERE user_id=? ORDER BY created_at DESC");
        ps.setInt(1, userId);
        return ps.executeQuery();
    }

    public ResultSet getOrderItems(int orderId) throws Exception {
        PreparedStatement ps = cn.prepareStatement("SELECT oi.*, p.name, p.image FROM order_items oi JOIN products p ON oi.product_id = p.id WHERE oi.order_id=?");
        ps.setInt(1, orderId);
        return ps.executeQuery();
    }

    // ----------------- Utility -----------------
    private void closeQuiet(AutoCloseable ac) {
        if (ac == null) return;
        try { ac.close(); } catch (Exception ignored) {}
    }

    public void close() {
        try {
            if (cn != null && !cn.isClosed()) cn.close();
        } catch (SQLException ignored) {}
    }
}
