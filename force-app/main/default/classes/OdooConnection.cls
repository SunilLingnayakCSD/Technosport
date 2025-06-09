public class OdooConnection {

    private static final String url = 'https://technosport-staging-2-18770572.dev.odoo.com';
    private static final String db = 'technosport-staging-2-18770572';
    private static final String username = 'admin';
    private static final String password = 'ADMIN';

    // Helper method to send JSON request to Odoo
    private static String sendJsonRequest(String method, String endpoint, String jsonBody) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url + endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        return res.getBody();
    }

    // Method to authenticate to Odoo and get the UID
    public static String authenticate() {
        // Construct the JSON payload for authentication
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'db' => db,
            'login' => username,
            'password' => password
        });

        // Send request to Odoo common endpoint for authentication
        String response = sendJsonRequest('POST', '/web/session/authenticate', jsonBody);
        
        // Parse the response to extract UID (authentication token)
        // Odoo returns authentication information in the 'session_id' for this endpoint
        String uid = parseJson(response, 'session_id');
        
        return uid;
    }

    // Method to create a Sale Order in Odoo
    public static String createSaleOrder(String uid) {
        // Construct the JSON payload for creating a sale order
        Map<String, Object> orderData = new Map<String, Object>{
            'partner_id' => 4649,  // Customer ID (res.partner)
            'date_order' => '2025-04-07',  // Optional: order date
            'state' => 'draft'  // Optional: default is draft
        };

        Map<String, Object> params = new Map<String, Object>{
            'db' => db,
            'uid' => uid,
            'password' => password,
            'model' => 'sale.order',
            'method' => 'create',
            'args' => new List<Object>{orderData}
        };
        
        // Convert map to JSON
        String jsonBody = JSON.serialize(params);
        
        // Send request to create sale order
        String response = sendJsonRequest('POST', '/web/dataset/call_kw', jsonBody);

        // Parse the response to extract Sale Order ID
        String orderId = parseJson(response, 'result');
        return orderId;
    }

    // Method to create a Sale Order Line
    public static void createSaleOrderLine(String orderId, String uid) {
        // Construct the JSON payload for creating a sale order line
        Map<String, Object> orderLineData = new Map<String, Object>{
            'order_id' => orderId,
            'product_id' => 253290,
            'product_uom_qty' => 1,
            'name' => 'Test Product Line'
        };

        Map<String, Object> params = new Map<String, Object>{
            'db' => db,
            'uid' => uid,
            'password' => password,
            'model' => 'sale.order.line',
            'method' => 'create',
            'args' => new List<Object>{orderLineData}
        };

        // Convert map to JSON
        String jsonBody = JSON.serialize(params);
        
        // Send request to create sale order line
        sendJsonRequest('POST', '/web/dataset/call_kw', jsonBody);
    }

    // A method to parse the JSON response and extract a specific field
    private static String parseJson(String jsonResponse, String key) {
        // Parse the JSON response
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        
        // Extract the value associated with the key
        if (resultMap.containsKey(key)) {
            return (String) resultMap.get(key);
        } else {
            return null;
        }
    }

    // Main method to create the sale order and line
    public static void createOrderAndLine() {
        String uid = authenticate();
        if (uid != null) {
            String orderId = createSaleOrder(uid);
            if (orderId != null) {
                createSaleOrderLine(orderId, uid);
                System.debug('Created Sale Order Line for Order ID: ' + orderId);
            }
        }
    }
}