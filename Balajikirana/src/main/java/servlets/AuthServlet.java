package servlets;

import dao.Dbconn;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.ResultSet;
import java.sql.SQLException;

@WebServlet("/admin/AuthServlet")
public class AuthServlet extends HttpServlet {

    private Dbconn db;

    @Override
    public void init() throws ServletException {
        try {
            db = new Dbconn(); // uses constructor with DB creds
        } catch (Exception e) {
            throw new ServletException("DB init failed", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        // Ensure form encoding
        req.setCharacterEncoding("UTF-8");

        String action = req.getParameter("action");
        if ("login".equalsIgnoreCase(action)) {
            try {
                handleLogin(req, resp);
            } catch (Exception e) {
                throw new ServletException(e);
            }
        } else if ("register".equalsIgnoreCase(action)) {
            handleRegister(req, resp);
        } else {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid action");
        }
    }

    private void handleLogin(HttpServletRequest req, HttpServletResponse resp) throws Exception {
        String email = req.getParameter("email");
        String password = req.getParameter("password");

        if (email == null || password == null || email.trim().isEmpty() || password.trim().isEmpty()) {
            req.setAttribute("error", "Please enter email and password.");
            req.getRequestDispatcher("/login.jsp").forward(req, resp);
            return;
        }

        try (ResultSet rs = db.getUserByEmail(email)) {
            if (rs != null && rs.next()) {
                String storedHash = rs.getString("password");
                String hashAttempt = sha256(password);

                if (storedHash != null && storedHash.equals(hashAttempt)) {

                    int userId = rs.getInt("id");
                    String name = rs.getString("name");
                    String role = rs.getString("role");

                    HttpSession session = req.getSession(true);

                    if ("admin".equalsIgnoreCase(role)) {

                        // Remove any previous customer login session
                        session.removeAttribute("userId");
                        session.removeAttribute("userName");

                        // Set admin session
                        session.setAttribute("adminId", userId);
                        session.setAttribute("adminName", name);
                        session.setAttribute("role", "admin");

                        resp.sendRedirect(req.getContextPath() + "/admin/admindashboard.jsp");
                        return;

                    } else {

                        // Remove any old admin login session
                        session.removeAttribute("adminId");
                        session.removeAttribute("adminName");

                        // Set customer session
                        session.setAttribute("userId", userId);
                        session.setAttribute("userName", name);
                        session.setAttribute("role", "user");

                        resp.sendRedirect(req.getContextPath() + "/index.jsp");
                        return;
                    }
                }
            }
        } catch (SQLException ex) {
            throw new ServletException(ex);
        }

        req.setAttribute("error", "Invalid email or password.");
        req.getRequestDispatcher("/login.jsp").forward(req, resp);
    }


    private void handleRegister(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String name = req.getParameter("name");
        String email = req.getParameter("email");
        String phone = req.getParameter("phone");
        String password = req.getParameter("password");

        // basic validation
        if (name == null || email == null || password == null ||
            name.trim().isEmpty() || email.trim().isEmpty() || password.trim().isEmpty()) {
            req.setAttribute("error", "Name, email and password are required.");
            req.getRequestDispatcher("/register.jsp").forward(req, resp);
            return;
        }

        String hashed = sha256(password);

        try {
            // keep using your existing insertUser(...) which should default role to 'user' at DB level
            int rows = db.insertUser(name.trim(), email.trim(), phone != null ? phone.trim() : null, hashed);
            if (rows > 0) {
                // registration success - auto-login
                try (ResultSet rs = db.getUserByEmail(email.trim())) {
                    if (rs != null && rs.next()) {
                        HttpSession session = req.getSession(true);
                        session.setAttribute("userId", rs.getInt("id"));
                        session.setAttribute("userName", rs.getString("name"));
                        session.setAttribute("role", rs.getString("role") != null ? rs.getString("role") : "user");
                    }
                }
                resp.sendRedirect(req.getContextPath() + "/index.jsp");
                return;
            } else {
                req.setAttribute("error", "Unable to register. Try again.");
                req.getRequestDispatcher("/register.jsp").forward(req, resp);
            }
        } catch (SQLException sqlEx) {
            // handle duplicate email (unique constraint)
            String msg = sqlEx.getMessage();
            if (msg != null && msg.toLowerCase().contains("duplicate")) {
                req.setAttribute("error", "Email already registered. Try login or use another email.");
                req.getRequestDispatcher("/register.jsp").forward(req, resp);
                return;
            }
            throw new ServletException(sqlEx);
        } catch (Exception ex) {
            throw new ServletException(ex);
        }
    }

    // Simple SHA-256 hashing. Use bcrypt for production.
    private static String sha256(String input) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hashed = md.digest(input.getBytes(StandardCharsets.UTF_8));
            // convert to hex
            StringBuilder sb = new StringBuilder(hashed.length * 2);
            for (byte b : hashed) {
                String hx = Integer.toHexString(0xff & b);
                if (hx.length() == 1) sb.append('0');
                sb.append(hx);
            }
            return sb.toString();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
