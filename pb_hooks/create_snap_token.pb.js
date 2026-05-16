routerAdd("POST", "/api/create-snap-token", (e) => {
  try {
    const info = e.requestInfo();
    if (info.auth == null) return e.json(401, { error: "Unauthorized" });

    const body = info.body;
    const orderId       = body.order_id;
    const amount        = body.amount;
    const customerName  = body.customer_name;
    const customerEmail = body.customer_email;

    if (!orderId || !amount || !customerName || !customerEmail) {
      return e.json(400, { error: "Field wajib kurang", received: JSON.stringify(body) });
    }

    const serverKey = $os.getenv("MIDTRANS_SERVER_KEY");
    const baseUrl   = $os.getenv("MIDTRANS_BASE_URL");

    if (!serverKey || !baseUrl) {
      return e.json(500, { error: "Konfigurasi Midtrans belum diatur di server" });
    }

    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    let encodedAuth = "";
    const raw = serverKey + ":";
    for (let i = 0; i < raw.length; i += 3) {
      const b1 = raw.charCodeAt(i), b2 = raw.charCodeAt(i + 1) || 0, b3 = raw.charCodeAt(i + 2) || 0;
      encodedAuth += chars.charAt(b1 >> 2);
      encodedAuth += chars.charAt(((b1 & 3) << 4) | (b2 >> 4));
      encodedAuth += chars.charAt(((b2 & 15) << 2) | (b3 >> 6));
      encodedAuth += chars.charAt(b3 & 63);
    }
    const rem = raw.length % 3;
    if (rem === 1) encodedAuth = encodedAuth.slice(0, -2) + "==";
    else if (rem === 2) encodedAuth = encodedAuth.slice(0, -1) + "=";

    let res;
    try {
      res = $http.send({
        url: baseUrl,
        method: "POST",
        headers: {
          "Authorization": "Basic " + encodedAuth,
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: JSON.stringify({
          transaction_details: { order_id: orderId, gross_amount: parseInt(amount) },
          customer_details: { first_name: customerName, email: customerEmail },
          item_details: [{ id: "PREMIUM_PLAN", price: parseInt(amount), quantity: 1, name: "UWANGKU Premium" }],
        }),
        timeout: 30,
      });
    } catch (err) {
      return e.json(502, { error: "Gagal terhubung ke Midtrans: " + err.toString() });
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      return e.json(res.statusCode, {
        error: "Midtrans error",
        midtrans_status: res.statusCode,
        midtrans_body: res.body,
        midtrans_json: res.json,
      });
    }

    return e.json(200, res.json);

  } catch (err) {
    return e.json(500, { error: "Hook error: " + err.toString() });
  }
}, $apis.requireAuth());
