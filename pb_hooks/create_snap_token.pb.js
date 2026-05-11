routerAdd("POST", "/api/create-snap-token", (e) => {
  try {
    const info = e.requestInfo();
    const isAuth = info.auth != null;

    if (!isAuth) {
      return e.json(401, { error: "Unauthorized" });
    }

    const body = info.body;

    const orderId       = body.order_id;
    const amount        = body.amount;
    const customerName  = body.customer_name;
    const customerEmail = body.customer_email;

    if (!orderId || !amount || !customerName || !customerEmail) {
      return e.json(400, {
        error: "Field order_id, amount, customer_name, customer_email wajib diisi",
        received: JSON.stringify(body)
      });
    }

    const serverKey = $os.getenv("MIDTRANS_SERVER_KEY");
    const baseUrl   = $os.getenv("MIDTRANS_BASE_URL");

    if (!serverKey || !baseUrl) {
      return e.json(500, { error: "Konfigurasi Midtrans belum diatur di server" });
    }

    let test1, resA, resB, resC;
    try {
      test1 = $http.send({
        url: "https://jsonplaceholder.typicode.com/todos/1",
        method: "GET",
        timeout: 10,
      });

      const encoded = serverKey + ":";
      const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
      let encodedAuth = "";
      for (let i = 0; i < encoded.length; i += 3) {
        const b1 = encoded.charCodeAt(i), b2 = encoded.charCodeAt(i + 1) || 0, b3 = encoded.charCodeAt(i + 2) || 0;
        encodedAuth += chars.charAt(b1 >> 2);
        encodedAuth += chars.charAt(((b1 & 3) << 4) | (b2 >> 4));
        encodedAuth += chars.charAt(((b2 & 15) << 2) | (b3 >> 6));
        encodedAuth += chars.charAt(b3 & 63);
      }
      const rem = encoded.length % 3;
      if (rem === 1) encodedAuth = encodedAuth.slice(0, -2) + "==";
      else if (rem === 2) encodedAuth = encodedAuth.slice(0, -1) + "=";

      // Test A: full headers with lowercase
      resA = $http.send({
        url: baseUrl,
        method: "POST",
        headers: {
          "authorization": "Basic " + encodedAuth,
          "content-type": "application/json",
          "accept": "application/json",
        },
        body: JSON.stringify({
          transaction_details: { order_id: orderId, gross_amount: parseInt(amount) },
        }),
        timeout: 15,
      });

      // Test B: no auth, no headers
      resB = $http.send({
        url: baseUrl,
        method: "POST",
        body: JSON.stringify({
          transaction_details: { order_id: "TEST-NO-" + orderId, gross_amount: 10000 },
        }),
        timeout: 15,
      });

      // Test C: auth without Content-Type
      resC = $http.send({
        url: baseUrl,
        method: "POST",
        headers: {
          "authorization": "Basic " + encodedAuth,
        },
        body: JSON.stringify({
          transaction_details: { order_id: orderId, gross_amount: parseInt(amount) },
          customer_details: { first_name: customerName, email: customerEmail },
          item_details: [{ id: "PREMIUM_PLAN", price: parseInt(amount), quantity: 1, name: "UWANGKU Premium" }],
        }),
        timeout: 15,
      });
    } catch (err) {
      return e.json(502, { error: "Gagal: " + err.toString() });
    }

    return e.json(200, {
      test1: test1.statusCode,
      A_status: resA.statusCode,
      A_body: typeof resA.json === "object" && resA.json ? Object.keys(resA.json).join(",") : typeof resA.json,
      B_status: resB.statusCode,
      B_body: typeof resB.json === "object" && resB.json ? Object.keys(resB.json).join(",") : typeof resB.json,
      C_status: resC.statusCode,
      C_body: typeof resC.json === "object" && resC.json ? Object.keys(resC.json).join(",") : typeof resC.json,
    });
  } catch (err) {
    return e.json(500, { error: "Hook error: " + err.toString() });
  }
}, $apis.requireAuth());
