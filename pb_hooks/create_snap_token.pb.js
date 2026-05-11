routerAdd("POST", "/api/create-snap-token", (e) => {
  try {
    const info = e.requestInfo();
    if (info.auth == null) {
      return e.json(401, { error: "Unauthorized" });
    }

    const body = info.body;
    const orderId = body.order_id;
    const amount = body.amount;
    const customerName = body.customer_name;
    const customerEmail = body.customer_email;

    if (!orderId || !amount || !customerName || !customerEmail) {
      return e.json(400, {
        error: "Field order_id, amount, customer_name, customer_email wajib diisi",
      });
    }

    const serverKey = $os.getenv("MIDTRANS_SERVER_KEY");
    const baseUrl = $os.getenv("MIDTRANS_BASE_URL");
    if (!serverKey || !baseUrl) {
      return e.json(500, { error: "Midtrans config missing on server" });
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

    const test1 = $http.send({
      url: "https://jsonplaceholder.typicode.com/todos/1",
      method: "GET",
      timeout: 10,
    });

    const testA = $http.send({
      url: baseUrl,
      method: "POST",
      headers: {
        "authorization": "Basic " + encodedAuth,
        "content-type": "application/json",
        "accept": "application/json",
      },
      body: JSON.stringify({
        transaction_details: {
          order_id: orderId,
          gross_amount: parseInt(amount),
        },
      }),
      timeout: 15,
    });

    const testB = $http.send({
      url: baseUrl,
      method: "POST",
      body: JSON.stringify({
        transaction_details: {
          order_id: "TEST-NO-" + orderId,
          gross_amount: 10000,
        },
      }),
      timeout: 15,
    });

    const testC = $http.send({
      url: baseUrl,
      method: "POST",
      headers: {
        "authorization": "Basic " + encodedAuth,
      },
      body: JSON.stringify({
        transaction_details: {
          order_id: orderId,
          gross_amount: parseInt(amount),
        },
        customer_details: {
          first_name: customerName,
          email: customerEmail,
        },
        item_details: [{
          id: "PREMIUM_PLAN",
          price: parseInt(amount),
          quantity: 1,
          name: "UWANGKU Premium",
        }],
      }),
      timeout: 15,
    });

    return e.json(200, {
      test1: test1.statusCode,
      A_status: testA.statusCode,
      A_body: testA.json ? Object.keys(testA.json).join(",") : typeof testA.json,
      B_status: testB.statusCode,
      B_body: testB.json ? Object.keys(testB.json).join(",") : typeof testB.json,
      C_status: testC.statusCode,
      C_body: testC.json ? Object.keys(testC.json).join(",") : typeof testC.json,
    });
  } catch (err) {
    return e.json(500, { error: "Hook error: " + err.toString() });
  }
}, $apis.requireAuth());
