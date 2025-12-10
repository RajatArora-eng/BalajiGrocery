package servlets;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.*;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;

@WebServlet("/SendWhatsAppServlet")
public class SendWhatsAppServlet extends HttpServlet {
    private static final Gson gson = new Gson();
    private static final String API_BASE = "https://graph.facebook.com/v17.0/";

    // Reads token and phone-number-id from environment variables for safety
    private String getToken(){ return System.getenv("WHATSAPP_TOKEN"); }
    private String getPhoneNumberId(){ return System.getenv("PHONE_NUMBER_ID"); }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) {
        resp.setContentType("application/json;charset=UTF-8");
        Map<String,Object> out = new HashMap<>();
        try (BufferedReader br = new BufferedReader(new InputStreamReader(req.getInputStream(), "UTF-8"));
             PrintWriter pw = resp.getWriter()) {

            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = br.readLine()) != null) sb.append(line);
            String body = sb.toString();
            if (body == null || body.trim().isEmpty()) {
                resp.setStatus(400);
                out.put("success", false);
                out.put("message", "empty body");
                pw.write(gson.toJson(out));
                return;
            }

            JsonObject json = JsonParser.parseString(body).getAsJsonObject();
            String phone = json.has("phone") ? json.get("phone").getAsString().trim() : null;
            String orderId = json.has("order_id") ? json.get("order_id").getAsString() : null;
            String message = json.has("message") ? json.get("message").getAsString() : null;

            if (phone == null || phone.isEmpty() || message == null || message.isEmpty()) {
                resp.setStatus(400);
                out.put("success", false);
                out.put("message", "phone and message required");
                pw.write(gson.toJson(out));
                return;
            }

            String token = getToken();
            String phoneNumberId = getPhoneNumberId();
            if (token == null || token.trim().isEmpty() || phoneNumberId == null || phoneNumberId.trim().isEmpty()) {
                resp.setStatus(500);
                out.put("success", false);
                out.put("message", "WhatsApp credentials not set on server (WHATSAPP_TOKEN / PHONE_NUMBER_ID).");
                pw.write(gson.toJson(out));
                return;
            }

            // Normalize phone: digits only, assume India if 10 digits
            phone = phone.replaceAll("\\D", "");
            if (phone.length() == 10) phone = "91" + phone;

            // Optional: check contact existence
            boolean contactExists = true;
            try {
                contactExists = checkWhatsAppContact(phone, token, phoneNumberId);
            } catch (Exception e) {
                // if check fails, we can attempt to send anyway or decide to fail. We'll attempt.
                contactExists = true;
            }

            if (!contactExists) {
                resp.setStatus(400);
                out.put("success", false);
                out.put("message", "phone not registered on WhatsApp");
                pw.write(gson.toJson(out));
                return;
            }

            // Prepare message payload
            String sendUrl = API_BASE + phoneNumberId + "/messages";
            URL url = new URL(sendUrl);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Authorization", "Bearer " + token);
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setDoOutput(true);

            Map<String,Object> payload = new HashMap<>();
            payload.put("messaging_product", "whatsapp");
            payload.put("to", phone);
            payload.put("type", "text");
            Map<String,String> textObj = new HashMap<>();
            textObj.put("body", message);
            payload.put("text", textObj);

            String jsonPayload = gson.toJson(payload);
            try (OutputStream os = conn.getOutputStream()) {
                os.write(jsonPayload.getBytes("UTF-8"));
            }

            int code = conn.getResponseCode();
            InputStream is = (code >= 200 && code < 400) ? conn.getInputStream() : conn.getErrorStream();
            String respBody = new String(is.readAllBytes(), "UTF-8");

            if (code >= 200 && code < 300) {
                out.put("success", true);
                out.put("detail", gson.fromJson(respBody, Map.class));
                pw.write(gson.toJson(out));
            } else {
                resp.setStatus(502);
                out.put("success", false);
                out.put("message", "whatsapp api error");
                out.put("detail", respBody);
                pw.write(gson.toJson(out));
            }

        } catch (Exception e) {
            e.printStackTrace();
            try {
                resp.setStatus(500);
                out.put("success", false);
                out.put("message", e.getMessage());
                resp.getWriter().write(gson.toJson(out));
            } catch (IOException ignored) {}
        }
    }

    // contacts check: returns true if phone exists on WhatsApp
    private boolean checkWhatsAppContact(String phone, String token, String phoneNumberId) throws IOException {
        String urlStr = API_BASE + phoneNumberId + "/contacts?blocking=wait&contacts=" + java.net.URLEncoder.encode(phone, "UTF-8");
        URL url = new URL(urlStr);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("GET");
        conn.setRequestProperty("Authorization", "Bearer " + token);
        conn.setDoInput(true);

        int code = conn.getResponseCode();
        InputStream is = (code >= 200 && code < 400) ? conn.getInputStream() : conn.getErrorStream();
        String respBody = new String(is.readAllBytes(), "UTF-8");
        if (code >= 200 && code < 300) {
            Map parsed = gson.fromJson(respBody, Map.class);
            java.util.List contacts = (java.util.List) parsed.get("contacts");
            if (contacts != null && !contacts.isEmpty()) {
                Map first = (Map) contacts.get(0);
                String status = (String) first.get("status");
                return ("valid".equalsIgnoreCase(status) || "reachable".equalsIgnoreCase(status) || "exists".equalsIgnoreCase(status));
            }
            return false;
        } else {
            throw new IOException("Contacts API error: " + code + " - " + respBody);
        }
    }
}
